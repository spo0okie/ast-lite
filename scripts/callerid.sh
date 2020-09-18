#!/bin/bash
# v1.1 добавлен поиск по сотовым, поэтому передаваемый параметр API нужно изменить в БД Астериск 
#	(Svc/orgX_CallerID) на чтото вроде inventory.org.local/web/api (теперь без указания контроллера и метода)

api=$2
num=$1

if [ -z "$api" ]; then
    exit 1
fi

if [ -z "$num" ]; then
    exit 2
fi

#запрошено 4 и менее знаков - ищем среди оборудования типа "телефон"
if [ ${#num} -le 4 ]; then
	#запрашиваем каллерид
	#отсекаем ошибки
	#xargs делает чтото вроде трим
	#обрезаем 30 байт - иначе циска ничего не показывает вообще
	#через iconv отсекаем половинки utf-8 символов если разрезали строку посередине символов
	wget --timeout=1 --tries=1 http://$api/phones/search?num=$num -O - -q | grep -v ERR | xargs | head -c 30 | iconv -c
fi

#запрошено 10 и более знаков - ищем среди пользователей по мобильнику
if [ ${#num} -ge 10 ]; then
	wget --timeout=1 --tries=1 http://$api/users/view?mobile=$num -O - -q | jq '.Ename' | xargs | head -c 30 | iconv -c
fi
