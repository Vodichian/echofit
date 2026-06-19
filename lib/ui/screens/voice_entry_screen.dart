import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/metrics_provider.dart';
import '../../services/voice_service.dart';
import '../../services/voice_parser.dart';
import '../../services/settings_service.dart';
import '../../services/sync_service.dart';

class VoiceEntryScreen extends StatefulWidget {
  const VoiceEntryScreen({super.key});

  @override
  State<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends State<VoiceEntryScreen> {
  final VoiceService _voiceService = VoiceService();
  final SettingsService _settingsService = SettingsService();
  final SyncService _syncService = SyncService();
  bool _isListening = false;
  String _recognizedText = "Tap the microphone and speak your metrics";

  @override
  void dispose() {
    _voiceService.cancelListening();
    super.dispose();
  }

  Future<void> _toggleListening(WidgetRef ref) async {
    debugPrint('VoiceEntryScreen: _toggleListening called. Current state: _isListening=$_isListening');
    if (_isListening) {
      await _voiceService.stopListening();
    } else {
      await _voiceService.startListening(
        onListeningChanged: (listening) {
          setState(() {
            _isListening = listening;
          });
        },
        onResult: (text, isFinal) async {
          setState(() {
            debugPrint('Recognized text: $text (isFinal: $isFinal)');
            _recognizedText = text;
          });

          if (isFinal) {
            final metric = VoiceParser.parse(text);
            if (metric != null) {
              await ref.read(metricsProvider.notifier).addMetric(metric);
              
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
                  debugPrint('Sync after voice entry failed: $e');
                }
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Saved and Synced: $text'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            }
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Voice Entry',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Say things like: "Weight is 75 kilos, body fat 15 percent"',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Text(
                      _recognizedText,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontStyle: _isListening ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 64),
                  GestureDetector(
                    onTap: () => _toggleListening(ref),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.red : Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? Colors.red : Theme.of(context).colorScheme.primary).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isListening)
                    const Text(
                      "Listening...",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
