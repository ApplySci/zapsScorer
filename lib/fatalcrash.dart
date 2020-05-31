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
    // bool haveRegistrationDetails = false;
    String warningString = '';
    String authToken =store.state.preferences['authToken'];

    if (!store.state.preferences['useServer']) {
      warningString = ': preferences are currently set to NOT use server '
          '- pressing this button will override that.';
      if (authToken == null || authToken.length == 0) {
        warningString += ' ';
      }
    }

    return MaterialApp(
      initialRoute: 'crash-home',
      routes: {
        'crash-home': (context) {
          return SimpleDialog(
            title: Text('Fatal database error'),
            children: <Widget>[
              SingleChildScrollView(
                  child: Padding(
                      padding: EdgeInsets.only(
                        left: 5,
                        right: 5,
                      ),
                      child: Text('Failed to open local database correctly. '
                          'If this is the first time that this has happened, '
                          'try restarting your database. '
                          'If this has happened before, you can delete the database and '
                          'start with a clean database. The existing database can be sent '
                          'to the server, where we will try to repair it. (UNTESTED)'))),
              SimpleDialogOption(
                child: Text('Exit app'),
                onPressed: () {
                  SystemNavigator.pop();
                },
              ),
              SimpleDialogOption(
                onPressed: () {
                  GameDB().sendDBToServer();
                },
                child: Text('Send db to server for fixing' + warningString),
              ),
              SimpleDialogOption(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext innerContext) {
                        return SimpleDialog(
                          title: Text('Crash log'),
                          children: <Widget>[
                            SingleChildScrollView(
                                child: Padding(
                                    padding: EdgeInsets.only(
                                      left: 5,
                                      right: 5,
                                    ),
                                    child: Text(
                                        crashDetails['exception'].toString()))),
                            SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.all(5),
                                child: Text(crashDetails['stack'].toString()),
                              ),
                            ),
                          ],
                        );
                      });
                },
                child: Text('Debugging: show the crash log'),
              )
            ],
          );
        },
      },
    );
  }
}
