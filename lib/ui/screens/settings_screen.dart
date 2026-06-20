import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/settings_service.dart';
import '../../services/sync_service.dart';
import '../../utils/backup_pruning_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  final _syncService = SyncService();
  
  final _urlController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  bool _isSaving = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final creds = await _settingsService.getCredentials();
    setState(() {
      _urlController.text = creds['url'] ?? '';
      _userController.text = creds['username'] ?? '';
      _passController.text = creds['password'] ?? '';
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    await _settingsService.saveCredentials(
      _urlController.text.trim(),
      _userController.text.trim(),
      _passController.text.trim(),
    );
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  Future<void> _triggerSync() async {
    final creds = await _settingsService.getCredentials();
    if (creds['url'] == null || creds['username'] == null || creds['password'] == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please save credentials first')),
        );
      }
      return;
    }

    setState(() => _isSyncing = true);
    try {
      await _syncService.syncWithNextcloud(
        baseUrl: creds['url']!,
        username: creds['username']!,
        appPassword: creds['password']!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _showRestoreDialog() async {
    final creds = await _settingsService.getCredentials();
    if (creds['url'] == null || creds['username'] == null || creds['password'] == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please save credentials first')),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final backups = await _syncService.getAvailableBackups(
        baseUrl: creds['url']!,
        username: creds['username']!,
        appPassword: creds['password']!,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading indicator

      if (backups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No backups found on server')),
        );
        return;
      }

      // Sort backups descending
      backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Backup to Restore'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: backups.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(backups[index].timestamp)),
                  subtitle: Text(backups[index].path.split('/').last),
                  onTap: () => Navigator.pop(context, backups[index]),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ).then((selectedBackup) async {
        if (selectedBackup is BackupFile && mounted) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Restore'),
              content: const Text('This will replace ALL local data with the selected backup. This cannot be undone. Are you sure?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('Restore'),
                ),
              ],
            ),
          );

          if (confirm == true && mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );

            try {
              await _syncService.importFromBackup(
                backupUrl: selectedBackup.path,
                username: creds['username']!,
                appPassword: creds['password']!,
              );
              if (mounted) {
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data restored successfully')),
                );
              }
            } catch (e) {
              if (mounted) {
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Restore failed: $e')),
                );
              }
            }
          }
        }
      });
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch backups: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Nextcloud Configuration',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your Nextcloud credentials to enable synchronization across devices.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'https://nextcloud.yourdomain.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.dns_outlined),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _userController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passController,
            decoration: const InputDecoration(
              labelText: 'App Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isSyncing ? null : _triggerSync,
            icon: _isSyncing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync),
            label: const Text('Sync Now'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Backup & Recovery',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Restore your data from a previous synchronization point.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isSyncing ? null : _showRestoreDialog,
            icon: const Icon(Icons.settings_backup_restore),
            label: const Text('Restore from Backup'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
}
