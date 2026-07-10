import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'exchange_api_client.dart';
import 'market_quote_live_client.dart';

enum MarketIndexStatus { idle, loading, loaded, failure }

enum MarketIndexLiveStatus { disconnected, connecting, live, failure }

class MarketIndexState {
  const MarketIndexState({
    required this.status,
    required this.indices,
    this.intradaySeriesByCode = const {},
    this.liveStatus = MarketIndexLiveStatus.disconnected,
    this.errorMessage,
    this.liveMessage,
    this.lastTickAt,
  });

  const MarketIndexState.idle()
      : status = MarketIndexStatus.idle,
        indices = const [],
        intradaySeriesByCode = const {},
        liveStatus = MarketIndexLiveStatus.disconnected,
        errorMessage = null,
        liveMessage = null,
        lastTickAt = null;

  final MarketIndexStatus status;
  final List<MarketIndex> indices;
  final Map<String, List<double>> intradaySeriesByCode;
  final MarketIndexLiveStatus liveStatus;
  final String? errorMessage;
  final String? liveMessage;
  final DateTime? lastTickAt;

  List<double> intradaySeriesFor(String indexCode) {
    return intradaySeriesByCode[indexCode] ?? const [];
  }

  MarketIndexState copyWith({
    MarketIndexStatus? status,
    List<MarketIndex>? indices,
    Map<String, List<double>>? intradaySeriesByCode,
    MarketIndexLiveStatus? liveStatus,
    String? errorMessage,
    String? liveMessage,
    DateTime? lastTickAt,
    bool clearErrorMessage = false,
  }) {
    return MarketIndexState(
      status: status ?? this.status,
      indices: indices ?? this.indices,
      intradaySeriesByCode: intradaySeriesByCode ?? this.intradaySeriesByCode,
      liveStatus: liveStatus ?? this.liveStatus,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      liveMessage: liveMessage ?? this.liveMessage,
      lastTickAt: lastTickAt ?? this.lastTickAt,
    );
  }
}

class MarketIndexSnapshot {
  const MarketIndexSnapshot({
    required this.dataSource,
    required this.indexCount,
    required this.indices,
  });

  final String dataSource;
  final int indexCount;
  final List<MarketIndex> indices;

  static MarketIndexSnapshot fromJson(Map<String, dynamic> json) {
    final values = json['indices'];
    return MarketIndexSnapshot(
      dataSource: _string(json['dataSource'], fallback: 'Stock-exchange-BE'),
      indexCount: json['indexCount'] is int ? json['indexCount'] as int : 0,
      indices: values is List
          ? values.map((value) => MarketIndex.fromJson(_map(value))).toList()
          : const [],
    );
  }
}

class MarketIndex {
  const MarketIndex({
    required this.indexCode,
    required this.indexName,
    required this.market,
    required this.currentValue,
    required this.changeSign,
    required this.changeValue,
    required this.changeRate,
    required this.accumulatedVolume,
    required this.accumulatedTradingValue,
    required this.openValue,
    required this.highValue,
    required this.lowValue,
    this.marketDataTime,
    required this.source,
  });

  final String indexCode;
  final String indexName;
  final String market;
  final String currentValue;
  final String changeSign;
  final String changeValue;
  final String changeRate;
  final int accumulatedVolume;
  final int accumulatedTradingValue;
  final String openValue;
  final String highValue;
  final String lowValue;
  final DateTime? marketDataTime;
  final String source;

  static MarketIndex fromJson(Map<String, dynamic> json) {
    return MarketIndex(
      indexCode: _string(json['indexCode'], fallback: ''),
      indexName: _string(json['indexName'], fallback: 'Korea Index'),
      market: _string(json['market'], fallback: 'KOREA'),
      currentValue: _string(json['currentValue'], fallback: '0'),
      changeSign: _string(json['changeSign'], fallback: ''),
      changeValue: _string(json['changeValue'], fallback: '0'),
      changeRate: _string(json['changeRate'], fallback: '0'),
      accumulatedVolume: _int(json['accumulatedVolume']),
      accumulatedTradingValue: _int(json['accumulatedTradingValue']),
      openValue: _string(json['openValue'], fallback: '0'),
      highValue: _string(json['highValue'], fallback: '0'),
      lowValue: _string(json['lowValue'], fallback: '0'),
      marketDataTime: _dateTime(json['marketDataTime']),
      source: _string(json['source'], fallback: 'KIS_WEBSOCKET_INDEX'),
    );
  }
}

class MarketIndexIntradaySnapshot {
  const MarketIndexIntradaySnapshot({
    required this.dataSource,
    required this.indexCode,
    required this.pointCount,
    required this.points,
  });

  final String dataSource;
  final String indexCode;
  final int pointCount;
  final List<MarketIndexIntradayPoint> points;

  static MarketIndexIntradaySnapshot fromJson(Map<String, dynamic> json) {
    final values = json['points'];
    return MarketIndexIntradaySnapshot(
      dataSource: _string(json['dataSource'], fallback: 'Stock-exchange-BE'),
      indexCode: _string(json['indexCode'], fallback: ''),
      pointCount: json['pointCount'] is int ? json['pointCount'] as int : 0,
      points: values is List
          ? values
              .map((value) => MarketIndexIntradayPoint.fromJson(_map(value)))
              .toList()
          : const [],
    );
  }
}

class MarketIndexIntradayPoint {
  const MarketIndexIntradayPoint({
    required this.bucketStart,
    required this.closeValue,
  });

  final DateTime? bucketStart;
  final double? closeValue;

  static MarketIndexIntradayPoint fromJson(Map<String, dynamic> json) {
    return MarketIndexIntradayPoint(
      bucketStart: _dateTime(json['bucketStart']),
      closeValue: _double(json['closeValue']),
    );
  }
}

class MarketIndexController extends ValueNotifier<MarketIndexState> {
  MarketIndexController({
    required ExchangeApiClient apiClient,
    MarketIndexLiveClient? liveClient,
    List<Duration> liveReconnectDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 3),
      Duration(seconds: 5),
    ],
  })  : _apiClient = apiClient,
        _liveClient = liveClient,
        _liveReconnectDelays = liveReconnectDelays,
        super(const MarketIndexState.idle());

  final ExchangeApiClient _apiClient;
  final MarketIndexLiveClient? _liveClient;
  final List<Duration> _liveReconnectDelays;
  StreamSubscription<Map<String, dynamic>>? _liveSubscription;
  Timer? _liveReconnectTimer;
  final Map<String, DateTime> _lastIndexTickBucketByCode = {};
  int _liveReconnectAttempt = 0;
  bool _isDisposed = false;

  bool get canSubscribeLive => _liveClient != null;

  Future<void> loadSnapshot() async {
    value = value.copyWith(status: MarketIndexStatus.loading);
    try {
      final response = await _apiClient.getMarketIndices();
      final snapshot = MarketIndexSnapshot.fromJson(response.data ?? {});
      final intradaySeriesByCode = await _loadIntradaySeries(snapshot.indices);
      final indices = _preferNewerLiveIndices(snapshot.indices, value.indices);
      _recordLatestIndexBuckets(indices);
      value = value.copyWith(
        status: MarketIndexStatus.loaded,
        indices: indices,
        intradaySeriesByCode: _mergeSnapshotCurrentPoints(
          indices,
          intradaySeriesByCode,
        ),
        clearErrorMessage: true,
      );
    } on ExchangeApiException catch (error) {
      value = value.copyWith(
        status: MarketIndexStatus.failure,
        errorMessage: error.message,
      );
    } on Object {
      value = value.copyWith(
        status: MarketIndexStatus.failure,
        errorMessage: 'Unable to load market indices.',
      );
    }
  }

  Future<void> subscribeLive() async {
    final liveClient = _liveClient;
    if (liveClient == null) {
      value = value.copyWith(
        liveStatus: MarketIndexLiveStatus.failure,
        liveMessage: 'Index WebSocket client is not configured.',
      );
      return;
    }
    if (_liveSubscription != null &&
        (value.liveStatus == MarketIndexLiveStatus.connecting ||
            value.liveStatus == MarketIndexLiveStatus.live)) {
      return;
    }
    _liveReconnectTimer?.cancel();
    _liveReconnectTimer = null;
    await _liveSubscription?.cancel();
    _liveSubscription = null;
    _liveReconnectAttempt = 0;
    value = value.copyWith(
      liveStatus: MarketIndexLiveStatus.connecting,
      liveMessage: 'Connecting index WebSocket.',
    );
    _openLiveSubscription(liveClient);
  }

  void _applyLiveIndex(MarketIndex tick) {
    final tickBucket = _indexTickBucket(tick.marketDataTime);
    final previousBucket = _lastIndexTickBucketByCode[tick.indexCode];
    if (tickBucket != null &&
        previousBucket != null &&
        tickBucket.isBefore(previousBucket)) {
      return;
    }
    final replacesLatestPoint = tickBucket != null &&
        previousBucket != null &&
        tickBucket == previousBucket;
    final nextIndices = List<MarketIndex>.of(value.indices);
    final index = nextIndices.indexWhere(
      (item) => item.indexCode == tick.indexCode,
    );
    if (index >= 0) {
      nextIndices[index] = tick;
    } else {
      nextIndices.add(tick);
    }
    _lastIndexTickBucketByCode[tick.indexCode] =
        tickBucket ?? DateTime.now().toUtc();
    _liveReconnectAttempt = 0;
    value = value.copyWith(
      status: MarketIndexStatus.loaded,
      indices: nextIndices,
      intradaySeriesByCode: replacesLatestPoint
          ? _replaceLatestIntradayPoint(value.intradaySeriesByCode, tick)
          : _appendIntradayPoint(value.intradaySeriesByCode, tick),
      liveStatus: MarketIndexLiveStatus.live,
      liveMessage: 'Live index ${tick.indexName} received.',
      lastTickAt: DateTime.now().toUtc(),
      clearErrorMessage: true,
    );
  }

  void _openLiveSubscription(MarketIndexLiveClient liveClient) {
    _liveSubscription = liveClient.subscribe().listen(
          (tick) => _applyLiveIndex(MarketIndex.fromJson(tick)),
          onError: (_) => _scheduleLiveReconnect(liveClient,
              reason: 'Index WebSocket disconnected.'),
          onDone: () => _scheduleLiveReconnect(liveClient,
              reason: 'Index WebSocket closed.'),
        );
  }

  void _scheduleLiveReconnect(
    MarketIndexLiveClient liveClient, {
    required String reason,
  }) {
    if (_isDisposed) {
      return;
    }
    final delays = _liveReconnectDelays;
    final delay = delays.isEmpty
        ? const Duration(seconds: 5)
        : delays[_liveReconnectAttempt.clamp(0, delays.length - 1)];
    _liveReconnectAttempt += 1;
    _liveReconnectTimer?.cancel();
    value = value.copyWith(
      liveStatus: MarketIndexLiveStatus.connecting,
      liveMessage:
          '$reason Reconnecting index WebSocket in ${delay.inSeconds}s.',
    );
    _liveReconnectTimer = Timer(delay, () {
      if (_isDisposed) {
        return;
      }
      _liveSubscription = null;
      _openLiveSubscription(liveClient);
    });
  }

  List<MarketIndex> _preferNewerLiveIndices(
    List<MarketIndex> snapshotIndices,
    List<MarketIndex> visibleIndices,
  ) {
    final visibleByCode = {
      for (final index in visibleIndices) index.indexCode: index,
    };
    return snapshotIndices.map((snapshotIndex) {
      final liveIndex = visibleByCode[snapshotIndex.indexCode];
      if (liveIndex == null ||
          !_isLaterMarketDataTime(
            liveIndex.marketDataTime,
            snapshotIndex.marketDataTime,
          )) {
        return snapshotIndex;
      }
      return liveIndex;
    }).toList(growable: false);
  }

  void _recordLatestIndexBuckets(Iterable<MarketIndex> indices) {
    for (final index in indices) {
      final bucket = _indexTickBucket(index.marketDataTime);
      if (bucket != null) {
        _lastIndexTickBucketByCode[index.indexCode] = bucket;
      }
    }
  }

  Future<Map<String, List<double>>> _loadIntradaySeries(
    List<MarketIndex> indices,
  ) async {
    final entries = await Future.wait(
      indices.map((index) async {
        try {
          final response = await _apiClient.getMarketIndexIntraday(
            indexCode: index.indexCode,
            limit: 390,
          );
          final snapshot = MarketIndexIntradaySnapshot.fromJson(
            response.data ?? {},
          );
          final values = snapshot.points
              .where((point) => point.bucketStart != null)
              .map((point) => point.closeValue)
              .whereType<double>()
              .toList(growable: false);
          return MapEntry(index.indexCode, values);
        } on Object {
          return MapEntry(index.indexCode, const <double>[]);
        }
      }),
    );
    return {
      for (final entry in entries)
        if (entry.value.isNotEmpty) entry.key: entry.value,
    };
  }

  @override
  void dispose() {
    _isDisposed = true;
    _liveReconnectTimer?.cancel();
    _liveSubscription?.cancel();
    super.dispose();
  }
}

Map<String, List<double>> _mergeSnapshotCurrentPoints(
  List<MarketIndex> indices,
  Map<String, List<double>> existing,
) {
  final next = <String, List<double>>{
    for (final entry in existing.entries)
      entry.key: List<double>.of(entry.value),
  };
  for (final index in indices) {
    next[index.indexCode] = _appendSeriesPoint(
      next[index.indexCode] ?? const [],
      _double(index.currentValue),
    );
  }
  return next;
}

Map<String, List<double>> _appendIntradayPoint(
  Map<String, List<double>> existing,
  MarketIndex tick,
) {
  final next = <String, List<double>>{
    for (final entry in existing.entries)
      entry.key: List<double>.of(entry.value),
  };
  next[tick.indexCode] = _appendSeriesPoint(
    next[tick.indexCode] ?? const [],
    _double(tick.currentValue),
  );
  return next;
}

Map<String, List<double>> _replaceLatestIntradayPoint(
  Map<String, List<double>> existing,
  MarketIndex tick,
) {
  final next = <String, List<double>>{
    for (final entry in existing.entries)
      entry.key: List<double>.of(entry.value),
  };
  final value = _double(tick.currentValue);
  final series = next[tick.indexCode];
  if (value == null || series == null || series.isEmpty) {
    return _appendIntradayPoint(next, tick);
  }
  series[series.length - 1] = value;
  return next;
}

DateTime? _indexTickBucket(DateTime? timestamp) {
  if (timestamp == null) {
    return null;
  }
  final utc = timestamp.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day, utc.hour, utc.minute);
}

bool _isLaterMarketDataTime(DateTime? candidate, DateTime? baseline) {
  if (candidate == null) {
    return false;
  }
  if (baseline == null) {
    return true;
  }
  return candidate.toUtc().isAfter(baseline.toUtc());
}

List<double> _appendSeriesPoint(List<double> series, double? value) {
  if (value == null) {
    return series;
  }
  if (series.isNotEmpty && series.last == value) {
    return series;
  }
  final next = [...series, value];
  const maxPoints = 420;
  if (next.length <= maxPoints) {
    return next;
  }
  return next.sublist(next.length - maxPoints);
}

class MarketIndexLiveClient {
  MarketIndexLiveClient({
    required Uri baseUri,
    QuoteSocketConnector? socketConnector,
  })  : _baseUri = baseUri,
        _socketConnector =
            socketConnector ?? ((uri) => WebSocketQuoteSocketConnection(uri));

  final Uri _baseUri;
  final QuoteSocketConnector _socketConnector;

  Uri get webSocketUri {
    final scheme = _baseUri.scheme == 'https' ? 'wss' : 'ws';
    final normalizedBasePath = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;
    return _baseUri.replace(
      scheme: scheme,
      path: '$normalizedBasePath/ws/market',
      query: null,
    );
  }

  Stream<Map<String, dynamic>> subscribe() {
    final connection = _socketConnector(webSocketUri);
    late final StreamSubscription<dynamic> socketSubscription;
    late final StreamController<Map<String, dynamic>> controller;

    void sendFrame(
      String command,
      Map<String, String> headers, [
      String? body,
    ]) {
      final buffer = StringBuffer(command)..write('\n');
      headers.forEach((key, value) {
        buffer.write('$key:$value\n');
      });
      buffer
        ..write('\n')
        ..write(body ?? '')
        ..write('\u0000');
      connection.add(buffer.toString());
    }

    void handleFrame(String frame) {
      if (frame.startsWith('CONNECTED')) {
        sendFrame('SUBSCRIBE', {
          'id': 'market-index',
          'destination': '/topic/market/indices',
          'ack': 'auto',
        });
        return;
      }
      if (!frame.startsWith('MESSAGE')) {
        return;
      }
      final separator = frame.indexOf('\n\n');
      if (separator < 0) {
        return;
      }
      final body = frame.substring(separator + 2).trim();
      if (body.isEmpty) {
        return;
      }
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        controller.add(decoded.map((key, value) => MapEntry('$key', value)));
      }
    }

    controller = StreamController<Map<String, dynamic>>(
      onListen: () {
        socketSubscription = connection.stream.listen(
          (event) {
            final payload = event is List<int>
                ? utf8.decode(event)
                : event?.toString() ?? '';
            for (final frame in payload.split('\u0000')) {
              if (frame.trim().isNotEmpty) {
                handleFrame(frame);
              }
            }
          },
          onError: controller.addError,
          onDone: controller.close,
        );
        sendFrame('CONNECT', {
          'accept-version': '1.2',
          'heart-beat': '10000,10000',
        });
      },
      onCancel: () async {
        await socketSubscription.cancel();
        await connection.close();
      },
    );

    return controller.stream;
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry('$key', value));
  }
  return const {};
}

String _string(Object? value, {required String fallback}) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString();
  return text.isEmpty ? fallback : text;
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

double? _double(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString().replaceAll(',', '').trim() ?? '');
}

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
