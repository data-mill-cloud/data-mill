#!/usr/bin/env bash

fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
file_folder=$(dirname $fullpath)

# Retrieving the OS type
OS=$(get_os_type)

# retrieve from config file
CLUSTER_NAME=$cfg__remote__cluster_name
BUCKET_NAME=$cfg__remote__bucket_name
STATE_BUCKET="gs://$BUCKET_NAME/"
REGION=$cfg__remote__region # "us-east1"
# e.g. to run for multiple zones: us-east-1b,us-east-1c,us-east-1d
ZONES=$cfg__remote__zones #"us-east1-a"

#( set -o posix ; set ) | more
#exit 1

if [ "$ACTION" = "install" ]; then
	# K8s cluster creation - GCE
	# https://github.com/kubernetes/kops/blob/master/docs/tutorial/gce.md
	# install kops if not available
	command -v kops >/dev/null 2>&1 || {
                if [ "$OS" = "Mac" ]; then
                        brew install kops
                else
                        # Linux
                        curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
                        chmod +x kops-linux-amd64
                        sudo mv kops-linux-amd64 /usr/local/bin/kops
                fi
        }

	# 1. create a bucket to store the cluster state
	command -v gsutil >/dev/null 2>&1 || {
		curl https://sdk.cloud.google.com | bash
		exec -l $SHELL
		gcloud init
	}
	gsutil mb $STATE_BUCKET
	#read -p "Check if correct, then press enter to continue.."

	PROJECT=`gcloud config get-value project`
	export KOPS_FEATURE_FLAGS=AlphaAllowGCE # to unlock the GCE features
	kops create cluster $CLUSTER_NAME --zones $ZONES --state $STATE_BUCKET --project=$PROJECT
	#read -p "Check if correct, then press enter to continue.."

	# verify that the cluster is correctly created and the store reachable
	kops get cluster --state $STATE_BUCKET
	#read -p "Check if correct, then press enter to continue.."

	# show the resulting cluster definition configuration
	kops get cluster --state $STATE_BUCKET $CLUSTER_NAME -oyaml
	#read -p "Check if correct, then press enter to continue.."

	# show the nodes
	kops get instancegroup --state $STATE_BUCKET --name $CLUSTER_NAME
elif [ "$ACTION" = "delete_all" ]; then
	kops delete cluster $CLUSTER_NAME
else
	echo "GKE setup error: ACTION should be either 'install' or 'delete_all'"
fi
