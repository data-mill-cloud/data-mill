#!/usr/bin/env bash

fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
file_folder=$(dirname $fullpath)

# load local yaml config
COMPONENT_CONFIG=$(file_exists $file_folder/$CONFIG_FILE $file_folder/"config.yaml")
eval $(parse_yaml $COMPONENT_CONFIG "cfg__")

# use if set or a string argument otherwise
ACTION=${ACTION:=$1}

if [ -z "$ACTION" ] || [ "$ACTION" != "install" ] && [ "$ACTION" != "delete" ];then
    echo "usage: $0 {'install' | 'delete'}";
    exit 1
elif [ "$ACTION" = "install" ]; then
    latest_arangodb=$(get_latest_github_release "arangodb/kube-arangodb")
    echo "installing $cfg__arangodb__release $latest_arangodb operator"
    # The following will install the custom resources required by the operators.
    helm upgrade --namespace $cfg__project__k8s_namespace --install --force  ${cfg__arangodb__release}-crd https://github.com/arangodb/kube-arangodb/releases/download/$latest_arangodb/kube-arangodb-crd.tgz
    # The following will install the operator for `ArangoDeployment`
    helm upgrade --namespace $cfg__project__k8s_namespace --install --force  $cfg__arangodb__release https://github.com/arangodb/kube-arangodb/releases/download/$latest_arangodb/kube-arangodb.tgz
    # installing ArangoDB server
    kubectl apply -n $cfg__project__k8s_namespace -f components/arangodb/$cfg__arangodb__mode.yaml
    echo "execute: "kubectl -n $cfg__project__k8s_namespace port-forward svc/""$cfg__arangodb__release"-"$cfg__arangodb__mode 8529""
    echo "Then access UI: https://localhost:8529"

else
    helm delete --purge $cfg__arangodb__release
    helm delete --purge ${cfg__arangodb__release}-crd
fi
