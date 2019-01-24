#!/bin/bash
# 
# This file is part of the bash-getopt distribution (https://github.com/turdusmerula/bash-getopt).
# Copyright (c) 2015 Sebastien Besombes.
# 
# This program is free software: you can redistribute it and/or modify  
# it under the terms of the GNU General Public License as published by  
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

version=1.1.1
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

# indicates number of waited parameters (-1 indicates infinite)
getopt_parameters_count=0

# indicates which params where alreay encountered
getopt_current_parameter=0

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
# - 2 action flag
# - 3 command
# - 4 category
# - 5 free text
# - 6 action option
# - 7 parameter

# Show available options
function getopt_show_options() {
    local i=0
    local type
    for type in "${getopt_types[@]}"
    do
        local short=${getopt_shorts[i]}
        local name="${getopt_names[i]}"
        local value=${getopt_values[i]}
        local description=${getopt_descriptions[i]}
        
        # flag or option or action_flag or action_option
        if [ ${type} -eq 0 ] || [ ${type} -eq 1 ] || [ ${type} -eq 2 ] || [ ${type} -eq 6 ]
        then
            
            if [ "_$short" == "_none" ]
            then
                local option_name=''
            else
                local option_name=$(printf "%2s, " $short)
            fi                
        	option_name="${option_name}${name}"
            
            if [[ "${getopt_values[$i]}" != "none" ]]
            then
                printf "\t%-30s%s\n" "${option_name} ${value}" "${description}" >&2
            else
                printf "\t%-30s%s\n" "${option_name}" "${description}" >&2
            fi
        fi
        
        # command
        if [ ${type} -eq 3 ]
        then
            printf "\t%-30s%s\n" "${name}" "${description}" >&2
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

function getopt_show_parameters() {
    local i=0
    local type
    for type in "${getopt_types[@]}"
    do
        local short=${getopt_shorts[i]}
        local name="${getopt_names[i]}"
        local value=${getopt_values[i]}
        local description=${getopt_descriptions[i]}
        
        # parameter
        if [ ${type} -eq 7 ]
        then
            printf "\t%-30s%s\n" "${name}" "${description}" >&2
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
    [ $getopt_parameters_count -ne 0 ] && echo>&2 && echo "Parameters:" >&2
    getopt_show_parameters
}

function getopt_add_param_description() {
    getopt_param_description="$*"
    return 0    
}

function getopt_allow_custom_command() {
    getopt_custom_command=1
    return 0
}

# return:
# 0: name exist
# 1: name does not exist
function getopt_check_name_exist() {
    local name="$1"
    
    local short
    for short in "${getopt_shorts[@]}"
    do
        if [[ "_$name" == "_$short" ]]
        then
            return 0
        fi
    done

	local option
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
    local name="$1"
    
    local i=0
    local short
    for short in "${getopt_shorts[@]}"
    do
        local type=${getopt_types[$i]}
        if [[ "_$name" == "_$short" ]] && ( [[ $type -eq 0 ]] || [[ $type -eq 1 ]] || [[ $type -eq 2 ]] || [[ $type -eq 6 ]] )
        then
            return 0
        fi
    
        (( i = i + 1 ))
    done

    local i=0
    local option
    for option in "${getopt_names[@]}"
    do
        local type=${getopt_types[$i]}
        if [[ "_$name" == "_$option" ]] && ( [[ $type -eq 0 ]] || [[ $type -eq 1 ]] || [[ $type -eq 2 ]] || [[ $type -eq 6 ]] )
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
    local name="$1"
    
    local i=0
    local option
    for option in "${getopt_names[@]}"
    do
        local type=${getopt_types[$i]}
        if [[ "_$name" == "_$option" ]] && [[ $type -eq 3 ]]
        then
            return 0
        fi
        (( i = i + 1 ))
    done

    return 1
}

# return:
# 0: parameter exist
# 1: parameter does not exist
function getopt_check_parameter_exist() {
    local i=0
    local ip=0
    local option
    for option in "${getopt_names[@]}"
    do
        local type=${getopt_types[$i]}
        if [[ $getopt_parameters_count -eq -1 ]]
        then
        	return 0
        fi
        if [[ $type -eq 7 ]] && [[ $ip -ge $getopt_current_parameter ]] 
        then
            return 0
        fi
        if [[ $type -eq 7 ]]
    	then
    		(( ip = ip + 1 ))
    	fi 
		(( i = i + 1 ))
    done

    return 1
}

# return:
# 0: name exist
# 1: name does not exist
function getopt_check_name_index() {
    local name="$1"
    
    local i=0
    local short
    for short in "${getopt_shorts[@]}"
    do
        if [[ "_$name" == "_$short" ]]
        then
            echo $i
            return 0
        fi
        (( i = i + 1 ))
    done

    local i=0
    local option
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
    local name="$1"
    
    local i=0
    local short
    for short in "${getopt_shorts[@]}"
    do
        local type=${getopt_types[$i]}
        if [[ "_$name" == "_$short" ]] && ( [[ $type -eq 0 ]] || [[ $type -eq 1 ]] || [[ $type -eq 2 ]] || [[ $type -eq 6 ]] )
        then
            echo $i
            return 0
        fi
        (( i = i + 1 ))
    done

    local i=0
    local option
    for option in "${getopt_names[@]}"
    do
        local type=${getopt_types[$i]}
        if [[ "_$name" == "_$option" ]] && ( [[ $type -eq 0 ]] || [[ $type -eq 1 ]] || [[ $type -eq 2 ]] || [[ $type -eq 6 ]] )
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
    local name="$1"
    
    local i=0
    local option
    for option in "${getopt_names[@]}"
    do
        local type=${getopt_types[$i]}
        if [[ "_$name" == "_$option" ]] && [[ $type -eq 3 ]]
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
function getopt_check_current_parameter_index() {
    local name="$1"
    
    if [[ $getopt_parameters_count -eq 0 ]]
    then
    	return 1
    fi
   
    local i=0
    local ip=0
    local option
    for option in "${getopt_names[@]}"
    do
        local type=${getopt_types[$i]}
        if [[ $type -eq 7 ]]
        then
        	if [[ $ip -eq $getopt_current_parameter ]]
        	then
        		echo $i
        		return 0
    		fi
			(( ip = ip + 1 ))
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

# shift n arguments to left
# @param n number of arguments to shift
function getopt_shift_arg() {
    local n=$1
    [ -z "$n" ] && n=1
    
    local n
    for i in $(seq 1 $n)
    do
        getopt_args=("${getopt_args[@]:1}")
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
        
        if [[ "_${arg}" == "_--" ]] && [[ $getopt_parse_options -eq 1 ]]
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
            
            local i=$(getopt_check_option_index "${filt_arg}")
            local value=${getopt_values[$i]}
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
            local index_arg=$i
        
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
                    getopt_args[0]="${filt_arg:2}"
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
    
            local i=$(getopt_check_option_index "-${short_arg}")
            local value=${getopt_values[$i]}
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
            local filt_arg=$short_arg
            local index_arg=$i
        fi
        
        # treat associated action
        local type=${getopt_types[$index_arg]}
        if [[ $type -eq 0 ]]
        then
            # set flag value
            eval "export ${getopt_actions[$i]}=1"
        elif [[ $type -eq 1 ]]
        then
            # set option value
            eval "export ${getopt_actions[$i]}='$value_arg'"            
        elif [[ $type -eq 2 ]]
        then
            # set action value
            eval "${getopt_actions[$i]}"            
        elif [[ $type -eq 6 ]]
        then
            # set action value
            eval "${getopt_actions[$i]}"            
        fi
        
        return 0
        
    else
        # command or parameter detected

        local res=0

		local read_command=0
        [ $getopt_parameters_count -ne 0 ] && getopt_check_parameter_exist
        if [[ $? -eq 0 ]]
		then
			local read_parameter=0
			if [[ $getopt_parameters_count -eq -1 ]]
			then
				read_parameter=1
			elif [[ $getopt_current_parameter -lt $getopt_parameters_count ]]
			then
				read_parameter=1
			else
				read_command=1
			fi
		else
			 read_command=1
       	fi
			
		if [[ $read_parameter -eq 1 ]]
		then
            # parameter was read, remove it
            getopt_args=("${getopt_args[@]:1}")
        
            # get parameter index
            local index_arg=$(getopt_check_current_parameter_index)
            local action=${getopt_actions[$index_arg]}
                    
            # set parameter value
            eval "export ${action}='${arg}'"            
        
       		(( getopt_current_parameter = getopt_current_parameter + 1 ))
		elif [[ $getopt_has_command -eq 0 ]]
		then
            if [[ $getopt_custom_command -eq 0 ]]
            then
	            echo "$(basename $0): unknown parameter '$arg'" >&2
	            exit 1
	        else
				read_command=1
	        fi
       	fi

		if [[ $read_command -eq 1 ]]
		then       
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
	            local index_arg=$(getopt_check_command_index "${arg}")
	            local action=${getopt_actions[$index_arg]}
	                    
	            # execute action
	            $action "${getopt_args[@]}" || exit $?
	            
	            # no more options after command, all is transmitted to child command
	            unset getopt_args
	            
	            # a command was executed
	            getopt_arg_command=1
	        fi
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
    local res=0
    while [[ $res -eq 0 ]]
    do
         getopt_read_arg
         res=$?
    done
    
    if [[ $getopt_parameters_count -gt 0 ]]
    then
    	if [[ $getopt_current_parameter -lt $getopt_parameters_count ]]
		then
            local index_arg=$(getopt_check_current_parameter_index)
            echo "$(basename $0): missing ${getopt_names[$index_arg]}" >&2
            exit 1
		fi			
    fi
   
    if [ $res -eq 2 ]
    then
        # a custom command was encountered and this is allowed
        return $res
    fi

    # at least a command was attempted but none found
    if [[ $getopt_has_command -eq 1 ]] && [[ $getopt_arg_command -eq 0 ]]
    then
        return 1
    fi

    return 0
}

# Shift left arguments from getopt_args
# @param count Number (default 1)
function getopt_shift() {
    if [ "_$1" == "_" ]
    then
        local count=1
    else
        local count=$1
    fi
    
    while [[ count -ne 0 ]]
    do
        # command was read, remove it
        getopt_args=("${getopt_args[@]:1}")
        
        (( count = count -1 ))
    done
    
}

function getopt_add_flag() {
    local value=none
    local type=0
    getopt_has_option=1

    if [ $# -eq 3 ]
    then
        local short=none
        local name=$1
        local description=$2
        local action=$3
    elif [ $# -eq 4 ]
    then
        local short=$1
        local name=$2
        local description=$3
        local action=$4
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
    local type=1
    getopt_has_option=1
    
    if [ $# -eq 4 ]
    then
        local short=none
        local name=$1
        local value=$2
        local description=$3
        local action=$4
    elif [ $# -eq 5 ]
    then
        local short=$1
        local name=$2
        local value=$3
        local description=$4
        local action=$5
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

function getopt_add_parameter() {
        local type=7

        if [ $# -eq 3 ]
        then
                local short=none
                local name=$1
                local value=none
                local description=$2
                local action=$3
        else
                echo "getopt_add_parameter: wrong parameters" >&2
                exit 1
        fi

        getopt_names[$getopt_option_num]="$name"
        getopt_shorts[$getopt_option_num]="$short"
        getopt_values[$getopt_option_num]="$value"
        getopt_descriptions[$getopt_option_num]="$description"
        getopt_actions[$getopt_option_num]="$action"
        getopt_types[$getopt_option_num]="$type"

        (( getopt_parameters_count = getopt_parameters_count + 1 ))
	    (( getopt_option_num = getopt_option_num + 1 ))
}

function getopt_add_action_flag() {
    local type=2
    getopt_has_option=1
    
    if [ $# -eq 3 ]
    then
        local short=none
        local name=$1
        local value=none
        local description=$2
        local action=$3
    elif [ $# -eq 4 ]
    then
        local short=$1
        local name=$2
        local value=none
        local description=$3
        local action=$4
    else
        echo "getopt_add_action_flag: wrong parameters" >&2 
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

function getopt_add_action_option() {
    local type=6
    getopt_has_option=1
    
    if [ $# -eq 4 ]
    then
        local short=none
        local name=$1
        local value=$2
        local description=$3
        local action=$4
    elif [ $# -eq 5 ]
    then
        local short=$1
        local name=$2
        local value=$3
        local description=$4
        local action=$5
    else
        echo "getopt_add_action_option: wrong parameters" >&2 
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
    local type=3
    getopt_has_command=1
    
    if [ $# -eq 3 ]
    then
        local short=none
        local name=$1
        local value=none
        local description=$2
        local action=$3
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
    local type=4

    if [ $# -eq 1 ]
    then
        local short=none
        local name=$1
        local value=none
        local description=none
        local action=none
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
    local type=5

    local short=none
    local name=$*
    local value=none
    local description=none
    local action=none
    
    getopt_names[$getopt_option_num]="$name"
    getopt_shorts[$getopt_option_num]="$short"
    getopt_values[$getopt_option_num]="$value"
    getopt_descriptions[$getopt_option_num]="$description"
    getopt_actions[$getopt_option_num]="$action"
    getopt_types[$getopt_option_num]="$type"
    
    (( getopt_option_num = getopt_option_num + 1 ))
}

getopt_add_help() {
    getopt_add_action_flag "-h" "--help"              "Print usage" "getopt_usage; exit 1"
}
