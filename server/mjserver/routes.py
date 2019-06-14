# -*- coding: utf-8 -*-
'''
maps server URIs to actions
'''

# core python imports

from datetime import datetime
from glob import glob
import json
import os
import time

# framework imports

from flask import flash, jsonify, redirect, render_template, request, url_for
from flask_emails import Message
from flask_httpauth import HTTPTokenAuth
from flask_login import login_user, logout_user, current_user, login_required
from werkzeug.urls import url_parse

# 3rt party imports

from itsdangerous import URLSafeTimedSerializer

# my app imports

from mjserver import app, db, BASE_DIR
from mjserver.errors import bad_request, error_response
from mjserver.forms import EmailForm, LoginForm, PasswordForm, ProfileForm, RegistrationForm
from mjserver.models import Game, User, UsersGames

# initialisations

serializer = URLSafeTimedSerializer(app.config['SECRET_KEY'])
API = '/api/v0/'
token_auth = HTTPTokenAuth(scheme='Token')
    
#%% --- API calls

@app.route(API + 'login', methods=['POST'])
def api_login():
    data = request.get_json() or {}
    try:
        user = User.query.filter_by(name=data['name']).first()
        if user.active and user.check_password(data['password']):
            login_user(user)
            response = jsonify({'id': user.user_id, 'token': user.token})
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


@app.route(API + 'games/<game_id>', methods=['POST', 'PUT'])
@token_auth.login_required
def api_save_game(game_id):
    # TODO needs testing
    import pickle
    with open('/home/model/apps/proxyport/htdocs/gamesave.pickle', 'wb') as f:
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

        this_game.is_active = data['live'] == 'true'
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

        db.session.commit()

        for idx in range(4):
            got_player = False
            if new_game:
                player_dict = jsondata['players'][idx]
                if player_dict['id'] >= 0:
                    player = User.query.get(player_dict['id'])
                    got_player = player is not None
            else:
                if idx < len(players_in_game):
                    player = players_in_game[idx]
                    got_player = True                    

            if not got_player:
                player = User()
                serial = 1
                testname = player_dict['name']
                # name must be unique, so add a unique serial number if 
                #   needed, eg Andrew 2, Andrew 3, Andrew 4
                while User.query.filter_by(name=testname).first() is not None: 
                    serial += 1
                    testname = player_dict['name'] + ' %d' % serial
                player.name = testname
                db.session.add(player)
                db.session.commit()

            jsondata['players'][idx]['id'] = player.user_id
            jsondata['players'][idx]['name'] = player.name

            usersgames = UsersGames.query.get((player.user_id, this_game.game_id))

            if usersgames is None:
                usersgames = UsersGames()
                usersgames.player = player
                usersgames.game = this_game

                db.session.add(usersgames)

            usersgames.score = scores[idx]
            usersgames.place = places[idx]

            db.session.commit()

        # we may have changed the players to sync with db
        this_game.json = json.dumps(jsondata)
        db.session.commit()
        response = jsonify({
            'id': this_game.game_id,
            'players': jsondata['players'],
            'last_updated': this_game.last_updated,
        })
        response.status_code = 201

    except Exception as err:
        db.session.rollback()
        response = str(err), 400
        raise err

    return response


@token_auth.verify_token
def api_verify_token(token):
    
    # TODO remove after testing
    if token == 'ok': 
        login_user(User.query.get(0))
        return True
    # end of block to be removed after testing
    
    # find a user attached to this token if we can
    test = User.check_token(token) if token else None

    if test is not None and test.active:
        login_user(test)
        return True
    return False


@app.route(API + 'check-pin', methods=['POST'])
@token_auth.login_required
def api_verify_pin():
    data = request.get_json() or {}
    try:
        user = User.query.get(data['id'])
        if str(user.pin) == data['pin']:
            if user.is_active:
                return ('', 204)
            return ('user deactivated', 403)
        return ('Wrong PIN', 403)
    except:
        pass

    return ('Failed to find user in db', 403)


@token_auth.error_handler
def api_token_auth_error():
    return error_response(401)


@app.route(API + 'users', methods=['GET'])
def api_list_users():
    return jsonify(User.get_all_names(request.if_modified_since).all())


@app.route(API + 'users/new', methods=['GET', 'POST', 'PUT'])
@token_auth.login_required
def api_create_user():
    data = request.get_json() or {}

    if 'name' not in data :
        return bad_request('must include name')

    suffix = ''
    counter = 2
    while User.query.filter_by(name=data['name']+suffix).first():
        suffix = '%d' % counter
        counter += 1
        
    user = User()
    user.from_dict(data, new_user=True)
    db.session.add(user)
    db.session.commit()

    response = jsonify(user.to_dict())
    response.status_code = 201
    response.headers['token'] = user.get_token()
    return response


#@app.route(API + 'users/<int:id>', methods=['PUT'])
#def json_update_user(id):
#    pass


@app.route(API, methods=['HEAD', 'GET'])
@token_auth.login_required
def api_ping():
    return ('OK', 200)


#%% --- web pages

@app.route('/confirm/<token>')
def confirm_email(token):
    try:
        email = serializer.loads(token, salt="email-confirm-key", max_age=86400)
    except:
        return error_response(404)

    user = User.query.filter_by(email=email).first_or_404()
    user.email_confirmed = True
    db.session.commit()
    return redirect(url_for('signin'))


@app.route('/download-my-details')
@login_required
def dump_my_data():
    '''
    provide GDPR-compliant data dump of a user's data
    TODO consider asking for password again before giving this
    '''
    return current_user.gdpr_dump()


@app.route('/login', methods=['GET', 'POST'])
def login():
    ''' handle website logins '''
    if current_user.is_authenticated:
        return redirect(url_for('front_page'))
    form = LoginForm()

    if not form.validate_on_submit():
        return render_template('login.html', title='Sign In', form=form)


    this_user = User.query.filter_by(name=form.name.data).first()
    if this_user is None \
            or not this_user.check_password(form.password.data) \
            or not this_user.active:
        flash('Invalid name or password')
        return redirect(url_for('login'))
    login_user(this_user, remember=form.remember_me.data)
    next_page = request.args.get('next')
    if not next_page or url_parse(next_page).netloc != '':
        next_page = url_for('front_page')
    return redirect(next_page)


@app.route('/logout')
def logout():
    ''' log current user out '''
    logout_user()
    return redirect(url_for('front_page'))


@app.route('/')
def front_page():
    '''
    serve the site front page, which is currently the only place that the
    mobile app can be downloaded from. So we dynamically see which
    version of the app is most recent, extract the version number from the
    filename, and offer that to the browser.
    '''
    test_dir = BASE_DIR / 'static'
    files = glob(str(test_dir / '*.apk'))
    try:
        newest = files[0][1+len(str(test_dir)):]
        version = newest.split('-')[1]
        filetime = time.strftime('%Y-%m-%d %H:%M', time.gmtime(os.path.getmtime(files[0])))
    except:
        newest = 'None available currently'
        version = '?'
        filetime = '?'

    return render_template(
        'front_page.html',
        version=version,
        filetime=filetime,
        newest=newest,
        user=current_user)


@app.route('/privacy')
def privacy():
    ''' display site privacy policy '''
    return render_template('privacy.html')


@app.route('/register', methods=['GET', 'POST'])
def register():
    ''' register a new user '''
    if current_user.is_authenticated:
        return redirect(url_for('front_page'))
    form = RegistrationForm()
    if not form.validate_on_submit():
        return render_template('register.html', title='Register', form=form)

    this_user = User()
    form.populate_obj(this_user)
    this_user.set_password(form.password.data)
    this_user.set_pin(form.pin.data)
    this_user.create_token()
    db.session.add(this_user)
    db.session.commit()
    flash('Congratulations, you are now a registered user, you are now logged in!')
    login_user(this_user)

    confirm_url = url_for(
        'confirm_email',
        token=serializer.dumps(this_user.email, salt='email-confirm-key'),
        _external=True)

    req = Message(
        html=render_template('email_activate.html', url=confirm_url),
        subject='Confirm your email for the ZAPS Mahjong Scorer',
        mail_from='webmaster@mahjong.bacchant.es',
        mail_to=this_user.email,
        ).send()

    if req.status_code not in [250, ]:
        pass # TODO message is not sent, deal with this

    return redirect(url_for('view_profile', user_id=this_user.user_id))


@app.route('/reset', methods=["GET", "POST"])
def reset_password():
    form = EmailForm()
    if not form.validate_on_submit():
        return render_template('reset.html', form=form)

    user = User.query.filter_by(email=form.email.data).first()
    if user is not None:
        recover_url = url_for(
            'reset_with_token',
            token=serializer.dumps(user.email, salt='recover-key'),
            _external=True)

        msg = Message(
            html=render_template('email_password_reset.html', url=recover_url),
            subject='Password reset requested',
            mail_from='webmaster@mahjong.bacchant.es',
            mail_to=user.email,
            )

        req = msg.send()

        if req.status_code not in [250, ]:
            pass # TODO message is not sent, deal with this

    flash('If that email is attached to an account, a password reset link has been sent to it')
    return redirect(url_for('front_page'))


@app.route('/reset/<token>', methods=["GET", "POST"])
def reset_with_token(token):
    try:
        email = serializer.loads(token, salt="recover-key", max_age=86400)
    except:
        return error_response(404)

    form = PasswordForm()

    if not form.validate_on_submit():
        return render_template('reset_with_token.html', form=form, token=token)

    user = User.query.filter_by(email=email).first_or_404()
    user.set_password(form.password.data)
    db.session.commit()
    return redirect(url_for('login'))


@app.route('/games/<game_id>')
def view_game(game_id):
    ''' display info on a particular game '''
    this_game = Game.query.get(game_id)
    if this_game.public or current_user in this_game.players:
        return render_template(
            'game.html',
            profiled=this_game,
            details=this_game.get_score_table()
        )
    return error_response(404)


@app.route('/users/<user_id>', methods=['GET', 'POST'])
def view_profile(user_id):
    ''' display user profile page '''
    this_user = User.query.filter_by(id=user_id).first_or_404()
    form = ProfileForm(obj=this_user)
    if not form.validate_on_submit():
        return render_template('user.html', profiled=this_user, form=form)
    # TODO ?handle updated user profile?
