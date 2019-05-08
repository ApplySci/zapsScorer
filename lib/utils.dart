// utility functions, enums and constants used across the app

import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';

void unassigned() {}

String enumToString(Object o) {
  return o.toString().split('.').last;
}

T enumFromString<T>(String key, List<T> values) {
  return values.firstWhere((v) => key == enumToString(v), orElse: () => null);
}

const int PAO_FLAG = 8888;

enum SCORE_DISPLAY {
  adjustments,
  chombo,
  chomboScore,
  deltas,
  finalDeltas,
  inProgress,
  netScores,
  oka,
  plainDeltas,
  plainTotals,
  textDeltas,
  totals,
  uma,
  startingPoints,
}

enum LOG { debug, info, score, unusual, warn, error }
enum RULE_SET { EMA2016, WRC2017 }
enum RESULT { tsumo, ron, draw, multiple_ron, chombo, none }

enum STORE {
  accumulateScores,
  addRow,
  addDelta,
  awardRiichiSticks,
  endOfGame,
  endOfHand,
  endGame,
  initGame,
  initHand,
  initPreferences,
  eastIsWinner,
  nextDealership,
  playerNames,
  popWinner,
  recordYakuStats,
  redealHand,
  resetRiichi,
  restoreFromJSON,
  setHanFuCallback,
  setPaoLiable,
  setPreferences,
  setResult,
  setRiichi,
  setRules,
  setUma,
  showDeltas,
  undoLastHand,
  unsetRotateWindsTo,
}

const String DEFAULT_COLOUR_KEY = 'Black Knight';

const Map<String, Color> BACKGROUND_COLOURS = {
  DEFAULT_COLOUR_KEY: Colors.black,
  'Fireball red': Color(0xFF330000),
  'Deep Purple': Color(0xFF220022),
};

class LONGTEXT {
  static const String ronTsumoHelp =
      '''Single-tap on a riichi stick to go into riichi.
   
Indicate scoring events by dragging tembo from one player to another, or from the centre box (representing the table as a whole, to a player.) When you press on the score of the player that will make the payment, and start dragging, a bunch of tembo sticks appear under your finger. Drag them to the player receiving the payment, and a white box will appear around that player's position. Now lift your finger off the screen. 
  
RON: drag from the player who discarded to the player who called ron.
  
MULTIPLE RON: (not applicable under WRC rules), drag from the player who discarded, to the centre box (i.e. a payment from the discarding player to the table as a whole).

TSUMO: drag from the centre box to the player who called tsumo. (so it's like a payment from "the table" to the winning player)

Press the DRAW button in the top-right to indicate an exhaustive draw.
  
Other actions (chombo, undo last hand, finish game early, restore saved game, and so on), are available from the menu in the top left corner.

(end)''';

  static const String privacy = '''Privacy policy
      
  If you provide your email address, we use it to notify you of significant site changes that affect your account.
  All the games that you associate with your account on the app, we associate with your account on our server, if you have the 'use server' setting switched on.
  By using the server, you agree to share the data on games you play, with the people you play against.
  You can download all your data on our server, or delete your account, by logging into the website.''';
}

class ROUTES {
  static const String chombo = '/chombo';
  static const String deadGames = '/games/dead';
  static const String draw = '/draw';
  static const String hands = '/';
  static const String hanFu = '/hanfu';
  static const String help = '/help';
  static const String helpSettings = '/helpSettings';
  static const String liveGames = '/games/live';
  static const String multipleRon = '/multipleRon';
  static const String pao = '/pao';
  static const String selectPlayers = '/selectPlayers';
  static const String settings = '/settings';
  static const String scoreSheet = '/scoresheet';
  static const String welcome = '/welcome';
  static const String whoDidIt = '/whodidit';
  static const String yaku = '/yaku';
}

const Map<String, String> WINDS = {
  'western': 'ESWN',
  'japanese': '東南西北',
};

/// assigns the chosen rule set to the Store
class Rules {
  RULE_SET rules = RULE_SET.WRC2017;

  bool chomboAfterUma = true;
  int chomboValue = -200;
  bool manganAt430 = true;
  bool multipleRons = false;
  int oka = 0; // ignored, as neither of the implemented rule sets use it
  bool riichiAbandonedAtEnd = true;
  int startingPoints = 300;
  List<int> uma = [150, 50, -50, -150];

  Rules([this.rules = RULE_SET.WRC2017]) {
    if (rules == RULE_SET.EMA2016) {
      riichiAbandonedAtEnd = false;
      multipleRons = true;
      manganAt430 = false;
    }
  }
}

String currentRouteName(BuildContext context) {
  String routeName;

  Navigator.popUntil(context, (route) {
    routeName = route.settings.name;
    return true;
  });

  return routeName;
}

/// Multi-purpose yes/no modal dialog
///
/// Asks the user a question in [prompt],
/// shows [trueText] on a button that returns true, and
/// [falseText] on the button that returns false.
/// Returns a [Future] that yields the user response true/false
///
/// example use:
/// ```
/// bool saidYes = yesNoDialog(
///   context,
///   prompt: 'Really draw?',
///   trueText: 'Hellyeah',
///   falseText: 'Nonononono',
/// );
/// if (saidYes) handleDraw();
/// ```
Future<bool> yesNoDialog(BuildContext context,
    {String prompt, String trueText, String falseText}) async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text(prompt),
        children: <Widget>[
          Divider(height: 20),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text(trueText),
          ),
          Divider(height: 20),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(falseText),
          ),
        ],
      );
    },
  );
}

/// Prettifies a score to one of a small number of fixed formats
dynamic scoreFormat(score, SCORE_DISPLAY kind, {bool japaneseNumbers = false}) {
  final bool scoreIsString = score is String;

  switch (kind) {
    case SCORE_DISPLAY.inProgress:
      return null;

    case SCORE_DISPLAY.chombo:
      String out;
      if (scoreIsString) {
        out = score;
      } else if (score == 0) {
        out = '';
      } else {
        out = '⊗';
      }
      return TextSpan(
          text: out,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ));

    case SCORE_DISPLAY.plainTotals:
      if (score > 0) {
        return score.toString();
      }

      return (japaneseNumbers ? '▲' : '-') + (-score).toString();

    case SCORE_DISPLAY.plainDeltas:
      if (scoreIsString) {
        return score;
      }

      if (score == 0) {
        return '';
      }

      if (score > 0) {
        return '+' + score.toString() + '00';
      }

      return (japaneseNumbers ? '▲' : '-') + (-score).toString() + '00';

    case SCORE_DISPLAY.netScores:
    case SCORE_DISPLAY.deltas:
      if (scoreIsString) {
        return TextSpan(
            text: score,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ));
      }

      if (score == 0) {
        return TextSpan(
            text: '.', style: TextStyle(color: Colors.grey, fontSize: 6));
      }

      if (score > 0) {
        return TextSpan(
          children: [
            TextSpan(text: '+' + score.toString()),
            TextSpan(
              text: '00',
              style: TextStyle(fontSize: 6),
            ),
          ],
          style: TextStyle(color: Colors.lightGreen),
        );
      }

      return TextSpan(
        children: [
          TextSpan(text: (japaneseNumbers ? '▲' : '-') + (-score).toString()),
          TextSpan(
            text: '00',
            style: TextStyle(fontSize: 6),
          ),
        ],
        style: TextStyle(color: Colors.redAccent),
      );

    case SCORE_DISPLAY.textDeltas:
      if (score == 0) {
        return '0';
      }
      final String textScore = (score.abs() / 10.0).toStringAsFixed(1);
      if (score > 0) {
        return '+' + textScore;
      }
      return (japaneseNumbers ? '▲' : '-') + textScore;

    case SCORE_DISPLAY.chomboScore:
    case SCORE_DISPLAY.oka:
    case SCORE_DISPLAY.uma:
    case SCORE_DISPLAY.adjustments:
    case SCORE_DISPLAY.finalDeltas:
      if (scoreIsString) {
        return TextSpan(
          text: score,
          style: TextStyle(
            color: Colors.blue,
          ),
        );
      }

      if (score == 0) {
        return TextSpan(
          text: '0',
          style: TextStyle(
            color: Colors.grey,
          ),
        );
      }

      final String textScore = (score.abs() / 10.0).toStringAsFixed(1);

      if (score > 0) {
        return TextSpan(
          text: '+' + textScore,
          style: TextStyle(color: Colors.lightGreen),
        );
      }

      return TextSpan(
        children: [
          TextSpan(text: (japaneseNumbers ? '▲' : '-') + textScore),
        ],
        style: TextStyle(color: Colors.redAccent),
      );

    case SCORE_DISPLAY.startingPoints:
    case SCORE_DISPLAY.totals:
      if (scoreIsString)
        return TextSpan(
          text: score,
          style: TextStyle(
            color: Colors.blue,
          ),
        );

      if (score == 0) {
        return TextSpan(
          text: '0',
          style: TextStyle(fontWeight: FontWeight.bold),
        );
      }

      if (score > 0) {
        return TextSpan(
          children: [
            TextSpan(text: score.toString()),
            TextSpan(
              text: '00',
              style: TextStyle(fontSize: 6),
            ),
          ],
          style:
              TextStyle(color: Colors.lightGreen, fontWeight: FontWeight.bold),
        );
      }

      return TextSpan(
        children: [
          TextSpan(text: (japaneseNumbers ? '▲' : '-') + (-score).toString()),
          TextSpan(
            text: '00',
            style: TextStyle(fontSize: 6),
          ),
        ],
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      );
  }
  return TextSpan(text: 'scoreFormat error');
}

class ScoreRow {
  int dealership;
  int handRedeals;
  int honbaSticks;
  int riichiSticks;
  int roundWind;
  List<int> scores = List(4);
  SCORE_DISPLAY type;
  List<List<int>> yaku;

  ScoreRow({
    this.dealership = -1,
    this.handRedeals = -1,
    this.honbaSticks = -1,
    this.riichiSticks = -1,
    this.roundWind = -1,
    this.scores,
    this.type,
    this.yaku,
  });

  Map<String, dynamic> toMap() {
    return {
      'dealership': dealership,
      'handRedeals': handRedeals,
      'honbaSticks': honbaSticks,
      'riichiSticks': riichiSticks,
      'roundWind': roundWind,
      'scores': scores,
      'type': enumToString(type),
      'yaku': yaku,
    };
  }

  static ScoreRow fromMap(row, String version) {
    ScoreRow out = ScoreRow(
      dealership: row['dealership'],
      handRedeals: row['handRedeals'],
      honbaSticks: row['honbaSticks'],
      riichiSticks: row['riichiSticks'],
      roundWind: row['roundWind'],
      type: enumFromString<SCORE_DISPLAY>(row['type'], SCORE_DISPLAY.values),
      yaku: <List<int>>[],
    );
    if (row['yaku'] is List && row['yaku'].length > 0) {
      List<List>.from(row['yaku']).forEach((List row) =>
          row.length == 0 ? null : out.yaku.add(List<int>.from(row)));
    }
    if (row['scores'] != null) {
      out.scores = List<int>.from(row['scores'], growable: false);
    }
    return out;
  }
}

class BigButton extends StatefulWidget {
  final String text;
  final Function onPressed;
  final bool activated;

  BigButton({
    this.text,
    this.onPressed,
    this.activated = false,
  });

  @override
  BigButtonState createState() => BigButtonState();
}

class BigButtonState extends State<BigButton> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: EdgeInsets.all(5),
        child: SizedBox(
          height: 30,
          child: RaisedButton(
            onPressed: widget.onPressed,
            color: widget.activated ? Colors.green[800] : null,
            child: AutoSizeText(
              (widget.activated ? '✓ ' : '') + widget.text,
              maxLines: 2,
            ),
          ),
        ),
      ),
    );
  }
}

String getTitle(BuildContext context, String title) {
  final dynamic args = ModalRoute.of(context).settings.arguments;
  return args != null && args.containsKey('headline')
      ? args['headline']
      : title;
}

Future<bool> confirmUndoLastHand(BuildContext context) async {
  return yesNoDialog(context,
      prompt: 'Really undo last hand?',
      trueText: 'Yes, undo it',
      falseText: 'No, keep it');
}

void gotoHands(BuildContext context, {Map<String, dynamic> args}) {
  try {
    Navigator.popUntil(context, (route) => route.settings.name == ROUTES.hands);
  } catch (e) {
    if (currentRouteName(context) != ROUTES.hands) {
      Navigator.pushNamed(context, ROUTES.hands, arguments: args);
    }
  }
}
