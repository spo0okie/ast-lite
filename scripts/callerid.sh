#!/bin/bash
wget http://$2?phone=$1 -O - -q | xargs | head -c 30
#| cut -b24
#| sed 's/\n//'