#!/bin/sh
#скрипт проверки регистраций. никаких настроек не требует
#если регистрации настроены в астериске, то он будет проверять что они работоспособны
#если регистраций не настроено, то и проверять нечего

. /etc/asterisk/scripts/bash.lib.sh

status=/var/log/asterisk/trunk.registered
logfile=$status.log

#общее количество настроенных регистраций
ast_total_registry
#текущее количество успешных регистраций
ast_online_registry

log "Got $online of $total registrations"

RES="1"

if [ "$total" != 0 ] && [ "$online" == 0 ]; then
	log "Waiting gor 30 secs for registartion self restore"

	sleep 30

	ast_online_registry
	if [ "$online" == 0 ]; then
		log "No luck, reloading sip module ... "

		/usr/sbin/asterisk -rx "sip reload" > /dev/null
		sleep 5

		ast_online_registry
		if [ "$online" == 0 ]; then
			RES="0"
		else
			log "Reload restored $online of $total registrations"
		fi

	else
		log "Self restored $online of $total registrations"
	fi
fi

echo $RES > $status