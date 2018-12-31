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
	helm repo update

	# installing prometheus
	helm upgrade $cfg__monitoring__prometheus__release stable/prometheus \
	--namespace $cfg__project__k8s_namespace \
	--values $file_folder/$cfg__monitoring__prometheus__config_file \
	--install --force

	random_secret=$(get_random_secret_key)
	echo "Installing Grafana: admin/$random_secret"
	# installing grafana
	helm upgrade $cfg__monitoring__grafana__release stable/grafana \
	--namespace $cfg__project__k8s_namespace \
	--values $file_folder/$cfg__monitoring__grafana__config_file \
	--set adminUser:admin,adminPassword:$random_secret \
	--install --force
	unset random_secret
else
	helm delete $cfg__monitoring__prometheus__release --purge
	helm delete $cfg__monitoring__grafana__release --purge
fi
