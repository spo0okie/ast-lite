#!/bin/bash

now=`date +%s`
fname=/tmp/ast_callfiles/$now.call

from=$1
to=$2
delay=$3

/etc/asterisk/scripts/callfile.sh $1 $2 $3 &