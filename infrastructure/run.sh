#!/usr/bin/env bash

rootpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
root_folder=$(dirname $rootpath)

# include common functions from utils
for filename in $root_folder/utils/*.sh; do
    . $filename
done

# we fetch the default config, unless specified differently in the CONFIG_FILE variable (-f)
CONFIG_FILE=${CONFIG_FILE:="default.yaml"}
# make sure we only get the filename and not a path (for error or simplicity passed in)
CONFIG_FILE=$(basename "$CONFIG_FILE")
echo "Using config at $root_folder/flavours/$CONFIG_FILE"

# include global configs
eval $(parse_yaml "$root_folder/flavours/$CONFIG_FILE" "cfg__")

# for debugging config var names:
#( set -o posix ; set ) | more
#exit 1

declare -a flavour;
if [ -z "$cfg__project__flavour" ] || [ "$cfg__project__flavour" = "all" ]; then
	flavour=($(ls $root_folder/components))
	echo "Using all components ${flavour[@]}"
else
	# read the list of components to include in "${flavour[@]}"
	IFS=', ' read -r -a flavour <<< "$cfg__project__flavour"
	echo "Using user-defined flavour: ${flavour[@]}"
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
	# start an interactive session using busybox in the cluster namespace
	debugging_pod_name="debugging-pod-"$(date '+%d-%m-%Y--%H-%M-%S')
	#--image=busybox
	kubectl run -it $debugging_pod_name \
	--image=ubuntu \
	--restart=Never --namespace=$cfg__project__k8s_namespace --env="POD_NAMESPACE=$cfg__project__k8s_namespace"
	echo "Terminating Debug Pod.."
	kubectl delete pod $debugging_pod_name -n=$cfg__project__k8s_namespace
elif [ "$ACTION" = "start" ]; then
	# just start K8s
	. $root_folder/k8s/setup.sh
	# show installed components
	helm ls
	# connect proxy
	# start proxy to connect to K8s API
        echo "Please access K8s UI at: http://localhost:$cfg__project__proxy_port/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/"
        kubectl proxy --port=$cfg__project__proxy_port #&

elif [[ "$ACTION" = "install" || "$ACTION" = "delete" ]]; then
	if [ "$ACTION" = "install" ]; then
		# 1. ******** Setup K8s ********
		. $root_folder/k8s/setup.sh
	fi

	# run ACTION on modules of the K8s cluster
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

	if [ "$ACTION" = "install" ]; then
		# show deployed services
		helm ls

		# start proxy to connect to K8s API
		#echo "Please access K8s UI at: http://localhost:$cfg__project__proxy_port/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/"
		#kubectl proxy --port=$cfg__project__proxy_port #&
	else
		# delete the namespace only if we removed all components
        	if [ -z "$COMPONENT" ]; then
                	kubectl delete namespace $cfg__project__k8s_namespace
	        fi
	fi
else
	echo "ACTION should be either debug, install or delete"
fi
