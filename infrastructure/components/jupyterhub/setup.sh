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
	# build the datascience image
	if [ "$cfg__jhub__ds_image__use_local_image" = true ];then
		folder_name=`basename $cfg__jhub__ds_image__name`
		echo "Building $cfg__jhub__ds_image__name:$cfg__jhub__ds_image__tag from $file_folder/ds_environments/$folder_name/Dockerfile"
		eval $(minikube docker-env)
		docker build -t $cfg__jhub__ds_image__name:$cfg__jhub__ds_image__tag -f $file_folder/ds_environments/$folder_name/Dockerfile .
		unset folder_name
	else
		echo "Using community image $cfg__jhub__ds_image__name:$cfg__jhub__ds_image__tag"
	fi

	# following https://z2jh.jupyter.org/en/stable/setup-jupyterhub.html
	helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
	helm repo update
	secretToken=$(get_random_secret_key)
	echo "JupyterHub secret token: $secretToken"
	helm upgrade $cfg__jhub__release jupyterhub/jupyterhub \
	  --namespace $cfg__project__k8s_namespace \
	  --version $cfg__jhub__version \
	  --values $file_folder/$cfg__jhub__config_file \
	  --set proxy.secretToken=$secretToken,singleuser.image.name=$cfg__jhub__ds_image__name,singleuser.image.tag=$cfg__jhub__ds_image__tag \
	  --install --force
	#--timeout $cfg__jhub__setup_timeout -- wait
	unset secretToken
else
	helm delete $cfg__jhub__release --purge
fi
