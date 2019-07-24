#!/bin/sh

get_random_string_key(){
	# as seen on https://gist.github.com/earthgecko/3089509
	# cat the random generator, replaces with chars, transposes to 1 column of 32 chars, get first row only
	cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1
}

# to be used for yaml files
get_random_base64_secret_key(){
	# returns a 32 chars secret, encoded in base64 format
	#openssl rand -base64 32
	cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1 | base64
}

# to be used for kubectl and other CLI tools, e.g. HELM
get_random_secret_key(){
	# classic method to create a secret
	openssl rand -hex 32
	# N.B all K8s secrets are saved in base64 format, but we pass it in clear
}


get_existing_secret(){
	# get secret and decode it from base64
	kubectl -n $1 get secrets $2 -o jsonpath=$3 | base64 -d
	# e.g. echo "MINIO:"$(get_existing_secret $cfg__project__k8s_namespace "minio-datalake" "{.data.accesskey}")
}
