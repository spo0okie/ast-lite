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

#общее количество настроенных регистраций
ast_total_registry() {
	total=`/usr/sbin/asterisk -rx "sip show registry" | grep "SIP registrations" | cut -d" " -f1`
}

#текущее количество успешных регистраций
ast_online_registry() {
	online=`/usr/sbin/asterisk -rx "sip show registry"|grep "Registered"|wc -l`
}

#прогоняет файл через сед и заменят старый файл результатом прогона
sed_file(){
	if [ ! -f "$1" ]; then
		stop "ERR: Can't sed $1: file not found"
	fi
	if cp $1 $1.bak; then
		/bin/cat $1.bak | /bin/sed "$2" > $1
	else
		stop "ERR: Can't sed $1: copying error"
	fi
}

#прогоняет файл через сед и заменят старый файл результатом прогона
backup_file(){
	if [ ! -f "$1" ]; then
		stop "ERR: Can't backup $1: file not found"
	fi
	if ! cp -fT $1 $1.bak; then
		stop "ERR: Can't backup $1: copying error"
	fi
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

#выставляет флаг ошибки работы скрипта
set_error_flag() {
	if [ -n "$statusfile" ]; then
		echo $1 > $statusfile.err
	fi
}

#выставляет флаг в файл статуса
set_status_flag() {
	if [ -n "$statusfile" ]; then
		echo $1 > $statusfile
	fi
}



##++
## Парсит INI файл с секциями в стиле:
## [section]
## attr=thing
## key=val
## [header]
## thing=another
## foo=bar
##
## @param file путь к файлу чтоб парсить
## @param section имя секции
## @return void (к переменным можно обращаться по их именам, по сути ф-я делает EVAL выбранной секции)
##--

ini_parser() {
	#взято тут https://www.joedog.org/2015/02/13/sh-script-ini-parser/
	#изрядно подправлено ибо из коробки не работало
	FILE=$1
	SECTION=$2
	#первая строка убирает пробелы вокруг знака равенства
	#вторая отсекает каменты до конца строки (не оч круто, т.к. можно обрезать пароль с ; или # внутри, ну в нашей задаче это не так важно
	#третья строка убирает пробелы в начале и конце строки
	#последняя (из преобразующих), экранирует все кавычки в файле и берет в кавычки вторую часть выражения var=val
	#а вот что делает строчка которая обрабатывает stdout?
	eval $( 
	sed -E -e 's/[[:space:]]*=[[:space:]]*/=/g' \
		-e 's/[;#].*$//' \
		-e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' \
		-e 's/"/\\"/' -e 's/([a-z]+)=(.*)/\1="\2"/' \
		< $FILE \
		| sed -n -e "/^\[$SECTION\]/,/^\[/{/.*=.*/p;}"
	)
	#	оригинал вырезалки секции с той функции, что я скачал с инета
	#| sed -n -e "/^[$SECTION]/I,/^s*\[/{/^[^;].*=.*/p;}"
	#разберем это выражение
	#/^[$SECTION]/I - адрес 1 - начало требуемой секции, что за литера I - хз
	#,
	#/^s*[/ - адрес 2 - начало следующей секции
	# --- итого обозначен диапазон между началом секции и началом следующей ---
	#{ - открываем набор функций выполняемый для диапазона обозначенного адресами выше
	#	/^[^;].*=.*/p; - вот эта дичь мне не ясна нужно печатать то что начинается с символов ^ или ; - это еще почему?
	#}
	# в итоге функцию я переписал, ибо эта не работала и я не понимал как она должна работать
}

