import 'dart:async';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'appbar.dart';
import 'gamedb.dart';
import 'store.dart';
import 'utils.dart';

class GamesListPage extends StatefulWidget {
  final bool liveGames;

  GamesListPage(this.liveGames);

  @override
  GamesListPageState createState() => GamesListPageState();
}

class GamesListPageState extends State<GamesListPage> {
  ScrollController _controller;
  final _db = GameDB();
  final Map<bool, List<String>> _gameIDs = {true: [], false: []};
  final Map<bool, List<String>> _summaries = {true: [], false: []};

  bool _isLoading = false;
  bool _liveGames = true;
  static const int _pageSize = 20;

  _scrollListener() {
    if (_controller.position.pixels == _controller.position.maxScrollExtent) {
      _getNextPage(scroll: true);
    }
  }

  void _getNextPage({bool scroll = false}) async {
    bool thisSetIsLive = _liveGames;
    if (_isLoading) {
      // TODO prevent db calls colliding
      Log.unusual('DB lookup collision in games > _getNextPage');
    }
    _isLoading = true;
    _db
        .list(
            live: thisSetIsLive,
            limit: _pageSize,
            offset: scroll ? _gameIDs[thisSetIsLive].length : 0)
        .then((List<Map<String, dynamic>> newItems) {
      setState(() {
        _isLoading = false;
        newItems.forEach((Map<String, dynamic> item) {
          if (!_gameIDs[thisSetIsLive].contains(item['gameID'])) {
            _gameIDs[thisSetIsLive].add(item['gameID']);
            _summaries[thisSetIsLive].add(item['summary']);
          }
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _liveGames = widget.liveGames;
    _controller = ScrollController()..addListener(_scrollListener);
    // pause to ensure everything's built before getting data
    Timer(Duration(milliseconds: 400), _getNextPage);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  void _loadGame(String gameID) async {
    GameDB().get(gameID).then((String json) {
      store.dispatch({'type': STORE.restoreFromJSON, 'json': json});
      Navigator.pushNamed(
          context, store.state.inProgress ? ROUTES.hands : ROUTES.scoreSheet,
          arguments: {'headline': 'Game restored'});
    });
  }

  void setFilter(newFilter) {
    setState(() => _liveGames = newFilter);
    if (_gameIDs[_liveGames].isEmpty) {
      _getNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar('Previous games'),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 15,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _gameIDs[_liveGames].length,
              itemBuilder: (context, index) {
                bool isLoaded =
                    _gameIDs[_liveGames][index] == store.state.gameID;
                return Card(
                    child: ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    if (!isLoaded) {
                      _loadGame(_gameIDs[_liveGames][index]);
                    }
                  },
                  title: AutoSizeText(
                    (isLoaded ? '(loaded) ' : '') +
                        _summaries[_liveGames][index],
                    maxLines: 3,
                  ),
                ));
              },
              //separatorBuilder: (context, _) => Divider(),
              controller: _controller,
              scrollDirection: Axis.vertical,
              padding: EdgeInsets.all(5.0),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: <Widget>[
                BigButton(
                    activated: !_liveGames,
                    onPressed: () => setFilter(false),
                    text: 'Finished'),
                BigButton(
                  activated: _liveGames,
                  onPressed: () => setFilter(true),
                  text: 'Ongoing',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
