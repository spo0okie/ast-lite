#!/bin/bash
# выдергивание расписания из БД
# v1.0 просто работает, выдергивает расписание по ID

api=$2
org=$1

if [ -z "$api" ]; then
    exit 1
fi

if [ -z "$org" ]; then
    exit 2
fi

response=`wget --timeout=1 --tries=1 http://$api/orgs/work-time?id=$org -O - -q | xargs`
if [ -z "$response" ]; then
	echo -n "*"
else
	echo "$response"
fi