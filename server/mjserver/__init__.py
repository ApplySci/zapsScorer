# -*- coding: utf-8 -*-
'''
This is the central co-ordinator of the flask server.
It creates the app, configures it, opens the databaes, and starts the login manager.
It is crucial that the imports from the module are at the very end, to avoid
complications from circular imports.
It only knows where the database lives, because we passed the base directory
in sys.path[0]. As a backup, for Windows development machines, the database
location can be specified in config.py, in the form:
SQLALCHEMY_DATABASE_URI = 'sqlite:///C:\\android\\ZAPScorer\\server\\mj.sqlite'
'''
import pathlib
import sys

# do this before any other imports might mess with sys.path
BASE_DIR = pathlib.Path(sys.path[0])

# imports from framework

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_login import LoginManager

# imports from app
from mjserver.config import Config

#%%
app = Flask(__name__, static_folder=str(BASE_DIR / 'static'))
app.config.from_object(Config)
test = str(BASE_DIR / 'mj.sqlite')

if test[0] == '/':
    # we are on *nix machine, so override Config value with live path
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + test

app.config['DEBUG'] = True

db = SQLAlchemy(app)
migrate = Migrate(app, db)
login = LoginManager(app)
login.login_view = 'login'

from mjserver import routes, models, errors
