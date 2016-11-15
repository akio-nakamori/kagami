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
	if [ $# -gt 1 ]
	then
    	echo "$2" >> ~/.kagami/log.kagami
	fi
}

clean()
{
    if [ -f /tmp/kagami/kagami.kill ]
    then
	rm /tmp/kagami/kagami.kill
    fi

    if [ -f /tmp/kagami/kagami.lock ]
    then
        rm /tmp/kagami/kagami.lock
    fi

    if [ -f /tmp/kagami/kagami.tweet.lock ]
    then
        rm /tmp/kagami/kagami.tweet.lock
    fi

    rm -f /tmp/kagami/*.tmp
}

ids()
{
    if [ -f ~/.kagami/ids_list ]
    then
	echo `cat ~/.kagami/ids_list | wc -l`
    fi
}

tweet()
{
    #tweet tweet_id
    twitter_get_tweet $1
}

max()
{
    twitter_get_fav max_id $1
}

since()
{
    twitter_get_fav since_id $1
}

populate_download_list()
{
if [ ! -f ~/.kagami/ids_list ]
then
    echo "Initial run..."
    twitter_get_fav > /tmp/kagami/fav.$PID
    touch ~/.kagami/ids_list
else
	number=$(cat ~/.kagami/ids_list | wc -l)
	if [ $number -gt 0 ]
    then
		cat ~/.kagami/ids_list | sort -ug > /tmp/kagami/ids_list.tmp
		cat /tmp/kagami/ids_list.tmp > ~/.kagami/ids_list
		rm /tmp/kagami/ids_list.tmp

		printf "Get new tweets"
		first=$(head -n 1 ~/.kagami/ids_list)
		last=$(tail -1 ~/.kagami/ids_list)

		debuglog "first $first number $number last $last"

		while [ $(( $(date --utc +%s) - 65 )) -lt $(date --utc --reference=/tmp/kagami/kagami.lock +%s) ]
		do
	    	# wait 60sec (65, but window is each 10 so 70sec)  before sending command
	    	printf "."
	    	sleep 10
		done
	
		debuglog "checking since_id $last"
    	get_since=`twitter_get_fav since_id $last`
		# wait 65s (because better more than 60 than getting code:34)
		sleep 65

		echo > /tmp/kagami/fav.$PID
		
		if [[ $get_since == *"code\":"* ]]
		then
	    	printf ": - "
	    	echo > /tmp/kagami/fav.$PID
		else
	    	printf ": + "
	    	echo $get_since > /tmp/kagami/fav.$PID
		fi

		debuglog "cheking max_id $first"
		get_max=`twitter_get_fav max_id $first`

		if [[ $get_max == *"code\":"* ]]
		then
	    	printf ": - "
		else
	    	printf ": + "
	    	echo $get_max >> /tmp/kagami/fav.$PID
		fi
	
		echo ""

		# update lock
        touch /tmp/kagami/kagami.lock
		touch /tmp/kagami/kagami.tweet.lock

		echo "Searching for missing older tweets"
		
		numer=`cat ~/.kagami/ids_list | wc -l`
		COUNTER=0
		while [ $COUNTER -le $number ]
        do
	    	printf "$COUNTER/$number : "
	    	
			num=$((number - COUNTER))
	    	debuglog "$number - $COUNTER = $num"
			if [ $num -eq 0 ]
	    	then
				num=1
	    	fi

	    	new_id=$(sed "${num}q;d" ~/.kagami/ids_list)

	    	printf "$new_id :"
	    	COUNTER=$((COUNTER + 1))
            
			while [ $(( $(date --utc +%s) - 65 )) -lt $(date --utc --reference=/tmp/kagami/kagami.lock +%s) ]
            do
                # wait till next compare (add buffer so it will be allways more than 1command/1minut
                printf "."
                sleep 70
            done

			debuglog "max_id $new_id"
            max_fav=`twitter_get_fav max_id $new_id`
	    	echo $max_fav > /tmp/kagami/prev.$PID

	    	touch /tmp/kagami/kagami.lock
	    	bad_code=1

			debuglog "checking for code 34"
	    	while [[ $max_fav == *"code\":34"* ]]
	    	do
				debuglog "wait 60s"
				while [ $(( $(date --utc +%s) - 10 )) -lt $(date --utc --reference=/tmp/kagami/kagami.lock +%s) ]
				do
		    		sleep 60
				done

				debuglog "max_id $new_id"
				max_fav=`twitter_get_fav max_id $new_id`
				echo $mad_fav > /tmp/kagami/$new_id.tmp
				echo $mad_fav > /tmp/kagami/prev.$PID

				debuglog "check if max_fav have less than 3 chars"
				if [ ${#max_fav} -lt 3 ]
				then
					debuglog "force max_fav = code:34"
			    	max_fav="code\":34"
				fi

				debuglog "bad_code = $bad_code"
				if [ $bad_code -gt 10 ]
				then
					debuglog "break out bad_code"
			    	break
				else
					debuglog "still bad_code = $((bad_code + 1))"
			    	bad_code=$((bad_code + 1))
			    	touch /tmp/kagami/kagami.lock
			    	printf "r"
				fi
	    	done

			debuglog "end code 34"

	    	#set +x
			if `jq -r .[].id_str /tmp/kagami/prev.$PID | sort -gu  > /tmp/kagami/ids_prev.$PID`
			then
				debuglog "id_str - ok"
			else 
				debuglog "id_str - not ok"
				cp /tmp/kagami/prev.$PID /tmp/kagami/prev.$PID.broken
			fi
	    	#cat /tmp/kagami/prev.$PID
	    	rm /tmp/kagami/prev.$PID
	    	prev_size=`cat /tmp/kagami/ids_prev.$PID | wc -l`
	    	
			debuglog "checking prev_size = $prev_size"
			# check if size is near empty
	    	if [ $prev_size -gt 0 ]
	    	then
                while IFS='' read -r preid || [[ -n "$preid" ]]
				do
    		    	if grep -q $preid ~/.kagami/ids_list
	    	    	then
						debuglog "$preid already in ids_list"
    	    			printf "-"
    	    	    else
						debuglog "$predid not found in ids_list. processing..."
						touch /tmp/kagami/kagami.tweet.lock
            			#locked
						while [ $(( $(date --utc +%s) - 5 )) -lt $(date --utc --reference=/tmp/kagami/kagami.tweet.lock +%s) ]
            			do
                	    	# wait till next compare
                	    	# printf "."
                	    	sleep 5
            			done
						
						#set -x
						printf "+"
						debuglog "get_tweet $preid"
						twitter_get_tweet $preid >> /tmp/kagami/fav.$PID
            			#unlocked
						rm /tmp/kagami/kagami.tweet.lock
        	    	fi
    			done < /tmp/kagami/ids_prev.$PID
				
				echo ""
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

twitter_get_data()
{
    # twitter_get_data ID-of-tmp-file

	debuglog "twitter_get_data"
    jq -r '. | { id: .id_str, date: .created_at, text: .text, url: [ .entities.urls[].url ], media: [ .extended_entities.media[]?.media_url_https ], video: [.extended_entities.media[]?.video_info ], user: .user.screen_name, user_url: .user.entities.url.urls[0].expanded_url }' /tmp/kagami/$1.tmp > /tmp/kagami/$1
    rm /tmp/kagami/$1.tmp

    author=`jq -r .user /tmp/kagami/$1`
	
	debuglog "check author $author"
    if grep -Fxq "$author" ~/.kagami/users.list
    then
        debuglog "$author is known (users.list)"
    else
        debuglog "$author adding to user.list"
		twitter_add_friend $author
    fi

	debuglog "creating meta-data"
    dl_line=$download_path"/"$1
    if [ ! -f $dl_line ]
    then
        debuglog "Creating meta-data for $1"
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
		return 0
	else
		debuglog "meta-data already exist"
		return 1
    fi
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
	if [[ "$result" == *"code\":"* ]]
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

	if [[ $result == *"code\":32"* ]]
	then
                echo "Error while adding $1"
        else
                echo "Added $1"
        fi
}

main()
{
    if [ -f ~/.kagami/kagami.cfg ]
    then
		source ~/.kagami/kagami.cfg
		
		debuglog "check for lock"
		if [ -f /tmp/kagami/kagami.lock ]
		then
	    	printf "locked"
		fi
		debuglog " wait till unlock"
		while [ -f /tmp/kagami/kagami.lock ]
		do
			sleep 60
			printf "."
		done
		
		debuglog "create lock as soon as there is open spot"
		touch /tmp/kagami/kagami.lock
		echo ""

		debuglog "populate_download_list"
		populate_download_list

		debuglog "check file size"
		# check if result isn't too small 'not auth' is 64chars most errors are less than 200chars
		FILESIZE=$(stat -c%s "/tmp/kagami/fav.$PID")
        	if [ $FILESIZE -lt 200 ]
		then
			echo "WARNING: fav file is to small: $FILESIZE"
			echo "Exiting with delay..."
			sleep 10
			rm /tmp/kagami/kagami.lock
			exit
		fi

		debuglog "Create ids.$PID"
		jq -r .[].id_str /tmp/kagami/fav.$PID | sort -gu  > /tmp/kagami/ids.$PID
		
		debuglog "Created ids.$PID"
		sed --in-place '/null/d' /tmp/kagami/ids.$PID
		
		debuglog "Parsing ids.$PID"
		while IFS='' read -r line || [[ -n "$line" ]]
		do
			debuglog "while line:" $line
			if grep -q $line ~/.kagami/ids_list
			then
				echo "$line found - skipping it..."
			else
				echo "$line processing..."	
				# get single tweet
				cat /tmp/kagami/fav.$PID > /tmp/kagami/new.fav.$line
				jq ".[] | select(.id_str==\"$line\")" /tmp/kagami/fav.$PID > /tmp/kagami/$line.tmp
                
				# make download list
                if twitter_get_data $line
				then
				    # echo "Starting downloading..."
			    	while IFS='' read -r url_line
			    	do
						debuglog "Start downloading for $line" "$url_line"

						if [ -f ~/.kagami/.downloaded ] && grep -Fxq $line ~/.kagami/.downloaded
						then
				    		# code if found, skip
				    		echo "Already exist.. $url_line"
						else
					    	# not found in .downloaded
					    	# echo "Downloading.. $url_line"
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
				else
					debuglog "meta-data of $line exist"
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
		#echo "...unlocked..."
    else
		printf "Missing config file\n"
    fi
}

PID=$$                                                                                                        
                                                                                                                                                                                                                             
if [ $# -gt 0  ]                                                                                               
then                                                                                                          
     if [ $1 == "clean"  ]                                                                                      
     then
		 clean
		 printf "clean\n"
	 elif [ $1 == "ids"  ]
	 then
		 ids                                                                                                   
     elif [ $1 == "tweet"  ]                                                                                    
     then                                                                                                      
         source ~/.kagami/kagami.cfg                                                                           
         tweet $2                                                                                              
     elif [ $1 == "max"  ]                                                                                      
     then                                                                                                      
         source ~/.kagami/kagami.cfg                                                                           
         max $2                                                                                                
     elif [ $1 == "since"  ]                                                                                    
     then                                                                                                      
         source ~/.kagami/kagami.cfg                                                                           
         since $2                                                                                              
     fi                                                                                                        
else                                                                                                          
     main                                                                                                      
fi 


# vim: tabstop=4: shiftwidth=4: noexpandtab:
