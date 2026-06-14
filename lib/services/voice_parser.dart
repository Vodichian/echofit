import '../models/health_metric.dart';

class VoiceParser {
  /// Parses a string for health metrics.
  /// Example: "Weight is 75.5 kilos and body fat is 15 percent"
  static HealthMetric? parse(String text) {
    text = text.toLowerCase();
    
    double? weight;
    double? bodyFat;
    int? visceralFat;
    double? waistline;

    // Weight regex: "weight (is)? 75.5"
    final weightRegex = RegExp(r'weight(?:\s+is)?\s+(\d+(?:\.\d+)?)');
    final weightMatch = weightRegex.firstMatch(text);
    if (weightMatch != null) {
      weight = double.tryParse(weightMatch.group(1)!);
    }

    // Body fat regex: "body fat (is)? 15"
    final bodyFatRegex = RegExp(r'body\s+fat(?:\s+is)?\s+(\d+(?:\.\d+)?)');
    final bodyFatMatch = bodyFatRegex.firstMatch(text);
    if (bodyFatMatch != null) {
      bodyFat = double.tryParse(bodyFatMatch.group(1)!);
    }

    // Visceral fat regex: "visceral fat (is)? 5"
    final visceralFatRegex = RegExp(r'visceral\s+fat(?:\s+is)?\s+(\d+)');
    final visceralFatMatch = visceralFatRegex.firstMatch(text);
    if (visceralFatMatch != null) {
      visceralFat = int.tryParse(visceralFatMatch.group(1)!);
    }

    // Waistline regex: "waistline (is)? 85" or "waist (is)? 85"
    final waistlineRegex = RegExp(r'waist(?:line)?(?:\s+is)?\s+(\d+(?:\.\d+)?)');
    final waistlineMatch = waistlineRegex.firstMatch(text);
    if (waistlineMatch != null) {
      waistline = double.tryParse(waistlineMatch.group(1)!);
    }

    if (weight == null && bodyFat == null && visceralFat == null && waistline == null) {
      return null;
    }

    return HealthMetric(
      timestamp: DateTime.now(),
      weight: weight,
      bodyFat: bodyFat,
      visceralFat: visceralFat,
      waistline: waistline,
    );
  }
}
