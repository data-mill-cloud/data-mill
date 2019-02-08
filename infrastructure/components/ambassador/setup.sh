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
	helm repo add datawire https://www.getambassador.io/helm
	# https://medium.com/devopslinks/how-to-create-an-api-gateway-using-ambassador-on-kubernetes-95f181904ff7
	# https://www.getambassador.io/user-guide/helm
	# https://github.com/datawire/ambassador/tree/master/helm/ambassador
	helm repo update
	helm upgrade $cfg__ambassador__release datawire/ambassador \
	 --namespace $cfg__project__k8s_namespace \
	 --values $file_folder/$cfg__ambassador__config_file \
	 --install --force --wait

	echo "Diagnostics available at http://"$(kubectl get svc -n=$cfg__project__k8s_namespace $cfg__ambassador__release | awk 'FNR > 1 { print $3 }')"/$cfg__ambassador__release/v0/diag/"
	helm repo remove datawire
else
	helm delete $cfg__ambassador__release --purge
fi
