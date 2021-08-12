# -*- coding: utf-8 -*-
'''
The database structure. flask db uses this to auto-generate the db.
And the server code uses this to operate the db.
'''

# core imports

from json import loads as json_loads, dumps as json_dumps
import pickle
import random
from datetime import datetime
import sys

# framework imports

from flask import jsonify
from flask_login import UserMixin
from sqlalchemy.ext.associationproxy import association_proxy
from sqlalchemy.orm.collections import attribute_mapped_collection
from werkzeug.security import generate_password_hash, check_password_hash

# app imports

from mjserver import db, BASE_DIR

# initialisation

with open(str(BASE_DIR / 'wordlist.pickle'), 'rb') as wordlist_file:
    wordlist = pickle.load(wordlist_file)

wordlist_len = len(wordlist)


def putIntoQueue(game_id, msg):
    if game_id not in QUEUES:
        # no one is watching this game :(
        return

    for q in QUEUES[game_id]:
        q.put(msg)

QUEUES = {'put': putIntoQueue}


class Player(db.Model, UserMixin):
    """
    Currently we work on the basis that every registered player has a website account, and
    every registered website account is a (potential) player. So this class is used
    both for players and for website players, as there's a one-to-one mapping between them.
    """
    __tablename__ = 'player'
    player_id = db.Column(db.Integer, primary_key=True)
    name_last_updated = db.Column(db.DateTime(), default=datetime.utcnow, onupdate=datetime.utcnow)
    token = db.Column(db.String(255))
    email = db.Column(db.Unicode(255), unique=True)
    name = db.Column(db.Unicode(255), unique=True)
    login_count = db.Column(db.Integer)
    pin = db.Column(db.String(4), default='0000')
    password_hash = db.Column(db.String(128))
    last_login_at = db.Column(db.DateTime())
    current_login_at = db.Column(db.DateTime())
    login_count = db.Column(db.Integer)
    active = db.Column(db.Boolean(), default=True)
    email_confirmed = db.Column(db.Boolean(), default=False)
    country = db.Column(db.String(2))
    ema_number = db.Column(db.Text())
    note = db.Column(db.UnicodeText())

    games = association_proxy('played_games', 'game')
    games_scores = association_proxy('played_games', 'score')
    games_places = association_proxy('played_games', 'place')
    seasons = association_proxy('played_seasons', 'season')
    seasons_scores = association_proxy('played_seasons', 'score')
    seasons_places = association_proxy('played_seasons', 'place')

    def __repr__(self):
        ''' just for pretty printing '''
        return '<Player {}>'.format(self.name)

    @classmethod
    def check_token(cls, token):
        return cls.query.filter_by(token=token).first()

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def create_token(self):
        ''' provide random 4-word sequence for logins '''
        token = ''
        sep = ''
        for idx in random.sample(range(wordlist_len), 4):
            token += sep + wordlist[idx]
            sep = ' '
        self.token = token
        db.session.commit()

    def gdpr_dump(self):

        keys = [
            'id', 'token', 'email', 'name', 'login_count', 'pin',
            'password_hash', 'last_login_at', 'current_login_at',
            'login_count', 'active', 'email_confirmed']

        out = {}
        for key in keys:
            out[key] = str(getattr(self, key))

        out['games'] = []
        for game in self.games:
            out['games'].append(game.json)

        return jsonify(out)

    @classmethod
    def get_all_names(cls, modified):
        if modified:
            out = db.session.query(cls.player_id, cls.name).filter(cls.active==True, cls.name_last_updated > modified).order_by(cls.name)
        else:
            out = db.session.query(cls.player_id, cls.name).filter(cls.active==True).order_by(cls.name)
        return out

    def get_id(self):
        return str(self.player_id)

    def get_token(self):
        '''
        issue an authentication token for logins that is a random 4-word sequence
        and store it with the player in the database.
        Currently, the token does not expire.
        '''
        if not self.token :
            self.create_token()

        return self.token

    def is_active(self):
        return self.active

    def merge_with(self, other):
        '''
        Merge another player into this one. Note that this will currently
        only be used from the shell, as it makes irreversible changes
        that could really mess things up
        '''
        games_to_move = []
        for game in other.games:
            games_to_move.append(game)

        for game in games_to_move:
            player_game = PlayersGames.query.filter_by(player_id=other.player_id, game_id=game.game_id).first()
            player_game.player = self
            game_json = json_loads(game.json)
            for player in game_json['players']:
                if player['player_id'] == other.player_id:
                    player['player_id'] = self.player_id
                    player['name'] = self.name

            game.json = json_dumps(game_json)
            db.session.commit()

        db.session.delete(other)
        db.session.commit()


    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def set_pin(self, pin):
        self.pin = pin

    def to_dict(self):
        pass

    @classmethod
    def unique_name(cls, name):
        suffix = ''
        counter = 2
        name = name.rstrip('1234567890 ')
        while cls.query.filter_by(name=name+suffix).first():
            suffix = '%d' % counter
            counter += 1

        return name + suffix


def make_desc(context):
    print('*** create default desc', sys.stdout)
    print(context, sys.stdout)


class Game(db.Model):
    '''
    The heart of the database: an individual game record
    '''
    __tablename__ = 'game'
    game_id = db.Column(db.Integer, primary_key=True)
    description = db.Column(db.UnicodeText(), default=make_desc)
    json = db.Column(db.UnicodeText())
    log = db.Column(db.LargeBinary())
    public = db.Column(db.Boolean())
    started = db.Column(db.DateTime())
    last_updated = db.Column(db.DateTime(), default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = db.Column(db.Boolean())
    season_id = db.Column(
        'season_id',
        db.Integer,
        db.ForeignKey('season.season_id'),
        )
    season_index = db.Column(db.Integer)
    table = db.Column(db.UnicodeText())
    note = db.Column(db.UnicodeText())

    players = association_proxy('games_players', 'player')
    player_names = association_proxy('games_players', 'player.name')
    scores = association_proxy('games_players', 'score')
    places = association_proxy('games_players', 'place')

    def __str__(self):
        return ( 'id: ' + self.game_id
            + '\n desc: ' + self.description
            + '\n started: ' + str(self.started)
            + '\n last_updated: ' + str(self.last_updated)
            + '\n public: ' + str(self.public)
            + '\n is_active: ' + str(self.is_active)
            )

    def get_score_table(self):
        if self.json is None:
            return {}
        json = json_loads(self.json)
        if 'hands' in json and 'deltas' not in json['hands'][-1]:
            del json['hands'][-1]

        return json


#%% docs at http://docs.sqlalchemy.org/en/latest/orm/extensions/associationproxy.html

class PlayersGames(db.Model):
    ''' this maps players to games, and provides the score and placement '''
    __tablename = 'playersgames'
    player_id = db.Column('player_id', db.Integer, db.ForeignKey('player.player_id'), primary_key=True)
    game_id = db.Column('game_id', db.Integer, db.ForeignKey('game.game_id'), primary_key=True)
    score = db.Column(db.Integer)
    penalties = db.Column(db.Integer)
    place = db.Column(db.Integer)
    note = db.Column(db.UnicodeText())

    player = db.relationship(
        Player,
        backref=db.backref(
            'played_games',
            lazy='joined',
            cascade="all,delete-orphan",
        ),
    )

    game = db.relationship(
        Game,
        backref=db.backref(
            'games_players',
            lazy='dynamic',
            cascade="all, delete-orphan",
            collection_class=attribute_mapped_collection("place"),
        ),
    )

    def __init__(self, player=None, game=None, score=-9999, place=-1):
        self.player = player
        self.game = game
        self.score = score
        self.place = place


#%% Seasons = Leagues and Tournaments

class Season(db.Model):
    '''
    Stores start and end dates of each season
    '''
    __tablename__ = 'season'
    season_id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.UnicodeText(), nullable=False)
    start_date = db.Column(db.DateTime(), nullable=True)
    end_date = db.Column(db.DateTime(), nullable=True)
    ranking = db.Column(db.Float(), nullable=True)
    country = db.Column(db.String(2), nullable=True)
    note = db.Column(db.UnicodeText(), nullable=True)


class SeasonsPlayers(db.Model):
    '''
    Stores score for each player for each season
    '''
    __tablename__ = 'seasonsplayers'

    season_id = db.Column(
        db.Integer,
        db.ForeignKey('season.season_id'),
        nullable=False,
        primary_key=True)

    player_id = db.Column(
        db.Integer,
        db.ForeignKey('player.player_id'),
        nullable=False,
        primary_key=True)

    score = db.Column(db.Integer, default=0, nullable=True) # score x 10
    place = db.Column(db.Integer, nullable=True)
    note = db.Column(db.UnicodeText(), nullable=True)

    player = db.relationship(
        Player,
        backref=db.backref(
            'played_seasons',
            lazy='joined',
            cascade="all,delete-orphan",
        ),
    )

    season = db.relationship(
        Season,
        backref=db.backref(
            'seasons_players',
            lazy='dynamic',
            cascade="all, delete-orphan",
            collection_class=attribute_mapped_collection("place"),
        ),
    )

    def __init__(self, player=None, season_id=None, score=None, place=None, note=None):
        self.player = player
        self.season_id = season_id
        self.score = score
        self.place = place
        self.note = note

    def __str__(self):
        return ( 'id: ' + self.season_id
            + '\n player: ' + self.player_id
            + '\n started: ' + str(self.firstgame)
            + '\n score: ' + str(self.aggscore)
            )
