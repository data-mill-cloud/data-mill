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

        # creating the PVC for mlflow
        $(find_by_volume_name_and_create $cfg__project__k8s_namespace "$file_folder/volumes/pvc/*" $cfg__mlflow__pvc_name "pvc")
        kubectl get pvc $cfg__mlflow__pvc_name -n=$cfg__project__k8s_namespace

	# check if the artifact store is supposed to use a local S3 or AWS S3
	if [ "$cfg__mlflow__artifact_store__type" = "minio" ]; then
                ACCESS_KEY=$(kubectl -n $cfg__project__k8s_namespace get secrets $cfg__mlflow__artifact_store__minio_release -o jsonpath="{.data.accesskey}" | base64 -d)
                SECRET_KEY=$(kubectl -n $cfg__project__k8s_namespace get secrets $cfg__mlflow__artifact_store__minio_release -o jsonpath="{.data.secretkey}" | base64 -d)
                ENDPOINT="http://${cfg__mlflow__artifact_store__minio_release}:9000"
		echo $(datalake_run_command "$cfg__project__k8s_namespace" "mc config host add dl $ENDPOINT $ACCESS_KEY $SECRET_KEY --api S3v4 && mc mb dl/$cfg__pachyderm__datalake__bucket --ignore-existing")

                echo "Set minio bucket $cfg__mlflow__artifact_store__bucket"
        else
                ACCESS_KEY=$cfg__mlflow__artifact_store__access_key
                SECRET_KEY=$cfg__mlflow__artifact_store__secret_key
                ENDPOINT=$cfg__mlflow__artifact_store__endpoint
                # e.g. ENDPOIND=http://hosted-minio.com:9000
                echo $(datalake_run_command "$cfg__project__k8s_namespace" "mc config host add dl $ENDPOINT $ACCESS_KEY $SECRET_KEY --api S3v4 && mc mb dl/$cfg__pachyderm__datalake__bucket --ignore-existing")
        fi

        echo "Mlflow set to use artifact store $cfg__mlflow__artifact_store__type"


	# adding and updating repo and helm chart
	helm repo add data-mill https://data-mill-cloud.github.io/data-mill/helm-charts/
	helm repo update

	helm upgrade $cfg__mlflow__release data-mill/mlflow \
         --namespace $cfg__project__k8s_namespace \
         --values $(get_values_file "$cfg__mlflow__config_file") \
	 --set server.artifacturi="s3://:5000/mlflow"
         --install --force
else
        helm delete $cfg__mlflow__release --purge
fi
