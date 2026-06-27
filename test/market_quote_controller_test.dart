import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_exchange_fe/src/core/exchange_api_client.dart';
import 'package:stock_exchange_fe/src/core/market_quote_controller.dart';
import 'package:stock_exchange_fe/src/core/market_quote_live_client.dart';

void main() {
  test('loads REST market quote snapshot from Stock-exchange-BE', () async {
    final controller = MarketQuoteController(
      apiClient: _client((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/market/quotes');
        expect(request.url.queryParameters['market'], 'KOSPI');
        expect(request.url.queryParameters['currency'], 'USD');

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': _snapshotJson(),
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
      seedQuotes: seedMarketQuotes,
    );

    await controller.loadSnapshot(market: 'KOSPI');

    expect(controller.value.status, MarketQuoteStatus.loaded);
    expect(controller.value.snapshot?.cacheStatus, 'FRESH_CACHE');
    expect(controller.value.quotes.single.stockName, 'Samsung Electronics');
    expect(controller.value.quotes.single.localCurrencyDisplay, 'USD 1,024.24');
    expect(
        controller.value.quotes.single.fxMeta, contains('Hana-OmniLens-API'));
  });

  test('keeps visible quotes when snapshot request fails', () async {
    final controller = MarketQuoteController(
      apiClient: _client((request) async {
        return _jsonResponse(
          {
            'success': false,
            'status': 502,
            'code': 'MARKET_001',
            'message': 'Hana OmniLens market upstream unavailable',
            'timestamp': '2026-06-18T06:00:00Z',
          },
          statusCode: 502,
        );
      }),
      seedQuotes: seedMarketQuotes,
    );

    await controller.loadSnapshot();

    expect(controller.value.status, MarketQuoteStatus.failure);
    expect(
      controller.value.errorMessage,
      'Hana OmniLens market upstream unavailable',
    );
    expect(controller.value.quotes, seedMarketQuotes);
  });

  test('requires sign in before account scoped snapshots', () async {
    var requestCount = 0;
    final controller = MarketQuoteController(
      apiClient: _client((request) async {
        requestCount++;
        return _jsonResponse({});
      }),
    );

    await controller.loadPortfolioSnapshot(accountId: null);
    await controller.loadWatchlistSnapshot(accountId: '');

    expect(requestCount, 0);
    expect(controller.value.status, MarketQuoteStatus.failure);
    expect(controller.value.errorMessage, 'Sign in to load watchlist quotes.');
  });

  test('loads portfolio quote snapshot for signed-in account', () async {
    final controller = MarketQuoteController(
      apiClient: _client((request) async {
        expect(
          request.url.path,
          '/api/v1/accounts/ACC-ABC123456789/market/quotes/portfolio',
        );
        expect(request.url.queryParameters['currency'], 'USD');

        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': _snapshotJson(stockName: 'NAVER', stockCode: '035420'),
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
    );

    await controller.loadPortfolioSnapshot(accountId: 'ACC-ABC123456789');

    expect(controller.value.status, MarketQuoteStatus.loaded);
    expect(controller.value.quotes.single.stockName, 'NAVER');
  });

  test('merges live WebSocket tick into visible quotes', () async {
    late _FakeQuoteSocketConnection connection;
    final controller = MarketQuoteController(
      apiClient: _client((request) async => _jsonResponse({})),
      liveClient: MarketQuoteLiveClient(
        baseUri: Uri.parse('http://localhost:3000'),
        socketConnector: (uri) {
          connection = _FakeQuoteSocketConnection();
          return connection;
        },
      ),
      seedQuotes: seedMarketQuotes,
    );

    await controller.subscribeLive(market: 'KOSPI');
    expect(controller.value.liveStatus, MarketQuoteLiveStatus.connecting);

    connection.emit('CONNECTED\nversion:1.2\n\n\u0000');
    connection.emit('MESSAGE\ndestination:/topic/market/markets/KOSPI\n\n'
        '${jsonEncode(_tickJson())}\u0000');
    await Future<void>.delayed(Duration.zero);

    expect(controller.value.liveStatus, MarketQuoteLiveStatus.live);
    expect(controller.value.quotes.first.stockName, 'Samsung Electronics');
    expect(controller.value.liveMessage, 'Live tick 005930 received.');

    await controller.unsubscribeLive();
    expect(connection.closed, isTrue);
  });

  test('reconnects live WebSocket with backoff after remote close', () async {
    final connections = <_FakeQuoteSocketConnection>[];
    final controller = MarketQuoteController(
      apiClient: _client((request) async => _jsonResponse({})),
      liveClient: MarketQuoteLiveClient(
        baseUri: Uri.parse('http://localhost:3000'),
        socketConnector: (uri) {
          final connection = _FakeQuoteSocketConnection();
          connections.add(connection);
          return connection;
        },
      ),
      liveReconnectDelays: const [Duration.zero],
      seedQuotes: seedMarketQuotes,
    );

    await controller.subscribeLive(market: 'KOSPI');
    expect(connections.length, 1);

    await connections.first.closeRemote();
    await Future<void>.delayed(Duration.zero);
    expect(
      controller.value.liveMessage,
      'Quote WebSocket closed. Reconnecting quote WebSocket in 0s.',
    );

    await Future<void>.delayed(Duration.zero);
    expect(connections.length, 2);

    connections.last.emit('CONNECTED\nversion:1.2\n\n\u0000');
    connections.last.emit('MESSAGE\ndestination:/topic/market/markets/KOSPI\n\n'
        '${jsonEncode(_tickJson())}\u0000');
    await Future<void>.delayed(Duration.zero);

    expect(controller.value.liveStatus, MarketQuoteLiveStatus.live);
    expect(controller.value.liveMessage, 'Live tick 005930 received.');

    await controller.unsubscribeLive();
    expect(connections.last.closed, isTrue);
  });

  test('marks live quotes stale while reconnecting after a received tick',
      () async {
    late _FakeQuoteSocketConnection connection;
    var snapshotRequestCount = 0;
    final controller = MarketQuoteController(
      apiClient: _client((request) async {
        snapshotRequestCount++;
        return _jsonResponse({
          'success': true,
          'status': 200,
          'code': 'COMMON_000',
          'message': 'OK',
          'data': _snapshotJson(stockName: 'NAVER', stockCode: '035420'),
          'timestamp': '2026-06-18T06:00:00Z',
        });
      }),
      liveClient: MarketQuoteLiveClient(
        baseUri: Uri.parse('http://localhost:3000'),
        socketConnector: (uri) {
          connection = _FakeQuoteSocketConnection();
          return connection;
        },
      ),
      liveReconnectDelays: const [Duration(seconds: 30)],
      seedQuotes: seedMarketQuotes,
    );

    await controller.subscribeLive(market: 'KOSPI');
    connection.emit('CONNECTED\nversion:1.2\n\n\u0000');
    connection.emit('MESSAGE\ndestination:/topic/market/markets/KOSPI\n\n'
        '${jsonEncode(_tickJson())}\u0000');
    await Future<void>.delayed(Duration.zero);

    expect(controller.value.liveStale, isFalse);

    await connection.closeRemote();
    await Future<void>.delayed(Duration.zero);

    expect(controller.value.liveStatus, MarketQuoteLiveStatus.connecting);
    expect(controller.value.liveStale, isTrue);
    expect(
      controller.value.liveMessage,
      'Quote WebSocket closed. Reconnecting quote WebSocket in 30s.',
    );

    await controller.loadSnapshot(market: 'KOSPI');

    expect(snapshotRequestCount, 1);
    expect(controller.value.status, MarketQuoteStatus.loaded);
    expect(controller.value.quotes.single.stockName, 'NAVER');
    expect(controller.value.liveStatus, MarketQuoteLiveStatus.connecting);
    expect(controller.value.liveStale, isTrue);

    await controller.unsubscribeLive();
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
    'localCurrencyPrice': '1024.24',
    'fxRate': '1525.93',
    'fxRateTime': '2026-06-18T06:00:00Z',
    'fxRateSource': 'Hana-OmniLens-API',
    'fxStale': false,
  };
}

ExchangeApiClient _client(
  Future<http.Response> Function(http.Request request) handler,
) {
  return ExchangeApiClient(
    baseUri: Uri.parse('http://localhost:3000'),
    httpClient: MockClient(handler),
  );
}

Map<String, Object?> _snapshotJson({
  String stockName = 'Samsung Electronics',
  String stockCode = '005930',
}) {
  return {
    'dataSource': 'Hana-OmniLens-API',
    'marketCoverage': 'KOSPI',
    'userLanguage': 'en',
    'displayCurrency': 'USD',
    'tradingMode': 'MOCK_LEDGER_ONLY',
    'transport': {
      'snapshot': 'REST',
      'realtime': 'WebSocket',
    },
    'cache': {
      'status': 'FRESH_CACHE',
      'cachedAt': '2026-06-18T06:00:00Z',
      'expiresAt': '2026-06-18T06:00:05Z',
      'staleUntil': '2026-06-18T06:00:30Z',
    },
    'quoteCount': 1,
    'quotes': [
      {
        'stockCode': stockCode,
        'stockName': stockName,
        'market': 'KOSPI',
        'currentPriceKrw': '82400',
        'changeRate': '+1.23%',
        'volume': 18300000,
        'localCurrency': 'USD',
        'localCurrencyPrice': '1024.24',
        'fxRate': '1525.93',
        'fxRateTime': '2026-06-18T06:00:00Z',
        'fxRateSource': 'Hana-OmniLens-API',
        'fxStale': false,
      }
    ],
    'servedAt': '2026-06-18T06:00:01Z',
  };
}

http.Response _jsonResponse(
  Map<String, Object?> body, {
  int statusCode = 200,
}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

class _FakeQuoteSocketConnection implements QuoteSocketConnection {
  final StreamController<dynamic> _streamController =
      StreamController<dynamic>();
  bool closed = false;

  @override
  Stream<dynamic> get stream => _streamController.stream;

  @override
  void add(String message) {}

  void emit(String message) {
    _streamController.add(message);
  }

  Future<void> closeRemote() async {
    if (!_streamController.isClosed) {
      await _streamController.close();
    }
  }

  @override
  Future<void> close() async {
    closed = true;
    if (!_streamController.isClosed) {
      await _streamController.close();
    }
  }
}
