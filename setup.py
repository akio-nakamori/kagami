#!/usr/bin/env python

try:
    from setuptools import setup
except ImportError:
    from distutils.core import setup

setup(name='kagami',
      version="0.6",
      description='Kagami is Twitter bot that scan all favorites tweet of given user.',
      author='bigretromike',
      url='https://github.com/akio-nakamori/kagami/',
      packages=["kagami", ],
      install_requires=[
          'twitter>=1.17.1',
          'sqlalchemy>=1.1.5'
      ],
      license='MIT'
      )
