#!/bin/bash
# ядреная библиотека по работе с другими библиотеками)
lib_core_version=0.2
#2018-08-13
#0.2
#	! некоторые исправления для совместимости с CON_silent=1
#
#2018-07-28
#0.1alpha initial release
#	+ var stuff (from arch_diff)
#	+ halt stuff
#	+ lib load stuff

#Останов программы с сообщением об ошибке
halt()
{
	msg=$1
	code=$2

	if [ -z "$code" ]; then
		code=10
	fi

	if [ -z "$msg" ]; then
		msg "Critial error!"
	fi

	msg="HALT: $msg"

	if [ -z "$lib_con_version" ]; then
		echo $msg
	else
		lmsg "$msg"
	fi

	exit $code
}


### ARR STUFF ##########################################################


#проверяет что $1 есть в списке $2
#возвращает true или false
arr_inlist()
{
	#echo "checking $1 in [$2]"
	#если один из параметров пуст - false
	if [ -z "$1" ]; then
		return 1
	elif [ -z "$2" ]; then
		return 1
	else
		#if [ `arr_list "$2" | egrep -c "^$1"` -gt 0 ]; then
		#	return 0
		#fi
		#ограничиваем массив совпадениями по grep
		#testlist=`arr_list "$2"|grep $1`
		#if [ -z "$testlist" ]; then
			#если все отфильтровалось то ошибка
		#	return 1
		#else
			#иначе перебираем поштучно
			for item in $2; do
				if  [ "$item" == "$1" ]; then
					return 0
				fi
			done
		#fi
	fi
	return 1
}

#выводим массив $1 построчно
arr_list() {
	for item in $1; do
		echo $item
	done
}

#оставляет только уникальные элементы массива $1
arr_uniq() {
	arr_list $1 | sort -u
}

#добавляет $1 к $2. Оба элементы могут быть списками
arr_add_uniq()
{
	arr_uniq "$2 $1"
}

#вычитаем из списка $1 список $2
arr_sub()
{
	for item in $1; do
		if ! $( arr_inlist $item $2); then
			echo $item
		fi
	done
}

### VAR STUFF ##########################################################


#проверка переменной и возврата кода (не 0 если ошибка)
checkvar_ret()  #check if var is set(return code)
{
	if [ -z "$1" ]; then
		lmsg_err "$2" "UNSET" && return 1
	else
		lmsg_ok "$2" "SET" && return 0
	fi
}

#проверка переменной и выход если не установлена
checkvar()      #check if var is set
{
	if [ -z "$1" ]; then
		lmsg_err "$2" "UNSET" && exit 10
	else
		lmsg_ok "$2" "SET"
	fi
}

#проверка переменной и выход если не установлена
var_ck()      #check if var is set
{
	varname=$1
	value=${!varname}
	checkvar "$value" "var_ck(): Checking var $varname ... "
}

#приведение переменной к булеву типу
#использовать както типа if $( bool $test ); then
bool()
{
	case $1 in
		[Yy][Ee][Ss])
			return 0
		;;
		[Tt][Rr][Uu][Ee])
			return 0
		;;
		[Ee][Nn][Aa][Bb][Ll][Ee])
			return 0
		;;
		1)
			return 0
		;;
		*)
			return 1
		;;
	esac
}

### DIR STUFF ##########################################################

dir_clean()
{
	p="dir_clean():"
	$fmsg="$p cleaning dir $1 ..."

	lmsg__ "$fmsg" "err"
	if $( rm -rf $1 ); then
		lmsg__ok "$fmsg"
	else
		lmsg__err "$fmsg"
	fi
}


dircheck()      #creates dir (and cleans it if $2==clean)
{
        if ! [ -d "$1" ]; then
                lmsg_err "dircheck(): Checking folder $1..." "MISS"
                mkdir -p $1
                if ! [ -d "$1" ]; then
                        lmsg_err "dircheck(): Creating $1 ..."
                        exit 1
                else
                        lmsg_ok "dircheck(): Creating $1 ..."
                fi
        else
                lmsg_ok "dircheck(): Checking folder $1..."
        fi
        if [ "$2" == "clean" ]; then
                if [ -n "$1" ]; then    #do not delete in /*
                        rm -f $1/* >>$logfile
                fi
                lmsg_ok "dircheck(): Cleaning folder $1 ..." "DONE"
        fi
}


### LIB STUFF ##########################################################

#загрузка библиотеки
lib_load()
{
	lib=$1
	if [ -z "$PROGPATH" ]; then
		halt "Critial error: incorrect core lib usage, PROGPATH is unset!"
	fi

	if [ ! -f "$PROGPATH/lib/$1.sh" ]; then
		halt "Critial error: Error while including $PROGPATH/lib/$1.sh!"
	fi

	. $PROGPATH/lib/$1.sh

	lib_ver_var=${lib}_version
	lib_ver=${!lib_ver_var}

	if [ -z "$lib_ver" ]; then
		halt "Critial error in $PROGPATH/lib/$1.sh: no lib_version set!"
	fi

	lmsg_ok "Library loaded: $1" "v$lib_ver"
}

lib_require()
{
	libreq=$1
	libreq_ver_var=${libreq}_version
	libreq_ver=${!libreq_ver_var}

	if [ -z "$libreq_ver" ]; then
		lib_load $1
	fi
}


### BACKUP ############################################################
#первичная инициализация. подключение библиотеки консоли
#прогоняет файл через сед и заменят старый файл результатом прогона

backup_file(){
	if [ ! -f "$1" ]; then
		halt "ERR: Can't backup $1: file not found"
	fi
	if ! cp -fT $1 $1.bak; then
		stop "ERR: Can't backup $1: copying error"
	fi
}


### passwd ############################################################
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


if [ "$CON_silent" != "1" ]; then
	echo "Core" v$lib_core_version
fi


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

lib_load lib_con