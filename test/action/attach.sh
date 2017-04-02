#!/bin/bash

xpl_path=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

source ${xpl_path}/../../getopt.sh

opt_detach_keys=""

getopt_add_param_description "[OPTIONS] CONTAINER"
getopt_add_option "--detach-keys" "string" "Override the key sequence for detaching a container" opt_detach_keys
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

echo "$(basename $0): attach executed"
echo "$(basename $0): opt_debug: $opt_debug"
echo "$(basename $0): opt_detach_keys: $opt_detach_keys"
