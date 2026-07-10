import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_exchange_fe/src/core/exchange_api_client.dart';
import 'package:stock_exchange_fe/src/core/market_index_controller.dart';
import 'package:stock_exchange_fe/src/core/market_quote_live_client.dart';

void main() {
  test('keeps the newest index tick and replaces the current minute point',
      () async {
    late _FakeIndexSocketConnection connection;
    final controller = MarketIndexController(
      apiClient: _client(),
      liveClient: MarketIndexLiveClient(
        baseUri: Uri.parse('http://localhost:3000'),
        socketConnector: (uri) {
          connection = _FakeIndexSocketConnection();
          return connection;
        },
      ),
    );

    await controller.subscribeLive();
    connection.emit('CONNECTED\nversion:1.2\n\n\u0000');
    connection.emit(_indexMessage('2800.10', '2026-07-10T03:00:10Z'));
    await Future<void>.delayed(Duration.zero);
    connection.emit(_indexMessage('2801.20', '2026-07-10T03:00:40Z'));
    await Future<void>.delayed(Duration.zero);
    connection.emit(_indexMessage('2700.00', '2026-07-10T02:59:59Z'));
    await Future<void>.delayed(Duration.zero);

    expect(controller.value.indices.single.currentValue, '2801.20');
    expect(controller.value.intradaySeriesFor('0001'), [2801.2]);

    controller.dispose();
  });
}

ExchangeApiClient _client() {
  return ExchangeApiClient(
    baseUri: Uri.parse('http://localhost:3000'),
    httpClient: MockClient((request) async => http.Response('{}', 404)),
  );
}

String _indexMessage(String currentValue, String marketDataTime) {
  return 'MESSAGE\ndestination:/topic/market/indices\n\n'
      '${jsonEncode({
        'indexCode': '0001',
        'indexName': 'KOSPI',
        'market': 'KOSPI',
        'currentValue': currentValue,
        'changeSign': '2',
        'changeValue': '10.20',
        'changeRate': '0.36',
        'accumulatedVolume': 1,
        'accumulatedTradingValue': 1,
        'openValue': '2790.00',
        'highValue': '2802.00',
        'lowValue': '2789.00',
        'marketDataTime': marketDataTime,
        'source': 'KIS_WEBSOCKET_INDEX',
      })}\u0000';
}

class _FakeIndexSocketConnection implements QuoteSocketConnection {
  final StreamController<dynamic> _streamController =
      StreamController<dynamic>();

  @override
  Stream<dynamic> get stream => _streamController.stream;

  @override
  void add(String message) {}

  void emit(String message) {
    _streamController.add(message);
  }

  @override
  Future<void> close() => _streamController.close();
}
