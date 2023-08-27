#!/bin/bash
# выдергивание деэурного из расписания из БД
# v1.0 просто работает, выдергивает расписание по ID
# v1.1 обработка сценария когда у дежурного 2 телефона
# v1.2 конфигурация вынесена в config.priv

. /etc/asterisk/scripts/config.priv.sh

log=/var/log/asterisk/techsuport.switch.log
response=`wget --no-proxy --timeout=15 --tries=1 $inventoryUrl/schedules/meta-status?id=$techSupportScheduleId -O - -q`

strdate=`date '+%Y-%m-%d %H:%M:%S'`
if [ -z "$response" ]; then
	echo "$strdate reading data failed"
	exit 10
fi



if [ "$response" == "{}" ]; then
	#echo "turning off schedule" >> $log
	phone=$techSupportNowork
else
	user=`echo "$response" | jq -r .user`

	if [ -z "$user" ]; then
		echo "$strdate error parsing user" >> $log
		exit 20
	fi

	#echo "searching phone for user $user >> $log"
	phone=`wget --no-proxy --timeout=15 --tries=1 $inventoryUrl/api/phones/search-by-user?login=$user -O - -q | xargs | cut -d',' -f1`
	name=`wget --no-proxy --timeout=15 --tries=1 $inventoryUrl/api/users/view?login=$user -O - -q | jq -r .Ename|cut -d ' ' -f1`

	if [ -z "$phone" ]; then
		echo "$strdate reading phone data failed" >> $log
		exit 30
	fi

fi

current=`/usr/sbin/asterisk -rx "database get techsupport org1_duty"|grep Value|cut -d':' -f2|xargs`

if [ -z "$current" ]; then
	echo "$strdate reading current duty phone data failed" >> $log
	exit 40
fi


echo "[$phone] vs [$current] //$name"
echo "$strdate switching to $phone ($name)" >> $log
/usr/sbin/asterisk -rx "database put techsupport org1_duty $phone" >> $log
/usr/sbin/asterisk -rx "database put techsupport org1_duty_name $name" >> $log
/etc/asterisk/scripts/wsSend.php $techSupportWS 2346 '/dash' "{\"event\":\"techSupportShift\",\"phone\":$phone}"

