# ZAPS Riichi Mahjong Scorer

EMA & WRC rules. It should work on Android & iPhone.
(but is completely untested on iPhone)

***Pull requests will be very welcome.***

#### Updates
It's getting to the point where I'll be ready to submit to the Android
store for early access.

### Dev notes

Written in [Flutter](https://flutter.dev/)/Dart, with the server side in
Python.

I've been editing and building in Android Studio on Windows.
I assume it's portable and will build on other platforms too,
but that's all untested.
It's using the latest versions of dart, flutter, packages (at the
moment, I haven't needed to freeze any of the package versions: at
some point, any of the packages may need to be frozen if they introduce
breaking changes: this can be done in [pubspec.yaml](pubspec.yaml).

The **guiding principles** are:
- the UI informs the players of the game's current state at a glance;
- thoughtful UX design ensures that **minimum user input is needed** to
do anything; data only needs to be entered once, and the UI is designed
so that the fewest taps possible are required to enter data;
- the **scoring must be reliably accurate**: during testing, the app
should be used in partnership with tembo. After testing, it should be
able to be used *instead* of tembo;
- **data collection is robust**, so partial game data is always saved and
available for restoration and resumption if the app crashes or is closed
mid-game;
- there's **an auditable log** of the actions that led to a particular
score;
- where possible, **power consumption is minimised**;
- **works offline in the same way as when online**, and will sync to the
server next time it is online (networking not yet implemented).
- Gemma-pro has thought hard about apps for scoring, and has several wise
reservations about them. The more of those reservations we can address,
the better the app will be.
  - It has to be resilient to loss of server.
  - It has to be nigh on impossible to cheat.
  - It has to have some kind of verifiability for each player at the table.
  - There has to be some way to check if the app, or communications with the server, have been tampered with.

## Files
Many of the files in the repository are there just to make the build
work, and were auto-generated by Android Studio & Flutter. Below, I'm
only listing the main program files.

#### App UI

- [main.dart](lib/main.dart) starts everything off.
- [appbar.dart](lib/appbar.dart) builds the top menu bar.
- [fatalcrash.dart](lib/fatalcrash.dart) tries to salvage something if
the database gets corrupted (WIP)
- [games.dart](lib/games.dart) offers the player the lists of previous
games to choose one to restore.
- [getplayer.dart](lib/getplayer.dart) builds the UI to identify
registered players and authenticate them.
- [hands.dart](lib/hands.dart) builds the main game screen which is the
interface for entering hands won.
- [hanfu.dart](lib/hanfu.dart) builds the screen that offers the player
a box for every possible score, from 1 han 30 fu to yakuman with pao.
- [help.dart](lib/help.dart) builds the help screen.
- [players.dart](lib/players.dart) builds the form that asks for player
names and the ruleset to be used.
- [scoresheet.dart](lib/scoresheet.dart) builds the scoresheet.
draw; chombo; pao; multiple ron.
- [settings.dart](lib/settings.dart) builds the settings screen.
- [welcome.dart](lib/welcome.dart) is the first screen the user sees
when they first play the game.
- [whodidit.dart](lib/whodidit.dart) builds the screen which is used to
identify players that are in a specific state: tempai at an exhaustive
- [yaku.dart](lib/yaku.dart) builds the alternative score screen
(toggle-able from settings) which asks the user to enter the yaku
which have been scored. It prevents mutually-incompatible yaku
from being entered.

#### App Backend

- [gameflow.dart](lib/gameflow.dart) handles the backend flow of a game.
- [gamedb.dart](lib/gamedb.dart) handles the backend database operations.
- [io.dart](lib/io.dart) handles the backend server communications.
- [store.dart](lib/store.dart) handles the backend storage of game state
in memory.
- [utils.dart](lib/utils.dart) provides various backend utility functions
- [yakuconstants.dart](lib/yakuconstants.dart) provides a set of
constants used by `yaku.dart` - it creates the order of buttons
on that screen, the han for each yaku, whether a yaku can appear
in an open hand, and whether it can only appear if the user riichi'd.
It also contains a Map which sets out which yaku are incompatible with
each other.

#### Server (website & backend)

Python 3.7+ ; wsgi ; flask ; sqlalchemy

- [\_\_init\_\_.py](server/mjserver/__init__.py)
- [api.py](server/mjserver/api.py) the functions for the API
- [app.py](server/app.py)
- [config.template.py](server/mjserver/config.template.py) - copy this to config.py and add your own passwords
- [errors.py](server/mjserver/errors.py) http error-page functions
- [forms.py](server/mjserver/forms.py) the forms for web pages
- [initdb.py](server/initdb.py) creates a dummy database to work with
- [models.py](server/mjserver/models.py) create and manage the database structure
- [oauth.py](server/mjserver/oauth.py) - not currently used
- [routes.py](server/mjserver/routes.py) the functions to make web-pages

Third-party packages required (pip install ...):

- alembic sqlalchemy flask flask_login flask_wtf flask_emails flask-moment flask_httpauth flask_sqlalchemy flask_migrate wtforms itsdangerous authlib loginpass werkzeug email_validator blinker

## TODO

- get the OBS overlay updating properly
- user-testing
- enable pantheon API?

## Recent changes
