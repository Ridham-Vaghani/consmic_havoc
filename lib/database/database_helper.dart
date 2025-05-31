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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE highscores(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        score INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        joystick_sensitivity REAL DEFAULT 1.0,
        control_type TEXT DEFAULT 'joystick',
        player_speed REAL DEFAULT 300.0
      )
    ''');

    // Insert default settings
    await db.insert('settings', {
      'id': 1,
      'joystick_sensitivity': 1.0,
      'control_type': 'joystick',
      'player_speed': 300.0,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from version $oldVersion to $newVersion");
    if (oldVersion < 2) {
      // Check if control_type column exists
      final columns = await db.rawQuery('PRAGMA table_info(settings)');
      final hasControlType =
          columns.any((column) => column['name'] == 'control_type');

      if (!hasControlType) {
        // Add control_type column to settings table only if it doesn't exist
        await db.execute(
            'ALTER TABLE settings ADD COLUMN control_type TEXT DEFAULT "joystick"');
      }

      // Update existing settings to have the default control type
      await db.update(
        'settings',
        {'control_type': 'joystick'},
        where: 'id = 1',
      );
    }
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

  Future<double> getJoystickSensitivity() async {
    final db = await database;
    final settings = await db.query('settings');
    if (settings.isNotEmpty) {
      return (settings.first['joystick_sensitivity'] as double?) ?? 1.0;
    }
    return 1.0;
  }

  Future<String> getControlType() async {
    final db = await database;
    final settings = await db.query('settings', where: 'id = 1');
    print("Database settings: $settings"); // Debug print
    if (settings.isNotEmpty) {
      final controlType = settings.first['control_type'] as String?;
      print("Retrieved control type: $controlType"); // Debug print
      return controlType ?? 'joystick';
    }
    return 'joystick';
  }

  Future<void> updateJoystickSensitivity(double sensitivity) async {
    final db = await database;
    await db.update(
      'settings',
      {'joystick_sensitivity': sensitivity},
      where: 'id = 1',
    );
  }

  Future<void> updateControlType(String controlType) async {
    final db = await database;
    print("Updating control type to: $controlType"); // Debug print
    await db.update(
      'settings',
      {'control_type': controlType},
      where: 'id = 1',
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
