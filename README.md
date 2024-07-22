# **Basic Volumez log collector for Kubernetes**
## **Use the following command to collect logs:**

`curl -sL https://github.com/VolumezTech/support/raw/main/vlz-k8s-collector.sh |bash`

Then upload the log file to support

## For more options you can donwload the collector script using curl or wget:
`curl -O https://github.com/VolumezTech/support/raw/main/vlz-k8s-collector.sh`

Add execute permissions:

`chmod +x ./vlz-k8s-collector.sh`

Then you can run the script locally with flags:
```
./vlz-k8s-collector.sh --help
Usage: ./vlz-k8s-collector.sh [--minimal | --full] [--skip-api]
If nothing is set perform regular collection

./vlz-k8s-collector.sh [--minimal | --full]

Examples:
    ./vlz-k8s-collector.sh --minimal              #Perform the shortest passible collection
    ./vlz-k8s-collector.sh                        #Perform regualr collection
    ./vlz-k8s-collector.sh --full                 #Perform full collection
    ./vlz-k8s-collector.sh --help, -h             #Show this help message.
```