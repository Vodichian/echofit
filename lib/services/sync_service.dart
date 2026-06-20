import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import '../models/health_metric.dart';
import '../utils/backup_pruning_utils.dart';
import 'database_service.dart';

class SyncService {
  final Dio _dio;
  final DatabaseService _dbService;

  SyncService({Dio? dio, DatabaseService? dbService})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            )),
        _dbService = dbService ?? DatabaseService();

  String _getAuthHeader(String username, String appPassword) {
    return 'Basic ${base64Encode(utf8.encode('$username:$appPassword'))}';
  }

  Future<void> syncWithNextcloud({
    required String baseUrl,
    required String username,
    required String appPassword,
    String remotePath = 'EchoFit/data.json',
  }) async {
    final String auth = _getAuthHeader(username, appPassword);
    final String fileUrl = '$baseUrl/remote.php/dav/files/$username/$remotePath';
    final String dirUrl = fileUrl.substring(0, fileUrl.lastIndexOf('/'));
    final String backupDirUrl = '$dirUrl/backups';

    debugPrint('Attempting Nextcloud Sync to URL: $fileUrl');

    try {
      // 1. Download current data from remote
      List<HealthMetric> remoteMetrics = [];
      try {
        final response = await _dio.get(
          fileUrl,
          options: Options(headers: {'Authorization': auth}),
        );
        if (response.statusCode == 200) {
          final List<dynamic> jsonList = jsonDecode(response.data);
          remoteMetrics = jsonList.map((e) => HealthMetric.fromJson(e)).toList();
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          debugPrint('Remote file not found (404). Proceeding with empty remote dataset.');
        } else {
          rethrow;
        }
      }

      // 2. Get local unsynced data
      final unsyncedMetrics = await _dbService.getUnsyncedMetrics();

      // 3. Merge data
      final Map<int, HealthMetric> allMetricsMap = {};
      for (var m in remoteMetrics) {
        allMetricsMap[m.timestamp.millisecondsSinceEpoch] = m;
      }
      for (var m in unsyncedMetrics) {
        allMetricsMap[m.timestamp.millisecondsSinceEpoch] = m;
      }
      
      final allMetrics = allMetricsMap.values.toList();

      // 4. Upload merged data
      final jsonToUpload = jsonEncode(allMetrics.map((e) => e.toJson()).toList());
      
      Future<Response> attemptPut(String url) async {
        return await _dio.put(
          url,
          data: jsonToUpload,
          options: Options(
            headers: {
              'Authorization': auth,
              'Content-Type': 'application/json',
            },
          ),
        );
      }

      Response uploadResponse;
      try {
        uploadResponse = await attemptPut(fileUrl);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          debugPrint('PUT failed with 404. Creating directory: $dirUrl');
          await _createDirectory(dirUrl, auth);
          uploadResponse = await attemptPut(fileUrl);
        } else {
          rethrow;
        }
      }

      if (uploadResponse.statusCode == 201 || uploadResponse.statusCode == 204 || uploadResponse.statusCode == 200) {
        // 5. Update local sync status
        for (var m in unsyncedMetrics) {
          await _dbService.updateMetric(m.copyWith(isSynced: true));
        }
        
        // Also insert remote metrics missing locally
        final localMetrics = await _dbService.getAllMetrics();
        final localTimestamps = localMetrics.map((e) => e.timestamp.millisecondsSinceEpoch).toSet();
        for (var m in remoteMetrics) {
          if (!localTimestamps.contains(m.timestamp.millisecondsSinceEpoch)) {
            await _dbService.insertMetric(m.copyWith(isSynced: true));
          }
        }

        // 6. Archive backup
        final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final String backupUrl = '$backupDirUrl/data_$timestamp.json';
        
        try {
          await attemptPut(backupUrl);
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) {
            debugPrint('Backup PUT failed with 404. Creating directory: $backupDirUrl');
            await _createDirectory(backupDirUrl, auth);
            await attemptPut(backupUrl);
          } else {
            debugPrint('Backup failed: $e');
          }
        }

        // 7. Prune backups
        await _pruneBackups(backupDirUrl, auth);

      } else {
        debugPrint('Upload failed with status: ${uploadResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('Sync failed: $e');
      rethrow;
    }
  }

  Future<void> _createDirectory(String url, String auth) async {
    try {
      await _dio.request(
        url,
        options: Options(
          method: 'MKCOL',
          headers: {'Authorization': auth},
        ),
      );
    } catch (e) {
      debugPrint('Failed to create directory $url: $e');
    }
  }

  Future<void> _pruneBackups(String backupDirUrl, String auth) async {
    try {
      final List<BackupFile> backups = await listBackups(backupDirUrl, auth);
      final List<BackupFile> toDelete = BackupPruningUtils.getFilesToDelete(backups, DateTime.now());

      for (var file in toDelete) {
        debugPrint('Pruning backup: ${file.path}');
        await _dio.delete(
          file.path,
          options: Options(headers: {'Authorization': auth}),
        );
      }
    } catch (e) {
      debugPrint('Error pruning backups: $e');
    }
  }

  Future<List<BackupFile>> listBackups(String backupDirUrl, String auth) async {
    try {
      final response = await _dio.request(
        backupDirUrl,
        options: Options(
          method: 'PROPFIND',
          headers: {
            'Authorization': auth,
            'Depth': '1',
          },
        ),
      );

      if (response.statusCode == 207) {
        final document = XmlDocument.parse(response.data);
        final List<BackupFile> backups = [];
        
        final responses = document.findAllElements('d:response');
        for (var res in responses) {
          final hrefElements = res.findAllElements('d:href');
          if (hrefElements.isEmpty) continue;
          final href = hrefElements.first.innerText;
          // Decode URL component as Nextcloud might return encoded paths
          final decodedPath = Uri.decodeFull(href);
          
          final ts = BackupPruningUtils.parseTimestamp(decodedPath);
          if (ts != null) {
            // Re-construct full URL if href is relative
            String fullPath = decodedPath;
            if (!fullPath.startsWith('http')) {
              // Extract host from backupDirUrl
              final uri = Uri.parse(backupDirUrl);
              fullPath = '${uri.scheme}://${uri.host}$decodedPath';
            }
            backups.add(BackupFile(path: fullPath, timestamp: ts));
          }
        }
        return backups;
      }
    } catch (e) {
      debugPrint('Error listing backups: $e');
    }
    return [];
  }

  Future<List<BackupFile>> getAvailableBackups({
    required String baseUrl,
    required String username,
    required String appPassword,
    String remotePath = 'EchoFit/data.json',
  }) async {
    final String auth = _getAuthHeader(username, appPassword);
    final String fileUrl = '$baseUrl/remote.php/dav/files/$username/$remotePath';
    final String dirUrl = fileUrl.substring(0, fileUrl.lastIndexOf('/'));
    final String backupDirUrl = '$dirUrl/backups';
    return await listBackups(backupDirUrl, auth);
  }

  Future<void> importFromBackup({
    required String backupUrl,
    required String username,
    required String appPassword,
  }) async {
    final String auth = _getAuthHeader(username, appPassword);
    
    try {
      final response = await _dio.get(
        backupUrl,
        options: Options(headers: {'Authorization': auth}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.data);
        final List<HealthMetric> metrics = jsonList.map((e) => HealthMetric.fromJson(e)).toList();

        // For "Import/Restore", we clear existing data and replace it
        final currentMetrics = await _dbService.getAllMetrics();
        for (var m in currentMetrics) {
          if (m.id != null) {
            await _dbService.deleteMetric(m.id!);
          }
        }

        for (var m in metrics) {
          // Re-insert as unsynced so that the next sync pushes this "restored" state
          await _dbService.insertMetric(m.copyWith(isSynced: false));
        }
        debugPrint('Successfully imported ${metrics.length} metrics from backup.');
      }
    } catch (e) {
      debugPrint('Import from backup failed: $e');
      rethrow;
    }
  }
}
