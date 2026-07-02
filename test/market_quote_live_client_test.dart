import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_exchange_fe/src/core/market_quote_live_client.dart';

void main() {
  test('builds Stock-exchange-BE STOMP WebSocket URI and subscribes topic',
      () async {
    late _FakeQuoteSocketConnection connection;
    final liveClient = MarketQuoteLiveClient(
      baseUri: Uri.parse('https://exchange.example.com/api'),
      socketConnector: (uri) {
        expect(uri.toString(), 'wss://exchange.example.com/api/ws/market');
        connection = _FakeQuoteSocketConnection();
        return connection;
      },
    );

    final ticks = <Map<String, dynamic>>[];
    final subscription = liveClient
        .subscribe(
          const MarketQuoteLiveSubscription(market: 'KOSPI'),
        )
        .listen(ticks.add);

    await Future<void>.delayed(Duration.zero);
    expect(connection.sent.first, startsWith('CONNECT\n'));

    connection.emit('CONNECTED\nversion:1.2\n\n\u0000');
    await Future<void>.delayed(Duration.zero);

    expect(
      connection.sent.last,
      contains('destination:/topic/market/markets/KOSPI'),
    );

    connection.emit('MESSAGE\ndestination:/topic/market/markets/KOSPI\n\n'
        '${jsonEncode(_tickJson())}\u0000');
    await Future<void>.delayed(Duration.zero);

    expect(ticks.single['stockCode'], '005930');
    expect(ticks.single['localCurrencyPrice'], '54.00');

    await subscription.cancel();
    expect(connection.closed, isTrue);
  });

  test('uses account scoped watchlist and portfolio topics', () {
    expect(
      const MarketQuoteLiveSubscription(
        accountId: 'ACC-ABC123456789',
        accountScope: MarketQuoteAccountScope.watchlist,
      ).topics,
      const ['/topic/accounts/ACC-ABC123456789/market/quotes/watchlist'],
    );
    expect(
      const MarketQuoteLiveSubscription(
        accountId: 'ACC-ABC123456789',
        accountScope: MarketQuoteAccountScope.portfolio,
      ).topics,
      const ['/topic/accounts/ACC-ABC123456789/market/quotes/portfolio'],
    );
  });
}

Map<String, Object?> _tickJson() {
  return {
    'stockCode': '005930',
    'stockName': 'Samsung Electronics',
    'market': 'KOSPI',
    'currentPriceKrw': '82400',
    'changeRate': '+1.23%',
    'volume': 18300000,
    'localCurrency': 'USD',
    'localCurrencyPrice': '54.00',
    'fxRate': '1525.93',
    'fxRateTime': '2026-06-18T06:00:00Z',
    'fxRateSource': 'Hana-OmniLens-API',
    'fxStale': false,
  };
}

class _FakeQuoteSocketConnection implements QuoteSocketConnection {
  final StreamController<dynamic> _streamController =
      StreamController<dynamic>();
  final List<String> sent = [];
  bool closed = false;

  @override
  Stream<dynamic> get stream => _streamController.stream;

  @override
  void add(String message) {
    sent.add(message);
  }

  void emit(String message) {
    _streamController.add(message);
  }

  @override
  Future<void> close() async {
    closed = true;
    await _streamController.close();
  }
}
