# -*- coding: utf-8 -*-
# copy to config.py and insert values
class Config(object):

    EMAIL_HOST = '' # smtp.example.com
    EMAIL_HOST_USER = '' # username
    EMAIL_HOST_PASSWORD = '' # password
    EMAIL_USE_SSL = True
    EMAIL_PORT = 465

    SECRET_KEY = b'' # any long string
    DEFAULT_PASSWORD = '' # something clever
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_DATABASE_URI = '/path/to/mj.sqlite'

    DISCORD_CLIENT_ID = ''
    DISCORD_CLIENT_SECRET = ''

    GOOGLE_CLIENT_ID = ''
    GOOGLE_CLIENT_SECRET = ''
