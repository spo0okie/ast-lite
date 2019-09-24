#!/bin/sh
if [ -z "$1" ]; then 
	echo "error"
	exit 10
fi

/usr/sbin/asterisk -rx"sip show registry"| grep $1| sed 's/ \+/ /g' | cut -d' ' -f5