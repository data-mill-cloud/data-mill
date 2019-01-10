#!/usr/bin/env bash

fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
file_folder=$(dirname $fullpath)

# load local yaml config
COMPONENT_CONFIG=$(file_exists "$file_folder/$CONFIG_FILE" "$file_folder/config.yaml")
eval $(parse_yaml $COMPONENT_CONFIG "cfg__")

# use if set or a string argument otherwise
ACTION=${ACTION:=$1}

if [ -z "$ACTION" ] || [ "$ACTION" != "install" ] && [ "$ACTION" != "delete" ];then
        echo "usage: $0 {'install' | 'delete'}";
        exit 1
elif [ "$ACTION" = "install" ]; then
	# creating the PV for minio
	$(find_by_volume_name_and_create $cfg__project__k8s_namespace "$file_folder/volumes/pv/*" $cfg__minio__pv_name "pv")
        kubectl get pv $cfg__minio__pv_name -n=$cfg__project__k8s_namespace
	# creating the PVC for minio
	$(find_by_volume_name_and_create $cfg__project__k8s_namespace "$file_folder/volumes/pvc/*" $cfg__minio__pvc_name "pvc")
        kubectl get pvc $cfg__minio__pvc_name -n=$cfg__project__k8s_namespace

	# deploying minio to k8s
	random_key=$(get_random_string_key 32)
	random_secret=$(get_random_secret_key)
	echo "Starting Minio with:"
	echo "- KEY:$random_key"
	echo "- SECRET:$random_secret"
	echo "- Mounting Minio on PVC named $cfg__minio__pvc_name"
	# https://github.com/helm/charts/tree/master/stable/minio#configuration
	helm upgrade $cfg__minio__release stable/minio \
	 --namespace $cfg__project__k8s_namespace \
	 --values $file_folder/$cfg__minio__config_file \
	 --set accessKey=$random_key,secretKey=$random_secret,persistence.existingClaim=$cfg__minio__pvc_name \
	 --install --force
	unset random_key
	unset random_secret

	# copy code examples to minio pod
	MINIO_POD_NAME=$(kubectl get pods --namespace $cfg__project__k8s_namespace -l "release=$cfg__minio__release" -o jsonpath="{.items[0].metadata.name}")
	echo "waiting for pod $MINIO_POD_NAME to be up and running"
	kubectl wait -n data-mill  --for=condition=Ready --timeout=600s pod $MINIO_POD_NAME
	echo "copying data to $MINIO_POD_NAME pod into /export folder"
	kubectl -n $cfg__project__k8s_namespace cp data/ ${MINIO_POD_NAME}:/export
else
	helm delete $cfg__minio__release --purge
fi
