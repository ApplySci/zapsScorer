# -*- coding: utf-8 -*-

class Config(object):

    EMAIL_HOST = 'smtp.webfaction.com'
    EMAIL_HOST_USER = 'londonanalytics'
    EMAIL_HOST_PASSWORD = 'zachzach'
    EMAIL_USE_SSL = True
    EMAIL_PORT = 465

    SECRET_KEY = b'wa-Ba-Pa-Lu-La'
    DEFAULT_PASSWORD = 'bambam'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_DATABASE_URI = 'sqlite:///C:\\library\\Dropbox\\source\\android\\flutter\\zaps_scorer\\server\\mjserver\\mj.sqlite'

    DISCORD_CLIENT_ID = '481694502420217856'
    DISCORD_CLIENT_SECRET = 'h3UGr4THxANW5GVV3W7vCMyzpy6F_b-K'

    # mj.apply.sci
    GOOGLE_CLIENT_ID = '875166051316-1opncm6672isl39s7rfttftvilcrc6dt.apps.googleusercontent.com'
    GOOGLE_CLIENT_SECRET = 'VCp7K6J7ThMtovtpAv7qmB8-'
