#!/usr/bin/env bash

# load component paths
eval $(get_paths)
# load local yaml config
eval $(get_component_config)

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
	  --values $(get_values_file "$cfg__jhub__config_file") \
	  --set proxy.secretToken=$secretToken \
	  --install --force $( [ ! -z $cfg__jhub__setup_timeout ] && [ $cfg__jhub__setup_timeout -gt 0 ] && printf %s "--timeout $cfg__jhub__setup_timeout --wait" )
	unset secretToken
	helm repo remove jupyterhub
else
	helm delete $cfg__jhub__release --purge
fi
