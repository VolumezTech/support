#!/bin/bash

echo "Collecting Volumez logs"
origin_pwd=$(pwd)
tmp_name=$(date +%s | md5sum | cut -c1-8)
tmp_folder=vlz-logz-$tmp_name
mkdir "$tmp_folder" && cd "$tmp_folder" || exit 1  # Exit script if mkdir or cd fails

run(){
	echo -n "running: $@ "|tee -a cmd.log
	$@
	if [ $? -eq 0 ]; then
		echo "[Success]" >> cmd.log
	else
		echo "[Error]" >> cmd.log
	fi
}

CERT_MGM=$(kubectl get pods --namespace vlz-cert-manager -o jsonpath='{.items[*].metadata.name}')
CSI_DRIVER=$(kubectl get pods --namespace vlz-csi-driver -o jsonpath='{.items[*].metadata.name}')

for container in $CERT_MGM; do
	# echo "kubectl logs --namespace vlz-cert-manager $container > $container.log" 
    run kubectl logs --namespace vlz-cert-manager "$container" > "$container.log" 2>&1
done

for container in $CSI_DRIVER; do
	# echo "kubectl logs --namespace vlz-csi-driver $container > $container.log 2>&1"
    run kubectl logs --namespace vlz-csi-driver "$container" > "$container.log" 2>&1
done

touch pv.log 
run kubectl get pv -A >> pv.log 2>&1
pv_names=$(kubectl get pv -A -o custom-columns=:.metadata.name |xargs)
for pv in $pv_names; do
	run kubectl describe pv $pv >> pv.log 2>&1
done

touch pvc.log 
run kubectl get pvc -A >> pvc.log 2>&1
pvc_names=$(kubectl get pvc -A -o custom-columns=:.metadata.name |xargs)
for pvc in $pvc_names; do
	run kubectl describe pvc $pvc >> pvc.log 2>&1
done

run kubectl api-resources >api-resources.log 2>&1
run kubectl get all -n vlz-csi-driver > get-vlz-csi-driver.log 2>&1
run kubectl get all -n vlz-cert-manager > get-vlz-cert-manager.log 2>&1
run kubectl get nodes --show-labels > get-nodes.log 2>&1
run helm list --all-namespaces > helm-namespace.log 2>&1

d=$(date "+%Y-%m-%d-%H-%M-%S")
cd $origin_pwd
tar -czf vlz-support-$d.tgz $tmp_folder

echo "Logs collected to: vlz-support-$d.tgz"

