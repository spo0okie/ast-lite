#!/bin/sh
for conf in `ls -1 ./exten.tpl.org*.conf | sed s/[^0-9]//g`; do
	if [ -n "$conf" ]; then
		if [ "$conf" != "1" ];then
			echo Organization $conf found
			cat ./exten.tpl.org1.conf | sed "s/org1_/org${conf}_/g" | sed "s/org1)/org${conf})/g" > ./exten.tpl.org$conf.conf
		fi
	fi
done