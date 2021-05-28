import 'package:flutter/material.dart';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
//import 'package:flutter_redux/flutter_redux.dart';

import 'appbar.dart';
import 'utils.dart';

class PlayerButton extends StatefulWidget {
  final Alignment alignment;
  final int playerIndex;
  final String playerName;
  final String textOn;
  final String textOff;
  final String textPrompt;
  final Function callback;
  final List<bool>? buttonsStates;
  final bool enabled;

  PlayerButton({
    this.alignment = Alignment.bottomRight,
    this.playerIndex = -99,
    this.playerName = 'unknown',
    required this.callback,
    this.enabled = true,
    this.buttonsStates,
    required this.textOff,
    required this.textOn,
    required this.textPrompt,
  });

  @override
  PlayerButtonState createState() => PlayerButtonState();
}

class PlayerButtonState extends State<PlayerButton> {
  PlayerButtonState();

  @override
  Widget build(BuildContext context) {
    final double smaller = min(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    return Align(
      alignment: widget.alignment,
      child: RotatedBox(
        quarterTurns: (4 - widget.playerIndex) % 4,
        child: SizedBox(
          width: smaller * 0.3,
          height: smaller * 0.3,
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: widget.buttonsStates![widget.playerIndex]
                      ? Colors.red
                      : Colors.blue),
                  onPressed: widget.enabled
                      ? () => widget.callback(widget.playerIndex)
                      : null,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(widget.buttonsStates![widget.playerIndex]
                        ? widget.textOn
                        : widget.textOff),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 10,
                    bottom: 10,
                  ),
                  child: AutoSizeText(widget.textPrompt),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const List<bool> FOUR_FALSE = [false, false, false, false];

class WhoDidItScreen extends StatefulWidget {
  final int maxPlayersSelected;
  final int minPlayersSelected;
  final bool multipleRonWinners;
  final Function whenDone;
  final Map<String, String> displayStrings;
  final int disableButton;
  final List<bool> preSelected;

  WhoDidItScreen({
    this.minPlayersSelected = 1,
    this.maxPlayersSelected = 4,
    this.multipleRonWinners = false,
    this.disableButton = -1,
    this.preSelected = FOUR_FALSE,
    required this.whenDone,
    required this.displayStrings,
  });

  WhoDidItScreenState createState() => WhoDidItScreenState();
}

class WhoDidItScreenState extends State<WhoDidItScreen> {
  late List<bool> buttonOn;
  int nPressed = 0;

  @override
  void initState() {
    super.initState();
    buttonOn = widget.preSelected.toList(growable: false);
  }

  void wrapUpAndGo() {
    Navigator.pop(context);
    widget.whenDone(context, buttonOn);
  }

  bool buttonPressed(int playerIndex) {
    bool isPressed = !buttonOn[playerIndex];

    List<bool> tempCopy = List<bool>.from(buttonOn);
    tempCopy[playerIndex] = isPressed;

    nPressed = 0;
    tempCopy.forEach((bool el) => el ? nPressed++ : 0);

    if (widget.minPlayersSelected == 1 &&
        widget.maxPlayersSelected == 1 &&
        isPressed) {
      nPressed = 1;
      setState(() {
        for (int i = 0; i < 4; i++) {
          buttonOn[i] = (i == playerIndex);
        }
      });
    } else {
      setState(() {
        buttonOn[playerIndex] = isPressed;
      });
    }
    return isPressed;
  }

  @override
  Widget build(BuildContext context) {
    bool ready;

    ready = nPressed >= widget.minPlayersSelected &&
        nPressed <= widget.maxPlayersSelected;

    const List<Alignment> alignments = [
      Alignment.bottomCenter,
      Alignment.centerRight,
      Alignment.topCenter,
      Alignment.centerLeft,
    ];
    final List<Widget> stacked = [];

    for (int i = 0; i < 4; i++) {
      if (i != widget.disableButton) {
        stacked.add(PlayerButton(
          alignment: alignments[i],
          playerIndex: i,
          callback: buttonPressed,
          enabled: true,
          buttonsStates: buttonOn,
          textOff: widget.displayStrings['off']!,
          textOn: widget.displayStrings['on']!,
          textPrompt: widget.displayStrings['prompt']!,
        ));
      }
    }

    stacked.add(Align(
      alignment: Alignment.bottomRight,
      child: FractionallySizedBox(
        widthFactor: 0.2,
        heightFactor: 0.15,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(primary: Colors.green[900]),
          child: AutoSizeText(
            'Done',
            style: TextStyle(color: ready ? Colors.white : Colors.grey),
            minFontSize: 6,
            maxLines: 1,
          ),
          onPressed: ready ? () => wrapUpAndGo() : null,
        ),
      ),
    ));

    return Scaffold(
      appBar: MyAppBar(GLOBAL.getTitle(context, 'Who?')),
      body: Stack(
        children: stacked,
      ),
    );
  }
}
