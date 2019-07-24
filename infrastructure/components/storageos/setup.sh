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
	helm repo add storageos https://charts.storageos.com
	helm repo update
	ST_OS_NAMESPACE=${cfg__storageos__namespace:=$cfg__project__k8s_namespace}
	helm upgrade $cfg__storageos__release storageos/storageoscluster-operator \
	 --namespace $ST_OS_NAMESPACE \
	 --version ${cfg__storageos__version:-'1.1.3'} \
	 --values $(get_values_file "$cfg__storageos__config_file") \
	 --install --force
	helm repo remove storageos
	unset ST_OS_NAMESPACE

	# add the API secret to authenticate requests
	apiUsername=$(get_random_base64_secret_key)
	apiPassword=$(get_random_base64_secret_key)
	# replace with the newly created secret and apply the resource config
	sed -e "s/api-username/${apiUsername}/g" -e "s/api-password/${apiPassword}/g" $file_folder/templates/secret.yaml | kubectl apply -f -
	unset apuUsername
	unset apiPassword
	
	# create a cluster
	sed -e "s/storageos-cluster/${cfg__storageos__cluster_name}/g" $file_folder/templates/cluster.yaml | kubectl apply -f -

	# add a storageclass if not automatically created, then set it to default if necessary
	$(kubectl get storageclass --all-namespaces | grep ${cfg__storageos__storageclass_name} >/dev/null) || {
		sed -e "s/stos-sc-name/${cfg__storageos__storageclass_name}/g" $file_folder/templates/storage_class.yaml | kubectl apply -f -
		kubectl patch storageclass fast -p '{ "metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
	}

else
	# todo: should we delete the resources first?

	# delete the operator using helm
	helm delete $cfg__storageos__release --purge
fi
