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
	#sed -e "s/release-name/${cfg__grafana__release}/g" \
	# -e "s/k8s-namespace/${cfg__project__k8s_namespace}/g" \
	#$file_folder/${cfg__grafana__config_file/.yaml/_template.yaml} > $file_folder/$cfg__grafana__config_file

	helm upgrade $cfg__grafana__release stable/grafana \
	 --namespace $cfg__project__k8s_namespace \
	 --values $file_folder/$cfg__grafana__config_file \
	 --install --force

	#rm $file_folder/$cfg__grafana__config_file
else
	helm delete $cfg__grafana__release --purge
fi
