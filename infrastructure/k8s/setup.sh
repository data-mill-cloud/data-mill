#!/usr/bin/env bash

fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
file_folder=$(dirname $fullpath)

# load local yaml config
# if -t was not passed we stick to the default config
TARGET_FILE=${TARGET_FILE:="$cfg__project__k8s_default_config"}
# if the target file was specified but does not exist, we fall back to the default config
TARGET_CONFIG=$(file_exists "$file_folder/configs/$TARGET_FILE" "$file_folder/configs/$cfg__project__k8s_default_config")
eval $(parse_yaml $TARGET_CONFIG "cfg__")

# Retrieving the OS type
OS=$(get_os_type)

check_multipass(){
	MIN_VERSION=18
	# use raw snap only if we are on a ubuntu/debian distro and after a certain version
	lsb_release -sr >/dev/null 2>&1 && {
        	# if lsb_release check the OS version
		if [ $(lsb_release -sr | cut -f1 -d ".") -ge $MIN_VERSION ]; then
			echo "USE_MULTIPASS=false"
		else
			echo "USE_MULTIPASS=true"
                fi
	} || echo "USE_MULTIPASS=true"
}

run_multipass(){
	if [ $USE_MULTIPASS = true ]; then
		# run command on the multipass VM
		VM_NAME=${cfg__local__provider}-vm
		# todo: change to make this configurable
		echo "multipass exec $VM_NAME -- "${1}
	else
		# run command on the host
		if [ -z "$2" ] || [ "$2" != "multipass_only" ]; then
			echo $1
		fi
	fi
}

# ACTIONS: start debug install delete
if [ "$ACTION" = "delete" ]; then
	if [ "$LOCATION" = "local" ]; then
		if [ "$cfg__local__provider" = "minikube" ]; then
			minikube stop
			minikube delete
		elif [ "$cfg__local__provider" = "microk8s" ]; then
			eval $(check_multipass)
			if [ $USE_MULTIPASS = true ]; then
				multipass stop $VM_NAME
				multipass delete $VM_NAME
				multipass purge
			else
				microk8s.stop
				microk8s.reset
			fi
		else
			echo "Local K8s provider $cfg__local__provider not supported!"
		fi
	else
		echo "ToDo"
	fi
else
	# we have to start, install, or debug the cluster
	if [ "$LOCATION" = "local" ]; then
		echo "Setting up local K8s cluster";

		if [ "$cfg__local__provider" = "minikube" ]; then
			# setting up minikube locally
			# premise: kvm, virtualbox or whatever we are going to use should be already installed
			# https://github.com/kubernetes/minikube/blob/master/docs/drivers.md
			# the VM driver installs at /usr/bin/docker-machine-driver-* or /usr/local/bin/docker-machine-driver-*
			drivers=(kvm kvm2 hyperkit xhyve)
			available=false
			for d in "${drivers[@]}"
			do
				if [ -f /usr/bin/docker-machine-driver-$d ] || [ -f /usr/bin/docker-machine-driver-$d ]; then
					available=true
					echo "Found the $d driver"
					break
				fi
			done

			if [ ! $available ]; then
				echo "No VM driver found, please install one first: https://github.com/kubernetes/minikube/blob/master/docs/drivers.md"
				exit 1
			fi

			command -v minikube >/dev/null 2>&1 || {
                		echo >&2 "minikube not available... installing";
				latest_minikube=$(get_latest_github_release "kubernetes/minikube")
				echo  "latest minikube version available is $latest_minikube"
				curl -Lo minikube https://storage.googleapis.com/minikube/releases/$latest_minikube/minikube-linux-amd64 && chmod +x minikube && sudo cp minikube /usr/local/bin/ && rm minikube
        		}
		elif [ "$cfg__local__provider" = "microk8s" ]; then
			echo "Setting up Microk8s cluster"

			# snap is necessary to install the cluster
			command -v snap >/dev/null 2>&1 || {
				echo "snap package manager is missing and required to install mikrok8s! Exiting.."
                                echo "Please install snapd and enable the service (e.g. from systemctl)"
                                echo "In case you get an error like the following please run 'sudo ln -s /var/lib/snapd/snap /snap':"
                                echo "    error: cannot install 'microk8s': classic confinement requires snaps under /snap or symlink from /snap to /var/lib/snapd/snap"
                                exit 1
                        }

			# use raw snap only if we are on a ubuntu/debian distro and after a certain version
			# by default use multipass, we tried it on other linux distro and snap was very messy
			#USE_MULTIPASS=true
			eval $(check_multipass)
			VM_NAME=${cfg__local__provider}-vm
			# todo: make vm_name configurable so that we can run multiple clusters

			# check the needed dependencies
			if [ $USE_MULTIPASS = true ]; then
				# multipass is necessary to create the VM
				command -v multipass >/dev/null 2>&1 || {
					# if we are on a linux machine we can use snap to install it
					case "$OS" in
						Linux)
						   echo "Multipass not available, installing using snap"
						   sudo snap install multipass --beta --classic
						   ;;
						Mac)
						   echo "Multipass is necessary to run microk8s. Please visit: https://github.com/CanonicalLtd/multipass/releases"
						   exit 1;;
						*)
						   echo "$OS is not supported"
						   exit 1;;
					esac
				}

				# make sure we have read write access to the multipass folder /run/multipass_socket
				MULTIPASS_GROUP=$(ls -g /run/multipass_socket | awk '{print $3}')
				# Multipass supported groups: sudo, adm, admin (https://github.com/CanonicalLtd/multipass/pull/513)
				if getent group $MULTIPASS_GROUP | grep &>/dev/null "\b$(whoami)\b"; then
					echo "$(whoami) has access to /run/multipass_socket"
				else
					echo "No access to /run/multipass_socket, Adding $(whoami) to group $MULTIPASS_GROUP"
					sudo usermod -aG $MULTIPASS_GROUP $(whoami)
					newgrp $MULTIPASS_GROUP
				fi
				echo "Launching multipass VM $VM_NAME"
				# launch a VM if not already running or does not exists yet
				# the exit 1 is needed in case the VM fails to start, e.g. when "launch failed: multipass socket access denied"
				kb_status=$(multipass info $VM_NAME | grep State: | awk -F": " '{ print $2 }' | xargs)
				if [ $? = 1 ]; then
					echo "Launching multipass VM $VM_NAME"
					multipass launch --name $VM_NAME --mem $cfg__local__storage --disk $cfg__local__storage -c $cfg__local__cpus || exit 1
				else
					multipass start $VM_NAME
				fi

				# ssh in the VM, or exit otherwise as all following commands are expected to be ran there
				#multipass shell $VM_NAME || exit 1
			fi

			# from here on we are on a Ubuntu-like machine with snap enabled
			echo "Checking if microk8s is already installed"
			$(run_multipass "sudo snap install microk8s --classic")
			# run the following command only for the multipass VM (noop if raw snap is used)
			$(run_multipass "sudo iptables -P FORWARD ACCEPT" "multipass_only")
		else
			echo "Local K8s provider $cfg__local__provider not supported!"
		fi

		# installing kubectl if not available
		command -v kubectl >/dev/null 2>&1 || {
			echo >&2 "kubectl not available... installing";
			# https://kubernetes.io/docs/tasks/ools/install-kubectl/#install-kubectl
			# downloading latest stable release
			curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
			# making executable and moving to bin
			chmod +x ./kubectl
			sudo mv ./kubectl /usr/local/bin/kubectl
		}

		if [ "$cfg__local__provider" = "minikube" ]; then
			# starting minikube cluster if not already started (to make sure this whole script is idempotent)
			kb_status=$(minikube status | grep "host:" | awk '{print $2}' FS=': ')
			if [ -z "$kb_status" ] || [ "$kb_status" = "Stopped" ]; then
				# starting minikube
				echo "starting local k8s provider $cfg__local__provider"
				echo "minikube start --cpus $cfg__local__cpus --memory $cfg__local__memory --disk-size=$cfg__local__storage --vm-driver $cfg__local__vm_driver "$( ( "$cfg__local__gpu_support" = true ) && printf %s '--gpu' )
				# in case of issues with mounting, it may be due to the vm driver (they behave differently) or more probably to a firewall issue on the host
				# https://github.com/kubernetes/minikube/issues/2379
				# https://github.com/kubernetes/minikube/issues/1548
				# please run minikube mount -v10 $root_folder/data:$cfg__local__mnt_data
				# https://kubernetes.io/docs/setup/minikube/#mounted-host-folders
				# starting registry mirror on host
				docker start registry-mirror || docker run -d --restart=always -p 5000:5000 --name registry-mirror \
				-v $PWD/registry/data/:/var/lib/registry/ \
				-v $PWD/registry/config/:/etc/docker/registry/ registry:2

				echo "starting minikube"
				minikube start \
				--cpus $cfg__local__cpus \
				--memory $cfg__local__memory \
				--disk-size=$cfg__local__storage \
				--vm-driver $cfg__local__vm_driver \
				--registry-mirror http://192.168.122.1:5000 \
				--insecure-registry http://192.168.122.1:5000 $( ( "$cfg__local__gpu_support" = true ) && printf %s '--gpu' )
				# GPU setup explained at https://github.com/kubernetes/minikube/blob/master/docs/gpu.md

				echo "Minikube VM started. Node accessible using 'minikube ssh'"

				# enable add-ons
				# https://github.com/kubernetes/minikube/blob/master/docs/addons.md
				minikube addons enable metrics-server
				if [ ! -z "$cfg__local__gpu_support" ] && [ "$cfg__local__gpu_support" = true ]; then
					minikube addons enable nvidia-driver-installer
					minikube addons enable nvidia-gpu-device-plugin
				fi
				# create a namespace for us
				kubectl create namespace $cfg__project__k8s_namespace
			else
				echo "Minikube is already running. Enjoy!"
			fi
		elif [ "$cfg__local__provider" = "microk8s" ]; then
			# start microk8s, if it is already running nothing will happen
			echo "$(run_multipass)"
			$(run_multipass "/snap/bin/microk8s.status --wait-ready --timeout 120") || $(run_multipass "/snap/bin/microk8s.start")
			echo "checking for DNS addon"
			$(run_multipass "/snap/bin/microk8s.status") | grep -e 'dns: enabled' >/dev/null 2>&1 || $(run_multipass "/snap/bin/microk8s.enable dns")
			echo "checking for storage addon"
			$(run_multipass "/snap/bin/microk8s.status") | grep -e 'storage: enabled' >/dev/null 2>&1 || $(run_multipass "/snap/bin/microk8s.enable storage")
			echo "checking for registry addon"
			$(run_multipass "/snap/bin/microk8s.status") | grep -e 'registry: enabled' >/dev/null 2>&1 || $(run_multipass "/snap/bin/microk8s.enable registry")

			if [ ! -z "$cfg__local__gpu_support" ] && [ "$cfg__local__gpu_support" = true ]; then
				$(run_multipass "/snap/bin/microk8s.status") | grep -e 'gpu: enabled' >/dev/null 2>&1 || $(run_multipass "/snap/bin/microk8s.enable gpu")
			fi

			# make sure allow-privileged is enabled for microk8s (not by default)
			echo "checking allow-privileged"

			$(run_multipass "cat /var/snap/microk8s/current/args/kube-apiserver") | grep -e '--allow-privileged' >/dev/null 2>&1 \
			&& { echo "--allow-privileged is already set"; } \
			|| {
				echo "Flag not set, adding it.."
				$(run_multipass "echo --allow-privileged") | $(run_multipass "sudo tee -a /var/snap/microk8s/current/args/kube-apiserver")
				# restart daemon after config change
				$(run_multipass "sudo systemctl restart snap.microk8s.daemon-apiserver")
				# the following used only for debug purposes
				#$(run_multipass "sudo cat /var/snap/microk8s/current/args/kube-apiserver")
			}

			if [ $USE_MULTIPASS = true ]; then
				# create a cluster context for our local kubectl tool
				$(run_multipass "/snap/bin/microk8s.config") > $file_folder/${cfg__local__provider}.config

				# switch to this config file
				export KUBECONFIG="$file_folder/${cfg__local__provider}.config"
				#echo "KUBECONFIG is $KUBECONFIG"
				kubectl config view --flatten
			fi
			# switch context
			kubectl config use-context $cfg__local__provider
			# create a namespace for us
			kubectl get ns $cfg__project__k8s_namespace >/dev/null 2>&1 || kubectl create namespace $cfg__project__k8s_namespace
		else
			echo "Local K8s provider $cfg__local__provider not supported!"
		fi

		# add an overlay network if required
		if [ ! -z "$cfg__local__use_overlay" ] && [ "$cfg__local__use_overlay" = true ]; then
			. $file_folder/overlay/setup.sh
		fi

		# installing helm client
		command -v helm >/dev/null 2>&1 || {
	                echo >&2 "Helm not available... installing";
			# helm installation
			wget "https://storage.googleapis.com/kubernetes-helm/helm-v2.12.1-linux-amd64.tar.gz"
			tar -zxvf helm-v2.12.1-linux-amd64.tar.gz
			mv linux-amd64/helm /usr/local/bin/helm
		}
		# initializing helm and installing tiller on the cluster
		# https://docs.helm.sh/using_helm/
		if [[ -z $(check_if_pod_exists "tiller") ]]; then
			echo "Installing Tiller"
			kubectl -n kube-system create sa tiller
			kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
			helm init --service-account tiller --wait --tiller-connection-timeout 300
			# 300 seconds (5 mins) is the default waiting time
			# --wait : block until Tiller is running and ready to receive requests
		fi
		# wait for tiller to be up and running (minikube is not respecting --wait)
		while [[ -z $(check_if_pod_exists "tiller") || $(get_pod_status "tiller") != "Running" ]]; do
			echo "tiller not yet running, waiting..."
			sleep 1
		done

		# show where tiller was deployed
		echo "Tiller deployed as pod "$(get_pod_name "tiller")
	else
		echo "Setting up infrastructure on remote K8s cluster";
	fi
fi
