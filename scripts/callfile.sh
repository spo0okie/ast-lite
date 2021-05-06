#!/bin/bash

now=`date +%s`
fname=/tmp/ast_callfiles/$now.call

from=$1
to=$2
delay=$3

if [ -n "$delay" ]; then
	sleep $delay
fi
mkdir -p /tmp/ast_callfiles

echo "Channel: Local/$from@org1_phones" > $fname
echo "Callerid: Вызов $to<$from>" >> $fname
echo "WaitTime:15" >> $fname
echo "Account: 1" >> $fname
echo "Context: org1_phones" >> $fname
echo "Extension: $to" >> $fname
echo "Priority: 1" >> $fname
mv $fname /var/spool/asterisk/outgoing