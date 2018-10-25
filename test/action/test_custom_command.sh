#!/bin/bash

xpl_path=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

source ${xpl_path}/../../getopt.sh

opt_value1=""

getopt_add_param_description "[OPTIONS] CONTAINER"
getopt_add_option "--value1" "string" "Option 1" opt_value1
getopt_add_help
getopt_set_args "$@" 
getopt_allow_custom_command

getopt_read_args
res=$?
[[ $res -eq 1 ]] && {
	getopt_usage
	exit 1
}
[[ $res -eq 2 ]] && {
	echo "Custom command (size: ${#getopt_args[@]}): ${getopt_args[@]}"
}

echo "$(basename $0): opt_value1: $opt_value1"
echo "$(basename $0): exit ok"
