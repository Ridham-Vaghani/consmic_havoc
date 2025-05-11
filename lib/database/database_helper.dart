import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('highscores.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE highscores(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        score INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL,
        value REAL NOT NULL
      )
    ''');

    // Insert default speed setting
    await db.insert('settings', {
      'key': 'game_speed',
      'value': 1.0,
    });
  }

  Future<int> insertScore(int score) async {
    final db = await database;
    return await db.insert('highscores', {
      'score': score,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHighScores() async {
    final db = await database;
    return await db.query(
      'highscores',
      orderBy: 'score DESC',
      limit: 10,
    );
  }

  Future<double> getGameSpeed() async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['game_speed'],
    );

    if (result.isEmpty) {
      return 1.0; // Default speed
    }
    return result.first['value'] as double;
  }

  Future<void> updateGameSpeed(double speed) async {
    final db = await database;
    await db.update(
      'settings',
      {'value': speed},
      where: 'key = ?',
      whereArgs: ['game_speed'],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
