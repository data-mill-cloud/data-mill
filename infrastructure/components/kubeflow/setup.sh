#!/usr/bin/env bash

fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
file_folder=$(dirname $fullpath)

# load local yaml config
# if -f was given and the file exists use it, otherwise fallback to the specified component default config
COMPONENT_CONFIG=$(file_exists "$file_folder/$CONFIG_FILE" "$file_folder/$cfg__project__component_default_config")
eval $(parse_yaml $COMPONENT_CONFIG "cfg__")

# use if set or a string argument otherwise
ACTION=${ACTION:=$1}

# Kubeflow global details (to both install and delete)
KUBEFLOW_TAG=${cfg__kubeflow__kubeflow_tag:=$(get_latest_github_release "kubeflow/kubeflow")}
KUBEFLOW_SRC="${file_folder}/${cfg__kubeflow__src_subfolder}/${KUBEFLOW_TAG}"
KUBEFLOW_CONFIG="${file_folder}/${cfg__kubeflow__conf_subfolder}/${KUBEFLOW_TAG}"

# kubeflow uses env vars to pass information to kfctl
# use a specific namespace if defined, or otherwise the project namespace
export K8S_NAMESPACE=${cfg__kubeflow__k8s_namespace:=$cfg__project__k8s_namespace}
echo "kubeflow namespace: "$K8S_NAMESPACE

if [ -z "$ACTION" ] || [ "$ACTION" != "install" ] && [ "$ACTION" != "delete" ];then
        echo "usage: $0 {'install' | 'delete'}";
        exit 1
elif [ "$ACTION" = "install" ]; then
	# https://www.kubeflow.org/docs/started/getting-started-gke/#understanding-the-deployment-process
	# The deployment process is controlled by 4 different commands:
	# - init - one time setup.
	# - generate - creates config files defining the various resources.
	# - apply - creates or updates the resources.
	# - delete - deletes the resources.
	# Except init, all commands take an argument which describes the set of resources to apply the command to
	# i.e., platform, k8s, all
	# install ksonnet if not available
	command -v ks >/dev/null 2>&1 \
	&& { echo "ksonnet is already installed"; } \
	|| {
		# use version if specified in the config, or latest otherwise
		KS_VER=${cfg__kubeflow__ksonnet_tag:=$(get_latest_github_release "ksonnet/ksonnet")}
		# remove the v char from the tag name
		KS_VER="${KS_VER:1:${#KS_VER}}"
		echo "Installing ksonnet $KS_VER, latest tag released is "$(get_latest_github_release "ksonnet/ksonnet")
		wget https://github.com/ksonnet/ksonnet/releases/download/v${KS_VER}/ks_${KS_VER}_linux_amd64.tar.gz -O ksonnet.tar.gz
		mkdir -p ksonnet && tar -xvf ksonnet.tar.gz -C ksonnet --strip-components=1
		# move ks binary to bin folder
		sudo cp ksonnet/ks /usr/local/bin
		# remove local ksonnet folder
		rm -fr ksonnet
		rm ksonnet.tar.gz
	}

	# download iff the folder with the code for the version is not already available locally
	if [ ! -d "${KUBEFLOW_SRC}" ]; then
		echo "Creating folder ${cfg__kubeflow__src_subfolder}/${KUBEFLOW_TAG}"
                mkdir -p ${KUBEFLOW_SRC}
		echo "Creating folder ${cfg__kubeflow__conf_subfolder}/${KUBEFLOW_TAG}"
		mkdir -p ${KUBEFLOW_CONFIG}
		# downloading kubeflow project in the source folder
	        cd ${KUBEFLOW_SRC}
		echo "Downloading kubeflow ${KUBEFLOW_TAG:1:${#KUBEFLOW_TAG}}, latest tag released is "$(get_latest_github_release "kubeflow/kubeflow")
		curl https://raw.githubusercontent.com/kubeflow/kubeflow/${KUBEFLOW_TAG}/scripts/download.sh | bash
	fi

	# initialize kubeflow for the specific target platform
	# looking at kfctl.h, the script expects platform in minikube, ack, gcp (which sets up gke) and * (whatever)
	if [ "$cfg__local__provider" = "minikube" ]; then
		${KUBEFLOW_SRC}/scripts/kfctl.sh init ${KUBEFLOW_CONFIG} --platform minikube
	else
		${KUBEFLOW_SRC}/scripts/kfctl.sh init ${KUBEFLOW_CONFIG}
	fi

	cd ${KUBEFLOW_CONFIG}
	# install kubeflow
	${KUBEFLOW_SRC}/scripts/kfctl.sh generate all
	${KUBEFLOW_SRC}/scripts/kfctl.sh apply all
else
	# delete kubeflow
	echo "Deleting kubeflow resources"
	cd ${KUBEFLOW_CONFIG}
	${KUBEFLOW_SRC}/scripts/kfctl.sh delete all
	# remove config and source code folders
	rm -rf ${KUBEFLOW_CONFIG}
	rm -rf ${KUBEFLOW_SRC}
fi
