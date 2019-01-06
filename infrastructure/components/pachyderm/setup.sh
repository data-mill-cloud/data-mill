#!/usr/bin/env bash

fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
file_folder=$(dirname $fullpath)

# load local yaml config
COMPONENT_CONFIG=$(file_exists $file_folder/$CONFIG_FILE $file_folder/"config.yaml")
eval $(parse_yaml $COMPONENT_CONFIG "cfg__")

# use if set or a string argument otherwise
ACTION=${ACTION:=$1}

if [ -z "$ACTION" ] || [ "$ACTION" != "install" ] && [ "$ACTION" != "delete" ];then
        echo "usage: $0 {'install' | 'delete'}";
        exit 1
elif [ "$ACTION" = "install" ]; then
	# https://hub.helm.sh/charts/stable/pachyderm
	helm upgrade $cfg__pachyderm__release stable/pachyderm \
	 --version $cfg__pachyderm__version \
	 --namespace $cfg__project__k8s_namespace \
	 --values $file_folder/$cfg__pachyderm__config_file \
	 --install --force
else
	helm delete $cfg__pachyderm__release --purge
fi
