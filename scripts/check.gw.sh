#!/bin/bash
#скрипт проверки соответствия текущего внешнего адреса и настройки внешнего адреса в asterisk
PROGPATH=/etc/asterisk/scripts

. $PROGPATH/lib/lib_core.sh


#файл лога
logfile=/var/log/asterisk/ext_ip.log
#файл статуса
statusfile=/var/log/asterisk/ext_ip
#конфиг
config=/etc/asterisk/sip_trunks.conf

lmsg "Script started -----"
msgGetExt="Getting external IP"
natted_ext=`/usr/bin/wget --no-proxy -O - -q icanhazip.com|/bin/sed 's/ //g'`

if ! ( echo $natted_ext | grep '^\([0-9]\{1,3\}\.\?\)\{4\}$' > /dev/null ); then
	set_error_flag 1
	lmsg_err "$msgGetExt" ERR
	halt "Can't detect natted address"
else
	lmsg_ok "$msgGetExt" "$natted_ext"
fi


msgGetCfg="Getting configured IP"
#сконфигурированный адрес
config_ext=`/bin/cat $config | /bin/grep -v -E " *;" | /bin/grep externip= | cut -d"=" -f2 |/bin/sed 's/ //g'`

if ! ( echo $config_ext | grep '^\([0-9]\{1,3\}\.\?\)\{4\}$' > /dev/null ); then
	set_error_flag 1
	lmsg_err "$msgGetCfg" ERR
	halt "Can't detect configured address"
else
	lmsg_ok "$msgGetCfg" "$config_ext"
fi


if [ "$natted_ext" != "$config_ext" ]; then
	#если адреса разъехались
	lmsg_err "Current configured IP: $config_ext != natted: $natted_ext" "Reconfig now"
	#делаем из старого конфиге новый, в котором подменяем внешний адрес на обнаруженный
	/bin/cat $config | /bin/sed "s/externip=$config_ext/externip=$natted_ext/" > $config.new__
	#подменяем сам конфиг
	if [ -s $config.new__ ]; then
		mv $config.new__ $config
		#перепускаем сервис
		/sbin/asterisk -rx'sip reload'
		modprobe ip_conntrack
	else
		set_error_flag 1
		halt "genered config file is zero-sized"
	fi
else
	lmsg_ok "Current configured: $config_ext == natted: $natted_ext" "All OK"
fi

set_error_flag 0
