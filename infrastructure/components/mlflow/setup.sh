#!/usr/bin/env bash

fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
file_folder=$(dirname $fullpath)

# load local yaml config
eval $(parse_yaml $file_folder/$CONFIG_FILE "cfg__")

# use if set or a string argument otherwise
ACTION=${ACTION:=$1}

if [ -z "$ACTION" ] || [ "$ACTION" != "install" ] && [ "$ACTION" != "delete" ];then
        echo "usage: $0 {'install' | 'delete'}";
        exit 1
elif [ "$ACTION" = "install" ]; then
	helm repo add data-mill https://data-mill-cloud.github.io/data-mill/helm-charts/
	helm repo update

	helm upgrade $cfg__mlflow__release data-mill/mlflow \
         --namespace $cfg__project__k8s_namespace \
         --values $file_folder/$cfg__mlflow__config_file \
         --install --force
else
        helm delete $cfg__mlflow__release --purge
fi
