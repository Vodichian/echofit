import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_metric.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../services/settings_service.dart';

final databaseServiceProvider = Provider((ref) => DatabaseService());
final settingsServiceProvider = Provider((ref) => SettingsService());
final syncServiceProvider = Provider((ref) => SyncService(
  dbService: ref.watch(databaseServiceProvider),
));

final metricsProvider = NotifierProvider<MetricsNotifier, List<HealthMetric>>(MetricsNotifier.new);

class MetricsNotifier extends Notifier<List<HealthMetric>> {
  DatabaseService get _dbService => ref.read(databaseServiceProvider);
  SettingsService get _settingsService => ref.read(settingsServiceProvider);
  SyncService get _syncService => ref.read(syncServiceProvider);

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
    _triggerSync();
  }

  Future<void> updateMetric(HealthMetric metric) async {
    await _dbService.updateMetric(metric);
    await loadMetrics();
    _triggerSync();
  }

  Future<void> deleteMetric(int id) async {
    await _dbService.deleteMetric(id);
    await loadMetrics();
    _triggerSync();
  }

  Future<void> _triggerSync() async {
    if (await _settingsService.hasCredentials()) {
      final creds = await _settingsService.getCredentials();
      try {
        await _syncService.syncWithNextcloud(
          baseUrl: creds['url']!,
          username: creds['username']!,
          appPassword: creds['password']!,
        );
      } catch (e) {
        debugPrint('Background sync failed: $e');
      }
    }
  }
}
