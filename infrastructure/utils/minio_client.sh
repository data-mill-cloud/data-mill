

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
	#kubectl delete pod $pod_name -n=$namespace
}
