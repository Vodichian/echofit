import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:echofit/services/database_service.dart';
import 'package:echofit/models/health_metric.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseService Tests', () {
    late DatabaseService dbService;
    late Database db;

    setUp(() async {
      dbService = DatabaseService();
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 3,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE health_metrics (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp INTEGER NOT NULL,
              weight REAL,
              bodyFat REAL,
              visceralFat REAL,
              waistline REAL,
              isSynced INTEGER NOT NULL DEFAULT 0,
              journalEntry TEXT
            )
          ''');
        },
      );
      dbService.database = db;
    });

    tearDown(() async {
      await db.close();
    });

    test('insertMetric should add a metric to the database', () async {
      final metric = HealthMetric(
        timestamp: DateTime.now(),
        weight: 70.0,
      );
      
      final id = await dbService.insertMetric(metric);
      expect(id, isNotNull);

      final metrics = await dbService.getAllMetrics();
      expect(metrics.length, 1);
      expect(metrics.first.weight, 70.0);
    });

    test('updateMetric should modify an existing metric', () async {
      final metric = HealthMetric(
        timestamp: DateTime.now(),
        weight: 70.0,
      );
      final id = await dbService.insertMetric(metric);
      
      final updatedMetric = metric.copyWith(id: id, weight: 75.0);
      await dbService.updateMetric(updatedMetric);

      final metrics = await dbService.getAllMetrics();
      expect(metrics.first.weight, 75.0);
    });

    test('deleteMetric should remove a metric from the database', () async {
      final metric = HealthMetric(
        timestamp: DateTime.now(),
        weight: 70.0,
      );
      final id = await dbService.insertMetric(metric);
      
      await dbService.deleteMetric(id);

      final metrics = await dbService.getAllMetrics();
      expect(metrics, isEmpty);
    });

    test('getUnsyncedMetrics should only return unsynced metrics', () async {
      await dbService.insertMetric(HealthMetric(timestamp: DateTime.now(), isSynced: false));
      await dbService.insertMetric(HealthMetric(timestamp: DateTime.now(), isSynced: true));

      final unsynced = await dbService.getUnsyncedMetrics();
      expect(unsynced.length, 1);
      expect(unsynced.first.isSynced, false);
    });
  });
}
