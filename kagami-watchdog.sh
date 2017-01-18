#!/bin/bash
#
# KAGAMI for Twitter
# Author : BigRetroMike
# GPLv2
#

while true
do
	/opt/kagami/kagami.sh daemon
	sleep 60
	if [ -f /tmp/kagami/kagami.kill ]
	then
		exit
	fi
done
