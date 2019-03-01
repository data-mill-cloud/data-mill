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
	# https://github.com/SeldonIO/seldon-core/blob/master/docs/install.md
	helm repo add seldon-charts https://storage.googleapis.com/seldon-charts
	helm repo update

	helm upgrade $cfg__seldon_crd__release seldon-charts/seldon-core-crd \
	 --namespace $cfg__project__k8s_namespace \
	 --values $(get_values_file "$cfg__seldon_crd__config_file") \
	 --install --force

	helm upgrade $cfg__seldon__release seldon-charts/seldon-core \
         --namespace $cfg__project__k8s_namespace \
         --values $(get_values_file "$cfg__seldon__config_file") \
         --install --force

	helm repo remove seldon-charts
else
        helm delete $cfg__seldon__release --purge
	helm delete $cfg__seldon_crd__release --purge
fi
