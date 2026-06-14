import 'package:json_annotation/json_annotation.dart';

part 'health_metric.g.dart';

@JsonSerializable()
class HealthMetric {
  final int? id;
  final DateTime timestamp;
  final double? weight;
  final double? bodyFat;
  final int? visceralFat;
  final double? waistline;
  final bool isSynced;

  HealthMetric({
    this.id,
    required this.timestamp,
    this.weight,
    this.bodyFat,
    this.visceralFat,
    this.waistline,
    this.isSynced = false,
  });

  factory HealthMetric.fromJson(Map<String, dynamic> json) => _$HealthMetricFromJson(json);
  Map<String, dynamic> toJson() => _$HealthMetricToJson(this);

  HealthMetric copyWith({
    int? id,
    DateTime? timestamp,
    double? weight,
    double? bodyFat,
    int? visceralFat,
    double? waistline,
    bool? isSynced,
  }) {
    return HealthMetric(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      weight: weight ?? this.weight,
      bodyFat: bodyFat ?? this.bodyFat,
      visceralFat: visceralFat ?? this.visceralFat,
      waistline: waistline ?? this.waistline,
      isSynced: isSynced ?? this.isSynced,
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
    };
  }

  factory HealthMetric.fromMap(Map<String, dynamic> map) {
    return HealthMetric(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      weight: map['weight'],
      bodyFat: map['bodyFat'],
      visceralFat: map['visceralFat'],
      waistline: map['waistline'],
      isSynced: map['isSynced'] == 1,
    );
  }
}
