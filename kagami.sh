#!/bin/bash
#
# KAGAMI for Twitter
# Author : BigRetroMike
# GPLv2
#

cfg_file=~/.kagami/kagami.cfg

#check if config exist and if not force creation of it
check_config()
{
if [ ! -f $cfg_file ]
then
	while [ ! -f $cfg_file ]
	then
		new_config
	fi
fi
}

#ask user about creating config file
new_config()
{
	echo '~/.kagami/kagami.cfg file missing'
        read -p "Create $cfg_file? [y/n]" input
        case $input in
                [Yy]*) new_config_create;;
                [Nn]*) exit;;
        esac
}

#check config file for all needed settings
syntax_config()
{
if grep -q screen_name "$cfg_file"; then
	if grep -q consumer_key "$cfg_file"; then
		if grep -q consumer_secret "$cfg_file"; then
			if grep -q oauth_token "$cfg_file"; then
				if grep -q oauth_secret "$cfg_file"; then
					if grep -q download_path "$cfg_file"; then
						if grep -q download_disk "$cfg_file"; then
							return True
						else
							read -p "download_disk:" down_disk
							echo "download_disk=$down_disk" >> $cfg_file
							return True
						fi
					fi
				fi
			fi
		fi
	fi
fi

return False
}

#wizard for config creation
new_config_create()
{
	if [ ! -d ~/.kagami  ]
	then
		mkdir ~/.kagami
		echo 'Created directory ~/.kagami'
	fi
	echo 'Creating config file...'
	echo 'All needed info are on https://apps.twitter.com/app/'
	read -p "user that you want to monitor" login
	echo "screen_name=$login" > $cfg_file.tmp
	read -p "consumer_key:" con_key
	echo "consumer_key=$con_key" >> $cfg_file.tmp
	read -p "consumer_secret:" con_secret
	echo "consumer_secret=$con_secret" >> $cfg_file.tmp
	read -p "access_token:" acc_token
	echo "oauth_token=$acc_token" >> $cfg_file.tmp
	read -p "access_secret:" acc_secret
	echo "oauth_secret=$acc_secret" >> $cfg_file.tmp
	read -p "download_path:" down_path
	echo "download_path=$down_path" >> $cfg_file.tmp
	read -p "download_path:" down_disk
	echo "download_disk=$down_disk" >> $cfg_file.tmp
	mv -f $cfg_file.tmp $cfg_file
	echo 'Created config file $cfg_file'
}

#check and created folderd and files inside home dir for kagami
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

	if [ ! -d $download_path  ]
	then
		mkdir $download_path
	fi
	
	if [ -f ~/.kagami/log.kagami ]
	then
		touch ~/.kagami/log.kagami
	fi
}

#Kagami is Kagami
splash()
{
	clear
	tput setab 0
	tput setaf 7

	echo $'                                                                      '
	echo $'                                        `.             ``             '
	echo $'                          `..--::::---/sh/-:::://++o+/:`              '
	echo $'                     .:+syhhhhhhhhhhhhhhh+yhhhhys/-`                  '
	echo $'                  -+yhhhhhhhhhhhhhhhhhhhsosyhhhhhhhyso:.              '
	echo $'         ````   -shhhhhhhhhhhhhhhhhhhhyh+hhshhhhhhhhhdNNmy+.          '
	echo $'     `-:/++////+yyysshhmdhhhhhhhhhhhhshy:shhyhhddmmmNNNNNNNNdo-       '
	echo $'  `-/+++//+/++++ooosddmNNNmmmdddhdddyshohosddmdmmmmmmmmmmmdhdddy:     '
	echo $'./++++/:/yy+++++/+yhhddhhhhhhhhyshhyhyshmshohhshhhhhhhhhhhhs..:+sy/   '
	echo $'-+++++//ys++++++/hhhhyhyyhhhhhhohhydyhsmmymhohyohhhhhhhhhhhhy:`  `-/. '
	echo $' :++++++y++++++/yhhhoyyyhhhhhy+yhydmssmmmdhmhoh/shhhhhyhhhhhhh+-`     '
	echo $'  :++++o++++++:yhhy+oyshhyssoooyydmdsdmmmmymmys+ooyyhhhshhhhhhh+:-    '
	echo $'   -++/s/++++/ohhy+/ysyyyyhshyhydmmyhmmmmmymmmoomsshhhhsshhhyyhh/.    '
	echo $'    `:/o+++++:hhs+o+sshhhhshmsydmmmhmmmmmmhmmmh+mmoyhhhyoshhhoyhy`    '
	echo $'      .+++++++hs/o+soyhhhohmhsmmmmmmmmmmmmdmmmm+mmmohhhh+oyhhy-oho    '
	echo $'      .+++++:yy//o/sshhhosys/yddmmmmmmmmmmmmmdhoooooohhhooshhh. :y-   '
	echo $'      :oo+hh+h/o/o/osho`/osso..-/hmmmmmmmmmms+:.-oh/oyhhsooyhh:  .+   '
	echo $'      :oo+hyo+oo/o/oshsoNNshd:::hmmmmmmmmmmmhdo::/Nhd+hhsooshh/   `   '
	echo $'      :oo+hy+/ood+++yyomdN::/:::ymmmmmmmmmmm+::::oNm+/yho/oshh+       '
	echo $'      :oo+yy+sosmoo/y+mmmN++y/+odmmmmmmmmmmm+s/osmNyyy+h++/oyh+       '
	echo $'      /oooohsyoodmo/osmmmmm++ssommmmmmmmmmmmhyhydNmsyo/h/o:-yh/       '
	echo $'      /ooo+yshyooyh//dmmmmmmmmmmmmmmmmmmmmmmmmmmmmd+/o/s:o- :h-       '
	echo $'      /oooo+yshsoooy+/oymdddmmmmmmmmmmmmmmmmmmmmddyo/oo-++.  +`       '
	echo $'      ++oooo+ohhsooshs+o:+hmmmmmmmmmmmmmmmmmmmmmhyoo/oo+o+`           '
	echo $'      ++ooooo+ohhsooyh+o/  ./sdmmmmmmmmmmmmhs+-+oooo/oooo/            '
	echo $'      ++oooooo/ohhsoshh+o.  :///yyyhhhsso-     ooooo/oooo:            '
	echo $'      ++ooooooo-+hhysshy++.////yhhhhhso///:.` `ooooo/ooos-            '
	echo $'      ++ooooooo: :hdysyhy+//////yhhhhhhs//////:++ooo/ooos-            '
	echo $'      +o+oooooo:  -ydhyyhs+://///ysyyyss://///:++o+o/ooos/            '
	echo $'      /o/oooooo: -o+yhhhhhs///////hhhhhh//////++oo/s/oooso            '
	echo $'      :o+ooooooodmy+/shhhhhs:+/////hhhhh////++o/y+sNsooosy            '
	echo $'      -oo/oooooNNNNms+shhhhho/o++++/hhhh/++oo++so+mNN+ooyh`           '
	echo $'      .oo+ooooyNNNNNNd+shhhhh+s+oooooNNN+ooo+oos+yNNNoooyh-           '
	echo $'                                                                      '

	tput sgr0
}

#plain menu
menu()
{
    echo 'What you want to do?'
	echo '0 Exit'
	echo '1 start daemon'
	echo '2 stop daemon'
	echo '3 check space'
	echo '4 kagami splash'
	echo '5 kill daemon'
	echo '6 status'
	echo '7 init-dir'
	echo '8 run once'
	echo '9 clean'
}

#handle menu input
menu_input()
{
	read -p "Pick [0-8]: " input
	case $input in
		[0]*) exit;;
		[1]*) daemon_start;;
		[2]*) daemon_stop;;
		[3]*) check_space_now;;
		[4]*) splash;;
		[5]*) daemon_kill;;
		[6]*) daemon_status;;
		[7]*) init_config_dirs;;
		[8]*) run_once;;
		[9]*) clean;;
    esac
}

#clean all temp data and locks
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

#check if disk have enough percent of free space
check_space()
{
	freespace="$(df -H | grep -vE '^Filesystem|tmpfs|cdrom|udev|run|boot'  | grep -E 'dev/' | awk '{ print $5   }' | cut -d'%' -f1)"
	free_space="${freespace}"
	requ_space=$download_disk

	if [ "$free_space" -gt "$requ_space" ]
	then
		return 0
	else
		return 1
	fi
}

check_space_now()
{
	if check_space
	then
		printf "you are ok\n"
	else
		printf "make space\n"
	fi
}

#check status of daemon
daemon_status()
{
	if [ -f /tmp/kagami/kagami.pid ]
	then
		if [ -f /tmp/kagami/kagami.lock ]
		then
			printf "Kagami is running :-)\n"
		else
			printf "Kagami watchdog is running but Kagami sleep"
		fi
	else
		printf "Kagami isn't running\n"
	fi
}

run_once()
{
	if check_space
	then
		/opt/kagami/kagami.sh once
	else
		printf "Not enought space\n"
	fi
}

#run daemon
daemon_start()
{
	run_this="/opt/kagami/kagami.sh daemon"
	test -x $run_this || exit 5
	PID_this=/tmp/kagami/kagami.pid
	
	if check_space
	then
		printf "Starting daemon...\n"
		PID = setsid $run_this >/dev/null 2>&1 < /dev/null &
		echo $PID > $PID_this
		printf "Running...\n"
	else
		printf "Not enought space\n"
		read -n1 -r -p "Press anything to continue..." key
	fi
}

#init killing procedure
daemon_stop()
{
	touch /tmp/kagami/kagami.kill
}

#execute kill command
daemon_kill()
{
	if  /tmp/kagami/kagami.lock
	then
		printf "Kagami is in middle of working... but I will kill her :(\n"
	fi
	PID_this="$(cat /tmp/kagami/kagami.pid)"
	kill -15 $PID_this
	printf "I will clean because she wont work in dirty room\n"
	clean
}

### Twitter Magic ###

debuglog()
{
    # title message
    echo "$1" >> ~/.kagami/log.kagami
	if [ $# -gt 1 ]
	then
    	echo "$2" >> ~/.kagami/log.kagami
	fi
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

daemon_run()
{
    if [ -f $cfg_file ]
    then
		source $cfg_file
		
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
	if [ $1 == "daemon" ]
	then
		daemon_start
		print "daemon"
	elif
    if [ $1 == "clean" ]                                                                                      
    then
		clean
		printf "clean\n"
	elif [ $1 == "ids" ]
	then
		ids                                                                                                   
    elif [ $1 == "tweet" ]                                                                                    
    then                                                                                                      
		source $cfg_file                                                                           
		tweet $2                                                                                              
    elif [ $1 == "max" ]                                                                                      
    then                                                                                                      
		source $cfg_file                                                                           
		max $2                                                                                                
    elif [ $1 == "since" ]                                                                                    
    then                                                                                                      
		source $cfg_file                                                                           
		since $2                                                                                              
    fi                                                                                                        
else                                                                                                          
	check_config
	if syntax_config
	then
		source $cfg_file
		init_config_dirs
		splash
		menu
		while true
		do
			menu_input
		done
	else
		echo 'Config file is missing some settings, Kagami is not pleased :('
	fi
fi 

# vim: tabstop=4: shiftwidth=4: noexpandtab: