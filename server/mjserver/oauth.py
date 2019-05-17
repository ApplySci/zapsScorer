# -*- coding: utf-8 -*-
'''
not yet used, but starting configuring oauth2 logins as an easier way for
folk to join the site. The use of loginpass means that Affero GPL must be used.
'''
# built in imports

# framework imports

from authlib.flask.client import OAuth
from loginpass import create_flask_blueprint
from loginpass import ( Discord, Google,
    # Facebook, StackOverflow, GitHub, Slack,
    # Twitter, Reddit, Gitlab, Dropbox,
    # Bitbucket, Spotify, Strava
)

# app imports
from mjserver import app

#%% oauth stuff


OAUTH_BACKENDS = [ Discord, Google,
    # Twitter, Facebook, GitHub, Dropbox,
    # Reddit, Gitlab, Slack, StackOverflow,
    # Bitbucket, Strava, Spotify
]

@app.route('/hid/')
def oauth_login_list():
    tpl = '<li><a href="/{}/login">{}</a></li>'
    lis = [tpl.format(b.OAUTH_NAME, b.OAUTH_NAME) for b in OAUTH_BACKENDS]
    return '<ul>{}</ul>'.format(''.join(lis))

def handle_authorize(remote, token, user_info):
    # type(remote) == RemoteApp # str(token)
    return str(user_info)

oauth = OAuth(app)

for backend in OAUTH_BACKENDS:
    bp = create_flask_blueprint(backend, oauth, handle_authorize)
    app.register_blueprint(bp, url_prefix='/{}'.format(backend.OAUTH_NAME))
