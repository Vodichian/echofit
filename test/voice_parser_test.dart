import 'package:flutter_test/flutter_test.dart';
import 'package:echofit/services/voice_parser.dart';

void main() {
  group('VoiceParser Tests', () {
    test('should parse weight', () {
      final result = VoiceParser.parse("Weight is 75.5 kilos");
      expect(result?.weight, 75.5);
    });

    test('should parse body fat', () {
      final result = VoiceParser.parse("Body fat is 15.2 percent");
      expect(result?.bodyFat, 15.2);
    });

    test('should parse visceral fat', () {
      final result = VoiceParser.parse("Visceral fat is 5");
      expect(result?.visceralFat, 5);
    });

    test('should parse waistline', () {
      final result = VoiceParser.parse("Waistline is 85");
      expect(result?.waistline, 85.0);
    });

    test('should parse journal entry/note', () {
      final result = VoiceParser.parse("Note is had a great workout today");
      expect(result?.journalEntry, "had a great workout today");
    });

    test('should parse journal entry with "comment"', () {
      final result = VoiceParser.parse("Comment is feeling a bit tired");
      expect(result?.journalEntry, "feeling a bit tired");
    });

    test('should parse journal entry with "journal entry"', () {
      final result = VoiceParser.parse("Journal entry is ate a healthy salad");
      expect(result?.journalEntry, "ate a healthy salad");
    });

    test('should parse multiple metrics including note', () {
      final result = VoiceParser.parse("Weight 80, body fat 18, and note felt strong");
      expect(result?.weight, 80.0);
      expect(result?.bodyFat, 18.0);
      expect(result?.journalEntry, "felt strong");
    });

    test('should handle case insensitivity', () {
      final result = VoiceParser.parse("WEIGHT 70.5 BODY FAT 15 NOTE TEST");
      expect(result?.weight, 70.5);
      expect(result?.bodyFat, 15.0);
      expect(result?.journalEntry, "test");
    });

    test('should return null for unrelated text', () {
      final result = VoiceParser.parse("The weather is nice today");
      expect(result, isNull);
    });
  });
}
