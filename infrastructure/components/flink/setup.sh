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
	helm repo add data-mill https://data-mill-cloud.github.io/data-mill/helm-charts/
        helm repo update
	if [ -z "$cfg__flink__type" ] || [ "$cfg__flink__type" = "session" ]; then
		echo "Deploying Flink Session Cluster"
		# deploying flink as session cluster
	        helm upgrade $cfg__flink__release data-mill/flink \
	         --namespace $cfg__project__k8s_namespace \
	         --values $(get_values_file "$cfg__flink__config_file") \
	         --install --force
	else
		# start as job
		echo "Deploying Flink Job cluster"
                helm upgrade $cfg__flink__release data-mill/flink-job \
                 --namespace $cfg__project__k8s_namespace \
                 --values $(get_values_file "$cfg__flink__config_file") \
                 --install --force
	fi
	helm repo remove data-mill
else
        helm delete $cfg__flink__release --purge
fi
