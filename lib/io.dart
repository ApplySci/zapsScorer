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

class IO {
  static final IO _singleton = IO._privateConstructor();
  static Alice httpLogger = Alice(showNotification: false);
  static Duration defaultTimeout = Duration(seconds: 10);

  bool _authorised = false;
  bool newlyAuthorised = false;

  bool get authorised => _authorised;

  IO._privateConstructor();

  factory IO() {
    return _singleton;
  }

  static Uri _apiPath(String suffix) =>
      Uri.parse(store.state.preferences['serverUrl'] + '/api/v0/' + suffix);

  Future<Map> sendDB(String filepath) async {
    if (!store.state.preferences['useServer']) return {};
    // TODO exception handling here
    http.MultipartRequest request =
        http.MultipartRequest('PUT', _apiPath('baddb'));
    request.files.add(await http.MultipartFile.fromPath('db', filepath));
    return _handleResponse(await request.send());
  }

  Future<Map> _handleResponse(http.BaseResponse response,
      {dynamic body}) async {
    Map out = {
      'ok': response.statusCode >= 200 &&
          response.statusCode < 400 &&
          response.headers.containsKey('zaps')
    };

    dynamic requestBody = body ?? (response.request as http.Request).body;
    httpLogger.onHttpResponse(response as http.Response, body: requestBody);

    if (out['ok']) {
      _authorised = true;
      dynamic responseBody;
      String? bodyText;
      try {
        bodyText = (response is http.Response)
            ? response.body
            : await (response as http.StreamedResponse).stream.bytesToString();
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

  Future<Map> _get(String what, [String? lastSeen]) async {
    if (!store.state.preferences['useServer']) return {};
    Log.debug('IO get: ' + what);
    try {
      return _handleResponse(await http
          .get(
            _apiPath(what),
            headers: _headers(lastSeen),
          )
          .timeout(defaultTimeout));
    } catch (e) {
      return {'ok': false};
    }
  }

  Future<Map> _post(String what, Map<String, String> args) async {
    if (!store.state.preferences['useServer']) return {};
    Log.debug('IO post: ' + what + ': ' + args.toString());
    try {
      return _handleResponse(
          await http
              .post(
                _apiPath(what),
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
      [String? lastSeen]) async {
    if (!store.state.preferences['useServer']) return {};
    Log.debug('IO put: ' + what + ': ' + args.toString());
    try {
      return _handleResponse(
          await http
              .put(
                _apiPath(what),
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

  Map<String, String> _headers([String? lastSeen]) {
    if (!store.state.preferences['useServer']) return {};
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

  Future<Map> createPlayer(Map<String, String> user) async {
    return (await _put('users/new', user))['body'] ?? {'id': user['id']};
  }

  Future<bool> isConnected() async {
    if (!store.state.preferences['useServer']) return false;

    /// True if server is reachable and contains our custom response header; else False
    try {
      http.Response response =
          await http.head(_apiPath(''), headers: _headers());
      httpLogger.onHttpResponse(response);
      bool isAuthorised =
          response.statusCode == 200 && response.headers.containsKey('zaps');
      newlyAuthorised = isAuthorised && !_authorised;
      // TODO newly authorised, so upload any stuff that's been waiting
      _authorised = isAuthorised;
      return (response.statusCode < 400 &&
          response.headers.containsKey('zaps'));
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

  Future<List> listPlayers([String? lastSeen]) async {
    if (!store.state.preferences['useServer']) return [];
    Map out = await _get('users', lastSeen);
    GLOBAL.playersListUpdated = out['ok'];
    return (out['body'] is List) ? out['body'] : [];
  }

  Future<Map> checkPin(int userID, String pin) async {
    if (!store.state.preferences['useServer']) return {};
    return await _post(
      'users/$userID/pin',
      {'pin': pin},
    );
  }

  Future<Map> login(int userID, String password) async {
    if (!store.state.preferences['useServer']) return {};
    Map out = await _post(
      'login',
      {'id': userID.toString(), 'password': password},
    );
    if (_authorised) {
      await store.dispatch({
        'type': STORE.setPreferences,
        'preferences': {'authToken': out['body']['token']}
      });
    }
    return out;
  }

  void sendDoraIndicator(Map<String, String> indicator) async {
    if (!store.state.preferences['useServer']) return;
    _put(
      'doraIndicator',
      indicator,
    );
  }

  Future<Map<String, Map<String, dynamic>>> listGames(Map filter) async {
    if (!store.state.preferences['useServer']) return {};
    // TODO
    return {};
  }

  dynamic getGame(String gameID) async {
    if (!store.state.preferences['useServer']) return {};
    // TODO
    return {};
  }
}
