import 'package:flutter_test/flutter_test.dart';
import 'package:echofit/services/voice_parser.dart';

void main() {
  test('VoiceParser should parse weight', () {
    final result = VoiceParser.parse("Weight is 75.5 kilos");
    expect(result?.weight, 75.5);
  });

  test('VoiceParser should parse body fat', () {
    final result = VoiceParser.parse("Body fat is 15.2 percent");
    expect(result?.bodyFat, 15.2);
  });

  test('VoiceParser should parse visceral fat', () {
    final result = VoiceParser.parse("Visceral fat is 5");
    expect(result?.visceralFat, 5);
  });

  test('VoiceParser should parse waistline', () {
    final result = VoiceParser.parse("Waistline is 85");
    expect(result?.waistline, 85.0);
  });

  test('VoiceParser should parse multiple metrics', () {
    final result = VoiceParser.parse("Weight 80, body fat 18, and waist 90");
    expect(result?.weight, 80.0);
    expect(result?.bodyFat, 18.0);
    expect(result?.waistline, 90.0);
    expect(result?.visceralFat, isNull);
  });

  test('VoiceParser should return null for no metrics', () {
    final result = VoiceParser.parse("Hello how are you");
    expect(result, isNull);
  });
}
