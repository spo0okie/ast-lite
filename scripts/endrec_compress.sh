#!/bin/bash
#скрипт сжатия wav в mp3

#v2.1
#	добавлено ожидание освобождения исходных файлов (занятость проверястся через lsof)

#v2.0 
#	может сжимать как одиночные файлы так и пару ( *-in + *-out) на два канала
#	разделено функционально на сжатие и складывание в папочки по датам

starttime=`date`
recdir=${1%/*}/..
reclog=$recdir/record.log

echo "$starttime: Got compress $*" >> $reclog

#откусываем от ввода .wav ,если оно там есть
input=${1%.wav}

#исходные файлы, если входные данные из двух каналов
inrec=$input-in.wav
outrec=$input-out.wav
#если в виде одного файла
simplerec=$input.wav

#во что пережимаем
mp3file=$input.mp3

#настройки sox
volcoeff="8"
rate="24k"
sox="nice /usr/local/bin/sox" # run a sox with reduced scheduling priority (nice)


#проверяем 2х канальный (2х файловый) вариант
if [ -r $inrec ]; then
	echo "$starttime: found IN channel wav: $inrec" >>$reclog
	#ищем второй канал
	if [ -r $outrec ]; then
		#проверяем что файл не пишется
		while $( lsof | grep -q $input ); do
			echo "$starttime: file is busy: $inrec, waiting 10sec ..." #>>$reclog
			sleep 10
		done
		#работаем
		echo "$starttime: found OUT channel wav: $outrec" >>$reclog
		echo "$starttime exec: $sox -m $inrec $outrec -r $rate $mp3file vol $volcoeff" >>$reclog
		$sox -m $inrec $outrec -r $rate $mp3file vol $volcoeff >/dev/null 2>&1
	else
		echo "$starttime: not found OUT channel wav: $outrec" >>$reclog
		echo -e "$starttime ERROR\n" >>$reclog
		exit 10
	fi
#проверяем однокональный (один файл) вариант
elif [ -r $simplerec ]; then
	#работаем
	#проверяем что файл не пишется
	while $( lsof | grep -q $input ); do
		echo "$starttime: file is busy: $simplerec, waiting 10sec ..." #>>$reclog
		sleep 10
	done
	echo "$starttime: found SINGLE channel wav: $simplerec" >>$reclog
	echo "$starttime exec: $sox $simplerec -r $rate $mp3file vol $volcoeff" >>$reclog
	$sox $simplerec -r $rate $mp3file vol $volcoeff >/dev/null 2>&1
else
#ничего не нашли!
	echo "$starttime: not found IN channel wav: $inrec or SIMPLE channel: $simplerec" >>$reclog
	echo -e "$starttime ERROR\n" >>$reclog
	exit 11
fi


#проверяем наличие mp3
if [ -r $mp3file ]; then
	#mp3 есть - прибираемся
	echo "$starttime mp3 ready: $mp3file" >>$reclog
	chmod 666 $mp3file
	echo "$starttime cleaning..." >>$reclog
	rm -f "$inrec"
	rm -f "$outrec"
	rm -f "$simplerec"
	echo "$starttime compress done" >>$reclog
else
	#нету mp3 - чтото пошло не так. выходим
	echo "$starttime: not found mp3: $mp3file" >>$reclog
	echo "$starttime ERROR" >>$reclog
	exit 12
fi
