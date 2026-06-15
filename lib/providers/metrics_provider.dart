import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_metric.dart';
import '../services/database_service.dart';

final metricsProvider = StateNotifierProvider<MetricsNotifier, List<HealthMetric>>((ref) {
  return MetricsNotifier();
});

class MetricsNotifier extends StateNotifier<List<HealthMetric>> {
  MetricsNotifier() : super([]) {
    loadMetrics();
  }

  final _dbService = DatabaseService();

  Future<void> loadMetrics() async {
    state = await _dbService.getAllMetrics();
  }

  Future<void> addMetric(HealthMetric metric) async {
    await _dbService.insertMetric(metric);
    await loadMetrics();
  }
}
