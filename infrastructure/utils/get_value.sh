#!/bin/sh

get_value() {
	#cat $1 | grep "name: " | awk -F": " '{ print $2 }'
	cat $1 | grep $2 | awk -F": " '{ print $2 }'
}

file_exists(){
	# returns $1 if exists or $2 as default location if not
	(ls $1 >> /dev/null 2>&1 && echo $1) || echo $2
}

iterate_file_exists(){
	# iterates on a list of paths and returns the first that actually exists, or nothing otherwise
	for location in "$@"
	do
		ls $location >> /dev/null 2>&1 && {
			echo $location
			break
		}
	done
}

check_if_pod_exists(){
	kubectl get pods --all-namespaces | grep $1
}

get_pod_name(){
        # NAMESPACE NAME READY STATUS RESTARTS AGE
        kubectl get pods --all-namespaces | awk '/'$1'/ {print $2;exit}'
}

get_pod_status() {
	# returns the status of a specific pod
	# NAMESPACE NAME READY STATUS RESTARTS AGE
	kubectl get pods --all-namespaces | awk '/'$1'/ {print $4;exit}'
}
