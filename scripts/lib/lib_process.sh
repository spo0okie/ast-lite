#!/bin/bash
lib_process_version="2.0rc"

#hist:
#	2018-07-28
#2.0.0 * Библиотека отделена от diff_arc
#	2017-09-17



#core check
if [ -z "lib_core_version" ]; then
        echo "HALT: Error loading $0 - load core first!"
        exit 99
fi

lib_require lib_con

pid_dir=/tmp/spoo.sync

#Проверяет живы ли процесы с ПИДами из переданного файла
#возвращает 0 (ок), если никого нет
#возвращает 1 (ошибка), если ктото жив
checkPIDFile()
{
	lmsg__ "Checking PID file $1 ... "
	if [ -f "$1" ]; then
		lmsg__norm "Checking PID file $1 ... " "busy"
		lmsg "Checking PIDs ..."
		for pid in `cat $1`; do
			lmsg__ "Checking for PID $pid ..." "alive"
			if ps -p $pid > /dev/null; then
				lmsg__err "Checking for pid $pid ..." "alive"
				return 1
			else
				lmsg__err "Checking for pid $pid ..." "miss"
			fi
		done
	else
		lmsg__ok "Checking PID file $1 ... " "free"
	fi
	return 0
}

#Пытается занять lock файл. Если файсл свободен, то занимает
#Иначе завершает работу
#
lockPIDFile()
{
	if checkPIDFile $1; then
		echo $$ > $1
		lmsg_ok "Lock $1"
	else
		halt "Other copy already running."
	fi
}


#Удаялет lock файл
unlockPIDFile()
{
	lmsg__ "Unlock PID file $1"
	if $( rm -f $1 ); then
		lmsg__ok "Unlock PID file $1"
	else
		lmsg__ "Unlock PID file $1"
	fi
}

#бесконечно ожидает освобождения lock файла, проверяя каждые 2 сек
waitPid()
{
	lmsg__ "waitPid($1) waiting process#$1 to complete ...."
	while ps -p $lastpid > /dev/null; do
		echo -n "."
		sleep 2
	done
	echo " done"
}

#ждет завершения одного из процессов из переданного списка
#возвращает списки $pids_destroyed $pids_remain
waitManyPids()
{
	#пробуем подтащить описания пидов из $piddescr_<pid>
	infolist=""
	for pid in $1; do
		descr=""
		piddescr="piddescr_$pid"
		descr=${!piddescr}
		if [ -n "$descr" ]; then
			infolist="$infolist $pid($descr)"
		else
			infolist="$infolist $pid"
		fi
	done

	lmsg__ "waitManyPids(): waiting for $infolist to complete"
	pids_destroyed=""
	while [ -z "$pids_destroyed" ]; do
		pids_remain=""
		infolist=""
		for pid in $1;do
			if ps -p $pid > /dev/null; then
				pids_remain="$pids_remain $pid"
			else
				pids_destroyed="$pids_destroyed $pid"
				descr=""
				piddescr="piddescr_$pid"
				descr=${!piddescr}
				if [ -n "$descr" ]; then
					infolist="$infolist $pid($descr)"
				else
					infolist="$infolist $pid"
				fi
			fi
			
		done
		sleep 2
		echo -n "."
	done
	echo "."
	lmsg "waitManyPids(): $infolist done"
}
