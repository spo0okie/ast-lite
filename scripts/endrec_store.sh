#!/bin/bash
#скрипт хранения mp3 в папочках с датами

starttime=`date`
recdir=${1%/*}/..
reclog=$recdir/record.log

#откусываем от ввода расширения wav & mp3 если они переданы
input=${1%.wav}
input=${input%.mp3}

#работаем с мп3 файлом
mp3file=$input.mp3
echo "$starttime: Got store $* ($mp3file)" >> $reclog

#дата для папки выкусывается из имени файла. т.е. если файл не по формату, то хрен он нормально сложится в папочку
fdate=`echo $1|rev|cut -d/ -f1|rev|cut -d- -f1`

if [ -r $mp3file ]; then
	echo "$starttime found mp3: $mp3file" >>$reclog
	mp3dir=$recdir/$fdate
	mkdir -p $mp3dir # no error on exist (-p)
	if [ -d $mp3dir ]; then
		chmod 777 $mp3dir
		echo "$starttime moving mp3: $mp3dir" >>$reclog
		mv $mp3file $mp3dir
		echo "$starttime store done" >>$reclog
	else
		echo "$starttime: not found dir: $mp3dir" >>$reclog
		echo "$starttime store ERROR" >>$reclog
		exit
	fi
else
	echo "$starttime: not found mp3: $mp3file" >>$reclog
	echo "$starttime store ERROR\n" >>$reclog
fi