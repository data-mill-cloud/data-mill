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
	# https://github.com/helm/charts/tree/master/stable/metallb
	helm upgrade $cfg__metallb__release stable/metallb \
	 --namespace $cfg__project__k8s_namespace \
	 --values $(get_values_file "$cfg__metallb__config_file") \
	 --install --wait --force
else
	helm delete $cfg__metallb__release --purge
fi
