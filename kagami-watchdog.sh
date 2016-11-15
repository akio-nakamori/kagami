#!/bin/bash

while true
do
	/opt/kagami/kagami-worker.sh
	sleep 60
	if [ -f /tmp/kagami/kagami.kill ]
	then
		exit
	fi
done
