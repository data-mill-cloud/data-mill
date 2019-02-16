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
		RELEASE=$(get_latest_github_release 'kubedb/cli')
		RELEASE=${RELEASE:=$cfg__kubedb__operator__version}
		OS=$(get_os_type)
		echo "Installing kubedb $RELEASE on $OS"
		case "$OS" in
			Linux)
				# Linux amd 64-bit
				wget -O kubedb https://github.com/kubedb/cli/releases/download/$RELEASE/kubedb-linux-amd64 \
				  && chmod +x kubedb \
				  && sudo mv kubedb /usr/local/bin/
				;;
			Mac)
				# Mac 64-bit
				wget -O kubedb https://github.com/kubedb/cli/releases/download/$RELEASE/kubedb-darwin-amd64 \
				  && chmod +x kubedb \
				  && sudo mv kubedb /usr/local/bin/
				;;
			*)
	                        echo "$OS not supported."
	                        exit 1;;
		esac
		unset OS
		unset RELEASE
        }

else
	helm delete --purge $cfg__kubedb__catalog__release
	helm delete --purge $cfg__kubedb__operator__release
fi
