#!/bin/bash

diff /tmp/meetme555.delay <(asterisk -rx "meetme list $1"| grep -v "that conference" | sed "s/\s\+/ /g" | cut -d" " -f4-5 |grep .) | grep '[<>]'
asterisk -rx "meetme list $1"| grep -v "that conference" | sed "s/\s\+/ /g" | cut -d" " -f4-5 |grep . > /tmp/meetme555.delay