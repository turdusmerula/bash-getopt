#!/bin/bash

xpl_path=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

source ${xpl_path}/../../getopt.sh

opt_option1=""

getopt_command_description="COMMAND"
getopt_add_option  "--option1" "name"  		   "Option with no shortname" opt_option1
getopt_add_help
getopt_add_category "Commands"
getopt_add_command "test_custom_params" "Test custom command evaluation" ${xpl_path}/action/test_custom_params.sh
getopt_add_text "\nRun '$(basename $0) COMMAND --help' for more information on a command.\n"
getopt_set_args "$@" 

getopt_read_args || {
	getopt_usage
	exit 1
}

echo "$(basename $0): opt_option1: $opt_option1"
echo "$(basename $0): exit ok"
