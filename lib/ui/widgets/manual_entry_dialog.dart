import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/health_metric.dart';
import '../../providers/metrics_provider.dart';
import '../../services/settings_service.dart';
import '../../services/sync_service.dart';

class ManualEntryDialog extends ConsumerStatefulWidget {
  final HealthMetric? initialMetric;
  final DateTime? initialDate;

  const ManualEntryDialog({
    super.key,
    this.initialMetric,
    this.initialDate,
  });

  @override
  ConsumerState<ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends ConsumerState<ManualEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _bodyFatController;
  late final TextEditingController _visceralFatController;
  late final TextEditingController _waistlineController;
  late final TextEditingController _journalController;

  final SettingsService _settingsService = SettingsService();
  final SyncService _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    final metric = widget.initialMetric;
    
    // If we're not editing, we might still want to pre-fill from the latest metric
    // unless a specific date was provided (which usually means a new entry for that date).
    HealthMetric? prefillSource;
    if (metric != null) {
      prefillSource = metric;
    } else if (widget.initialDate == null) {
      final metrics = ref.read(metricsProvider);
      prefillSource = metrics.isNotEmpty ? metrics.first : null;
    }

    _weightController = TextEditingController(text: prefillSource?.weight?.toString() ?? '');
    _bodyFatController = TextEditingController(text: prefillSource?.bodyFat?.toString() ?? '');
    _visceralFatController = TextEditingController(text: prefillSource?.visceralFat?.toString() ?? '');
    _waistlineController = TextEditingController(text: prefillSource?.waistline?.toString() ?? '');
    _journalController = TextEditingController(text: prefillSource?.journalEntry ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _visceralFatController.dispose();
    _waistlineController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  void _adjustValue(TextEditingController controller, double delta, {bool isInt = false}) {
    double current = double.tryParse(controller.text) ?? 0.0;
    double newValue = current + delta;
    if (newValue < 0) newValue = 0;
    
    if (isInt) {
      controller.text = newValue.round().toString();
    } else {
      controller.text = double.parse(newValue.toStringAsFixed(2)).toString();
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final weight = double.tryParse(_weightController.text);
      final bodyFat = double.tryParse(_bodyFatController.text);
      final visceralFat = double.tryParse(_visceralFatController.text);
      final waistline = double.tryParse(_waistlineController.text);
      final journalEntry = _journalController.text.isNotEmpty ? _journalController.text : null;

      if (weight == null && bodyFat == null && visceralFat == null && waistline == null && journalEntry == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter at least one metric or a note')),
        );
        return;
      }

      final metric = (widget.initialMetric ?? HealthMetric(timestamp: widget.initialDate ?? DateTime.now())).copyWith(
        weight: weight,
        bodyFat: bodyFat,
        visceralFat: visceralFat,
        waistline: waistline,
        journalEntry: journalEntry,
        isSynced: false, // Mark as unsynced after update
      );

      if (widget.initialMetric != null) {
        await ref.read(metricsProvider.notifier).updateMetric(metric);
      } else {
        await ref.read(metricsProvider.notifier).addMetric(metric);
      }

      // Trigger Sync
      if (await _settingsService.hasCredentials()) {
        final creds = await _settingsService.getCredentials();
        try {
          await _syncService.syncWithNextcloud(
            baseUrl: creds['url']!,
            username: creds['username']!,
            appPassword: creds['password']!,
          );
        } catch (e) {
          debugPrint('Sync after manual entry failed: $e');
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.initialMetric != null ? 'Metric updated' : 'Metric saved')),
        );
      }
    }
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double increment,
    bool isInt = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _adjustValue(controller, -increment, isInt: isInt),
            icon: const Icon(Icons.remove_circle_outline),
            color: Colors.redAccent,
          ),
          IconButton(
            onPressed: () => _adjustValue(controller, increment, isInt: isInt),
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialMetric != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Health Metric' : 'Add Health Metric'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.initialDate != null || isEditing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Date: ${(widget.initialMetric?.timestamp ?? widget.initialDate!).toString().substring(0, 10)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              _buildNumericField(
                controller: _weightController,
                label: 'Weight (kg)',
                icon: Icons.monitor_weight_outlined,
                increment: 0.1,
              ),
              _buildNumericField(
                controller: _bodyFatController,
                label: 'Body Fat (%)',
                icon: Icons.percent,
                increment: 0.1,
              ),
              _buildNumericField(
                controller: _visceralFatController,
                label: 'Visceral Fat (lvl)',
                icon: Icons.opacity,
                increment: 0.5,
              ),
              _buildNumericField(
                controller: _waistlineController,
                label: 'Waistline (cm)',
                icon: Icons.straighten,
                increment: 0.5,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _journalController,
                decoration: const InputDecoration(
                  labelText: 'Journal Entry / Notes',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (isEditing)
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Entry?'),
                  content: const Text('Are you sure you want to delete this health record?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await ref.read(metricsProvider.notifier).deleteMetric(widget.initialMetric!.id!);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
