# -*- coding: utf-8 -*-
'''
maps server URIs to actions
'''

# core python imports

from glob import glob
import os
import queue
import time

# framework imports

from flask import flash, g, redirect, render_template, request, Response, url_for
from flask_emails import Message
from flask_httpauth import HTTPTokenAuth
from flask_login import login_user, logout_user, current_user, login_required, user_loaded_from_header, LoginManager
from werkzeug.urls import url_parse

# 3rt party imports

from itsdangerous import URLSafeTimedSerializer

# my app imports

from mjserver import app, db, BASE_DIR
from mjserver.errors import error_response
from mjserver.forms import EmailForm, LoginForm, PasswordForm, ProfileForm, RegistrationForm
from mjserver.models import Game, User, UsersGames, QUEUES

# initialisations

login_manager = LoginManager()
login_manager.init_app(app)

@user_loaded_from_header.connect
def user_loaded_from_header(self, user=None):
    g.login_via_header = True

@login_manager.request_loader
def load_user_from_request(request):
    # try to login using the api_key url arg
    api_key = request.args.get('api_key')
    if api_key:
        user = User.query.filter_by(api_key=api_key).first()
        if user:
            return user
    # finally, return None if failed to login
    return None

serializer = URLSafeTimedSerializer(app.config['SECRET_KEY'])
API = '/api/v0/'
token_auth = HTTPTokenAuth(scheme='Token')

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
    this_user.name = User.unique_name(this_user.name)
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


@app.route('/games')
def list_games():
    ''' list all games '''
    these_games = Game.query.order_by(Game.is_active.desc(), Game.last_updated.desc()).all()
    return render_template('gamelist.html', games=these_games)


@app.route('/games/<game_id>')
def view_game(game_id):
    ''' display info on a particular game '''
    this_game = Game.query.get(game_id)
    if this_game.public or current_user in this_game.players:
        return render_template(
            'game.html',
            game=this_game,
            details=this_game.get_score_table()
        )
    return error_response(404)


@app.route('/users/<user_id>', methods=['GET', 'POST'])
def view_profile(user_id):
    ''' display user profile page '''
    this_user = User.query.filter_by(user_id=user_id).first_or_404()
    form = ProfileForm(obj=this_user)
    if not form.validate_on_submit():
        return render_template('user.html', profiled=this_user, form=form)
    # TODO ?handle updated user profile?


def game_stream(q):
    waiting = True
    while waiting:
        time.sleep(5)
        waiting = False
        waiting2 = True
        # TODO test whether this loop break when the app is killed
        while waiting2:
            try:
                message = q.get(block=False)
                yield "data: {}\n\n".format(message)
            except queue.Empty:
                waiting = True
                waiting2 = False


@app.route('/live/<game_id>')
def view_live_game(game_id):
    this_game = Game.query.get(game_id)
    return render_template('live.html',
                           game=this_game,
                           details=this_game.get_score_table())


@app.route('/stream/<game_id>')
def stream_live_game(game_id):
    q = queue.Queue()
    if not game_id in QUEUES:
        QUEUES[game_id] = []
    QUEUES[game_id].append(q)
    return Response(game_stream(q), mimetype="text/event-stream")
