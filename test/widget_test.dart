import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_exchange_fe/src/app.dart';
import 'package:stock_exchange_fe/src/core/account_controller.dart';
import 'package:stock_exchange_fe/src/core/exchange_api_client.dart';
import 'package:stock_exchange_fe/src/core/exchange_session_controller.dart';
import 'package:stock_exchange_fe/src/core/market_detail_controller.dart';
import 'package:stock_exchange_fe/src/core/market_quote_controller.dart';
import 'package:stock_exchange_fe/src/core/notification_controller.dart';
import 'package:stock_exchange_fe/src/core/tax_controller.dart';
import 'package:stock_exchange_fe/src/core/trade_controller.dart';

void main() {
  testWidgets('renders market shell with USD quote context', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_stockExchangeTestApp());
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
      findsWidgets,
    );
  });

  testWidgets('navigates portfolio, alerts, and tax tabs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_stockExchangeTestApp());
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
    expect(find.text('Integrated alert inbox'), findsOneWidget);
    expect(find.text('Sign in to load watchlist and portfolio alerts.'), findsOneWidget);

    await tester.tap(_navigationDestination('Tax'));
    await tester.pumpAndSettle();
    expect(find.text('Tax Refund'), findsOneWidget);
    expect(find.text('Government verification'), findsOneWidget);
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
    final accountController = AccountController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async => _jsonResponse({
              'success': true,
              'status': 200,
              'code': 'COMMON_000',
              'message': 'OK',
              'data': {
                'accountId': 'ACC-ABC123456789',
                'currency': 'USD',
                'cashBalanceUsd': '0.00',
              },
              'timestamp': '2026-06-18T06:00:00Z',
            })),
      ),
    );
    final tradeController = TradeController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async => _jsonResponse({
              'success': true,
              'status': 200,
              'code': 'COMMON_000',
              'message': 'OK',
              'data': {
                'accountId': 'ACC-ABC123456789',
                'currency': 'USD',
                'cashBalanceUsd': '0.00',
                'totalMarketValueUsd': '0.00',
                'totalAssetValueUsd': '0.00',
                'realizedPnlUsd': '0.00',
                'unrealizedPnlUsd': '0.00',
                'tradingMode': 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
                'holdings': [],
                'recentTrades': [],
              },
              'timestamp': '2026-06-18T06:00:00Z',
            })),
      ),
    );
    addTearDown(controller.dispose);
    addTearDown(accountController.dispose);
    addTearDown(tradeController.dispose);

    await tester.pumpWidget(
      StockExchangeApp(
        sessionController: controller,
        accountController: accountController,
        tradeController: tradeController,
      ),
    );
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
                  'fxStale': true,
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
      _stockExchangeTestApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();

    expect(find.text('SK hynix'), findsOneWidget);
    expect(find.text('USD 184.16'), findsOneWidget);
    expect(
      find.text('Cache FRESH_CACHE / REST snapshot / WebSocket live'),
      findsOneWidget,
    );
    expect(find.text('FX stale'), findsOneWidget);
    expect(
      find.text(
        'FX 1525.80 / 2026-06-18T06:00:00.000Z / source Hana-OmniLens-API / stale',
      ),
      findsWidgets,
    );
  });

  testWidgets('loads stock detail chart and order book from REST', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketDetailController = MarketDetailController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          expect(request.url.queryParameters['currency'], 'USD');

          if (request.url.path.endsWith('/chart')) {
            return _jsonResponse({
              'success': true,
              'status': 200,
              'code': 'COMMON_000',
              'message': 'OK',
              'data': {
                'dataSource': 'Hana-OmniLens-API',
                'stockCode': '005930',
                'interval': '1d',
                'from': '2026-06-01',
                'to': '2026-06-18',
                'baseCurrency': 'KRW',
                'displayCurrency': 'USD',
                'pointCount': 2,
                'points': [
                  {
                    'tradeDate': '2026-06-17',
                    'openPriceKrw': '80000',
                    'highPriceKrw': '81800',
                    'lowPriceKrw': '79800',
                    'closePriceKrw': '81200',
                    'localCurrency': 'USD',
                    'closeLocalCurrencyPrice': '53.22',
                    'volume': 17100000,
                    'adjusted': false,
                  },
                  {
                    'tradeDate': '2026-06-18',
                    'openPriceKrw': '81000',
                    'highPriceKrw': '82900',
                    'lowPriceKrw': '80500',
                    'closePriceKrw': '82400',
                    'localCurrency': 'USD',
                    'closeLocalCurrencyPrice': '54.01',
                    'volume': 18300000,
                    'adjusted': false,
                  }
                ],
                'servedAt': '2026-06-18T06:00:01Z',
              },
              'timestamp': '2026-06-18T06:00:01Z',
            });
          }
          if (request.url.path.endsWith('/orderbook')) {
            return _jsonResponse({
              'success': true,
              'status': 200,
              'code': 'COMMON_000',
              'message': 'OK',
              'data': {
                'dataSource': 'Hana-OmniLens-API',
                'stockCode': '005930',
                'market': 'KOSPI',
                'baseCurrency': 'KRW',
                'displayCurrency': 'USD',
                'asks': [
                  {
                    'priceKrw': '82500',
                    'localCurrencyPrice': '54.08',
                    'quantity': 800,
                    'orderCount': 12,
                  }
                ],
                'bids': [
                  {
                    'priceKrw': '82400',
                    'localCurrencyPrice': '54.01',
                    'quantity': 1200,
                    'orderCount': 19,
                  }
                ],
                'marketDataTime': '2026-06-18T06:00:00Z',
                'servedAt': '2026-06-18T06:00:01Z',
              },
              'timestamp': '2026-06-18T06:00:01Z',
            });
          }

          expect(request.url.path, '/api/v1/stocks/005930');
          return _jsonResponse({
            'success': true,
            'status': 200,
            'code': 'COMMON_000',
            'message': 'OK',
            'data': {
              'stockCode': '005930',
              'stockName': 'Samsung Electronics',
              'market': 'KOSPI',
              'sector': 'Semiconductor',
              'baseCurrency': 'KRW',
              'displayCurrency': 'USD',
              'currentPriceKrw': '82400',
              'localCurrencyPrice': '54.01',
              'changeRate': '+1.23%',
              'volume': 18300000,
              'marketDataTime': '2026-06-18T06:00:00Z',
              'foreignOwnershipRate': '55.31',
              'foreignLimitExhaustionRate': '55.31',
              'foreignOwnershipBaseDate': '2026-06-18',
              'viActive': false,
              'singlePriceTrading': true,
              'priceLimitState': 'UPPER_LIMIT',
              'tradingHalted': false,
              'orderable': true,
              'dataSource': 'Hana-OmniLens-API',
              'servedAt': '2026-06-18T06:00:01Z',
            },
            'timestamp': '2026-06-18T06:00:01Z',
          });
        }),
      ),
    );
    addTearDown(marketDetailController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(marketDetailController: marketDetailController),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Load details'));
    await tester.tap(find.text('Load details'));
    await tester.pumpAndSettle();

    expect(find.text('Stock detail, chart, and order book'), findsOneWidget);
    expect(find.text('Samsung Electronics'), findsWidgets);
    expect(find.text('USD 54.01'), findsWidgets);
    expect(find.text('Single-price trading'), findsOneWidget);
    expect(find.text('UPPER_LIMIT'), findsWidgets);
    expect(find.text('Foreign ownership gauge'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('foreign-ownership-rate-gauge')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('foreign-limit-rate-gauge')),
      findsOneWidget,
    );
    expect(find.text('Historical price line'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('market-history-chart-line')),
      findsOneWidget,
    );
    expect(find.textContaining('Ask 54.08 x 800'), findsOneWidget);
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
    var accountRequestCount = 0;
    final accountController = AccountController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          accountRequestCount++;
          if (request.method == 'GET') {
            expect(request.url.path, '/api/v1/accounts/ACC-ABC123456789');
            return _jsonResponse({
              'success': true,
              'status': 200,
              'code': 'COMMON_000',
              'message': 'OK',
              'data': {
                'accountId': 'ACC-ABC123456789',
                'currency': 'USD',
                'cashBalanceUsd': '125.50',
                'updatedAt': '2026-06-18T06:00:00Z',
              },
              'timestamp': '2026-06-18T06:00:00Z',
            });
          }

          expect(request.method, 'POST');
          expect(
            request.url.path,
            '/api/v1/accounts/ACC-ABC123456789/deposits',
          );
          expect(jsonDecode(request.body), {'amountUsd': 1000});
          return _jsonResponse({
            'success': true,
            'status': 200,
            'code': 'COMMON_000',
            'message': 'OK',
            'data': {
              'accountId': 'ACC-ABC123456789',
              'currency': 'USD',
              'cashBalanceUsd': '1125.50',
              'lastLedgerEntryId': 'CASH-123',
              'updatedAt': '2026-06-18T06:00:00Z',
            },
            'timestamp': '2026-06-18T06:00:00Z',
          });
        }),
      ),
    );
    final tradeController = TradeController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/portfolio')) {
            return _jsonResponse({
              'success': true,
              'status': 200,
              'code': 'COMMON_000',
              'message': 'OK',
              'data': {
                'accountId': 'ACC-ABC123456789',
                'currency': 'USD',
                'cashBalanceUsd': '125.50',
                'totalMarketValueUsd': '0.00',
                'totalAssetValueUsd': '125.50',
                'realizedPnlUsd': '0.00',
                'unrealizedPnlUsd': '0.00',
                'tradingMode': 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
                'holdings': [],
                'recentTrades': [],
              },
              'timestamp': '2026-06-18T06:00:00Z',
            });
          }
          return _jsonResponse({});
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
    addTearDown(accountController.dispose);
    addTearDown(tradeController.dispose);
    addTearDown(portfolioQuoteController.dispose);
    addTearDown(sessionController.dispose);

    await tester.pumpWidget(
      StockExchangeApp(
        sessionController: sessionController,
        accountController: accountController,
        tradeController: tradeController,
        portfolioQuoteController: portfolioQuoteController,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_navigationDestination('Portfolio'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Refresh').first);
    await tester.pumpAndSettle();

    expect(find.text('Signed in as hana'), findsOneWidget);
    expect(find.text('USD 125.50'), findsWidgets);
    expect(find.text('NAVER'), findsOneWidget);
    expect(
      find.text('Cache FRESH_CACHE / account REST + WebSocket'),
      findsOneWidget,
    );
    expect(accountRequestCount, greaterThanOrEqualTo(1));

    await tester.tap(find.text('Deposit'));
    await tester.pumpAndSettle();

    expect(find.text('USD 1125.50'), findsWidgets);
    expect(find.text('Last ledger entry CASH-123'), findsOneWidget);
  });

  testWidgets('checks and places mock order through exchange ledger', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1900));
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
    final sessionController = ExchangeSessionController(
      sessionStore: store,
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async => _jsonResponse({})),
      ),
    );
    final accountController = AccountController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async => _jsonResponse({
              'success': true,
              'status': 200,
              'code': 'COMMON_000',
              'message': 'OK',
              'data': {
                'accountId': 'ACC-ABC123456789',
                'currency': 'USD',
                'cashBalanceUsd': '200.00',
              },
              'timestamp': '2026-06-18T06:00:00Z',
            })),
      ),
    );
    final tradeController = TradeController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/trades/orderability')) {
            expect(request.url.queryParameters['stockCode'], '005930');
            expect(request.url.queryParameters['side'], 'BUY');
            expect(request.url.queryParameters['quantity'], '1');
            return _jsonResponse({
              'success': true,
              'status': 200,
              'code': 'COMMON_000',
              'message': 'OK',
              'data': {
                'stockCode': '005930',
                'side': 'BUY',
                'quantity': 1,
                'canPlaceMockOrder': true,
                'blockingReasons': [],
                'warnings': [
                  'VI_ACTIVE',
                  'SINGLE_PRICE_TRADING',
                  'BUY_AT_UPPER_LIMIT',
                ],
                'orderabilitySource': 'Hana-OmniLens-API',
                'tradingMode': 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
              },
              'timestamp': '2026-06-18T06:00:00Z',
            });
          }
          if (request.method == 'POST') {
            expect(request.url.path, '/api/v1/accounts/ACC-ABC123456789/trades');
            expect(jsonDecode(request.body), {
              'stockCode': '005930',
              'side': 'BUY',
              'quantity': 1,
            });
            return _jsonResponse({
              'success': true,
              'status': 200,
              'code': 'COMMON_000',
              'message': 'OK',
              'data': _tradeJson(),
              'timestamp': '2026-06-18T06:00:00Z',
            });
          }
          return _jsonResponse({
            'success': true,
            'status': 200,
            'code': 'COMMON_000',
            'message': 'OK',
            'data': _portfolioJson(),
            'timestamp': '2026-06-18T06:00:00Z',
          });
        }),
      ),
    );
    addTearDown(sessionController.dispose);
    addTearDown(accountController.dispose);
    addTearDown(tradeController.dispose);

    await tester.pumpWidget(
      StockExchangeApp(
        sessionController: sessionController,
        accountController: accountController,
        tradeController: tradeController,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_navigationDestination('Portfolio'));
    await tester.pumpAndSettle();

    expect(find.text('Exchange mock ledger only. No KIS order is sent.'), findsOneWidget);

    await tester.tap(find.text('Check orderability'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Volatility interruption is active'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Buy order is at the upper price limit'),
      findsOneWidget,
    );

    await tester.tap(find.text('Place mock order'));
    await tester.pumpAndSettle();

    expect(find.text('Last mock trade'), findsOneWidget);
    expect(find.textContaining('BUY 1 Samsung Electronics'), findsOneWidget);
    expect(find.text('Samsung Electronics'), findsWidgets);
    expect(find.text('USD 150.00'), findsWidgets);
  });

  testWidgets('loads tax refund status with government reference', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1800));
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
    final sessionController = ExchangeSessionController(
      sessionStore: store,
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async => _jsonResponse({})),
      ),
    );
    final taxController = TaxController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          expect(
            request.url.path,
            '/api/v1/accounts/ACC-ABC123456789/tax/refund-status',
          );
          return _jsonResponse({
            'success': true,
            'status': 200,
            'code': 'COMMON_000',
            'message': 'OK',
            'data': _taxCaseJson(),
            'timestamp': '2026-06-18T06:00:00Z',
          });
        }),
      ),
    );
    addTearDown(sessionController.dispose);
    addTearDown(taxController.dispose);

    await tester.pumpWidget(
      StockExchangeApp(
        sessionController: sessionController,
        taxController: taxController,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_navigationDestination('Tax'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Refresh tax status'));
    await tester.pumpAndSettle();

    expect(find.text('Government verification'), findsOneWidget);
    expect(find.text('REFUND_APPROVED'), findsWidgets);
    expect(find.text('TAX-CASE-1'), findsWidgets);
    expect(find.text('Withholding tax split'), findsOneWidget);
    expect(find.text('Refundable difference'), findsOneWidget);
    expect(find.text('Submitted tax documents'), findsOneWidget);
    expect(find.textContaining('residence.pdf'), findsOneWidget);
    expect(find.text('Refund status timeline'), findsOneWidget);
    expect(find.text('Documents received'), findsOneWidget);
    expect(find.text('Mock sell ledger matched'), findsOneWidget);
    expect(find.text('Government sync REFUND_APPROVED'), findsOneWidget);
    expect(find.text('Advance review requested'), findsOneWidget);
    expect(find.text('Refund input from mock sells'), findsOneWidget);
    expect(find.textContaining('Total sells USD 70.00'), findsOneWidget);
    expect(find.text('Post-payment recapture notice'), findsOneWidget);
    expect(find.text('Matched sell trade'), findsOneWidget);
    expect(
      find.textContaining('Samsung Electronics 1 shares'),
      findsOneWidget,
    );
  });

  testWidgets('renders alert inbox and K-News feed after sign in', (tester) async {
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
    final sessionController = ExchangeSessionController(
      sessionStore: store,
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async => _jsonResponse({})),
      ),
    );
    final notificationController = NotificationController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        sessionProvider: () => sessionController.session,
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/notifications/devices')) {
            return _jsonEnvelope(_notificationDevicesJson());
          }
          if (request.url.path.endsWith('/notifications')) {
            return _jsonEnvelope(_notificationInboxJson());
          }
          if (request.url.path.endsWith('/intelligence')) {
            return _jsonEnvelope(_stockIntelligenceJson());
          }
          if (request.url.path.endsWith('/read')) {
            return _jsonEnvelope(_readNotificationJson());
          }
          return _jsonEnvelope({});
        }),
      ),
    );
    addTearDown(sessionController.dispose);
    addTearDown(notificationController.dispose);

    await sessionController.restore();
    await tester.pumpWidget(
      _stockExchangeTestApp(
        sessionController: sessionController,
        notificationController: notificationController,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_navigationDestination('Alerts'));
    await tester.pumpAndSettle();

    expect(find.text('Integrated alert inbox'), findsOneWidget);
    expect(find.text('Push device registration'), findsOneWidget);
    expect(find.textContaining('IOS LOCAL_NOOP_PUSH'), findsOneWidget);
    expect(find.text('Samsung disclosure translated'), findsOneWidget);
    expect(find.text('K-News intelligence feed'), findsOneWidget);
    expect(find.text('Samsung earnings improve'), findsOneWidget);
    expect(find.text('https://dart.fss.or.kr/report'), findsOneWidget);
    expect(find.text('DISCLOSURE'), findsOneWidget);
    expect(find.text('NEWS'), findsOneWidget);
    expect(find.text('HIGH'), findsOneWidget);
    expect(find.text('POSITIVE'), findsOneWidget);
    expect(find.text('LOW'), findsOneWidget);
    expect(find.text('GLOSSARY_MATCHED'), findsWidgets);
    expect(find.text('공시 -> disclosure'), findsOneWidget);
    expect(find.text('실적 -> earnings'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Watchlist'));
    await tester.pumpAndSettle();
    expect(find.text('Samsung disclosure translated'), findsOneWidget);

    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();

    expect(notificationController.value.inbox?.unreadCount, 0);
  });
}

Finder _navigationDestination(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is NavigationDestination && widget.label == label,
  );
}

StockExchangeApp _stockExchangeTestApp({
  ExchangeSessionController? sessionController,
  AccountController? accountController,
  TradeController? tradeController,
  MarketDetailController? marketDetailController,
  MarketQuoteController? marketQuoteController,
  MarketQuoteController? portfolioQuoteController,
  NotificationController? notificationController,
  TaxController? taxController,
}) {
  return StockExchangeApp(
    sessionStore: MemoryExchangeSessionStore(),
    sessionController: sessionController,
    accountController: accountController,
    tradeController: tradeController,
    marketDetailController: marketDetailController,
    marketQuoteController: marketQuoteController,
    portfolioQuoteController: portfolioQuoteController,
    notificationController: notificationController,
    taxController: taxController,
  );
}

http.Response _jsonResponse(Map<String, Object?> body) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );
}

http.Response _jsonEnvelope(Map<String, Object?> data) {
  return _jsonResponse({
    'success': true,
    'status': 200,
    'code': 'COMMON_000',
    'message': 'OK',
    'data': data,
    'timestamp': '2026-06-18T06:00:00Z',
  });
}

Map<String, Object?> _tradeJson() {
  return {
    'tradeId': 'TRD-1',
    'accountId': 'ACC-ABC123456789',
    'stockCode': '005930',
    'stockName': 'Samsung Electronics',
    'side': 'BUY',
    'quantity': 1,
    'executionPriceUsd': '50.00',
    'grossAmountUsd': '50.00',
    'realizedPnlUsd': '0.00',
    'remainingQuantity': 1,
    'cashBalanceUsdAfter': '150.00',
    'tradingMode': 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
  };
}

Map<String, Object?> _portfolioJson() {
  return {
    'accountId': 'ACC-ABC123456789',
    'currency': 'USD',
    'cashBalanceUsd': '150.00',
    'totalMarketValueUsd': '55.00',
    'totalAssetValueUsd': '205.00',
    'realizedPnlUsd': '0.00',
    'unrealizedPnlUsd': '5.00',
    'tradingMode': 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
    'holdings': [
      {
        'stockCode': '005930',
        'stockName': 'Samsung Electronics',
        'quantity': 1,
        'averagePriceUsd': '50.00',
        'currentPriceUsd': '55.00',
        'marketValueUsd': '55.00',
        'unrealizedPnlUsd': '5.00',
        'unrealizedPnlRate': '10.00',
      }
    ],
    'recentTrades': [_tradeJson()],
  };
}

Map<String, Object?> _taxCaseJson() {
  return {
    'caseId': 'TAX-CASE-1',
    'accountId': 'ACC-ABC123456789',
    'taxYear': 2026,
    'treatyCountry': 'US',
    'residenceCertificateFileName': 'residence.pdf',
    'reducedTaxApplicationFileName': 'reduced-tax.pdf',
    'advancePaymentRequested': true,
    'status': 'REFUND_APPROVED',
    'currency': 'USD',
    'totalSellAmountUsd': '70.00',
    'realizedProfitUsd': '20.00',
    'realizedLossUsd': '0.00',
    'netRealizedPnlUsd': '20.00',
    'taxableRealizedPnlUsd': '20.00',
    'estimatedWithholdingTaxUsd': '4.40',
    'estimatedTreatyTaxUsd': '3.00',
    'estimatedRefundUsd': '1.40',
    'advancePaymentEligible': true,
    'matchedTradeCount': 1,
    'matchedTrades': [
      {
        'tradeId': 'TRD-1',
        'stockCode': '005930',
        'stockName': 'Samsung Electronics',
        'quantity': 1,
        'grossAmountUsd': '70.00',
        'realizedPnlUsd': '20.00',
        'executedAt': '2026-06-18T06:00:00Z',
      }
    ],
    'dataSource': 'EXCHANGE_MOCK_LEDGER_REALIZED_PNL',
    'createdAt': '2026-06-18T06:00:00Z',
    'updatedAt': '2026-06-18T06:30:00Z',
  };
}

Map<String, Object?> _notificationInboxJson() {
  return {
    'accountId': 'ACC-ABC123456789',
    'unreadCount': 1,
    'totalCount': 1,
    'notifications': [
      {
        'notificationId': 'NTF-ABC123456789',
        'eventId': 'ALERT-1',
        'subjectType': 'STOCK',
        'subjectId': '005930',
        'sourceType': 'DISCLOSURE',
        'title': 'Samsung disclosure translated',
        'summary': 'AI summary with sentiment and importance.',
        'originalUrl': 'https://dart.fss.or.kr/report',
        'primaryStockCode': '005930',
        'matchedStockCodes': ['005930'],
        'matchReasons': ['WATCHLIST'],
        'glossaryTerms': [_glossaryTerm('공시', 'disclosure', 'DISCLOSURE')],
        'translationQualityFlags': ['GLOSSARY_MATCHED'],
        'deliveryStatus': 'DELIVERED',
        'deliveryProvider': 'LOCAL_INBOX',
        'deliveryAttemptCount': 1,
        'deliveredAt': '2026-06-18T06:00:00Z',
        'lastDeliveryError': null,
        'read': false,
        'createdAt': '2026-06-18T06:00:00Z',
        'readAt': null,
      }
    ],
    'servedAt': '2026-06-18T06:01:00Z',
  };
}

Map<String, Object?> _readNotificationJson() {
  final notifications =
      _notificationInboxJson()['notifications'] as List<Object?>;
  return {
    ...(notifications.single as Map<String, Object?>),
    'read': true,
    'readAt': '2026-06-18T06:02:00Z',
  };
}

Map<String, Object?> _notificationDevicesJson() {
  return {
    'accountId': 'ACC-ABC123456789',
    'activeCount': 1,
    'totalCount': 1,
    'devices': [
      {
        'deviceTokenId': 'NTD-ABC123456789',
        'platform': 'IOS',
        'provider': 'LOCAL_NOOP_PUSH',
        'tokenHash': 'hash',
        'maskedToken': 'local-...0001',
        'appVersion': '0.1.0',
        'locale': 'en_US',
        'active': true,
        'registeredAt': '2026-06-18T06:00:00Z',
        'lastSeenAt': '2026-06-18T06:00:00Z',
        'disabledAt': null,
      }
    ],
    'servedAt': '2026-06-18T06:01:00Z',
  };
}

Map<String, Object?> _stockIntelligenceJson() {
  return {
    'stockCode': '005930',
    'dataSource': 'ALERT_EVENT_STORE',
    'itemCount': 1,
    'items': [
      {
        'eventId': 'ALERT-1',
        'sourceType': 'NEWS',
        'title': 'Samsung earnings improve',
        'summary': 'Translated three-line summary.',
        'originalUrl': 'https://news.example.com/1',
        'primaryStockCode': '005930',
        'relatedStocks': ['005930'],
        'sentiment': 'POSITIVE',
        'importance': 'HIGH',
        'riskLevel': 'LOW',
        'glossaryTerms': [_glossaryTerm('실적', 'earnings', 'ACCOUNTING')],
        'translationQualityFlags': ['GLOSSARY_MATCHED'],
        'watchlistTarget': true,
        'holderTarget': false,
        'publishedAt': '2026-06-18T05:55:00Z',
        'receivedAt': '2026-06-18T06:00:00Z',
        'targetCount': 1,
      }
    ],
    'servedAt': '2026-06-18T06:01:00Z',
  };
}

Map<String, Object?> _glossaryTerm(
  String sourceTerm,
  String englishTerm,
  String category,
) {
  return {
    'sourceTerm': sourceTerm,
    'normalizedTerm': sourceTerm,
    'englishTerm': englishTerm,
    'category': category,
  };
}
