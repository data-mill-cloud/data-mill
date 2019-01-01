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
	# https://github.com/SeldonIO/seldon-core/blob/master/docs/install.md
	helm repo add seldon-charts https://storage.googleapis.com/seldon-charts
	helm repo update

	helm upgrade $cfg__seldon_crd__release seldon-charts/seldon-core-crd \
	 --namespace $cfg__project__k8s_namespace \
	 --values $file_folder/$cfg__seldon_crd__config_file \
	 --install --force

	helm upgrade $cfg__seldon__release seldon-charts/seldon-core \
         --namespace $cfg__project__k8s_namespace \
         --values $file_folder/$cfg__seldon__config_file \
         --install --force
else
        helm delete $cfg__seldon__release --purge
	helm delete $cfg__seldon_crd__release --purge
fi
