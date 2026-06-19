import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_metric.dart';
import '../services/database_service.dart';

final databaseServiceProvider = Provider((ref) => DatabaseService());

final metricsProvider = NotifierProvider<MetricsNotifier, List<HealthMetric>>(MetricsNotifier.new);

class MetricsNotifier extends Notifier<List<HealthMetric>> {
  DatabaseService get _dbService => ref.read(databaseServiceProvider);

  @override
  List<HealthMetric> build() {
    loadMetrics();
    return [];
  }

  Future<void> loadMetrics() async {
    state = await _dbService.getAllMetrics();
  }

  Future<void> addMetric(HealthMetric metric) async {
    await _dbService.insertMetric(metric);
    await loadMetrics();
  }

  Future<void> updateMetric(HealthMetric metric) async {
    await _dbService.updateMetric(metric);
    await loadMetrics();
  }

  Future<void> deleteMetric(int id) async {
    await _dbService.deleteMetric(id);
    await loadMetrics();
  }
}
