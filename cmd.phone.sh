#!/bin/bash

if [ -z "$2" ]; then
	echo "usage: $0 <cmd> <phone_num>"
	echo "cmd:"
	echo "	getxml: Load current phone config in XML format"
	echo "	reload: Reboot phone"
	exit 10
fi

#файл кастомных настроек провижна для этого сервера
phoneprov_priv=/etc/asterisk/phoneprov.priv.conf

#timeout перед выполнением команды
timeout=2

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
	for i in `seq $timeout -1 1`; do
		echo "Phone $2 ($phone_addr); Will $1 in $i ..."
		sleep 1
	done
	asterisk -rx "module reload"
fi

#берем пароль из файла провижна
if [ -f $phoneprov_priv ]; then
	password=`grep WEBADMIN /etc/asterisk/phoneprov.priv.conf | cut -d"=" -f3`
fi
#если неудача
if [ -z "$password" ]; then
	password=admin
fi

#пытаемся выяснить что за модель телефона:
echo Supposing Cisco ...
title=`curl -s http://$phone_addr/|grep -E '<title>SPA[0-9]+G? Configuration Utility</title>'`
if [ -n "$title" ]; then
	echo Cisco SPA detected
	model=CiscoSPA
fi

echo Supposing Yealink ...
title=`curl -s "http://$phone_addr/servlet?m=mod_listener&p=login&q=loginForm&jumpto=status"|grep -E '<title>Yealink T[0-9]+P Phone</title>'`
if [ -n "$title" ]; then
	echo Yealink detected
	model=Yealink
fi

if [ -z "$model" ]; then
	echo Supposing Grandstream ...
	title=`curl -s http://$phone_addr/json/configs/model.define.js|grep '"model":'`
	if [ -n "$title" ]; then
		echo Grandstream detected
		model=Grandstream
	fi
fi

if [ -z "$model" ]; then
	echo "Unknown vendor or phone unreachable"
	exit 11
fi


case $1 in
	[Rr][Ee][Ll][Oo][Aa][Dd]|[Rr][Ee][Bb][Oo][Oo][Tt]|[Rr][Ee][Ss][Tt][Aa][Rr][Tt])
		case $model in
		Grandstream)
			#в случае удачного запроса на логин по урлу ниже, телефон отдает номер сессии в JSON
			#надо его оттуда выкусить
			sid=$(curl -s \
			-H "Referer: http://$phone_addr/" \
			-H "Origin: http://$phone_addr" \
			-c /tmp/cookies.txt \
			-d "username=admin&password=$password" \
			http://$phone_addr/cgi-bin/dologin \
			| sed -r 's|.*"sid": "([0-9a-z]+)".*|\1|' )
		
			echo $sid
			#с этим СИДом запрашиваем перезагрузку
			curl -i -v \
			-H "Referer: http://$phone_addr/" \
			-H "Origin: http://$phone_addr" \
			-b /tmp/cookies.txt \
			-d "request=REBOOT&sid=$sid" \
			http://$phone_addr/cgi-bin/api-sys_operation
			;;
		CiscoSPA)
			curl --user admin:$password "http://$phone_addr/admin/reboot"
			;;

		Yealink)
			curl --user admin:$password "http://$phone_addr/servlet?key=Reboot"
			;;
		esac
		;;
	[Gg][Ee][Tt][Xx][Mm][Ll])
		curl "http://$phone_addr/admin/spacfg.xml"
		;;
	*)
		echo Unknown request. Use $0 -h for help
		;;
esac
