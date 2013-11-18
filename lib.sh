#!/bin/bash

# wait-for $command $jqpattern $target
function wait-for {
	[[ $# = 3 ]] || { echo "Internal error calling wait-for" ; exit 99 ; }
	cmd=$1
	pattern=$2
	target=$3
	loop=1
	while [[ $loop -le 120 ]]
	do
		STATE=`$cmd | jq $pattern | sed -e 's/"\(.*\)"/\1/'`
		echo "State is: $STATE"
		if [[ $STATE == $target ]]; then
			return 0
		fi
		sleep 1
		loop=$(( $loop + 1 ))
	done
	return 1
}

# Check required programs are install
function check-installs {
	command -v aws >/dev/null 2>&1 || { echo >&2 "Need aws installed: http://aws.amazon.com/cli/.  Aborting."; exit 1; }
	command -v jq >/dev/null 2>&1 || { echo >&2 "Need jq installed: http://stedolan.github.io/jq/download/.  Aborting."; exit 1; }
}