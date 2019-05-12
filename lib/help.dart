import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'appbar.dart';
import 'utils.dart';

/// Provides context-sensitive help
class HelpScreen extends StatelessWidget {
  /// The name of the page that help should be given for
  final String page;

  HelpScreen({this.page = ROUTES.help});

  @override
  Widget build(BuildContext context) {
    Widget helpText;

    switch (page) {
      case ROUTES.help:
        helpText = AutoSizeText(LONGTEXT.ronTsumoHelp);
        break;
      case ROUTES.helpSettings:
        helpText = Text('''Server-side stuff isn't active yet.         
'''); // TODO
        break;
    }

    return Scaffold(
      appBar: MyAppBar('Help is here'),
      body: DefaultTextStyle(
        style: TextStyle(
          fontSize: 35.0,
          color: Colors.yellow,
          decoration: null,
        ),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: helpText,
        ),
      ),
    );
  }
}
