#!/usr/bin/env bash

fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
file_folder=$(dirname $fullpath)

# load local yaml config
# if -f was given and the file exists use it, otherwise fallback to the specified component default config
COMPONENT_CONFIG=$(file_exists "$file_folder/$CONFIG_FILE" "$file_folder/$cfg__project__component_default_config")
eval $(parse_yaml $COMPONENT_CONFIG "cfg__")

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
	 --values $file_folder/$cfg__traefik__config_file \
	 --install --force

	# unset vars
	unset traefik_ns
	unset app_host
else
	helm delete $cfg__traefik__release --purge
fi
