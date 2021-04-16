#!/bin/sh
#скрипт окончания записи вызова
#v2.0
#	разделен отдельно на сжатие и раскладываение по папкам, для того
#	чтобы можно было использовать сжатие отдельно
/etc/asterisk/scripts/endrec_compress.sh $* && /etc/asterisk/scripts/endrec_store.sh $*
