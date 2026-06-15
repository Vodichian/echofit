import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/metrics_provider.dart';
import '../widgets/metric_card.dart';
import '../../models/health_metric.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(metricsProvider);
    final latest = metrics.isNotEmpty ? metrics.first : null;

    return Scaffold(
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
                  Text(
                    'Weight Trend',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 250,
                    padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: _WeightChart(metrics: metrics),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  title: Text('Weight: ${metric.weight ?? "--"} kg'),
                  subtitle: Text(metric.timestamp.toString().substring(0, 16)),
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

class _WeightChart extends StatelessWidget {
  final List<HealthMetric> metrics;
  const _WeightChart({required this.metrics});

  @override
  Widget build(BuildContext context) {
    if (metrics.length < 2) {
      return const Center(child: Text('Not enough data for chart'));
    }

    final dataPoints = metrics.reversed
        .where((m) => m.weight != null)
        .toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(dataPoints.length, (i) {
              return FlSpot(i.toDouble(), dataPoints[i].weight!);
            }),
            isCurved: true,
            color: Colors.blue,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
