/// Manages the user-selection of the score of the current hand
///
/// Note that "points" are used to refer to the points as normally understood in
/// riichi, e.g. a mangan is 8000 points.
/// whereas "score" always refers to hundreds of points, so a mangan is a score of 80.

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'appbar.dart';
import 'gameflow.dart';
import 'store.dart';
import 'utils.dart';

class HanFuButton extends StatelessWidget {
  final Map buttonDetails;
  final bool manganAt430;
  final Function callback;

  HanFuButton({this.buttonDetails, this.manganAt430, this.callback});

  @override
  Widget build(BuildContext context) {
    final int points =
        buttonDetails.containsKey('points') ? buttonDetails['points'] : null;
    // suppress the 4x30 (points=1920) button if manganAt430
    return buttonDetails.containsKey('text') && !(points == 1920 && manganAt430)
        ? RaisedButton(
            onPressed: () {
              if (points != null) {
                callback(points);
              }
            },
            child: AutoSizeText(
              buttonDetails['text'],
              textAlign: TextAlign.center,
              maxLines: 3,
              minFontSize: 10,
            ),
            padding: const EdgeInsets.all(3.0),
          )
        : Container();
  }
}

class HanFuScreen extends StatefulWidget {
  @override
  HanFuScreenState createState() => HanFuScreenState();
}

class HanFuScreenState extends State<HanFuScreen> {
  String title = "What's the score?";

  static const List<Map> hanFuButtons = [
    {'text': '1-30', 'points': 240},
    {'text': '2-30, 1-60', 'points': 480},
    {'text': '3-30, 2-60', 'points': 960},
    {'text': '4-30, 3-60', 'points': 1920},
    {'text': '1-40', 'points': 320},
    {'text': '2-40, 1-80', 'points': 640},
    {'text': '3-40, 2-80', 'points': 1280},
    {'text': 'Mangan', 'points': 2000},
    {'text': '1-50, 2-25', 'points': 400},
    {'text': '2-50, 3-25, 1-100', 'points': 800},
    {'text': '3-50, 4-25, 2-100', 'points': 1600},
    {'text': 'Haneman', 'points': 3000},
    {'text': '1-70', 'points': 560},
    {'text': '2-70', 'points': 1120},
    {},
    {'text': 'Baiman', 'points': 4000},
    {'text': '1-90', 'points': 720},
    {'text': '2-90', 'points': 1440},
    {},
    {'text': 'Sanbaiman', 'points': 6000},
    {'text': '1-110', 'points': 880},
    {'text': '2-110', 'points': 1760},
    {'text': 'Yakuman with Pao', 'points': PAO_FLAG},
    {'text': 'Yakuman', 'points': 8000},
  ];

  @override
  Widget build(BuildContext context) {
    String newTitle = getTitle(context, null);
    title = (newTitle == null) ? title : newTitle;
    return Scaffold(
      drawer: myDrawer(context),
      appBar: MyAppBar(title),
      body: DefaultTextStyle(
        style: TextStyle(
          fontSize: 35.0,
          color: Colors.yellow,
          decoration: null,
        ),
        child: StoreConnector<Game, Map>(
          converter: (store) => {
                'manganAt430': store.state.ruleSet.manganAt430,
                'callback': Scoring.onScoreSelected,
              },
          builder: (context, storeMap) {
            return GridView.count(
              children: List.generate(
                hanFuButtons.length,
                (int index) => HanFuButton(
                      buttonDetails: hanFuButtons[index],
                      manganAt430: storeMap['manganAt430'],
                      callback: (int points) =>
                          storeMap['callback'](context, points),
                    ),
              ),
              crossAxisCount: 4,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
            );
          },
        ),
      ),
    );
  }
}
