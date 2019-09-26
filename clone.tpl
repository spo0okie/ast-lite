#!/bin/sh

conf=2
while [ -e ./exten.tpl.org$conf.conf ]; do
	echo Organization $conf found
	cat ./exten.tpl.org1.conf | sed "s/org1_/org${conf}_/g" | sed "s/org1)/org${conf})/g" > ./exten.tpl.org$conf.conf
	conf=$(( $conf + 1 ))
done