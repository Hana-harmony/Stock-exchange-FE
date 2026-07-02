part of '../notification_controller.dart';

const Object _copyWithUndefined = Object();

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

String _string(Object? value, {required String fallback}) {
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

String? _nullableString(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value.map((item) => item.toString()).toList();
}

List<AlertGlossaryTerm> _glossaryTerms(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .map((item) => AlertGlossaryTerm.fromJson(_map(item)))
      .where((term) => term.displayLabel.isNotEmpty)
      .toList();
}

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
