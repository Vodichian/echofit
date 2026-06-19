import 'package:flutter_test/flutter_test.dart';
import 'package:echofit/models/health_metric.dart';

void main() {
  group('HealthMetric Model Tests', () {
    final timestamp = DateTime(2023, 10, 27, 10, 30);
    
    test('HealthMetric.fromMap should create a valid instance', () {
      final map = {
        'id': 1,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'weight': 75.5,
        'bodyFat': 15.2,
        'visceralFat': 5.0,
        'waistline': 85.0,
        'isSynced': 1,
        'journalEntry': 'Feeling good'
      };

      final metric = HealthMetric.fromMap(map);

      expect(metric.id, 1);
      expect(metric.timestamp, timestamp);
      expect(metric.weight, 75.5);
      expect(metric.bodyFat, 15.2);
      expect(metric.visceralFat, 5.0);
      expect(metric.waistline, 85.0);
      expect(metric.isSynced, true);
      expect(metric.journalEntry, 'Feeling good');
    });

    test('HealthMetric.toMap should return a valid map', () {
      final metric = HealthMetric(
        id: 1,
        timestamp: timestamp,
        weight: 75.5,
        bodyFat: 15.2,
        visceralFat: 5.0,
        waistline: 85.0,
        isSynced: true,
        journalEntry: 'Feeling good'
      );

      final map = metric.toMap();

      expect(map['id'], 1);
      expect(map['timestamp'], timestamp.millisecondsSinceEpoch);
      expect(map['weight'], 75.5);
      expect(map['bodyFat'], 15.2);
      expect(map['visceralFat'], 5.0);
      expect(map['waistline'], 85.0);
      expect(map['isSynced'], 1);
      expect(map['journalEntry'], 'Feeling good');
    });

    test('copyWith should create a new instance with updated values', () {
      final metric = HealthMetric(
        id: 1,
        timestamp: timestamp,
        weight: 75.5,
        isSynced: false,
      );

      final updated = metric.copyWith(weight: 80.0, isSynced: true);

      expect(updated.id, 1);
      expect(updated.timestamp, timestamp);
      expect(updated.weight, 80.0);
      expect(updated.isSynced, true);
    });

    test('fromJson and toJson should be consistent', () {
      final metric = HealthMetric(
        timestamp: timestamp,
        weight: 70.0,
        journalEntry: 'Test',
      );

      final json = metric.toJson();
      final fromJson = HealthMetric.fromJson(json);

      expect(fromJson.timestamp, metric.timestamp);
      expect(fromJson.weight, metric.weight);
      expect(fromJson.journalEntry, metric.journalEntry);
    });
  });
}
