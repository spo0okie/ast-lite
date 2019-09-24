#!/bin/sh
#скрипт отправки записи на почту
#
usage="Usage: $0 <file> <muttrc> <to_addr> <subject> <message>"
if [ -z "$5" ]; then
	echo $usage
	exit 1
fi

muttrc=$2
to=$3
subject=$4
message=$5

input=${1%.wav}
input=${input%.mp3}

#если есть WAV то жмем его
if [ -r "$input.wav" ]; then
	/etc/asterisk/scripts/endrec_compress.sh $input
fi

#если есть MP3 то отправляем его
if [ -r "$input.mp3" ]; then
	echo -e $message | /usr/bin/mutt -F $muttrc -a "$input.mp3" -s "$subject" -- $to
else
	echo "$input.mp3 not found"
fi