#!/bin/bash

xpl_path=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

source ${xpl_path}/../../getopt.sh

opt_driver=""

getopt_command_description="COMMAND"
getopt_add_help
getopt_add_option  "--driver" "name"  		   "Set custom driver" opt_driver
getopt_add_category "Commands"
getopt_add_command "ls" "List containers" ${xpl_path}/container/ls.sh
getopt_add_text "\nRun '$(basename $0) COMMAND --help' for more information on a command.\n"
getopt_set_args "$@" 

getopt_read_args || {
	getopt_usage
	exit 1
}

echo "$(basename $0): opt_driver: $opt_driver"
