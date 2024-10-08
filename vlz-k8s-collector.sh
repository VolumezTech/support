#!/bin/bash

VERSION="v2.1"
COLLECTOR_LOG="cmd.log"

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'  # No Color

print_msg() {
    local color="$1"
    local message="$2"

    case "$color" in
        "ok")
            echo -e "${GREEN}OK:$message${NC}"  # Green color
            ;;
        "warn")
            echo -e "${YELLOW}WARN:$message${NC}"  # Yellow color
            ;;
        "error")
            echo -e "${RED}ERROR:$message${NC}"  # Red color
            ;;
    esac
}

help()
{
    cat <<EOF
Usage: $0 [--minimal | --full]
If nothing is set perform regular collection

$0 [--minimal | --full]

Examples:
    $0 --minimal              #Perform the shortest passible collection
    $0                        #Perform regualr collection
    $0 --full                 #Perform full collection
    $0 --help, -h             #Show this help message
    $0 --version -v           #Show script version and exit

EOF
   
    exit 1
}

show_arguments(){
    # Display parsed arguments (for debugging)
    echo "Minimal: $minimal"
    echo "Regular:" $regular
    echo "Full: $full"
    echo "Skip API: $skip_api"
    
    # Your script logic here
    if [[ "$minimal" -eq 1 ]]; then
        echo "Running in minimal mode."
    fi
    
    if [[ "$full" -eq 1 ]]; then
        echo "Running in full mode."
    fi
    
    if [[ "$skip_api" -eq 1 ]]; then
        echo "Skipping API."
    fi
}

arg_pars(){
    # Initialize variables
    minimal=0
    regular=0
    full=0
    skip_api=0
    debug=0
    
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --version|-v)
                echo "Version:"
                echo "$(basename $0) $VERSION"
                exit 0
                ;;
            --minimal)
                minimal=1
                shift
                ;;
            --full)
                full=1
                shift
                ;;
            --skip-api)
                skip_api=1
                shift
                ;;
            --debug)
                debug=1
                shift
                ;;
            --help|-h)
                help
                ;;
            *)
                print_msg error "\"$1\" is an invalid argument"
                help
                ;;
        esac
    done
    
    # Validate arguments
    if [[ "$minimal" -eq 1 && "$full" -eq 1 ]]; then
        print_msg "error" "You can specify either --minimal or --full, but not both."
        help
    elif [[ "$minimal" -eq 0 && "$full" -eq 0 ]]; then
        regular=1
    fi
    if [ "$debug" -eq 1 ] ; then
        show_arguments
    fi
}


run(){
    log_file=$1
    shift
    echo -n "running: $@ " | tee -a "$log_file" $COLLECTOR_LOG
    "$@" >> "$log_file" 2>&1
    if [ $? -eq 0 ]; then
        echo "[Success]" | tee -a "$log_file" $COLLECTOR_LOG
    else
        echo "[Error]" | tee -a "$log_file" $COLLECTOR_LOG
    fi
}

pre_collect()
{   
    origin_pwd=$(pwd)
    tmp_name=$(date +%s | md5sum | cut -c1-8)
    tmp_folder=vlz-logz-$tmp_name
    mkdir "$tmp_folder" && cd "$tmp_folder" || exit 1  # Exit script if mkdir or cd fails
    echo "Created tmp dir for collection $tmp_folder"
}

get_entities() {
    local pod
    local i
    # Fetch the list of pod names in the vlz-cert-manager namespace
    CERT_MGM_PODS=$(kubectl get pods --namespace vlz-cert-manager -o jsonpath='{.items[*].metadata.name}')
    # Fetch the list of pod names in the vlz-csi-driver namespace
    CSI_DRIVER_PODS=$(kubectl get pods --namespace vlz-csi-driver -o jsonpath='{.items[*].metadata.name}')
    
    get_containers() 
    {
            local namespace=$1
            local pod=$2
            kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.spec.containers[*].name}'
    }

    CERT_MGM_PODS_ARRAY=()
    CERT_MGM_CONTAINERS_ARRAY=()
    CSI_DRIVER_PODS_ARRAY=()
    CSI_DRIVER_CONTAINERS_ARRAY=()

    # Populate arrays for CERT_MGM
    for pod in $CERT_MGM_PODS; do
        containers=$(get_containers vlz-cert-manager "$pod")
        CERT_MGM_PODS_ARRAY+=("$pod")
        CERT_MGM_CONTAINERS_ARRAY+=("$containers")
    done

    # Populate arrays for CSI_DRIVER
    for pod in $CSI_DRIVER_PODS; do
        containers=$(get_containers vlz-csi-driver "$pod")
        CSI_DRIVER_PODS_ARRAY+=("$pod")
        CSI_DRIVER_CONTAINERS_ARRAY+=("$containers")
    done

    if [ "$debug" -eq 1 ] ;then
        echo 
        # Print the pods and their containers for verification
        echo "CERT_MGM pods and their containers:"
        for i in "${!CERT_MGM_PODS_ARRAY[@]}"; do
            echo "Pod: ${CERT_MGM_PODS_ARRAY[$i]}, Containers: ${CERT_MGM_CONTAINERS_ARRAY[$i]}"
        done
        
        echo "CSI_DRIVER pods and their containers:"
        for i in "${!CSI_DRIVER_PODS_ARRAY[@]}"; do
            echo "Pod: ${CSI_DRIVER_PODS_ARRAY[$i]}, Containers: ${CSI_DRIVER_CONTAINERS_ARRAY[$i]}"
        done
    fi
}

collect_minimal_pods(){
    local pod
    for pod in $CERT_MGM_PODS; do
        run "$pod.log" kubectl logs --namespace vlz-cert-manager "$pod"
    done
    
    for pod in $CSI_DRIVER_PODS; do
        run "$pod.log" kubectl logs --namespace vlz-csi-driver "$pod" vlz
    done
}

collect_all_pods(){
    local pod
    local container containers
    local i
    
    for i in "${!CERT_MGM_PODS_ARRAY[@]}"; do
        pod=${CERT_MGM_PODS_ARRAY[$i]}
        containers=$(echo ${CERT_MGM_CONTAINERS_ARRAY[$i]}| xargs)
        for container in $containers; do
            run "$pod-$container.log" kubectl logs --namespace vlz-cert-manager "$pod" "$container"
        done
    done

    for i in "${!CSI_DRIVER_PODS_ARRAY[@]}"; do
        pod=${CSI_DRIVER_PODS_ARRAY[$i]}
        containers=$(echo ${CSI_DRIVER_CONTAINERS_ARRAY[i]}| xargs)
        for container in $containers; do
            run "$pod-$container.log" kubectl logs --namespace vlz-csi-driver "$pod" "$container"
        done
    done
}
    
collect_generanl_cluster(){
    run api-resources.log kubectl api-resources
    run get-vlz-csi-driver.log kubectl get all -n vlz-csi-driver
    run get-vlz-cert-manager.log kubectl get all -n vlz-cert-manager
    run get-nodes.log kubectl get nodes --show-labels
    run helm-namespace.log helm list --all-namespaces
}

collect_all_pv(){
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
}

post_collect()
{
    local d
    echo "$0: $VERSION" >> $COLLECTOR_LOG   
    d=$(date "+%Y-%m-%d-%H-%M-%S")
    cd $origin_pwd
    tar -czf vlz-support-$d.tgz $tmp_folder
    print_msg "ok" "Logs collected to: vlz-support-$d.tgz"
}

minimal(){
collect_generanl_cluster
collect_minimal_pods
}

regular(){
collect_generanl_cluster
collect_all_pods
}

full(){
collect_generanl_cluster
collect_all_pods
collect_all_pv
}

main(){
    arg_pars "$@"
    pre_collect
    echo "Collecting Volumez logs"
    
    get_entities
    if [ "$minimal" -eq 1 ] ; then
        minimal
    elif [ "$full" -eq 1 ] ; then
        full
    else
        regular
    fi
    
    post_collect
}

# For testing we do not run main when sourcing the script
# In other words skip main $0 contains bash_unit (our unitest tool)
if [[ "$0" == *"bash_unit"* ]] ; then
    true
else
    main "$@"
fi
