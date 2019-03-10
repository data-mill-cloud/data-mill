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
	# https://strimzi.io/quickstarts/minikube/
	# install strimzi operator
	helm repo add strimzi http://strimzi.io/charts/

        helm upgrade $cfg__kafka__release strimzi/strimzi-kafka-operator \
         --namespace $cfg__project__k8s_namespace \
         --install --force --wait
	# --values $(get_values_file "$cfg__kafka__config_file")

	# install kafka resource using the operator
	if [ ! -z $cfg__kafka__deployment_file ]; then
		echo "Deploying Kafka cluster: $cfg__kafka__release"
		sed -e "s/my-cluster/$cfg__kafka__release/" $(get_values_file "$cfg__kafka__deployment_file") | kubectl apply --namespace=$cfg__project__k8s_namespace -f -
	fi

	# remove strimzi repo
	helm repo remove strimzi
else
	# remove strimzi resource if deployed
	# cancel the kafka cluster if set in the component config
	if [ ! -z $cfg__kafka__deployment_file ]; then
		echo "Deleting Kafka cluster: $cfg__kafka__release"
		sed -e "s/my-cluster/$cfg__kafka__release/" $(get_values_file "$cfg__kafka__deployment_file") | kubectl delete --namespace=$cfg__project__k8s_namespace -f -
	fi

        # remove kafka operator
        helm delete --purge $cfg__kafka__release
fi
