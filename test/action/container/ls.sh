#!/bin/bash

xpl_path=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

source ${xpl_path}/../../../getopt.sh

getopt_add_param_description "regex"
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
	echo "Custom regex: ${getopt_args[*]}"
}

echo "$(basename $0): ls executed"
