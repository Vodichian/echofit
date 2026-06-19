import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:echofit/providers/metrics_provider.dart';
import 'package:echofit/services/database_service.dart';
import 'package:echofit/models/health_metric.dart';

import 'metrics_notifier_test.mocks.dart';

@GenerateMocks([DatabaseService])
void main() {
  group('MetricsNotifier Tests', () {
    late MockDatabaseService mockDbService;

    setUp(() {
      mockDbService = MockDatabaseService();
    });

    test('addMetric should call database and reload', () async {
      when(mockDbService.getAllMetrics()).thenAnswer((_) async => []);
      when(mockDbService.insertMetric(any)).thenAnswer((_) async => 1);

      final container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDbService),
        ],
      );

      final metric = HealthMetric(timestamp: DateTime.now(), weight: 70.0);
      
      await container.read(metricsProvider.notifier).addMetric(metric);

      verify(mockDbService.insertMetric(any)).called(1);
      verify(mockDbService.getAllMetrics()).called(2); // Initial build + after add
    });

    test('updateMetric should call database and reload', () async {
      when(mockDbService.getAllMetrics()).thenAnswer((_) async => []);
      when(mockDbService.updateMetric(any)).thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDbService),
        ],
      );

      final metric = HealthMetric(id: 1, timestamp: DateTime.now(), weight: 75.0);
      
      await container.read(metricsProvider.notifier).updateMetric(metric);

      verify(mockDbService.updateMetric(metric)).called(1);
      verify(mockDbService.getAllMetrics()).called(2);
    });

    test('deleteMetric should call database and reload', () async {
      when(mockDbService.getAllMetrics()).thenAnswer((_) async => []);
      when(mockDbService.deleteMetric(any)).thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDbService),
        ],
      );

      await container.read(metricsProvider.notifier).deleteMetric(1);

      verify(mockDbService.deleteMetric(1)).called(1);
      verify(mockDbService.getAllMetrics()).called(2);
    });
  });
}
