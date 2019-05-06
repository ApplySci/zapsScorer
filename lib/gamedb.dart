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

  Directory dbDir;
  static String deviceID = '';
  static Database _database;
  static final GameDB _singleton = GameDB._privateConstructor();
  Map<String, dynamic> lastGame;
  bool handledStart = false;

  GameDB._privateConstructor();

  factory GameDB([String _deviceID]) {
    if (_deviceID != null) {
      deviceID = _deviceID;
    }
    return _singleton;
  }

  Future<Database> get database async {
    if (_database == null) {
      _database = await initDB();
      List<Map> lastGames = await _database.query(
        'Games',
        where: 'live = 1',
        columns: ['gameID', 'summary', 'json'],
        limit: 1,
      );
      if (lastGames.length == 1) {
        lastGame = lastGames[0];
      }
    }
    return _database;
  }

  void _createTables([Database db]) async {
    if (db == null) {
      db = _database;
    }
    await db.execute("CREATE TABLE Games ("
        "gameID TEXT PRIMARY KEY ON CONFLICT REPLACE, "
        "live BOOL, "
        "summary TEXT NOT NULL, "
        "json TEXT NOT NULL"
        ") WITHOUT ROWID;");
    await db.execute("CREATE INDEX live_idx ON Games (live, summary DESC);");
  }

  void deleteTables() async {
    await (await database).close();
    File(p.join(dbDir.path, "games.db")).delete();
    _database = await initDB();
  }

  Future<Database> initDB() async {
    dbDir = await getApplicationDocumentsDirectory();
    return await openDatabase(p.join(dbDir.path, "games.db"),
        version: _version,
        onOpen: (db) {},
        onCreate: (Database db, int version) => _createTables(db));
  }

  Future<int> put(Map<String, dynamic> record) async {
    return await (await database).insert('Games', record,
        conflictAlgorithm: ConflictAlgorithm.replace);
    // TODO check for errors
  }

  Future<String> get(String gameID) async {
    List<Map<String, dynamic>> out = await (await database).query(
      'Games',
      columns: ['json'],
      where: 'gameID = ?',
      whereArgs: [gameID],
    );
    // TODO check for errors
    return out[0]['json'];
  }

  Future<List<Map<String, dynamic>>> list(
      {bool live, int limit, int offset}) async {
    dynamic results = await (await database).query(
      'Games',
      where: 'live = ?',
      whereArgs: [live ? 1 : 0],
      columns: ['gameID', 'summary'],
      limit: limit,
      offset: offset,
    );
    // TODO check for errors
    return results;
  }
}
