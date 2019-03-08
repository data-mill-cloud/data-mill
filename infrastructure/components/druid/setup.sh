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
	# add helm incubator repo
	helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
	helm repo update
	# install druid
	helm upgrade $cfg__druid__release incubator/druid \
	 --namespace $cfg__project__k8s_namespace \
	 --values $(get_values_file "$cfg__druid__config_file") \
	 --install --force
	helm repo remove incubator
else
	helm delete $cfg__druid__release --purge
fi
