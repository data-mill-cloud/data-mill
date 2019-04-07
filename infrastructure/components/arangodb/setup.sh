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
    latest_arangodb=$(get_latest_github_release "arangodb/kube-arangodb")
    echo "installing $cfg__arangodb__release $latest_arangodb operator"
    # The following will install the custom resources required by the operators.
    helm upgrade --namespace $cfg__project__k8s_namespace --install --force ${cfg__arangodb__release}-crd https://github.com/arangodb/kube-arangodb/releases/download/$latest_arangodb/kube-arangodb-crd.tgz
    # The following will install the operator for `ArangoDeployment`
    helm upgrade --namespace $cfg__project__k8s_namespace --install --force ${cfg__arangodb__release} https://github.com/arangodb/kube-arangodb/releases/download/$latest_arangodb/kube-arangodb.tgz
    # installing ArangoDB server as in $file_folder/${cfg__arangodb__mode}.yaml
    kubectl apply -n $cfg__project__k8s_namespace -f $(get_values_file "${cfg__arangodb__mode}.yaml")
else
    # delete DB definition as in $file_folder/${cfg__arangodb__mode}.yaml
    kubectl delete -n $cfg__project__k8s_namespace -f $(get_values_file "${cfg__arangodb__mode}.yaml")
    helm delete --purge ${cfg__arangodb__release}
    helm delete --purge ${cfg__arangodb__release}-crd
fi
