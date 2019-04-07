#!/usr/bin/env bash

# load component paths
eval $(get_paths)
# load local yaml config
eval $(get_component_config)

# use if set or a string argument otherwise
ACTION=${ACTION:=$1}

NIFI_CRD="https://raw.githubusercontent.com/b23llc/nifi-fn-operator/master/config/crds/nififn_v1alpha1_nififn.yaml"
NIFI_OPERATOR="https://raw.githubusercontent.com/b23llc/nifi-fn-operator/master/config/deploy/nifi-fn-operator.yaml"
NIFI_REGISTRY="https://raw.githubusercontent.com/b23llc/nifi-fn-operator/master/config/deploy/nifi.yaml"

if [ -z "$ACTION" ] || [ "$ACTION" != "install" ] && [ "$ACTION" != "delete" ];then
        echo "usage: $0 {'install' | 'delete'}";
        exit 1
elif [ "$ACTION" = "install" ]; then
	# install CRDs
	kubectl apply -f $NIFI_CRD
	# install nifi operator
	kubectl apply -f $NIFI_OPERATOR
	# add the nifi registry if required
	if [ $cfg__nifi__deploy_registry = true ]; then
		#kubectl apply --namespace=$cfg__project__k8s_namespace -f $NIFI_REGISTRY
		kubectl apply -f $NIFI_REGISTRY
	fi
else
	# if used, remove nifi registry
	if [ $cfg__nifi__deploy_registry = true ]; then
                #kubectl delete --namespace=$cfg__project__k8s_namespace -f $NIFI_REGISTRY
		kubectl delete -f $NIFI_REGISTRY
        fi
	# remove the nifi operator
	kubectl delete -f $NIFI_OPERATOR
	# removing nifi operator, CRD
	kubectl delete -f $NIFI_CRD
fi
