import 'package:flutter_test/flutter_test.dart';
import 'package:echofit/utils/backup_pruning_utils.dart';

void main() {
  group('BackupPruningUtils Tests', () {
    final now = DateTime(2023, 10, 27, 12, 0, 0); // Friday

    test('parseTimestamp should parse correct filenames', () {
      expect(BackupPruningUtils.parseTimestamp('data_20231027_123000.json'), DateTime(2023, 10, 27, 12, 30, 0));
      expect(BackupPruningUtils.parseTimestamp('EchoFit/backups/data_20231027_123000.json'), DateTime(2023, 10, 27, 12, 30, 0));
      expect(BackupPruningUtils.parseTimestamp('invalid.json'), isNull);
    });

    test('should keep all for current date and 1 per day for 1 week', () {
      final files = [
        BackupFile(path: 'today_1', timestamp: DateTime(2023, 10, 27, 10, 0)),
        BackupFile(path: 'today_2', timestamp: DateTime(2023, 10, 27, 11, 0)),
        BackupFile(path: 'yesterday_1', timestamp: DateTime(2023, 10, 26, 10, 0)),
        BackupFile(path: 'yesterday_2', timestamp: DateTime(2023, 10, 26, 11, 0)),
        BackupFile(path: 'three_days_ago', timestamp: DateTime(2023, 10, 24, 10, 0)),
      ];

      final toDelete = BackupPruningUtils.getFilesToDelete(files, now);
      final deletePaths = toDelete.map((f) => f.path).toList();
      
      // Both today files should be kept
      expect(deletePaths, isNot(contains('today_1')));
      expect(deletePaths, isNot(contains('today_2')));
      
      // Yesterday: only newest kept
      expect(deletePaths, contains('yesterday_1'));
      expect(deletePaths, isNot(contains('yesterday_2')));
      
      // Three days ago kept
      expect(deletePaths, isNot(contains('three_days_ago')));
    });

    test('should keep 1 for each week for 4 weeks', () {
      final files = [
        BackupFile(path: 'today', timestamp: DateTime(2023, 10, 27, 10, 0)),
        // Week 2 ago (approx 10-14 days ago)
        BackupFile(path: 'w2_a', timestamp: DateTime(2023, 10, 15, 10, 0)),
        BackupFile(path: 'w2_b', timestamp: DateTime(2023, 10, 14, 10, 0)),
      ];

      final toDelete = BackupPruningUtils.getFilesToDelete(files, now);
      final deletePaths = toDelete.map((f) => f.path).toList();

      expect(deletePaths, contains('w2_b')); 
      expect(deletePaths, isNot(contains('w2_a')));
      expect(deletePaths, isNot(contains('today')));
    });

    test('should keep 1 for each month for 12 months', () {
      final files = [
        BackupFile(path: 'today', timestamp: DateTime(2023, 10, 27, 10, 0)),
        // 11 months ago
        BackupFile(path: 'm11_a', timestamp: DateTime(2022, 11, 15, 10, 0)),
        BackupFile(path: 'm11_b', timestamp: DateTime(2022, 11, 14, 10, 0)),
        // 13 months ago
        BackupFile(path: 'too_old', timestamp: DateTime(2022, 09, 15, 10, 0)),
      ];

      final toDelete = BackupPruningUtils.getFilesToDelete(files, now);
      final deletePaths = toDelete.map((f) => f.path).toList();

      expect(deletePaths, contains('m11_b'));
      expect(deletePaths, isNot(contains('m11_a')));
      expect(deletePaths, contains('too_old'));
    });
   group('Consistency with user requirements', () {
      test('Requirement: Keep all for current date', () {
        final now = DateTime(2023, 10, 27, 12, 0, 0);
        final files = [
          BackupFile(path: 't1', timestamp: DateTime(2023, 10, 27, 0, 0, 1)),
          BackupFile(path: 't2', timestamp: DateTime(2023, 10, 27, 23, 59, 59)),
        ];
        final toDelete = BackupPruningUtils.getFilesToDelete(files, now);
        expect(toDelete, isEmpty);
      });

      test('Requirement: Keep 1 record for each day of the week for 1 week', () {
        final now = DateTime(2023, 10, 27, 12, 0, 0);
        final files = List.generate(10, (i) => 
          BackupFile(path: 'd$i', timestamp: now.subtract(Duration(days: i, hours: 1)))
        );
        // d0 is today (but 1 hour ago, so it's after todayStart if now is 12:00)
        // Wait, now is 12:00, d0 is 11:00 today.
        // d1 is 11:00 yesterday.
        // ... d6 is 6 days ago.
        // d7 is 7 days ago (might be outside 1 week if limit is exactly 7 days)
        
        final toDelete = BackupPruningUtils.getFilesToDelete(files, now);
        final keptPaths = files.where((f) => !toDelete.contains(f)).map((f) => f.path).toList();
        
        expect(keptPaths, contains('d0'));
        expect(keptPaths, contains('d1'));
        expect(keptPaths, contains('d2'));
        expect(keptPaths, contains('d3'));
        expect(keptPaths, contains('d4'));
        expect(keptPaths, contains('d5'));
        expect(keptPaths, contains('d6'));
        // d7, d8, d9 might be kept by week rule (1 per week)
      });
    });
  });
}
