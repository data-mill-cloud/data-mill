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
	helm repo update

	# adding prometheus operator crd's
	kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/alertmanager.crd.yaml
	kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheus.crd.yaml
	kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheusrule.crd.yaml
	kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/servicemonitor.crd.yaml

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
fi
