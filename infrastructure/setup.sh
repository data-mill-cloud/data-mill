#!/usr/bin/env bash

rootpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
root_folder=$(dirname $rootpath)

# include common functions from utils
for filename in $root_folder/utils/*.sh; do
    . $filename
done

# by default we fetch config.yaml, unless specified differently in the CONFIG_FILE variable
CONFIG_FILE=${CONFIG_FILE:="config.yaml"}
# include global configs
eval $(parse_yaml $root_folder/$CONFIG_FILE "cfg__")

# for debugging config var names:
# ( set -o posix ; set ) | more


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

# 1. ******** Setup K8s ********
. $root_folder/k8s/setup.sh $LOCATION

# 2. ******** VOLUMES ********
# 2.1 create persistent volumes on the cluster
for volume_def in $root_folder/volumes/pv/*; do
	pv_name=$(get_value $volume_def)
	# check if the volume exists (redirect stderr and stdout to black hole)
	kubectl get pv $pv_name -n=$cfg__project__k8s_namespace 2> /dev/null > /dev/null
	# if we had an error than the volume did not exist
	if [ $? -ne 0 ]; then
		echo "Creating volume named $pv_name for $volume_def"
	        kubectl create -f $volume_def -n=$cfg__project__k8s_namespace
	fi
	# show the volume info in any case now
	kubectl get pv $pv_name -n=$cfg__project__k8s_namespace
done

# 2.2 create persistent volume claims on the cluster
for volume_def in $root_folder/volumes/pvc/*; do
        pvc_name=$(get_value $volume_def)
        # check if the volume exists (redirect stderr and stdout to black hole)
        kubectl get pvc $pvc_name -n=$cfg__project__k8s_namespace 2> /dev/null > /dev/null
        # if we had an error than the volume did not exist
        if [ $? -ne 0 ]; then
                echo "Creating volume claim named $pvc_name for $volume_def"
                kubectl create -f $volume_def -n=$cfg__project__k8s_namespace
        fi
        # show the volume info in any case now
        kubectl get pvc $pvc_name -n=$cfg__project__k8s_namespace
done

# 3. ******** MODULES ********
# setup modules on the K8s cluster
. $root_folder/components/minio/setup.sh $ACTION

#for component in $root_folder/components/*; do
#	setup_component="$component/setup.sh"
#	if [ -e "$setup_component" ]; then
#		echo "Running $ACTION for $setup_component";
#		. $setup_component $ACTION
#	else
#		echo "$setup_component unavailable. Skipping!"
#	fi
#done

# show deployed services
helm ls

# start proxy to connect to K8s API
if [ $ACTION = "install" ]; then
	echo "Please access K8s UI at: http://localhost:$cfg__project__proxy_port/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/"
	#kubectl proxy --port=$cfg__project__proxy_port #&
fi
