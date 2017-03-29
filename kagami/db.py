#!/usr/bin/env python
# -*- coding: utf-8 -*-

from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import create_engine, exists
from sqlalchemy.orm import relationship, sessionmaker
from sqlalchemy.schema import Column, ForeignKey
from sqlalchemy.types import Integer, Unicode, Float
from sqlalchemy.pool import NullPool

Base = declarative_base()
session = None
engine = None


def init_db(db_file):
    global engine
    engine = create_engine('sqlite:///' + str(db_file), poolclass=NullPool)
    Session = sessionmaker(bind=engine)
    global session
    session = Session()
    Base.metadata.create_all(engine)


def get_session():
    return session


class UserTable(Base):
    __tablename__ = 'user'
    id = Column(Integer, primary_key=True)
    id_str = Column(Unicode(512), nullable=False)
    screen_name = Column(Unicode(512), nullable=False)
    added = Column(Integer, nullable=False)

    def __repr__(self):
        return "<User(id_str='%s', screen_name='%s')>" % (self.id_str, self.screen_name)


class FileTable(Base):
    __tablename__ = 'file'
    id = Column(Integer, primary_key=True)
    file = Column(Unicode(512), nullable=False)
    local = Column(Integer, nullable=False)
    user_screen_name = Column(Unicode(512), nullable=False)
    tweet_id_str = Column(Unicode(512), nullable=False)


class TimerTable(Base):
    __tablename__ = 'timer'
    id = Column(Integer, primary_key=True)
    name = Column(Unicode(3), nullable=False)
    count = Column(Integer, nullable=False)
    limit = Column(Integer, nullable=False)
    time = Column(Float, nullable=False)


class TweetTable(Base):
    __tablename__ = 'tweet'
    id = Column(Integer, primary_key=True)
    id_str = Column(Unicode(512), nullable=False)
    screen_name = Column(Unicode(512), nullable=False)
    text = Column(Unicode(512), nullable=False)
    url = Column(Unicode(512), nullable=True)
