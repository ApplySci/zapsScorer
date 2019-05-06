/// Displays the settings screen, dispatches actions to the store as needed

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'appbar.dart';
import 'gamedb.dart';
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
        TextEditingController(text: store.state.preferences['apiUrl']);
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
          'apiUrl',
          'backgroundColour',
          'japaneseNumbers',
          'japaneseWinds',
          'namedYaku',
          'useServer',
        ];
        final Map storeValues = {'dispatch': store.dispatch};
        params.forEach((String param) =>
            storeValues[param] = store.state.preferences[param]);
        return storeValues;
      },
      builder: (BuildContext context, Map storeValues) {
        final List<Widget> rows = [];

        Row makeRow(String label, _SETTING type, String optionStore,
            {dynamic options}) {
          Widget control;

          switch (type) {
            case _SETTING.onOff:
              control = Switch(
                value: storeValues[optionStore] as bool,
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
              control = FlatButton(
                onPressed: options as Function,
                child: Text(optionStore),
              );
              break;
            case _SETTING.URL:
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
                    log(LOG.info, val);
                  }
                  storeValues['dispatch']({
                    'type': STORE.setPreferences,
                    'preferences': {optionStore: val},
                  });
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

          return Row(
            children: [
              Expanded(
                flex: 2,
                child: AutoSizeText(label),
              ),
              Expanded(
                flex: 2,
                child: control,
              )
            ],
          );
        }

        rows.add(makeRow(
          'Japanese-style negative numbers \n (▲ instead of -)',
          _SETTING.onOff,
          'japaneseNumbers',
        ));

        rows.add(makeRow(
          'Japanese winds \n (東南西北 instead of ESWN)',
          _SETTING.onOff,
          'japaneseWinds',
        ));

        rows.add(makeRow(
          'Ask names of yaku\n rather than just han count',
          _SETTING.onOff,
          'namedYaku',
        ));

        /*rows.add(makeRow(
          'PIN',
          _SETTING.digits,
          'PIN',
        ));*/

        rows.add(makeRow(
          'Background colour \n (needs restart)',
          _SETTING.multi,
          'backgroundColour',
          options: BACKGROUND_COLOURS,
        ));

        rows.add(makeRow(
          'Use server',
          _SETTING.onOff,
          'useServer',
        ));

        rows.add(makeRow(
          'Server URL',
          _SETTING.URL,
          'apiUrl',
        ));

        rows.add(Divider(height: 30));

        rows.add(makeRow('Delete database (will delete ALL stored games)',
            _SETTING.button, 'Delete', options: () async {
          bool reallyDelete = await yesNoDialog(context,
              prompt: 'Really delete the whole db?',
              trueText: 'Yes, destroy all the games',
              falseText: 'NO!');
          if (reallyDelete) {
            GameDB().deleteTables();
          }
        }));

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
/*
{'type': 'button',
'title': 'Open browser',
'section': 'main',
'buttons': [{'title': 'Create account', 'id': 'browser'}],
'desc': (
'Go to the website now to register as a new user, then come back here '
+ 'and register this device'
),
},
{'type': 'button',
'title': setting_text,
'section': 'main',
'buttons': [{'title': button_text, 'id': 'register_device'}],
'desc': desc_text,
'key': 'register'
},

*/