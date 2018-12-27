#!/usr/bin/env bash

fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
file_folder=$(dirname $fullpath)

# load local yaml config
eval $(parse_yaml $file_folder/config.yaml "cfg__")

# use if set or a string argument otherwise
ACTION=${ACTION:=$1}

if [ -z "$ACTION" ] || [ "$ACTION" != "install" ] && [ "$ACTION" != "delete" ];then
        echo "usage: $0 {'install' | 'delete'}";
        exit 1
elif [ "$ACTION" = "install" ]; then
	# following https://z2jh.jupyter.org/en/stable/setup-jupyterhub.html
	helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
	helm repo update
	secretToken=$(get_random_secret_key)
	echo "JupyterHub secret token: $secretToken"
	helm upgrade --install $cfg__jhub__release \
	  --namespace $cfg__project__k8s_namespace \
	  --version $cfg__jhub__version \
	  --values $file_folder/$cfg__jhub__config_file \
	  --set proxy.secretToken=$secretToken \
	  jupyterhub/jupyterhub
	unset secretToken
else
	helm delete $cfg__jhub__release --purge
fi
