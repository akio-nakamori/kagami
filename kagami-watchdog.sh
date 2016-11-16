#!/bin/bash

while true
do
	/opt/kagami/kagami-worker.sh
	sleep 60
	if [ -f /tmp/kagami/kagami.kill ]
	then
		rm /tmp/kagami/kagami.kill
		exit
	fi
done
