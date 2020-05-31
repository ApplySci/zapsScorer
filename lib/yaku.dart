/// Manages the user-selection of the yaku of the current hand

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'appbar.dart';
import 'gameflow.dart';
import 'store.dart';
import 'utils.dart';
import 'yakuconstants.dart';

List<int> impossibleYaku = [];

class YakuButton extends StatefulWidget {
  final int yakuID;
  final Map buttonDetails;
  final bool inRiichi;
  final bool isClosed;
  final bool isTsumo;
  final Function callback;

  YakuButton({
    this.yakuID,
    this.buttonDetails,
    this.inRiichi,
    this.isClosed,
    this.isTsumo,
    this.callback,
  });

  @override
  YakuButtonState createState() => YakuButtonState();
}

class YakuButtonState extends State<YakuButton> {
  int hanCount = 0;
  bool isPressed = false;
  Function onPressed;

  @override
  Widget build(BuildContext context) {
    bool enabled = true;
    if (impossibleYaku.contains(widget.yakuID) ||
        (widget.buttonDetails.containsKey('open') &&
            widget.buttonDetails['open'] == false &&
            !widget.isClosed) ||
        (widget.buttonDetails.containsKey('riichi') &&
            (!widget.inRiichi || !widget.isClosed))) {
      enabled = false;
    }

    String buttonLabel = widget.buttonDetails['romaji'];
    bool isCountableButton = widget.buttonDetails['score'] == 0;
    Color buttonColour;

    onPressed = () {
      setState(() {
        isPressed = !isPressed;
        widget.callback({
          'pressed': isPressed,
          'yaku': widget.yakuID,
          'han': (widget.buttonDetails.containsKey('open') &&
                  widget.buttonDetails['open'] == -1 &&
                  !widget.isClosed)
              ? hanCount - 1
              : hanCount,
        });
      });
    };

    if (widget.yakuID == YAKU_TSUMO) {
      enabled = widget.isClosed && widget.isTsumo;
      isPressed = enabled;
      onPressed = () => false;
    }

    if (widget.yakuID == YAKU_RIICHI) {
      enabled = widget.inRiichi;
      isPressed = enabled;
      onPressed = () => false;
    }

    if (isPressed || (isCountableButton && hanCount > 0)) {
      buttonColour = Colors.green;
    } else {
      buttonColour = Colors.blue;
    }

    if (!enabled) {
      onPressed = null;
    } else if (isCountableButton) {
      buttonLabel = buttonLabel + ' x' + hanCount.toString();
      onPressed = (int delta) {
        setState(() {
          hanCount += delta;
          isPressed = hanCount > 0;
          widget.callback({
            'pressed': 'count',
            'yaku': widget.yakuID,
            'han': hanCount,
          });
        });
      };

      return Stack(
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: RaisedButton(
                  color: buttonColour,
                  onPressed: hanCount > 0 ? () => onPressed(-1) : null,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      '-1',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: RaisedButton(
                  color: buttonColour,
                  onPressed: () => onPressed(1),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Text('+1', style: TextStyle(fontSize: 10)),
                  ),
                ),
              ),
            ],
          ),
          AutoSizeText(
            buttonLabel,
            maxLines: 1,
            maxFontSize: 16,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      );
    } else {
      hanCount = widget.buttonDetails['score'];
    }

    return RaisedButton(
      color: buttonColour,
      onPressed: onPressed,
      child: AutoSizeText(
        buttonLabel,
        textAlign: TextAlign.center,
        maxLines: 3,
        minFontSize: 10,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.grey,
        ),
      ),
      padding: const EdgeInsets.all(1.0),
    );
  }
}

class YakuScreen extends StatefulWidget {
  @override
  YakuScreenState createState() => YakuScreenState();
}

class YakuScreenState extends State<YakuScreen> {
  bool openCloseAsked = false;
  bool isClosed = true;
  bool gotHan = false;
  Map<int, int> yaku = {};
  int fu = 0;
  int han = 0;
  List<Widget> buttonList;
  String winnerName;
  int lastWinnerSeen = -1;

  Future<int> fuDialog(BuildContext context, String winnerName,
      {bool mightHave30 = true}) async {
    // could get cute with sankantsu, but having it with fewer than 5 han is too rare to care

    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('$winnerName - fu?'),
          children: [
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              shrinkWrap: true,
              children: [30, 40, 50, 60, 70, 80, 90, 100, 110]
                  .map((int fu) => RaisedButton(
                        child: Text(fu.toString()),
                        onPressed: (fu == 30 && !mightHave30)
                            ? null
                            : () => Navigator.pop(context, fu),
                      ))
                  .toList(),
            )
          ],
        );
      },
    );
  }

  void recordResults() {
    int points;
    if (han > 1000) {
      // yakuman
      points = 8000;
      if (yaku.containsKey(YAKU_RIICHI)) {
        yaku.remove(YAKU_RIICHI);
      }
      if (yaku.containsKey(YAKU_TSUMO)) {
        yaku.remove(YAKU_TSUMO);
      }
      if (yaku.containsKey(PAO_FLAG)) {
        points = PAO_FLAG;
      }
    } else if (han > 10) {
      points = 6000;
    } else if (han > 7) {
      points = 4000;
    } else if (han > 5) {
      points = 3000;
    } else if (han > 4 ||
        (han == 4 &&
            ((fu == 30 && store.state.ruleSet.manganAt430) || fu > 30))) {
      points = 2000;
    } else {
      points = fu * pow(2, 2 + han);
    }
    String logText =
        '$fu fu, $han han ' + (isClosed ? 'closed' : 'open') + ': ';
    yaku.forEach((int k, int v) {
      logText += YAKU_DETAILS[k]['romaji'] + (k < 0 ? ' x$v' : '') + '; ';
    });
    Log.score(logText);
    if (isClosed) {
      yaku[HAND_IS_CLOSED] = 1;
    }
    store.dispatch({
      'type': STORE.recordYakuStats,
      'yaku': yaku,
    });
    Scoring.onScoreSelected(context, points);
  }

  void donePressed() async {
    impossibleYaku = [];
    gotHan = true;
    // fu=41 indicates that it's mangan+, so no need to ask user for fu
    if (yaku.containsKey(YAKU_CHITOITSU)) {
      fu = 25;
    } else if (yaku.containsKey(YAKU_PINFU)) {
      fu = yaku.containsKey(YAKU_TSUMO) ? 20 : 30;
    } else if (yaku.containsKey(YAKU_HONROUTOU)) {
      // honroutou is always at least 4 han 40 fu, so mangan+
      fu = 41;
    } else if (han > 4 || (han == 4 && store.state.ruleSet.manganAt430)) {
      fu = 41; // dummy number to ensure mangan where appropriate
    } else {
      // we've eliminated all the cases bar one where fu can be inferred.
      // First check whether 30 fu is possible. 20 fu is not possible here.
      bool mightHave30 = true;
      if (yaku.containsKey(YAKU_SANANKOU) // sanankou
              ||
              (yaku.containsKey(YAKU_YAKUHAI) && yaku[YAKU_YAKUHAI] >= 3)
              ||
              (yaku.containsKey(YAKU_SANKANTSU)) // sankantsu
              ||
              (!yaku.containsKey(YAKU_TSUMO) &&
                  isClosed) // ron, closed hand, no pinfu
          ) {
        mightHave30 = false;
      }
      if (!mightHave30 && han == 4) {
        fu = 41;
      } else {
        // can't infer fu, so ask user
        fu = await fuDialog(context, winnerName, mightHave30: mightHave30);
      }
    }

    if (fu != null) {
      recordResults();
    }
  }

  void disableIncompatibleYaku(int yakuPressed, bool pressed) {
    if (pressed) {
      INCOMPATIBLE_YAKU[yakuPressed].forEach((int bad) {
        if (!impossibleYaku.contains(bad)) {
          impossibleYaku.add(bad);
        }
      });
    } else {
      impossibleYaku = [];
      yaku.forEach((key, value) {
        if (value > 0) {
          disableIncompatibleYaku(key, true);
        }
      });
    }
  }

  void onPressed(dynamic action) {
    setState(() {
      if (action['pressed'] == true) {
        han += action['han'];
        yaku[action['yaku']] = 1;
        disableIncompatibleYaku(action['yaku'], true);
      } else if (action['pressed'] == false) {
        han -= action['han'];
        yaku.remove(action['yaku']);
        disableIncompatibleYaku(action['yaku'], false);
      } else if (action['pressed'] == 'count') {
        han += action['han'] -
            (yaku.containsKey(action['yaku']) ? yaku[action['yaku']] : 0);
        yaku[action['yaku']] = action['han'];
        disableIncompatibleYaku(action['yaku'], action['han'] > 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dynamic args = ModalRoute.of(context).settings.arguments;
    int winner = args is Map && args.containsKey('winner')
        ? args['winner']
        : store.state.result['winners'];

    if (!(winner is int)) {
      // dummy to foil problematic async rebuild
      return Container();
    }

    if (winner != lastWinnerSeen) {
      lastWinnerSeen = winner;
      yaku = {};
      openCloseAsked = false;
      isClosed = true;
      gotHan = false;
      fu = 0;
      han = 0;
      impossibleYaku = [];
    }

    winnerName = store.state.players[winner]['name'];

    bool inRiichi = store.state.riichiDeltaThisHand[winner] < 0;

    if (inRiichi && !yaku.containsKey(YAKU_RIICHI)) {
      yaku[YAKU_RIICHI] = 1;
      han++;
    }

    if (inRiichi) {
      isClosed = true;
      openCloseAsked = true;
    }

    if (!openCloseAsked) {
      return SimpleDialog(
        title: Text('$winnerName - hand open or closed?'),
        children: <Widget>[
          Padding(
            child: Container(),
            padding: EdgeInsets.all(10),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() {
                openCloseAsked = true;
                isClosed = false;
              });
            },
            child: Text('Open'),
          ),
          Padding(
            child: Container(),
            padding: EdgeInsets.all(10),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() {
                openCloseAsked = true;
                isClosed = true;
              });
            },
            child: Text('Closed'),
          ),
        ],
      );
    }

    bool isTsumo = isClosed && store.state.result['result'] == RESULT.tsumo;

    if (isTsumo && !yaku.containsKey(YAKU_TSUMO)) {
      yaku[YAKU_TSUMO] = 1;
      han++;
    }
    disableIncompatibleYaku(YAKU_TSUMO, isTsumo);

    buttonList = [];

    YAKU_BUTTON_ORDER.forEach((int id) {
      buttonList.add(YakuButton(
        yakuID: id,
        buttonDetails: YAKU_DETAILS[id],
        inRiichi: inRiichi,
        isClosed: isClosed,
        isTsumo: isTsumo,
        callback: onPressed,
      ));
    });

    bool validYaku = false;
    yaku.forEach((id, val) {
      if (id > 0 && val > 0 && id != PAO_FLAG) {
        validYaku = true;
      }
    });

    // sanity checks
    if ((yaku.containsKey(YAKU_HONROUTOU) && !yaku.containsKey(1)) || // honroutou, no toitoi
        (yaku.containsKey(18) &&
            (!yaku.containsKey(YAKU_YAKUHAI) ||
                yaku[YAKU_YAKUHAI] < 2)) || // shousangan with yaku hai<2
        (yaku.containsKey(PAO_FLAG)) && // Pao without daisangan, Shousuushi
            !yaku.containsKey(19) &&
            !yaku.containsKey(20)) {
      // at least one of the sanity checks has failed, so disable the done button for now
      validYaku = false;
    }

    buttonList.add(RaisedButton(
      color: Colors.green[900],
      onPressed: validYaku ? donePressed : null,
      child: AutoSizeText(
        'Done',
        style: TextStyle(color: validYaku ? Colors.white : null),
      ),
    ));

    return Scaffold(
      appBar: MyAppBar(GLOBAL.getTitle(context, "What's the score?")),
      body: DefaultTextStyle(
        style: TextStyle(
          fontSize: 20.0,
          color: Colors.yellow,
          decoration: null,
        ),
        child: GridView.count(
          shrinkWrap: true,
          children: buttonList,
          childAspectRatio: 2,
          crossAxisCount: 4,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
      ),
    );
  }
}
