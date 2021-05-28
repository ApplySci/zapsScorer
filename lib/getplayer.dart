/// provide the user with a select box of players to assign to a game
/// players registered on device, but not on server, have id < 0
/// NB 0 is also a magic value for id: it indicates the default player placeholder

import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:pin_code_text_field/pin_code_text_field.dart';

import 'appbar.dart';
import 'gamedb.dart';
import 'io.dart';
import 'store.dart';
import 'utils.dart';

// TODO warn user if players db is still waiting to update from the network

class GetPlayer extends StatefulWidget {
  @override
  GetPlayerState createState() => GetPlayerState();
}

class GetPlayerState extends State<GetPlayer> {
  late Function callback;
  late int index;
  bool validateWithPassword = false;
  late List<Map<String, dynamic>> players;

  @override
  Widget build(BuildContext context) {
    // TODO add a refresh icon for user to get users from server?

    final dynamic args = ModalRoute.of(context)!.settings.arguments;
    if (args is Map) {
      callback = args['callback'];
      index = args['index'];
      players = args['players'];
      if (args.containsKey('password') && args['password']) {
        validateWithPassword = true;
      }
    }

    return Scaffold(
      //drawer: myDrawer(context),
      appBar: MyAppBar(GLOBAL.getTitle(context, 'Pick a player')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(5),
            child: AutoSizeText('Start typing to filter list of registered '
                'players, or to create a new player. '
                'Click blue icon to save new player, '
                'or tap on a registered player in the scrollable list below.'),
          ),
          Expanded(
            flex: 1,
            child: FindPlayer(
                callback: callback,
                index: index,
                players: players,
                validateWithPassword: validateWithPassword),
          ),
          Expanded(
            flex: 7,
            child: Container(),
          ),
          // make space for the dropdown
        ],
      ),
    );
  }
}

class FindPlayer extends StatefulWidget {
  final Function callback;
  final int index;
  final List<Map<String, dynamic>> players;
  final bool validateWithPassword;
  final bool allowCreateUser;
  final FindPlayerState state = FindPlayerState();

  FindPlayer(
      {required this.callback,
        required this.index,
        required this.players,
        required this.validateWithPassword,
      this.allowCreateUser = true});

  @override
  FindPlayerState createState() => state;
}

class FindPlayerState extends State<FindPlayer> {
  TextEditingController controller = TextEditingController();
  List<String> playerNames = [];
  List<Map<String, dynamic>> availablePlayers = [];
  late int priorSelection;
  double waiting = 0;
  final FocusNode focusNode = FocusNode();
  late TopBarNotifier topBar;

  @override
  void initState() {
    super.initState();

    topBar = TopBarNotifier();

    List<int> seenIDs = [];
    List<int> playerIDs = [];
    playerNames = [];
    priorSelection = widget.players[widget.index]['id'];
    int owner = store.state.preferences['userID'];
    int nextID;

    for (int i = 0; i < widget.players.length; i++) {
      nextID = widget.players[i]['id'];
      playerIDs.add(nextID);
      if (nextID <= GLOBAL.nextUnregisteredID) {
        GLOBAL.nextUnregisteredID = nextID - 1;
      }
    }

    GLOBAL.allPlayers.forEach((dynamic onePlayer) {
      int idToInsert = onePlayer['id'];
      int pos = playerIDs.indexOf(idToInsert);
      String nameToInsert = onePlayer['name'].toLowerCase();

      if (seenIDs.contains(idToInsert)) {
        // NOP
      } else if (pos == widget.index || (idToInsert == owner && pos == -1)) {
        // this is the player that is already selected, or that owns the device, so put them at the top
        availablePlayers.insert(0, onePlayer);
        playerNames.insert(0, nameToInsert);
        seenIDs.add(idToInsert);
      } else if (pos == -1) {
        // this player hasn't been selected yet, so add it to the list
        availablePlayers.add(onePlayer);
        playerNames.add(nameToInsert);
        seenIDs.add(idToInsert);
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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

  void createUser() async {
    // Create user PIN for new players.
    // Ask them to enter PIN twice, check they match,
    String errmsg = '';
    String? pin1 = '0000';
    String? pin2 = '';
    Map<String, dynamic> newUser;

    // ensure username is unique, locally
    int suffix = 1;
    String name = controller.text;
    while (GLOBAL.nameIsNotUnique(name)) {
      name = '${controller.text} ${suffix++}';
    }

    while (pin1 != pin2) {
      pin1 = await getPin(
        context,
        name,
        title: errmsg +
            "Create PIN for $name - use 0000 if security isn't an issue",
      );
      if (pin1 == null) {
        return;
      }
      pin2 = await getPin(context, name, title: 'Verify PIN for $name');
      if (pin2 == null) {
        return;
      }
      errmsg = 'PINs do not match! ';
    }

    Navigator.pop(context);
    topBar.show(context: context, message: 'OK!', color: Colors.green[900]!);
    newUser = await GameDB().addUser(
      {
        'id': (GLOBAL.nextUnregisteredID--).toString(),
        'name': name,
        'pin': pin1 ?? '',
      },
      updateServer: store.state.preferences['registerNewPlayers'],
    );

    GLOBAL.allPlayers.insert(0, newUser);
    widget.callback(newUser);
  }

  @override
  Widget build(BuildContext context) {
    TypeAheadField playerList = TypeAheadField(
      hideOnEmpty: true,
      hideSuggestionsOnKeyboardHide: false,
      getImmediateSuggestions: true,
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        autofocus: true,
        focusNode: focusNode,
        style: DefaultTextStyle.of(context)
            .style
            .copyWith(fontStyle: FontStyle.italic),
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          icon: GestureDetector(
            child: Icon(
              Icons.person_add,
              color: Colors.lightBlue,
            ),
            onTap: createUser,
          ),
        ),
      ),
      suggestionsCallback: getSuggestions,
      itemBuilder: (context, player) {
        return ListTile(
          title: Container(
            color: player['id'] == priorSelection ? Colors.greenAccent : null,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: player['id'] < 0
                      ? Container()
                      : Icon(
                          Icons.account_circle,
                          color: Colors.green,
                        ),
                ),
                Expanded(
                  flex: 9,
                  child: Text(
                    player['name'],
                    style: TextStyle(
                        color: player['id'] == priorSelection
                            ? Colors.black
                            : null),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      onSuggestionSelected: (result) async {
        if (result['id'] <= 0) {
          // user is registered on device but not on server, so don't ask for PIN, just accept them
          Navigator.pop(context);
          widget.callback(result);
          return;
        }

        Function getUserInput;
        Function verifyUserInput;

        if (widget.validateWithPassword) {
          getUserInput = getPassword;
          verifyUserInput = login;
        } else {
          getUserInput = getPin;
          verifyUserInput = IO().checkPin;
        }

        dynamic input = await getUserInput(context, result['name']);
        if (input == null) {
          // user has cancelled
          FocusScope.of(context).requestFocus(focusNode);
          return;
        }

        setState(() => waiting = 1);

        // TODO don't check pin if player is already validated
        Map checkResult = await verifyUserInput(result['id'], input);
        if (checkResult['ok']) {
          if (checkResult['body'] is Map &&
              checkResult['body'].containsKey('token')) {
            result['authToken'] = checkResult['body']['token'];
          }
          Navigator.pop(context);
          widget.callback(result);
          return;
        } else {
          setState(() => waiting = 0);
          FocusScope.of(context).requestFocus(focusNode);
          topBar.show(
            context: context,
            message:
                'wrong ' + (widget.validateWithPassword ? 'password' : 'pin'),
          );
        }
      },
    );

    return Stack(
      children: [
        Opacity(opacity: waiting, child: CircularProgressIndicator()),
        Opacity(opacity: 1 - waiting, child: playerList),
        topBar,
      ],
    );
  }
}

Future<String> getPassword(BuildContext context, String name) async {
  String password = '';
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        children: [
          Padding(
            child: Text('Please enter the Password for $name'),
            padding: EdgeInsets.only(
              left: 5,
              right: 5,
              bottom: 15,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 5,
              right: 5,
              bottom: 15,
              top: 15,
            ),
            child: TextFormField(
              // TODO test password checking
              autofocus: true,
              keyboardType: TextInputType.text,
              onFieldSubmitted: (String val) {
                password = val;
                Navigator.pop(context, val);
              },
            ),
          ),
        ],
      );
    },
  );
  return password;
}

Future<String?> getPin(BuildContext context, String name, {String? title}) async {
  String? pin;
  await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: [
            Padding(
              child: Text(title ?? 'Please enter the PIN for $name'),
              padding: EdgeInsets.only(
                left: 5,
                right: 5,
                bottom: 15,
              ),
            ),
            PinCodeTextField(
              autofocus: true,
              hideCharacter: true,
              highlight: true,
              highlightColor: Colors.blue,
              defaultBorderColor: Colors.black,
              hasTextBorderColor: Colors.green,
              maxLength: 4,
              hasError: false,
              maskCharacter: "*",
              onDone: (text) {
                pin = text;
                Navigator.pop(context, pin);
              },
              pinBoxOuterPadding: EdgeInsets.only(bottom:20, left: 5,),
              pinBoxDecoration:
                  ProvidedPinBoxDecoration.defaultPinBoxDecoration,
              pinBoxWidth: 60,
              pinTextStyle: TextStyle(fontSize: 30.0),
              wrapAlignment: WrapAlignment.start,
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                pin = null;
                Navigator.pop(context, null);
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
              )
            ),
          ],
        );
      });
  return pin;
}

Future<Map> login(int userID, String password) async {
  Map result = await IO().login(userID, password);
  return result;
}
