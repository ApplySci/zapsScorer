# ZAPS Riichi Mahjong Scorer

EMA & WRC rules. It should work on Android & iPhone.
(but is completely untested on iPhone)

***Pull requests will be very welcome.***

#### Updates
It's getting to the point where I'll be ready to submit to the Android
store for early access. 

### Dev notes

Written in [Flutter](https://flutter.dev/)/Dart.

I've been editing and building in Android Studio on Windows.
I assume it's portable and will build on other platforms too,
but that's all untested.
It's using the latest versions of dart, flutter, packages (at the
moment, I haven't needed to freeze any of the package versions: at
some point, any of the packages may need to be frozen if they introduce
breaking changes: this can be done in [pubspec.yaml](pubspec.yaml).

The **guiding principles** are:
- minimum user input is needed to do anything; data only needs to be
entered once, and the UI is designed so that the fewest taps possible
are required to enter data.
- the UI informs the players of the game's current state at a glance.
- the scoring should be reliably accurate: during testing, the app should
be used in partnership with tembo. After testing, it should be able to be
used *instead* of tembo. 
- data collection is robust, so partial game data is always saved and
available for restoration and resumption if the app crashes or is closed
mid-game;
- there's an auditable log of the actions that led to a particular score,
where 
- where possible, power consumption is minimised;

## Files
Many of the files in the repository are there just to make the build
work, and were auto-generated by Android Studio & Flutter. Below, I'm
only listing the main program files.

#### UI

- [main.dart](lib/main.dart) starts everything off.
- [welcome.dart](lib/welcome.dart) is the first screen the user sees when they first play the game.
- [players.dart](lib/players.dart) builds the form that asks for player names and the ruleset to be used.
- [hands.dart](lib/hands.dart) builds the main game screen which is the interface for entering hands won.
- [scoresheet.dart](lib/scoresheet.dart) builds the scoresheet.
- [whodidit.dart](lib/whodidit.dart) builds the screen which is used to identify players that are in a specific state: tempai at an exhaustive draw; chombo; pao; multiple ron.
- [hanfu.dart](lib/hanfu.dart) builds the screen that offers the player a box for every possible score, from 1 han 30 fu to yakuman with pao.
- [yaku.dart](lib/yaku.dart) builds the alternative score screen
(toggle-able from settings) which asks the user to enter the yaku 
which have been scored. It prevents mutually-incompatible yaku 
from being entered. As yet, the data from this isn't stored 
anywhere, only the score is.
- [games.dart](lib/games.dart) offers the player the lists of previous games to choose one to restore.
- [settings.dart](lib/settings.dart) builds the settings screen.
- [help.dart](lib/help.dart) builds the help screen.
- [appbar.dart](lib/appbar.dart) builds the top menu bar.

#### Backend

- [gameflow.dart](lib/gameflow.dart) handles the backend flow of a game.
- [gamedb.dart](lib/gamedb.dart) handles the backend database operations.
- [io.dart](lib/io.dart) will handle the backend server communications, eventually.
- [store.dart](lib/store.dart) handles the backend storage of game state in memory.
- [utils.dart](lib/utils.dart) provides various backend utility functions
- [yakuconstants.dart](lib/yakuconstants.dart) provides a set of
constants used by `yaku.dart` - it creates the order of buttons 
on that screen, the han for each yaku, whether a yaku can appear 
in an open hand, and whether it can only appear if the user riichi'd.
It also contains a Map which sets out which yaku are incompatible with
each other. 


## TODO

- Networking stuff: the intention at the moment is to use the [Pantheon
server software](https://github.com/MahjongPantheon/pantheon/).
- make the log more informative, adding all scoring events in.
