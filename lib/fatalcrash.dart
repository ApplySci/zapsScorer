import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'gamedb.dart';
import 'store.dart';

class FatalCrash extends StatelessWidget {
  // TODO failed to open db

  final Map crashDetails;

  FatalCrash(this.crashDetails);

  @override
  Widget build(BuildContext context) {
    // TODO check if registered, and whether we have an email address for user
    return AlertDialog(
      title: Text('Oh dearie me'),
      content: SingleChildScrollView(
          child: Text('Fatal error, failed to open local database correctly. '
              'If this is the first time that this has happened, '
              'try restarting your database.'
              'If this has happened before, you can delete the database and'
              'start with a clean database. The existing database will be sent'
              'to the server, and we will try to repair it.')),
      actions: <Widget>[
        RaisedButton(
          child: Text('Exit app'),
          onPressed: () {
            SystemNavigator.pop();
          },
        ),
        RaisedButton(
          onPressed: () {
            GameDB().sendDBToServer();
          },
          child: Text('Send db to server for fixing' +
              (store.state.preferences['useServer']
                  ? ''
                  : ': preferences are currently set to NOT use server'
                      '- pressing this button will override that.')),
        ),
        RaisedButton(
          onPressed: () {},
          child: Text('Debugging: show the crash log'),
        )
      ],
    );
  }
}
