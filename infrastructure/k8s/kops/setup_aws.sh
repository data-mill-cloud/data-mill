#!/usr/bin/env bash

fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
file_folder=$(dirname $fullpath)

# Retrieving the OS type
OS=$(get_os_type)

# retrieve from config file
CLUSTER_NAME=$cfg__remote__cluster_name
BUCKET_NAME=$cfg__remote__bucket_name
STATE_BUCKET=s3://$BUCKET_NAME
REGION=$cfg__remote__region #"us-east1"
ZONES=$cfg__remote__zones #"us-east-1a"
NO_NODES=$cfg__remote__no_nodes #2
NODE_SIZE=$cfg__remote__node_size #t2.medium

#( set -o posix ; set ) | more
#exit 1

if [ "$ACTION" = "install" ]; then
	# K8s cluster creation - AWS
	# https://medium.com/containermind/how-to-create-a-kubernetes-cluster-on-aws-in-few-minutes-89dda10354f4

	# 1. INSTALLATION
	if [ "$OS" = "Mac" ]; then
		brew install kops
	else
		# Linux
		curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
		chmod +x kops-linux-amd64
		sudo mv kops-linux-amd64 /usr/local/bin/kops
	fi

	# 2. IAM - CREATE USER AND GRANT PERMISSIONS
	echo "Create a new user on IAM and grant the following permissions:"
	echo "AmazonEC2FullAccess"
	echo "AmazonRoute53FullAccess"
	echo "AmazonS3FullAccess"
	echo "AmazonVPCFullAccess"
	read -p "Once done, press enter to continue.."

	# 3. configure AWS CLI
	aws configure

	# 4. create s3 bucket and enable versioning
	aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION
	aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

	# 5. create a cluster definition
	kops create cluster --node-count=$NO_NODES --node-size=$NODE_SIZE --zones=$ZONES --name=$CLUSTER_NAME

	#6. review configuration
	kops edit cluster --name $CLUSTER_NAME

	# 7. apply configuration and wait for the cluster to be ready
	kops update cluster --name $CLUSTER_NAME --yes
	kops validate cluster

	# 8. get info of master node
	kubectl cluster-info

elif [ "$ACTION" = "delete" ]; then
	kops delete cluster $CLUSTER_NAME
else
	echo "Error: $ACTION should be either 'install' or 'delete'"
fi
