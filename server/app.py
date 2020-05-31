# -*- coding: utf-8 -*-
'''
This boots up the whole server. It adds the current directory to the start of
the python path, to ensure all the imports work as expected. It's called
app.py to ensure that flask always picks it up correctly when run from the
command-line.
'''
import inspect
import os
import sys

# add directory of this file, to the start of the path,
# before importing any of the app

sys.path.insert(
    0,
    os.path.realpath(os.path.abspath(os.path.split(inspect.getfile(
        inspect.currentframe()))[0]))
    )

from mjserver import app as application, db

@application.shell_context_processor
def make_shell_context():
    from mjserver.models import User, Game, UsersGames
    return {'db': db, 'User': User, 'Game': Game, 'UsersGames': UsersGames}

if __name__ == "__main__":
    application.run(debug=True, threaded=True)