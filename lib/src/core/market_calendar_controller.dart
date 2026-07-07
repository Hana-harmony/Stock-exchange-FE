import 'package:flutter/foundation.dart';

import 'exchange_api_client.dart';

enum MarketCalendarStatus { idle, loading, loaded, failure }

class MarketCalendarState {
  const MarketCalendarState({
    required this.status,
    this.calendar,
    this.errorMessage,
  });

  const MarketCalendarState.idle()
      : status = MarketCalendarStatus.idle,
        calendar = null,
        errorMessage = null;

  const MarketCalendarState.loading({this.calendar})
      : status = MarketCalendarStatus.loading,
        errorMessage = null;

  const MarketCalendarState.loaded({required this.calendar})
      : status = MarketCalendarStatus.loaded,
        errorMessage = null;

  const MarketCalendarState.failure({required this.errorMessage, this.calendar})
      : status = MarketCalendarStatus.failure;

  final MarketCalendarStatus status;
  final MarketCalendar? calendar;
  final String? errorMessage;
}

class MarketCalendarController extends ValueNotifier<MarketCalendarState> {
  MarketCalendarController({required ExchangeApiClient apiClient})
      : _apiClient = apiClient,
        super(const MarketCalendarState.idle());

  final ExchangeApiClient _apiClient;

  Future<void> load({int limit = 6}) async {
    value = MarketCalendarState.loading(calendar: value.calendar);
    try {
      final response = await _apiClient.getMarketCalendar(limit: limit);
      value = MarketCalendarState.loaded(
        calendar: MarketCalendar.fromJson(response.data ?? {}),
      );
    } on ExchangeApiException catch (error) {
      value = MarketCalendarState.failure(
        errorMessage: error.message,
        calendar: value.calendar,
      );
    } on Object {
      value = MarketCalendarState.failure(
        errorMessage: 'Unable to load Korea market calendar.',
        calendar: value.calendar,
      );
    }
  }
}

class MarketCalendar {
  const MarketCalendar({
    required this.dataSource,
    required this.market,
    required this.timezone,
    required this.currentStatus,
    required this.eventCount,
    required this.events,
    this.currentTime,
    this.currentDate,
    this.servedAt,
  });

  final String dataSource;
  final String market;
  final String timezone;
  final DateTime? currentTime;
  final String? currentDate;
  final String currentStatus;
  final int eventCount;
  final List<MarketCalendarEvent> events;
  final DateTime? servedAt;

  static MarketCalendar fromJson(Map<String, dynamic> json) {
    final eventValues = json['events'] is List
        ? json['events'] as List<Object?>
        : const <Object?>[];
    return MarketCalendar(
      dataSource: _string(json['dataSource'], fallback: ''),
      market: _string(json['market'], fallback: 'KOSPI/KOSDAQ'),
      timezone: _string(json['timezone'], fallback: 'Asia/Seoul'),
      currentTime: _dateTime(json['currentTime']),
      currentDate: _nullableString(json['currentDate']),
      currentStatus: _string(json['currentStatus'], fallback: 'CLOSED'),
      eventCount: _int(json['eventCount']),
      events: eventValues
          .map((value) => MarketCalendarEvent.fromJson(_map(value)))
          .toList(growable: false),
      servedAt: _dateTime(json['servedAt']),
    );
  }
}

class MarketCalendarEvent {
  const MarketCalendarEvent({
    required this.eventId,
    required this.title,
    required this.market,
    required this.eventType,
    required this.timeLabel,
    required this.dateLabel,
    required this.importance,
    required this.status,
    required this.minutesUntil,
    this.scheduledAt,
  });

  final String eventId;
  final String title;
  final String market;
  final String eventType;
  final DateTime? scheduledAt;
  final String timeLabel;
  final String dateLabel;
  final String importance;
  final String status;
  final int minutesUntil;

  static MarketCalendarEvent fromJson(Map<String, dynamic> json) {
    return MarketCalendarEvent(
      eventId: _string(json['eventId'], fallback: ''),
      title: _string(json['title'], fallback: 'Korea market event'),
      market: _string(json['market'], fallback: 'KOSPI/KOSDAQ'),
      eventType: _string(json['eventType'], fallback: ''),
      scheduledAt: _dateTime(json['scheduledAt']),
      timeLabel: _string(json['timeLabel'], fallback: ''),
      dateLabel: _string(json['dateLabel'], fallback: ''),
      importance: _string(json['importance'], fallback: 'MEDIUM'),
      status: _string(json['status'], fallback: 'UPCOMING'),
      minutesUntil: _int(json['minutesUntil']),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry('$key', value));
  }
  return {};
}

String _string(Object? value, {required String fallback}) {
  if (value == null) {
    return fallback;
  }
  final text = '$value';
  return text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  if (value == null) {
    return null;
  }
  final text = '$value'.trim();
  return text.isEmpty ? null : text;
}

int _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? 0;
}

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
