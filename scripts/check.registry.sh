#!/bin/sh
log=/var/log/ast.trunk.registry

online=`/usr/sbin/asterisk -rx "sip show registry"|grep "Registered"|wc -l`
RES="OK"
if [ "$online" == 0 ]; then
	sleep 30
	online=`/usr/sbin/asterisk -rx "sip show registry"|grep "Registered"|wc -l`
	if [ "$online" == 0 ]; then
		/usr/sbin/asterisk -rx "sip reload" > /dev/null
		sleep 5
		online=`/usr/sbin/asterisk -rx "sip show registry"|grep "Registered"|wc -l`
		if [ "$online" == 0 ]; then
			RES="ERR"
		fi
	fi
fi
echo $RES > $log