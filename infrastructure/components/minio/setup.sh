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
	# deploying minio to k8s
	random_key=$(get_random_string_key 32)
	random_secret=$(get_random_secret_key)
	# debug only, to be removed
	#echo "Starting Minio with:"
	#echo "- KEY:$random_key"
	#echo "- SECRET:$random_secret"

	# https://github.com/helm/charts/tree/master/stable/minio#configuration
	helm upgrade $cfg__minio__release stable/minio \
	 --namespace $cfg__project__k8s_namespace \
	 --values $file_folder/$cfg__minio__config_file \
	 --set accessKey=$random_key,secretKey=$random_secret,persistence.storageClass=$cfg__minio__storage_class \
	 --recreate-pods \
	 --install --force $( [ ! -z $cfg__minio__setup_timeout ] && [ $cfg__minio__setup_timeout -gt 0 ] && printf %s "--timeout $cfg__minio__setup_timeout --wait" )
	unset random_key
	unset random_secret

	# copy code examples to minio pod
	$(minio_create_bucket $cfg__project__k8s_namespace $cfg__minio__release $cfg__project__data_folder "examples")
else
	helm delete $cfg__minio__release --purge
fi
