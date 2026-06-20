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

    test('syncWithNextcloud should backup and prune', () async {
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

      // Mock PUT (upload merged AND backup)
      when(mockDio.put(any, data: anyNamed('data'), options: anyNamed('options'))).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      // Mock PROPFIND for pruning (empty list)
      when(mockDio.request(any, options: argThat(predicate<Options>((o) => o.method == 'PROPFIND'), named: 'options'))).thenAnswer(
        (_) async => Response(
          statusCode: 207,
          data: '<?xml version="1.0" encoding="UTF-8"?><d:multistatus xmlns:d="DAV:"></d:multistatus>',
          requestOptions: RequestOptions(path: ''),
        ),
      );

      // Mock Local Update
      when(mockDbService.updateMetric(any)).thenAnswer((_) async => {});
      when(mockDbService.insertMetric(any)).thenAnswer((_) async => 1);

      await syncService.syncWithNextcloud(
        baseUrl: 'https://test.com',
        username: 'user',
        appPassword: 'pass',
      );

      // Verify normal PUT
      verify(mockDio.put(argThat(contains('data.json')), data: anyNamed('data'), options: anyNamed('options'))).called(1);
      // Verify backup PUT
      verify(mockDio.put(argThat(contains('backups/data_')), data: anyNamed('data'), options: anyNamed('options'))).called(1);
      // Verify PROPFIND
      verify(mockDio.request(any, options: argThat(predicate<Options>((o) => o.method == 'PROPFIND'), named: 'options'))).called(1);
    });

    test('importFromBackup should replace local data', () async {
      final backupData = [metric.toJson()];
      when(mockDio.get(any, options: anyNamed('options'))).thenAnswer(
        (_) async => Response(
          data: jsonEncode(backupData),
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      when(mockDbService.getAllMetrics()).thenAnswer((_) async => [metric]);
      when(mockDbService.deleteMetric(any)).thenAnswer((_) async => 1);
      when(mockDbService.insertMetric(any)).thenAnswer((_) async => 1);

      await syncService.importFromBackup(
        backupUrl: 'https://test.com/backup.json',
        username: 'user',
        appPassword: 'pass',
      );

      verify(mockDbService.deleteMetric(1)).called(1);
      verify(mockDbService.insertMetric(argThat(predicate<HealthMetric>((m) => !m.isSynced)))).called(1);
    });
  });
}
