import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'exchange_api_client.dart';
import 'market_quote_live_client.dart';

enum MarketIndexStatus {
  idle,
  loading,
  loaded,
  failure,
}

enum MarketIndexLiveStatus {
  disconnected,
  connecting,
  live,
  failure,
}

class MarketIndexState {
  const MarketIndexState({
    required this.status,
    required this.indices,
    this.liveStatus = MarketIndexLiveStatus.disconnected,
    this.errorMessage,
    this.liveMessage,
    this.lastTickAt,
  });

  const MarketIndexState.idle()
      : status = MarketIndexStatus.idle,
        indices = const [],
        liveStatus = MarketIndexLiveStatus.disconnected,
        errorMessage = null,
        liveMessage = null,
        lastTickAt = null;

  final MarketIndexStatus status;
  final List<MarketIndex> indices;
  final MarketIndexLiveStatus liveStatus;
  final String? errorMessage;
  final String? liveMessage;
  final DateTime? lastTickAt;

  MarketIndexState copyWith({
    MarketIndexStatus? status,
    List<MarketIndex>? indices,
    MarketIndexLiveStatus? liveStatus,
    String? errorMessage,
    String? liveMessage,
    DateTime? lastTickAt,
    bool clearErrorMessage = false,
  }) {
    return MarketIndexState(
      status: status ?? this.status,
      indices: indices ?? this.indices,
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
      marketDataTime: _dateTime(json['marketDataTime']),
      source: _string(json['source'], fallback: 'KIS_WEBSOCKET_INDEX'),
    );
  }
}

class MarketIndexController extends ValueNotifier<MarketIndexState> {
  MarketIndexController({
    required ExchangeApiClient apiClient,
    MarketIndexLiveClient? liveClient,
  })  : _apiClient = apiClient,
        _liveClient = liveClient,
        super(const MarketIndexState.idle());

  final ExchangeApiClient _apiClient;
  final MarketIndexLiveClient? _liveClient;
  StreamSubscription<Map<String, dynamic>>? _liveSubscription;

  bool get canSubscribeLive => _liveClient != null;

  Future<void> loadSnapshot() async {
    value = value.copyWith(status: MarketIndexStatus.loading);
    try {
      final response = await _apiClient.getMarketIndices();
      final snapshot = MarketIndexSnapshot.fromJson(response.data ?? {});
      value = value.copyWith(
        status: MarketIndexStatus.loaded,
        indices: snapshot.indices,
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
    await _liveSubscription?.cancel();
    value = value.copyWith(
      liveStatus: MarketIndexLiveStatus.connecting,
      liveMessage: 'Connecting index WebSocket.',
    );
    _liveSubscription = liveClient.subscribe().listen(
          (tick) => _applyLiveIndex(MarketIndex.fromJson(tick)),
          onError: (_) => value = value.copyWith(
            liveStatus: MarketIndexLiveStatus.failure,
            liveMessage: 'Index WebSocket disconnected.',
          ),
          onDone: () => value = value.copyWith(
            liveStatus: MarketIndexLiveStatus.disconnected,
            liveMessage: 'Index WebSocket closed.',
          ),
        );
  }

  void _applyLiveIndex(MarketIndex tick) {
    final nextIndices = List<MarketIndex>.of(value.indices);
    final index =
        nextIndices.indexWhere((item) => item.indexCode == tick.indexCode);
    if (index >= 0) {
      nextIndices[index] = tick;
    } else {
      nextIndices.add(tick);
    }
    value = value.copyWith(
      status: MarketIndexStatus.loaded,
      indices: nextIndices,
      liveStatus: MarketIndexLiveStatus.live,
      liveMessage: 'Live index ${tick.indexName} received.',
      lastTickAt: DateTime.now().toUtc(),
      clearErrorMessage: true,
    );
  }

  @override
  void dispose() {
    _liveSubscription?.cancel();
    super.dispose();
  }
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

    void sendFrame(String command, Map<String, String> headers,
        [String? body]) {
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

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
