#!/bin/sh
#скрипт отправки записи на почту
#
usage="Usage: $0 <muttrc> <to_addr> <subject> <message>"
if [ -z "$5" ]; then
	echo $usage
	exit 1
fi

muttrc=$1
to=$2
subject=$3
message=$4

echo -e $message | /usr/bin/mutt -F $muttrc -s "$subject" -- $to
