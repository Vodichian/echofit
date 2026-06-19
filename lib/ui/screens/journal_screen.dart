import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/metrics_provider.dart';
import '../../models/health_metric.dart';
import '../widgets/manual_entry_dialog.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<HealthMetric> _getEventsForDay(DateTime day, List<HealthMetric> metrics) {
    return metrics.where((m) => isSameDay(m.timestamp, day)).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      final metrics = ref.read(metricsProvider);
      final events = _getEventsForDay(selectedDay, metrics);

      if (events.isNotEmpty) {
        _openEntry(events.first);
      } else {
        _promptCreateEntry(selectedDay);
      }
    }
  }

  void _openEntry(HealthMetric metric) {
    showDialog(
      context: context,
      builder: (context) => ManualEntryDialog(initialMetric: metric),
    );
  }

  void _promptCreateEntry(DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No entry found'),
        content: Text('Would you like to create a new health record for ${date.toString().substring(0, 10)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => ManualEntryDialog(initialDate: date),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(metricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
      ),
      body: Column(
        children: [
          TableCalendar<HealthMetric>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => _getEventsForDay(day, metrics),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              markersMaxCount: 1,
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildDetailsList(metrics),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsList(List<HealthMetric> metrics) {
    if (_selectedDay == null) return const SizedBox.shrink();

    final dayMetrics = _getEventsForDay(_selectedDay!, metrics);

    if (dayMetrics.isEmpty) {
      return Center(
        child: Text(
          'No records for this day',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: dayMetrics.length,
      itemBuilder: (context, index) {
        final metric = dayMetrics[index];
        return Card(
          child: ListTile(
            title: Text('Entry at ${metric.timestamp.toString().substring(11, 16)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (metric.weight != null) Text('Weight: ${metric.weight} kg'),
                if (metric.journalEntry != null)
                  Text(
                    'Note: ${metric.journalEntry}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openEntry(metric),
          ),
        );
      },
    );
  }
}
