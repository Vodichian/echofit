import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint('VoiceService: Microphone permission denied');
        return false;
      }
    }

    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
      );
    } catch (e) {
      debugPrint('VoiceService: Error during speech initialization: $e');
      _isInitialized = false;
    }

    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String, bool) onResult, // (text, isFinal)
    required Function(bool) onListeningChanged,
  }) async {
    bool ok = _isInitialized;
    if (!ok) {
      debugPrint('VoiceService: Initializing...');
      ok = await initialize();
    }

    if (!ok) {
      debugPrint('VoiceService: Initialization failed or permission denied');
      onListeningChanged(false);
      return;
    }

    debugPrint('VoiceService: Starting to listen...');
    onListeningChanged(true);
    
    try {
      // On some platforms (like Windows beta), passing complex options 
      // might cause issues. We'll use simpler options if needed.
      await _speech.listen(
        onResult: (result) {
          debugPrint('VoiceService: onResult - words: ${result.recognizedWords}, final: ${result.finalResult}');
          if (result.finalResult) {
            onListeningChanged(false);
          }
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (e) {
      debugPrint('VoiceService: Exception in listen(): $e');
      onListeningChanged(false);
    }
  }

  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('VoiceService: Error stopping: $e');
    }
  }

  Future<void> cancelListening() async {
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (e) {
      debugPrint('VoiceService: Error canceling: $e');
    }
  }

  bool get isListening => _speech.isListening;
}
