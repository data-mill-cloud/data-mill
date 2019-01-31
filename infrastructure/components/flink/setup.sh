#!/usr/bin/env bash

fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
file_folder=$(dirname $fullpath)

# load local yaml config
# if -f was given and the file exists use it, otherwise fallback to the specified component default config
COMPONENT_CONFIG=$(file_exists "$file_folder/$CONFIG_FILE" "$file_folder/$cfg__project__component_default_config")
eval $(parse_yaml $COMPONENT_CONFIG "cfg__")

# use if set or a string argument otherwise
ACTION=${ACTION:=$1}

if [ -z "$ACTION" ] || [ "$ACTION" != "install" ] && [ "$ACTION" != "delete" ];then
        echo "usage: $0 {'install' | 'delete'}";
        exit 1
elif [ "$ACTION" = "install" ]; then
	helm repo add data-mill https://data-mill-cloud.github.io/data-mill/helm-charts/
        helm repo update
	if [ -z "$cfg__flink__type" ] || [ "$cfg__flink__type" = "session" ]; then
		echo "Deploying Flink Session Cluster"
		# deploying flink as session cluster
	        helm upgrade $cfg__flink__release data-mill/flink \
	         --namespace $cfg__project__k8s_namespace \
	         --values $file_folder/$cfg__flink__config_file \
	         --install --force
	else
		# start as job
		echo "Deploying Flink Job cluster"
                helm upgrade $cfg__flink__release data-mill/flink-job \
                 --namespace $cfg__project__k8s_namespace \
                 --values $file_folder/$cfg__flink__config_file \
                 --install --force
	fi
	helm repo remove data-mill
else
        helm delete $cfg__flink__release --purge
fi
