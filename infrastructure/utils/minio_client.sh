
# this is a more general purpose way to, e.g. create buckets, on a datalake
datalake_run_command(){
	namespace=$1
	command=$2
	command=$(echo $command | sed -e 's/[\/&]/\\&/g' )
	#echo $command

	dd=$(date '+%d-%m-%Y--%H-%M-%S')
	pod_name="sh-pod-"$dd
	container_name="sh-container-"$dd
	deployment_file="mc_pod_deployment.yaml"

	# https://kubernetes.io/docs/tasks/debug-application-cluster/determine-reason-pod-failure/#writing-and-reading-a-termination-message
	sed -e "s/pod-name/${pod_name}/g" -e "s/container-name/${container_name}/g" -e "s/container-command/${command}/g" $root_folder/utils/$deployment_file | kubectl create --namespace=$namespace -f -
	#kubectl describe pod $pod_name -n=$namespace
	#kubectl wait --for=condition=Completed pod/$pod_name -n=$namespace
	# the kubectl wait gave lots of issues, so good old bash will quickly do the job
	until [ $(kubectl get pods $pod_name -n=$namespace | awk 'FNR>1 {print $3}') = "Complete" ]; do sleep 3; done
	kubectl delete pod $pod_name -n=$namespace
}

# this is to be used for minio only
minio_create_bucket(){
	namespace=$1
	minio_release=$2
	data_folder=$3
	bucket_name=$4

	# create a folder in our data folder
	mkdir -p $root_folder/$data_folder/$bucket_name
	# copy folder into minio pod
        MINIO_POD_NAME=$(kubectl get pods --namespace $namespace -l "release=$minio_release" -o jsonpath="{.items[0].metadata.name}")
        #echo "waiting for pod $MINIO_POD_NAME to be up and running"
        kubectl wait -n $namespace  --for=condition=Ready --timeout=600s pod $MINIO_POD_NAME > /dev/null 2>&1
        #echo "copying data to $MINIO_POD_NAME pod into /export folder"
        kubectl -n $namespace cp $root_folder/$data_folder/$bucket_name/ ${MINIO_POD_NAME}:/export
}
