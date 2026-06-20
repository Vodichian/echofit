import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:echofit/providers/metrics_provider.dart';
import 'package:echofit/services/database_service.dart';
import 'package:echofit/services/settings_service.dart';
import 'package:echofit/services/sync_service.dart';
import 'package:echofit/models/health_metric.dart';

import 'metrics_notifier_test.mocks.dart';

@GenerateMocks([DatabaseService, SettingsService, SyncService])
void main() {
  group('MetricsNotifier Tests', () {
    late MockDatabaseService mockDbService;
    late MockSettingsService mockSettingsService;
    late MockSyncService mockSyncService;

    setUp(() {
      mockDbService = MockDatabaseService();
      mockSettingsService = MockSettingsService();
      mockSyncService = MockSyncService();
      
      // Default mock behavior for sync check
      when(mockSettingsService.hasCredentials()).thenAnswer((_) async => false);
    });

    test('addMetric should call database, reload and trigger sync', () async {
      when(mockDbService.getAllMetrics()).thenAnswer((_) async => []);
      when(mockDbService.insertMetric(any)).thenAnswer((_) async => 1);
      when(mockSettingsService.hasCredentials()).thenAnswer((_) async => true);
      when(mockSettingsService.getCredentials()).thenAnswer((_) async => {
        'url': 'http://test.com',
        'username': 'user',
        'password': 'pass',
      });
      when(mockSyncService.syncWithNextcloud(
        baseUrl: anyNamed('baseUrl'),
        username: anyNamed('username'),
        appPassword: anyNamed('appPassword'),
      )).thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDbService),
          settingsServiceProvider.overrideWithValue(mockSettingsService),
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );

      final metric = HealthMetric(timestamp: DateTime.now(), weight: 70.0);
      
      await container.read(metricsProvider.notifier).addMetric(metric);
      
      // Wait for background sync to be triggered
      await untilCalled(mockSyncService.syncWithNextcloud(
        baseUrl: anyNamed('baseUrl'),
        username: anyNamed('username'),
        appPassword: anyNamed('appPassword'),
      ));

      verify(mockDbService.insertMetric(any)).called(1);
      verify(mockDbService.getAllMetrics()).called(2);
      verify(mockSyncService.syncWithNextcloud(
        baseUrl: 'http://test.com',
        username: 'user',
        appPassword: 'pass',
      )).called(1);
    });

    test('updateMetric should call database, reload and trigger sync', () async {
      when(mockDbService.getAllMetrics()).thenAnswer((_) async => []);
      when(mockDbService.updateMetric(any)).thenAnswer((_) async => {});
      when(mockSettingsService.hasCredentials()).thenAnswer((_) async => true);
      when(mockSettingsService.getCredentials()).thenAnswer((_) async => {
        'url': 'http://test.com',
        'username': 'user',
        'password': 'pass',
      });
      when(mockSyncService.syncWithNextcloud(
        baseUrl: anyNamed('baseUrl'),
        username: anyNamed('username'),
        appPassword: anyNamed('appPassword'),
      )).thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDbService),
          settingsServiceProvider.overrideWithValue(mockSettingsService),
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );

      final metric = HealthMetric(id: 1, timestamp: DateTime.now(), weight: 75.0);
      
      await container.read(metricsProvider.notifier).updateMetric(metric);
      
      await untilCalled(mockSyncService.syncWithNextcloud(
        baseUrl: anyNamed('baseUrl'),
        username: anyNamed('username'),
        appPassword: anyNamed('appPassword'),
      ));

      verify(mockDbService.updateMetric(metric)).called(1);
      verify(mockDbService.getAllMetrics()).called(2);
      verify(mockSyncService.syncWithNextcloud(
        baseUrl: 'http://test.com',
        username: 'user',
        appPassword: 'pass',
      )).called(1);
    });

    test('deleteMetric should call database, reload and trigger sync', () async {
      when(mockDbService.getAllMetrics()).thenAnswer((_) async => []);
      when(mockDbService.deleteMetric(any)).thenAnswer((_) async => {});
      when(mockSettingsService.hasCredentials()).thenAnswer((_) async => true);
      when(mockSettingsService.getCredentials()).thenAnswer((_) async => {
        'url': 'http://test.com',
        'username': 'user',
        'password': 'pass',
      });
      when(mockSyncService.syncWithNextcloud(
        baseUrl: anyNamed('baseUrl'),
        username: anyNamed('username'),
        appPassword: anyNamed('appPassword'),
      )).thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDbService),
          settingsServiceProvider.overrideWithValue(mockSettingsService),
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );

      await container.read(metricsProvider.notifier).deleteMetric(1);
      
      await untilCalled(mockSyncService.syncWithNextcloud(
        baseUrl: anyNamed('baseUrl'),
        username: anyNamed('username'),
        appPassword: anyNamed('appPassword'),
      ));

      verify(mockDbService.deleteMetric(1)).called(1);
      verify(mockDbService.getAllMetrics()).called(2);
      verify(mockSyncService.syncWithNextcloud(
        baseUrl: 'http://test.com',
        username: 'user',
        appPassword: 'pass',
      )).called(1);
    });
  });
}
