import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

class FlexibleDateTimeConverter implements JsonConverter<DateTime, Object?> {
  const FlexibleDateTimeConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json is Timestamp) return json.toDate().toUtc();
    if (json is DateTime) return json.toUtc();
    if (json is String) {
      final parsed = DateTime.tryParse(json);
      if (parsed != null) return parsed.toUtc();
    }
    return DateTime.now().toUtc();
  }

  @override
  Object? toJson(DateTime object) => object.toUtc().toIso8601String();
}

class FlexibleNullableDateTimeConverter
    implements JsonConverter<DateTime?, Object?> {
  const FlexibleNullableDateTimeConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate().toUtc();
    if (json is DateTime) return json.toUtc();
    if (json is String) {
      final parsed = DateTime.tryParse(json);
      if (parsed != null) return parsed.toUtc();
    }
    return null;
  }

  @override
  Object? toJson(DateTime? object) => object?.toUtc().toIso8601String();
}
