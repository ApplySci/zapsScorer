//

import 'package:flutter/material.dart';
//import 'package:auto_size_text/auto_size_text.dart';

import 'appbar.dart';
import 'gamedb.dart';
import 'store.dart';
import 'utils.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> lastGame = GameDB().lastGame;
    if (lastGame != null) {
      return SimpleDialog(
        // TODO split this out into appbar.dart file, and add options to restore other games
        title: Text('Resume this game: ' + lastGame['summary']),
        children: <Widget>[
          Divider(height: 20),
          SimpleDialogOption(
            onPressed: () {
              store.dispatch(
                  {'type': STORE.restoreFromJSON, 'json': lastGame['json']});
              Navigator.popAndPushNamed(context, ROUTES.hands);
            },
            child: Text('Yes'),
          ),
          Divider(height: 20),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pushNamed(context, ROUTES.selectPlayers);
            },
            child: Text('No, start a new game'),
          ),
          Divider(height: 20),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pushNamed(context, ROUTES.liveGames);
            },
            child: Text('View the list of other ongoing games'),
          ),
          Divider(height: 20),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pushNamed(context, ROUTES.deadGames);
            },
            child: Text('View the list of completed games'),
          ),
        ],
      );
    }
    return Scaffold(
      drawer: myDrawer(context),
      appBar: MyAppBar('Welcome!'),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Text(
              'Hello!',
              style: TextStyle(fontSize: 30),
            ),
          ),
          Expanded(
            flex: 8,
            child: Stack(children: [
              Align(alignment: Alignment.bottomRight, child: Icon(Icons.arrow_downward)),
              SingleChildScrollView(
                  child: Text(
                LONGTEXT.ronTsumoHelp,
                style: TextStyle(fontSize: 18),
              )),
            ]),
          ),
          Expanded(
            flex: 1,
            child: SizedBox(
              width: 200,
              height: 50,
              child: RaisedButton(
                child: Text(
                  "Let's play",
                  style: TextStyle(fontSize: 30),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, ROUTES.selectPlayers);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
