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
	helm repo update
	helm upgrade $cfg__dask__release stable/dask \
	 --namespace $cfg__project__k8s_namespace \
	 -f $file_folder/$cfg__dask__config_file \
	 --install --force
else
	helm delete $cfg__dask__release --purge
fi
