/// Select players for the next game
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

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
  List<String> playerNames = ['', '', '', ''];
  RULE_SET ruleSet;
  List<FocusNode> _focusNodes = [];
  List<TextEditingController> _controllers = [];

  @override
  void initState() {
    ruleSet = store.state.ruleSet == null
        ? RULE_SET.WRC2017
        : store.state.ruleSet.rules;
    playerNames = List.from(store.state.playerNames);
    super.initState();
    for (int i = 0; i < 4; i++) {
      _controllers.add(TextEditingController(text: playerNames[i]));
      _focusNodes.add(FocusNode());
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          _controllers[i].selection = TextSelection(
              baseOffset: 0, extentOffset: _controllers[i].text.length);
        } else {
          playerNames[i] = _controllers[i].text;
        }
      });
    }
    _focusNodes.add(FocusNode());
  }

  @override
  void dispose() {
    for (int i = 0; i < 4; i++) {
      _focusNodes[i].dispose();
      _controllers[i].dispose();
    }
    _focusNodes[4].dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _nameFields = [];

    void unfocusNodes() {
      for (int i = 0; i < 4; i++) {
        playerNames[i] = _controllers[i].text;
      }
      FocusScope.of(context).requestFocus(_focusNodes[4]);
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }

    for (int i = 0; i < 4; i++) {
      _nameFields.add(TextFormField(
        style: TextStyle(fontSize: 14),
        autofocus: i == 0,
        focusNode: _focusNodes[i],
        controller: _controllers[i],
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (String name) {
          _focusNodes[i].unfocus();
          playerNames[i] = name;
          FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
        },
        decoration: InputDecoration(
          icon: Icon(Icons.person),
          labelText: 'Player ' + (i + 1).toString(),
          hintText: 'press enter to save',
        ),
      ));
    }

    return Scaffold(
      appBar: MyAppBar("Who's playing?"),
      drawer: myDrawer(context),
      body: Form(
        child: ListView(
          addAutomaticKeepAlives: true,
          children: <Widget>[
            _nameFields[0],
            _nameFields[1],
            _nameFields[2],
            _nameFields[3],
            Padding(
              padding: EdgeInsets.all(2),
            ),
            Row(
              children: [
                BigButton(
                  text: 'EMA rules',
                  activated: ruleSet == RULE_SET.EMA2016,
                  onPressed: () => setState(() {
                        ruleSet = RULE_SET.EMA2016;
                      }),
                ),
                BigButton(
                  text: 'WRC rules',
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
                  text: 'Randomise seating and start',
                  onPressed: () {
                    unfocusNodes();
                    Scoring.randomiseAndStartGame(
                        context, playerNames, ruleSet);
                  },
                ),
                BigButton(
                  text: 'Keep this player order and start',
                  onPressed: () {
                    unfocusNodes();
                    Scoring.startGame(context, playerNames, ruleSet);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
