/// Network interfacing with a server
///
///

import 'package:http/http.dart' as http;
import 'package:alice/alice.dart';

class IOinterface {
  static final IOinterface _singleton = IOinterface._privateConstructor();

  // this is a map, as we only ever want to send the latest version of a game
  final Map<String, dynamic> _gamesStackAPI = {};

  // a normal pipeline for other API calls, to be handled in order
  final List<dynamic> _playersStackAPI = [];
  final http.Client _client = http.Client();
  static Alice httplogger = Alice(showNotification: false);

  void sendOne() async {
    /*
    Client.push();
    httplogger.onHttpResponse(response);
    */
  }

  IOinterface._privateConstructor();

  factory IOinterface() {
    return _singleton;
  }

  void updateGame(String gameID, dynamic options) async {
    _gamesStackAPI[gameID] = options;
  }

/*  Future<List<Map<String, dynamic>>> listPlayers() async {

    return requests.get(
      url=self.__api_path + 'users',
      headers={'Authorization': 'Token %s' % self.__token},
    )
  }*/

  dynamic getGame(String gameID) async {
    return {};
  }

  void createPlayer() async {}
}
