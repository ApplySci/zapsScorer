/// provides a context-specific app bar and drawer

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'gameflow.dart';
import 'io.dart';
import 'store.dart';
import 'utils.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;

  MyAppBar([this.title]);

  @override
  Size get preferredSize => new Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final String routeName = GLOBAL.currentRouteName(context);
    final List<Widget> actions = [];

    // don't show help button on help pages or welcome page;
    if (![ROUTES.help, ROUTES.helpSettings, ROUTES.welcome]
        .contains(routeName)) {
      actions.add(IconButton(
        icon: new Icon(Icons.help),
        onPressed: () {
          String nextRoute = ROUTES.help;
          switch (routeName) {
            case ROUTES.settings:
              nextRoute = ROUTES.helpSettings;
              break;
          }
          Navigator.pushNamed(context, nextRoute);
        },
      ));
    }

    return AppBar(
      primary: true,
      title: AutoSizeText(title ?? 'Riichi scorer', maxLines: 2),
      actions: actions,
    );
  }
}

Drawer myDrawer(BuildContext context) {
  bool gameInProgress = store.state.inProgress;
  TextStyle deactivatedText = TextStyle(color: Colors.grey[500]);
  dynamic inProgressStyle = gameInProgress ? null : deactivatedText;

  List<Widget> listTiles = <Widget>[
    /*DrawerHeader(
      decoration: BoxDecoration(
        color: Colors.blue,
      ),
      margin: EdgeInsets.all(1),
      padding:EdgeInsets.all(1),
      child: Text(''),
    ),*/
    ListTile(
      title: Text('Chombo', style: inProgressStyle),
      onTap: gameInProgress
          ? (() {
              Navigator.popAndPushNamed(context, ROUTES.chombo);
            })
          : null,
    ),
    ListTile(
      title: Text('Undo last hand', style: inProgressStyle),
      onTap: gameInProgress
          ? (() {
              Navigator.pop(context);
              Scoring.maybeUndoLastHand(context);
            })
          : null,
    ),
    ListTile(
      title: Text('Finish this game', style: inProgressStyle),
      onTap: gameInProgress
          ? (() {
              Navigator.pop(context);
              Scoring.askToFinishGame(context);
            })
          : null,
    ),
    ListTile(
      title: Text('Resume an ongoing saved game'),
      onTap: () {
        Navigator.popAndPushNamed(context, ROUTES.liveGames);
      },
    ),
    ListTile(
        title: Text('View scoresheet of a finished game'),
        onTap: () {
          Navigator.popAndPushNamed(context, ROUTES.deadGames);
        }),
    ListTile(
      title: Text('New game'),
      onTap: (() async {
        Navigator.pop(context);
        if (gameInProgress) {
          bool? reallyFinish = await GLOBAL.yesNoDialog(context,
              prompt:
                  'Really shelve this game now (it can be continued later) and start a new one?',
              trueText: 'Yes, shelve it and start a new game',
              falseText: 'No, carry on playing this game');
          if (reallyFinish == true) {
            Scoring.deleteIfEmpty(context);
            Navigator.pushNamedAndRemoveUntil(context, ROUTES.selectPlayers,
                ModalRoute.withName(ROUTES.hands));
          }
          return;
        }
        Navigator.pushNamed(context, ROUTES.selectPlayers);
      }),
    ),
    ListTile(
      title: Text('Settings'),
      trailing: Icon(Icons.settings),
      onTap: () {
        Navigator.popAndPushNamed(context, ROUTES.settings);
      },
    ),
    ListTile(
      title: Text('Privacy policy'),
      trailing: Icon(Icons.lock_outline),
      onTap: () =>
          Navigator.popAndPushNamed(context, ROUTES.privacyPolicy),
    ),
    ListTile(
      title: Text('Exit app'),
      onTap: () async {
        Navigator.pop(context);
        bool? reallyQuit = await GLOBAL.yesNoDialog(
          context,
          prompt: 'Really quit?',
          trueText: 'Yes, really quit',
          falseText: "No, don't quit",
        );
        if (reallyQuit == true) {
          SystemNavigator.pop();
        }
      },
    ),
  ];

  if (USING_IO) {
    listTiles.add(ListTile(
      title: Text('show network log'),
      trailing: Icon(Icons.network_wifi),
      onTap: () => IO.httpLogger.showInspector(),
    ));
  }

  return Drawer(
    child: ListView(
      children: listTiles,
    ),
  );
}
