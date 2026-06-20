import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChartSettings {
  final Set<String> selectedMetrics;
  final bool showDataPoints;
  final bool showPredictions;

  ChartSettings({
    required this.selectedMetrics,
    required this.showDataPoints,
    required this.showPredictions,
  });

  ChartSettings copyWith({
    Set<String>? selectedMetrics,
    bool? showDataPoints,
    bool? showPredictions,
  }) {
    return ChartSettings(
      selectedMetrics: selectedMetrics ?? this.selectedMetrics,
      showDataPoints: showDataPoints ?? this.showDataPoints,
      showPredictions: showPredictions ?? this.showPredictions,
    );
  }
}

class ChartSettingsNotifier extends Notifier<ChartSettings> {
  @override
  ChartSettings build() {
    return ChartSettings(
      selectedMetrics: {'Weight'},
      showDataPoints: true,
      showPredictions: false,
    );
  }

  void toggleMetric(String metric) {
    final newMetrics = Set<String>.from(state.selectedMetrics);
    if (newMetrics.contains(metric)) {
      if (newMetrics.length > 1) {
        newMetrics.remove(metric);
      }
    } else {
      newMetrics.add(metric);
    }
    state = state.copyWith(selectedMetrics: newMetrics);
  }

  void toggleDataPoints(bool value) {
    state = state.copyWith(showDataPoints: value);
  }

  void togglePredictions(bool value) {
    state = state.copyWith(showPredictions: value);
  }
}

final chartSettingsProvider = NotifierProvider<ChartSettingsNotifier, ChartSettings>(ChartSettingsNotifier.new);
