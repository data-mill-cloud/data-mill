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

	# use the global namespace if no specific one is set
	traefik_ns=${cfg__traefik__k8s_namespace:=$cfg__project__k8s_namespace}

	# use the local hostname if no host is set
	app_host=$(hostname --long)
	app_host=${cfg__traefik__host:=$app_host}

	# install traefik chart
	helm upgrade $cfg__traefik__release stable/traefik \
	 --namespace $traefik_ns \
	 --values $(get_values_file "$cfg__traefik__config_file") \
	 --install --force

	# unset vars
	unset traefik_ns
	unset app_host
else
	helm delete $cfg__traefik__release --purge
fi
