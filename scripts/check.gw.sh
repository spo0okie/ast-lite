#!/bin/sh
#скрипт проверки соответствия текущего внешнего адреса и настройки внешнего адреса в asterisk

. /etc/asterisk/scripts/bash.lib.sh

#файл лога
statusfile=/var/log/asterisk/ext_ip
logfile=/var/log/asterisk/ext_ip.log

config=/etc/asterisk/sip_trunks.conf

#текущий внешний адрес 
natted_ext=`/usr/bin/wget -O - -q icanhazip.com|/bin/sed 's/ //g'`

#сконфигурированный адрес
config_ext=`/bin/cat $config | /bin/grep -v -E " *;" | /bin/grep externip= | /bin/cut -d"=" -f2 |/bin/sed 's/ //g'`

DATE=`/bin/date`


if [ -z "$natted_ext" ]; then
	set_error_flag 1
	stop "ERROR: Can't detect natted address"
fi

#проверка синтаксиса возвращенного адреса
if ! ( echo $natted_ext | grep '^\([0-9]\{1,3\}\.\?\)\{4\}$' ); then
	set_error_flag 1
	stop "ERROR: Can't detect natted address"
fi

if [ -z "$config_ext" ]; then
	set_error_flag 1
	stop "ERROR: Can't detect configured address"
fi

if [ "$natted_ext" != "$config_ext" ]; then
	#если адреса разъехались
	log "Current configured IP: $config_ext != natted: $natted_ext;	- Reconfig now"
	#делаем из старого конфиге новый, в котором подменяем внешний адрес на обнаруженный
	/bin/cat $config | /bin/sed "s/externip=$config_ext/externip=$natted_ext/" > $config.new__
	#подменяем сам конфиг
	mv $config.new__ $config
	#перепускаем сервис
	/sbin/service asterisk stop
	/sbin/service network restart
	/sbin/service asterisk start
else
	echo "Current configured: $config_ext;	natted: $natted_ext;	- All OK"
	echo $DATE
	echo "--------------------------------------------------------------------"
fi

set_error_flag 0
