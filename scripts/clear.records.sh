#!/bin/bash
if [ -z "$1" ]; then
	echo "Usage: $0 <org_name> [days=180] [action=echo]"
	exit
fi
org=$1
i=180
if [ -n "$2" ]; then
	i=$2
fi
cmd=echo
if [ -n "$3" ]; then
	cmd=$3
fi
find /home/record/$1 -type f -mtime +$i -exec $cmd -f {} \;