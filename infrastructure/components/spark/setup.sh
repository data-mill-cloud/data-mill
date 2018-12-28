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
	# https://github.com/GoogleCloudPlatform/spark-on-k8s-operator
	helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
	helm upgrade --install $cfg__spark__release \
	 --namespace $cfg__project__k8s_namespace \
	 -f $file_folder/$cfg__spark__config_file incubator/sparkoperator
else
	helm delete $cfg__spark__release --purge
fi
