import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/chart_settings_provider.dart';
import '../widgets/metric_card.dart';
import '../widgets/manual_entry_dialog.dart';
import '../../models/health_metric.dart';
import '../../utils/regression_utils.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showChartSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final currentSettings = ref.watch(chartSettingsProvider);
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chart Settings', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Show Data Points'),
                    value: currentSettings.showDataPoints,
                    onChanged: (val) => ref.read(chartSettingsProvider.notifier).toggleDataPoints(val),
                  ),
                  SwitchListTile(
                    title: const Text('Show Predictive Trends'),
                    value: currentSettings.showPredictions,
                    onChanged: (val) => ref.read(chartSettingsProvider.notifier).togglePredictions(val),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(metricsProvider);
    final latest = metrics.isNotEmpty ? metrics.first : null;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const ManualEntryDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Metric'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('EchoFit Dashboard'),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest Metrics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.2,
                        children: [
                          MetricCard(
                            title: 'Weight',
                            value: latest?.weight?.toString() ?? '--',
                            unit: 'kg',
                            icon: Icons.monitor_weight_outlined,
                            color: Colors.blue,
                          ),
                          MetricCard(
                            title: 'Body Fat',
                            value: latest?.bodyFat?.toString() ?? '--',
                            unit: '%',
                            icon: Icons.percent,
                            color: Colors.orange,
                          ),
                          MetricCard(
                            title: 'Visceral',
                            value: latest?.visceralFat?.toString() ?? '--',
                            unit: 'lvl',
                            icon: Icons.opacity,
                            color: Colors.red,
                          ),
                          MetricCard(
                            title: 'Waist',
                            value: latest?.waistline?.toString() ?? '--',
                            unit: 'cm',
                            icon: Icons.straighten,
                            color: Colors.green,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trends',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => _showChartSettings(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const _ChartMetricSelector(),
                  const SizedBox(height: 16),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.only(right: 24, top: 16, bottom: 8, left: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: _TrendChart(metrics: metrics),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final metric = metrics[index];
                return ListTile(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => ManualEntryDialog(initialMetric: metric),
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  title: Text('Weight: ${metric.weight ?? "--"} kg'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(metric.timestamp.toString().substring(0, 16)),
                      if (metric.journalEntry != null && metric.journalEntry!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Note: ${metric.journalEntry}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                  trailing: Icon(
                    metric.isSynced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                    size: 18,
                    color: metric.isSynced ? Colors.green : Colors.grey,
                  ),
                );
              },
              childCount: metrics.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _ChartMetricSelector extends ConsumerWidget {
  const _ChartMetricSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(chartSettingsProvider);
    final metricsLabels = ['Weight', 'Body Fat', 'Visceral', 'Waist'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: metricsLabels.map((metric) {
          final isSelected = settings.selectedMetrics.contains(metric);
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(metric),
              selected: isSelected,
              onSelected: (_) => ref.read(chartSettingsProvider.notifier).toggleMetric(metric),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TrendChart extends ConsumerWidget {
  final List<HealthMetric> metrics;
  const _TrendChart({required this.metrics});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (metrics.length < 2) {
      return const Center(child: Text('Not enough data for chart'));
    }

    final settings = ref.watch(chartSettingsProvider);
    final dataPoints = metrics.reversed.toList();

    List<LineChartBarData> lineBarsData = [];

    if (settings.selectedMetrics.contains('Weight')) {
      lineBarsData.addAll(_generateBars(dataPoints, (m) => m.weight, Colors.blue, 'Weight', settings));
    }
    if (settings.selectedMetrics.contains('Body Fat')) {
      lineBarsData.addAll(_generateBars(dataPoints, (m) => m.bodyFat, Colors.orange, 'Body Fat', settings));
    }
    if (settings.selectedMetrics.contains('Visceral')) {
      lineBarsData.addAll(_generateBars(dataPoints, (m) => m.visceralFat, Colors.red, 'Visceral', settings));
    }
    if (settings.selectedMetrics.contains('Waist')) {
      lineBarsData.addAll(_generateBars(dataPoints, (m) => m.waistline, Colors.green, 'Waist', settings));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (dataPoints.length / 5).clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= dataPoints.length) return const SizedBox();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    DateFormat('MMM d').format(dataPoints[index].timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: lineBarsData,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Theme.of(context).colorScheme.surfaceContainerHigh,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  spot.y.toStringAsFixed(1),
                  TextStyle(
                    color: spot.bar.color ?? Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<LineChartBarData> _generateBars(
    List<HealthMetric> data,
    double? Function(HealthMetric) getValue,
    Color color,
    String label,
    ChartSettings settings,
  ) {
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      final val = getValue(data[i]);
      if (val != null) {
        spots.add(FlSpot(i.toDouble(), val));
      }
    }

    if (spots.isEmpty) return [];

    List<LineChartBarData> bars = [
      LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(show: settings.showDataPoints),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.1),
        ),
      ),
    ];

    if (settings.showPredictions && spots.length >= 2) {
      final regression = calculateLinearRegression(spots);
      final lastX = spots.last.x;
      final predictionSpots = [
        spots.last,
        FlSpot(lastX + 1, regression.predict(lastX + 1)),
        FlSpot(lastX + 2, regression.predict(lastX + 2)),
      ];

      bars.add(
        LineChartBarData(
          spots: predictionSpots,
          isCurved: false,
          color: color.withValues(alpha: 0.5),
          barWidth: 2,
          isStrokeCapRound: true,
          dashArray: [5, 5],
          dotData: const FlDotData(show: false),
        ),
      );
    }

    return bars;
  }
}
