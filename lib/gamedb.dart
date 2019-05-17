/// handle sqlite database of games
///
///
///

import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class GameDB {
  // https://medium.com/flutter-community/using-sqlite-in-flutter-187c1a82e8b

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

  Future _setLastGame() async {
    List<Map<String, dynamic>> results = await _db.query(
      'Games',
      where: 'live = 1',
      columns: ['gameID', 'summary', 'json'],
      orderBy: 'summary DESC',
      limit: 1,
    );
    lastGame = (results.length == 1) ? results[0] : null;
  }

  void _createTables([Database db]) {
    Batch batch = (db ?? _db).batch();
    batch.execute("CREATE TABLE Games ("
        "gameID TEXT PRIMARY KEY ON CONFLICT REPLACE, "
        "live BOOL, "
        "summary TEXT NOT NULL, "
        "json TEXT NOT NULL, "
        "lastUpdated TEXT "
        ") WITHOUT ROWID;");

    batch.execute("CREATE INDEX live_idx ON Games (live, summary DESC);");

    batch.execute("CREATE TABLE Users ("
        "id INT PRIMARY KEY ON CONFLICT REPLACE, "
        "name TEXT NOT NULL,"
        "lastUpdated TEXT"
        ") WITHOUT ROWID;");

    batch.execute("CREATE TABLE Updates ("
        "what TEXT PRIMARY KEY ON CONFLICT REPLACE, " // table name
        "utc TEXT) WITHOUT ROWID;"); // Iso8601String

    _addTestPlayers(batch);
    batch.commit(noResult: true);
  }

  deleteTables() {
    _db.close().then((_) {
      File(p.join(_dbDir.path, "games.db")).delete().then((_) => initDB());
    });
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

  // db.setLastUpdated('Users', DateTime.now().toIso8601String()) TODO at network update
  Future setLastUpdated(String table, String utc) {
    return _db.insert('Updates', {'utc': utc, 'what': table},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future initDB() async {
    _dbDir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(p.join(_dbDir.path, "games.db"),
        version: _version,
        onOpen: (Database db) {},
        onUpgrade: (Database db, int oldVersion, int newVersion) {
          if (oldVersion < 2) {}
        },
        onCreate: (Database db, int version) => _createTables(db));
    return _setLastGame();
  }

  void putGame(Map<String, dynamic> record) {
    record['lastUpdated'] = DateTime.now().millisecondsSinceEpoch;
    _db.insert('Games', record, conflictAlgorithm: ConflictAlgorithm.replace);
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

  Future<List<Map<String, dynamic>>> listPlayers() async {
    return _db.query(
      'Users',
      columns: ['id', 'name'],
    );
  }

  _addTestPlayers(Batch batch) {
    List<String> test = [
      'Ian P',
      'Jon',
      'Ritchie',
      'Roger',
      'Ian G',
      'Rod',
      'Nick',
      'David',
      'Glenn',
      'Tommy',
      'Joe LT',
      'Joe S',
      'Steve',
      'Don',
    ];
    int i = 0;
    test.forEach((v) => batch.insert('Users', {'id': ++i, 'name': v},
        conflictAlgorithm: ConflictAlgorithm.replace));
  }
}
