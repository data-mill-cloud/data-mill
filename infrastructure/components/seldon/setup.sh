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
        # https://docs.seldon.io/projects/seldon-core/en/latest/workflow/install.html
        helm upgrade $cfg__seldon__release seldon-core-operator \
         --namespace $cfg__project__k8s_namespace \
         --repo https://storage.googleapis.com/seldon-charts \
         --values $(get_values_file "$cfg__seldon__config_file") \
         --install --force
else
        helm delete $cfg__seldon__release --purge
fi
