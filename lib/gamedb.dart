/// handle sqlite database of games
///
///
///

import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'io.dart';
import 'utils.dart';

class GameDB {
  static const int _version = 1;
  static Directory _dbDir;
  static Database _db;
  static Map<String, dynamic> lastGame;
  static final GameDB _singleton = GameDB._privateConstructor();
  static bool handledStart = false;

  GameDB._privateConstructor();

  factory GameDB() {
    return _singleton;
  }

  Future setLastGame() async {
    List<Map<String, dynamic>> results = await _db.query(
      'Games',
      where: 'live = 1',
      columns: ['gameID', 'summary', 'json'],
      orderBy: 'summary DESC',
      limit: 1,
    );
    lastGame = (results.length == 1) ? results[0] : null;
  }

  Future _createTables([Database db]) async {
    Batch batch = (_db ?? db).batch();
    batch.execute("CREATE TABLE Games ("
        "gameID TEXT PRIMARY KEY ON CONFLICT REPLACE, "
        "live BOOL, "
        "summary TEXT NOT NULL, "
        "json TEXT NOT NULL, "
        "lastUpdated TEXT "
        ") WITHOUT ROWID;");

    batch.execute("CREATE INDEX live_idx ON Games (live, summary DESC);");

    batch.execute(
        """CREATE TRIGGER lastGameUpdate AFTER UPDATE OF gameID, json, live, summary ON Games
    BEGIN
    UPDATE Games SET lastUpdated=CURRENT_TIMESTAMP WHERE id=id;
    END;""");

    batch.execute("CREATE TABLE Users ("
        "id INT PRIMARY KEY ON CONFLICT REPLACE, "
        "name TEXT NOT NULL,"
        "lastUpdated TEXT"
        ") WITHOUT ROWID;");

    // will be used for if-modified-since header
    batch.execute("CREATE TABLE Updates ("
        "what TEXT PRIMARY KEY ON CONFLICT REPLACE, "
        "utc TEXT) WITHOUT ROWID;");

    batch.execute(
        """CREATE TRIGGER lastUserUpdate AFTER UPDATE OF id, name ON Users
    BEGIN
    UPDATE Users SET lastUpdated=CURRENT_TIMESTAMP WHERE id=id;
    END;""");

    /*List results = */
    await batch.commit(); // TODO check results
    updatePlayersFromServer();
  }

  void addUser(Map<String, dynamic> user, {updateServer: false}) async {
    if (updateServer) {
      user = await IO().createPlayer(user);
    }
    _db.insert('Users', {'id': user['id'], 'name': user['name']},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future rebuildDatabase() async {
    try {
      await _db.close();
    } catch (e) {}
    await File(p.join(_dbDir.path, "games.db")).delete();
    await initDB();
  }

  Future<String> getLastUpdated(String table) async {
    List results = await _db.query(
      'Updates',
      where: 'what = ?',
      whereArgs: [table],
      columns: ['utc'],
    );
    return results?.length == 1 ? results[0]['utc'] : null;
  }

  Future setLastUpdated(String table, DateTime utc, [Batch batch]) async {
    if (batch == null) {
      return _db.insert('Updates', {'utc': HttpDate.format(utc), 'what': table},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      return batch.insert(
          'Updates', {'utc': HttpDate.format(utc), 'what': table},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future initDB() async {
    _dbDir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(p.join(_dbDir.path, "games.db"),
        version: _version,
        onOpen: (Database db) {},
        onUpgrade: (Database db, int oldVersion, int newVersion) {
          if (oldVersion < 2) {}
        },
        onCreate: (Database db, int version) async => await _createTables(db));
  }

  Future<Map> putGame(Map<String, dynamic> record) async {
    record['lastUpdated'] = DateTime.now().millisecondsSinceEpoch;
    _db.insert('Games', record, conflictAlgorithm: ConflictAlgorithm.replace);
    return await IO().updateGame(record['gameID'], record);
  }

  void deleteGame(String gameID) {
    _db.delete('Games', where: 'gameID = ?', whereArgs: [gameID]);
  }

  Future<String> getGame(String gameID) async {
    List<Map<String, dynamic>> out = await _db.query(
      'Games',
      columns: ['json'],
      where: 'gameID = ?',
      whereArgs: [gameID],
    );
    return out?.length == 1 ? out[0]['json'] : null;
  }

  Future<List<Map<String, dynamic>>> listGames(
      {bool live, int limit, int offset}) async {
    return _db.query(
      'Games',
      where: 'live = ?',
      whereArgs: [live ? 1 : 0],
      columns: ['gameID', 'summary'],
      limit: limit,
      offset: offset,
    );
    // TODO check for errors
  }

  Future listPlayers() async {
    // select from the newly-updated local db
    List<Map<String, dynamic>> players = await _db.query(
      'Users',
      columns: ['id', 'name'],
    );

    // strip away the dbQuery objects, leaving just a list of Maps
    players.forEach((Map<String, dynamic> player) {
      GLOBAL.allPlayers.add({'id': player['id'], 'name': player['name']});
    });
    GLOBAL.playersListUpdated = true;
  }

  Future updatePlayersFromServer() async {
    // get players from the server. Get all of them, if we think there's not many to deal with
    GLOBAL.playersListUpdated = false;
    String lastUpdated =
        GLOBAL.allPlayers.length < 50 ? null : await getLastUpdated('Users');
    List<dynamic> newPlayers = await IO().listPlayers(lastUpdated);

    // update local db with updates received from the server
    Batch batch = _db.batch();
    newPlayers.forEach((player) {
      batch.insert('Users', {'id': player[0], 'name': player[1]},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    setLastUpdated('Users', DateTime.now(), batch);
    batch.commit(noResult: true);
    listPlayers();
  }
}
