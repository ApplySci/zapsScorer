import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/services.dart';

import 'package:auto_size_text/auto_size_text.dart';

import 'utils.dart';
//import 'package:pin_input_text_field/pin_input_text_field.dart';

getPlayer(
  BuildContext context, {
  Function callback,
  int index,
  List<Map<String, dynamic>> players,
}) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(5),
                child: AutoSizeText('Start typing to filter list of registered '
                    'players, or to create a new player. '
                    'Click blue icon to save new player, '
                    'or tap on a registered player in the scrollable list below.'),
              ),
            ),
            Expanded(
              flex: 1,
              child: FindPlayer(
                callback: callback,
                index: index,
                players: players,
              ),
            ),
            Expanded(
              flex: 7,
              child: Container(),
            ),
            // make space for the dropdown
          ]),
        );
      });
  return null;
}

class FindPlayer extends StatefulWidget {
  final Function callback;
  final int index;
  final List<Map<String, dynamic>> players;

  FindPlayer({this.callback, this.index, this.players});

  @override
  FindPlayerState createState() => FindPlayerState();
}

class FindPlayerState extends State<FindPlayer> {
  TextEditingController controller = TextEditingController();
  List<String> playerNames = [];
  List<Map<String, dynamic>> availablePlayers = [];
  int priorSelection;

  @override
  void initState() {
    super.initState();

    List<int> playerIDs = [];
    playerNames = [];
    priorSelection = widget.players[widget.index]['id'];

    for (int i = 0; i < widget.players.length; i++) {
      playerIDs.add(widget.players[i]['id']);
    }

    allPlayers.forEach((dynamic onePlayer) {

      int pos = playerIDs.indexOf(onePlayer['id']);
      String nameToInsert = onePlayer['name'].toLowerCase();

      if (pos == widget.index) {
        // this is the player that is already selected, so put them at the top
        availablePlayers.insert(0, onePlayer);
        playerNames.insert(0, nameToInsert);
      } else if (pos == -1) {
        // this player hasn't been selected yet, so add it to the list
        availablePlayers.add(onePlayer);
        playerNames.add(nameToInsert);
      }
      if (playerIDs[widget.index] == -1) {
        // only pre-fill the filter input field, if it's an unregistered player (id -1)
        // NB 0 is also a magic value for id: it indicates the default player placeholder
        controller.text = widget.players[widget.index]['name'];
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      }
    });
  }

  List<Map<String, dynamic>> getSuggestions(String pattern) {
    List<Map<String, dynamic>> filteredPlayers = [];
    String testPattern = pattern.toLowerCase();
    for (int i = 0; i < playerNames.length; i++) {
      if (playerNames[i].contains(testPattern)) {
        filteredPlayers.add(availablePlayers[i]);
      }
    }
    return filteredPlayers;
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField(
      hideOnEmpty: true,
      hideSuggestionsOnKeyboardHide: false,
      getImmediateSuggestions: true,
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        autofocus: true,
        style: DefaultTextStyle.of(context)
            .style
            .copyWith(fontStyle: FontStyle.italic),
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          icon: GestureDetector(
            child: Icon(Icons.person_add, color: Colors.lightBlue,),
            onTap: () {
              widget.callback(controller.text);
              Navigator.pop(context);
            },
          ),
        ),
      ),
      suggestionsCallback: getSuggestions,
      itemBuilder: (context, player) {
        return ListTile(
          title: Container(
            child: Text(player['name']),
            color: player['id'] == priorSelection ? Colors.green : null,
          ),
        );
      },
      onSuggestionSelected: (result) {
        Navigator.pop(context);
        widget.callback(result);
      },
    );
  }
}
