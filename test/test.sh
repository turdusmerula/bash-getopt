#!/bin/bash

xpl_path=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

source ${xpl_path}/../getopt.sh

opt_value1=value1
opt_flag1=0
opt_flag2=0

output=$(mktemp -d)
echo -n > $output/list
getopt_command_description="COMMAND"
getopt_add_option        "-v" "--value" "string"   "Option in variable (default $opt_value1)" opt_value1
getopt_add_action_option "-l" "--list"  "[]"       "Option that add value in a file" 'echo -n "$value_arg " >> $output/list'
getopt_add_flag          "-f" "--flag1"  		   "Flag in variable" opt_flag1
getopt_add_flag 	     "--flag2"    		       "Flag with no short name" opt_flag2
getopt_add_help
getopt_add_category "Command sub category 1"
getopt_add_command "test_recursive"                 "Test recursive commands" ${xpl_path}/action/test_recursive.sh
getopt_add_category "Command sub category 2"
getopt_add_command "test_1_parameter"               "Test one mandatory parameter" ${xpl_path}/action/test_1_parameter.sh
getopt_add_command "test_3_parameters"              "Test three mandatory parameters" ${xpl_path}/action/test_3_parameters.sh
getopt_add_command "test_3_parameters_with_options" "Test three mandatory parameters mixed with options" ${xpl_path}/action/test_3_parameters_with_options.sh
getopt_add_command "test_custom_command"            "Test custom command" ${xpl_path}/action/test_custom_command.sh
getopt_add_command "sub_test4" "Sub command 4" ${xpl_path}/action/sub_test4.sh
getopt_add_text "\nRun '$(basename $0) COMMAND --help' for more information on a command.\n"
getopt_set_args "$@" 

getopt_read_args || {
	getopt_usage
	exit 1
}

echo "$(basename $0): opt_value1: $opt_value1"
echo "$(basename $0): opt_flag1: $opt_flag1"
echo "$(basename $0): opt_flag2: $opt_flag2"
echo "$(basename $0): list=$(cat $output/list)"
rm -rf $output
echo "$(basename $0): exit ok"
