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
	# https://github.com/helm/charts/tree/master/incubator/cassandra
	helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
	# deploy
	helm upgrade $cfg__cassandra__release incubator/cassandra \
	 --namespace $cfg__project__k8s_namespace \
	 --values $file_folder/$cfg__cassandra__config_file \
	 --install --force
else
	helm delete $cfg__cassandra__release --purge
fi
