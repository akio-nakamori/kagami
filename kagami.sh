#!/bin/bash
#
# Kagami (for Twitter)
# Author : bigretromike
# GLPv2
#

init_config_dirs()
{
	if [ ! -d /tmp/kagami  ]
        then
                mkdir /tmp/kagami
        fi

	if [ ! -f ~/.kagami/users.list  ]
	then
		touch ~/.kagami/users.list
	fi

	if [ ! -d $download_path  ]
	then
		mkdir $download_path
	fi
	
	if [ -f ~/.kagami/log.kagami  ]
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
	if [ ! -d ~/.kagami  ]
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
}

menu_input()
{
        read -p "Pick [0-6]: " input
        case $input in
		[0]*) exit;;
		[1]*) daemon_start;;
		[2]*) daemon_stop;;
                [3]*) check_space_now;;
		[4]*) splash;;
		[5]*) daemon_kill;;
		[6]*) daemon_status;;
        esac
}

check_space()
{
	freespace="$(df -H | grep -vE '^Filesystem|tmpfs|cdrom|udev' | awk '{ print $5  }' | cut -d'%' -f1)"
	free_space="${freespace}"
	requ_space=30

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

daemon_start()
{
	run_this=/opt/kagami/kagami-watchdog.sh
	text -x $run_this || exit 5
	PID_this=/tmp/kagami/kagami.pid

	if check_space
	then
		printf "Starting daemon...\n"
		startproc -f -p $PID_this $run_this
		printf "Running...\n"
	else
		printf "Not enought space\n"
		read -n1 -r -p "Press anything to continue..." key
	fi
}

daemon_stop()
{
	touch /tmp/kagami/kagami.kill
}

daemon_kill()
{
	if  /tmp/kagami/kagami.lock
	then
		printf "Kagami is in middle of working... but I will kill her :(\n"
	fi
	PID_this="$(cat /tmp/kagami/kagami.pid)"
	kill -15 $PID_this
	printf "I will clean because she wont work in dirty room\n"
	$(/opt/kagami/kagami-worker.sh clean)
}

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

if [ -f ~/.kagami/kagami.cfg  ]
then
	source ~/.kagami/kagami.cfg
	init_config_dirs
	splash
	menu
	while true
	do
		menu_input
	done
else
	new_config
fi

# vim: tabstop=4: shiftwidth=4: noexpandtab:
