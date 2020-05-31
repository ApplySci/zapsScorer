/// Select players for the next game
import 'package:flutter/material.dart';

import 'package:reorderables/reorderables.dart';

import 'appbar.dart';
import 'gameflow.dart';
import 'store.dart';
import 'utils.dart';

class SelectPlayersScreen extends StatefulWidget {
  SelectPlayersScreen();

  @override
  SelectPlayersScreenState createState() => SelectPlayersScreenState();
}

class SelectPlayersScreenState extends State<SelectPlayersScreen> {
  List<Map<String, dynamic>> players;
  RULE_SET ruleSet;

  @override
  void initState() {
    ruleSet = store.state.ruleSet == null
        ? RULE_SET.EMA2016
        : store.state.ruleSet.rules;
    players = store.state.players.toList(growable: true);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      Map<String, dynamic> player = players.removeAt(oldIndex);
      players.insert(newIndex, player);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _nameFields = [];

    for (int i = 0; i < 4; i++) {
      _nameFields.add(ListTile(
        key: ValueKey(i),
        title: GestureDetector(
          onTap: () =>
              Navigator.of(context).pushNamed(ROUTES.getPlayer, arguments: {
            'callback': (Map player) =>
                setState(() => players[i] = Map<String, dynamic>.from(player)),
            'index': i,
            'players': players,
          }),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: players[i]['id'] != null && players[i]['id'] > 0
                    ? Icon(Icons.account_circle, color: Colors.green)
                    : Container(),
              ),
              Expanded(
                flex: 10,
                child: Text(players[i]['name']),
              ),
              Expanded(
                flex: 1,
                child: Icon(Icons.drag_handle),
              ),
            ],
          ),
        ),
      ));
    }

    return Scaffold(
      appBar: MyAppBar("Who's playing?"),
      drawer: myDrawer(context),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(5),
            child: Text(
                'Tap on a name to change a player. Long-press and drag to reorder players.'),
          ),
          ReorderableColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _nameFields,
            onReorder: _onReorder,
          ),
          Padding(
            padding: EdgeInsets.all(2),
          ),
          Row(
            children: [
              BigButton(
                text: ' EMA rules',
                activated: ruleSet == RULE_SET.EMA2016,
                onPressed: () => setState(() {
                  ruleSet = RULE_SET.EMA2016;
                }),
              ),
              BigButton(
                text: ' WRC rules',
                activated: ruleSet == RULE_SET.WRC2017,
                onPressed: () => setState(() {
                  ruleSet = RULE_SET.WRC2017;
                }),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(2),
          ),
          Row(
            children: <Widget>[
              BigButton(
                text: ' Randomise seating and start',
                onPressed: () {
                  Scoring.randomiseAndStartGame(context, players, ruleSet);
                },
              ),
              BigButton(
                text: ' Keep this player order and start',
                onPressed: () => Scoring.startGame(context, players, ruleSet),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
