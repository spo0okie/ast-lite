#!/bin/bash
lib_ini_files_version=0.2

#2018-07-28
#v0.2	initial

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



#core check
if [ -z "lib_core_version" ]; then
        echo "HALT: Error loading $0 - load core first!"
        exit 99
fi

lib_require lib_con

ini_parser() {
    #взято тут https://www.joedog.org/2015/02/13/sh-script-ini-parser/
    #изрядно подправлено ибо из коробки не работало
    FILE=$1
    SECTION=$2
    #первая строка убирает пробелы вокруг знака равенства
    #вторая отсекает каменты до конца строки (не оч круто, т.к. можно обрезать пароль с ; или # внутри, ну в нашей задаче это не так важно
    #третья строка убирает пробелы в начале и конце строки
    #последняя (из преобразующих), экранирует все ка..ычки в файле и берет в кавычки вторую часть выражения var=val
    #а вот что делает строчка которая обрабатывает stdout?
    eval $(
    sed -E -e 's/[[:space:]]*=[[:space:]]*/=/g' \
        -e 's/[;#].*$//' \
        -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' \
        -e 's/"/\\"/' -e 's/([a-z]+)=(.*)/\1="\2"/' \
        < $FILE \
        | sed -n -e "/^\[$SECTION\]/,/^\[/{/.*=.*/p;}"
    )
    #   оригинал вырезалки секции с той функции, что я скачал с инета
    #| sed -n -e "/^[$SECTION]/I,/^s*\[/{/^[^;].*=.*/p;}"
    #разберем это выражение
    #/^[$SECTION]/I - адрес 1 - начало требуемой секции, что за литера I - хз
    #,
    #/^s*[/ - адрес 2 - начало следующей секции
    # --- итого обозначен диапазон между началом секции и началом следующей ---
    #{ - открываем набор функций выполняемый для диапазона обозначенного адресами выше
    #   /^[^;].*=.*/p; - вот эта дичь мне не ясна нужно печатать то что начинается с символов ^ или ; - это еще почему?
    #}
    # в итоге функцию я переписал, ибо эта не работала и я не понимал как она должна работать
}

#проверяем наличие секции
ini_section_ck() {
	FILE=$1
	SECTION=$2
	sec_cnt=`cat $FILE | egrep -v '^[;#]' | grep "\[$SECTION\]" | wc -l`
	msg="Checking INI section $1/[$2]"
	if ! [ "$sec_cnt" -eq "1" ]; then
		lmsg_err "$msg" "UNSET" && exit 10
	else
		lmsg_ok "$msg" "SET"
	fi

}

ini_section_load() {
	ini_parser $*
	lmsg_ok "Loading INI section $1/[$2]" "OK"
}

#возвращает список всех секций файла
ini_section_list() {
	cat $1 | grep -v '^[;#]' | egrep '^\[\w+\]' | sed -E 's/\[(\w+)\](\(.*\))?/\1/'
}