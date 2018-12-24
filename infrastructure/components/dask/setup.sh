#!/usr/bin/env bash

fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
file_folder=$(dirname $fullpath)

# load local yaml config
eval $(parse_yaml $file_folder/config.yaml "cfg__")

if [ -z "$1" ] || [ "$1" != "install" ] && [ "$1" != "delete" ];then
	echo "usage: $0 {install | delete}";
	exit 1
elif [ "$1" = "install" ]; then
	helm repo update
	helm upgrade --install $cfg__dask__release \
	 --namespace $cfg__project__k8s_namespace \
	 -f $file_folder/$cfg__dask__config_file stable/dask
else
	helm delete $cfg__dask__release --purge
fi
