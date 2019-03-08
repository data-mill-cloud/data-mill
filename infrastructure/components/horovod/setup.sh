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
	# https://github.com/helm/charts/tree/master/stable/horovod
	kubectl delete statefulsets.apps --cascade=false $cfg__horovod__release
	helm upgrade $cfg__horovod__release stable/horovod \
	 --namespace $cfg__project__k8s_namespace \
	 --values $(get_values_file "$cfg__horovod__config_file") \
	 --install --force
else
	helm delete $cfg__horovod__release --purge
	kubectl delete statefulsets.apps --cascade=false $cfg__horovod__release
fi
