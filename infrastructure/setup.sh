#!/usr/bin/env bash

rootpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
root_folder=$(dirname $rootpath)

# include common functions from utils
for filename in $root_folder/utils/*.sh; do
    . $filename
done

# include global configs
eval $(parse_yaml $root_folder/config.yaml "cfg__")

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

# 1. setup K8s cluster
. $root_folder/k8s/setup.sh $LOCATION

# 2. setup modules on the K8s cluster
for component in $root_folder/components/*; do
	setup_component="$component/setup.sh"
	if [ -e "$setup_component" ]; then
		echo "Running $ACTION for $setup_component";
		. $setup_component $ACTION
	else
		echo "$setup_component unavailable. Skipping!"
	fi
done

# show deployed services
helm ls

# start proxy to connect to K8s API
if [ $ACTION = "install" ]; then
	echo "Please access K8s UI at: http://localhost:$cfg__project__proxy_port/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/"
	kubectl proxy --port=$cfg__project__proxy_port #&
fi
