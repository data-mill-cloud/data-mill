find_by_volume_name_and_create(){
	# iterate on folder and create volume
	namespace=$1 # $cfg__project__k8s_namespace
	path=$2  # "$file_folder/volumes/pv/*"
	vol_name=$3 # $cfg__minio__pv_name
	vol_type=$4 # i.e. pv or pvc

	# look in each volume definition in the path to find a volume with the specified name
	for volume_def in $path; do
		if [ $(get_value $volume_def "name: ") = "$vol_name" ]; then
			# the volume was found in the folder
			# check if the volume exists (redirect stderr and stdout to black hole)
			kubectl get $vol_type $vol_name -n=$namespace 2> /dev/null > /dev/null
		        # if we had an error than the volume did not exist
        		if [ $? -ne 0 ]; then
        	        	kubectl create -f $volume_def -n=$namespace
			fi
			break
		fi
	done
}
