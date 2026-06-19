import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:echofit/services/sync_service.dart';
import 'package:echofit/services/database_service.dart';
import 'package:echofit/models/health_metric.dart';

import 'sync_service_test.mocks.dart';

@GenerateMocks([Dio, DatabaseService])
void main() {
  late SyncService syncService;
  late MockDio mockDio;
  late MockDatabaseService mockDbService;

  setUp(() {
    mockDio = MockDio();
    mockDbService = MockDatabaseService();
    syncService = SyncService(dio: mockDio, dbService: mockDbService);
  });

  group('SyncService Tests', () {
    final timestamp = DateTime(2023, 10, 27);
    final metric = HealthMetric(id: 1, timestamp: timestamp, weight: 70.0, isSynced: false);

    test('syncWithNextcloud should download, merge and upload data', () async {
      // Mock GET (remote data)
      when(mockDio.get(any, options: anyNamed('options'))).thenAnswer(
        (_) async => Response(
          data: jsonEncode([]),
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      // Mock Local Unsynced
      when(mockDbService.getUnsyncedMetrics()).thenAnswer((_) async => [metric]);
      when(mockDbService.getAllMetrics()).thenAnswer((_) async => [metric]);

      // Mock PUT (upload merged)
      when(mockDio.put(any, data: anyNamed('data'), options: anyNamed('options'))).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      // Mock Local Update
      when(mockDbService.updateMetric(any)).thenAnswer((_) async => {});

      await syncService.syncWithNextcloud(
        baseUrl: 'https://test.com',
        username: 'user',
        appPassword: 'pass',
      );

      verify(mockDio.get(any, options: anyNamed('options'))).called(1);
      verify(mockDbService.getUnsyncedMetrics()).called(1);
      verify(mockDio.put(any, data: anyNamed('data'), options: anyNamed('options'))).called(1);
      verify(mockDbService.updateMetric(argThat(predicate<HealthMetric>((m) => m.isSynced)))).called(1);
    });

    test('syncWithNextcloud should handle 404 for remote file', () async {
      when(mockDio.get(any, options: anyNamed('options'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(statusCode: 404, requestOptions: RequestOptions(path: '')),
        ),
      );

      when(mockDbService.getUnsyncedMetrics()).thenAnswer((_) async => []);
      when(mockDbService.getAllMetrics()).thenAnswer((_) async => []);
      
      // Mock PUT
      when(mockDio.put(any, data: anyNamed('data'), options: anyNamed('options'))).thenAnswer(
        (_) async => Response(statusCode: 204, requestOptions: RequestOptions(path: '')),
      );

      await syncService.syncWithNextcloud(
        baseUrl: 'https://test.com',
        username: 'user',
        appPassword: 'pass',
      );

      verify(mockDio.get(any, options: anyNamed('options'))).called(1);
      // Should still proceed to upload local data (if any)
    });
  });
}
