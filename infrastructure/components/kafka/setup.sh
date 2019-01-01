#!/usr/bin/env bash

#set -ex

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

	# https://strimzi.io/quickstarts/minikube/
	helm repo add strimzi http://strimzi.io/charts/ 
    helm install strimzi/strimzi-kafka-operator --name $cfg__kafka__release --namespace $cfg__project__k8s_namespace
	latest_strimzi=$(get_latest_github_release "strimzi/strimzi-kafka-operator")
	kubectl apply -f https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/$latest_strimzi/examples/kafka/kafka-persistent.yaml \
	 --namespace $cfg__project__k8s_namespace

else
    helm delete --purge $cfg__kafka__release
	kubectl delete -f https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/$latest_strimzi/examples/kafka/kafka-persistent.yaml \
	 --namespace $cfg__project__k8s_namespace
fi
