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
	helm repo add kubemq-charts https://kubemq-io.github.io/charts
	helm repo update
	kubemq_token=$(get_random_secret_key)
	echo "kubemq token: "$kubemq_token
	helm upgrade $cfg__kubemq__release kubemq-charts/kubemq \
	 --namespace $cfg__project__k8s_namespace \
	 --set token=$kubemq_token \
	 --install --force
	#--values $file_folder/$cfg__kubemq__config_file \
	helm repo remove kubemq-charts
else
	helm delete $cfg__kubemq__release --purge
fi
