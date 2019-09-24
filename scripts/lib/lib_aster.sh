#!/bin/sh
lib_aster_version="0.1 alpha"
#библиотека для скриптов астериска на шелле



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


#проверяет что в каждой секции есть пароль
users_conf_ck(){

	users_conf=$1
	backup_file $users_conf
	lmsg_ok "Backup file $1"

	#проверяем что в каждой секции установлен пароль
	lmsg__ "Validating file $1"

	#выдергиваем все имена незакомментированных секций, кроме тех, что с (!) - шаблоны т.е.
	#sections=`ini_section_list $users_conf` - не годится, т.к. надо исключать шаблоны
	sections=`cat $users_conf | grep -v '^;' | egrep '^\[\w+\]' | egrep -v '^\[\w+\]\(!\)' | sed -E 's/\[(\w+)\](\(.*\))?/\1/'`
	for sec in $sections; do
		secret=null
		ini_parser "$users_conf.bak" $sec
		if [ "$secret" = "null" ] ; then
			lmsg "$sec($callerid) - no passwd key exist! (adding)"
			sed -i "/\[$sec\]/a\secret=" $users_conf
		else
			echo -n .
		fi
	done
	echo
	#проверяем что в файле нет пустых паролей
	paswds_set=0
	while : ; do
		#кладем в переменную генеренный пароль
		pass=$(genpass)

		#ищем пустые пароли в файле
		sed "/^secret=$/{q100}" $users_conf >/dev/null
		if [ "$?" -eq "100" ]; then
            #нашли - пробуем вписать туда генереный пароль
            if sed -i "0,/^secret=$/s//secret=$pass/" $users_conf ;then
                #увеличиваем счетчик внесенных изменений
                paswds_set=$(( $paswds_set + 1 ))
            else
                #something goes terribly wrong
                halt "Can't sed users.conf! Check fs problems please."
            fi
        else
            #пустых паролей нет
            lmsg_ok "Password check: $paswds_set passwords added"
            break
        fi
    done
}