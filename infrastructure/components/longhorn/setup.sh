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
	kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
else
	# create uninstallation job to clean up CRDs from the system and wait for success
	kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/master/uninstall/uninstall.yaml
	kubectl get job/longhorn-uninstall -w
	# remove longhorn
	kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
	# remove uninstall
	kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/master/uninstall/uninstall.yaml
fi
