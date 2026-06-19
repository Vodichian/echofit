import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/health_metric.dart';
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

  Future<void> syncWithNextcloud({
    required String baseUrl,
    required String username,
    required String appPassword,
    String remotePath = 'EchoFit/data.json',
  }) async {
    final String auth = 'Basic ${base64Encode(utf8.encode('$username:$appPassword'))}';
    final String fileUrl = '$baseUrl/remote.php/dav/files/$username/$remotePath';
    final String dirUrl = fileUrl.substring(0, fileUrl.lastIndexOf('/'));

    debugPrint('Attempting Nextcloud Sync to URL: $fileUrl');

    try {
      // 1. Download current data from remote
      List<HealthMetric> remoteMetrics = [];
      try {
        debugPrint('GET Request to: $fileUrl');
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
          debugPrint('Remote file not found (404). This is expected for the first sync. Proceeding with empty remote dataset.');
        } else {
          debugPrint('DioException during GET: ${e.type} - ${e.message}');
          if (e.response != null) {
            debugPrint('Response Status: ${e.response?.statusCode}');
            debugPrint('Response Data: ${e.response?.data}');
          }
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
      debugPrint('PUT Request to: $fileUrl with ${allMetrics.length} metrics');
      final jsonToUpload = jsonEncode(allMetrics.map((e) => e.toJson()).toList());
      
      Future<Response> attemptPut() async {
        return await _dio.put(
          fileUrl,
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
        uploadResponse = await attemptPut();
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          debugPrint('PUT failed with 404. Attempting to create parent directory: $dirUrl');
          try {
            // MKCOL to create directory
            await _dio.request(
              dirUrl,
              options: Options(
                method: 'MKCOL',
                headers: {'Authorization': auth},
              ),
            );
            debugPrint('Directory created successfully. Retrying PUT.');
            uploadResponse = await attemptPut();
          } catch (dirError) {
            debugPrint('Failed to create directory: $dirError');
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      if (uploadResponse.statusCode == 201 || uploadResponse.statusCode == 204 || uploadResponse.statusCode == 200) {
        debugPrint('Upload successful. Updating local sync status.');
        // 5. Update local data as synced
        for (var m in unsyncedMetrics) {
          await _dbService.updateMetric(m.copyWith(isSynced: true));
        }
        // Also insert remote metrics that were missing locally (optional but good for multi-device)
        final localMetrics = await _dbService.getAllMetrics();
        final localTimestamps = localMetrics.map((e) => e.timestamp.millisecondsSinceEpoch).toSet();
        
        for (var m in remoteMetrics) {
          if (!localTimestamps.contains(m.timestamp.millisecondsSinceEpoch)) {
            await _dbService.insertMetric(m.copyWith(isSynced: true));
          }
        }
      } else {
        debugPrint('Upload failed with status: ${uploadResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('Sync failed with error: $e');
      rethrow;
    }
  }
}
