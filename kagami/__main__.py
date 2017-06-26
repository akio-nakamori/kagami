#!/usr/bin/env python
# -*- coding: utf-8 -*-

import splash
import kagami
import sys
from threading import Thread
from Queue import Queue
from time import sleep

# variables
q = Queue()
last_since_id = 1
run_this = 1


def print_menu():
    print("What you want to do?")
    print("0 Exit")
    print("1 Get_All_Friends")
    print("2 Get_All_Favorite")
    print("3 Loop (Monitor) All_Favorites")


def worker():
    kag = kagami.Kagami()
    kag.run(silent=True)
    while True:
        next_item = q.get()
        if next_item is not None:
            kag.run(silent=True)
            if int(next_item) == -1:
                kag.get_friends()
            elif int(next_item) == 0:
                kag.download_media()
            elif int(next_item) > 0:
                global last_since_id
                last_since_id = kag.get_fav_tweets(int(next_item))
        q.task_done()


def run_daemon_task(kk, qq):
    kk.run_application = 1
    while kk.run_application == 1:
        global last_since_id
        qq.put(last_since_id)
        qq.put(0)
        qq.join()
        if last_since_id != 0:
            for i in xrange(1, 60):
                kagami.Kagami().print_progress_bar("Waiting ", i, 60)
                sleep(1)
        else:
            print("")  # new line
            for i in xrange(1, 60*15):
                kagami.Kagami().print_progress_bar("Sleeping ", i, 60*15)
                sleep(1)
            last_since_id = 1

# detect argument to start in daemon
if len(sys.argv) > 1:
    if sys.argv[1] == "daemon":
        run_this = 0

if run_this == 1:
    # splash screen
    print splash.splash
    print_menu()
else:
    print"starting..."

# initial setup
k = kagami.Kagami()
k.run(silent=False)
k.halt()

# setup worker
z = Thread(target=worker)
z.daemon = True
z.start()

while run_this == 1:
    command = raw_input("Pick [0-9]:")
    if command == "0":  # exit
        run_this = 0
    elif command == "1":  # get friends
        q.put(-1)
        q.join()
        print("Friends List Refresh: DONE")
    elif command == "2":  # get fav
        k.run_application = 1
        while k.run_application == 1:
            q.put(last_since_id)  # start from start
            q.put(0)  # download
            q.join()
            if last_since_id != 0:
                for i in xrange(1, 60):
                    kagami.Kagami().print_progress_bar("Waiting ", i, 60)
                    sleep(1)
            else:
                print("last_since_id = 0, time to say goodbye")
                k.run_application = 0
        print("Favorite Tweets Refresh: DONE")
    elif command == "3":  # loop fav
        run_daemon_task(k, q)
    else:
        run_this = 0

print("Shutdown Kagami...")
k.halt()
exit(0)
