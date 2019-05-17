/// Displays the main game screen

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/animation.dart';

import 'appbar.dart';
import 'gamedb.dart';
import 'gameflow.dart';
import 'store.dart';
import 'utils.dart';

const int gameStateBoxDragDrop = 4;

class GamePage extends StatefulWidget {
  @override
  GamePageState createState() => GamePageState();
}

class GamePageState extends State<GamePage> {
  WindsRotator windsRotator;

  @override
  void initState() {
    super.initState();
    windsRotator = WindsRotator();
  }

  @override
  Widget build(BuildContext context) {
    if (!GameDB.handledStart) {
      GameDB.handledStart = true;
      // pause to ensure this screen is built before going to the welcome screen, on first startup
      Timer(Duration(milliseconds: 100),
          () => Navigator.pushNamed(context, ROUTES.welcome));
      return Container();
    }

    return StoreConnector<Game, Map>(converter: (store) {
      // force rebuild whenever there's a change in the number of hands
      return {'numberOfHands': store.state.scoreSheet.length};
    }, builder: (BuildContext context, Map storeValues) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          drawer: myDrawer(context),
          appBar: MyAppBar(getTitle(context, 'Ready for next hand')),
          body: DefaultTextStyle(
            style: TextStyle(
              fontSize: 35.0,
              color: Colors.yellow,
              decoration: null,
            ),
            child: Stack(children: [
              PlayerBox(alignment: Alignment.bottomCenter, playerIndex: 0),
              PlayerBox(alignment: Alignment.centerRight, playerIndex: 1),
              PlayerBox(alignment: Alignment.topCenter, playerIndex: 2),
              PlayerBox(alignment: Alignment.centerLeft, playerIndex: 3),
              Align(
                alignment: Alignment.center,
                child: GameStateBox(),
              ),
              Align(
                alignment: Alignment.topRight,
                child: FractionallySizedBox(
                  widthFactor: 0.2,
                  alignment: Alignment.bottomLeft,
                  child: RaisedButton(
                    child: AutoSizeText('Draw'),
                    onPressed: () => Navigator.pushNamed(context, ROUTES.draw),
                  ),
                ),
              ),
              Align(alignment: Alignment.center, child: windsRotator),
              EndOfGameOverlay(),
              Align(
                alignment: Alignment.bottomLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.2,
                  alignment: Alignment.bottomLeft,
                  child: RaisedButton(
                    child: AutoSizeText(
                      'Score sheet',
                      maxLines: 2,
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, ROUTES.scoreSheet),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }
}

/// The box in the centre of the screen
class GameStateBox extends StatefulWidget {
  GameStateBox();

  @override
  GameStateBoxState createState() => GameStateBoxState();
}

class GameStateBoxState extends State<GameStateBox> {
  @override
  Widget build(BuildContext context) {
    final double smaller = min(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    return StoreConnector<Game, Map<String, dynamic>>(
      converter: (store) {
        return {
          'japaneseWinds': store.state.preferences['japaneseWinds'],
          'roundWind': store.state.roundWind,
          'handRedeals': store.state.handRedeals,
          'riichiSticks': store.state.riichiSticks,
          'dealership': store.state.dealership,
          'honbaSticks': store.state.honbaSticks,
        };
      },
      builder: (BuildContext context, Map<String, dynamic> storeValues) {
        return Draggable<int>(
          data: gameStateBoxDragDrop,
          feedback: TemboBunch(),
          childWhenDragging: AutoSizeText('Tsumo!'),
          child: TemboDragTarget(
            playerIndex: gameStateBoxDragDrop,
            child: SizedBox(
              width: smaller * 0.3,
              height: smaller * 0.3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: AutoSizeText(WINDS[storeValues['japaneseWinds']
                            ? 'japanese'
                            : 'western'][storeValues['roundWind']] +
                        " " +
                        (storeValues['dealership'] + 1).toString() +
                        '-' +
                        storeValues['handRedeals'].toString()),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TemboStick(color: Colors.blue),
                        ),
                        Expanded(
                          flex: 2,
                          child: AutoSizeText(
                              storeValues['riichiSticks'].toString()),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(),
                        ),
                        Expanded(
                          flex: 1,
                          child: HonbaStick(),
                        ),
                        Expanded(
                          flex: 2,
                          child: AutoSizeText(
                              storeValues['honbaSticks'].toString()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PlayerBox extends StatefulWidget {
  final Alignment alignment;
  final int playerIndex;

  PlayerBox({this.alignment = Alignment.bottomLeft, this.playerIndex = -99});

  @override
  PlayerBoxState createState() => PlayerBoxState();
}

class PlayerBoxState extends State<PlayerBox> {
  String title = 'Here';

  @override
  Widget build(BuildContext context) {
    final double smaller = min(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    return Align(
      alignment: widget.alignment,
      child: RotatedBox(
        quarterTurns: (4 - widget.playerIndex) % 4,
        child: SizedBox(
          width: smaller * 0.4,
          height: smaller * 0.3,
          child: TemboDragTarget(
            playerIndex: widget.playerIndex,
            child:
                StoreConnector<Game, Map<String, dynamic>>(converter: (store) {
              return {
                'dealership': store.state.dealership,
                'japaneseWinds': store.state.preferences['japaneseWinds'],
                'japaneseNumbers': store.state.preferences['japaneseNumbers'],
                'score': store.state.scores[widget.playerIndex],
                'inRiichi': store.state.inRiichi[widget.playerIndex],
                'name': store.state.players[widget.playerIndex]['name'],
              };
            }, builder: (BuildContext context, Map storeValues) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () async {
                        bool ok = !storeValues['inRiichi'];
                        if (!ok) {
                          ok = await yesNoDialog(context,
                              prompt: 'Really remove riichi?',
                              trueText: "Yes, I'm not really in riichi",
                              falseText: "No, keep me in riichi");
                        }
                        if (ok) {
                          store.dispatch({
                            'type': STORE.setRiichi,
                            'player': widget.playerIndex,
                            'inRiichi': !storeValues['inRiichi'],
                            'log': true,
                          });
                        }
                      },
                      child: storeValues['inRiichi']
                          ? TemboStick(
                              color: Colors.blue,
                            )
                          : TemboStick(
                              color: Colors.grey[700],
                            ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Draggable<int>(
                      data: widget.playerIndex,
                      maxSimultaneousDrags: 1,
                      feedback: TemboBunch(),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Row(
                              children: [
                                AutoSizeText(WINDS[storeValues['japaneseWinds']
                                        ? 'japanese'
                                        : 'western'][(widget.playerIndex -
                                            storeValues['dealership']) %
                                        4] +
                                    " "),
                                AutoSizeText.rich(
                                  TextSpan(
                                    text: scoreFormat(storeValues['score'],
                                        SCORE_DISPLAY.plainTotals,
                                        japaneseNumbers:
                                            storeValues['japaneseWinds']),
                                    children: [
                                      TextSpan(
                                        text: '00',
                                        style: DefaultTextStyle.of(context)
                                            .style
                                            .apply(fontSizeFactor: 0.5),
                                      ),
                                    ],
                                  ),
//                                  maxFontSize: 100,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: store.state.scoreSheet.length < 2 ? 3 : 1,
                            child: AutoSizeText(
                              storeValues['name'],
                              maxFontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      childWhenDragging: AutoSizeText(
                        'Oh Noes!',
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class TemboDragTarget extends StatefulWidget {
  final Widget child;
  final int playerIndex;

  TemboDragTarget({this.child, this.playerIndex = -99});

  @override
  TemboDragTargetState createState() => TemboDragTargetState();
}

class TemboDragTargetState extends State<TemboDragTarget> {
  bool draggedOver = false;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<Game, void Function(int)>(
      converter: (store) {
        return (int loser) {
          if (widget.playerIndex == gameStateBoxDragDrop) {
            store.dispatch({
              'type': STORE.setResult,
              'result': {
                'result': RESULT.ron,
                'losers': loser,
              },
            });
            return Navigator.pushNamed(context, ROUTES.multipleRon);
          }

          Map result = {'winners': widget.playerIndex};
          String headline =
              ' by ' + store.state.players[widget.playerIndex]['name'];

          if (loser == gameStateBoxDragDrop) {
            result['result'] = RESULT.tsumo;
            headline = 'Tsumo' + headline;
          } else {
            result['result'] = RESULT.ron;
            result['losers'] = loser;
            headline =
                'Ron' + headline + ' off ' + store.state.players[loser]['name'];
          }

          Log.score(headline);
          store.dispatch({'type': STORE.setResult, 'result': result});
          Scoring.getHanFu(context, {'headline': headline});
        };
      },
      builder: (context, callback) {
        return DragTarget<int>(
          onAccept: (data) {
            // don't need to setState, because it will repaint anyway
            draggedOver = false;
            callback(data);
          },
          onLeave: (data) {
            draggedOver = false;
          },
          onWillAccept: (data) {
            if (data == widget.playerIndex ||
                (widget.playerIndex == gameStateBoxDragDrop &&
                    !store.state.ruleSet.multipleRons)) {
              return false;
            }
            // don't need to setState, because it will repaint anyway
            draggedOver = true;
            return true;
          },
          builder: (
            BuildContext context,
            List<dynamic> accepted,
            List<dynamic> rejected,
          ) {
            return Container(
              decoration: draggedOver
                  ? BoxDecoration(
                      border: Border.all(width: 2.0, color: Colors.white),
                    )
                  : null,
              child: widget.child,
            );
          },
        );
      },
    );
  }
}

class TemboStick extends StatelessWidget {
  final Color color;
  final double angle, originX, originY;
  final double width;

  TemboStick({
    this.color = Colors.white,
    this.angle = 0,
    this.originX = 30,
    this.originY = 0,
    this.width = 35,
  });

  @override
  Widget build(BuildContext context) {
    final Widget spotlessStick = Stick(color, width);

    return this.angle == 0
        ? Stack(children: [
            Center(
              child: spotlessStick,
            ),
            Center(
              child: Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ])
        : Transform.rotate(
            angle: this.angle,
            origin: Offset(this.originX, this.originY),
            child: spotlessStick,
          );
  }
}

class TemboBunch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      TemboStick(color: Colors.green, angle: pi / 2, width: 15),
      TemboStick(color: Colors.white, angle: 5 * pi / 8, width: 15),
      TemboStick(color: Colors.blue, angle: 3 * pi / 8, width: 15),
    ]);
  }
}

class WindsRotator extends StatefulWidget {
  final bool showDeltas;

  WindsRotator({this.showDeltas});

  @override
  WindsRotatorState createState() => WindsRotatorState();
}

class WindsRotatorState extends State<WindsRotator>
    with SingleTickerProviderStateMixin {
  Animation<double> _animation;
  AnimationController _animationController;
  Tween<double> _tween;
  bool _visible;
  FourWindDiscs _discs;
  FourDeltaOverlays _deltas;

  @override
  void initState() {
    super.initState();
    _visible = false;
    _deltas = FourDeltaOverlays();
    _discs = FourWindDiscs();
    _animationController = AnimationController(
        duration: Duration(milliseconds: 3500), vsync: this);
    _tween = Tween(begin: 1.0 * store.state.dealership, end: -1);
    _animation = _tween.animate(_animationController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((AnimationStatus status) {
        setState(() {
          _visible = (status == AnimationStatus.reverse ||
              status == AnimationStatus.forward);
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<Game, Map<String, bool>>(
      converter: (store) => {
            'endOfHand': store.state.endOfHand,
            'endOfGame': store.state.endOfGame
          },
      builder: (BuildContext context, Map<String, bool> endFlags) {
        if (endFlags['endOfHand']) {
          // timer to ensure build is finished before doing the below
          Timer(Duration(milliseconds: 100), () {
            store.dispatch({'type': STORE.endOfHand, 'value': false});
            move();
          });
        }
        return IgnorePointer(
          child: Stack(
            children: [
              Opacity(
                  opacity: _visible || endFlags['endOfGame'] ? 1 : 0,
                  child: _deltas),
              Opacity(
                opacity: _visible && !endFlags['endOfHand'] ? 1 : 0,
                child: Align(
                  alignment: Alignment.center,
                  child: Transform.rotate(
                      angle: -_animation.value * pi / 2, child: _discs),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void move() {
    double to = 1.0 * store.state.rotateWindsTo;
    if (_tween.end == -1) {
      _tween.end = 1.0 * store.state.dealership;
    }
    _tween.begin = (to < _tween.end - 2) ? _tween.end - 4 : _tween.end;
    _tween.end = store.state.endOfHand ? _tween.begin : to;
    // wait to ensure the animation doesn't collide with the first build of page
    Timer(Duration(milliseconds: 100), () {
      _visible = true;
      _animationController.reset();
      _animationController.forward();
    });
  }
}

class FourWindDiscs extends StatelessWidget {
  Widget build(BuildContext context) {
    final double smaller = min(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    return SizedBox(
      height: smaller * 0.5,
      width: smaller * 0.5,
      child: StoreConnector<Game, bool>(
        converter: (store) {
          return store.state.preferences['japaneseWinds'];
        },
        builder: (BuildContext context, bool japaneseWinds) {
          String winds = WINDS[japaneseWinds ? 'japanese' : 'western'];
          return Stack(
            children: [
              Align(
                  alignment: Alignment.bottomCenter, child: WindDisc(winds[0])),
              Align(
                  alignment: Alignment.centerRight,
                  child:
                      RotatedBox(quarterTurns: 3, child: WindDisc(winds[1]))),
              Align(
                  alignment: Alignment.topCenter,
                  child:
                      RotatedBox(quarterTurns: 2, child: WindDisc(winds[2]))),
              Align(
                  alignment: Alignment.centerLeft,
                  child:
                      RotatedBox(quarterTurns: 1, child: WindDisc(winds[3]))),
            ],
          );
        },
      ),
    );
  }
}

class WindDisc extends StatelessWidget {
  final String wind;

  WindDisc(this.wind);

  @override
  Widget build(BuildContext context) {
    final double smaller = min(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    return Container(
      width: smaller / 10.0,
      height: smaller / 10.0,
      child: Align(
        child: AutoSizeText(
          wind,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          maxFontSize: 20,
        ),
      ),
      decoration: new BoxDecoration(
        color: Colors.orange,
        shape: BoxShape.circle,
      ),
    );
  }
}

class HonbaStick extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      Align(
        alignment: Alignment.topLeft,
        child: TemboStick(color: Colors.white),
      ),
    ];

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 2; j++) {
        children.add(Positioned(
          left: 2 + j * 8.0,
          top: 16.0 + i * 4.0,
          width: 3,
          height: 3,
          child: Container(
            color: Colors.black,
          ),
        ));
      }
    }

    return Stack(children: children);
  }
}

class Stick extends StatelessWidget {
  final Color color;
  final double thickness;

  Stick(this.color, [this.thickness = 35.0]);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120.0,
      height: thickness,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(thickness / 3)),
      ),
    );
  }
}

class FourDeltaOverlays extends StatelessWidget {
  final List<DeltaOverlay> overlays = [
    DeltaOverlay(),
    DeltaOverlay(),
    DeltaOverlay(),
    DeltaOverlay(),
  ];

  @override
  Widget build(BuildContext context) {
    return StoreConnector<Game, List<int>>(
      converter: (store) => List<int>.from(store.state.changes),
      builder: (BuildContext context, List<int> changes) {
        for (int i = 0; i < 4; i++) {
          overlays[i].setScores(changes[i], changes[i + 4]);
        }
        return Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: overlays[0],
            ),
            Align(
                alignment: Alignment.centerRight,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: overlays[1],
                )),
            Align(
                alignment: Alignment.topCenter,
                child: RotatedBox(
                  quarterTurns: 2,
                  child: overlays[2],
                )),
            Align(
                alignment: Alignment.centerLeft,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: overlays[3],
                )),
          ],
        );
      },
    );
  }
}

class DeltaOverlay extends StatefulWidget {
  final DeltaOverlayState state = DeltaOverlayState();

  @override
  DeltaOverlayState createState() => state;

  void setScores(int delta, int riichiDelta) {
    state.setScores(delta, riichiDelta);
  }
}

class DeltaOverlayState extends State<DeltaOverlay> {
  int delta = 0;
  int riichiDelta = 0;

  void setScores(int newDelta, int newRiichiDelta) {
    delta = newDelta;
    riichiDelta = newRiichiDelta;
  }

  Widget build(BuildContext context) {
    if (delta == 0 && riichiDelta == 0) {
      return Container();
    }
    final double smaller = min(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    return SizedBox(
      width: smaller * 0.4,
      height: smaller * 0.25,
      child: Container(
        color: Colors.blue[900],
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(flex: 1, child: Container()),
                  Expanded(
                    flex: 8,
                    child: AutoSizeText(
                      scoreFormat(delta, SCORE_DISPLAY.plainDeltas,
                          japaneseNumbers:
                              store.state.preferences['japaneseNumbers']),
                      style: TextStyle(color: Colors.white),
                      maxFontSize: 30,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: riichiDelta == 0
                  ? Container()
                  : Row(
                      children: [
                        Expanded(flex: 1, child: TemboStick(color: Colors.red)),
                        Expanded(
                          flex: 8,
                          child: AutoSizeText(
                            scoreFormat(
                                riichiDelta * 10, SCORE_DISPLAY.plainDeltas,
                                japaneseNumbers:
                                    store.state.preferences['japaneseNumbers']),
                            style: TextStyle(color: Colors.white),
                            maxFontSize: 30,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class EndOfGameOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<Game, bool>(
      converter: (store) => store.state.endOfGame,
      builder: (BuildContext context, bool visible) {
        return Opacity(
          opacity: visible ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !visible,
            child: Stack(
              children: [
                AbsorbPointer(
                  absorbing: visible,
                  child: Container(
                    color: Color.fromARGB(30, 50, 50, 50),
                    child: FractionallySizedBox(
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: FinishGameNowChoice(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FinishGameNowChoice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double smaller = min(
        MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);
    return SizedBox(
      height: 0.5 * smaller,
      width: 0.5 * smaller,
      child: Container(
        color: Colors.red,
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: AutoSizeText(
                "End of the game. You can view the scoresheet using the " +
                    "button at the bottom-left of the screen",
                style: TextStyle(color: Colors.white),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: RaisedButton(
                      child: Text('Undo Last Hand'),
                      onPressed: () async {
                        if (await confirmUndoLastHand(context)) {
                          store.dispatch(
                              {'type': STORE.endOfGame, 'value': false});
                          Scoring.undoLastHand();
                        }
                      },
                    ),
                  ),
                  Expanded(flex: 1, child: Container()),
                  Expanded(
                    flex: 1,
                    child: RaisedButton(
                      child: Text('Finish game'),
                      onPressed: () {
                        store.dispatch(
                            {'type': STORE.endOfHand, 'value': false});
                        Scoring.finishGame(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
