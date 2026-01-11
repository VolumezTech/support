# modules/aws-region/main.tf
# Deploys one EC2 instance per AZ in an AWS region for latency measurement

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "key_name" {
  type = string
}

variable "public_key" {
  type    = string
  default = ""
}

# Create key pair in this region if public_key is provided
resource "aws_key_pair" "latency_test" {
  count      = var.public_key != "" ? 1 : 0
  key_name   = var.key_name
  public_key = var.public_key

  tags = {
    Name = "${var.project_name}-key"
  }
}

locals {
  key_name = var.public_key != "" ? aws_key_pair.latency_test[0].key_name : var.key_name
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "project_name" {
  type    = string
  default = "latency-mesh"
}

# Get available AZs in this region
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Filter AZs that support the instance type
data "aws_ec2_instance_type_offerings" "available" {
  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }

  location_type = "availability-zone-id"
}

locals {
  # Only use AZs that support the instance type
  supported_az_ids = toset([
    for az_id in data.aws_availability_zones.available.zone_ids :
    az_id if contains(data.aws_ec2_instance_type_offerings.available.locations, az_id)
  ])
}

# Get current region
data "aws_region" "current" {}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC for latency testing
resource "aws_vpc" "latency_test" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "latency_test" {
  vpc_id = aws_vpc.latency_test.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Route table
resource "aws_route_table" "latency_test" {
  vpc_id = aws_vpc.latency_test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.latency_test.id
  }

  tags = {
    Name = "${var.project_name}-rt"
  }
}

# Create a subnet per supported AZ
resource "aws_subnet" "latency_test" {
  for_each = local.supported_az_ids

  vpc_id                  = aws_vpc.latency_test.id
  cidr_block              = cidrsubnet("10.0.0.0/16", 8, index(tolist(local.supported_az_ids), each.key))
  availability_zone       = [for az in data.aws_availability_zones.available.names : az if data.aws_availability_zones.available.zone_ids[index(data.aws_availability_zones.available.names, az)] == each.key][0]
  map_public_ip_on_launch = true

  tags = {
    Name  = "${var.project_name}-subnet-${each.key}"
    AZ_ID = each.key
  }
}

# Associate subnets with route table
resource "aws_route_table_association" "latency_test" {
  for_each = aws_subnet.latency_test

  subnet_id      = each.value.id
  route_table_id = aws_route_table.latency_test.id
}

# Security group allowing ICMP and SSH
resource "aws_security_group" "latency_test" {
  name        = "${var.project_name}-sg"
  description = "Security group for latency testing"
  vpc_id      = aws_vpc.latency_test.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ICMP (ping) from anywhere
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ICMP from within the VPC (self-reference)
  ingress {
    from_port = -1
    to_port   = -1
    protocol  = "icmp"
    self      = true
  }

  # All traffic within VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # iperf3 port
  ingress {
    from_port   = 5201
    to_port     = 5201
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # qperf ports
  ingress {
    from_port   = 19765
    to_port     = 19766
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# User data script to install measurement tools
locals {
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y iperf3 qperf bind-utils jq

    # Create measurement script
    cat > /home/ec2-user/measure_latency.sh << 'SCRIPT'
    #!/bin/bash
    TARGET_IP=$1
    TARGET_AZ=$2
    SOURCE_AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone-id)
    
    # Run ping test (100 packets)
    PING_RESULT=$(ping -c 100 -i 0.1 $TARGET_IP 2>/dev/null | tail -1)
    
    # Parse results: rtt min/avg/max/mdev = 0.123/0.456/0.789/0.012 ms
    if [[ $PING_RESULT =~ ([0-9.]+)/([0-9.]+)/([0-9.]+)/([0-9.]+) ]]; then
        MIN=$${BASH_REMATCH[1]}
        AVG=$${BASH_REMATCH[2]}
        MAX=$${BASH_REMATCH[3]}
        MDEV=$${BASH_REMATCH[4]}
    else
        MIN="N/A"
        AVG="N/A"
        MAX="N/A"
        MDEV="N/A"
    fi
    
    # Output JSON
    echo "{\"source_az\":\"$SOURCE_AZ\",\"target_az\":\"$TARGET_AZ\",\"target_ip\":\"$TARGET_IP\",\"min_ms\":\"$MIN\",\"avg_ms\":\"$AVG\",\"max_ms\":\"$MAX\",\"mdev_ms\":\"$MDEV\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
    SCRIPT
    chmod +x /home/ec2-user/measure_latency.sh
    chown ec2-user:ec2-user /home/ec2-user/measure_latency.sh
  EOF
}

# Deploy one instance per supported AZ
resource "aws_instance" "latency_node" {
  for_each = local.supported_az_ids

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = local.key_name
  vpc_security_group_ids = [aws_security_group.latency_test.id]
  subnet_id              = aws_subnet.latency_test[each.key].id

  user_data = local.user_data

  tags = {
    Name   = "${var.project_name}-${each.key}"
    AZ_ID  = each.key
    Region = data.aws_region.current.name
  }
}

# Outputs
output "instances" {
  value = {
    for az_id, instance in aws_instance.latency_node : az_id => {
      instance_id = instance.id
      private_ip  = instance.private_ip
      public_ip   = instance.public_ip
      az_id       = az_id
      az_name     = instance.availability_zone
      region      = data.aws_region.current.name
      cloud       = "aws"
    }
  }
}

output "region" {
  value = data.aws_region.current.name
}

output "az_count" {
  value = length(local.supported_az_ids)
}
