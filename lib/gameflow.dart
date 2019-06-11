/// Does all the clever stuff, scoring and routing

//import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'store.dart';
import 'utils.dart';

import 'gamedb.dart';

class Scoring {
  static void calculateChombo(BuildContext context, List<bool> hasChombo) {
    // hand cancelled, return everyone's riichi sticks
    List<int> chombos = [0, 0, 0, 0];
    String playerNames = '';
    for (int i = 0; i < 4; i++) {
      if (hasChombo[i]) {
        playerNames += store.state.players[i]['name'] + ', ';
        chombos[i] = 1;
      }
    }
    _returnRiichiSticks();
    store.dispatch({
      'type': STORE.addRow,
      'score_display': SCORE_TEXT_SPAN.chombo,
      'scores': chombos,
    });
    Log.score('Chombo by $playerNames');
    initHand();
  }

// called from the Draw whoDidIt dialog when Done is pressed
  static void calculateDrawScores(BuildContext context, List<bool> tenpai) {
    int nReady = 0;
    int from = 0;
    int to = 0;

    List<int> winners = [];
    List<int> losers = [];

    List<dynamic> deltas = [0, 0, 0, 0];

    for (int i = 0; i < 4; i++) {
      if (tenpai[i]) nReady++;
    }

    switch (nReady) {
      case 1:
        from = 10;
        to = 30;
        break;
      case 2:
        from = 15;
        to = 15;
        break;
      case 3:
        from = 30;
        to = 10;
    }

    for (int i = 0; i < 4; i++) {
      if (tenpai[i]) {
        winners.add(i);
        deltas[i] = to;
      } else {
        losers.add(i);
        deltas[i] = -from;
      }
    }

    Log.score('Draw $deltas');
    store.dispatch({
      'type': STORE.setResult,
      'result': {
        'result': RESULT.draw,
        'winners': winners,
        'losers': losers,
      },
    });

    handEnd(context, deltas);
  }

  static void calculatePao(BuildContext context, List<bool> responsible) {
    store.dispatch({
      'type': STORE.setPaoLiable,
      'liable': responsible.indexOf(true),
    });
    _endOfHanFu(context, 8000);
  }


  static Future<bool> confirmUndoLastHand(BuildContext context) async {
    return GLOBAL.yesNoDialog(context,
        prompt: 'Really undo last hand?',
        trueText: 'Yes, undo it',
        falseText: 'No, keep it');
  }


  static void askToFinishGame(BuildContext context) async {
    bool reallyFinish = await GLOBAL.yesNoDialog(context,
        prompt: 'Really finish this game now?',
        trueText: 'Yes, finish it',
        falseText: 'No, carry on playing');
    if (reallyFinish) {
      Log.unusual('User requested early finish of game');
      finishGame(context);
    }
  }

  static void getHanFu(BuildContext context, [dynamic args]) {
    Navigator.of(context).pushNamed(
        store.state.preferences['namedYaku'] ? ROUTES.yaku : ROUTES.hanFu,
        arguments: args);
  }

  static void handEnd(BuildContext context, dynamic dataIn) {
    Map<String, dynamic> resultMap = Map.from(store.state.result);
    dynamic winners = resultMap['winners'];
    RESULT result = resultMap['result'];

    bool eastIsWinner = false;
    bool wasDraw = false;
    List<int> scoreChange = List(4);

    if (winners is List) {
      if (winners.length == 1) {
        winners = winners[0];
      } else {
        eastIsWinner = winners.contains(store.state.dealership);
      }
    }
    if (winners is int) eastIsWinner = winners == store.state.dealership;

    switch (result) {
      case RESULT.draw:
        wasDraw = true;
        scoreChange = List<int>.from(dataIn);
        break;
      case RESULT.tsumo:
        resultMap['score'] = dataIn;
        scoreChange = _calculateTsumoScores(eastIsWinner, resultMap);
        break;
      case RESULT.ron:
        resultMap['score'] = dataIn;
        scoreChange = _calculateRonScores(resultMap);
        // get store.state.riichiSticks *after* _calculateRonScores, as it can change there
        scoreChange[winners] += 10 * store.state.riichiSticks;
        store.dispatch({'type': STORE.awardRiichiSticks, 'to': winners});
        break;
      case RESULT.multiple_ron:
        eastIsWinner = store.state.result['eastIsWinner'];
        scoreChange = List<int>.from(resultMap['score']);
        scoreChange[winners] += 10 * store.state.riichiSticks;
        store.dispatch({'type': STORE.awardRiichiSticks, 'to': winners});
        break;
      case RESULT.chombo:
// this should already have been handled, so it should never arrive here
      case RESULT.none:
        assert(
        false, 'Received a result in Scoring.handEnd that was unexpected');
        return;
    }

    store.dispatch({
      'type': STORE.addDelta,
      'deltas': scoreChange,
    });

    for (int i = 0; i < 4; i++) {
      if (store.state.inRiichi[i]) {
        scoreChange[i] -= 10;
      }
    }

    store.dispatch({
      'type': STORE.addRow,
      'score_display': SCORE_TEXT_SPAN.deltas,
      'scores': scoreChange,
    });

    // split out score changes between riichi-stick changes and other;
    for (int i = 0; i < 4; i++) {
      scoreChange[i] -= 10 * store.state.riichiDeltaThisHand[i];
    }

    store.dispatch({
      'type': STORE.showDeltas,
      'deltas': List<int>.from(scoreChange)
        ..addAll(store.state.riichiDeltaThisHand),
    });

    store.dispatch(STORE.resetRiichi);
    if (eastIsWinner) {
      store.dispatch(STORE.redealHand);
      return _nextHand(context);
    } else if (store.state.dealership == 3 && store.state.roundWind > 0) {
      // end of the South wind round
      return _maybeFinishGame(context);
    } else {
      store.dispatch({
        'type': STORE.nextDealership,
        'wasDraw': wasDraw,
        'eastIsWinner': eastIsWinner
      });
      _nextHand(context);
    }
  }

  static void handleNextRon(BuildContext context, [int points]) {
    // called once for each winner in a multiple-ron
    int winner = store.state.result['winners'].last;
    String prefix = 'And ';
    if (points == null) {
      // first entry here
      prefix = 'Firstly, ';
      store.dispatch(STORE.accumulateScores);
      store.dispatch({
        'type': STORE.eastIsWinner,
        'isIt': store.state.result['winners'].contains(store.state.dealership),
      });
    } else {
      // we've been here before, so save score for this ronning player, and move onto next one
      Map<String, int> resultToSend = {
        'winners': winner,
        'losers': store.state.result['losers'],
        'score': points,
      };
      if (store.state.result.containsKey('liable')) {
        resultToSend['liable'] = store.state.result['liable'];
      }
      List<int> scoreChange = _calculateRonScores(resultToSend);
      for (int i = 0; i < 4; i++) {
        scoreChange[i] += store.state.result['score'][i];
      }
      store.dispatch({
        'type': STORE.accumulateScores,
        'score': List<int>.from(scoreChange)
      });
      if (store.state.result['winners'].length == 1) {
        // actually, that was the last ronning player, so stop
        store.dispatch(STORE.setHanFuCallback);
        handEnd(context, 'Multiple ron');
        return;
      }
      // at least one more player to get the score of
      store.dispatch(STORE.popWinner);
      winner = store.state.result['winners'].last;
      Navigator.pop(context);

      if (store.state.result['winners'].length == 1) {
        prefix = 'Finally, ';
      }
    }

    store.dispatch({'type': STORE.setHanFuCallback, 'callback': handleNextRon});
    Log.score('Ron by ' + store.state.players[winner]['name']);

    getHanFu(context, {
      'headline': prefix + _getYakuHeadline(winner),
      'winner': winner,
    });
  }

  static void initHand() {
    store.dispatch(STORE.initHand);
  }

  static void multipleRons(BuildContext context, List<bool> winners) {
    Map<String, dynamic> result = Map.from(store.state.result);
    final int loser = result['losers'];

    result['winners'] = <int>[];
    result['result'] = RESULT.multiple_ron;

    for (int i = 1; i < 4; i++) {
      int one = (loser + i) % 4;
      if (winners[one]) {
        result['winners'].add(one);
      }
    }
    store.dispatch({'type': STORE.setResult, 'result': result});
    String logText =
        'Multiple ron: ' + store.state.players[loser]['name'] + ' dealt into ';
    result['winners'].forEach((int i) {
      logText += store.state.players[i]['name'] + ', ';
    });
    Log.score(logText);

    handleNextRon(context);
  }

  static void onScoreSelected(BuildContext context, int points) async {
    if (points == PAO_FLAG) {
      await Navigator.pushNamed(context, ROUTES.pao);
      return;
    }
    _endOfHanFu(context, points);
  }

  static void randomiseAndStartGame(BuildContext context,
      List<Map<String, dynamic>> players, RULE_SET ruleSet) {
    List<Map<String, dynamic>> copiedNames = players.toList();
    List<Map<String, dynamic>> reorderedNames = [];

    final _random = new Random();
    for (int i = 0; i < 4; i++) {
      int idx = _random.nextInt(4 - i);
      reorderedNames.add(copiedNames[idx]);
      copiedNames.removeAt(idx);
    }
    startGame(context, reorderedNames, ruleSet);
  }

  static void startGame(BuildContext context, List<Map<String, dynamic>> players,
      RULE_SET ruleSet) {
    store.dispatch({'type': STORE.setRules, 'ruleSet': ruleSet});
    store.dispatch({'type': STORE.players, 'players': players});
    store.dispatch(STORE.initGame);

    Log.logs = [];
    Log.info('Game start, players E,S,N,W: $players');
    try {
      Navigator.popUntil(context, ModalRoute.withName(ROUTES.hands));
    } catch (e) {
      if (GLOBAL.currentRouteName(context) != ROUTES.hands) {
        Navigator.pushReplacementNamed(context, ROUTES.hands);
      }
    }
  }

  static void maybeUndoLastHand(BuildContext context) async {
    bool reallyUndo = await confirmUndoLastHand(context);
    if (reallyUndo) {
      undoLastHand();
    }
  }

  static List<int> _calculateRonScores(Map<String, dynamic> result) {
// called by handEnd and multipleRons
    int winner = result['winners'];
    bool eastIsWinner = winner == store.state.dealership;
    List<int> scoreChange = [0, 0, 0, 0];
    int delta = _mjRound((eastIsWinner ? 6 : 4) * result['score']);
    int honbaBonus = 3 * store.state.honbaSticks;
    scoreChange[result['winners']] = delta + honbaBonus;
    if (result.containsKey('liable')) {
      store.dispatch(STORE.setPaoLiable);
      int pao = result['liable'];
      scoreChange[result['losers']] = -delta ~/ 2 - honbaBonus;
// using += just in case loser = liable anyway
      scoreChange[pao] += -delta ~/ 2;
    } else {
      scoreChange[result['losers']] = -delta - honbaBonus;
    }
    store.dispatch({
      'type': STORE.setRiichi,
      'player': winner,
      'inRiichi': false,
    });
    return scoreChange;
  }

  static List<int> _calculateTsumoScores(bool eastIsWinner,
      Map<String, dynamic> result) {
// only called from handEnd
    List<int> scoreChange;
    int pao = -1;
    int score = result['score'];
    int delta1 = _mjRound(score + 100 * store.state.honbaSticks);
    int delta2 = _mjRound(2 * score + 100 * store.state.honbaSticks);

    if (result.containsKey(('liable'))) {
      pao = result['liable'];
      store.dispatch(STORE.setPaoLiable);
      scoreChange = [0, 0, 0, 0];
    }

    if (eastIsWinner) {
      if (pao > -1) {
        scoreChange[pao] = -3 * delta2;
      } else {
        scoreChange = [-delta2, -delta2, -delta2, -delta2];
      }
      scoreChange[result['winners']] = 3 * delta2;
    } else {
      if (pao > -1) {
        scoreChange[pao] = -2 * delta1 - delta2;
      } else {
        scoreChange = [-delta1, -delta1, -delta1, -delta1];
        scoreChange[store.state.dealership] = -delta2;
      }
      scoreChange[result['winners']] = 2 * delta1 + delta2;
    }

    store.dispatch({
      'type': STORE.setRiichi,
      'player': result['winners'],
      'inRiichi': false,
    });

    scoreChange[result['winners']] += 10 * store.state.riichiSticks;
    store.dispatch({'type': STORE.awardRiichiSticks, 'to': result['winners']});

    return scoreChange;
  }

  static void _endOfHanFu(BuildContext context, int points) {
    if (store.state.hanFuCallback == unassigned) {
      handEnd(context, points);
    } else {
      store.state.hanFuCallback(context, points);
    }
  }

  static void _maybeFinishGame(BuildContext context) {
    _gotoHands(context);
    store.dispatch({'type': STORE.endOfGame, 'value': true});
  }

  static void finishGame(BuildContext context) {
    Log.info('game finished');
    store.dispatch(STORE.endGame);
    if (deleteIfEmpty(context)) {
      Navigator.pushNamedAndRemoveUntil(
          context, ROUTES.selectPlayers, ModalRoute.withName(ROUTES.hands));
      return;
    }

    // descending
    List<int> orderedScores = (store.state.scores.toList(growable: false)
      ..sort())
        .reversed
        .toList(growable: false);

    // zero-indexed, so placement[0] is 2 if player 1 ended up 2rd.
    List<int> placement = List(4);

    for (int i = 0; i < 4; i++) {
      placement[i] = orderedScores.indexOf(store.state.scores[i]);
    }

    List<int> allUma = store.state.ruleSet.uma.toList(growable: false);

    int adjustmentTotal = store.state.ruleSet.riichiAbandonedAtEnd
        ? 0
        : 10 * store.state.riichiSticks; // will be awarded to 1st place

    List<int> adjustments = [adjustmentTotal, 0, 0, 0];
    List<int> tiedPlaces = [1, 2, 3, 4]; // no ties in the default case

    int shared;

    // Calculation for sharing uma between tied places,
    // and sharing left-over riichi sticks between joint-first places.
    // The below may look cumbersome, but it is at least explicit as to how
    // each case is handled. And there's only 8 cases, so it's not too horrible
    // to handle each one individually, rather than trying to add clever
    // heuristics to do it otherwise.

    if (orderedScores[0] == orderedScores[1] &&
        orderedScores[1] == orderedScores[2] &&
        orderedScores[2] == orderedScores[3]) {
      tiedPlaces = [1, 1, 1, 1];
      allUma =
          List.filled(4, (allUma[0] + allUma[1] + allUma[2] + allUma[3]) ~/ 4);
      adjustments = List.filled(4, (adjustmentTotal ~/ 4));
    } else if (orderedScores[1] == orderedScores[2] &&
        orderedScores[2] == orderedScores[3]) {
      tiedPlaces = [1, 2, 2, 2];
      shared = (allUma[1] + allUma[2] + allUma[3]) ~/ 3;
      allUma = [allUma[0], shared, shared, shared];
    } else if (orderedScores[0] == orderedScores[1] &&
        orderedScores[1] == orderedScores[2]) {
      shared = (allUma[0] + allUma[1] + allUma[2]) ~/ 3;
      tiedPlaces = [1, 1, 1, 4];
      allUma = [shared, shared, shared, allUma[3]];
      shared = adjustmentTotal ~/ 3;
      adjustments = [shared, shared, shared, 0];
    } else if (orderedScores[0] == orderedScores[1] &&
        orderedScores[2] == orderedScores[3]) {
      tiedPlaces = [1, 1, 3, 3];
      shared = (allUma[0] + allUma[1]) ~/ 2;
      int shared2 = (allUma[2] + allUma[3]) ~/ 2;
      allUma = [shared, shared, shared2, shared2];
      shared = adjustmentTotal ~/ 2;
      adjustments = [shared, shared, 0, 0];
    } else if (orderedScores[1] == orderedScores[2]) {
      tiedPlaces = [1, 2, 2, 4];
      shared = (allUma[1] + allUma[2]) ~/ 2;
      allUma = [allUma[0], shared, shared, allUma[3]];
    } else if (orderedScores[2] == orderedScores[3]) {
      tiedPlaces = [1, 2, 3, 3];
      shared = (allUma[2] + allUma[3]) ~/ 2;
      allUma = [allUma[0], allUma[1], shared, shared];
    } else if (orderedScores[0] == orderedScores[1]) {
      tiedPlaces = [1, 1, 3, 4];
      shared = (allUma[0] + allUma[1]) ~/ 2;
      allUma = [shared, shared, allUma[2], allUma[3]];
      shared = adjustmentTotal ~/ 2;
      adjustments = [shared, shared, 0, 0];
    }

    List<int> finalPlaces = List(4);
    List<int> finalUma = List(4);
    List<int> finalAdjustments = List(4);

    for (int i = 0; i < 4; i++) {
      finalPlaces[i] = tiedPlaces[placement[i]];
      finalUma[i] = allUma[placement[i]];
      finalAdjustments[i] = adjustments[placement[i]];
    }

    store.dispatch({
      'type': STORE.setUma,
      'uma': finalUma,
      'adjustments': finalAdjustments,
      'places': finalPlaces,
    });

    Navigator.pushNamed(context, ROUTES.scoreSheet);
    // TODO add button to scoresheet offering to register unregistered players, if there were any present in this game
  }

  static bool deleteIfEmpty(BuildContext context) {
    bool wasEmpty = false;
    store.dispatch(STORE.endGame);
    if (store.state.scoreSheet.length == 0 ||
        store.state.scoreSheet.length == 1 &&
            store.state.scoreSheet.last.type == SCORE_TEXT_SPAN.inProgress) {

      // the game never started
      wasEmpty = true;
      GameDB().deleteGame(store.state.gameID);
    }
    return wasEmpty;
  }

  static String _getYakuHeadline(int i) {
    return 'Score by ' + store.state.players[i]['name'];
  }


  static void _gotoHands(BuildContext context, {Map<String, dynamic> args}) {
    try {
      Navigator.popUntil(context, (route) => route.settings.name == ROUTES.hands);
    } catch (e) {
      if (GLOBAL.currentRouteName(context) != ROUTES.hands) {
        Navigator.pushNamed(context, ROUTES.hands, arguments: args);
      }
    }
  }

  static int _mjRound(int score) {
    return (score.abs() / 100).ceil() * score.sign;
  }

  static void _nextHand(BuildContext context) {
    initHand();
    _gotoHands(context);
    store.dispatch({'type': STORE.endOfHand, 'value': true});
  }

  static void _returnRiichiSticks() {
    for (int i = 0; i < 4; i++) {
      if (store.state.inRiichi[i]) {
        store.dispatch(
            {'type': STORE.setRiichi, 'player': i, 'inRiichi': false});
      }
    }
  }

  static void undoLastHand() {
    _returnRiichiSticks();
    store.dispatch(STORE.undoLastHand);
  }
}
