/// The ZAPS Mahjong Scorer, in Flutter
///
/// This file only assigns top-level routes and the store

// https://www.dartlang.org/guides/language/effective-dart/documentation#doc-comments

// core imports

//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// third-party imports
import 'package:flutter_redux/flutter_redux.dart';

//

// imports from this app
import 'fatalcrash.dart';
import 'gamedb.dart';
import 'gameflow.dart';
import 'games.dart';
import 'getplayer.dart';
import 'hands.dart';
import 'hanfu.dart';
import 'help.dart';
import 'io.dart';
import 'players.dart';
import 'settings.dart';
import 'scoresheet.dart';
import 'store.dart';
import 'utils.dart';
import 'welcome.dart';
import 'whodidit.dart';
import 'yaku.dart';

// TODO consider someday adding ability to take photo of winning Hands and attach to game https://flutter.dev/docs/cookbook/plugins/picture-using-camera
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.black, //top bar color
    statusBarIconBrightness: Brightness.light, //top bar icons
    systemNavigationBarColor: Colors.black, //bottom bar color
    systemNavigationBarIconBrightness: Brightness.light, //bottom bar icons
  ));

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) => initPrefs().then((_) {
            GLOBAL.playersListUpdated = !store.state.preferences['useServer'];
            GameDB db = GameDB();
            db.initDB().then((dynamic success) {
              if (success is bool && success) {
                db.listPlayers().then((_) {
                  db.updatePlayersFromServer(); // async IO, do NOT wait for it
                  db.setLastGame().then((_) => runApp(ScorerApp()));
                });
              } else {
                runApp(FatalCrash(success));
              }
            });
          }));
}

class ScorerApp extends StatelessWidget {
  // An appbar is created for each screen separately, and each screen has its
  // own scaffold, because when there was just one scaffold with shared appbar,
  // the menu would intermittently just vanish completely.
  // I never did track down whether that was a flutter bug, or my bug.
  // Anyway, this means that the TopBarNotifier isn't very stable, as it's not
  // assigned to a global context and scaffold.

  @override
  Widget build(BuildContext context) {
    return StoreProvider<GameState>(
      // Pass the store to the StoreProvider. Any ancestor `StoreConnector`
      // Widgets will find and use this value as the `Store`.
      store: store,
      child: StoreConnector<GameState, String>(
        converter: (store) => store.state.preferences['backgroundColour'],
        builder: (BuildContext context, String color) {
          return MaterialApp(
            initialRoute: ROUTES.hands,
            navigatorKey: USING_IO ? IO.httpLogger.getNavigatorKey() : null,
            title: "ZAPS Mahjong Scorer",
            theme: ThemeData(
              primaryColor: Colors.deepPurple[900],
              scaffoldBackgroundColor: BACKGROUND_COLOURS[color],
              brightness: Brightness.dark,
            ),
            routes: {
              ROUTES.hands: (context) => GamePage(),
              ROUTES.welcome: (context) => WelcomePage(),
              ROUTES.deadGames: (context) => GamesListPage(false),
              ROUTES.getPlayer: (context) => GetPlayer(),
              ROUTES.liveGames: (context) => GamesListPage(true),
              ROUTES.scoreSheet: (context) => ScoreSheetScreen(),
              ROUTES.hanFu: (context) => HanFuScreen(),
              ROUTES.help: (context) => HelpScreen(),
              ROUTES.selectPlayers: (context) => SelectPlayersScreen(),
              ROUTES.yaku: (context) => YakuScreen(),
              ROUTES.settings: (context) => SettingsScreen(),
              ROUTES.privacyPolicy: (context) =>
                  HelpScreen(page: ROUTES.privacyPolicy),
              ROUTES.helpSettings: (context) =>
                  HelpScreen(page: ROUTES.helpSettings),
              ROUTES.chombo: (context) => WhoDidItScreen(
                    minPlayersSelected: 1,
                    maxPlayersSelected: 4,
                    whenDone: Scoring.calculateChombo,
                    displayStrings: {
                      'on': 'Chombo!',
                      'off': '-',
                      'prompt': 'Who chomboed?',
                    },
                  ),
              ROUTES.draw: (context) => WhoDidItScreen(
                    minPlayersSelected: 0,
                    maxPlayersSelected: 4,
                    preSelected: store.state.inRiichi,
                    whenDone: Scoring.calculateDrawScores,
                    displayStrings: {
                      'on': 'tenpai',
                      'off': 'noten',
                      'prompt': 'Who is in tenpai?',
                    },
                  ),
              ROUTES.multipleRon: (context) => WhoDidItScreen(
                    disableButton: store.state.result['losers'],
                    minPlayersSelected: 2,
                    maxPlayersSelected: 3,
                    whenDone: Scoring.multipleRons,
                    displayStrings: {
                      'on': 'Won!',
                      'off': 'Bystander',
                      'prompt': 'Who called ron?',
                    },
                  ),
              ROUTES.pao: (context) => WhoDidItScreen(
                    disableButton: store.state.result['winners'] is List
                        ? store.state.result['winners'].last
                        : store.state.result['winners'],
                    minPlayersSelected: 1,
                    maxPlayersSelected: 1,
                    whenDone: Scoring.calculatePao,
                    displayStrings: {
                      'on': 'Guilty!',
                      'off': 'Guilty?',
                      'prompt': 'Who is responsible? ',
                    },
                  ),
            },
          );
        },
      ),
    );
  }
}
