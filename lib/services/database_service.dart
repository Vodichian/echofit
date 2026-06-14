import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/health_metric.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'echofit.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE health_metrics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        weight REAL,
        bodyFat REAL,
        visceralFat INTEGER,
        waistline REAL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> insertMetric(HealthMetric metric) async {
    final db = await database;
    return await db.insert('health_metrics', metric.toMap());
  }

  Future<List<HealthMetric>> getAllMetrics() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('health_metrics', orderBy: 'timestamp DESC');
    return List.generate(maps.length, (i) => HealthMetric.fromMap(maps[i]));
  }

  Future<List<HealthMetric>> getUnsyncedMetrics() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'health_metrics',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => HealthMetric.fromMap(maps[i]));
  }

  Future<void> updateMetric(HealthMetric metric) async {
    final db = await database;
    await db.update(
      'health_metrics',
      metric.toMap(),
      where: 'id = ?',
      whereArgs: [metric.id],
    );
  }

  Future<void> deleteMetric(int id) async {
    final db = await database;
    await db.delete(
      'health_metrics',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
