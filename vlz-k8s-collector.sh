#!/bin/bash

echo "Collecting Volumez logs"
origin_pwd=$(pwd)
tmp_name=$(date +%s | md5sum | cut -c1-8)
tmp_folder=vlz-logz-$tmp_name
mkdir "$tmp_folder" && cd "$tmp_folder" || exit 1  # Exit script if mkdir or cd fails

run(){
    log_file=$1
    shift
    echo -n "running: $@ " | tee -a "$log_file" cmd.log
    $@ >> "$log_file" 2>&1
    if [ $? -eq 0 ]; then
        echo "[Success]" | tee -a "$log_file" cmd.log
    else
        echo "[Error]" | tee -a "$log_file" cmd.log
    fi
}

CERT_MGM=$(kubectl get pods --namespace vlz-cert-manager -o jsonpath='{.items[*].metadata.name}')
CSI_DRIVER=$(kubectl get pods --namespace vlz-csi-driver -o jsonpath='{.items[*].metadata.name}')

for container in $CERT_MGM; do
    run "$container.log" kubectl logs --namespace vlz-cert-manager "$container"
done

for container in $CSI_DRIVER; do
    run "$container.log" kubectl logs --namespace vlz-csi-driver "$container"
done

run pv.log kubectl get pv -A
pv_names=$(kubectl get pv -A -o custom-columns=:.metadata.name | xargs)
for pv in $pv_names; do
    run pv.log kubectl describe pv $pv
done

run pvc.log kubectl get pvc -A
pvc_names=$(kubectl get pvc -A -o custom-columns=:.metadata.name | xargs)
for pvc in $pvc_names; do
    run pvc.log kubectl describe pvc $pvc
done

run api-resources.log kubectl api-resources
run get-vlz-csi-driver.log kubectl get all -n vlz-csi-driver
run get-vlz-cert-manager.log kubectl get all -n vlz-cert-manager
run get-nodes.log kubectl get nodes --show-labels
run helm-namespace.log helm list --all-namespaces

d=$(date "+%Y-%m-%d-%H-%M-%S")
cd $origin_pwd
tar -czf vlz-support-$d.tgz $tmp_folder

echo "Logs collected to: vlz-support-$d.tgz"