class BackupFile {
  final String path;
  final DateTime timestamp;

  BackupFile({required this.path, required this.timestamp});

  @override
  String toString() => 'BackupFile(path: $path, timestamp: $timestamp)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupFile &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          timestamp == other.timestamp;

  @override
  int get hashCode => path.hashCode ^ timestamp.hashCode;
}

class BackupPruningUtils {
  /// Parses a filename like 'data_20231027_123000.json' to extract the timestamp.
  static DateTime? parseTimestamp(String filename) {
    try {
      final basename = filename.split('/').last;
      final match = RegExp(r'data_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})\.json').firstMatch(basename);
      if (match != null) {
        return DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
          int.parse(match.group(4)!),
          int.parse(match.group(5)!),
          int.parse(match.group(6)!),
        );
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  /// Returns a list of backups that should be deleted according to the retention policy.
  static List<BackupFile> getFilesToDelete(List<BackupFile> allFiles, DateTime now) {
    if (allFiles.isEmpty) return [];

    final sortedFiles = List<BackupFile>.from(allFiles)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final Set<BackupFile> toKeep = {};
    
    final todayStart = DateTime(now.year, now.month, now.day);
    final sevenDaysAgoLimit = todayStart.subtract(const Duration(days: 7));
    final fourWeeksAgoLimit = todayStart.subtract(const Duration(days: 28));
    final twelveMonthsAgoLimit = DateTime(now.year, now.month - 12, now.day);

    final Map<String, BackupFile> dailyBackups = {}; 
    final Map<int, BackupFile> weeklyBackups = {}; 
    final Map<String, BackupFile> monthlyBackups = {}; 

    for (var file in sortedFiles) {
      final ts = file.timestamp;
      
      // 1. Keep all for current date
      if (ts.year == now.year && ts.month == now.month && ts.day == now.day) {
        toKeep.add(file);
        continue;
      }

      // 2. Keep 1 record for each day for 1 week
      if (ts.isAfter(sevenDaysAgoLimit)) {
        final dayKey = "${ts.year}-${ts.month}-${ts.day}";
        if (!dailyBackups.containsKey(dayKey)) {
          dailyBackups[dayKey] = file;
          toKeep.add(file);
        }
        continue;
      }

      // 3. Keep 1 record for each week for 4 weeks
      if (ts.isAfter(fourWeeksAgoLimit)) {
        final weekKey = ts.difference(DateTime(1970, 1, 1)).inDays ~/ 7;
        if (!weeklyBackups.containsKey(weekKey)) {
          weeklyBackups[weekKey] = file;
          toKeep.add(file);
        }
        continue;
      }

      // 4. Keep 1 record for each month for 12 months
      if (ts.isAfter(twelveMonthsAgoLimit)) {
        final monthKey = "${ts.year}-${ts.month}";
        if (!monthlyBackups.containsKey(monthKey)) {
          monthlyBackups[monthKey] = file;
          toKeep.add(file);
        }
      }
    }

    return allFiles.where((f) => !toKeep.contains(f)).toList();
  }
}
