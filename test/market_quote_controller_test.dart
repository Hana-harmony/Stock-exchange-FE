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
      controller.value.quotes.single.fxMeta,
      contains('Hana-OmniLens-API'),
    );
  });

  test('fills missing USD price from KRW and FX direction', () {
    final usdPerKrwQuote = MarketQuote.fromJson({
      ..._tickJson(),
      'currentPriceKrw': '100000',
      'localCurrencyPrice': '0',
      'fxRate': '0.0007',
    });
    final krwPerUsdQuote = MarketQuote.fromJson({
      ..._tickJson(),
      'currentPriceKrw': '100000',
      'localCurrencyPrice': '0',
      'fxRate': '1400',
    });

    expect(usdPerKrwQuote.localCurrencyDisplay, 'USD 70.00');
    expect(krwPerUsdQuote.localCurrencyDisplay, 'USD 71.43');
  });

  test('closing zero-volume tick cannot erase accumulated regular volume', () {
    final snapshot = MarketQuote.fromJson({
      ..._tickJson(),
      'volume': 18300000,
      'marketDataTime': '2026-07-10T06:30:00Z',
    });
    final closingTick = MarketQuote.fromJson({
      ..._tickJson(),
      'volume': 0,
      'marketDataTime': '2026-07-10T06:31:00Z',
    });

    expect(snapshot.mergeRegularTick(closingTick).volume, 18300000);
  });

  test('keeps circuit breaker state from a realtime tick', () {
    final snapshot = MarketQuote.fromJson(_tickJson());
    final circuitTick = MarketQuote.fromJson({
      ..._tickJson(),
      'tradingHalted': true,
      'circuitBreakerActive': true,
      'tradingHaltReason': '서킷브레이커 발동',
    });

    final merged = snapshot.mergeRegularTick(circuitTick);

    expect(merged.tradingHalted, isTrue);
    expect(merged.circuitBreakerActive, isTrue);
    expect(merged.tradingHaltReason, '서킷브레이커 발동');
  });

  test('hides seed quotes when initial snapshot request fails', () async {
    final controller = MarketQuoteController(
      apiClient: _client((request) async {
        return _jsonResponse({
          'success': false,
          'status': 502,
          'code': 'MARKET_001',
          'message': 'Hana OmniLens market upstream unavailable',
          'timestamp': '2026-06-18T06:00:00Z',
        }, statusCode: 502);
      }),
      seedQuotes: seedMarketQuotes,
    );

    await controller.loadSnapshot();

    expect(controller.value.status, MarketQuoteStatus.failure);
    expect(
      controller.value.errorMessage,
      'Hana OmniLens market upstream unavailable',
    );
    expect(controller.value.quotes, isEmpty);
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
    connection.emit(
      'MESSAGE\ndestination:/topic/market/markets/KOSPI\n\n'
      '${jsonEncode({
            ..._tickJson(),
            'stockName': 'Smoke Test Name',
            'currentPriceKrw': '83000',
            'localCurrencyPrice': '53.95'
          })}\u0000',
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.value.liveStatus, MarketQuoteLiveStatus.live);
    expect(controller.value.quotes.first.stockName, 'Samsung Electronics');
    expect(controller.value.quotes.first.currentPriceKrw, '83000');
    expect(controller.value.quotes.first.localCurrencyPrice, '53.95');
    expect(controller.value.liveMessage, 'Live tick 005930 received.');

    await controller.unsubscribeLive();
    expect(connection.closed, isTrue);
  });

  test('notifies only the listenable for the stock changed by a live tick',
      () async {
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
    final samsung = controller.acquireQuoteListenable('005930');
    final kakao = controller.acquireQuoteListenable('035720');
    var samsungNotifications = 0;
    var kakaoNotifications = 0;
    samsung.addListener(() => samsungNotifications++);
    kakao.addListener(() => kakaoNotifications++);

    await controller.subscribeMarketLiveStocks(['005930', '035720']);
    connection.emit('CONNECTED\nversion:1.2\n\n\u0000');
    connection.emit(
      'MESSAGE\ndestination:/topic/market/stocks/035720\n\n'
      '${jsonEncode({
            ..._tickJson(),
            'stockCode': '035720',
            'stockName': 'Kakao',
          })}\u0000',
    );
    await Future<void>.delayed(Duration.zero);

    expect(kakaoNotifications, 1);
    expect(kakao.value?.stockCode, '035720');
    expect(samsungNotifications, 0);

    await Future<void>.delayed(const Duration(milliseconds: 300));
    connection.emit(
      'MESSAGE\ndestination:/topic/market/stocks/005930\n\n'
      '${jsonEncode({
            ..._tickJson(),
            'currentPriceKrw': '83000',
          })}\u0000',
    );
    await Future<void>.delayed(Duration.zero);

    expect(samsungNotifications, 1);
    expect(samsung.value?.currentPriceKrw, '83000');
    expect(kakaoNotifications, 1);

    await controller.unsubscribeLive();
    controller.releaseQuoteListenable('005930');
    controller.releaseQuoteListenable('035720');
  });

  test('updates a stock listenable when a REST snapshot is loaded', () async {
    final controller = MarketQuoteController(
      apiClient: _client((request) async {
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
    final naver = controller.acquireQuoteListenable('035420');
    var notifications = 0;
    naver.addListener(() => notifications++);

    await controller.loadSnapshot();

    expect(notifications, 1);
    expect(naver.value?.stockName, 'NAVER');
    controller.releaseQuoteListenable('035420');
  });

  test('keeps newer live quote when REST snapshot returns older price',
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
          'data': _snapshotJson(),
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
      seedQuotes: seedMarketQuotes,
    );

    await controller.subscribeLive();
    expect(controller.hasGeneralLiveSubscription, isTrue);

    connection.emit('CONNECTED\nversion:1.2\n\n\u0000');
    connection.emit(
      'MESSAGE\ndestination:/topic/market/quotes\n\n'
      '${jsonEncode({
            ..._tickJson(),
            'currentPriceKrw': '90000',
            'localCurrencyPrice': '58.50',
            'volume': 19000000
          })}\u0000',
    );
    await Future<void>.delayed(Duration.zero);

    await controller.loadSnapshot(market: 'KOSPI');

    expect(snapshotRequestCount, 1);
    expect(controller.quoteFor('005930')?.currentPriceKrw, '90000');
    expect(controller.quoteFor('005930')?.localCurrencyPrice, '58.50');
    expect(controller.quoteFor('005930')?.volume, 19000000);

    await controller.unsubscribeLive();
  });

  test(
    'keeps market quote topics while adding and removing detail demand',
    () async {
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
        seedQuotes: seedMarketQuotes,
      );

      await controller.subscribeMarketLiveStocks(['005930', '000270']);
      connections.last.emit('CONNECTED\nversion:1.2\n\n\u0000');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(connections.length, 1);
      expect(
        connections.last.sent.join('\n'),
        contains('destination:/topic/market/stocks/005930'),
      );
      expect(
        connections.last.sent.join('\n'),
        contains('destination:/topic/market/stocks/000270'),
      );
      expect(
        connections.last.sent.join('\n'),
        isNot(contains('destination:/topic/market/quotes')),
      );

      await controller.addDemandLiveStock('035720');
      expect(connections.first.closed, isTrue);
      connections.last.emit('CONNECTED\nversion:1.2\n\n\u0000');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(connections.length, 2);
      final demandTopics = connections.last.sent.join('\n');
      expect(demandTopics, contains('destination:/topic/market/stocks/005930'));
      expect(demandTopics, contains('destination:/topic/market/stocks/000270'));
      expect(demandTopics, contains('destination:/topic/market/stocks/035720'));
      expect(demandTopics, isNot(contains('destination:/topic/market/quotes')));
      expect(controller.hasLiveSubscriptionForStock('035720'), isTrue);

      await controller.removeDemandLiveStock('035720');
      expect(connections[1].closed, isTrue);
      connections.last.emit('CONNECTED\nversion:1.2\n\n\u0000');
      await Future<void>.delayed(Duration.zero);

      expect(connections.length, 3);
      final marketTopics = connections.last.sent.join('\n');
      expect(marketTopics, contains('destination:/topic/market/stocks/005930'));
      expect(marketTopics, contains('destination:/topic/market/stocks/000270'));
      expect(
        marketTopics,
        isNot(contains('destination:/topic/market/stocks/035720')),
      );
      expect(controller.hasLiveSubscriptionForStock('035720'), isFalse);

      await controller.unsubscribeLive();
    },
  );

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
    connections.last.emit(
      'MESSAGE\ndestination:/topic/market/markets/KOSPI\n\n'
      '${jsonEncode(_tickJson())}\u0000',
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.value.liveStatus, MarketQuoteLiveStatus.live);
    expect(controller.value.liveMessage, 'Live tick 005930 received.');

    await controller.unsubscribeLive();
    expect(connections.last.closed, isTrue);
  });

  test(
    'continues reconnecting after configured backoff delays are used',
    () async {
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
      );

      await controller.subscribeLive(market: 'KOSPI');
      await connections[0].closeRemote();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await connections[1].closeRemote();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(connections, hasLength(3));
      expect(controller.value.liveStatus, MarketQuoteLiveStatus.connecting);

      await controller.unsubscribeLive();
    },
  );

  test(
    'marks live quotes stale while reconnecting after a received tick',
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
      connection.emit(
        'MESSAGE\ndestination:/topic/market/markets/KOSPI\n\n'
        '${jsonEncode(_tickJson())}\u0000',
      );
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
    },
  );
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
    'transport': {'snapshot': 'REST', 'realtime': 'WebSocket'},
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
      },
    ],
    'servedAt': '2026-06-18T06:00:01Z',
  };
}

http.Response _jsonResponse(Map<String, Object?> body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
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
