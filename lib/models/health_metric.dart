import 'package:json_annotation/json_annotation.dart';

part 'health_metric.g.dart';

@JsonSerializable()
class HealthMetric {
  final int? id;
  final DateTime timestamp;
  final double? weight;
  final double? bodyFat;
  final double? visceralFat;
  final double? waistline;
  final bool isSynced;
  final String? journalEntry;

  HealthMetric({
    this.id,
    required this.timestamp,
    this.weight,
    this.bodyFat,
    this.visceralFat,
    this.waistline,
    this.isSynced = false,
    this.journalEntry,
  });

  factory HealthMetric.fromJson(Map<String, dynamic> json) => _$HealthMetricFromJson(json);
  Map<String, dynamic> toJson() => _$HealthMetricToJson(this);

  HealthMetric copyWith({
    int? id,
    DateTime? timestamp,
    double? weight,
    double? bodyFat,
    double? visceralFat,
    double? waistline,
    bool? isSynced,
    String? journalEntry,
  }) {
    return HealthMetric(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      weight: weight ?? this.weight,
      bodyFat: bodyFat ?? this.bodyFat,
      visceralFat: visceralFat ?? this.visceralFat,
      waistline: waistline ?? this.waistline,
      isSynced: isSynced ?? this.isSynced,
      journalEntry: journalEntry ?? this.journalEntry,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'weight': weight,
      'bodyFat': bodyFat,
      'visceralFat': visceralFat,
      'waistline': waistline,
      'isSynced': isSynced ? 1 : 0,
      'journalEntry': journalEntry,
    };
  }

  factory HealthMetric.fromMap(Map<String, dynamic> map) {
    return HealthMetric(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      weight: (map['weight'] as num?)?.toDouble(),
      bodyFat: (map['bodyFat'] as num?)?.toDouble(),
      visceralFat: (map['visceralFat'] as num?)?.toDouble(),
      waistline: (map['waistline'] as num?)?.toDouble(),
      isSynced: map['isSynced'] == 1,
      journalEntry: map['journalEntry'],
    );
  }
}
