#!/usr/bin/env bash

fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
file_folder=$(dirname $fullpath)

# load local yaml config
eval $(parse_yaml $file_folder/$CONFIG_FILE "cfg__")

# use if set or a string argument otherwise
ACTION=${ACTION:=$1}

if [ -z "$ACTION" ] || [ "$ACTION" != "install" ] && [ "$ACTION" != "delete" ];then
        echo "usage: $0 {'install' | 'delete'}";
        exit 1
elif [ "$ACTION" = "install" ]; then
	# installing prometheus
	helm upgrade --install $cfg__monitoring__prometheus__release \
	--namespace $cfg__project__k8s_namespace \
	-f $file_folder/$cfg__monitoring__prometheus__config_file \
	stable/prometheus

	# installing grafana
	helm upgrade --install $cfg__monitoring__grafana__release \
	--namespace $cfg__project__k8s_namespace \
	-f $file_folder/$cfg__monitoring__grafana__config_file \
	stable/grafana

else
	helm delete $cfg__monitoring__prometheus__release --purge
	helm delete $cfg__monitoring__grafana__release --purge
fi
