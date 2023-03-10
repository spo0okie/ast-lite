#!/bin/bash



now=`date`
log=/var/log/asterisk/bitrix/$1.log

if [ "$1" == "register" ]; then
	usage="$0 register org1 callerId direction external_phone bitrix_user_id [recordfile]"
	if [ -z $6 ]; then
		echo "usage: $usage"
		exit 10
	fi

	#USER_PHONE_INNER	Внутренний номер пользователя. Обязательный.	string
	USER_PHONE_INNER=$3

	#Обязательный. Тип звонка:
	#1 - исходящий
	#2 - входящий
	#3 - входящий с перенаправлением
	#4 - обратный
	if [ "$4" == "in" ]; then
		TYPE=2
	else
		TYPE=1
	fi

	#PHONE_NUMBER	Номер телефона. Обязательный	string
	PHONE_NUMBER=`echo $5| sed 's/^\+7/8/'`

	#USER_ID	Идентификатор пользователя. Обязательный.	int
	USER_ID=$6

	#CALL_START_DATE	Дата/время звонка в формате iso8601. Обратите внимание, что в дате необходимо передавать часовой пояс, для избежания искажения времени звонка. Пример: 2021-02-03T18:25:10+03:00 .	string
	#CRM_CREATE	[0/1] - Автоматическое создание в CRM сущности, связанной со звонком. При необходимости, создает в CRM лид или сделку, в зависимости от настроек и режима работы CRM . Обратите внимание, что дело звонка создается при любом значении этого параметра, если создание возможно.

	CRM_CREATE=1
	json="{\"TYPE\":$TYPE,\"USER_PHONE_INNER\":"$USER_PHONE_INNER",\"USER_ID\":$USER_ID,\"PHONE_NUMBER\":"$PHONE_NUMBER",\"CRM_CREATE\":$CRM_CREATE}"
	echo "$now > $json" >> $log
	callID=`curl -s -X POST -H "Content-Type: application/json" -d $json https://goya-consult.bitrix24.ru/rest/48/y3zrfjwi35bgb5we/telephony.externalcall.register.json | jq -r .result.CALL_ID |sed 's/\n//'`
	echo "$now < $callID" >> $log

	if [ -n "$7" ]; then
		echo -e "USER_ID:$USER_ID\nCALL_ID:$callID" > $7.btx
	fi
	echo -n $callID
fi


if [ "$1" == "finish" ]; then

	usage="$0 attachRecord recordfile callId userId"

	if [ -f "$2.btx" ]; then
		CALL_ID=`grep CALL_ID "$2.btx"|cut -d':' -f2`
		USER_ID=`grep USER_ID "$2.btx"|cut -d':' -f2`
	else
		if [ -z $4 ]; then
			echo "usage: $usage"
			exit 10
		fi
		CALL_ID=$3
		USER_ID=$4
	fi


	#дата для папки выкусывается из имени файла. т.е. если файл не по формату, то хрен он нормально сложится в папочку
	fdate=`echo $2|rev|cut -d/ -f1|rev|cut -d- -f1`

	recdir=${2%/*}/..

	#откусываем от ввода расширения wav & mp3 если они переданы
	input=${2%.wav}
	input=${input%.mp3}

	#работаем с мп3 файлом
	mp3name=$(basename $input.mp3)
	mp3dir=$recdir/$fdate
	mp3file=$mp3dir/$mp3name
	mp3duration=$(mp3info -p "%S\n" $mp3file)



	if [ -r $mp3file ]; then
		echo "$now attaching mp3: $mp3file to $CALL_ID" >>$log
		(echo "{\"CALL_ID\":\"$CALL_ID\",\"USER_ID\":\"$USER_ID\",\"DURATION\":$mp3duration}") | \
		curl -s -X POST -H "Content-Type: application/json" -d @- https://goya-consult.bitrix24.ru/rest/48/y3zrfjwi35bgb5we/telephony.externalcall.finish.json --verbose

		(echo "{\"CALL_ID\":\"$CALL_ID\",\"FILENAME\":\"$mp3name\",\"FILE_CONTENT\":\""; base64 $mp3file; echo '"}') | \
		curl -s -X POST -H "Content-Type: application/json" -d @- https://goya-consult.bitrix24.ru/rest/48/y3zrfjwi35bgb5we/telephony.externalcall.attachRecord.json --verbose
	else
		echo "$now not found mp3: $mp3file for $CALL_ID" >>$log
	fi
fi
