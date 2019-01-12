#!/usr/bin/env bash

fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
file_folder=$(dirname $fullpath)

# load local yaml config
# if -f was given and the file exists use it, otherwise fallback to the specified component default config
COMPONENT_CONFIG=$(file_exists "$file_folder/$CONFIG_FILE" "$file_folder/$cfg__project__component_default_config")
eval $(parse_yaml $COMPONENT_CONFIG "cfg__")

# use if set or a string argument otherwise
ACTION=${ACTION:=$1}

if [ -z "$ACTION" ] || [ "$ACTION" != "install" ] && [ "$ACTION" != "delete" ];then
        echo "usage: $0 {'install' | 'delete'}";
        exit 1
elif [ "$ACTION" = "install" ]; then
	MINIO_ACCESS_KEY=$(kubectl -n $cfg__project__k8s_namespace get secrets $cfg__pachyderm__minio -o jsonpath="{.data.accesskey}" | base64 -d)
	MINIO_SECRET_KEY=$(kubectl -n $cfg__project__k8s_namespace get secrets $cfg__pachyderm__minio -o jsonpath="{.data.secretkey}" | base64 -d)
	MINIO_ENDPOINT=$(kubectl -n $cfg__project__k8s_namespace  get endpoints $cfg__pachyderm__minio | awk 'NR==2 {print $2}')
	# before installing pachyderm, make sure a bucket named $cfg__pachyderm__bucket is available on minio
	echo $(datalake_run_command "$cfg__project__k8s_namespace" "mc config host add minio http://minio-datalake:9000 $MINIO_ACCESS_KEY $MINIO_SECRET_KEY --api S3v4 && mc mb minio/$cfg__pachyderm__bucket --ignore-existing")

	# https://hub.helm.sh/charts/stable/pachyderm
	helm upgrade $cfg__pachyderm__release stable/pachyderm \
	 --version $cfg__pachyderm__version \
	 --namespace $cfg__project__k8s_namespace \
	 --values $file_folder/$cfg__pachyderm__config_file \
	 --set s3.accessKey=$MINIO_ACCESS_KEY,s3.secretKey=$MINIO_SECRET_KEY,s3.bucketName=$cfg__pachyderm__bucket,s3.endpoint=$MINIO_ENDPOINT \
	 --install --force
else
	helm delete $cfg__pachyderm__release --purge
fi
