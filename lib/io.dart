/// Network interfacing with a server. This is all in flux right now,
/// as the API is being defined by exploratory experimentation.
/// So consider this file one giant TODO
/// It is crucial that all of this is non-blocking async, otherwise the app
/// just sits there frozen if useServer is true, and there's no network connection

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alice/alice.dart';

import 'store.dart';
import 'utils.dart';

const bool USING_IO = true;

class IO extends IOAbstract {
  static final IO _singleton = IO._privateConstructor();
  static Alice httpLogger = Alice(showNotification: false);

  IO._privateConstructor();

  factory IO() {
    return store.state.preferences['useServer'] ? _singleton : IOdummy();
  }

  static Future<http.StreamedResponse> sendDB(String filepath) async {
    http.MultipartRequest request =
        http.MultipartRequest('PUT', Uri.parse(_apiPath() + 'baddb'));
    request.files.add(await http.MultipartFile.fromPath('db', filepath));
    return await request.send();
  }

  static String _apiPath() => store.state.preferences['serverUrl'] + '/api/v0/';

  Map _handleResponse(http.Response response, {dynamic body}) {
    Map out = {'ok': response.statusCode >= 200 && response.statusCode < 400};

    if (out['ok']) {
      dynamic requestBody;
      if (body == null) {
        requestBody = (response.request as http.Request).body;
      } else {
        requestBody = body;
      }
      httpLogger.onHttpResponse(response, body: requestBody);

      dynamic responseBody;
      try {
        responseBody = jsonDecode(response.body.replaceAll('\n', ''));
      } catch (e) {
        responseBody = response.body;
      }
      out['body'] = responseBody;
    } else {
      out['body'] = null;
    }
    return out;
  }

  Future<Map> _get(String what, [String lastSeen]) async {
    return _handleResponse(await http.get(
      _apiPath() + what,
      headers: _headers(lastSeen),
    ));
  }

  Future<Map> _put(String what, Map<String, String> args,
      [String lastSeen]) async {
    return _handleResponse(await http.put(
      _apiPath() + what,
      headers: _headers(lastSeen),
      body: args,
    ), body: args);
    // encoding: defaults to UTF8
  }

  Map<String, String> _headers([String lastSeen]) {
    Map<String, String> headers = {};
    if (store.state.preferences['authToken'] != null &&
        store.state.preferences['authToken'].length > 0) {
      headers['Authorization'] =
          "Token " + store.state.preferences['authToken'];
    }
    if (lastSeen != null) {
      headers['If-Modified-Since'] = lastSeen;
    }
    return headers;
  }

  Future<Map> createPlayer(Map user) async {
    return (await _put('users/new', {'username': user['username']}))['body'] ??
        {'id': user['id']};
  }

  Future<bool> isConnected() async {
    /// True if server is reachable and we are authenticated; else False
    http.Response response = await http.head(_apiPath());
    httpLogger.onHttpResponse(response);
    return response.statusCode == 200;
  }

  Future<Map> updateGame(String gameID, Map<String, dynamic> gameIn) async {
    Map<String, String> gameOut = {};
    gameIn.forEach((String key, dynamic val) {
      gameOut[key] = val.toString();
    });
    return _put('games/$gameID', gameOut);
  }

  Future<List> listPlayers([String lastSeen]) async {
    Map out = await _get('users', lastSeen);
    GLOBAL.playersListUpdated = out['ok'];
    return out['body'] ?? [];
  }

  Future<Map<String, Map<String, dynamic>>> listGames(Map filter) async {
    // TODO
    return {};
  }

  dynamic getGame(String gameID) async {
    // TODO
    return {};
  }
}

class IOdummy extends IOAbstract {
  static final IOdummy _singleton = IOdummy._privateConstructor();

  IOdummy._privateConstructor();

  factory IOdummy() => _singleton;

  Future<bool> isConnected() async => false;

  Future<Map> updateGame(String gameID, dynamic options) async => {};

  Future<List> listPlayers() async => [];

  dynamic getGame(String gameID) async => {};

  Future<Map> createPlayer(Map<String, dynamic> user) async => user;
}

abstract class IOAbstract {
  Future<bool> isConnected();

  Future<Map> updateGame(String gameID, Map<String, dynamic> options) async =>
      {};

  Future<List> listPlayers();

  dynamic getGame(String gameID) async => {};

  Future<Map> createPlayer(Map<String, dynamic> user);
}
