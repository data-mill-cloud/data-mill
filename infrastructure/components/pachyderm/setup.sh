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
	if [ "$cfg__pachyderm__datalake__type" = "minio" ]; then
		ACCESS_KEY=$(kubectl -n $cfg__project__k8s_namespace get secrets $cfg__pachyderm__datalake__minio_release -o jsonpath="{.data.accesskey}" | base64 -d)
		SECRET_KEY=$(kubectl -n $cfg__project__k8s_namespace get secrets $cfg__pachyderm__datalake__minio_release -o jsonpath="{.data.secretkey}" | base64 -d)
		ENDPOINT=$(kubectl -n $cfg__project__k8s_namespace  get endpoints $cfg__pachyderm__datalake__minio_release | awk 'NR==2 {print $2}')

		# before installing pachyderm, make sure a bucket named $cfg__pachyderm__bucket is available on minio
		#echo $(datalake_run_command "$cfg__project__k8s_namespace" "mc config host add minio http://$cfg__pachyderm__datalake__minio_release:9000 $ACCESS_KEY $SECRET_KEY --api S3v4 && mc mb minio/$cfg__pachyderm__datalake__bucket --ignore-existing")
		$(minio_create_bucket $cfg__project__k8s_namespace $cfg__pachyderm__datalake__minio_release $cfg__project__data_folder $cfg__pachyderm__datalake__bucket)
	else
		echo "Pachyderm set to use dalake $cfg__pachyderm__datalake__type"
		ACCESS_KEY=$cfg__pachyderm__datalake__access_key
		SECRET_KEY=$cfg__pachyderm__datalake__secret_key
		ENDPOINT=$cfg__pachyderm__datalake__endpoint
		# e.g. ENDPOIND=http://hosted-minio.com:9000
		echo $(datalake_run_command "$cfg__project__k8s_namespace" "mc config host add dl $ENDPOINT $ACCESS_KEY $SECRET_KEY --api S3v4 && mc mb dl/$cfg__pachyderm__datalake__bucket --ignore-existing")
	fi

	# https://hub.helm.sh/charts/stable/pachyderm
	#helm upgrade $cfg__pachyderm__release stable/pachyderm \
	# --version $cfg__pachyderm__version \
	# --namespace $cfg__project__k8s_namespace \
	# --values $file_folder/$cfg__pachyderm__config_file \
	# --set s3.accessKey=$ACCESS_KEY,s3.secretKey=$SECRET_KEY,s3.bucketName=$cfg__pachyderm__datalake__bucket,s3.endpoint=$ENDPOINT \
	# --install --force
else
	helm delete $cfg__pachyderm__release --purge
fi
