#!/bin/sh


starttime=`date`
recdir=${1%/*}/..
reclog=$recdir/record.log

echo "$starttime: Got command $1" >> $reclog

fdate=`echo $1|rev|cut -d/ -f1|rev|cut -d- -f1`

inrec=$1-in.wav
outrec=$1-out.wav
mp3file=$1.mp3

volcoeff="8"
rate="24k"
sox="nice /usr/local/bin/sox" # run a sox with reduced scheduling priority (nice)

if [ -r $inrec ]; then
	echo "$starttime: found IN channel wav: $inrec" >>$reclog
	if [ -r $outrec ]; then
		echo "$starttime: found OUT channel wav: $otrec" >>$reclog
		echo "$starttime exec: $sox -q -m $inrec $outrec -r $rate $mp3file vol $volcoeff" >>$reclog
		$sox -m $inrec $outrec -r $rate $mp3file vol $volcoeff >/dev/null 2>&1
	else
		echo "$starttime: not found OUT channel wav: $outrec" >>$reclog
		echo -e "$starttime ERROR\n" >>$reclog
		exit
	fi
else 
	echo "$starttime: not found IN channel wav: $inrec" >>$reclog
	echo -e "$starttime ERROR\n" >>$reclog
	exit
fi

$sox -m $inrec $outrec -r $rate $mp3file vol $volcoeff >/dev/null 2>&1

if [ -r $mp3file ]; then
	echo "$starttime found mp3: $mp3file" >>$reclog
	mp3dir=$recdir/$fdate
	mkdir -p $mp3dir # no error if existing (-p)
	if [ -d $mp3dir ]; then
		echo "$starttime moving mp3: $mp3dir" >>$reclog
		mv $mp3file $mp3dir
		echo "$starttime cleaning..." >>$reclog
		rm -f $inrec
		rm -f $outrec
		echo -e "$starttime done\n" >>$reclog
	else
		echo "$starttime: not found dir: $mp3dir" >>$reclog
		echo -e "$starttime ERROR\n" >>$reclog
		exit
	fi
else
	echo "$starttime: not found mp3: $mp3file" >>$reclog
	echo -e "$starttime ERROR\n" >>$reclog
fi