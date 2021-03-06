# bash-getopt

A customizable version of getopt for bash.

bash-getopt allows to add complex option patterns to your scripts with as many as sublevels as needed.

## Install

Do a ```make install```, the script will then be available at ```/usr/local/share/getopt/getopt.sh```

Note: bash-getopt is made with only one script ```getopt.sh``` allowing you to embed it directly inside your code source.

## Usage

Source the script 

```
source /usr/local/share/getopt/getopt.sh
```

It will add some functions to describe the script input options inside, exemple:

```
opt_config=$HOME/.docker
opt_debug=0
opt_tls=0


getopt_command_description="COMMAND"
getopt_add_option "-c" "--config" "string" "Location of client config files (default $opt_config)" opt_config
getopt_add_flag   "-D" "--debug"  		   "Enable debug mode" opt_debug
getopt_add_help
getopt_add_flag 	   "--tls"    		   "Use TLS; implied by --tlsverify" opt_tls

getopt_add_category "Management commands"
getopt_add_command "container" "Manage containers" ${xpl_path}/action/container.sh

getopt_add_category "Commands"
getopt_add_command "attach" "Attach to a running container" ${xpl_path}/action/attach.sh

getopt_add_text "\nRun '$(basename $0) COMMAND --help' for more information on a command.\n"

getopt_set_args "$@" 

getopt_read_args || {
	getopt_usage
	exit 1
}

echo "$(basename $0): opt_config: $opt_config"
echo "$(basename $0): opt_debug: $opt_debug"
echo "$(basename $0): opt_tls: $opt_tls"
```
This will result in help menu showing when no parameter is given or with ```--help```:

```
Usage: docker 

Options:
  -c, --config string               Location of client config files (default /home/yeah/.docker)
  -D, --debug                       Enable debug mode
  -h, --help                        Print usage
      --tls                         Use TLS; implied by --tlsverify

Management commands:
  container                     Manage containers

Commands:
  attach                        Attach to a running container

Run 'docker COMMAND --help' for more information on a command.
```
See the tests to have a full overview of bash-getopts capacity.

### getopt_command_description

Set the prompt in the command line with a custom pattern.

### getopt_add_flag

Add a flag to the option list, flags do not allow any user custom value.

Takes 4 parameters:

  * shorthand name of the option prefixed by ```-```, one letter size. This parameter is Optional.
  * full name of the option prefixed by ```--```.
  * description of the option.
  * variable name that will take the option value.

### getopt_add_action_flag

Add a flag to the option list, flags do not allow any user custom value.

This option differs from ```getopt_add_flag``` as it allow to specify a custom action instead of filling a variable.

Takes 4 parameters:

  * shorthand name of the option prefixed by ```-```, one letter size. This parameter is Optional.
  * full name of the option prefixed by ```--```.
  * description of the option.
  * action to execute.

Exemple, for the ```--help``` option you will find the following action ```getopt_usage; exit 1``` that show usage and exits immediately.

### getopt_add_action_option

Add an option to the option list with a custom parameter.

This option differs from ```getopt_add_option``` as it allow to specify a custom action instead of filling a variable.

Takes 5 parameters:

  * shorthand name of the option prefixed by ```-```, one letter size. This parameter is Optional.
  * full name of the option prefixed by ```--```.
  * description of the expected value.
  * description of the option.
  * action to execute.

Inside the action you can access to the content of the option value with the ```value_arg``` variable .

### getopt_add_option

Add an option to the list, options are waiting for the user to fill a value.

Takes 4 parameters:

  * shorthand name of the option prefixed by ```-```, one letter size. This parameter is Optional.
  * full name of the option prefixed by ```--```.
  * description of the expected value.
  * description of the option.
  * variable name that will take the option value.

### getopt_add_help

Add the ```--help``` option automatically.

### getopt_add_command

Add a command to be executed, a command is a subscript who takes remaining parameters to parse in input.

Takes 4 parameters:

  * name of the command.
  * description of the command.
  * path of the script to be executed.

### getopt_add_parameter

Add mandatory parameter to be given.

Takes 4 parameters:

  * name of the parameter.
  * description of the parameter.
  * variable name that will take the parameter value.

### getopt_add_category

Add a new category inside the usage function. 

### getopt_add_text

Add a free text inside the usage function, this allow to add hints or custom notes.

### getopt_read_args

Reads the cached command line and parse it.

Returns:

  * 0: the whole command line was read ok
  * 1: the command was not complete (waited a command)
  * 2: a custom command was encountered and should be treated by script

### getopt_read_arg

Takes from the cached command line the next argument and do associated action.

Returns:

  * 0: and argument was read ok
  * 1: nothing was read
  * 2: a custom command was encountered and should be treated by script

### getopt_shift

Shift arguments from the cached command line and drop them.

Takes 1 parameter:

  * optional: number of arguments to shift, 1 by default.

### getopt_set_args

Push some commands in cache. This function should be called before reading arguments to push them in cache.

The call is usualy made from the whole command line:

```
getopt_set_args "$@"
```

You can also give arguments from a custom array:

```
getopt_set_args "${array[@]}"
```

### getopt_allow_custom_command

Allow ```getopt_read_args``` to not fail if an unknown command is found, allowing to add custom behavior.

```getopt_read_args``` will stop gracefuly and give 2 as result indicating that it has encountered an unknown command, you can then add a special behavior to treat it:

```
getopt_read_args
res=$?
[[ $res -eq 1 ]] && {
	# wrong option or premature end
	getopt_usage
	exit 1
}
[[ $res -eq 2 ]] && {
	# custom command, add your own action
	echo "Custom regex: ${getopt_args[*]}"
}
```
