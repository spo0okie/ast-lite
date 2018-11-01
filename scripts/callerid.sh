#!/bin/bash
phone=$1
server=$2
wget http://$2?phone=$1 -O - -q | xargs