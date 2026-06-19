// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_metric.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthMetric _$HealthMetricFromJson(Map<String, dynamic> json) => HealthMetric(
  id: (json['id'] as num?)?.toInt(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  weight: (json['weight'] as num?)?.toDouble(),
  bodyFat: (json['bodyFat'] as num?)?.toDouble(),
  visceralFat: (json['visceralFat'] as num?)?.toDouble(),
  waistline: (json['waistline'] as num?)?.toDouble(),
  isSynced: json['isSynced'] as bool? ?? false,
  journalEntry: json['journalEntry'] as String?,
);

Map<String, dynamic> _$HealthMetricToJson(HealthMetric instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'weight': instance.weight,
      'bodyFat': instance.bodyFat,
      'visceralFat': instance.visceralFat,
      'waistline': instance.waistline,
      'isSynced': instance.isSynced,
      'journalEntry': instance.journalEntry,
    };
