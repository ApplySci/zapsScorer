# -*- coding: utf-8 -*-
'''
maps server URIs to actions
'''

# TODO Add an API call to get list of users that a device can be registered to - i.e. devices with a password

# core python imports

from datetime import datetime
import json

# framework imports

from flask import g, jsonify, request
from flask.sessions import SecureCookieSessionInterface
#from flask_emails import Message
from flask_httpauth import HTTPTokenAuth
from flask_login import login_user, current_user, user_loaded_from_header, LoginManager

from jinja2 import pass_eval_context
from markupsafe import Markup

# 3rt party imports

from itsdangerous import URLSafeTimedSerializer

# my app imports

from mjserver import app, db
from mjserver.errors import bad_request, error_response
from mjserver.models import Game, Player, PlayersGames, QUEUES

# initialisations

class CustomSessionInterface(SecureCookieSessionInterface):
    """Prevent creating session from API requests."""
    def save_session(self, *args, **kwargs):
        if g.get('login_via_header'):
            return
        return super(CustomSessionInterface, self).save_session(*args, **kwargs)

"""
def some_alternative_login_code_that_has_been_disabled_for_now():
    login_manager = LoginManager()
    app.session_interface = CustomSessionInterface()
    login_manager.init_app(app)


    @user_loaded_from_header.connect
    def user_loaded_from_header(self, user=None):
        g.login_via_header = True


    @login_manager.request_loader
    def load_user_from_request(request_in):
        # try to login using the api_key url arg
        api_key = request_in.args.get('api_key')
        if api_key:
            user = Player.query.filter_by(api_key=api_key).first()
            if user:
                return user
        # finally, return None if failed to login
        return None
"""

def jsonconverter(o):
    #if isinstance(o, datetime.datetime):
    return o.__str__()


serializer = URLSafeTimedSerializer(app.config['SECRET_KEY'])
API = '/api/v0/'
token_auth = HTTPTokenAuth(scheme='Token')

#%% ---

@app.route(API + 'login', methods=['POST'])
def api_login():
    try:
        data = request.values
        player_id = int(data['id'])
        if player_id <= 0:
            return ('Invalid ID'), 403
        user = Player.query.get(player_id)
        if user.active and user.check_password(data['password']):
            login_user(user)
            response = jsonify({'token': user.get_token(), 'ok': 1})
            response.status_code = 200
            return response

        msg = 'Invalid name/password combination'
    except Exception as err:
        msg = str(err)

    response = jsonify({'message': msg})
    response.status_code = 403
    return response


@app.route(API + 'games', methods=['GET', 'POST'])
@token_auth.login_required
def api_list_games():
    list_with_descriptions = []
    for game in current_user.games:
        if game.is_active:
            list_with_descriptions.append(
                [game.game_id, game.description, game.json, game.last_updated]
            )
    response = jsonify(list_with_descriptions)
    response.status_code = 200
    return response


@app.route(API + 'games/<game_id>', methods=['GET'])
@token_auth.login_required
def api_get_game(game_id):
    try:
        game = Game.query.get(game_id)
        response = jsonify(game)
        response.status_code = 200
        return response
    except Exception as err:
        response = str(err), 400
        raise err


@app.route(API + 'users/<player_id>/pin', methods=['POST'])
@token_auth.login_required
def api_verify_pin(player_id):
    if int(player_id) <= -1 and int(player_id) >= -4:
        return('ok', 200)

    data = request.values or {}
    try:
        user = Player.query.get(player_id)
        if str(user.pin) == data['pin']:
            if user.is_active:
                return (user.get_token(), 200)
            return ('user deactivated', 403)
        return ('Wrong PIN', 403)
    except Exception:
        pass

    return ('Failed to find user in db', 403)


@app.route(API + 'games/<game_id>', methods=['POST', 'PUT'])
@token_auth.login_required
def api_save_game(game_id):
    # TODO needs testing
    import pickle
    with open('gamesave.pickle', 'wb') as f:
        pickle.dump(request.values, f)

    data = request.values or {}
    if 'summary' not in data or 'json' not in data or 'live' not in data or 'lastUpdated' not in data:
        return bad_request('must include summary, json, live and lastUpdated fields')

    jsondata = json.loads(data['json'])
    this_game = Game.query.get(game_id)
    new_game = this_game is None
    if new_game:
        this_game = Game()
        this_game.game_id = game_id

    try:
        this_game.description = data['summary']
        this_game.started = datetime.fromtimestamp(int(game_id[0:10]))
        this_game.public = False
        this_game.log = pickle.dumps(jsondata['log'])
        this_game.last_updated = datetime.fromtimestamp(int(data['lastUpdated'][0:10]))

        this_game.league = jsondata['league'] if 'league' in jsondata else None

        this_game.is_active = jsondata['inProgress'] == 1
        if this_game.is_active:
            places = [0, 0, 0, 0]
            scores = jsondata['scores']
        else:
            scores = jsondata['final_score']['finaleDeltas']
            places = jsondata['final_score']['places']

        if new_game:
            db.session.add(this_game)
        else:
            players_in_game = this_game.players.copy()

        for idx in range(4):
            got_player = False
            player_dict = jsondata['players'][idx]
            if new_game:
                if player_dict['id'] is not None and player_dict['id'] >= 0:
                    player = Player.query.get(player_dict['id'])
                    got_player = player is not None
            else:
                if idx < len(players_in_game):
                    player = players_in_game[idx]
                    got_player = True

            if not got_player:
                player = Player()
                player.name =  Player.unique_name(player_dict['name'])
                db.session.add(player)
                db.session.commit()

            jsondata['players'][idx]['id'] = player.player_id
            jsondata['players'][idx]['name'] = player.name

            # TODO needs special handling if player_id == 0,
            #      as player_id must be unique in each game
            usersgames = PlayersGames.query.get((player.player_id, this_game.game_id))

            if usersgames is None:
                usersgames = PlayersGames()
                usersgames.player = player
                usersgames.game = this_game
                db.session.add(usersgames)

            usersgames.score = scores[idx]
            usersgames.place = places[idx]


        # we may have changed the players to sync with db
        this_game.json = json.dumps(jsondata, default=jsonconverter)
        db.session.commit()

        update = {
            'id': this_game.game_id,
            'players': jsondata['players'],
            'last_updated': this_game.last_updated,
        }
        response = jsonify(update)

        for idx in range(4):
            if 'pin' in update['players'][idx]:
                del update['players'][idx]['pin']

        update = {**update,
            'scores': scores,
            'places': places,
            'scoresheet': jsondata['scoreSheet'],
            'started': this_game.started,
            };

        (QUEUES['put'])(this_game.game_id, json.dumps(update, default=jsonconverter));

        response.status_code = 201

    except Exception as err:
        db.session.rollback()
        response = str(err), 400
        raise err

    return response


@app.route(API + 'doraIndicator', methods=['PUT'])
@token_auth.login_required
def api_dora():
    data = request.values

    (QUEUES['put'])(data['game_id'], json.dumps(
        {'indicator': data['indicator'],
         'hand': data['hand'],
         },
        default=jsonconverter))

    return ('ok', 200)


@token_auth.verify_token
def api_verify_token(token):

    # find a user attached to this token if we can
    test = Player.check_token(token) if token else None

    if test is not None and test.active:
        login_user(test)
        return True

    return False


@token_auth.error_handler
def api_token_auth_error():
    return error_response(401)


@app.route(API + 'players', methods=['GET'])
@token_auth.login_required
def api_list_players():
    names = Player.get_all_names(request.if_modified_since)
    return jsonify(names.all())


@app.route(API + 'users/new', methods=['GET', 'POST', 'PUT'])
@token_auth.login_required
def api_create_user():
    data = request.values

    if 'name' not in data:
        return bad_request('must include name')

    user = Player()
    user.name = Player.unique_name(data['name'])
    user.pin = data['pin'] if 'pin' in data else '0000'
    db.session.add(user)
    db.session.commit()

    response = jsonify({
            'id': user.player_id,
            'name': user.name,
            'token': user.get_token(),
            })
    response.status_code = 201
    return response


@app.route(API + 'users/<int:player_id>', methods=['PUT', 'PATCH'])
@token_auth.login_required
def json_update_user(id):
    pass


@app.route(API, methods=['HEAD', 'GET'])
@token_auth.login_required
def api_ping():
    return ('OK', 200)

@app.after_request
def apply_caching(response):
    response.headers["zaps"] = 1
    return response

def format_datetime(value, format="%a %d %b %Y %H:%M"):
    """Format a date time to (format=Default): DoW dd mmm YYYY HH:MM"""
    # https://docs.python.org/2/library/datetime.html#strftime-strptime-behavior
    if value is None:
        return ""
    return value.strftime(format)

# Register the template filter with the Jinja Environment
app.jinja_env.filters['formatdatetime'] = format_datetime

@pass_eval_context
def format_finalscore(ctx, value, el="td"):
    out = '<' + el + ' class=delta'
    if value == 0:
        out += 'zero>0'
    elif value > 0:
        out += 'positive>+' + '{0:.1f}'.format(value/10)
    else:
        out += 'negative>' + '{0:.1f}'.format(value/10)

    out += '</' + el + '>'

    return Markup(out) if ctx.autoescape else out

app.jinja_env.filters['formatfinalscore'] = format_finalscore

@pass_eval_context
def format_delta(ctx, value, el="td"):

    out = '<' + el + ' class=delta'
    if value == 0:
        out += 'zero>0'
    elif value > 0:
        out += 'positive>+' + '{0:,}'.format(value*100)
    else:
        out += 'negative>' + '{0:,}'.format(value*100)

    out += '</' + el + '>'

    return Markup(out) if ctx.autoescape else out

app.jinja_env.filters['formatdelta'] = format_delta
