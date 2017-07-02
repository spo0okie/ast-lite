#!/bin/bash
#скрипт транслитерации. Используется для подмены CallerID

for NAME in "$*" ; do
TRS=`echo $NAME | sed "y/абвгдезийклмнопрстуфхцы/abvgdezijklmnoprstufxcy/"`
TRS=`echo $TRS | sed "y/АБВГДЕЗИЙКЛМНОПРСТУФХЦЫ/ABVGDEZIJKLMNOPRSTUFXCY/"`
TRS=${TRS//ч/ch};
TRS=${TRS//Ч/CH} TRS=${TRS//ш/sh};
TRS=${TRS//Ш/SH} TRS=${TRS//ё/yo};
TRS=${TRS//Ё/YO} TRS=${TRS//ж/zh};
TRS=${TRS//Ж/ZH} TRS=${TRS//щ/sh\'};
TRS=${TRS//Щ/SH\'} TRS=${TRS//э/ye};
TRS=${TRS//Э/YE} TRS=${TRS//ю/yu};
TRS=${TRS//Ю/YU} TRS=${TRS//я/ya};
TRS=${TRS//Я/YA} TRS=${TRS//ъ/\`};
TRS=${TRS//ъ\`} TRS=${TRS//ь/\'};
TRS=${TRS//Ь/\'}

echo $TRS

done