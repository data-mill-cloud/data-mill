#!/usr/bin/env bash

# load component paths
eval $(get_paths)
# load local yaml config
eval $(get_component_config)

# use if set or a string argument otherwise
ACTION=${ACTION:=$1}

PROMETHEUS_BASE_PATH="https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd"

if [ -z "$ACTION" ] || [ "$ACTION" != "install" ] && [ "$ACTION" != "delete" ];then
        echo "usage: $0 {'install' | 'delete'}";
        exit 1
elif [ "$ACTION" = "install" ]; then
	helm repo update

	# adding prometheus operator crd's
	kubectl apply -f ${PROMETHEUS_BASE_PATH}/alertmanager.crd.yaml
	kubectl apply -f ${PROMETHEUS_BASE_PATH}/prometheus.crd.yaml
	kubectl apply -f ${PROMETHEUS_BASE_PATH}/prometheusrule.crd.yaml
	kubectl apply -f ${PROMETHEUS_BASE_PATH}/servicemonitor.crd.yaml

	random_secret=$(get_random_secret_key)

	# installing prometheus operator
	helm upgrade $cfg__monitoring__release stable/prometheus-operator \
	--namespace $cfg__project__k8s_namespace \
	--set prometheusOperator.createCustomResource=false,grafana.adminPassword=$random_secret \
	--install --force

	echo "kubectl port-forward -n $cfg__project__k8s_namespace svc/""$cfg__monitoring__release-grafana 3000:80"
	echo "http://localhost:3000 admin:$random_secret"
	unset random_secret
else
	helm delete $cfg__monitoring__release --purge

	# delete CRDs
        kubectl delete -f ${PROMETHEUS_BASE_PATH}/alertmanager.crd.yaml
        kubectl delete -f ${PROMETHEUS_BASE_PATH}/prometheus.crd.yaml
        kubectl delete -f ${PROMETHEUS_BASE_PATH}/prometheusrule.crd.yaml
        kubectl delete -f ${PROMETHEUS_BASE_PATH}/servicemonitor.crd.yaml
fi
