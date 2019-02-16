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
	case $cfg__elastic__use_version in
	community)
		# install via community helm chart
		helm repo update
		helm upgrade ${cfg__elastic__release} stable/elasticsearch \
	         --namespace $cfg__project__k8s_namespace \
	         --values $file_folder/$cfg__elastic__config_file \
		 --install --force
		# --recreate-pods
		;;
	official)
		# install via official elastic image
		helm repo add elastic https://helm.elastic.co
		helm repo update
		default_storage_class=$(get_default_storage_class)
		echo "Deploying using default storage class $default_storage_class"
                helm upgrade ${cfg__elastic__release} elastic/elasticsearch \
                 --namespace $cfg__project__k8s_namespace \
                 --values $file_folder/$cfg__elastic__config_file \
		 --set volumeClaimTemplate.storageClassName=$default_storage_class \
                 --install --force
		# volumeClaimTemplate.storageClassName=standard
		unset default_storage_class
		helm repo remove elastic
		;;
	*)
		# installing using kubedb if available
		echo "Deploying using kubedb"
		command -v kubedb >/dev/null 2>&1 || {
			echo "kubedb not available. Please install kubedb dependency first"
			exit 1
		}
		# https://kubedb.com/docs/0.9.0/guides/elasticsearch/quickstart/quickstart/
		es_version="6.3-v1"
		sed -e "s/es-name/${cfg__elastic__release}/g" -e "s/es-ns/${cfg__project__k8s_namespace}/g" -e "s/es-version/${es_version}/g" $file_folder/$cfg__elastic__config_file | kubectl create --namespace=${cfg__project__k8s_namespace} -f -
		;;
	esac
else
	case $cfg__elastic__use_version in
		kubedb) echo "not implemented yet"
			#kubectl delete pod ${cfg__elastic__release} -n ${cfg__project__k8s_namespace}
			;;
		*) helm delete --purge ${cfg__elastic__release};;
	esac
fi
