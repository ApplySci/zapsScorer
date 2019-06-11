/// Displays the settings screen, dispatches actions to the store as needed

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'appbar.dart';
import 'gamedb.dart';
import 'getplayer.dart';
import 'store.dart';
import 'utils.dart';

enum _SETTING { onOff, URL, button, digits, multi }

class SettingsScreen extends StatefulWidget {
  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _controller;

  @override
  void initState() {
    _controller =
        TextEditingController(text: store.state.preferences['serverUrl']);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<Game, Map>(
      converter: (store) {
        const List<String> params = [
          'serverUrl',
          'backgroundColour',
          'japaneseNumbers',
          'japaneseWinds',
          'namedYaku',
          'authToken',
          'userID',
          'username',
          'useServer',
        ];
        final Map storeValues = {'dispatch': store.dispatch};
        params.forEach((String param) =>
            storeValues[param] = store.state.preferences[param]);
        return storeValues;
      },
      builder: (BuildContext context, Map storeValues) {
        final List<Widget> rows = [];

        void makeRow(String label, _SETTING type, String optionStore,
            {dynamic options}) {
          Widget control;
          List<int> widthRatio = [3, 2];

          switch (type) {
            case _SETTING.onOff:
              widthRatio = [5, 2];
              control = Switch(
                value: (storeValues[optionStore] ?? false) as bool,
                onChanged: (val) {
                  storeValues[optionStore] = val;
                  storeValues['dispatch']({
                    'type': STORE.setPreferences,
                    'preferences': {optionStore: val},
                  });
                },
              );
              break;
            case _SETTING.digits:
              control = TextField(keyboardType: TextInputType.number);
              break;
            case _SETTING.button:
              widthRatio = [2, 2];
              control = FlatButton(
                onPressed: options,
                child: Text(
                  optionStore,
                  textAlign: TextAlign.right,
                ),
              );
              break;
            case _SETTING.URL:
              widthRatio = [1, 3];
              control = TextFormField(
                keyboardType: TextInputType.url,
                controller: _controller,
                decoration: InputDecoration(
                  labelText: DEFAULT_PREFERENCES[optionStore],
                  hintText: 'https://example.com',
                ),
                onFieldSubmitted: (String val) {
                  if (val.length == 0) {
                    val = DEFAULT_PREFERENCES[optionStore];
                    _controller.text = val;
                    Log.info(val);
                  }
                  storeValues['dispatch']({
                    'type': STORE.setPreferences,
                    'preferences': {optionStore: val},
                  });
                  options();
                },
              );
              break;
            case _SETTING.multi:
              final List<DropdownMenuItem<String>> items = [];
              String currentVal = options.keys.first;
              options.forEach((key, val) {
                if (storeValues[optionStore] == key) {
                  currentVal = key;
                }
                items.add(DropdownMenuItem(
                  value: key,
                  child: AutoSizeText(
                    key,
                    minFontSize: 8,
                  ),
                ));
              });

              control = DropdownButton<String>(
                items: items,
                isExpanded: true,
                value: currentVal,
                onChanged: (val) {
                  storeValues[optionStore] = val;
                  storeValues['dispatch']({
                    'type': STORE.setPreferences,
                    'preferences': {optionStore: val},
                  });
                },
              );
          }

          // add some vertical space, let each row breathe a bit
          rows.add(Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  flex: widthRatio[0],
                  child: AutoSizeText(label),
                ),
                Expanded(
                  flex: widthRatio[1],
                  child: Align(
                    child: control,
                    alignment: Alignment.centerRight,
                  ),
                )
              ],
            ),
          ));
        }

        makeRow(
          'Japanese-style negative numbers (▲ not -)',
          _SETTING.onOff,
          'japaneseNumbers',
        );

        makeRow(
          'Japanese winds (東南西北 not ESWN)',
          _SETTING.onOff,
          'japaneseWinds',
        );

        makeRow(
          'Ask names of yaku, not just han & fu',
          _SETTING.onOff,
          'namedYaku',
        );

        makeRow(
          'Background colour',
          _SETTING.multi,
          'backgroundColour',
          options: BACKGROUND_COLOURS,
        );

        makeRow(
          'Log of current game',
          _SETTING.button,
          'View',
          options: () => showLog(context),
        );

        rows.add(Divider(height: 30));

        makeRow(
          'Use server',
          _SETTING.onOff,
          'useServer',
        );

        if (storeValues['useServer']) {
          makeRow(
            'Server URL',
            _SETTING.URL,
            'serverUrl',
            options: () {
              // got new server, so get list of users in background
              GameDB().updatePlayersFromServer();
            },
          );

          makeRow(
            'Register new players on server',
            _SETTING.onOff,
            'registerNewPlayers',
          );

          makeRow(
            'Register device to a registered player',
            _SETTING.button,
            storeValues['authToken'] != null &&
                    storeValues['authToken'].length > 0
                ? ('registered to ' + storeValues['username'])
                : 'unregistered',
            options: () {
              getPlayer(
                context,
                index: 0,
                players: [
                  {'id': storeValues['userID'], 'name': storeValues['username']}
                ],
                callback: (dynamic player) {
                  // TODO catch case if player is not registered
                  // TODO call network to authenticate this user
                  store.dispatch({
                    'type': STORE.setPreferences,
                    'preferences': {
                      'userID': player['id'],
                      'username': player['name'],
                      'authToken': 'ok', // TODO use real auth token
                    }
                  });
                },
              );
            },
          );
        }

        rows.add(Divider(height: 30));

        makeRow('Delete database (will delete ALL stored games)',
            _SETTING.button, 'Delete', options: () async {
          bool reallyDelete = await GLOBAL.yesNoDialog(context,
              prompt: 'Really delete the whole db?',
              trueText: 'Yes, destroy all the games',
              falseText: 'NO!');
          if (reallyDelete != null && reallyDelete) {
            GameDB().rebuildDatabase();
          }
        });

/*
        makeRow('test', _SETTING.button, 'test', options: () async {
          debugPrint("test button currently not configured");
        });
*/

        return Scaffold(
          appBar: MyAppBar('Settings'),
          body: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: rows,
              padding: EdgeInsets.all(5.0),
              addAutomaticKeepAlives: true,
            ),
          ),
        );
      },
    );
  }
}

void showLog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Material(
        child: Column(
          children: [
            Expanded(
              flex: 12,
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: Log.logs.length,
                  itemBuilder: (context, index) {
                    LOG type =
                        enumFromString<LOG>(Log.logs[index][1], LOG.values);
                    TextStyle style = TextStyle(
                        color: type == LOG.error
                            ? Colors.red
                            : (type == LOG.unusual
                                ? Colors.yellow
                                : (type == LOG.score
                                    ? Colors.green
                                    : Colors.white)));
                    return Container(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: AutoSizeText(
                              Log.logs[index][0]
                                  .substring(0, 19)
                                  .replaceFirst('T', ' '),
                              style: style,
                            ),
                          ),
                          // timestamp
                          Expanded(
                            flex: 2,
                            child: AutoSizeText(
                              Log.logs[index][1],
                              style: style,
                            ),
                          ),
                          // log type
                          Expanded(
                            flex: 8,
                            child: AutoSizeText(
                              Log.logs[index][2],
                              style: style,
                            ),
                          ),
                          // log text
                        ],
                      ),
                    );
                  },
                  scrollDirection: Axis.vertical,
                  padding: EdgeInsets.all(5.0),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: RaisedButton(
                child: Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      );
    },
  );
}
