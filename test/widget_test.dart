import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_exchange_fe/src/app.dart';
import 'package:stock_exchange_fe/src/core/exchange_api_client.dart';
import 'package:stock_exchange_fe/src/core/exchange_session_controller.dart';
import 'package:stock_exchange_fe/src/core/market_quote_controller.dart';

void main() {
  testWidgets('renders market shell with USD quote context', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const StockExchangeApp());
    await tester.pumpAndSettle();

    expect(find.text('Hana Local Exchange'), findsOneWidget);
    expect(find.text('Korea Market'), findsOneWidget);
    expect(find.text('Sign in with username and password'), findsOneWidget);
    expect(find.text('Search all Korean stocks'), findsOneWidget);
    expect(find.text('WebSocket live'), findsOneWidget);
    expect(find.text('REST snapshot ready'), findsOneWidget);
    expect(find.text('USD 54.00'), findsOneWidget);
    expect(
      find.text('FX 1525.93 / unknown time / source Hana-OmniLens-API'),
      findsOneWidget,
    );
  });

  testWidgets('navigates portfolio, alerts, and tax tabs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const StockExchangeApp());
    await tester.pumpAndSettle();

    await tester.tap(_navigationDestination('Portfolio'));
    await tester.pumpAndSettle();
    expect(find.text('Mock USD cash'), findsWidgets);
    expect(find.text('Mock USD trading ledger. No real order is sent.'), findsOneWidget);

    await tester.tap(_navigationDestination('Alerts'));
    await tester.pumpAndSettle();
    expect(
      find.text('AI translated news and disclosures for your stocks.'),
      findsOneWidget,
    );
    expect(find.text('Original link / My Portfolio / High importance'), findsOneWidget);

    await tester.tap(_navigationDestination('Tax'));
    await tester.pumpAndSettle();
    expect(find.text('Tax Refund'), findsOneWidget);
    expect(find.text('Estimated refund USD 84.30'), findsOneWidget);
  });

  testWidgets('signs in with the injected session controller', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = ExchangeSessionController(
      sessionStore: MemoryExchangeSessionStore(),
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/login');
          return _jsonResponse({
            'success': true,
            'status': 200,
            'code': 'COMMON_000',
            'message': 'OK',
            'data': {
              'username': 'hana',
              'accountId': 'ACC-ABC123456789',
              'tokenType': 'Bearer',
              'accessToken': 'access-token',
              'refreshToken': 'refresh-token',
            },
            'timestamp': '2026-06-18T06:00:00Z',
          });
        }),
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(StockExchangeApp(sessionController: controller));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'hana');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Signed in as hana'), findsOneWidget);
    expect(find.text('Account ACC-ABC123456789'), findsOneWidget);
  });

  testWidgets('refreshes market quotes from REST snapshot', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = MarketQuoteController(
      seedQuotes: seedMarketQuotes,
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/market/quotes');
          return _jsonResponse({
            'success': true,
            'status': 200,
            'code': 'COMMON_000',
            'message': 'OK',
            'data': {
              'dataSource': 'Hana-OmniLens-API',
              'marketCoverage': 'ALL',
              'displayCurrency': 'USD',
              'transport': {
                'snapshot': 'REST',
                'realtime': 'WebSocket',
              },
              'cache': {'status': 'FRESH_CACHE'},
              'quoteCount': 1,
              'quotes': [
                {
                  'stockCode': '000660',
                  'stockName': 'SK hynix',
                  'market': 'KOSPI',
                  'currentPriceKrw': '281000',
                  'changeRate': '+2.10%',
                  'volume': 2300000,
                  'localCurrency': 'USD',
                  'localCurrencyPrice': '184.16',
                  'fxRate': '1525.80',
                  'fxRateTime': '2026-06-18T06:00:00Z',
                  'fxRateSource': 'Hana-OmniLens-API',
                  'fxStale': false,
                }
              ],
              'servedAt': '2026-06-18T06:00:01Z',
            },
            'timestamp': '2026-06-18T06:00:01Z',
          });
        }),
      ),
    );
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      StockExchangeApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();

    expect(find.text('SK hynix'), findsOneWidget);
    expect(find.text('USD 184.16'), findsOneWidget);
    expect(find.text('Cache FRESH_CACHE / REST snapshot / WebSocket live'), findsOneWidget);
  });

  testWidgets('refreshes account portfolio quotes after sign in', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = MemoryExchangeSessionStore();
    await store.write(
      const AuthSession(
        username: 'hana',
        accountId: 'ACC-ABC123456789',
        tokenType: 'Bearer',
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    );
    final portfolioQuoteController = MarketQuoteController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          expect(
            request.url.path,
            '/api/v1/accounts/ACC-ABC123456789/market/quotes/portfolio',
          );
          return _jsonResponse({
            'success': true,
            'status': 200,
            'code': 'COMMON_000',
            'message': 'OK',
            'data': {
              'dataSource': 'Hana-OmniLens-API',
              'marketCoverage': 'PORTFOLIO',
              'displayCurrency': 'USD',
              'transport': {
                'snapshot': 'REST',
                'realtime': 'WebSocket',
              },
              'cache': {'status': 'FRESH_CACHE'},
              'quoteCount': 1,
              'quotes': [
                {
                  'stockCode': '035420',
                  'stockName': 'NAVER',
                  'market': 'KOSPI',
                  'currentPriceKrw': '183700',
                  'changeRate': '+0.80%',
                  'volume': 930000,
                  'localCurrency': 'USD',
                  'localCurrencyPrice': '120.41',
                  'fxRate': '1525.59',
                  'fxRateTime': '2026-06-18T06:00:00Z',
                  'fxRateSource': 'Hana-OmniLens-API',
                  'fxStale': false,
                }
              ],
              'servedAt': '2026-06-18T06:00:01Z',
            },
            'timestamp': '2026-06-18T06:00:01Z',
          });
        }),
      ),
    );
    final sessionController = ExchangeSessionController(
      sessionStore: store,
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async => _jsonResponse({})),
      ),
    );
    addTearDown(portfolioQuoteController.dispose);
    addTearDown(sessionController.dispose);

    await tester.pumpWidget(
      StockExchangeApp(
        sessionController: sessionController,
        portfolioQuoteController: portfolioQuoteController,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_navigationDestination('Portfolio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refresh').first);
    await tester.pumpAndSettle();

    expect(find.text('Signed in as hana'), findsOneWidget);
    expect(find.text('NAVER'), findsOneWidget);
    expect(
      find.text('Cache FRESH_CACHE / account REST + WebSocket'),
      findsOneWidget,
    );
  });
}

Finder _navigationDestination(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is NavigationDestination && widget.label == label,
  );
}

http.Response _jsonResponse(Map<String, Object?> body) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );
}
