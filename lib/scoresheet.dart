/// Displays the score sheet, but does not amend it in any way

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'appbar.dart';
import 'store.dart';
import 'utils.dart';

class ScoreSheetScreen extends StatelessWidget {
  Divider myDivider([double height = 3]) {
    return Divider(height: height, color: Colors.blueAccent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: myDrawer(context),
      appBar: MyAppBar(
          store.state.inProgress ? 'Scores on the doors' : 'Game over'),
      body: StoreConnector<Game, Map<String, dynamic>>(
        converter: (store) {
          return {
            'body': store.state.scoreSheet,
            'finalScores': store.state.finalScores,
            'scores': store.state.scores,
            'playerNames': store.state.playerNames,
            'inProgress': store.state.inProgress,
            'japaneseWinds': store.state.preferences['japaneseWinds'],
            'japaneseNumbers': store.state.preferences['japaneseNumbers'],
            'riichiSticks': store.state.riichiSticks,
            'startingPoints': store.state.ruleSet.startingPoints,
          };
        },
        builder: (BuildContext context, Map<String, dynamic> storeValues) {
          ScrollController _scrollController = ScrollController();
          bool alternateRows = true;
          List<Widget> rows = [];

          dynamic rowShade() {
            alternateRows = !alternateRows;
            return alternateRows ? Color.fromARGB(255, 20, 20, 20) : null;
          }

          Container makeCell(dynamic cell, SCORE_DISPLAY cellType, int column) {
            return Container(
              child: Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: RichText(
                      textAlign: TextAlign.right,
                      text: scoreFormat(cell, cellType,
                          japaneseNumbers: storeValues['japaneseNumbers'])),
                ),
                flex: column == 0 ? 2 : 1,
              ),
            );
          }

          void addRow(dynamic title, List<dynamic> cells, SCORE_DISPLAY rowType,
              {CrossAxisAlignment align}) {
            List<Widget> thisRow = [makeCell(title, rowType, 0)];
            for (int i = 0; i < 4; i++) {
              thisRow.add(makeCell(cells[i], rowType, i + 1));
            }
            rows.add(Container(
              child: Row(
                children: thisRow,
                crossAxisAlignment:
                    align == null ? CrossAxisAlignment.center : align,
              ),
              color: rowShade(),
              padding: EdgeInsets.only(
                bottom: 3,
                top: rowType == SCORE_DISPLAY.deltas ? 0 : 3,
              ),
            ));
          }

          addRow('', storeValues['playerNames'].toList(), SCORE_DISPLAY.totals,
              align: CrossAxisAlignment.end);

          addRow('start', List.filled(4, storeValues['startingPoints']),
              SCORE_DISPLAY.totals);

          int lastWindRound = -1;

          if (storeValues['body'].length > 0) {
            // hands of the game
            int rowIndex = 0;

            while (rowIndex < storeValues['body'].length &&
                [SCORE_DISPLAY.deltas, SCORE_DISPLAY.chombo]
                    .contains(storeValues['body'][rowIndex].type)) {
              ScoreRow row = storeValues['body'][rowIndex];
              if (lastWindRound != row.roundWind) {
                rows.add(myDivider());
              }
              lastWindRound = row.roundWind;
              String handName =
                  WINDS[storeValues['japaneseWinds'] ? 'japanese' : 'western']
                          [row.roundWind] +
                      (1 + row.dealership).toString() +
                      '-' +
                      row.handRedeals.toString();
              addRow(handName, row.scores.toList(), row.type);
              rowIndex += 1;
            }

            rows.add(myDivider());
            addRow(
                'Running Total', storeValues['scores'], SCORE_DISPLAY.totals);

            List<int> netScores = List(4);
            for (int i = 0; i < 4; i++) {
              netScores[i] =
                  storeValues['scores'][i] - storeValues['startingPoints'];
            }
            addRow('Net score', netScores, SCORE_DISPLAY.finalDeltas);

            if (!storeValues['inProgress'] &&
                storeValues['finalScores'].length > 0) {
              rows.add(myDivider());
              addRow('Uma', storeValues['finalScores'][SCORE_DISPLAY.uma],
                  SCORE_DISPLAY.finalDeltas);
              if (!storeValues['finalScores'][SCORE_DISPLAY.chomboScore]
                  .every((int chombo) => chombo == 0)) {
                addRow(
                    'Chombos',
                    storeValues['finalScores'][SCORE_DISPLAY.chomboScore],
                    SCORE_DISPLAY.chomboScore);
              }
              if (!store.state.ruleSet.riichiAbandonedAtEnd &&
                  storeValues['riichiSticks'] > 0) {
                addRow(
                    'Adjustments',
                    storeValues['finalScores'][SCORE_DISPLAY.adjustments],
                    SCORE_DISPLAY.adjustments);
              }
              rows.add(myDivider(30));
              addRow(
                  'Final score',
                  storeValues['finalScores'][SCORE_DISPLAY.finalDeltas],
                  SCORE_DISPLAY.finalDeltas);
              rows.add(myDivider(20));
              addRow(
                  '', storeValues['playerNames'].toList(), SCORE_DISPLAY.totals,
                  align: CrossAxisAlignment.start);
              if (store.state.ruleSet.riichiAbandonedAtEnd &&
                  storeValues['riichiSticks'] > 0) {
                rows.add(myDivider(20));
                addRow(
                    10 * storeValues['riichiSticks'],
                    ['Riichi', 'sticks', 'left', 'over'],
                    SCORE_DISPLAY.finalDeltas);
              }
              rows.add(myDivider(20));
              rows.add(InkWell(
                child: Text(
                  'New game',
                  style: TextStyle(fontSize: 20),
                ),
                onTap: () => Navigator.pushNamed(context, ROUTES.selectPlayers),
              ));
            }
          }

          ListView listView = ListView(
            controller: _scrollController,
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            children: rows,
            padding: EdgeInsets.all(5.0),
            addAutomaticKeepAlives: true,
          );

          Timer(Duration(milliseconds: 500), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });

          return WillPopScope(
            onWillPop: () async => store.state.inProgress,
            child: listView,
          );
        },
      ),
    );
  }
}
