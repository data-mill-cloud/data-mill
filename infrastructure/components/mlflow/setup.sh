#!/usr/bin/env bash

# load component paths
eval $(get_paths)
# load local yaml config
eval $(get_component_config)

# use if set or a string argument otherwise
ACTION=${ACTION:=$1}

if [ -z "$ACTION" ] || [ "$ACTION" != "install" ] && [ "$ACTION" != "delete" ];then
        echo "usage: $0 {'install' | 'delete'}";
        exit 1
elif [ "$ACTION" = "install" ]; then
        # creating the PVC for mlflow
        $(find_by_volume_name_and_create $cfg__project__k8s_namespace "$file_folder/volumes/pvc/*" $cfg__mlflow__pvc_name "pvc")
        kubectl get pvc $cfg__mlflow__pvc_name -n=$cfg__project__k8s_namespace

	# adding and updating repo and helm chart
	helm repo add data-mill https://data-mill-cloud.github.io/data-mill/helm-charts/
	helm repo update

	helm upgrade $cfg__mlflow__release data-mill/mlflow \
         --namespace $cfg__project__k8s_namespace \
         --values $file_folder/$cfg__mlflow__config_file \
         --install --force
else
        helm delete $cfg__mlflow__release --purge
fi
