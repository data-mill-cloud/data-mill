count_vars_from_prefix(){
	( set -o posix ; set ) | grep "^$1" | wc -l
}

get_paths(){
	echo 'fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)'
	echo 'file_folder=$(dirname $fullpath)'
}

is_target_env_defined(){
	EVARS=$(count_vars_from_prefix "cfg__${1}__")
	NUM_VARS=$(( $EVARS ))
	[[ "$NUM_VARS" -gt "0" ]] && echo "true" || echo "false"
}

get_target_env_config(){
	# if -t was passed we overwrite the default project config or take that otherwise
	if [ ! -z $TARGET_FILE ]; then
		# use the provided target file as it is or attempt loading it as filename inside the k8s config folder if not found
		TARGET_CONFIG=$(file_exists "$TARGET_FILE" "$file_folder/configs/$TARGET_FILE")
		echo "$(parse_yaml $TARGET_CONFIG 'cfg__')"
	else
		# if no explicit target file was specified, we check whether we already have the config loaded in the flavour (centralised configuration)
		LOCVARS=$(count_vars_from_prefix "cfg__local__")
		REMVARS=$(count_vars_from_prefix "cfg__remote__")
		HYBVARS=$(count_vars_from_prefix "cfg__hybrid__")
		NUM_VARS=$(( $LOCVARS + $REMVARS + $HYBVARS ))

		# the config vars are not defined already (centralised in the flavour file)
		# we rather need to load it from the component folder (distributed configuration)
		if [ "$NUM_VARS" -eq "0" ]; then
			# load the default target file from the local k8s folder otherwise
			TARGET_CONFIG="$file_folder/configs/$cfg__project__k8s_default_config"
			echo "$(parse_yaml $TARGET_CONFIG 'cfg__')"
		fi
	fi
}

get_component_config(){
	# check if a config already exists for the component (i.e. was defined in the flavour file)
	COMPONENT_NAME=$(basename "$file_folder")
	NUM_VARS=$(count_vars_from_prefix "cfg__${COMPONENT_NAME}__")
	#echo "VARS for $COMPONENT_NAME are no. $NUM_VARS"
	# if no vars are available we are not using the centralised config, but the distributed one (1 file per component)
	# in this case we need to check in the component folder
	if [ "$NUM_VARS" -eq "0" ]; then
		# if -f FLAVOUR_FILE was given and the file for the component exists, then use it
		# we have to be careful, since config_file may be passed as filename or path, let's then just retrieve the filename
		FLAVOUR_FILE=$(basename "$FLAVOUR_FILE")
		# otherwise fallback to the specified component default config (e.g. when using -c component without specifying any flavour)
		COMPONENT_CONFIG=$(file_exists "$file_folder/$FLAVOUR_FILE" "$file_folder/$cfg__project__component_default_config")
		echo "$(parse_yaml $COMPONENT_CONFIG 'cfg__')"
	fi
}

# returns the path to the file in the flavour folder or config_folder, if it exists, or to the component folder otherwise
get_values_file(){
	# $cfg__project__config_folder is either set explicitly or defaulted to the flavour config folder (see run.sh)
	echo $(file_exists "${cfg__project__config_folder}/${1}" "${file_folder}/${1}")
	# this can be changed in future to skip the action on the component if the values.yaml is not found
	# for now we however want to provide all 3 options for now (flavour_folder, flavours with config_folder, per-component values.yaml)
}
