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
	ffdl_version=$(get_latest_github_release 'IBM/FfDL')
	ffdl_version=${cfg__ffdl__version:-$ffdl_version}
	if [ -z $ffdl_version ]; then
		echo "no version defined for ffdl, nor latest version is available on repo"
		exit 1
	else
		ffdl_url="https://github.com/IBM/FfDL/archive/${ffdl_version}.tar.gz"
		echo "installing ffdl release "$ffdl_version" from "$ffdl_url
		wget $ffdl_url --directory-prefix=$file_folder
		tar -zxvf "${file_folder}/${ffdl_version}.tar.gz" -C ${file_folder}
		rm "${file_folder}/${ffdl_version}.tar.gz"

		# https://github.com/IBM/FfDL/blob/master/docs/detailed-installation-guide.md
		export FFDL_PATH="${file_folder}/FfDL-${ffdl_version:1}"
		default_storage_class=$(get_default_storage_class)
		export SHARED_VOLUME_STORAGE_CLASS=${cfg__ffdl__shared_volume_storage_class:-$default_storage_class}
		export VM_TYPE=none
		export PUBLIC_IP=${cfg__project__public_ip:-localhost}
		export NAMESPACE=${cfg__ffdl__namespace:-$cfg__project__k8s_namespace}

		# installing storage plugin (where is this??)
		helm install storage-plugin --set namespace=$NAMESPACE

		. ${FFDL_PATH}/bin/create_static_volumes.sh
		. $FFDL_PATH/bin/create_static_volumes_config.sh
		helm install $FFDL_PATH --set lcm.shared_volume_storage_class=$SHARED_VOLUME_STORAGE_CLASS,namespace=$NAMESPACE

		# start the monitoring grafana dashboard
		. ${FFDL_PATH}/bin/grafana.init.sh
		grafana_port=$(kubectl get svc grafana -o jsonpath='{.spec.ports[0].nodePort}')
		ui_port=$(kubectl get svc ffdl-ui -o jsonpath='{.spec.ports[0].nodePort}')
		restapi_port=$(kubectl get svc ffdl-restapi -o jsonpath='{.spec.ports[0].nodePort}')
		s3_port=$(kubectl get svc s3 -o jsonpath='{.spec.ports[0].nodePort}')
		echo "Monitoring dashboard: http://$PUBLIC_IP:$grafana_port/ (login: admin/admin)"
		echo "Web UI: http://$PUBLIC_IP:$ui_port/#/login?endpoint=$node_ip:$restapi_port&username=test-user"
	fi

else
	echo "deleting ffdl"
	helm ls | grep $cfg__ffdl__release | awk '{print $1}' | xargs -L1 helm delete --purge
fi
