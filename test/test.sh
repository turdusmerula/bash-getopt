#!/bin/bash

xpl_path=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

source ${xpl_path}/../getopt.sh

opt_config=$HOME/.docker
opt_debug=0
opt_tls=0

output=$(mktemp -d)

getopt_command_description="COMMAND"
getopt_add_option "-c" "--config" "string" "Location of client config files (default $opt_config)" opt_config
getopt_add_action_option "-l" "--list" "[]" "add an item to the list" 'echo -n "$value_arg " >> $output/list'
getopt_add_flag   "-D" "--debug"  		   "Enable debug mode" opt_debug
getopt_add_help
getopt_add_flag 	   "--tls"    		   "Use TLS; implied by --tlsverify" opt_tls
getopt_add_category "Management commands"
getopt_add_command "container" "Manage containers" ${xpl_path}/action/container.sh
getopt_add_category "Commands"
getopt_add_command "attach" "Attach to a running container" ${xpl_path}/action/attach.sh
getopt_add_command "copy" "copy an image" ${xpl_path}/action/copy.sh
getopt_add_command "rm" "remove an image" ${xpl_path}/action/rm.sh
getopt_add_text "\nRun '$(basename $0) COMMAND --help' for more information on a command.\n"
getopt_set_args "$@" 

getopt_read_args || {
	getopt_usage
	exit 1
}

echo "$(basename $0): opt_config: $opt_config"
echo "$(basename $0): opt_debug: $opt_debug"
echo "$(basename $0): opt_tls: $opt_tls"
echo "$(basename $0): list=$(cat $output/list)"