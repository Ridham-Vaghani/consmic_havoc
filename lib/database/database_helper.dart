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

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
