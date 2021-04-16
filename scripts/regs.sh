#!/bin/bash
for i in `ls -1 /etc/asterisk/exten.tpl.org*.conf | sed s/[^0-9]//g`; do
	orgname=`head -n1 /etc/asterisk/org$i/_*`
	for reg in `egrep -v '^;' /etc/asterisk/org$i/sip_reg.conf | grep register | cut -d' ' -f3`; do
		phone=`echo $reg|cut -d'/' -f2`
		reg=`echo $reg|cut -d'/' -f1`
		server=`echo $reg|cut -d'@' -f2`
		reg=`echo $reg|cut -d'@' -f1`
		ulogin=`echo $reg|cut -d':' -f1`
		upass=`echo $reg|cut -d':' -f2`

		echo org$i	$orgname	$phone	$server	$ulogin	$upass
	done
done;