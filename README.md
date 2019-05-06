# zaps_scorer

ZAPS Mahjong Scorer. Written in Flutter/Dart. Should work on Android & iPhone. (completely untested on iPhone)

## Files

- `main.dart` starts everything off.
- `welcome.dart` is the first screen the user sees when they first play the game.
- `players.dart` builds the form that asks for player names and the ruleset to be used.
- `hands.dart` builds the main game screen which is the interface for entering hands won.
- `scoresheet.dart` builds the scoresheet.
- `whodidit.dart` builds the screen which is used to identify players that are in a specific state: tempai at an exhaustive draw; chombo; pao; multiple ron.
- `hanfu.dart` builds the screen that offers the player a box for every possible score, from 1 han 30 fu to yakuman with pao.
- `yaku.dart` builds the alternative score screen (toggle-able from settings) which asks the user to enter the yaku which have been scored. It prevents mutually-incompatible yaku from being entered. As yet, the data from this isn't stored anywhere, only the score is.
- `games.dart` offers the player the lists of previous games to choose one to restore.
- `settings.dart` builds the settings screen.
- `help.dart` builds the help screen.
- `appbar.dart` builds the top menu bar.
- `gameflow.dart` handles the backend flow of a game.
- `gamedb.dart` handles the backend database operations.
- `io.dart` will handle the backend server communications, eventually.
- `store.dart` handles the backend storage of game state in memory.
- `utils.dart` provides various backend utility functions
- `yakuconstants.dart` provides a set of constants used by `yaku.dart` - it creates the order of buttons on that screen, the han for each yaku, whether a yaku can appear in an open hand, and whether it can only appear if the user riichi'd. It also contains a Map which sets out which yaku are incompatible with each other. 


### TODO

Networking stuff
