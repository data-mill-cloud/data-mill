#!/usr/bin/env bash

fullpath=$(readlink --canonicalize --no-newline $BASH_SOURCE)
file_folder=$(dirname $fullpath)

# load local yaml config
# if -f was given and the file exists use it, otherwise fallback to the specified component default config
COMPONENT_CONFIG=$(file_exists "$file_folder/$CONFIG_FILE" "$file_folder/$cfg__project__component_default_config")
eval $(parse_yaml $COMPONENT_CONFIG "cfg__")

# use if set or a string argument otherwise
ACTION=${ACTION:=$1}

if [ -z "$ACTION" ] || [ "$ACTION" != "install" ] && [ "$ACTION" != "delete" ];then
        echo "usage: $0 {'install' | 'delete'}";
        exit 1
elif [ "$ACTION" = "install" ]; then
	# https://github.com/upmc-enterprises/elasticsearch-operator
	helm repo add es-operator https://raw.githubusercontent.com/upmc-enterprises/elasticsearch-operator/master/charts/

	# add elasticsearch operator using helm
	# install elasticsearch operator
	helm upgrade ${cfg__elastic__release}-operator es-operator/elasticsearch-operator \
	 --namespace $cfg__project__k8s_namespace \
	 --values $file_folder/$cfg__elastic__operator__config_file \
	 --install --force $( [ ! -z $cfg__elastic__operator__setup_timeout ] && [ $cfg__elastic__operator__setup_timeout -gt 0 ] && printf %s "--timeout $cfg__elastic__operator__setup_timeout --wait" )

	# install elasticsearch stack
	helm upgrade ${cfg__elastic__release}-es es-operator/elasticsearch \
         --namespace $cfg__project__k8s_namespace \
         --values $file_folder/$cfg__elastic__es__config_file \
	 --recreate-pods \
         --install --force $( [ ! -z $cfg__elastic__es__setup_timeout ] && [ $cfg__elastic__es__setup_timeout -gt 0 ] && printf %s "--timeout $cfg__elastic__es__setup_timeout --wait" )
else
	helm delete ${cfg__elastic__release}-es --purge
	helm delete ${cfg__elastic__release}-operator --purge
fi
