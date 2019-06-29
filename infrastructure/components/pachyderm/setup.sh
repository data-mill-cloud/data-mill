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
	if [ "$cfg__pachyderm__datalake__type" = "minio" ]; then
		ACCESS_KEY=$(kubectl -n $cfg__project__k8s_namespace get secrets $cfg__pachyderm__datalake__minio_release -o jsonpath="{.data.accesskey}" | base64 -d)
		SECRET_KEY=$(kubectl -n $cfg__project__k8s_namespace get secrets $cfg__pachyderm__datalake__minio_release -o jsonpath="{.data.secretkey}" | base64 -d)
		#ENDPOINT=$(kubectl -n $cfg__project__k8s_namespace  get endpoints $cfg__pachyderm__datalake__minio_release | awk 'NR==2 {print $2}')
		ENDPOINT="${cfg__pachyderm__datalake__minio_release}:9000"

		# before installing pachyderm, make sure a bucket named $cfg__pachyderm__bucket is available on minio
		#echo $(datalake_run_command "$cfg__project__k8s_namespace" "mc config host add minio http://$cfg__pachyderm__datalake__minio_release:9000 $ACCESS_KEY $SECRET_KEY --api S3v4 && mc mb minio/$cfg__pachyderm__datalake__bucket --ignore-existing")
		$(minio_create_bucket $cfg__project__k8s_namespace $cfg__pachyderm__datalake__minio_release $cfg__project__data_folder $cfg__pachyderm__datalake__bucket)
		echo "Set minio bucket $cfg__pachyderm__datalake__bucket"
	else
		ACCESS_KEY=$cfg__pachyderm__datalake__access_key
		SECRET_KEY=$cfg__pachyderm__datalake__secret_key
		ENDPOINT=$cfg__pachyderm__datalake__endpoint
		# e.g. ENDPOIND=http://hosted-minio.com:9000
		echo $(datalake_run_command "$cfg__project__k8s_namespace" "mc config host add dl $ENDPOINT $ACCESS_KEY $SECRET_KEY --api S3v4 && mc mb dl/$cfg__pachyderm__datalake__bucket --ignore-existing")
	fi

	echo "Pachyderm set to use dalake $cfg__pachyderm__datalake__type"

	# https://hub.helm.sh/charts/stable/pachyderm
	# --version $cfg__pachyderm__version
	helm upgrade $cfg__pachyderm__release stable/pachyderm \
	 --namespace $cfg__project__k8s_namespace \
	 --values $(get_values_file "$cfg__pachyderm__config_file") \
	 --set s3.accessKey=$ACCESS_KEY,s3.secretKey=$SECRET_KEY,s3.bucketName=$cfg__pachyderm__datalake__bucket,s3.endpoint=$ENDPOINT \
	 --recreate-pods \
	 --install --force
else
	helm delete $cfg__pachyderm__release --purge
fi
