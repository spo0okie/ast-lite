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
	wget --timeout=1 --tries=1 https://$api/phones/search?num=$num -O - -q --no-check-certificate | grep -v ERR | xargs | head -c 30 | iconv -c 2>/dev/null | tr -d '\r\n'
fi

#запрошено 10 и более знаков - ищем среди пользователей по мобильнику
if [ ${#num} -ge 10 ]; then
	#заменяем пробелы (URLencode для бедных)
	safenum=`echo $num| sed 's/\+/%2b/g'`
	wget --timeout=1 --tries=1 https://$api/users/view?mobile=$safenum -O - -q --no-check-certificate | jq '.Ename' | xargs | head -c 30 | iconv -c 2>/dev/null | tr -d '\r\n'
fi
