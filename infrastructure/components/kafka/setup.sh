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

	# https://docs.confluent.io/current/installation/installing_cp/cp-helm-charts/docs/index.html
	helm repo add confluent https://confluentinc.github.io/cp-helm-charts/
	helm repo update

	# confluent kafka
	helm upgrade $cfg__kafka__release confluent/cp-helm-charts \
	 --namespace $cfg__project__k8s_namespace \
	 --values $file_folder/$cfg__kafka__config_file \
	 --install --force

	# kafka manager
	echo "helm upgrade $cfg__kmanager__release stable/kafka-manager --namespace $cfg__project__k8s_namespace --values $file_folder/$cfg__kmanager__config_file --install --force"
        helm upgrade $cfg__kmanager__release stable/kafka-manager \
         --namespace $cfg__project__k8s_namespace \
         --values $file_folder/$cfg__kmanager__config_file \
	 --install --force --debug

	# test the deployment
	helm test $cfg__kafka__release

	# producer test
	echo "Producer test:"
	echo "kubectl exec -c cp-kafka-broker -it $cfg__kafka__release""-cp-kafka-0 -- /bin/bash /usr/bin/kafka-console-producer --broker-list localhost:9092 --topic test"

	# consumer test
	echo "Consumer test:"
	echo "kubectl exec -c cp-kafka-broker -it $cfg__kafka__release""-cp-kafka-0 -- /bin/bash /usr/bin/kafka-console-consumer --bootstrap-server localhost:9092 --topic test --from-beginning"

	echo "Deploy a client Pod for test purposes: https://docs.confluent.io/current/installation/installing_cp/cp-helm-charts/docs/index.html#kafka"
	# kubectl apply -f cp-helm-charts/examples/kafka-client.yaml
	# kubectl exec -it kafka-client -- /bin/bash
else
	helm delete $cfg__kafka__release --purge
	helm delete $cfg__kmanager__release --purge
fi
