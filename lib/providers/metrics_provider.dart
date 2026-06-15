import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_metric.dart';
import '../services/database_service.dart';

final metricsProvider = NotifierProvider<MetricsNotifier, List<HealthMetric>>(MetricsNotifier.new);

class MetricsNotifier extends Notifier<List<HealthMetric>> {
  final _dbService = DatabaseService();

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
}
