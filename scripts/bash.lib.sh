#!/bin/sh
#библиотека для скриптов астериска на шелле


#выводит строку на экран и в логфайл (если он определен)
log() {
	echo $*
	if [ -n "$logfile" ]; then
		echo `date +"%Y-%m-%d %H:%M:%S"` $* >> $logfile
	fi
}

#логирует ошибку и завершает работу
stop() {
    log $1 && exit 10
}

#выводит случайный символ из переданной строки
choose() { echo ${1:RANDOM%${#1}:1} $RANDOM; }

#возвращает пароль длинной 8-16 символов
genpass() {
	{
		choose '^+-.,()*'
		choose '0123456789'
		choose 'abcdefghijklmnopqrstuvwxyz'
		choose 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
		for i in $( seq 1 $(( 4 + RANDOM % 8 )) ); do
			choose '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
		done
	} | sort -R | awk '{printf "%s",$1}'
}

#проверяет установленая ли переменная $1, если нет то сообщает об ошибке $2 и завершает работу
check_var() {
	#echo -n "$1 ... "
	if [ -z "${!1}" ]; then
		stop "ERR: \$${1} is empty! $2"
	#else
	#	echo "OK"
	fi
}

#возвращает статус пира в астериске
ast_peer_status() {
	status=`/usr/sbin/asterisk -rx "sip show peer $1"|grep "Status"|cut -d":" -f2|cut -d" " -f2`
	echo $status
}


#прогоняет файл через сед и заменят старый файл результатом прогона
sed_file(){
	cp $1 $1.bak
	/bin/cat $1.bak | /bin/sed "$2" > $1
}

#инклудит обязательный файл
require() {
	if [ -z "$1" ]; then
		stop "ERR: Incorrect require usage. Need argument <file_to_include>"
	fi

	if [ ! -f "$1" ]; then
		echo "ERR: Required file [$1] not found!"
		exit
	fi

. $1
}