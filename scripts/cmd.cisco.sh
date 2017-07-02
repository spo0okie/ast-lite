#!/bin/sh

if [ -z "$2" ]; then
	echo "usage: $0 <cmd> <phone_num>"
	echo "cmd:"
	echo "	getxml: Load current phone config in XML format"
	echo "	reload: Reboot phone"
	exit 10
fi

if [ "$2" == "all" ]; then
	list=`asterisk -rx "sip show peers"|grep -v "(Unspecified)" | sed 's/\\// /' |awk "{print \\$1}" | grep -E '[0-9]{3,4}'`
	strlist=`echo $list| tr '\n' ' '`
	echo "Bulk $1 for $strlist in ..."
	for i in `seq 9 -1 1`; do
		echo "$i ..."
		sleep 1
	done
	asterisk -rx "module reload"
	for i in $list; do
		$0 $1 $i bulk
	done
	exit
fi


iptest=`echo "$2" |grep -E '([0-9]{1,3}[\.]){3}[0-9]{1,3}'`
if [ "$2" == "$iptest" ]; then
	echo "got phone IP"
	phone_addr=$2
else
	phone_addr=`asterisk -rx "sip show peer $2"|grep Addr- |cut -d: -f2|sed 's/ //g'`
fi

if [ -z "$3" ]; then
	for i in `seq 5 -1 1`; do
		echo "Phone $2 ($phone_addr); Will $1 in $i ..."
		sleep 1
	done
	asterisk -rx "module reload"
fi

case $1 in
	[Rr][Ee][Ll][Oo][Aa][Dd]|[Rr][Ee][Bb][Oo][Oo][Tt]|[Rr][Ee][Ss][Tt][Aa][Rr][Tt])
		curl "http://$phone_addr/admin/reboot"
		;;
	[Gg][Ee][Tt][Xx][Mm][Ll])
		curl "http://$phone_addr/admin/spacfg.xml"
		;;
	*)
		echo Unknown request. Use $0 -h for help
		;;
esac
