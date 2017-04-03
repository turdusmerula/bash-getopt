#!/bin/bash
getopt_option_num=0
#getopt_shorts[]: short names
#getopt_names[]: long names
#getopt_values[]: for option, expected value 
#getopt_descriptions[]
#getopt_actions[]
#getopt_types[]

# description for command line
getopt_param_description=""

# indicates if at least an options begininning by - or -- exists
getopt_has_option=0

# indicates if at least one command is defined
getopt_has_command=0

# indicates if parsing options is enabled
# automatically switch to false if a '--' is encountered
getopt_parse_options=1

# bash arguments, set by getopt_set_args
unset getopt_args

# indicates if custom commands are allowed
getopt_custom_command=0

# indicates if a command was found in arguments
getopt_arg_command=0

#types:
# - 0 flag
# - 1 option
# - 2 action
# - 3 command
# - 4 category
# - 5 free text

# Show available options
function getopt_show_options() {
	i=0
	for type in "${getopt_types[@]}"
	do
		short=${getopt_shorts[i]}
		name="${getopt_names[i]}"
		value=${getopt_values[i]}
		description=${getopt_descriptions[i]}
		
		# flag or option or action_flag
		if [ ${type} -eq 0 ] || [ ${type} -eq 1 ] || [ ${type} -eq 2 ]
		then
			
			if [ "_$short" == "_none" ]
			then
				printf "      " >&2
			else
				printf "  %2s, " $short >&2
			fi				
			
			if [[ "${getopt_values[$i]}" != "none" ]]
			then
				printf "%-30s%s\n" "${name} ${value}" "${description}" >&2
			else
				printf "%-30s%s\n" "${name}" "${description}" >&2
			fi
		fi
		
		# command
		if [ ${type} -eq 3 ]
		then
			printf "  %-30s%s\n" "${name}" "${description}" >&2
		fi
		
		# catgory
		if [ ${type} -eq 4 ]
		then
			echo >&2
			printf "%s:\n" "${name}" >&2
		fi

		# free text
		if [ ${type} -eq 5 ]
		then
			echo -e "${name}" >&2
		fi

		(( i = i + 1 ))
	done
}

# Show function usage
function getopt_usage() {
	echo "Usage: $(basename $0) ${getopt_param_description}" >&2
	echo >&2
	[ $getopt_has_option -eq 1 ] && echo "Options:" >&2
	getopt_show_options
}

function getopt_add_param_description() {
	getopt_param_description=$*
	return 0	
}

function getopt_allow_custom_command() {
	getopt_custom_command=1
	return 1
}

# return:
# 0: name exist
# 1: name does not exist
function getopt_check_name_exist() {
	name="$1"
	
	for short in "${getopt_shorts[@]}"
	do
		if [[ "_$name" == "_$short" ]]
		then
			return 0
		fi
	done

	for option in "${getopt_names[@]}"
	do
		if [[ "_$name" == "_$option" ]]
		then
			return 0
		fi
	done

	return 1
}

# return:
# 0: option exist
# 1: option does not exist
function getopt_check_option_exist() {
	name="$1"
	
	i=0
	for short in "${getopt_shorts[@]}"
	do
		type=${getopt_types[$i]}
		if [[ "_$name" == "_$short" ]] && ( [[ $type -eq 0 ]] || [[ $type -eq 1 ]] || [[ $type -eq 2 ]] )
		then
			return 0
		fi
	
		(( i = i + 1 ))
	done

	i=0
	for option in "${getopt_names[@]}"
	do
		type=${getopt_types[$i]}
		if [[ "_$name" == "_$option" ]] && ( [[ $type -eq 0 ]] || [[ $type -eq 1 ]] || [[ $type -eq 2 ]] )
		then
			return 0
		fi
	
		(( i = i + 1 ))
	done

	return 1
}

# return:
# 0: command exist
# 1: command does not exist
function getopt_check_command_exist() {
	name="$1"
	
	i=0
	for option in "${getopt_names[@]}"
	do
		type=${getopt_types[$i]}
		if [[ "_$name" == "_$option" ]] && [[ $type -eq 3 ]]
		then
			return 0
		fi
		(( i = i + 1 ))
	done

	return 1
}

# return:
# 0: name exist
# 1: name does not exist
function getopt_check_name_index() {
	name="$1"
	
	i=0
	for short in "${getopt_shorts[@]}"
	do
		if [[ "_$name" == "_$short" ]]
		then
			echo $i
			return 0
		fi
		(( i = i + 1 ))
	done

	i=0
	for option in "${getopt_names[@]}"
	do
		if [[ "_$name" == "_$option" ]]
		then
			echo $i
			return 0
		fi
		(( i = i + 1 ))
	done

	return 1
}

# return:
# 0: option exist
# 1: option does not exist
function getopt_check_option_index() {
	name="$1"
	
	i=0
	for short in "${getopt_shorts[@]}"
	do
		type=${getopt_types[$i]}
		if [[ "_$name" == "_$short" ]] && ( [[ $type -eq 0 ]] || [[ $type -eq 1 ]] || [[ $type -eq 2 ]] )
		then
			echo $i
			return 0
		fi
		(( i = i + 1 ))
	done

	i=0
	for option in "${getopt_names[@]}"
	do
		type=${getopt_types[$i]}
		if [[ "_$option" == "_$short" ]] && ( [[ $type -eq 0 ]] || [[ $type -eq 1 ]] || [[ $type -eq 2 ]] )
		then
			echo $i
			return 0
		fi
		(( i = i + 1 ))
	done

	return 1
}

# return:
# 0: option exist
# 1: option does not exist
function getopt_check_command_index() {
	name="$1"
	
	i=0
	for option in "${getopt_names[@]}"
	do
		type=${getopt_types[$i]}
		if [[ "_$option" == "_$option" ]] && [[ $type -eq 3 ]]
		then
			echo $i
			return 0
		fi
		(( i = i + 1 ))
	done

	return 1
}

# prepare args to be read
getopt_set_args() {
	while [[ "_$@" != "_" ]]
	do
		getopt_args[${#getopt_args[@]}]="$1"
		shift
	done
}

# Read one argument from cached command line
# return :
# 0: option was read
# 1: nothing to read
# 2: custom command found
function getopt_read_arg() {
	
	# test if something to read
	[ ${#getopt_args[@]} -lt 1 ] && return 1
	
    local arg="${getopt_args[0]}" 
    
	if [[ "_${arg:0:1}" == "_-" ]] && [[ $getopt_parse_options -eq 1 ]]
	then
		# parse option
	    if [ "_$(echo "$arg" | grep '=')" != "_" ]
	    then
	        local filt_arg="$(echo $arg | sed "s#\(.*\)=.*#\1#g")"
	        local value_arg="$(echo $arg | sed "s#.*=\(.*\)#\1#g")"
	    else
	        local filt_arg=$arg
	        unset value_arg
	    fi
		
		if [[ "_${filt_arg}" == "_--" ]] && [[ $getopt_parse_options -eq 1 ]]
		then
			# stop parsing options
			getopt_parse_options=0
			
			# option was read, remove it
			getopt_args=("${getopt_args[@]:1}")
			
		elif [[ "_${filt_arg:0:2}" == "_--" ]]
		then
			# long flag detected
			
			# option was read, remove it
			getopt_args=("${getopt_args[@]:1}")

			getopt_check_option_exist "${filt_arg}"
			if [[ $? -ne 0 ]]
			then
				echo "$(basename $0): unknown option '$filt_arg'" >&2
				exit 1			
			fi
			
			i=$(getopt_check_option_index "${filt_arg}")
			value=${getopt_values[$i]}
			if [[ "_$value" == "_none" ]]
			then
				if [[ -n "$value_arg" ]]
				then
					echo "$(basename $0): unexpected value '$value_arg' for option '$filt_arg'" >&2
					exit 1
				fi			
			else
				if [[ -z "$value_arg" ]] && [[ -z "${getopt_args[0]}" ]]
				then
					echo "$(basename $0): expected value for option '$filt_arg'" >&2
					exit 1
				else
					if [[ -z "$value_arg" ]]
					then
						# take one value from args
						value_arg=${getopt_args[0]}
						getopt_args=("${getopt_args[@]:1}")
					fi
				fi
			fi

			# set found option
			index_arg=$i
		
		elif [[ "_${filt_arg:0:1}" == "_-" ]] && [[ $getopt_parse_options -eq 1 ]]
		then
			# shorthand flag detected
			if [[ ${#filt_arg} -eq 1 ]]
			then
				echo "$(basename $0): '-' is not a valid option" >&2
				exit 1
			fi
		
			if [[ ${#filt_arg} -gt 2 ]]
			then
				# extract one shorthand argument
				local short_arg=${filt_arg:1:1}
				
				# set shorthand options left to read
				if [[ -z "$value_arg" ]]
				then
					getopt_args[0]="-${filt_arg:2}"
				else
					getopt_args[0]="-${filt_arg:2}=$value_arg"
				fi
				
				# won't apply to this arg, value is only available for last shorthand arg
				unset value_arg
			else
				local short_arg=${filt_arg:1:1}
				# option was read, remove it
				getopt_args=("${getopt_args[@]:1}")
			fi
			
			getopt_check_option_exist "-${short_arg}"
			if [[ $? -ne 0 ]]
			then
				echo "$(basename $0): unknown shorthand option '$short_arg'" >&2
				exit 1			
			fi
	
			i=$(getopt_check_option_index "-${short_arg}")
			value=${getopt_values[$i]}
			if [[ "_$value" == "_none" ]]
			then
				if [[ -n "$value_arg" ]]
				then
					echo "$(basename $0): unexpected value '$value_arg' for shorthand option '$short_arg'" >&2
					exit 1
				fi			
			else
				if [[ -z "$value_arg" ]] && [[ -z "${getopt_args[0]}" ]]
				then
					echo "$(basename $0): expected value for shorthand option '$short_arg'" >&2
					exit 1
				else
					if [[ -z "$value_arg" ]]
					then
						# take one value from args
						value_arg=${getopt_args[0]}
						getopt_args=("${getopt_args[@]:1}")
					fi
				fi
			fi
			
			# set found option
			filt_arg=$short_arg
			index_arg=$i
		fi
		
		# treat associated action
		type=${getopt_types[$index_arg]}
		if [[ $type -eq 0 ]]
		then
			# set flag value
			eval "export ${getopt_actions[$i]}=1"
		elif [[ $type -eq 1 ]]
		then
			# set option value
			eval "export ${getopt_actions[$i]}=$value_arg"			
		elif [[ $type -eq 2 ]]
		then
			# set action value
			eval "${getopt_actions[$i]}"			
		fi
		
		return 0
		
	else
		# command detected

		res=0
		
		getopt_check_command_exist "${arg}"
		if [[ $? -ne 0 ]]
		then
			if [[ $getopt_custom_command -eq 0 ]]
			then
				echo "$(basename $0): unknown command '$arg'" >&2
				exit 1
			else
				# allow a custom command but indicates we encountered one
				res=2
			fi
		else
			# command was read, remove it
			getopt_args=("${getopt_args[@]:1}")
		
			# get command index
			index_arg=$(getopt_check_command_index "${arg}")
			action=${getopt_actions[$index_arg]}
					
			# execute action
			$action "${getopt_args[@]}"
			
			# no more options after command, all is transmitted to child command
			unset getopt_args
			
			# a command was executed
			getopt_arg_command=1
		fi
		
		return $res
	fi

	return 1
}

# Read arguments from cached command line
# return :
# 0: command line was read ok
# 1: incomplete command line
# 2: custom command found
function getopt_read_args() {
	res=0
	while [[ $res -eq 0 ]]
	do
		 getopt_read_arg
		 res=$?
	done
	
	if [ $res -eq 2 ]
	then
		# a custom command wa encountered and this is allowed
		return $res
	fi

	# at least a command was attempted but none found
	if [[ $getopt_has_command -eq 1 ]] && [[ $getopt_arg_command -eq 0 ]]
	then
		return 1
	fi

	return 0
}

function getopt_add_flag() {
	value=none
	type=0
	getopt_has_option=1

	if [ $# -eq 3 ]
	then
		short=none
		name=$1
		description=$2
		action=$3
	elif [ $# -eq 4 ]
	then
		short=$1
		name=$2
		description=$3
		action=$4
	else
		echo "getopt_add_flag: wrong parameters" >&2 
		exit 1
	fi
	
	getopt_names[$getopt_option_num]="$name"
	getopt_shorts[$getopt_option_num]="$short"
	getopt_values[$getopt_option_num]="$value"
	getopt_descriptions[$getopt_option_num]="$description"
	getopt_actions[$getopt_option_num]="$action"
	getopt_types[$getopt_option_num]="$type"
	
	(( getopt_option_num = getopt_option_num + 1 ))
}

function getopt_add_option() {
	type=1
	getopt_has_option=1
	
	if [ $# -eq 4 ]
	then
		short=none
		name=$1
		value=$2
		description=$3
		action=$4
	elif [ $# -eq 5 ]
	then
		short=$1
		name=$2
		value=$3
		description=$4
		action=$5
	else
		echo "getopt_add_option: wrong parameters" >&2 
		exit 1
	fi
	
	getopt_names[$getopt_option_num]="$name"
	getopt_shorts[$getopt_option_num]="$short"
	getopt_values[$getopt_option_num]="$value"
	getopt_descriptions[$getopt_option_num]="$description"
	getopt_actions[$getopt_option_num]="$action"
	getopt_types[$getopt_option_num]="$type"
	
	(( getopt_option_num = getopt_option_num + 1 ))
}

function getopt_add_action_flag() {
	type=2
	getopt_has_option=1
	
	if [ $# -eq 3 ]
	then
		short=none
		name=$1
		value=none
		description=$2
		action=$3
	elif [ $# -eq 4 ]
	then
		short=$1
		name=$2
		value=none
		description=$3
		action=$4
	else
		echo "getopt_add_action: wrong parameters" >&2 
		exit 1
	fi
	
	getopt_names[$getopt_option_num]="$name"
	getopt_shorts[$getopt_option_num]="$short"
	getopt_values[$getopt_option_num]="$value"
	getopt_descriptions[$getopt_option_num]="$description"
	getopt_actions[$getopt_option_num]="$action"
	getopt_types[$getopt_option_num]="$type"
	
	(( getopt_option_num = getopt_option_num + 1 ))
}

function getopt_add_command() {
	type=3
	getopt_has_command=1
	
	if [ $# -eq 3 ]
	then
		short=none
		name=$1
		value=none
		description=$2
		action=$3
	else
		echo "getopt_add_command: wrong parameters" >&2 
		exit 1
	fi
	
	getopt_names[$getopt_option_num]="$name"
	getopt_shorts[$getopt_option_num]="$short"
	getopt_values[$getopt_option_num]="$value"
	getopt_descriptions[$getopt_option_num]="$description"
	getopt_actions[$getopt_option_num]="$action"
	getopt_types[$getopt_option_num]="$type"
	
	(( getopt_option_num = getopt_option_num + 1 ))
}

function getopt_add_category() {
	type=4

	if [ $# -eq 1 ]
	then
		short=none
		name=$1
		value=none
		description=none
		action=none
	else
		echo "getopt_add_category: wrong parameters" >&2 
		exit 1
	fi
	
	getopt_names[$getopt_option_num]="$name"
	getopt_shorts[$getopt_option_num]="$short"
	getopt_values[$getopt_option_num]="$value"
	getopt_descriptions[$getopt_option_num]="$description"
	getopt_actions[$getopt_option_num]="$action"
	getopt_types[$getopt_option_num]="$type"
	
	(( getopt_option_num = getopt_option_num + 1 ))
}

function getopt_add_text() {
	type=5

	short=none
	name=$*
	value=none
	description=none
	action=none
	
	getopt_names[$getopt_option_num]="$name"
	getopt_shorts[$getopt_option_num]="$short"
	getopt_values[$getopt_option_num]="$value"
	getopt_descriptions[$getopt_option_num]="$description"
	getopt_actions[$getopt_option_num]="$action"
	getopt_types[$getopt_option_num]="$type"
	
	(( getopt_option_num = getopt_option_num + 1 ))
}

getopt_add_help() {
	getopt_add_action_flag "-h" "--help"   		   "Print usage" "getopt_usage; exit 1"
}