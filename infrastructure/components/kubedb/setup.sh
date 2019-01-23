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
	# https://kubedb.com/docs/0.9.0/setup/install/
	helm repo add appscode https://charts.appscode.com/stable/
	helm repo update

	# use a different namespace if set
	kubedb_namespace=${cfg__project__k8s_namespace:=$cfg__kubedb__namespace}

	# install kubedb operator chart
	echo "Deploying kubedb operator"
	# kubedb complains a lot if you try to upgrade it, even with --reuse-values
	helm install appscode/kubedb --name $cfg__kubedb__operator__release \
	 --version $cfg__kubedb__operator__version \
	 --values $file_folder/$cfg__kubedb__operator__config_file \
	 --namespace $kubedb_namespace $( [ ! -z $cfg__kubedb__operator__setup_timeout ] && [ $cfg__kubedb__operator__setup_timeout -gt 0 ] && printf %s "--timeout $cfg__kubedb__operator__setup_timeout --wait" )

	# wait for CRDs to be registered
	kubectl get crds -l app=kubedb -w

	# install kubedb catalog
	echo "Deploying kubedb catalog"
	helm upgrade $cfg__kubedb__catalog__release appscode/kubedb-catalog --install --force \
	 --version $cfg__kubedb__catalog__version \
	 --namespace $kubedb_namespace $( [ ! -z $cfg__kubedb__catalog__setup_timeout ] && [ $cfg__kubedb__catalog__setup_timeout -gt 0 ] && printf %s "--timeout $cfg__kubedb__catalog__setup_timeout --wait" )

	# unset namespace
	unset kubedb_namespace

	# install kubedb client
        command -v kubedb >/dev/null 2>&1 || {
		OS=$(get_os_type)
		echo "Installing kubedb on $OS"
		case "$OS" in
			Linux)
				# Linux amd 64-bit
				wget -O kubedb https://github.com/kubedb/cli/releases/download/$cfg__kubedb__operator__version/kubedb-linux-amd64 \
				  && chmod +x kubedb \
				  && sudo mv kubedb /usr/local/bin/
				;;
			Mac)
				# Mac 64-bit
				wget -O kubedb https://github.com/kubedb/cli/releases/download/0.9.0/kubedb-darwin-amd64 \
				  && chmod +x kubedb \
				  && sudo mv kubedb /usr/local/bin/
				;;
			*)
	                        echo "$OS not supported."
	                        exit 1;;
		esac
        }

else
	helm delete --purge $cfg__kubedb__catalog__release
	helm delete --purge $cfg__kubedb__operator__release
fi
