#!/bin/sh
#скрипт проверки доступности удаленного узла, и взятия на себя функции принятия звонков в случае его недоступности\
#логика скрипта такая:
#есть стандартная схема: звонки поставляет ПРОВАЙДЕР на НОДУ по умолчанию, а она распределяет вызовы по остальным нодам.
#так вот если мы обнаруживаем, что у нас ситуация когда ПРОВАЙДЕР доступен а НОДА нет, то мы забираем регистрацию на себя
#в любом ином случае мы отказываемся брать на себя такой функционал: если НОДА доступна - то она сама отработает, 
#если ПРОВАЙДЕР недоступен, то мы ничего не примем

. /etc/asterisk/scripts/bash.lib.sh

#файл лога
logfile=/var/log/asterisk/incoming.failover.log

#конфиг в который будет инклудиться конфиг с настройками для резервинования
config=/etc/asterisk/sip_trunks.conf

#сокращение в переменных icf = incoming calls failover
icf_main_peer_desc="icf_main_peer misconfigured? must content name of default peer for incoming calls acceptance."
icf_prov_trunk_desc="icf_prov_trunk misconfigured? must content name of provider trunk which sends incoming calls."

#настройки этой ноды в кластере отказоустойчивых серверов астериск
require /etc/asterisk/node.conf

check_var "icf_conf" "Must content name of file with failover config"
check_var "icf_main_peer" "$icf_main_peer_desc"
check_var "icf_prov_trunk" "$icf_prov_trunk_desc"

#включает или выключает конфигурацию для резервирования (коментирует или раскомментирует инклуд файла с конфигурацией)
set_config() {
	config_line="#include $icf_conf"
	log "set_config(): Switching failover mode to $1"
	case "$1" in
		on)
			#включить резервирование - раскомментировать подключение конфига с регистрацией
			sed_file $config "s/;$config_line/$config_line/"
			;;
		off)
			#выключить резервирование - закомментировать подключение конфига с регистрацией
			sed_file $config "s/$config_line/;$config_line/"
			;;
		*)
			stop "set_config(): Incorrect request [$1]; must be <on|off>"
			;;
	esac
}

#возвращает текущую настройку резервирования в конфиге (включен/выключен)
get_config() {
	config_on=`/bin/cat $config | /bin/grep -E "^#include $icf_conf" | wc -l`
	config_off=`/bin/cat $config | /bin/grep -E "^;#include $icf_conf" | wc -l`

	case "$config_on-$config_off" in
		1-0)
			echo "on"
			;;
		0-1)
			echo "off"
			;;
		*)
			stop "config error"
			;;
	esac
}

#возвращает текущую необходимость во включении резервирования
set_status() {
	main_peer_status=$(ast_peer_status $icf_main_peer)
	prov_trunk_status=$(ast_peer_status $icf_prov_trunk)
	check_var "main_peer_status" "$icf_main_peer_desc. Current value is [$icf_main_peer]"
	check_var "prov_trunk_status" "$icf_prov_trunk_desc. Current value is [$icf_prov_trunk]"
	if [ "$main_peer_status" != "OK" ] && [ "$prov_trunk_status" == "OK" ]; then
		status_now="on"
	else
		status_now="off"
	fi
}

config_now=$(get_config)
set_status

if [ "$config_now" != "$status_now" ]; then
	sleep 45
	config_now=$(get_config)
	set_status
	if [ "$config_now" != "$status_now" ]; then
		log "Got misconfiguration: remote_peer is [$main_peer_status], prov_trunk is [$prov_trunk_status], failover must be [$status_now], failover cofig is [$config_now]"
		set_config $status_now
		#/usr/sbin/asterisk -rx "sip reload"
	fi
fi


