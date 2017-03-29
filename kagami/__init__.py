#!/usr/bin/env python
# -*- coding: utf-8 -*-

import time
from os.path import expanduser, join
from os.path import exists as os_exists
from os import mkdir
import json
import db
import splash
from twitter import *
from sys import platform, stdout
from sqlalchemy import exists
from time import time, sleep
from urllib import urlretrieve
from ntpath import split, basename
from threading import Thread
from Queue import Queue


if platform == "win32":
    import ctypes
else:
    from os import statvfs


class Kagami:
    run_application = 1
    home_dir = expanduser("~")
    cfg_dir = join(home_dir, ".kagami")
    cfg_file = join(cfg_dir, "kagami.json")
    config = {}
    timer_fav = {}
    timer_fri = {}

    def __init__(self):
        global run_application
        run_application = 1

    def stop_app(self):
        self.run_application = 0
        print("stop")

    def check_config(self):
        if not os_exists(self.cfg_dir):
            try:
                mkdir(self.cfg_dir, 0o750)
            except Exception as e:
                print("Error: {}".format(str(e)))
        else:
            if not os_exists(self.cfg_file):
                return False
            else:
                return True

    def new_config(self):
        print('Creating new config file ~/.kagami/kagami.cfg')
        print('All needed info are on https://apps.twitter.com/app/')
        Kagami.config['screen_name'] = raw_input('user that you want to monitor:')
        Kagami.config['consumer_key'] = raw_input('consumer_key:')
        Kagami.config['consumer_secret'] = raw_input('consumer_secret:')
        Kagami.config['oauth_token'] = raw_input('access_token:')
        Kagami.config['oauth_secret'] = raw_input('access_secret:')
        Kagami.config['download_path'] = raw_input('download_path:')
        Kagami.config['download_disk'] = raw_input('download_disk:')
        Kagami.config['database'] = str(join(self.cfg_dir, 'kagami.sqlite3'))
        json.dump(Kagami.config, open(name=self.cfg_file, mode='w'))
        print('Config saved...')

    def load_config(self):
        if not self.check_config():
            self.new_config()
        try:
            self.config = json.load(open(name=self.cfg_file, mode='r'))
            return True
        except Exception as e:
            print(str(e))
            return False

    def syntax_config(self):
        if len(self.config) > 0:
            need_list = {'screen_name', 'consumer_key', 'consumer_secret',
                         'oauth_token', 'oauth_secret', 'database',
                         'download_path', 'download_disk'}
            for key in self.config:
                if key in need_list:
                    need_list.remove(key)
            if len(need_list) == 0:
                return True
        return False

    def run(self, silent=True):
        if silent is False:
            print("Checking...")
        _checking_ok = False
        if not self.check_config():
            self.new_config()
        if self.load_config():
            if self.syntax_config():
                _checking_ok = True
        if not _checking_ok:
            if silent is False:
                print("Error: Syntax")
            self.stop_app()
        else:
            if silent is False:
                print("Syntax: OK")
                print("Database: Checking... ")

            db.init_db(self.config['database'])
            if silent is False:
                print("Database: OK")

            if not db.session.query(exists().where(db.TimerTable.name == unicode("fav"))).scalar():
                t = db.TimerTable()
                t.name = unicode("fav")
                t.time = time()
                t.limit = 75
                t.count = t.limit
                db.session.add(t)
                db.session.commit()
                self.timer_fav['time'] = t.time
                self.timer_fav['count'] = t.count
                self.timer_fav['limit'] = t.limit
            else:
                row = db.session.query(db.TimerTable).filter(db.TimerTable.name == unicode("fav")).first()
                self.timer_fav['time'] = row.time
                self.timer_fav['count'] = row.count
                self.timer_fav['limit'] = row.limit

            if not db.session.query(exists().where(db.TimerTable.name == unicode("fri"))).scalar():
                t = db.TimerTable()
                t.name = unicode("fri")
                t.time = time()
                t.limit = 15
                t.count = t.limit
                db.session.add(t)
                db.session.commit()
                self.timer_fri['time'] = t.time
                self.timer_fri['count'] = t.count
                self.timer_fri['limit'] = t.limit
            else:
                row = db.session.query(db.TimerTable).filter(db.TimerTable.name == unicode("fri")).first()
                self.timer_fri['time'] = row.time
                self.timer_fri['count'] = row.count
                self.timer_fri['limit'] = row.limit

            if silent is False:
                print("Timers: OK")

            if not os_exists(self.config['download_path']):
                mkdir(self.config['download_path'])
            if silent is False:
                print("Download: OK")

    def halt(self):
        db.session.close()

    def free_space(self):
        if platform == "win32":
            free_bytes = ctypes.c_ulonglong(0)
            ctypes.windll.kernel32.GetDiskFreeSpaceExW(ctypes.c_wchar_p(self.home_dir), None, None,
                                                       ctypes.pointer(free_bytes))
            user_free = free_bytes.value / 1024 / 1024 / 1024
        else:
            st = statvfs(self.home_dir)
            user_free = st.f_bavail * st.f_frsize / 1024 / 1024 / 1024

        if int(user_free) >= int(self.config['download_disk']):
            return True
        else:
            print("Not enough space")
            return False

    def get_fav_tweets(self, since_id):
        # resetting limit if needed
        if time() - float(self.timer_fav['time']) > 900:
            self.timer_fav['count'] = self.timer_fav['limit']
        if not since_id:
            since_id = 1
        t = Twitter(auth=OAuth(token=self.config['oauth_token'],
                               token_secret=self.config['oauth_secret'],
                               consumer_key=self.config['consumer_key'],
                               consumer_secret=self.config['consumer_secret']))
        kwargs = dict(screen_name=self.config['screen_name'], count=200, since_id=int(since_id))

        # limit 75 request (15 minutes(900sec)) 1r/12s
        # favorites = {'1'}  # dummy for start
        get_more_favorite = True
        tweets_count = 0
        tweets_count_max = 0
        local_last_since_id = since_id
        while get_more_favorite:
            if self.timer_fav['count'] > 0:  # and favorites.__len__() != 0:  # count_message_recived
                favorites = t.favorites.list(**kwargs)  # execute
                tweets_count_max += favorites.__len__()
                for favorite in favorites:
                    tweets_count += 1
                    self.print_progress_bar("Downloading Tweets: ", tweets_count, tweets_count_max)
                    if not db.session.query(exists().where(db.TweetTable.id_str == favorite['id_str'])).scalar():
                        n = db.TweetTable()
                        n.id_str = unicode(favorite['id_str'])
                        n.text = unicode(favorite['text'])
                        n.screen_name = unicode(favorite['user']['screen_name'])
                        if not db.session.query(exists().where(db.UserTable.screen_name == n.screen_name)).scalar():
                            self.add_friend(n.screen_name)
                        n.url = favorite['entities']['urls']
                        if n.url == "" or not n.url:
                            n.url = unicode("empty")
                        else:
                            n.url = n.url[0]['url']

                        if 'extended_entities' in favorite:
                            medias = favorite['extended_entities']['media']  # media_url_https
                            for media in medias:
                                f = db.FileTable()
                                f.user_screen_name = n.screen_name
                                f.tweet_id_str = n.id_str
                                if media['type'] == "photo":
                                    f.file = media['media_url_https']
                                elif media['type'] == "video" or media['type'] == "animated_gif":
                                    bitrate = 0
                                    for variant in media['video_info']['variants']:
                                        if 'bitrate' in variant:
                                            if variant['bitrate'] >= bitrate:
                                                bitrate = variant['bitrate']
                                                f.file = variant['url']
                                else:
                                    print("Unsupported type:" + str(media['type']))
                                f.local = 0
                                if not db.session.query(exists().where(db.FileTable.file == f.file)).scalar():
                                    db.session.add(f)
                                    db.session.commit()

                        db.session.add(n)
                        db.session.commit()

                if favorites.__len__() != 0:
                    if since_id in kwargs:
                        kwargs.__delitem__('since_id')
                    # kwargs['since_id'] = favorites[0]['id']
                    fav_len = favorites.__len__()
                    kwargs['max_id'] = favorites[fav_len - 1]['id']
                    # local_last_since_id = int(kwargs['since_id'])
                else:
                    get_more_favorite = False
                    local_last_since_id = 0

                self.timer_fav['time'] = favorites.rate_limit_reset
                self.timer_fav['count'] = favorites.rate_limit_remaining
                self.timer_fav['limit'] = favorites.rate_limit_limit
            else:
                # we hit the limit
                time_now = time()
                reset_time = self.timer_fav['time'] - time_now
                print("")  # empty line
                if reset_time > 0:
                    reset_ticks = int(reset_time) + 1
                    for tick in xrange(1, reset_ticks):
                        self.print_progress_bar("Waiting for favorites_list limit reset: ", tick, reset_ticks)
                        sleep(1)
                self.timer_fav['time'] = time()
                if self.timer_fav['limit'] > 0:
                    self.timer_fav['count'] = self.timer_fav['limit']
                else:
                    self.timer_fav['count'] = 75
                # favorites = {'1'}

            db.session.query(db.TimerTable).filter_by(name=unicode('fav')).update({"time": self.timer_fav['time']})
            db.session.query(db.TimerTable).filter_by(name=unicode('fav')).update({"count": self.timer_fav['count']})
            db.session.query(db.TimerTable).filter_by(name=unicode('fav')).update({"limit": self.timer_fav['limit']})
            db.session.commit()

        return local_last_since_id

    def get_friends(self):
        # resetting limit if needed
        if time() > float(self.timer_fri['time']):
            self.timer_fri['count'] = self.timer_fri['limit']

        t = Twitter(auth=OAuth(token=self.config['oauth_token'],
                               token_secret=self.config['oauth_secret'],
                               consumer_key=self.config['consumer_key'],
                               consumer_secret=self.config['consumer_secret']))
        kwargs = dict(screen_name=self.config['screen_name'],
                      include_user_entities=0,
                      skip_status=1,
                      cursor=-1,
                      count=200)

        # dummy friends
        # limit 15 req (15 minutes(900sec)) 1r/60s
        friends = dict(next_cursor=-1)
        friend_count = 0
        friend_count_max = 0
        get_more_friends = True
        while get_more_friends:
            if self.timer_fri['count'] > 0 and friends['next_cursor'] != 0:
                friends = t.friends.list(**kwargs)  # execute
                friend_count_max += friends['users'].__len__()
                for friend in friends['users']:
                    friend_count += 1
                    self.print_progress_bar("Downloading Friends: ", friend_count, friend_count_max)
                    if not db.session.query(exists().where(db.UserTable.id_str == friend['id_str'])).scalar():
                        u = db.UserTable()
                        u.id_str = friend['id_str']
                        u.screen_name = friend['screen_name']
                        u.added = 0
                        db.session.add(u)
                        db.session.commit()
                kwargs['cursor'] = friends['next_cursor']

                self.timer_fri['time'] = friends.rate_limit_reset
                self.timer_fri['count'] = friends.rate_limit_remaining
                self.timer_fri['limit'] = friends.rate_limit_limit
            else:
                if friends['next_cursor'] == 0:
                    get_more_friends = False
                else:
                    # we hit the limit
                    reset_time = time() - self.timer_fri['time']
                    print("Waiting {} seconds because friends_list limit".format(str(reset_time)))
                    if reset_time < 0:
                        reset_time *= -1
                    time_to_wait = int(reset_time) + 1
                    current_seconds = 0
                    while current_seconds <= time_to_wait:
                        current_seconds += 1
                        Kagami().print_progress_bar("Waiting: ", current_seconds, time_to_wait)
                        sleep(1)

                    self.timer_fri['time'] = time()
                    self.timer_fri['count'] = self.timer_fri['limit']

            db.session.query(db.TimerTable).filter_by(name='fri').update({"time": self.timer_fri['time']})
            db.session.query(db.TimerTable).filter_by(name='fri').update({"count": self.timer_fri['count']})
            db.session.query(db.TimerTable).filter_by(name='fri').update({"limit": self.timer_fri['limit']})
            db.session.commit()

    def add_friend(self, screen_name):
        # https://dev.twitter.com/rest/reference/post/friendships/create
        t = Twitter(auth=OAuth(token=self.config['oauth_token'],
                               token_secret=self.config['oauth_secret'],
                               consumer_key=self.config['consumer_key'],
                               consumer_secret=self.config['consumer_secret']))
        kwargs = dict(screen_name=screen_name,
                      follow=1)
        friends = t.friendships.create(**kwargs)  # execute
        return friends['following']

    def remove_friend(self, screen_name):
        # https://dev.twitter.com/rest/reference/post/friendships/destroy
        t = Twitter(auth=OAuth(token=self.config['oauth_token'],
                               token_secret=self.config['oauth_secret'],
                               consumer_key=self.config['consumer_key'],
                               consumer_secret=self.config['consumer_secret']))
        kwargs = dict(screen_name=screen_name)
        friends = t.friendships.destroy(**kwargs)  # execute
        return ~friends['following']

    def download_media(self):
        if self.free_space:
            file_to_download_list = db.session.query(db.FileTable).filter(db.FileTable.local == 0).all()
            download_count_max = len(file_to_download_list)
            download_count = 1
            for file_to_download in file_to_download_list:
                self.print_progress_bar("Downloading media: ", download_count, download_count_max)
                head, tail = split(file_to_download.file)
                filename = tail or basename(head)
                file_path = join(self.config['download_path'], filename)
                urlretrieve(file_to_download.file, file_path)
                download_count += 1
                db.session.query(db.FileTable).filter_by(id=file_to_download.id).update({"local": 1})
            db.session.commit()

    @staticmethod
    def print_progress_bar(prefix, counter, counter_max):
        value = float(counter) / float(counter_max)
        value *= 10
        i = 0
        percent = ""
        while i < value:
            percent += "#"
            i += 1
        i -= 1
        while i < 9:
            percent += "-"
            i += 1
        percent += " " + str(counter) + "/" + str(counter_max)
        stdout.write("\r" + prefix + percent)
        stdout.flush()


def print_menu():
    print("What you want to do?")
    print("0 Exit")
    print("1 Get_All_Friends")
    print("2 Get_All_Favorite")
    print("3 Loop (Monitor) All_Favorites")


def worker():
    kag = Kagami()
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

q = Queue()

last_since_id = 1

if __name__ == '__main__':
    print splash.splash
    k = Kagami()
    k.run(silent=False)

    z = Thread(target=worker)
    z.daemon = True
    z.start()

    print_menu()

    run_this = 1
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
                        Kagami().print_progress_bar("Waiting ", i, 60)
                        sleep(1)
                else:
                    print("last_since_id = 0, time to say goodbye")
                    k.run_application = 0
            print("Favorite Tweets Refresh: DONE")
        elif command == "3":  # loop fav
            k.run_application = 1
            while k.run_application == 1:
                q.put(last_since_id)
                q.put(0)
                q.join()
                if last_since_id != 0:
                    for i in xrange(1, 60):
                        Kagami().print_progress_bar("Waiting ", i, 60)
                        sleep(1)
                else:
                    print("")  # new line
                    for i in xrange(1, 60*15):
                        Kagami().print_progress_bar("Sleeping ", i, 60*15)
                        sleep(1)
                    last_since_id = 1
        else:
            run_this = 0

    print("Shutdown Kagami...")
    k.halt()
    exit(0)
