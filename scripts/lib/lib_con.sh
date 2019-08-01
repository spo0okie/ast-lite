#!/bin/sh
# библиотека по работе с консолью. отпочковано от diff_arc с целью разделения функций по библиотекам

lib_con_version=1.2
#2018-08-13
#1.2	* добалена поддержка LOG_silent=1

#2018-07-28
#1.1.2	* fork from arch_diff v1.1.2 rc





#core check
if [ -z "lib_core_version" ]; then
	echo "HALT: Error loading $0 - load core first!"
	exit 99
fi

### CONSOLE STUFF ######################################################
crlf='
'

if [ "$TERM" != "dumb" ] && [ "$TERM" != "unknown" ] && [ -n "$TERM" ]; then
	CON_RED=$(tput setaf 1)
	CON_GREEN=$(tput setaf 2)
	CON_NORMAL=$(tput sgr0)
	CON_WIDTH=$(tput cols)
fi

CON_RMARGIN=2
CON_TTY=`tty`

if [ "${CON_TTY:0:4}" = "/dev" ]; then
	CON_TTY="tty"
else
	CON_TTY="no"
fi



#Выводит сообщение со статусом 
#$1	- сообщение (слева)
#2	- статус (справа)
#3	- код цвета
con_stat()	#report ok ($msg $status $colorcode)
{
	if [ "$CON_silent" = "1" ]; then 
		 return 0 
	fi
	if [ "$CON_TTY" = "no" ]; then 
		con_msg "$1 - $2" && return 0 
	fi

	if [ "$(( $CON_WIDTH - ${#2} - 2 - $CON_RMARGIN ))" -lt "${#1}" ]; then
		msg="${1:0:$(( $CON_WIDTH - ${#2} - $CON_RMARGIN - 5 ))}..."	#trunkate long messages
	else
		msg=$1
	fi

	printf "%s%*s%s\n" "$msg" $(( $CON_WIDTH - ${#msg} - ${#2} - 2 - $CON_RMARGIN )) " " "[$3$2$CON_NORMAL]"

}


#выводит только статус сообщения
#$1	- сообщение (слева)
#2	- статус (справа)
#3	- код цвета
con_stat_stat()	#report ok ($msg $status $colorcode
{
	if [ "$CON_silent" = "1" ]; then 
		 return 0 
	fi

	if [ "$CON_TTY" = "no" ]; then 
		con_msg " - $2" && return 0 
	fi

	if [ "$(( $CON_WIDTH - ${#2} - 2 - $CON_RMARGIN ))" -lt "${#1}" ]; then
		msg="${1:0:$(( $CON_WIDTH - ${#2} - $CON_RMARGIN - 5 ))}..."	#trunkate long messages
	else
		msg=$1
	fi

	printf "%*s%s\n" $(( $CON_WIDTH - ${#msg} - ${#2} - 2 - $CON_RMARGIN )) " " "[$3$2$CON_NORMAL]"

}


#выводит только сообщение без статуса
#$1	- сообщение (слева)
#2	- статус (справа)
#3	- код цвета
con_stat_msg()	#report ok ($msg $status $colorcode
{
	#выведет сообщение и подготовит к выводу статуса. 
	#уже в этой функции надо передать самый длинный возможный статус для обрезки сообщения
	if [ "$CON_silent" = "1" ]; then 
		 return 0 
	fi

	if [ "$CON_TTY" = "no" ]; then 
		printf "%s" "$1" && return 0 
	fi

	if [ "$(( $CON_WIDTH - ${#2} - 2 - $CON_RMARGIN ))" -lt "${#1}" ]; then
		msg="${1:0:$(( $CON_WIDTH - ${#2} - $CON_RMARGIN - 5 ))}..."	#trunkate long messages
	else
		msg=$1
	fi
	printf "%s" "$msg"
}

#выводит сообщение в консоль, если она не заглушена
con_msg()	#msg to console
{
	if [ "$CON_silent" = "1" ]; then 
		 return 0 
	fi
	echo "$1"
}

#выводит сообщение в лог, если он определен
log_msg()	#msg to log
{
	if [ "$LOG_silent" = "1" ]; then 
		 return 0 
	fi
	if [ -z "$logfile" ]; then
		logfile=/dev/null
	fi
	echo "$1" >>$logfile
}

#выводит сообщение и в лог и в консоль (ориентируясь на окружение)
lmsg() 	#log command
{	
	date=`date +"%F %T"`
	con_msg "$date $1" && log_msg "$date $1"
}



#вывод сообщений сразу со статусом
lmsg_ok() 	#log command
{	
	date=`date +"%F %T"`
	if [ -z "$2" ]; then
		status='OK'
	else
		status="$2"
	fi
	con_stat "$date $1" "$status" $CON_GREEN && log_msg "$date $1 - $status"
}

lmsg_norm() 	#log command
{	
	date=`date +"%F %T"`
	if [ -z "$2" ]; then
		status='NORM'
	else
		status="$2"
	fi
	con_stat "$date $1" "$status" $CON_NORMAL && log_msg "$date $1 - $status "
}

lmsg_err() 	#log command
{	
	date=`date +"%F %T"`
	if [ -z "$2" ]; then
		status='ERR'
	else
		status="$2"
	fi
	con_stat "$date $1" "$status"  $CON_RED && log_msg "$date $1 - $status "
}


#вывод сообщения и оставление места для статуса
lmsg__() 	#log command and leave space for status $2
{	
	date=`date +"%F %T"`
	if [ -z "$2" ]; then
		status='NORM'
	else
		status="$2"
	fi
	con_stat_msg "$date $1" "$status"  && log_msg "$date $1 ... "
}

#дописывание статусов
lmsg__ok() 	#log command status after lmsg__
{	
	date=`date +"%F %T"`
	if [ -z "$2" ]; then
		status='OK'
	else
		status="$2"
	fi
	con_stat_stat "$date $1" "$status" $CON_GREEN && log_msg "$date $1 - $status"
}

lmsg__err() 	#log command
{	
	date=`date +"%F %T"`
	if [ -z "$2" ]; then
		status='ERR'
	else
		status="$2"
	fi
	con_stat_stat "$date $1" "$status"  $CON_RED && log_msg "$date $1 - $status "
}

lmsg__norm() 	#log command
{	
	date=`date +"%F %T"`
	if [ -z "$2" ]; then
		status='NORM'
	else
		status="$2"
	fi
	con_stat_stat "$date $1" "$status" $CON_NORMAL && log_msg "$date $1 - $status "
}


