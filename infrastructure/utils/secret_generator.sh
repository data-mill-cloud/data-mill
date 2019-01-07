#!/bin/sh

get_random_string_key(){
	# as seen on https://gist.github.com/earthgecko/3089509
	cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1
}

get_random_secret_key(){
	# classic
	openssl rand -hex 32
}


get_existing_secret(){
	kubectl -n $1 get secrets $2 -o jsonpath="{.data.accesskey}" | base64 -d
	# e.g. echo "MINIO:"$(get_existing_secret $cfg__project__k8s_namespace "minio-datalake")
}
