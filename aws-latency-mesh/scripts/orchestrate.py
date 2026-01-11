#!/usr/bin/env python3
"""
Orchestrates full-mesh latency measurements across AWS and Azure regions.

Usage:
    ./orchestrate.py --cloud aws                    # AWS only (uses terraform/aws)
    ./orchestrate.py --cloud azure                  # Azure only (uses terraform/azure)
    ./orchestrate.py --cloud aws --cloud azure      # Both clouds
    ./orchestrate.py --inventory inv.json           # Use existing inventory file

Environment variables:
    SSH_KEY       - Path to SSH private key (optional if auto-detected from terraform)
    TCP_DURATION  - Duration in seconds for TCP latency test (default: 5)
    PARALLEL_JOBS - Max parallel SSH connections (default: 10)
"""

import json
import subprocess
import os
import sys
import re
import tempfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from itertools import combinations
from datetime import datetime, timezone
from pathlib import Path
import argparse

# Default SSH users per cloud
DEFAULT_SSH_USERS = {
    'aws': 'ec2-user',
    'azure': 'azureuser'
}


def get_terraform_inventory(terraform_dir, cloud=None):
    """Fetch instance inventory from Terraform output.

    Args:
        terraform_dir: Base terraform directory
        cloud: Optional cloud name (aws/azure) for subdirectory
    """
    if cloud:
        tf_path = Path(terraform_dir) / cloud
    else:
        tf_path = Path(terraform_dir)

    if not tf_path.exists():
        return None, None, None

    try:
        # Get instances
        result = subprocess.run(
            ['terraform', f'-chdir={tf_path}', 'output', '-json', 'instances'],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode != 0:
            return None, None, None
        instances = json.loads(result.stdout)

        # Get SSH key
        key_result = subprocess.run(
            ['terraform', f'-chdir={tf_path}', 'output', '-raw', 'ssh_private_key'],
            capture_output=True, text=True, timeout=30
        )
        ssh_key = key_result.stdout if key_result.returncode == 0 else None

        # Get SSH user
        user_result = subprocess.run(
            ['terraform', f'-chdir={tf_path}', 'output', '-raw', 'ssh_user'],
            capture_output=True, text=True, timeout=30
        )
        ssh_user = user_result.stdout.strip() if user_result.returncode == 0 else None

        return instances, ssh_key, ssh_user

    except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError):
        return None, None, None


def load_inventory(inventory_file):
    """Load instance inventory from JSON file."""
    with open(inventory_file, 'r') as f:
        return json.load(f)


def get_ssh_user(instance, override_user=None):
    """Get SSH user for an instance based on cloud type."""
    if override_user:
        return override_user
    cloud = instance.get('cloud', 'aws')
    return DEFAULT_SSH_USERS.get(cloud, 'ec2-user')


def parse_qperf_output(output):
    """Parse qperf tcp_lat output to extract latency statistics.

    qperf output format:
        tcp_lat:
            latency  =  1.52 ms

    For statistics we run multiple iterations and calculate min/avg/max/stddev.
    """
    latency_match = re.search(r'latency\s*=\s*([\d.]+)\s*(us|ms|s)', output)
    if latency_match:
        value = float(latency_match.group(1))
        unit = latency_match.group(2)
        # Convert to milliseconds
        if unit == 'us':
            value /= 1000
        elif unit == 's':
            value *= 1000
        return value
    return None


def start_qperf_servers(instances, ssh_key, ssh_user_override):
    """Start qperf servers on all instances in parallel."""
    ssh_opts = [
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'UserKnownHostsFile=/dev/null',
        '-o', 'ConnectTimeout=10',
        '-o', 'LogLevel=ERROR'
    ]

    def start_server(instance):
        ssh_user = get_ssh_user(instance, ssh_user_override)
        public_ip = instance['public_ip']
        try:
            # Kill any existing qperf and start fresh server
            cmd = [
                'ssh', '-i', ssh_key, *ssh_opts,
                f'{ssh_user}@{public_ip}',
                'pkill -9 qperf 2>/dev/null; nohup qperf > /dev/null 2>&1 &'
            ]
            subprocess.run(cmd, capture_output=True, timeout=15)
            return True
        except Exception:
            return False

    with ThreadPoolExecutor(max_workers=10) as executor:
        list(executor.map(start_server, instances))

    # Give servers time to start
    import time
    time.sleep(2)


def stop_qperf_servers(instances, ssh_key, ssh_user_override):
    """Stop qperf servers on all instances."""
    ssh_opts = [
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'UserKnownHostsFile=/dev/null',
        '-o', 'ConnectTimeout=10',
        '-o', 'LogLevel=ERROR'
    ]

    def stop_server(instance):
        ssh_user = get_ssh_user(instance, ssh_user_override)
        public_ip = instance['public_ip']
        try:
            cmd = [
                'ssh', '-i', ssh_key, *ssh_opts,
                f'{ssh_user}@{public_ip}',
                'pkill -9 qperf 2>/dev/null || true'
            ]
            subprocess.run(cmd, capture_output=True, timeout=10)
        except Exception:
            pass

    with ThreadPoolExecutor(max_workers=10) as executor:
        list(executor.map(stop_server, instances))


def run_measurement(source_instance, target_instance, ssh_key, ssh_user_override, tcp_duration):
    """Run TCP latency measurement from source to target instance using qperf.

    Note: qperf servers should already be running on all instances before calling this.
    """
    source_ip = source_instance['public_ip']
    target_ip = target_instance['private_ip']
    source_az = source_instance['az_id']
    target_az = target_instance['az_id']
    region = source_instance['region']
    cloud = source_instance.get('cloud', 'aws')

    # Skip same-AZ measurements
    if source_az == target_az:
        return {
            'type': 'skip',
            'cloud': cloud,
            'source_az': source_az,
            'target_az': target_az,
            'reason': 'same_az'
        }

    # Get SSH user for this instance
    ssh_user = get_ssh_user(source_instance, ssh_user_override)

    ssh_opts = [
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'UserKnownHostsFile=/dev/null',
        '-o', 'ConnectTimeout=10',
        '-o', 'LogLevel=ERROR'
    ]

    try:
        # Run multiple qperf measurements from source to get statistics
        latencies = []
        iterations = 5  # Run 5 measurements for statistics

        for _ in range(iterations):
            client_cmd = [
                'ssh', '-i', ssh_key, *ssh_opts,
                f'{ssh_user}@{source_ip}',
                f'qperf -t 1 {target_ip} tcp_lat 2>/dev/null || echo "ERROR"'
            ]
            result = subprocess.run(client_cmd, capture_output=True, text=True, timeout=30)

            if 'ERROR' not in result.stdout:
                latency = parse_qperf_output(result.stdout)
                if latency is not None:
                    latencies.append(latency)

        if latencies:
            # Calculate statistics
            min_ms = min(latencies)
            max_ms = max(latencies)
            avg_ms = sum(latencies) / len(latencies)

            # Calculate standard deviation
            variance = sum((x - avg_ms) ** 2 for x in latencies) / len(latencies)
            mdev_ms = variance ** 0.5

            return {
                'type': 'result',
                'cloud': cloud,
                'region': region,
                'source_az': source_az,
                'target_az': target_az,
                'source_ip': source_ip,
                'target_ip': target_ip,
                'min_ms': min_ms,
                'avg_ms': avg_ms,
                'max_ms': max_ms,
                'mdev_ms': mdev_ms,
                'packet_loss_pct': 0,  # TCP doesn't have packet loss in same way
                'sample_count': len(latencies),
                'measurement_type': 'tcp_qperf',
                'timestamp': datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')
            }

        return {
            'type': 'error',
            'cloud': cloud,
            'source_az': source_az,
            'target_az': target_az,
            'error': 'no_valid_measurements',
            'output': 'qperf returned no valid latency values'
        }

    except subprocess.TimeoutExpired:
        return {
            'type': 'error',
            'cloud': cloud,
            'source_az': source_az,
            'target_az': target_az,
            'error': 'timeout'
        }
    except Exception as e:
        return {
            'type': 'error',
            'cloud': cloud,
            'source_az': source_az,
            'target_az': target_az,
            'error': str(e)
        }


def run_region_measurements(cloud, region, instances, ssh_key, ssh_user, tcp_duration, max_workers):
    """Run full-mesh measurements for a single region."""
    results = []
    instance_list = list(instances.values())

    # Generate unique AZ pairs (combinations, not permutations)
    # TCP latency is symmetric (round-trip), so we only measure each pair once
    pairs = list(combinations(instance_list, 2))

    print(f"  Starting qperf servers on {len(instance_list)} nodes...")
    start_qperf_servers(instance_list, ssh_key, ssh_user)

    print(f"  Running {len(pairs)} measurements in {cloud}/{region}...")

    try:
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = {
                executor.submit(run_measurement, src, dst, ssh_key, ssh_user, tcp_duration): (src, dst)
                for src, dst in pairs
            }

            for future in as_completed(futures):
                result = future.result()
                results.append(result)
                if result['type'] == 'result':
                    print(f"    {result['source_az']} -> {result['target_az']}: {result['avg_ms']:.3f}ms (TCP)")
                elif result['type'] == 'error':
                    print(f"    {result['source_az']} -> {result['target_az']}: ERROR - {result.get('error', 'unknown')}")
    finally:
        print(f"  Stopping qperf servers...")
        stop_qperf_servers(instance_list, ssh_key, ssh_user)

    return results


def main():
    script_dir = Path(__file__).parent.resolve()
    default_terraform_dir = script_dir.parent / 'terraform'
    default_results_dir = script_dir.parent / 'results' / datetime.now().strftime('%Y%m%d_%H%M%S')

    parser = argparse.ArgumentParser(
        description='Run full-mesh latency measurements across AWS and Azure AZs',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument('--inventory', help='Path to inventory JSON (skips Terraform)')
    parser.add_argument('--terraform-dir', default=str(default_terraform_dir),
                        help=f'Terraform base directory (default: {default_terraform_dir})')
    parser.add_argument('--cloud', action='append', choices=['aws', 'azure'],
                        help='Cloud(s) to include (can specify multiple: --cloud aws --cloud azure)')
    parser.add_argument('--output-dir', default=str(default_results_dir),
                        help='Output directory for results')
    parser.add_argument('--ssh-key', default=os.environ.get('SSH_KEY'),
                        help='SSH private key (auto-detected from terraform if not provided)')
    parser.add_argument('--ssh-user', default=None,
                        help='SSH username override (default: auto-detect per cloud)')
    parser.add_argument('--tcp-duration', type=int, default=int(os.environ.get('TCP_DURATION', '5')),
                        help='Duration for TCP latency test in seconds')
    parser.add_argument('--max-workers', type=int, default=int(os.environ.get('PARALLEL_JOBS', '10')),
                        help='Max parallel measurements per region')
    args = parser.parse_args()

    print("=" * 60)
    print("Multi-Cloud Full-Mesh TCP Latency Measurement")
    print("=" * 60)

    # Determine which clouds to use
    clouds_to_use = args.cloud if args.cloud else ['aws', 'azure']

    # Collect inventory and SSH keys from specified clouds
    inventory = {}
    ssh_keys = {}  # Track SSH key per cloud
    ssh_users = {}  # Track SSH user per cloud

    if args.inventory:
        print(f"\nLoading inventory from {args.inventory}...")
        inventory = load_inventory(args.inventory)
    else:
        print(f"\nFetching inventory from Terraform ({args.terraform_dir})...")

        for cloud in clouds_to_use:
            cloud_inventory, cloud_ssh_key, cloud_ssh_user = get_terraform_inventory(args.terraform_dir, cloud)

            if cloud_inventory:
                inventory.update(cloud_inventory)
                print(f"  {cloud.upper()}: {len(cloud_inventory)} instances")

                if cloud_ssh_key:
                    # Save SSH key to temp file
                    key_file = Path(tempfile.gettempdir()) / f'{cloud}_latency_key'
                    key_file.write_text(cloud_ssh_key)
                    key_file.chmod(0o600)
                    ssh_keys[cloud] = str(key_file)
                    print(f"  {cloud.upper()} SSH key saved to {key_file}")

                if cloud_ssh_user:
                    ssh_users[cloud] = cloud_ssh_user
            else:
                print(f"  {cloud.upper()}: No instances found (terraform/{cloud} may not be deployed)")

        if not inventory:
            print("ERROR: No instances found. Run 'terraform apply' first.", file=sys.stderr)
            sys.exit(1)

    # Create output directory and save inventory
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    inventory_file = output_dir / 'inventory.json'
    with open(inventory_file, 'w') as f:
        json.dump(inventory, f, indent=2)
    print(f"Inventory saved to {inventory_file}")

    # Group instances by cloud, then by region
    clouds = {}
    for az_id, instance in inventory.items():
        cloud = instance.get('cloud', 'aws')
        region = instance['region']
        if cloud not in clouds:
            clouds[cloud] = {}
        if region not in clouds[cloud]:
            clouds[cloud][region] = {}
        clouds[cloud][region][az_id] = instance

    # Count totals
    total_instances = len(inventory)
    total_regions = sum(len(regions) for regions in clouds.values())
    print(f"Found {len(clouds)} clouds, {total_regions} regions, {total_instances} total instances")

    for cloud, regions in sorted(clouds.items()):
        print(f"  {cloud.upper()}: {len(regions)} regions, {sum(len(r) for r in regions.values())} instances")

    # Run measurements for each cloud/region
    all_results = []
    for cloud in sorted(clouds.keys()):
        print(f"\n{'='*60}")
        print(f"[{cloud.upper()}]")
        print("=" * 60)

        # Determine SSH key for this cloud
        if args.ssh_key:
            cloud_ssh_key = args.ssh_key
        elif cloud in ssh_keys:
            cloud_ssh_key = ssh_keys[cloud]
        else:
            print(f"ERROR: No SSH key available for {cloud}. Provide --ssh-key or deploy with terraform.", file=sys.stderr)
            continue

        # Determine SSH user for this cloud
        cloud_ssh_user = args.ssh_user or ssh_users.get(cloud)

        for region, instances in sorted(clouds[cloud].items()):
            print(f"\n[{cloud}/{region}] {len(instances)} AZs")
            results = run_region_measurements(
                cloud, region, instances,
                cloud_ssh_key, cloud_ssh_user,
                args.tcp_duration, args.max_workers
            )
            all_results.extend(results)

    # Save results
    output_data = {
        'metadata': {
            'timestamp': datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z'),
            'tcp_duration': args.tcp_duration,
            'measurement_type': 'tcp_qperf',
            'total_measurements': len([r for r in all_results if r['type'] == 'result']),
            'total_errors': len([r for r in all_results if r['type'] == 'error']),
            'clouds': list(clouds.keys()),
            'regions': {cloud: list(regions.keys()) for cloud, regions in clouds.items()}
        },
        'results': all_results
    }

    results_file = output_dir / 'results.json'
    with open(results_file, 'w') as f:
        json.dump(output_data, f, indent=2)

    # Generate markdown report
    report_file = output_dir / 'report.md'
    from generate_report import generate_report
    generate_report(output_data, report_file, inventory=inventory)

    print(f"\n{'=' * 60}")
    print(f"Complete!")
    print(f"Results: {results_file}")
    print(f"Report:  {report_file}")
    print(f"Total measurements: {output_data['metadata']['total_measurements']}")
    print(f"Total errors: {output_data['metadata']['total_errors']}")
    print("=" * 60)


if __name__ == '__main__':
    main()
