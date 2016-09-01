#!/bin/bash
#
# KAGAMI for Twitter
# Author : BigRetroMike
# GPLv2
#

# twitter codes:
# 144 - no status
# 32 - bad auth

debuglog()
{
    # title message
    echo "$1" >> ~/.kagami/log.kagami
    echo "$2" >> ~/.kagami/log.kagami
}

clean()
{
    if [ -f /tmp/kagami/kagami.lock ]
    then
        rm /tmp/kagami/kagami.lock
    fi
    if [ -f /tmp/kagami/kagami.tweet.lock ]
    then
        rm /tmp/kagami/kagami.tweet.lock
    fi
}

populate_download_list()
{
if [ ! -f ~/.kagami/ids_list ]
then
    echo "Initial run..."
    twitter_get_fav > /tmp/kagami/fav.$PID
    touch ~/.kagami/ids_list
else
    # first=$(head -n 1 ~/.kagami/ids_list)
    number=$(cat ~/.kagami/ids_list | wc -l)
    if [ $number -gt 0 ]
    then
	cat ~/.kagami/ids_list | sort -ug > /tmp/kagami/ids_list.tmp
	cat /tmp/kagami/ids_list.tmp > ~/.kagami/ids_list
	rm /tmp/kagami/ids_list.tmp
    	printf "Get new tweets"
        last=$(tail -1 ~/.kagami/ids_list)
	#set -x 
        twitter_get_fav since_id $last > /tmp/kagami/fav.$PID
	# check fav size, if its bigger than 100 (empty, error)
	fav_size=`cat /tmp/kagami/fav.$PID | wc -c`
	if [ $fav_size -gt 100 ]
	then
	    echo ": found"
	else
	    echo ": not found"
	fi
	#set +x
	# cat /tmp/kagami/fav.$PID
        # Limit is 15/15minuts, so its 1command per 1minute, then lets wait ~60sec
        printf "wait for windows"
        while [ $(( $(date --utc +%s) - 65 )) -lt $(date --utc --reference=/tmp/kagami/kagami.lock +%s) ]
        do
            # wait till next compare (add buffer so it will be allways more than 1command/1minut
	    printf "."
	    sleep 10
	done
        touch /tmp/kagami/kagami.lock
        echo ""

	numer=`cat ~/.kagami/ids_list | wc -l`
	COUNTER=0
        echo "Searching for missing tweets"
	while [ $COUNTER -le $number ]
        do
	    echo "$COUNTER/$number"
	    #set -x
	    num=$((number - COUNTER))
	    if [ $num -eq 0 ]
	    then
		num=1
	    fi
	    new_id=$(sed "${num}q;d" ~/.kagami/ids_list)
	    #set +x
	    printf $new_id
	    COUNTER=$((COUNTER + count))
            while [ $(( $(date --utc +%s) - 65 )) -lt $(date --utc --reference=/tmp/kagami/kagami.lock +%s) ]
            do
                # wait till next compare (add buffer so it will be allways more than 1command/1minut
                printf "<"
                sleep 10
            done
            touch /tmp/kagami/kagami.lock
	    echo ""
	    #set -x
            twitter_get_fav max_id $new_id > /tmp/kagami/prev.$PID
	    #cat /tmp/kagami/prev.$PID
	    #set +x
	    jq -r .[].id_str /tmp/kagami/prev.$PID | sort -gu  > /tmp/kagami/ids_prev.$PID
	    cat /tmp/kagami/prev.$PID
	    rm /tmp/kagami/prev.$PID
	    prev_size=`cat /tmp/kagami/ids_prev.$PID | wc -l`
	    # check if size is near empty
	    if [ $prev_size -gt 0 ]
	    then
                while IFS='' read -r preid || [[ -n "$preid" ]]
		do
    		    if grep -q $preid ~/.kagami/ids_list
	    	    then
    	    		echo "$preid found in id_list"
    	    	    else
    			touch /tmp/kagami/kagami.tweet.lock
            		while [ $(( $(date --utc +%s) - 6 )) -lt $(date --utc --reference=/tmp/kagami/kagami.tweet.lock +%s) ]
            		do
                	    # wait till next compare
                	    printf "."
                	    sleep 5
            		done
			#set -x
			# fav already have newest tweets so add less new
            		twitter_get_tweet $preid >> /tmp/kagami/fav.$PID
			#set +x
			# cat /tmp/kagami/fav.$PID
            		rm /tmp/kagami/kagami.tweet.lock
        	    fi
    		done < /tmp/kagami/ids_prev.$PID
		# echo "fav.PID"
		# cat /tmp/kagami/fav.$PID
    		rm /tmp/kagami/ids_prev.$PID
	    else
		echo "no new tweet found"
	    fi
	done
    else
	echo "ids_list is empty"
	twitter_get_fav > /tmp/kagami/fav.$PID
    fi
fi
}

init_config_dirs()
{
        if [ ! -d /tmp/kagami ]
        then
                mkdir /tmp/kagami
        fi

	if [ ! -f ~/.kagami/users.list ]
	then
		touch ~/.kagami/users.list
	fi

	if [ ! -d $download_path ]
	then
		mkdir $download_path
	fi
	
	if [ -f ~/.kagami/log.kagami ]
	then
                touch ~/.kagami/log.kagami
        fi
}

new_config()
{
	echo '~/.kagami/kagami.cfg file missing'
        read -p "Create ~/.kagami/kagami.cfg? [y/n]" input
        case $input in
                [Yy]*) new_config_create;;
                [Nn]*) exit;;
        esac
}

new_config_create()
{
	if [ ! -d ~/.kagami ]
	then
		mkdir ~/.kagami
		echo 'Created directory ~/.kagami'
	fi
	echo 'Creating config file...'
	echo 'All needed info are on https://apps.twitter.com/app/'
	read -p "user that you want to monitor" login
	echo "screen_name=$login" >  ~/.kagami/kagami.cfg
	read -p "consumer_key:" con_key
	echo "consumer_key=$con_key" >> ~/.kagami/kagami.cfg
	read -p "consumer_secret:" con_secret
	echo "consumer_secret=$con_secret" >> ~/.kagami/kagami.cfg
	read -p "access_token:" acc_token
	echo "oauth_token=$acc_token" >> ~/.kagami/kagami.cfg
	read -p "access_secret:" acc_secret
	echo "oauth_secret=$acc_secret" >> ~/.kagami/kagami.cfg
	read -p "download_path:" down_path
	echo "download_path=$down_path" >> ~/.kagami/kagami.cfg
	echo 'Created config file ~/.kagami/kagami.cfg'
}

twitter_get_data()
{
    # twitter_get_data ID-of-tmp-file

    jq -r '. | { id: .id_str, date: .created_at, text: .text, url: [ .entities.urls[].url ], media: [ .extended_entities.media[]?.media_url_https ], video: [.extended_entities.media[]?.video_info ], user: .user.screen_name, user_url: .user.entities.url.urls[0].expanded_url }' /tmp/kagami/$1.tmp > /tmp/kagami/$1
    rm /tmp/kagami/$1.tmp
    
    author=`jq -c .user /tmp/kagami/$1`
    author=${author:1:-1}

    if grep -Fxq $author ~/.kagami/users.list
    then
        echo "$author is known (users.list)"
    else
        twitter_add_friend $author
        echo "$author adding to user.list"
        echo $author >> ~/.kagami/users.list
    fi

    dl_line=$download_path"/"$1
    if [ ! -f $dl_line ]
    then
        echo "Creating meta-data for $1"
        touch $dl_line
        jq ".user" /tmp/kagami/$1 >> $dl_line
        jq ".user_url" /tmp/kagami/$1 >> $dl_line
        jq ".date" /tmp/kagami/$1 >> $dl_line
        jq ".text" /tmp/kagami/$1 >> $dl_line
        jq ".media[]" /tmp/kagami/$1 >> $dl_line
        jq ".media[]" /tmp/kagami/$1 > /tmp/kagami/images.$PID
        jq ".video[]" /tmp/kagami/$1 >> $dl_line
        jq ".url" /tmp/kagami/$1 >> $dl_line

        # extract mp4 vel gifs
        cat /tmp/kagami/$1 | jq '.video[] | [.variants[]?] ' > /tmp/kagami/mp4.tmp.$PID
        cat /tmp/kagami/mp4.tmp.$PID | jq '.[] | select(.url | contains("mp4")) | .url' > /tmp/kagami/mp4.$PID
        rm /tmp/kagami/mp4.tmp.$PID
        # sort/uniq dl lists
        cat /tmp/kagami/images.$PID | sort -u > /tmp/kagami/download.$PID
        cat /tmp/kagami/mp4.$PID | sort -u >> /tmp/kagami/download.$PID
        rm /tmp/kagami/images.$PID
        rm /tmp/kagami/mp4.$PID
    fi
    rm /tmp/kagami/$1
}

twitter_get_tweet()
{
	# 180commands/15minuts
	# twitter_get_tweet
	# https://api.twitter.com/1.1/statuses/show.json

        set -o errexit
        timestamp=`date +%s`
        nonce=`date +%s%T | openssl base64 | sed -e s'/[+=/]//g'`
        if [ $# -gt 0 ]
        then
                signature_base_string="GET&https%3A%2F%2Fapi.twitter.com%2F1.1%2Fstatuses%2Fshow.json&id%3D${1}%26oauth_consumer_key%3D${consumer_key}%26oauth_nonce%3D${nonce}%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D${timestamp}%26oauth_token%3D${oauth_token}%26oauth_version%3D1.0"
        fi
        signature_key="${consumer_secret}&${oauth_secret}"
        oauth_signature=`echo -n ${signature_base_string} | openssl dgst -sha1 -hmac ${signature_key} -binary | openssl base64 | sed -e s'/+/%2B/' -e s'/\//%2F/' -e s'/=/%3D/'`
        header="Authorization: OAuth oauth_consumer_key=\"${consumer_key}\", oauth_nonce=\"${nonce}\", oauth_signature=\"${oauth_signature}\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"${timestamp}\", oauth_token=\"${oauth_token}\", oauth_version=\"1.0\""
        if [ $# -gt 0 ]
        then
                data_curl="id=${1}"
        fi
	#set -x
        result=`curl -s --get 'https://api.twitter.com/1.1/statuses/show.json' --data "${data_curl}" --header "Content-Type: application/x-www-form-urlencoded" --header "${header}"`
	#set +x
	if [[ "$result" == *"code"* ]]
	then
		echo $1 > $timestamp
		echo $data_curl >> $timestamp
		echo $signature_base_string >> $timestamp
		echo $result >> $timestamp
        fi
	echo "[${result}]"
}

twitter_get_fav()
{
	# 15commands/15minutes
	# twitter_get_fav
	# twitter_get_fav since_id tweet_id
	# twitter_get_fav max_id tweet_id

	set -o errexit
        timestamp=`date +%s`
        nonce=`date +%s%T | openssl base64 | sed -e s'/[+=/]//g'`
	if [ $# -eq 0 ]
	then
	        signature_base_string="GET&https%3A%2F%2Fapi.twitter.com%2F1.1%2Ffavorites%2Flist.json&count%3D${count}%26oauth_consumer_key%3D${consumer_key}%26oauth_nonce%3D${nonce}%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D${timestamp}%26oauth_token%3D${oauth_token}%26oauth_version%3D1.0%26screen_name%3D${screen_name}"
		data_curl="count=${count}&screen_name=${screen_name}"
	else
		#since_id or max_id
		if [[ $1 == "since_id" ]]
		then
			signature_base_string="GET&https%3A%2F%2Fapi.twitter.com%2F1.1%2Ffavorites%2Flist.json&count%3D${count}%26oauth_consumer_key%3D${consumer_key}%26oauth_nonce%3D${nonce}%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D${timestamp}%26oauth_token%3D${oauth_token}%26oauth_version%3D1.0%26screen_name%3D${screen_name}%26since_id%3D${2}"
			data_curl="count=${count}&screen_name=${screen_name}&since_id=${2}"
		else
			signature_base_string="GET&https%3A%2F%2Fapi.twitter.com%2F1.1%2Ffavorites%2Flist.json&count%3D${count}%26max_id%3D${2}%26oauth_consumer_key%3D${consumer_key}%26oauth_nonce%3D${nonce}%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D${timestamp}%26oauth_token%3D${oauth_token}%26oauth_version%3D1.0%26screen_name%3D${screen_name}"
			data_curl="count=${count}&max_id=${2}&screen_name=${screen_name}"
		fi
	fi
        signature_key="${consumer_secret}&${oauth_secret}"
        oauth_signature=`echo -n ${signature_base_string} | openssl dgst -sha1 -hmac ${signature_key} -binary | openssl base64 | sed -e s'/+/%2B/' -e s'/\//%2F/' -e s'/=/%3D/'`
        header="Authorization: OAuth oauth_consumer_key=\"${consumer_key}\", oauth_nonce=\"${nonce}\", oauth_signature=\"${oauth_signature}\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"${timestamp}\", oauth_token=\"${oauth_token}\", oauth_version=\"1.0\""
	result=`curl -s --get 'https://api.twitter.com/1.1/favorites/list.json' --data "${data_curl}" --header "Content-Type: application/x-www-form-urlencoded" --header "${header}"`
	#set -x
	echo "${result}" > /tmp/kagami/$2.tweet_dl
	if [ $# -gt 0 ]
	then
		if [[ $1 == "since_id" ]]
		then
			if [ "${#result}" -gt 3 ]
			then
				echo "${result}"
			else
				echo ""
			fi
		else
			echo "${result}"
		fi
	else
		echo "${result}"
	fi
	#set +x
}

twitter_get_friend()
{
	#https://dev.twitter.com/rest/reference/get/friends/list
	#twitter_download GET https://api.twitter.com/1.1/friends/list.json?screen_name=${screen_name}
		set -o errexit
        timestamp=`date +%s`
        nonce=`date +%s%T | openssl base64 | sed -e s'/[+=/]//g'`
        if [ $# -gt 0 ]
        then
                signature_base_string="POST&https%3A%2F%2Fapi.twitter.com%2F1.1%2Ffriends%2Flist.json&26oauth_consumer_key%3D${consumer_key}%26oauth_nonce%3D${nonce}%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D${timestamp}%26oauth_token%3D${oauth_token}%26oauth_version%3D1.0%26screen_name%3D${1}"
        fi
        signature_key="${consumer_secret}&${oauth_secret}"
        oauth_signature=`echo -n ${signature_base_string} | openssl dgst -sha1 -hmac ${signature_key} -binary | openssl base64 | sed -e s'/+/%2B/' -e s'/\//%2F/' -e s'/=/%3D/'`
        header="Authorization: OAuth oauth_consumer_key=\"${consumer_key}\", oauth_nonce=\"${nonce}\", oauth_signature=\"${oauth_signature}\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"${timestamp}\", oauth_token=\"${oauth_token}\", oauth_version=\"1.0\""
        if [ $# -gt 0 ]
        then
                data_curl="screen_name=${1}"
        fi
        result=`curl -s --get 'https://api.twitter.com/1.1/friends/list.json' --data "${data_curl}" --header "Content-Type: application/x-www-form-urlencoded" --header "${header}"`
        
        echo ${result}
}

twitter_add_friend()
{
	# twitter_add_friend screen_name
	#https://dev.twitter.com/rest/reference/post/friendships/create
	#twitter_download POST https://api.twitter.com/1.1/friendships/create.json?screen_name=$1&follow=true
	set -o errexit
        timestamp=`date +%s`
        nonce=`date +%s%T | openssl base64 | sed -e s'/[+=/]//g'`
        if [ $# -gt 0 ]
        then
                signature_base_string="POST&https%3A%2F%2Fapi.twitter.com%2F1.1%2Ffriendships%2Fcreate.json&follow%3Dtrue%26oauth_consumer_key%3D${consumer_key}%26oauth_nonce%3D${nonce}%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D${timestamp}%26oauth_token%3D${oauth_token}%26oauth_version%3D1.0%26screen_name%3D${1}"
        fi
        signature_key="${consumer_secret}&${oauth_secret}"
        oauth_signature=`echo -n ${signature_base_string} | openssl dgst -sha1 -hmac ${signature_key} -binary | openssl base64 | sed -e s'/+/%2B/' -e s'/\//%2F/' -e s'/=/%3D/'`
        header="Authorization: OAuth oauth_consumer_key=\"${consumer_key}\", oauth_nonce=\"${nonce}\", oauth_signature=\"${oauth_signature}\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"${timestamp}\", oauth_token=\"${oauth_token}\", oauth_version=\"1.0\""
        if [ $# -gt 0 ]
        then
                data_curl="follow=true&screen_name=${1}"
        fi
        result=`curl -s -X POST 'https://api.twitter.com/1.1/friendships/create.json' --data "${data_curl}" --header "Content-Type: application/x-www-form-urlencoded" --header "${header}"`
        debuglog "add_friend" $result

	if [[ $result == *"code=\"32"* ]]
	then
                echo "Error while adding $1"
        else
                echo "Added $1"
        fi
}

PID=$$
if [ $# -gt 0 ]
then
	if [ $1 == "clean" ]
	then
		clean
	fi
fi

if [ -f ~/.kagami/kagami.cfg ]
then
	source ~/.kagami/kagami.cfg
        
        init_config_dirs

	printf "Checking for lock"
	while [ -f /tmp/kagami/kagami.lock ]
	do
		# wait 1minute
		sleep 60
		printf "."
	done
	touch /tmp/kagami/kagami.lock
	echo ""

	populate_download_list
	#read -p "1"
	# check if result isn't too small 'not auth' is 64chars
	FILESIZE=$(stat -c%s "/tmp/kagami/fav.$PID")
        if [ $FILESIZE -lt 200 ]
	then
		echo "WARNING: fav file is to small: $FILESIZE"
		exit
	fi

	echo "Create ids.$PID"
	jq -r .[].id_str /tmp/kagami/fav.$PID | sort -gu  > /tmp/kagami/ids.$PID
	#exit
	echo "Created ids.$PID"
	debuglog "Parsing ids" $PID
	while IFS='' read -r line || [[ -n "$line" ]]
	do
		debuglog "while line:" $line
		if grep -q $line ~/.kagami/ids_list
		then
			echo "$line found - skipping it..."
		else
			echo "$line processing..."
			# get single tweet
			jq ".[] | select(.id_str==\"$line\")" /tmp/kagami/fav.$PID > /tmp/kagami/$line.tmp
			debuglog "processing $line" $(cat /tmp/kagami/$line.tmp)
                        # make download list
                        if twitter_get_data $line
			then
			    echo "Starting downloading..."
			    while IFS='' read -r url_line
			    do
				debuglog "Start downloading for $line" "$url_line"
				if [ -f ~/.kagami/.downloaded ] && grep -Fxq $line ~/.kagami/.downloaded
				then
				    # code if found, skip
				    echo "Already exist.. $url_line"
				else
				    # not found in .downloaded
				    echo "Downloading.. $url_line"
				    url_no=${url_line:1:-1}
				    url="${url_no}:large"
				    file=${url_no##*/}
				    if [[ `wget -S --spider $url  2>&1 | grep 'HTTP/1.1 200 OK'` ]]
				    then
					wget -nc -nv -q -O $download_path/$file $url
				    else
					wget -nc -nv -q -O $download_path/$file $url_no
				    fi
				    echo $url_line >> ~/.kagami/.downloaded
				fi
			    done < /tmp/kagami/download.$PID
			    rm /tmp/kagami/download.$PID
			fi
			#add id of tweet to list of known ids
			echo $line >> ~/.kagami/ids_list
		fi
	done < /tmp/kagami/ids.$PID

	uniq ~/.kagami/ids_list | sort -g > ~/.kagami/ids_list.tmp
	cat ~/.kagami/ids_list.tmp > ~/.kagami/ids_list

	# clean up and unlock
	if [ -f ~/.kagami/ids_list.tmp ]
	then
		rm ~/.kagami/ids_list.tmp
	fi

	if [ -f /tmp/kagami/ids.$PID ]
	then
		rm /tmp/kagami/ids.$PID
	fi

	if [ -f /tmp/kagami/fav.$PID ]
	then
		rm /tmp/kagami/fav.$PID
	fi

	rm /tmp/kagami/kagami.lock
	echo "...unlocked..."
else
	new_config
fi


# vim: tabstop=4: shiftwidth=4: noexpandtab:
