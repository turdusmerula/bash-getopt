#!/bin/bash

xpl_path=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

source ${xpl_path}/../../getopt.sh

opt_param1=""
opt_param2=""
opt_param3=""

getopt_add_param_description "[OPTIONS] PARAM1 PARAM2 PARAM3"
getopt_add_parameter "PARAM1" "Parameter 1" opt_param1
getopt_add_parameter "PARAM2" "Parameter 2" opt_param2
getopt_add_parameter "PARAM3" "Parameter 3" opt_param3
getopt_add_help
getopt_set_args "$@" 
getopt_read_args
res=$?
[[ $res -eq 1 ]] && {
	getopt_usage
	exit 1
}

echo "$(basename $0): opt_param1: $opt_param1"
echo "$(basename $0): opt_param2: $opt_param2"
echo "$(basename $0): opt_param3: $opt_param3"
echo "$(basename $0): exit ok"
