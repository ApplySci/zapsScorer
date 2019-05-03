/// Network interfacing with a pantheon server
///
///

// Pantheon mobile SPA seems to do all its I/O in:
// https://github.com/MahjongPantheon/pantheon/blob/master/Tyr/src/app/services/riichiApi.ts

class IOinterface {
  static final IOinterface _singleton = IOinterface._privateConstructor();

  final Map<String, dynamic> _gamesStackAPI = {};

  final List<dynamic> _playersStackAPI = []; // stack for other API calls

  void sendOne() async {
    //
  }

  IOinterface._privateConstructor();

  factory IOinterface() {
    return _singleton;
  }

  void updateGame(String gameID, dynamic options) async {
    _gamesStackAPI[gameID] = options;
  }

  dynamic getGame(String gameID) async {
    return {};
  }

  Future<Map<String, dynamic>> listPlayers() async {
    return {};
  }

  void createPlayer() async {

  }
}
