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
	# following https://z2jh.jupyter.org/en/stable/setup-jupyterhub.html
	helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
	helm repo update
	secretToken=$(get_random_secret_key)
	echo "JupyterHub secret token: $secretToken"
	echo "Deploying JupyterHub: it might take long as the images are being pulled..."
	helm upgrade $cfg__jhub__release jupyterhub/jupyterhub \
	  --namespace $cfg__project__k8s_namespace \
	  --version $cfg__jhub__version \
	  --values $file_folder/$cfg__jhub__config_file \
	  --set proxy.secretToken=$secretToken \
	  --install --force $( [ ! -z $cfg__jhub__setup_timeout ] && [ $cfg__jhub__setup_timeout -gt 0 ] && printf %s "--timeout $cfg__jhub__setup_timeout --wait" )
	unset secretToken
else
	helm delete $cfg__jhub__release --purge
fi
