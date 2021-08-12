// utility functions, enums and constants used across the app
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:another_flushbar/flushbar.dart';

void unassigned() {}

String enumToString<T>(T o) {
  return o.toString().split('.').last;
}

T enumFromString<T>(String key, List<T> values) {
  return values.firstWhere((v) => key == enumToString(v));
}

const int PAO_FLAG = 8888;

enum SCORE_STRING {
  deltas,
  totals,
  finalDeltas,
}

enum SCORE_TEXT_SPAN {
  adjustments,
  chombo,
  chomboScore,
  deltas,
  finalDeltas,
  inProgress,
  names,
  netScores,
  oka,
  places,
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
  players,
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
}

const String DEFAULT_COLOUR_KEY = 'black knight';

const Map<String, Color> BACKGROUND_COLOURS = {
  DEFAULT_COLOUR_KEY: Colors.black,
  'fireball red': Color(0xFF330000),
  'deep purple': Color(0xFF220033),
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
''';

  static const String privacy = '''Privacy policy
      
  If you provide your email address, we use it to notify you of significant site changes that affect your account.
  All the games that you associate with your account on the app, we associate with your account on our server, if you have the 'use server' setting switched on.
  By using the server, you agree to share the data on games you play, with the people you play against.
  You can download all your data on our server, or delete your account, by logging into the website.
  We don't collect any data other than that which you enter into the app.
  Game data is stored on the phone. If you don't use the server, it's not stored anywhere else. ''';
}

class ROUTES {
  static const String chombo = '/chombo';
  static const String deadGames = '/games/dead';
  static const String draw = '/draw';
  static const String getPlayer = '/getPlayer';
  static const String hands = '/';
  static const String hanFu = '/hanfu';
  static const String help = '/help';
  static const String helpSettings = '/helpSettings';
  static const String liveGames = '/games/live';
  static const String multipleRon = '/multipleRon';
  static const String pao = '/pao';
  static const String privacyPolicy = '/privacyPolicy';
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
  RULE_SET rules = RULE_SET.EMA2016;

  bool chomboAfterUma = true;
  int chomboValue = -200;
  bool manganAt430 = false;
  bool multipleRons = true;
  int oka = 0; // ignored, as neither of the implemented rule sets use it
  bool riichiAbandonedAtEnd = false;
  int startingPoints = 300;
  List<int> uma = [150, 50, -50, -150];

  Rules([this.rules = RULE_SET.EMA2016]) {
    if (rules == RULE_SET.WRC2017) {
      riichiAbandonedAtEnd = true;
      multipleRons = false;
      manganAt430 = true;
    }
  }
}

class ScoreRow {
  int dealership;
  int handRedeals;
  int honbaSticks;
  int riichiSticks;
  int roundWind;
  List<int>? scores = List.filled(4, 0);
  SCORE_TEXT_SPAN type;
  List<List<int>>? yaku;

  ScoreRow({
    this.dealership = -1,
    this.handRedeals = -1,
    this.honbaSticks = -1,
    this.riichiSticks = -1,
    this.roundWind = -1,
    this.scores,
    required this.type,
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

  static ScoreRow fromMap(row, String? version) {
    ScoreRow out = ScoreRow(
      dealership: row['dealership'],
      handRedeals: row['handRedeals'],
      honbaSticks: row['honbaSticks'],
      riichiSticks: row['riichiSticks'],
      roundWind: row['roundWind'],
      type:
          enumFromString<SCORE_TEXT_SPAN>(row['type'], SCORE_TEXT_SPAN.values),
      yaku: <List<int>>[],
    );
    if (row['yaku'] is List && row['yaku'].length > 0) {
      List<List>.from(row['yaku']).forEach((List row) =>
          row.length == 0 ? null : out.yaku!.add(List<int>.from(row)));
    }
    if (row['scores'] != null) {
      out.scores = List<int>.from(row['scores'], growable: false);
    }
    return out;
  }
}

class BigButton extends StatefulWidget {
  final String text;
  final void Function()? onPressed;
  final bool activated;

  BigButton({
    required this.text,
    required this.onPressed,
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
          height: 40,
          child: ElevatedButton(
            onPressed: widget.onPressed,
            child: AutoSizeText(
              (widget.activated ? '✓ ' : '') + widget.text,
              maxLines: 2,
            ),
            style: ElevatedButton.styleFrom(primary:widget.activated ? Colors.green[800] : null),
          ),
        ),
      ),
    );
  }
}

class GLOBAL {
  static bool nameIsNotUnique(String name) {
    for (Map<String, dynamic> player in allPlayers) {
      if (player['name'] == name) {
        return true;
      }
    }
    return false;
  }

  static String currentRouteName(BuildContext context) {
    String routeName='';

    Navigator.popUntil(context, (route) {
      if (route.settings.name != null) {
        routeName = route.settings.name!;
      }
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
  /// bool saidYes = GLOBAL.yesNoDialog(
  ///   context,
  ///   prompt: 'Really draw?',
  ///   trueText: 'yes',
  ///   falseText: 'No',
  /// );
  /// if (saidYes) handleDraw();
  /// ```
  static Future<bool?> yesNoDialog(BuildContext context,
      {required String prompt,
        required String trueText,
        required String falseText}) async {

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
  static String scoreFormatString(score, SCORE_STRING kind,
      {bool japaneseNumbers = false}) {
    final bool scoreIsString = score is String;

    switch (kind) {
      case SCORE_STRING.totals:
        if (score > 0) {
          return score.toString();
        }

        return (japaneseNumbers ? '▲' : '-') + (-score).toString();

      case SCORE_STRING.deltas:
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

      case SCORE_STRING.finalDeltas:
        if (score == 0) {
          return '0';
        }
        final String textScore = (score.abs() / 10.0).toStringAsFixed(1);
        if (score > 0) {
          return '+' + textScore;
        }
        return (japaneseNumbers ? '▲' : '-') + textScore;
    }
  }

  static InlineSpan scoreFormatTextSpan(score, SCORE_TEXT_SPAN kind,
      {bool japaneseNumbers = false}) {
    final bool scoreIsString = score is String;

    switch (kind) {
      case SCORE_TEXT_SPAN.places:
      case SCORE_TEXT_SPAN.inProgress:
        return TextSpan(text: '');

      case SCORE_TEXT_SPAN.names:
        // should never actually reach this
        return TextSpan(text: score);

      case SCORE_TEXT_SPAN.chombo:
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

      case SCORE_TEXT_SPAN.netScores:
      case SCORE_TEXT_SPAN.deltas:
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

      case SCORE_TEXT_SPAN.chomboScore:
      case SCORE_TEXT_SPAN.oka:
      case SCORE_TEXT_SPAN.uma:
      case SCORE_TEXT_SPAN.adjustments:
      case SCORE_TEXT_SPAN.finalDeltas:
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

      case SCORE_TEXT_SPAN.startingPoints:
      case SCORE_TEXT_SPAN.totals:
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
            style: TextStyle(
                color: Colors.lightGreen, fontWeight: FontWeight.bold),
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
          style:
              TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        );
    }
  }

  static String? getTitle(BuildContext context, String? title) {
    final dynamic args = ModalRoute.of(context)!.settings.arguments;
    return args != null && args.containsKey('headline')
        ? args['headline']
        : title;
  }

  static void showFailedLoadingDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(
              "Failed to reload game; sorry, I don't know how to fix this"),
        );
      },
    );
  }

  static List<Map<String, dynamic>> allPlayers = [];
  static bool playersListUpdated = false;
  static int nextUnregisteredID = -2;
}

class TopBarNotifier extends StatefulWidget {
  final TopBarNotifierState _state = TopBarNotifierState();

  void show({required BuildContext context, required String message, Color? color}) =>
      _state.show(context, message, color);

  @override
  TopBarNotifierState createState() => _state;
}

class TopBarNotifierState extends State<TopBarNotifier>
    with TickerProviderStateMixin {
  late TopBarNotifierState self;

  @override
  void initState() {
    super.initState();
    self = this;
  }

  void show(BuildContext context, String message, Color? color) {
    AnimationController _animator = AnimationController(
      vsync: self,
      lowerBound: 0,
      upperBound: 1,
      duration: Duration(seconds: 3),
    );

    Flushbar(
      backgroundColor: color ?? Colors.red[900]!,
      showProgressIndicator: true,
      flushbarPosition: FlushbarPosition.TOP,
      message: message,
      duration: Duration(seconds: 3),
      progressIndicatorController: _animator,
    ).show(context);
    _animator.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
