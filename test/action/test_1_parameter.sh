#!/bin/bash

xpl_path=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

source ${xpl_path}/../../getopt.sh

opt_param1=0

getopt_add_param_description "[OPTIONS] PARAM1"
getopt_add_parameter "PARAM1" "Parameter 1" opt_param1
getopt_add_help
getopt_set_args "$@" 
getopt_read_args
res=$?
[[ $res -eq 1 ]] && {
	getopt_usage
	exit 1
}

echo "$(basename $0): opt_param1: $opt_param1"
echo "$(basename $0): exit ok"
