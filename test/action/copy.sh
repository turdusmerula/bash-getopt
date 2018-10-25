#!/bin/bash

xpl_path=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

source ${xpl_path}/../../getopt.sh

opt_force=0

getopt_add_param_description "[OPTIONS] IMAGE_SOURCE IMAGE_DEST"
getopt_add_flag "--force" "force" "Force removing" opt_force
getopt_add_parameter "IMAGE_SOURCE" "Image source" opt_image_source
getopt_add_parameter "IMAGE_DEST" "Image destination" opt_image_dest
getopt_add_help
getopt_set_args "$@" 
getopt_read_args
res=$?
[[ $res -eq 1 ]] && {
	getopt_usage
	exit 1
}

echo "$(basename $0): rm executed"
echo "$(basename $0): opt_debug: $opt_debug"
echo "$(basename $0): opt_force: $opt_force"
echo "$(basename $0): opt_image_source: $opt_image_source"
echo "$(basename $0): opt_image_dest: $opt_image_dest"
