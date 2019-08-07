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
	nginx_ns=${cfg__nginx_ingress__k8s_namespace:=$cfg__project__k8s_namespace}
	# https://kubernetes.github.io/ingress-nginx/deploy/baremetal/
	helm upgrade $cfg__nginx_ingress__release stable/nginx-ingress \
	 --namespace $nginx_ns \
	 --values $(get_values_file "$cfg__nginx_ingress__config_file") \
	 --install --force
	unset nginx_ns
else
	helm delete $cfg__nginx_ingress__release --purge
fi
