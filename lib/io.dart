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
  static Duration defaultTimeout = Duration(seconds: 10);

  bool _authorised = false;

  bool get authorised => _authorised;

  IO._privateConstructor();

  factory IO() {
    return store.state.preferences['useServer'] ? _singleton : IOdummy();
  }

  static String _apiPath() => store.state.preferences['serverUrl'] + '/api/v0/';

  Future<Map> sendDB(String filepath) async {
    // TODO exception handling here
    http.MultipartRequest request =
        http.MultipartRequest('PUT', Uri.parse(_apiPath() + 'baddb'));
    request.files.add(await http.MultipartFile.fromPath('db', filepath));
    return _handleResponse(await request.send());
  }

  Map _handleResponse(http.BaseResponse response, {dynamic body}) {
    Map out = {'ok': response.statusCode >= 200
                    && response.statusCode < 400
                    && response.headers.containsKey('zaps')};

    dynamic requestBody = body ?? (response.request as http.Request).body;
    httpLogger.onHttpResponse(response, body: requestBody);

    if (out['ok']) {
      _authorised = true;
      dynamic responseBody;
      String bodyText;
      try {
        bodyText = (response is http.Response)
            ? response.body
            : (response as http.StreamedResponse).stream.bytesToString();
        responseBody = jsonDecode(bodyText.replaceAll('\n', ''));
      } catch (e) {
        responseBody = bodyText ?? 'Failed to get response body';
      }
      out['body'] = responseBody;
    } else {
      _authorised = false;
      out['body'] = null;
    }
    return out;
  }

  Future<Map> _get(String what, [String lastSeen]) async {
    Log.debug('IO get: ' + what);
    try {
      return _handleResponse(await http
          .get(
            _apiPath() + what,
            headers: _headers(lastSeen),
          )
          .timeout(defaultTimeout));
    } catch (e) {
      return {'ok': false};
    }
  }

  Future<Map> _post(String what, Map<String, String> args) async {
    Log.debug('IO post: ' + what + ': ' + args.toString());
    try {
      return _handleResponse(
          await http
              .post(
                _apiPath() + what,
                headers: _headers(),
                body: args,
              )
              .timeout(defaultTimeout),
          body: args);
    } catch (e) {
      return {'ok': false};
    }
    // encoding: defaults to UTF8
  }

  Future<Map> _put(String what, Map<String, String> args,
      [String lastSeen]) async {
    Log.debug('IO put: ' + what + ': ' + args.toString());
    try {
      return _handleResponse(
          await http
              .put(
                _apiPath() + what,
                headers: _headers(lastSeen),
                body: args,
              )
              .timeout(defaultTimeout),
          body: args);
    } catch (e) {
      return {'ok': false};
    }
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
    return (await _put('users/new', {'name': user['name']}))['body'] ??
        {'id': user['id']};
  }

  Future<bool> isConnected() async {
    /// True if server is reachable and contains our custom response header; else False
    try {
      http.Response response = await http.head(_apiPath(), headers: _headers());
      httpLogger.onHttpResponse(response);
      _authorised = response.statusCode == 200 && response.headers.containsKey('zaps');
      return ([200, 401, 403].contains(response.statusCode) && response.headers.containsKey('zaps'));
    } catch (e) {
      _authorised = false;
      return false;
    }
  }

  Future<Map> updateGame(String gameID, Map<String, dynamic> gameIn) async {
    Map<String, String> gameOut = {};
    gameIn.forEach((String key, dynamic val) {
      gameOut[key] = val.toString();
    });
    return _put('games/$gameID', gameOut);
  }

  Future<List> listPlayers([String lastSeen]) async {
    if (!await isConnected()) {
      return [];
    }
    Map out = await _get('users', lastSeen);
    GLOBAL.playersListUpdated = out['ok'];
    return (out['body'] is List) ? out['body'] : [];
  }

  Future<Map> checkPin(int userID, String pin) async {
    return await _post(
      'users/$userID/pin',
      {'pin': pin},
    );
  }

  Future<Map> login(int userID, String password) async {
    Map out = await _post(
      'login',
      {'id': userID.toString(), 'password': password},
    );
    _authorised = out['ok'];
    return out;
  }

  void sendDoraIndicator(Map<String, String> indicator) async {
    _put('doraIndicator', indicator,);
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

  bool get authorised => false;

  Future<bool> isConnected() async => false;

  Future<Map> updateGame(String gameID, dynamic options) async => {};

  Future<List> listPlayers() async => [];

  dynamic getGame(String gameID) async => {};

  Future<Map> checkPin(int userID, String pin) async => {};

  Future<Map> login(int userID, String password) async => {};

  Future<Map> createPlayer(Map<String, dynamic> user) async => user;

  void sendDoraIndicator(Map<String, String> indicator) async => {};
}

abstract class IOAbstract {
  bool get authorised;

  Future<bool> isConnected();

  Future<Map> updateGame(String gameID, Map<String, dynamic> options) async =>
      {};

  Future<List> listPlayers();

  dynamic getGame(String gameID) async => {};

  Future<Map> checkPin(int userID, String pin) async => {};

  Future<Map> login(int userID, String password) async => {};

  Future<Map> createPlayer(Map<String, dynamic> user);

  void sendDoraIndicator(Map<String, String> indicator) async => {};
}
