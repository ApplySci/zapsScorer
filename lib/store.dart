/// Glues the whole thing together with variables shared app-wide, using redux

import 'dart:convert';

import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';

import 'gamedb.dart';
import 'utils.dart';

SharedPreferences _prefs;

const Map<String, dynamic> DEFAULT_PREFERENCES = {
  'backgroundColour': DEFAULT_COLOUR_KEY, // Colors.black,
  'installationID': null,
  'japaneseWinds': true,
  'japaneseNumbers': false,
  'namedYaku': false,
  'registerNewPlayers': false,
  'serverUrl': 'https://mahjong.bacchant.es',
  'userID': 0, // id on server
  'username': '', // players name attached to this id
  'authToken': '', // server authorisation token
  'useServer': true,
};

class Log {
  static List<List<dynamic>> logs = [];

  static String handName() {
    return WINDS[store.state.preferences['japaneseWinds']
            ? 'japanese'
            : 'western'][store.state.roundWind] +
        (store.state.dealership + 1).toString() +
        '-' +
        store.state.handRedeals.toString();
  }

  static void debug(String text) {
    debugPrint(text);
  }

  static void _saveLog(LOG type, String text) {
    String typeString = enumToString(type);
    logs.add([
      DateTime.now().toIso8601String(),
      typeString,
      handName() + " " + text
    ]);
    debug('$typeString : $text');
  }

  static void score(String text) {
    _saveLog(LOG.score, text);
  }

  static void unusual(String text) {
    _saveLog(LOG.unusual, text);
  }

  static void warn(String text) {
    _saveLog(LOG.warn, text);
  }

  static void error(String text) {
    _saveLog(LOG.error, text);
  }

  static void info(String text) {
    _saveLog(LOG.info, text);
  }
}

class GameState {
  List<int> changes = <int>[0, 0, 0, 0, 0, 0, 0, 0].toList(growable: false);
  int dealership = 0;
  bool endOfGame = false;
  bool endOfHand = false;
  Map<SCORE_TEXT_SPAN, List<int>> finalScores = {};
  String gameID;
  int handRedeals = 0;
  Function hanFuCallback = unassigned;
  int honbaSticks = 0;
  bool inProgress = false;

  List<bool> inRiichi =
      <bool>[false, false, false, false].toList(growable: false);

  bool loadedOK = false;

  List<Map<String, dynamic>> players = [
    {'id': 0, 'name': 'Player 1'},
    {'id': 0, 'name': 'Player 2'},
    {'id': 0, 'name': 'Player 3'},
    {'id': 0, 'name': 'Player 4'},
  ];

  Map<String, dynamic> preferences = Map.from(DEFAULT_PREFERENCES);
  Map<String, dynamic> result = {};

  List<int> riichiDeltaThisHand =
      <int>[0, 0, 0, 0].toList(growable: false); // number gained in this hand

  int riichiSticks = 0; // number on the table from this & previous hands
  int roundWind = 0;
  Rules ruleSet;
  List<int> scores = <int>[0, 0, 0, 0].toList(growable: false);
  List<ScoreRow> scoreSheet = [];
  String title = 'ZAPS Mahjong Scorer';
  Map<String, dynamic> widgets = {};

  String handTitle() {
    String out = DateTime.now()
            .toIso8601String()
            .substring(0, 16)
            .replaceFirst('T', ' ') +
        ' ';
    if (inProgress) {
      out += WINDS[preferences['japaneseWinds'] ? 'japanese' : 'western']
              [roundWind] +
          '${dealership + 1}-$handRedeals';

      for (int i = 0; i < 4; i++) {
        out += ' ' +
            players[i]['name'] +
            '(' +
            (scores[i] / 10.0).toStringAsFixed(1) +
            '),';
      }
    } else {
      List<int> placements = [0, 1, 2, 3];
      placements.sort((int a, int b) =>
          store.state.finalScores[SCORE_TEXT_SPAN.finalDeltas][b] -
          store.state.finalScores[SCORE_TEXT_SPAN.finalDeltas][a]);
      for (int i = 0; i < 4; i++) {
        out += ' ' +
            players[i]['name'] +
            '(' +
            GLOBAL.scoreFormatString(
                store.state.finalScores[SCORE_TEXT_SPAN.finalDeltas]
                    [placements[i]],
                SCORE_STRING.finalDeltas) +
            '),';
      }
    }
    return out;
  }

  String toJSON() {
    Map<String, dynamic> valuesToSave = {
      'finalScores': {},
      'gameID': gameID,
      'inProgress': inProgress,
      'log': List.from(Log.logs),
      'players': players,
      'rules': enumToString(ruleSet.rules),
      'scores': scores,
      'scoreSheet': scoreSheet.map((ScoreRow row) => row.toMap()).toList(),
      'title': handTitle(),
    };
    finalScores.forEach((SCORE_TEXT_SPAN key, List<int> value) {
      valuesToSave['finalScores'][enumToString(key)] = value;
    });
    return jsonEncode(valuesToSave);
  }

  void putGame() async {
    Map result = await GameDB().putGame({
      'gameID': gameID,
      'live': inProgress,
      'summary': handTitle(),
      'json': toJSON(),
    });

    if (result['ok']) {
      List<Map<String, dynamic>> newPlayers = [];
      for (int i = 0; i < 4; i++) {
        Map<String, dynamic> newPlayer = result['body']['players'][i];
        if (newPlayer['id'] == store.state.players[i]['id']) {
          newPlayer['name'] = players[i]['name'];
        } else {
          GameDB().addUser(newPlayer);
        }
        newPlayers.add(newPlayer);
      }

      store.dispatch({'type': STORE.players, 'players': newPlayers});
    }
  }
}

/// Sole arbiter of the contents of the Store after initialisation
GameState scoreReducer(GameState state, dynamic action) {
  void fromJSON(String json) {
    Map<String, dynamic> restoredValues = jsonDecode(json);

    Log.logs = List<List<dynamic>>.from(restoredValues['log']);
    state.finalScores = {};
    (restoredValues['finalScores'] as Map<String, dynamic>)
        .forEach((String key, dynamic values) {
      state.finalScores[
              enumFromString<SCORE_TEXT_SPAN>(key, SCORE_TEXT_SPAN.values)] =
          List<int>.from(values);
    });

    state.gameID = restoredValues['gameID'];
    state.inProgress = restoredValues['inProgress'];
    state.players = List<Map<String, dynamic>>.from(restoredValues['players']);
    state.ruleSet = Rules(
        enumFromString<RULE_SET>(restoredValues['rules'], RULE_SET.values));

    state.scores = List<int>.from(restoredValues['scores']);

    state.scoreSheet = List<ScoreRow>.from(restoredValues['scoreSheet']
        .map((row) => ScoreRow.fromMap(row, restoredValues['version'])));

    if (state.inProgress) {
      state.dealership = state.scoreSheet.last.dealership;
      state.handRedeals = state.scoreSheet.last.handRedeals;
      state.roundWind = state.scoreSheet.last.roundWind;

      if (state.scoreSheet.length == 0) {
        state.honbaSticks = 0;
        state.riichiSticks = 0;
      } else {
        state.honbaSticks = state.scoreSheet.last.honbaSticks;
        state.riichiSticks = state.scoreSheet.last.riichiSticks;
      }
    }
  }

  void _resetHandCounters() {
    state.riichiDeltaThisHand = [0, 0, 0, 0];
    state.inRiichi = [false, false, false, false];
    state.result = {};
  }

  void _initHand() {
    if (state.scoreSheet.length > 1 &&
        state.scoreSheet.last.type == SCORE_TEXT_SPAN.inProgress) {
      Log.error(
          'Asked to add a new score row, but previous row was still in progress');
      state.scoreSheet.removeLast();
    }
    state.scoreSheet.add(ScoreRow(
      type: SCORE_TEXT_SPAN.inProgress,
      dealership: state.dealership,
      roundWind: state.roundWind,
      handRedeals: state.handRedeals,
      riichiSticks: state.riichiSticks,
      honbaSticks: state.honbaSticks,
    ));

    _resetHandCounters();
    state.putGame();
  }

  Log.debug(action.toString());
  STORE toDo = action is STORE ? action : action['type'];

  switch (toDo) {
    case STORE.accumulateScores:
      if (action is Map && action.containsKey('score')) {
        state.result['score'] = action['score'].toList(growable: false);
      } else {
        state.result['score'] = <int>[0, 0, 0, 0];
      }

      break;

    case STORE.addRow:
      state.scoreSheet.last.type = action['score_display'];
      state.scoreSheet.last.scores = action['scores'].toList();
      break;

    case STORE.addDelta:
      for (int i = 0; i < 4; i++) {
        state.scores[i] += action['deltas'][i];
      }
      break;

    case STORE.awardRiichiSticks:
      state.riichiDeltaThisHand[action['to']] += state.riichiSticks;
      state.riichiSticks = 0;
      break;

    case STORE.endOfGame:
      state.endOfGame = action['value'];
      state.endOfHand = action['value'];
      break;

    case STORE.endOfHand:
      state.endOfHand = action['value'];
      break;

    case STORE.endGame:
      state.inProgress = false;
      break;

    case STORE.initGame:
      // reinitialise the entire state. But is this REALLY the best way to do this?

      // variables we'll carry over to the new state:
      Map<String, dynamic> preferences = Map.from(state.preferences);
      List<Map<String, dynamic>> players =
          state.players.toList(growable: false);
      RULE_SET rules = state.ruleSet.rules;

      // new state
      state = GameState();

      // carry over variables
      preferences.forEach(
          (String key, dynamic value) => state.preferences[key] = value);
      state.players = players;
      state.ruleSet = Rules(rules);

      // initialise game
      state.gameID = DateTime.now().millisecondsSinceEpoch.toString() +
          store.state.preferences['installationID'];
      int sp = state.ruleSet.startingPoints;
      state.scores = <int>[sp, sp, sp, sp];
      state.inProgress = true;
      _initHand();
      break;

    case STORE.initHand:
      _initHand();
      break;

    case STORE.initPreferences:
      action['preferences'].forEach((key, val) {
        state.preferences[key] = val;
      });
      break;

    case STORE.eastIsWinner:
      state.result['eastIsWinner'] = action['isIt'];
      break;

    case STORE.nextDealership:
      state.honbaSticks = action['wasDraw'] ? state.honbaSticks + 1 : 0;
      state.handRedeals = 0;
      state.dealership += 1;
      state.endOfHand = true;
      if (state.dealership > 3) {
        state.dealership = 0;
        state.roundWind += 1;
      }
      break;

    case STORE.players:
      state.players = action['players'].toList();
      break;

    case STORE.popWinner:
      state.result['winners'].removeLast();
      break;

    case STORE.recordYakuStats:
      state.scoreSheet.last.yaku = [];
      (action['yaku'] as Map<int, int>)
          .forEach((key, val) => state.scoreSheet.last.yaku.add([key, val]));
      break;

    case STORE.redealHand:
      state.honbaSticks += 1;
      state.handRedeals += 1;
      break;

    case STORE.resetRiichi:
      state.inRiichi = [false, false, false, false];
      break;

    case STORE.restoreFromJSON:
      try {
        fromJSON(action['json']);
        state.loadedOK = true;
      } catch (e, stackTrace) {
        Log.error('failed to restore game: $e , $stackTrace');
        state.loadedOK = false;
      }
      break;

    case STORE.setHanFuCallback:
      if (action is Map && action.containsKey('callback')) {
        state.hanFuCallback = action['callback'];
      } else {
        state.hanFuCallback = unassigned;
      }
      break;

    case STORE.setPaoLiable:
      if (action is Map && action.containsKey('liable')) {
        state.result['liable'] = action['liable'];
        Log.score('Pao liable: ' + state.players[action['liable']]['name']);
      } else {
        state.result.remove('liable');
      }
      break;

    case STORE.setPreferences:
      action['preferences'].forEach((key, val) {
        state.preferences[key] = val;
        if (val is bool) {
          _prefs.setBool(key, val);
        } else if (val is String) {
          _prefs.setString(key, val);
        } else if (val is double) {
          _prefs.setDouble(key, val);
        } else if (val is int) {
          _prefs.setInt(key, val);
        }
      });
      break;

    case STORE.setResult:
      state.result = Map.from(action['result']);
      break;

    case STORE.setRiichi:
      if (state.inRiichi[action['player']] != action['inRiichi']) {
        state.inRiichi[action['player']] = action['inRiichi'];
        int multiplier = action['inRiichi'] ? 1 : -1;
        String playerRef = 'player ' + (action['player'] + 1).toString();
        if (multiplier == -1) {
          if (action.containsKey('log')) {
            Log.unusual('$playerRef removed riichi');
            Log.score('$playerRef riichi removed');
          }
        } else {
          Log.score('$playerRef riichi');
        }
        state.scores[action['player']] -= multiplier * 10;
        state.riichiSticks += multiplier;
        state.riichiDeltaThisHand[action['player']] -= multiplier;
      }
      break;

    case STORE.setRules:
      state.ruleSet = Rules(action['ruleSet']);
      break;

    case STORE.setUma:
      List<int> chomboPenalties = List(4);
      List<int> finalScores = List(4);
      List<int> chomboCount = [0, 0, 0, 0];
      state.scoreSheet.forEach((ScoreRow row) {
        if (row.type == SCORE_TEXT_SPAN.chombo) {
          for (int i = 0; i < 4; i++) {
            chomboCount[i] += row.scores[i];
          }
        }
      });
      for (int i = 0; i < 4; i++) {
        chomboPenalties[i] = state.ruleSet.chomboValue * chomboCount[i];
        finalScores[i] = state.scores[i] -
            state.ruleSet.startingPoints +
            action['uma'][i] +
            action['adjustments'][i] +
            chomboPenalties[i];
      }
      state.finalScores = {
        SCORE_TEXT_SPAN.uma: action['uma'],
        SCORE_TEXT_SPAN.chomboScore: chomboPenalties,
        SCORE_TEXT_SPAN.adjustments: action['adjustments'],
        SCORE_TEXT_SPAN.finalDeltas: finalScores,
        SCORE_TEXT_SPAN.places: action['places']
      };

      state.putGame();
      Log.score('Final scores ${state.finalScores}');

      break;

    case STORE.showDeltas:
      state.changes = action['deltas'].toList(growable: false);
      break;

    case STORE.undoLastHand:
      if (state.scoreSheet.length < 2) return state; // nothing to do
      if (state.scoreSheet.last.type == SCORE_TEXT_SPAN.inProgress) {
        state.scoreSheet.removeLast();
      }
      Log.unusual(
          'User is deleting row: ' + state.scoreSheet.last.toMap().toString());

      if (state.scoreSheet.last.type == SCORE_TEXT_SPAN.deltas) {
        for (int i = 0; i < 4; i++) {
          state.scores[i] -= state.scoreSheet.last.scores[i];
        }
      }
      Log.score('Scores reversed: ' + state.scoreSheet.last.scores.toString());

      state.dealership = state.scoreSheet.last.dealership;
      state.handRedeals = state.scoreSheet.last.handRedeals;
      state.roundWind = state.scoreSheet.last.roundWind;
      state.honbaSticks = state.scoreSheet.last.honbaSticks;
      state.riichiSticks = state.scoreSheet.last.riichiSticks;
      state.scoreSheet.last.type = SCORE_TEXT_SPAN.inProgress;
      state.scoreSheet.last.scores = null;

      _resetHandCounters();

      break;
  }
  return state;
}

/// Initialise preferences, using defaults and values from disk
Future initPrefs() {
  return SharedPreferences.getInstance().then((SharedPreferences prefs) {
    _prefs = prefs;
    final Map prefsFromDisk = {
      'type': STORE.initPreferences,
      'preferences': {}
    };
    store.state.preferences.forEach((key, val) {
      dynamic test = _prefs.get(key);
      if (test != null && test != val) {
        prefsFromDisk['preferences'][key] = test;
      }
    });
    if (store.state.preferences['installationID'] == null &&
        !prefsFromDisk['preferences'].containsKey('installationID')) {
      prefsFromDisk['preferences']['installationID'] =
          DateTime.now().millisecondsSinceEpoch.toString();
      _prefs.setString(
          'installationID', prefsFromDisk['preferences']['installationID']);
    }
    if (prefsFromDisk['preferences'].length > 0) {
      store.dispatch(prefsFromDisk);
    }
  });
}

/// global variables are bad, mmmkay. But incredibly useful here.
final store = Store<GameState>(
  scoreReducer,
  initialState: GameState(),
);
