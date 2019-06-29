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
	kubectl apply -f https://raw.github.com/astefanutti/kubebox/master/kubernetes.yaml
else
	kubectl delete -f https://raw.github.com/astefanutti/kubebox/master/kubernetes.yaml
fi
