#!/usr/bin/env bash

rootpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
root_folder=$(dirname $rootpath)

# include common functions from utils
for filename in $root_folder/utils/*.sh; do
    . $filename
done

# include global configs
echo "Using config at $FLAVOUR_FILE"
eval $(parse_yaml "$FLAVOUR_FILE" "cfg__")

# set the position of the configuration files
# 1) a path is specified for all components in the flavour config as "config_folder" (1 folder with all flavours, configs in separated folders)
if [ -z $cfg__project__config_folder ]; then
	# 2) a path is not specified, so we expect all configs to be in the flavour folder (each flavour is a folder that has all configs inside)
	cfg__project__config_folder=$(dirname "$FLAVOUR_FILE")
        # 3) if the config path is not specified, nor the configs are available at the flavour folder, then use the component folder to load the configuration (distributed)
fi

# 2) make sure we passed an environment and this is defined in the loaded flavour or target file
if [[ $(is_target_env_defined "$LOCATION") = "false" ]]; then
	echo "Cluster details for location ${LOCATION} are undefined! Please check your flavour file "$(basename "$FLAVOUR_FILE")", your target file and default cluster settings."
	exit 1
fi

# 3) make sure if we passed a kubeconfig to use it
if [[ "$LOCATION" = "hybrid" ]]; then
        echo "Using existing cluster whose kube-config file is defined at ${cfg__hybrid__config}"
	export KUBECONFIG=${cfg__hybrid__config}
fi

declare -a flavour;
if [ -z "$cfg__project__flavour" ] || [ "$cfg__project__flavour" = "all" ]; then
	flavour=($(ls $root_folder/components))
	[ "$ACTION" != "debug" ] && [ -z "$COMPONENT" ] && echo "Using all components is deprecated, this would include: ${flavour[@]}"
else
	# read the list of components to include in "${flavour[@]}"
	IFS=', ' read -r -a flavour <<< "$cfg__project__flavour"
	[ "$ACTION" != "debug" ] && [ -z "$COMPONENT" ] && echo "Using user-defined flavour: ${flavour[@]}"
fi

echo ""
echo "--------"
echo ""
echo '8888888b.           888                    888b     d888 d8b 888 888 '
echo '888  "Y88b          888                    8888b   d8888 Y8P 888 888 '
echo '888    888          888                    88888b.d88888     888 888 '
echo '888    888  8888b.  888888  8888b.         888Y88888P888 888 888 888 '
echo '888    888     "88b 888        "88b        888 Y888P 888 888 888 888 '
echo '888    888 .d888888 888    .d888888 888888 888  Y8P  888 888 888 888 '
echo '888  .d88P 888  888 Y88b.  888  888        888   "   888 888 888 888 '
echo '8888888P"  "Y888888  "Y888 "Y888888        888       888 888 888 888 '
echo ""
echo "--------"
echo ""


if [ "$ACTION" = "debug" ]; then
	case $DPOD in
	net)
	  # busybox is perfect for small network troubleshooting and it is around 1 MB of size
	  debug_image="busybox";;
	app)
	  # we derive from the ubuntu:latest (~88MB) and add java, python3 and kafka clients (more complete toolkit)
	  debug_image="datamillcloud/appdebugger:0.1";;
	esac

	# start an interactive session using busybox in the cluster namespace
	debugging_pod_name="debugging-pod-"$(date '+%d-%m-%Y--%H-%M-%S')
	# run the debug docker image as a pod in the application namespace
	kubectl run -it $debugging_pod_name \
	--image=$debug_image \
	--restart=Never --namespace=$cfg__project__k8s_namespace --env="POD_NAMESPACE=$cfg__project__k8s_namespace"
	echo "Terminating Debug Pod.."
	kubectl delete pod $debugging_pod_name -n=$cfg__project__k8s_namespace
elif [ "$ACTION" = "proxy" ]; then
	# connect proxy
	# start proxy to connect to K8s API
	echo "Please access K8s UI at: http://localhost:$cfg__project__proxy_port/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/"
	kubectl proxy --port=$cfg__project__proxy_port #&

else
	# setup the k8s cluster if starting or installing a flavour
	if [[ "$ACTION" = "start" || "$ACTION" = "install" ]]; then
		# 1. ******** Setup K8s ********
		. $root_folder/k8s/setup.sh
	fi

	# skip if we only desire to start the existing cluster regardless of the flavour
	if [[ "$ACTION" = "install" || "$ACTION" = "delete" ]]; then
		# run ACTION on modules of the K8s cluster that are included in the selected flavour (-f) or component (-c)
		for c in "${flavour[@]}"; do
			if [[ -z "$COMPONENT"  || ( ! -z "$COMPONENT" &&  $c = "$COMPONENT") ]]; then
				setup_component="$root_folder/components/$c/setup.sh"
				if [ -e "$setup_component" ]; then
					echo "Running $ACTION for $setup_component";
					. $setup_component $ACTION
				else
					echo "$setup_component unavailable. Skipping!"
				fi
			fi
		done
	fi

	if [[ "$ACTION" = "start" || "$ACTION" = "install" ]]; then
		# show deployed services
		helm ls
	elif [[ "$ACTION" = "alt" || "$ACTION" = "delete" || "$ACTION" = "delete_all" ]]; then
		# delete the namespace only if we ran delete and removed all components (delete -f and not delete -c was ran) or directly delete_all
        	if [[ "$ACTION" = "delete_all" || ( "$ACTION" = "delete" && -z "$COMPONENT" ) ]]; then
                	kubectl delete namespace $cfg__project__k8s_namespace
	        fi
		# call k8s/setup to alt, or delete the cluster iff this was explicitly requested (delete_all), delete flavour has no effect
                . $root_folder/k8s/setup.sh
	fi
fi
