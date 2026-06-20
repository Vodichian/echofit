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
import 'dart:math';

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
                    padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8, left: 8),
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

    // Grouping
    final leftMetrics = {'Weight', 'Waist'};
    final rightMetrics = {'Body Fat', 'Visceral'};

    final selectedLeft = settings.selectedMetrics.intersection(leftMetrics);
    final selectedRight = settings.selectedMetrics.intersection(rightMetrics);

    // Calculate Min/Max for each group
    double leftMin = double.infinity;
    double leftMax = double.negativeInfinity;
    double rightMin = double.infinity;
    double rightMax = double.negativeInfinity;

    for (var m in dataPoints) {
      if (selectedLeft.contains('Weight') && m.weight != null) {
        leftMin = min(leftMin, m.weight!);
        leftMax = max(leftMax, m.weight!);
      }
      if (selectedLeft.contains('Waist') && m.waistline != null) {
        leftMin = min(leftMin, m.waistline!);
        leftMax = max(leftMax, m.waistline!);
      }
      if (selectedRight.contains('Body Fat') && m.bodyFat != null) {
        rightMin = min(rightMin, m.bodyFat!);
        rightMax = max(rightMax, m.bodyFat!);
      }
      if (selectedRight.contains('Visceral') && m.visceralFat != null) {
        rightMin = min(rightMin, m.visceralFat!);
        rightMax = max(rightMax, m.visceralFat!);
      }
    }

    // Default values if no metrics in a group are selected
    if (leftMin == double.infinity) {
      leftMin = 0;
      leftMax = 100;
    } else {
      leftMin = (leftMin * 0.95).floorToDouble();
      leftMax = (leftMax * 1.05).ceilToDouble();
    }

    if (rightMin == double.infinity) {
      rightMin = 0;
      rightMax = 50;
    } else {
      rightMin = (rightMin * 0.9).floorToDouble();
      rightMax = (rightMax * 1.1).ceilToDouble();
    }

    // Ensure range is at least 1 to avoid division by zero
    if (leftMax == leftMin) leftMax += 1;
    if (rightMax == rightMin) rightMax += 1;

    double scaleValue(double val) {
      // Maps right values to left coordinate space
      return ((val - rightMin) / (rightMax - rightMin)) * (leftMax - leftMin) + leftMin;
    }

    List<LineChartBarData> lineBarsData = [];

    if (selectedLeft.contains('Weight')) {
      lineBarsData.addAll(_generateBars(dataPoints, (m) => m.weight, Colors.blue, 'Weight', settings, null));
    }
    if (selectedLeft.contains('Waist')) {
      lineBarsData.addAll(_generateBars(dataPoints, (m) => m.waistline, Colors.green, 'Waist', settings, null));
    }
    if (selectedRight.contains('Body Fat')) {
      lineBarsData.addAll(_generateBars(dataPoints, (m) => m.bodyFat, Colors.orange, 'Body Fat', settings, scaleValue));
    }
    if (selectedRight.contains('Visceral')) {
      lineBarsData.addAll(_generateBars(dataPoints, (m) => m.visceralFat, Colors.red, 'Visceral', settings, scaleValue));
    }

    return LineChart(
      LineChartData(
        minY: leftMin,
        maxY: leftMax,
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
                    style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: selectedLeft.isNotEmpty ? Text(selectedLeft.join('/'), style: const TextStyle(fontSize: 10)) : null,
            axisNameSize: 12,
            sideTitles: SideTitles(
              showTitles: selectedLeft.isNotEmpty,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(value.toStringAsFixed(0), style: TextStyle(fontSize: 10, color: Colors.blue.shade300)),
              ),
            ),
          ),
          rightTitles: AxisTitles(
            axisNameWidget: selectedRight.isNotEmpty ? Text(selectedRight.join('/'), style: const TextStyle(fontSize: 10)) : null,
            axisNameSize: 12,
            sideTitles: SideTitles(
              showTitles: selectedRight.isNotEmpty,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                // Inverse mapping: visualValue to original rightValue
                double originalValue = ((value - leftMin) / (leftMax - leftMin)) * (rightMax - rightMin) + rightMin;
                return SideTitleWidget(
                  meta: meta,
                  child: Text(originalValue.toStringAsFixed(1), style: TextStyle(fontSize: 10, color: Colors.orange.shade300)),
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
                // Get the actual original value
                double actualValue = spot.y;
                final barIndex = spot.barIndex;
                final barData = lineBarsData[barIndex];
                
                // If it was a scaled bar, we need to unscale it for the tooltip
                // We'll use a hack: check if the bar color matches our "right" colors
                if (barData.color == Colors.orange || barData.color == Colors.red || 
                    (barData.color?.withValues(alpha: 0.5) == Colors.orange.withValues(alpha: 0.5))) {
                   actualValue = ((spot.y - leftMin) / (leftMax - leftMin)) * (rightMax - rightMin) + rightMin;
                }

                return LineTooltipItem(
                  actualValue.toStringAsFixed(1),
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
    double Function(double)? scaler,
  ) {
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      final val = getValue(data[i]);
      if (val != null) {
        spots.add(FlSpot(i.toDouble(), scaler != null ? scaler(val) : val));
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
