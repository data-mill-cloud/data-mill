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
	# https://argoproj.github.io/docs/argo/demo.html
	# https://github.com/argoproj/argo-helm
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo update
	# if set use special namespace for argo
	argo_namespace=${cfg__project__k8s_namespace:=$cfg__argo__namespace}
	# deploy chart
	helm upgrade $cfg__argo__release argo/argo \
	 --namespace $argo_namespace \
	 --values $(get_values_file "$cfg__argo__config_file") \
	 --install --force
	# remove argo repo (we do not want to update everything every time)
	helm repo remove argo

	unset argo_namespace

	# install argo CLI
        command -v kubedb >/dev/null 2>&1 || {
		RELEASE=$(get_latest_github_release 'argoproj/argo')
                RELEASE=${RELEASE:=$cfg__argo__version}
		# install for specific os
                OS=$(get_os_type)
                echo "Installing argo $RELEASE on $OS"
                case "$OS" in
                        Linux)
                                # Linux amd 64-bit
				wget -O argo https://github.com/argoproj/argo/releases/download/$RELEASE/argo-linux-amd64 \
				 && chmod +x argo \
				 && sudo mv argo /usr/local/bin/
                                ;;
                        Mac)
                                # Mac 64-bit
                                wget -O argo https://github.com/argoproj/argo/releases/download/$RELEASE/argo-darwin-amd64 \
                                  && chmod +x argo \
                                  && sudo mv argo /usr/local/bin/
                                ;;
                        *)
                                echo "$OS not supported."
                                exit 1;;
                esac
        }

else
	helm delete $cfg__argo__release --purge
fi
