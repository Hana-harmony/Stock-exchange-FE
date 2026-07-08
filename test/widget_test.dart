import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_exchange_fe/src/app.dart';
import 'package:stock_exchange_fe/src/core/account_controller.dart';
import 'package:stock_exchange_fe/src/core/exchange_api_client.dart';
import 'package:stock_exchange_fe/src/core/exchange_session_controller.dart';
import 'package:stock_exchange_fe/src/core/market_calendar_controller.dart';
import 'package:stock_exchange_fe/src/core/market_detail_controller.dart';
import 'package:stock_exchange_fe/src/core/market_index_controller.dart';
import 'package:stock_exchange_fe/src/core/market_news_controller.dart';
import 'package:stock_exchange_fe/src/core/market_quote_controller.dart';
import 'package:stock_exchange_fe/src/core/notification_controller.dart';
import 'package:stock_exchange_fe/src/core/trade_controller.dart';
import 'package:stock_exchange_fe/src/core/watchlist_controller.dart';
import 'package:stock_exchange_fe/src/ui/assets/app_assets.dart';
import 'package:stock_exchange_fe/src/ui/theme/app_tokens.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadPretendardFont();
  });

  testWidgets('renders markets landing page and navigates bottom tabs',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(
        marketQuoteController: marketQuoteController,
        nowProvider: () => DateTime.parse('2026-07-06T00:15:00Z'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Markets'), findsOneWidget);
    expect(find.bySemanticsLabel('AI Assistant'), findsOneWidget);
    expect(find.bySemanticsLabel('Search'), findsOneWidget);
    expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
    expect(find.byKey(const ValueKey('market-status-section')), findsOneWidget);
    expect(find.byKey(const ValueKey('market-status-card-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('market-status-card-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('market-status-card-2')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('market-indicator-banner')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('market-indicator-summary-0')),
      findsOneWidget,
    );
    expect(find.text('KOSPI'), findsWidgets);
    expect(find.text('KOSDAQ'), findsWidgets);
    expect(find.text('2570.94'), findsOneWidget);
    expect(find.text('09:15'), findsOneWidget);
    expect(find.text('Closing call auction'), findsWidgets);
    expect(find.text('Trending Stocks'), findsOneWidget);
    expect(find.text('Samsung Electronics'), findsWidgets);
    expect(
      _findAssetImage('assets/stock_logos/kr/005930.png'),
      findsWidgets,
    );
    expect(
      _findAssetImage(AppAssets.stockCardRed),
      findsNothing,
    );
    expect(
      _findAssetImage(AppAssets.stockCardGreen),
      findsNothing,
    );
    expect(
      _findAssetImage(AppAssets.marketDataContainer),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('trending-stock-005930')));
    await tester.pumpAndSettle();

    expect(find.text('Samsung Electronics'), findsWidgets);
    expect(
        find.byKey(const ValueKey('stock-detail-tab-chart')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stock-detail-tab-chart')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stock-chart-content')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-nav-Accounts')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('accounts-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('accounts-page-title')), findsOneWidget);
    expect(find.text('Total Assets'), findsOneWidget);
    expect(find.text('USD 50,000.00'), findsOneWidget);
    expect(find.text('USD 0.00 (0.00%)'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('${_testSession.accountId} [ISA(Brokerage)]'),
        findsOneWidget);

    final moreIcon = tester.widget<Image>(
      find
          .descendant(
            of: find.byKey(const ValueKey('accounts-header-more')),
            matching: find.byType(Image),
          )
          .first,
    );
    expect((moreIcon.image as AssetImage).assetName, AppAssets.headerMoreIcon);
    expect(moreIcon.width, 36);
    expect(moreIcon.height, 36);

    final settingsIcon = tester.widget<Image>(
      find
          .descendant(
            of: find.byKey(const ValueKey('accounts-header-settings')),
            matching: find.byType(Image),
          )
          .first,
    );
    expect(
      (settingsIcon.image as AssetImage).assetName,
      AppAssets.settingsIcon,
    );
    expect(settingsIcon.width, 36);
    expect(settingsIcon.height, 36);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-WatchLists')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'WatchLists'), findsOneWidget);
    expect(find.byKey(const ValueKey('watchlist-screen')), findsOneWidget);
    expect(find.text('Watchlist'), findsOneWidget);
    expect(find.byKey(const ValueKey('watchlist-item-005930')), findsOneWidget);
    expect(find.text('Samsung Electronics'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-Discover')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Discover'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('discover-market-news-list')),
      findsOneWidget,
    );
    expect(
      find.text('Korea market rebounds as chip stocks recover'),
      findsOneWidget,
    );
    expect(
      _findNetworkImage('https://news.example.com/market.jpg'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('market-news-card-MKT-NEWS-001')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('market-news-detail-screen')),
      findsOneWidget,
    );
    expect(find.text('AI Analysis'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text
                .toPlainText()
                .contains('Detailed translated market article from OmniLens.'),
      ),
      findsOneWidget,
    );
    expect(find.text('View Original'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('notification-article-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('discover-market-news-list')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('bottom-nav-MY')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('my-screen')), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text(_testSession.accountId), findsOneWidget);
    expect(find.byKey(const ValueKey('my-logout-button')), findsOneWidget);

    AssetImage notificationAsset() {
      final container =
          find.byKey(const ValueKey('header-notifications-image'));
      final image = tester.widget<Image>(
        find
            .descendant(
              of: container,
              matching: find.byType(Image),
            )
            .first,
      );
      return image.image as AssetImage;
    }

    await tester.tap(find.byKey(const ValueKey('bottom-nav-Markets')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Markets'), findsOneWidget);
    expect(notificationAsset().assetName, AppAssets.headerNotificationsNew);

    await tester.tap(find.bySemanticsLabel('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('notification-filter-all')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notification-filter-portfolio')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notification-filter-watchlist')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notification-card-LOCAL-NTF-0001')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('notification-card-LOCAL-NTF-0001')),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI Analysis'), findsOneWidget);
    expect(find.text('View Original'), findsOneWidget);
    expect(_findAssetImage(AppAssets.hanaMontanaAnalysisCharacter),
        findsOneWidget);
    expect(find.text('Glossary'), findsNothing);
    final glossaryParagraph = tester.widget<RichText>(
      find.descendant(
        of: find.byKey(const ValueKey('notification-article-body-paragraph-0')),
        matching: find.byType(RichText),
      ),
    );
    expect(
        glossaryParagraph.text.toPlainText(), contains('Daejangju for FY2025'));
    await tester.tapAt(
      tester.getTopLeft(
            find.byKey(
              const ValueKey('notification-article-body-paragraph-0'),
            ),
          ) +
          const Offset(160, 12),
    );
    await tester.pumpAndSettle();

    expect(find.text('Financial Glossary'), findsOneWidget);
    expect(find.text('Daejangju (Market Leader)'), findsOneWidget);
    expect(
      find.textContaining('dictates the overall trend.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('notification-article-back')));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('notification-card-LOCAL-NTF-0001')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('notification-header-back')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Markets'), findsOneWidget);
    expect(notificationAsset().assetName, AppAssets.headerNotifications);
  });

  testWidgets(
      'markets requests ten default trending quotes despite seed quotes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final requestedStockCodes = <List<String>>[];
    final marketQuoteController = MarketQuoteController(
      seedQuotes: seedMarketQuotes,
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/v1/stocks/search-rankings') {
            return http.Response('{}', 500);
          }
          if (request.url.path == '/api/v1/market/quotes') {
            final stockCodes =
                request.url.queryParametersAll['stockCodes'] ?? const [];
            requestedStockCodes.add(stockCodes);
            final quotes = stockCodes
                .asMap()
                .entries
                .map((entry) => _quoteJson(_marketQuoteForCode(
                      entry.value,
                      entry.key,
                    )))
                .toList(growable: false);
            return _jsonEnvelope({
              'dataSource': 'Stock-exchange-BE',
              'marketCoverage': 'REQUESTED_STOCK_CODES',
              'displayCurrency': 'USD',
              'transport': {
                'snapshot': 'REST',
                'realtime': 'WebSocket',
              },
              'cache': {'status': 'HIT'},
              'quoteCount': quotes.length,
              'quotes': quotes,
              'servedAt': '2026-06-18T06:00:00Z',
            });
          }
          return http.Response('{}', 404);
        }),
      ),
    );
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();

    expect(requestedStockCodes, isNotEmpty);
    expect(requestedStockCodes.last, hasLength(10));
    expect(
      requestedStockCodes.last,
      containsAll([
        '005930',
        '000660',
        '005380',
        '000270',
        '086790',
        '035420',
        '068270',
        '105560',
        '055550',
        '012330',
      ]),
    );
    expect(find.byKey(const ValueKey('trending-stock-000660')), findsOneWidget);
  });

  testWidgets('markets surfaces provider outages instead of empty states',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const quoteMessage =
        'KIS market data provider is unavailable for stockCode=005930';
    const indexMessage = 'KIS index data provider is unavailable.';
    final marketIndexController = MarketIndexController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/v1/market/indices') {
            return _jsonErrorEnvelope(
              status: 502,
              code: 'MARKET_001',
              message: indexMessage,
            );
          }
          return http.Response('{}', 404);
        }),
      ),
    );
    final marketQuoteController = MarketQuoteController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/v1/stocks/search-rankings') {
            return _jsonErrorEnvelope(
              status: 502,
              code: 'MARKET_001',
              message: quoteMessage,
            );
          }
          if (request.url.path == '/api/v1/market/quotes') {
            return _jsonErrorEnvelope(
              status: 502,
              code: 'MARKET_001',
              message: quoteMessage,
            );
          }
          return http.Response('{}', 404);
        }),
      ),
    );
    addTearDown(marketIndexController.dispose);
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(
        marketIndexController: marketIndexController,
        marketQuoteController: marketQuoteController,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Market indices unavailable'), findsOneWidget);
    expect(find.text(indexMessage), findsOneWidget);
    expect(find.text('No indices'), findsNothing);
    expect(find.text('Market data unavailable'), findsOneWidget);
    expect(find.text(quoteMessage), findsOneWidget);
    expect(find.text('No stocks'), findsNothing);
  });

  testWidgets('searches stocks and opens the placeholder detail tabs',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Search History'), findsOneWidget);
    expect(find.byKey(const ValueKey('market-search-input')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('market-search-input')),
      '카카오',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('market-search-results-input')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('stock-search-result-035720')),
        findsOneWidget);
    expect(find.textContaining('KakaoBank'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stock-search-result-035720')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kakao'), findsWidgets);
    expect(find.textContaining('035720'), findsOneWidget);
    expect(find.text('Order'), findsWidgets);
    expect(find.text('K-News'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stock-detail-tab-chart')));
    await tester.pumpAndSettle();
    expect(find.byKey(const PageStorageKey<String>('stock-chart-tab')),
        findsOneWidget);
  });

  testWidgets('opens the original market news URL from detail button',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final previousLauncher = UrlLauncherPlatform.instance;
    final launcher = _RecordingUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() {
      UrlLauncherPlatform.instance = previousLauncher;
    });

    final marketQuoteController = _marketQuoteController();
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-nav-Discover')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('market-news-card-MKT-NEWS-001')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('notification-article-view-original')),
    );
    await tester.pump();

    expect(launcher.launchedUrls, ['https://news.example.com/market']);
    expect(
      launcher.lastOptions?.mode,
      PreferredLaunchMode.externalApplication,
    );
    expect(launcher.lastOptions?.webOnlyWindowName, '_blank');
  });

  testWidgets('adds a stock to backend watchlist from detail heart',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('market-search-input')),
      '카카오',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-search-result-035720')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('stock-detail-favorite-button')),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-nav-WatchLists')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('watchlist-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('watchlist-item-035720')), findsOneWidget);
    expect(find.text('Kakao'), findsWidgets);
  });

  testWidgets('pins detail tabs and reveals compact header on scroll',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('market-search-input')),
      '카카오',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-search-result-035720')));
    await tester.pumpAndSettle();

    final collapsedHeader = find.byKey(
      const ValueKey('stock-detail-collapsed-header'),
    );
    expect(collapsedHeader, findsOneWidget);

    final beforeScroll = tester.widget<AnimatedOpacity>(collapsedHeader);
    expect(beforeScroll.opacity, 0);

    await tester.drag(
      find.byKey(const PageStorageKey<String>('stock-order-tab')),
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();

    final afterScroll = tester.widget<AnimatedOpacity>(collapsedHeader);
    expect(afterScroll.opacity, greaterThan(beforeScroll.opacity));
    expect(afterScroll.opacity, greaterThan(0.8));
    expect(find.text('Order'), findsOneWidget);
  });

  testWidgets('opens the figma order entry screen when tapping buy',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('market-search-input')),
      '카카오',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-search-result-035720')));
    await tester.pumpAndSettle();

    final stockNameHelpIcon = tester.widget<Image>(
      find.byKey(const ValueKey('stock-detail-name-help-icon')),
    );
    expect(
      (stockNameHelpIcon.image as AssetImage).assetName,
      AppAssets.questionIcon,
    );
    expect(stockNameHelpIcon.width, 24);
    expect(stockNameHelpIcon.height, 24);

    await tester.tap(find.byKey(const ValueKey('stock-detail-buy-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('stock-order-entry-screen')),
      findsOneWidget,
    );
    expect(find.text('Limit Order'), findsOneWidget);
    expect(find.text('Modify/Cancel'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Mid Price'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('stock-order-submit-button')),
      findsOneWidget,
    );
    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('\$'), findsWidgets);
  });

  testWidgets('opens global peer sheet from stock detail name help icon',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('market-search-input')),
      '카카오',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-search-result-035720')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('stock-detail-name-help-icon-button')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Kakao is the Block of South Korea'),
        findsOneWidget);
    expect(find.textContaining('Revenue model mixes'), findsOneWidget);
    expect(find.text('Global Comparison'), findsOneWidget);
    expect(_findAssetImage('assets/stock_logos/us/SQ.png'), findsOneWidget);
    expect(_findAssetImage('assets/stock_logos/us/PYPL.png'), findsOneWidget);
    expect(find.textContaining('Overall Business'), findsOneWidget);
    expect(find.textContaining('Block'), findsWidgets);
    expect(find.text('Key Strengths'), findsOneWidget);
    expect(find.textContaining('Payments'), findsWidgets);
    expect(
      find.textContaining('Kakao is tagged for payments exposure'),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('global-peer-bottom-sheet')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    final headlineText = tester.widget<Text>(
      find.byKey(const ValueKey('global-peer-sheet-headline')),
    );
    expect(headlineText.maxLines, isNull);
    expect(headlineText.overflow, TextOverflow.visible);

    final peerSummaryText = tester.widget<Text>(
      find.textContaining('PayPal provides a global payments benchmark').first,
    );
    expect(peerSummaryText.maxLines, isNull);
    expect(peerSummaryText.overflow, TextOverflow.visible);

    final strengthDescriptionText = tester.widget<Text>(
      find
          .textContaining(
            'Kakao is tagged for payments exposure',
          )
          .first,
    );
    expect(strengthDescriptionText.maxLines, isNull);
    expect(strengthDescriptionText.overflow, TextOverflow.visible);
  });

  testWidgets('updates quantity, price, and order amount in order entry',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('market-search-input')),
      '카카오',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-search-result-035720')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-detail-buy-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('stock-order-quantity-input')),
      '7',
    );
    await tester.enterText(
      find.byKey(const ValueKey('stock-order-price-input')),
      '1200',
    );
    await tester.pumpAndSettle();

    expect(find.text('\$8,400'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('stock-order-step-minus')).first);
    await tester.pumpAndSettle();

    expect(find.text('\$7,200'), findsOneWidget);
  });

  testWidgets('shows account pin bottom sheet from order entry buy button',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('market-search-input')),
      '카카오',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-search-result-035720')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-detail-buy-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('stock-order-quantity-input')),
      '100',
    );
    await tester.enterText(
      find.byKey(const ValueKey('stock-order-price-input')),
      '1000000',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-order-submit-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('stock-order-pin-sheet')), findsOneWidget);
    expect(find.text('Account PIN'), findsWidgets);
    expect(
        find.byKey(const ValueKey('stock-order-pin-cancel')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('stock-order-pin-confirm')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('stock-order-pin-key-1')));
    await tester.tap(find.byKey(const ValueKey('stock-order-pin-key-2')));
    await tester.tap(find.byKey(const ValueKey('stock-order-pin-key-3')));
    await tester.tap(find.byKey(const ValueKey('stock-order-pin-key-4')));
    await tester.pumpAndSettle();

    final partialPinDisplay = tester.widget<Text>(
      find.byKey(const ValueKey('stock-order-pin-display')),
    );
    expect(partialPinDisplay.data, '●\u00A0●\u00A0●\u00A0●');

    await tester.tap(find.byKey(const ValueKey('stock-order-pin-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('stock-order-pin-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stock-order-pin-key-5')));
    await tester.tap(find.byKey(const ValueKey('stock-order-pin-key-6')));
    await tester.pumpAndSettle();

    final fullPinDisplay = tester.widget<Text>(
      find.byKey(const ValueKey('stock-order-pin-display')),
    );
    expect(fullPinDisplay.data, '●\u00A0●\u00A0●\u00A0●\u00A0●\u00A0●');

    await tester.tap(find.byKey(const ValueKey('stock-order-pin-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('stock-order-pin-sheet')), findsNothing);
    expect(
      find.byKey(const ValueKey('stock-order-confirm-dialog')),
      findsOneWidget,
    );
    expect(find.text('Confirm Buy Order'), findsOneWidget);
    expect(find.text('Order Price'), findsOneWidget);
    expect(find.text('Total Amount'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('stock-order-confirm-dialog')),
        matching: find.text('Kakao'),
      ),
      findsOneWidget,
    );
    expect(find.text(r'$1,000.000'), findsOneWidget);
    expect(find.text('100 Shares'), findsOneWidget);
    expect(find.text(r'$100,000.000'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stock-order-confirm-submit')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('stock-order-confirm-dialog')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('stock-order-complete-dialog')),
      findsOneWidget,
    );
    expect(find.text('Order Completed'), findsOneWidget);
    expect(
      find.text(
        'Your buy order has been successfully submitted.\n'
        'You can view your order details in the Accounts tab.',
      ),
      findsOneWidget,
    );
    expect(find.text('View Accounts'), findsOneWidget);

    final viewAccountsButton = find.byKey(
      const ValueKey('stock-order-complete-view-accounts'),
    );
    final viewAccountsIcon = tester.widget<ImageIcon>(
      find
          .descendant(
            of: viewAccountsButton,
            matching: find.byType(ImageIcon),
          )
          .first,
    );
    expect((viewAccountsIcon.image as AssetImage).assetName,
        AppAssets.externalLinkIcon);
    expect(viewAccountsIcon.color, AppColors.gray700);
    expect(viewAccountsIcon.size, 24);

    await tester.tap(
      find.byKey(const ValueKey('stock-order-complete-view-accounts')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('stock-order-complete-dialog')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('accounts-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('accounts-page-title')), findsOneWidget);
    expect(find.text('Total Assets'), findsOneWidget);
  });

  testWidgets('matches figma layout metrics for order entry confirmation',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 62, bottom: 34);
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
      tester.view.resetViewPadding();
      tester.binding.setSurfaceSize(null);
    });

    final marketQuoteController = _marketQuoteController();
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('market-search-input')),
      '카카오',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-search-result-035720')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-detail-buy-button')));
    await tester.pumpAndSettle();

    _expectRect(
      tester.getRect(find.byKey(const ValueKey('stock-detail-page-title'))),
      const Rect.fromLTWH(0, 62, 402, 44),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('stock-order-top-section'))),
      const Rect.fromLTWH(0, 106, 402, 158),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('stock-order-account-info'))),
      const Rect.fromLTWH(16, 208, 370, 44),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('stock-order-entry-tabs'))),
      const Rect.fromLTWH(0, 264, 402, 41),
    );
    _expectRect(
      tester
          .getRect(find.byKey(const ValueKey('stock-order-quote-list-shell'))),
      const Rect.fromLTWH(0, 305, 152, 535),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('stock-order-form-panel'))),
      const Rect.fromLTWH(152, 305, 250, 535),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('stock-order-settlement-tabs'))),
      const Rect.fromLTWH(168, 325, 218, 36),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('stock-order-select-field'))),
      const Rect.fromLTWH(168, 381, 218, 40),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('stock-order-checkbox-row'))),
      const Rect.fromLTWH(168, 441, 218, 17),
    );
    _expectRect(
      tester
          .getRect(find.byKey(const ValueKey('stock-order-stepper-Quantity'))),
      const Rect.fromLTWH(168, 478, 218, 68),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('stock-order-stepper-Price'))),
      const Rect.fromLTWH(168, 566, 218, 68),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('stock-order-submit-section'))),
      const Rect.fromLTWH(168, 714, 218, 110),
    );

    await tester.enterText(
      find.byKey(const ValueKey('stock-order-quantity-input')),
      '100',
    );
    await tester.enterText(
      find.byKey(const ValueKey('stock-order-price-input')),
      '1000000',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-order-submit-button')));
    await tester.pumpAndSettle();

    for (final key in const ['1', '2', '3', '4', '5', '6']) {
      await tester.tap(find.byKey(ValueKey('stock-order-pin-key-$key')));
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-order-pin-confirm')));
    await tester.pumpAndSettle();

    _expectRect(
      tester.getRect(find.byKey(const ValueKey('stock-order-confirm-dialog'))),
      const Rect.fromLTWH(21, 256, 360, 362),
    );
    _expectRect(
      tester.getRect(
        find.byKey(const ValueKey('stock-order-confirm-details-card')),
      ),
      const Rect.fromLTWH(39, 367, 324, 164),
    );

    await tester.tap(find.byKey(const ValueKey('stock-order-confirm-submit')));
    await tester.pumpAndSettle();

    _expectRect(
      tester.getRect(find.byKey(const ValueKey('stock-order-complete-dialog'))),
      const Rect.fromLTWH(21, 347, 360, 180),
    );
    _expectRect(
      tester.getRect(
        find.byKey(const ValueKey('stock-order-complete-view-accounts')),
      ),
      const Rect.fromLTWH(39, 458, 324, 45),
    );
  });

  testWidgets('matches figma layout metrics for accounts screen',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 62, bottom: 34);
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
      tester.view.resetViewPadding();
      tester.binding.setSurfaceSize(null);
    });

    final marketQuoteController = _marketQuoteController();
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-nav-Accounts')));
    await tester.pumpAndSettle();

    _expectRect(
      tester.getRect(find.byKey(const ValueKey('accounts-page-title'))),
      const Rect.fromLTWH(0, 62, 402, 44),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('accounts-primary-tabs'))),
      const Rect.fromLTWH(0, 106, 402, 41),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('accounts-account-selector'))),
      const Rect.fromLTWH(0, 147, 402, 56),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('accounts-summary-section'))),
      const Rect.fromLTWH(0, 203, 402, 149),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('accounts-summary-card'))),
      const Rect.fromLTWH(12, 219, 378, 117),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('accounts-asset-filter-tabs'))),
      const Rect.fromLTWH(0, 352, 402, 34),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('accounts-asset-filter-tab-0'))),
      const Rect.fromLTWH(12, 352, 43, 34),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('accounts-asset-filter-tab-1'))),
      const Rect.fromLTWH(63, 352, 93, 34),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('portfolio-allocation-chart'))),
      const Rect.fromLTWH(0, 402, 402, 96),
    );
    _expectRect(
      tester
          .getRect(find.byKey(const ValueKey('accounts-holdings-filter-row'))),
      const Rect.fromLTWH(0, 498, 402, 56),
    );
    _expectRect(
      tester
          .getRect(find.byKey(const ValueKey('accounts-market-scope-segment'))),
      const Rect.fromLTWH(269, 508, 121, 36),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('accounts-table-header'))),
      const Rect.fromLTWH(0, 554, 402, 48),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('accounts-holding-row-0'))),
      const Rect.fromLTWH(0, 602, 402, 62),
    );

    final totalPositions = tester.widget<RichText>(
      find.byKey(const ValueKey('accounts-total-positions')),
    );
    expect(totalPositions.text.toPlainText(), 'Total 60 Positions');
    expect(find.text('USD 50,000.00'), findsOneWidget);
    expect(find.text('USD 0.00 (0.00%)'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.text('Foreign Currency (Cash Balance)'))
          .overflow,
      isNull,
    );
  });

  testWidgets('shows K-News toolbar and switches between list and card layouts',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('market-search-input')),
      '카카오',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-search-result-035720')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-detail-tab-k-news')));
    await tester.pumpAndSettle();

    expect(find.byKey(const PageStorageKey<String>('stock-k-news-tab')),
        findsOneWidget);
    expect(find.text('Newest'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('stock-news-layout-list')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('stock-news-layout-grid')), findsOneWidget);
    expect(
      find.text('Kakao expands global content partnerships'),
      findsOneWidget,
    );
    expect(
      find.text('Kakao files major shareholding disclosure'),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('stock-news-list-tile-NEWS-1')));
    await tester.pumpAndSettle();

    expect(find.text('AI Analysis'), findsNothing);
    expect(
      find.text('() crisis intraday Korean stock market.'),
      findsNothing,
    );
    expect(find.text('카카오는 신규 콘텐츠 제휴를 체결했다.'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains(
                  'Kakao full translated news content.',
                ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('notification-article-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-news-layout-grid')));
    await tester.pumpAndSettle();

    expect(find.byKey(const PageStorageKey<String>('stock-k-news-tab')),
        findsOneWidget);
    expect(find.text('Card'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('stock-detail-tab-disclosures')));
    await tester.pumpAndSettle();

    expect(
      find.text('Kakao files major shareholding disclosure'),
      findsOneWidget,
    );
    expect(
      find.text('Kakao expands global content partnerships'),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('stock-news-list-tile-DISCLOSURE-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI Analysis'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains(
                  'Kakao full translated disclosure content.',
                ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders stock detail chart and API fundamentals',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    final chartRequests = <Uri>[];
    final marketDetailController = _marketDetailController(
      chartRequests: chartRequests,
      stockMarketDataTime: '2026-07-04T06:30:00Z',
    );
    addTearDown(marketQuoteController.dispose);
    addTearDown(marketDetailController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(
        marketQuoteController: marketQuoteController,
        marketDetailController: marketDetailController,
        nowProvider: () => DateTime.parse('2026-07-03T15:10:00Z'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('market-search-input')),
      '카카오',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-search-result-035720')));
    await tester.pumpAndSettle();

    expect(chartRequests, isNotEmpty);
    expect(chartRequests.first.queryParameters['from'], '2026-07-03');
    expect(chartRequests.first.queryParameters['to'], '2026-07-03');
    expect(chartRequests.first.queryParameters['interval'], '1m');
    expect(find.text('Market Closed Jul 3, 2026 3:30 PM KST'), findsOneWidget);
    expect(find.textContaining('Jul 4, 2026 3:30 PM KST'), findsNothing);
    expect(find.text('+USD 0.40 +1.14%'), findsWidgets);

    await tester
        .tap(find.byKey(const ValueKey('stock-detail-tab-fundamentals')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const PageStorageKey<String>('stock-fundamentals-tab')),
      findsOneWidget,
    );
    expect(find.text('Market Status'), findsOneWidget);
    expect(find.text('Foreign Ownership'), findsOneWidget);
    expect(find.text('KOSPI'), findsOneWidget);
    expect(find.text('27.0%~27.6%'), findsOneWidget);
    expect(find.text('test / TIME_SERIES_ADJUSTED 0.91'), findsOneWidget);
    expect(find.byKey(const ValueKey('stock-fundamentals-trigger-vi')),
        findsNothing);
    expect(find.byKey(const ValueKey('stock-fundamentals-trigger-low-limit')),
        findsNothing);

    await tester.tap(find.byKey(const ValueKey('stock-detail-tab-chart')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('stock-chart-content')), findsOneWidget);
    expect(find.text('1D price chart'), findsOneWidget);
    expect(find.text('09:00 KST'), findsOneWidget);
    expect(find.text('15:30 KST'), findsOneWidget);
    expect(find.text('USD 35.50'), findsWidgets);
    expect(find.text('KRW 54,800'), findsOneWidget);
    expect(find.text('KRW 53,200'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stock-chart-period-1W')));
    await tester.pumpAndSettle();
    expect(find.text('1W price chart'), findsOneWidget);
    expect(chartRequests.last.queryParameters['from'], '2026-06-26');
    expect(chartRequests.last.queryParameters['to'], '2026-07-03');
    expect(chartRequests.last.queryParameters['interval'], '30m');
    expect(find.text('+USD 1.50 +4.41%'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('stock-chart-period-1M')));
    await tester.pumpAndSettle();
    expect(find.text('1M price chart'), findsOneWidget);
    expect(chartRequests.last.queryParameters['from'], '2026-06-02');
    expect(chartRequests.last.queryParameters['to'], '2026-07-03');
    expect(chartRequests.last.queryParameters['interval'], '1d');
    expect(find.text('+USD 5.50 +18.33%'), findsWidgets);
  });

  testWidgets('extends 1D stock chart with live quote candle', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController(
      seedQuotes: [
        MarketQuote(
          stockCode: '035720',
          stockName: 'Kakao',
          market: 'KOSPI',
          currentPriceKrw: '56000',
          changeRate: '+2.30%',
          volume: 1300000,
          localCurrency: 'USD',
          localCurrencyPrice: '36.70',
          fxRate: '1525.93',
          fxRateTime: null,
          fxRateSource: 'Hana-OmniLens-API',
          fxStale: false,
          marketDataTime: DateTime.utc(2026, 7, 3, 5, 1, 30),
          badge: 'Live',
        ),
      ],
    );
    final marketDetailController = _marketDetailController(
      stockMarketDataTime: '2026-07-03T06:30:00Z',
    );
    final sessionController = _sessionController();
    final tradeController = _tradeController();
    final notificationController = _notificationController();
    addTearDown(marketQuoteController.dispose);
    addTearDown(marketDetailController.dispose);
    addTearDown(sessionController.dispose);
    addTearDown(tradeController.dispose);
    addTearDown(notificationController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: StockDetailScreen(
          sessionController: sessionController,
          marketDetailController: marketDetailController,
          marketQuoteController: marketQuoteController,
          tradeController: tradeController,
          notificationController: notificationController,
          stockCode: '035720',
          title: 'Kakao',
          market: 'KOSPI',
          sector: 'IT',
          nowProvider: () => DateTime.parse('2026-07-03T05:02:00Z'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(marketQuoteController.quoteFor('035720')?.currentPriceKrw, '56000');
    expect(
      marketQuoteController.quoteFor('035720')?.marketDataTime?.toUtc(),
      DateTime.utc(2026, 7, 3, 5, 1, 30),
    );

    await tester.tap(find.byKey(const ValueKey('stock-detail-tab-chart')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('stock-chart-content')), findsOneWidget);
    expect(find.text('1D price chart'), findsOneWidget);
    final latestPrice = tester.widget<Text>(
      find.byKey(const ValueKey('stock-chart-latest-price')),
    );
    expect(latestPrice.data, 'USD 36.70');
  });

  testWidgets('hides foreign ownership forecast for non restricted stocks',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    final marketDetailController = _marketDetailController(
      foreignOwnershipPredictionConfidenceLevel: 'NOT_APPLICABLE',
      foreignOwnershipPredictionConfidenceScore: '0',
      foreignOwnershipPredictionModelVersion: 'none',
    );
    addTearDown(marketQuoteController.dispose);
    addTearDown(marketDetailController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(
        marketQuoteController: marketQuoteController,
        marketDetailController: marketDetailController,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('market-search-input')),
      '카카오',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-search-result-035720')));
    await tester.pumpAndSettle();

    expect(find.text('Foreign Ownership Forecast'), findsNothing);
    expect(find.text('Foreign Ownership Limit Alert'), findsNothing);

    await tester
        .tap(find.byKey(const ValueKey('stock-detail-tab-fundamentals')));
    await tester.pumpAndSettle();

    expect(find.text('Market Status'), findsOneWidget);
    expect(find.text('Foreign Ownership'), findsNothing);
    expect(find.text('Estimated exhaustion'), findsNothing);
    expect(find.text('none / NOT_APPLICABLE 0'), findsNothing);
  });

  testWidgets(
      'shows initial loading before quote and detail data are available',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = MarketQuoteController(
      seedQuotes: const [],
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async => _jsonEnvelope({
              'dataSource': 'Stock-exchange-BE',
              'marketCoverage': 'KOREA',
              'displayCurrency': 'USD',
              'quoteCount': 0,
              'quotes': <Object?>[],
              'servedAt': '2026-06-18T06:00:00Z',
            })),
      ),
    );
    final marketDetailController = _loadingMarketDetailController();
    final sessionController = _sessionController();
    final tradeController = _tradeController();
    final notificationController = _notificationController();
    addTearDown(marketQuoteController.dispose);
    addTearDown(marketDetailController.dispose);
    addTearDown(sessionController.dispose);
    addTearDown(tradeController.dispose);
    addTearDown(notificationController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: StockDetailScreen(
          sessionController: sessionController,
          marketDetailController: marketDetailController,
          marketQuoteController: marketQuoteController,
          tradeController: tradeController,
          notificationController: notificationController,
          stockCode: '005930',
          title: 'Samsung Electronics',
          market: 'KOSPI',
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('stock-detail-initial-loading')),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey('stock-detail-initial-error')), findsNothing);
  });

  testWidgets(
      'renders stock detail from live quote while detail API is pending',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    final marketDetailController = _loadingMarketDetailController();
    final sessionController = _sessionController();
    final tradeController = _tradeController();
    final notificationController = _notificationController();
    addTearDown(marketQuoteController.dispose);
    addTearDown(marketDetailController.dispose);
    addTearDown(sessionController.dispose);
    addTearDown(tradeController.dispose);
    addTearDown(notificationController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: StockDetailScreen(
          sessionController: sessionController,
          marketDetailController: marketDetailController,
          marketQuoteController: marketQuoteController,
          tradeController: tradeController,
          notificationController: notificationController,
          stockCode: '005930',
          title: 'Samsung Electronics',
          market: 'KOSPI',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey('stock-detail-initial-loading')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('stock-detail-partial-loading')),
      findsOneWidget,
    );
    expect(find.text('Loading market data'), findsNothing);
    expect(find.text('Live quote updating'), findsOneWidget);
    expect(find.text('005930'), findsOneWidget);
    expect(find.text('Samsung Electronics'), findsWidgets);
    expect(find.text('USD 54.00'), findsOneWidget);
    expect(find.text('KRW 82,400'), findsOneWidget);
  });

  testWidgets('blocks sell with VI warning modal when VI is triggered',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    final marketDetailController = _marketDetailController(viActive: true);
    addTearDown(marketQuoteController.dispose);
    addTearDown(marketDetailController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(
        marketDetailController: marketDetailController,
        marketQuoteController: marketQuoteController,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('market-search-input')),
      '카카오',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-search-result-035720')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sell'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('vi-restriction-dialog')), findsOneWidget);
    expect(find.text('Volatility Interruption Triggered!'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('vi-restriction-confirm')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('vi-restriction-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('vi-restriction-dialog')), findsNothing);
  });

  testWidgets(
      'blocks buy with price limit warning modal when low limit is triggered',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    final marketDetailController = _marketDetailController(
      priceLimitState: 'LOWER',
    );
    addTearDown(marketQuoteController.dispose);
    addTearDown(marketDetailController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(
        marketDetailController: marketDetailController,
        marketQuoteController: marketQuoteController,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('market-search-input')),
      '카카오',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stock-search-result-035720')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buy'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('price-limit-restriction-dialog')),
      findsOneWidget,
    );
    expect(find.text('Price Limit Reached!'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('price-limit-restriction-confirm')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('price-limit-restriction-confirm')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('price-limit-restriction-dialog')),
      findsNothing,
    );
  });

  testWidgets('shows API search results with orange query highlight',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('market-search-input')),
      'Samsung',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('stock-search-result-005930')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('stock-search-result-07747')),
      findsOneWidget,
    );
    expect(find.text('Samsung Electronics'), findsOneWidget);
    expect(
      find.text('CSOP Samsung Electronics Daily (2x) Leveraged Product'),
      findsOneWidget,
    );

    final samsungText = find.descendant(
      of: find.byKey(const ValueKey('stock-search-result-005930')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText() == 'Samsung Electronics',
      ),
    );

    final textSpan = tester.widget<RichText>(samsungText).text;
    final highlightSpan =
        _allTextSpans(textSpan).firstWhere((span) => span.text == 'Samsung');
    expect(highlightSpan.style?.color, AppColors.orange500);
  });

  test('labels quote status as closed outside Korea regular hours', () {
    expect(
      marketQuoteLiveStatusLabel(
        MarketQuoteLiveStatus.connecting,
        null,
        nowUtc: DateTime.utc(2026, 6, 24, 7),
      ),
      'Closed',
    );
    expect(
      marketQuoteLiveStatusLabel(
        MarketQuoteLiveStatus.connecting,
        null,
        nowUtc: DateTime.utc(2026, 6, 24, 1),
      ),
      'Connecting',
    );
  });
}

Future<void> _loadPretendardFont() async {
  final regular = FontLoader('Pretendard')
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Medium.otf'))
    ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'))
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Bold.otf'));
  await regular.load();
}

class _RecordingUrlLauncher extends UrlLauncherPlatform {
  final List<String> launchedUrls = [];
  LaunchOptions? lastOptions;

  @override
  Null get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    lastOptions = options;
    return true;
  }

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchedUrls.add(url);
    return true;
  }
}

StockExchangeApp _stockExchangeTestApp({
  required MarketQuoteController marketQuoteController,
  MarketCalendarController? marketCalendarController,
  MarketIndexController? marketIndexController,
  MarketQuoteController? watchlistQuoteController,
  MarketDetailController? marketDetailController,
  MarketNewsController? marketNewsController,
  NotificationController? notificationController,
  WatchlistController? watchlistController,
  DateTime Function()? nowProvider,
}) {
  return StockExchangeApp(
    sessionController: _sessionController(),
    accountController: _accountController(),
    tradeController: _tradeController(),
    marketCalendarController:
        marketCalendarController ?? _marketCalendarController(),
    marketDetailController: marketDetailController ?? _marketDetailController(),
    marketIndexController: marketIndexController ?? _marketIndexController(),
    marketNewsController: marketNewsController ?? _marketNewsController(),
    marketQuoteController: marketQuoteController,
    watchlistQuoteController:
        watchlistQuoteController ?? _accountMarketQuoteController(),
    notificationController: notificationController ?? _notificationController(),
    watchlistController: watchlistController ?? _watchlistController(),
    nowProvider: nowProvider,
  );
}

const _testSession = AuthSession(
  username: 'hana',
  accountId: 'ACC-ABC123456789',
  tokenType: 'Bearer',
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
);

ExchangeSessionController _sessionController() {
  final store = MemoryExchangeSessionStore();
  unawaited(store.write(_testSession));
  return ExchangeSessionController(
    apiClient: ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async => http.Response('{}', 404)),
    ),
    sessionStore: store,
  );
}

AccountController _accountController() {
  return AccountController(
    apiClient: ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/v1/accounts/${_testSession.accountId}') {
          return _jsonEnvelope(_accountJson());
        }
        return http.Response('{}', 404);
      }),
      sessionProvider: () => _testSession,
    ),
  );
}

TradeController _tradeController() {
  return TradeController(
    apiClient: ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/v1/accounts/${_testSession.accountId}/portfolio') {
          return _jsonEnvelope(_portfolioJson());
        }
        if (path == '/api/v1/accounts/${_testSession.accountId}/trades') {
          if (request.method == 'GET') {
            return _jsonEnvelope({
              'accountId': _testSession.accountId,
              'tradeCount': 0,
              'trades': <Object?>[],
            });
          }
          return _jsonEnvelope({
            'orderId': 'ORD-1',
            'stockCode': '005930',
            'stockName': 'Samsung Electronics',
            'side': 'BUY',
            'quantity': 3,
            'orderType': 'LIMIT',
            'limitPriceUsd': '54.00',
            'observedPriceUsd': '54.00',
            'status': 'FILLED',
            'message': 'Filled',
            'tradeExecution': {
              'tradeId': 'TRD-1',
              'stockCode': '005930',
              'stockName': 'Samsung Electronics',
              'side': 'BUY',
              'quantity': 3,
              'executionPriceUsd': '54.00',
              'grossAmountUsd': '162.00',
              'realizedPnlUsd': '0.00',
              'remainingQuantity': 3,
              'cashBalanceUsdAfter': '49838.00',
              'tradingMode': 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
            },
          });
        }
        if (path == '/api/v1/accounts/${_testSession.accountId}/orders') {
          return _jsonEnvelope({
            'accountId': _testSession.accountId,
            'orderCount': 0,
            'orders': <Object?>[],
          });
        }
        if (path ==
            '/api/v1/accounts/${_testSession.accountId}/trades/orderability') {
          return _jsonEnvelope({
            'stockCode': request.url.queryParameters['stockCode'] ?? '005930',
            'side': request.url.queryParameters['side'] ?? 'BUY',
            'quantity':
                int.tryParse(request.url.queryParameters['quantity'] ?? '1') ??
                    1,
            'canPlaceMockOrder': true,
            'blockingReasons': <Object?>[],
            'warnings': <Object?>[],
            'orderabilitySource': 'Hana-OmniLens-API',
            'tradingMode': 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
          });
        }
        return http.Response('{}', 404);
      }),
      sessionProvider: () => _testSession,
    ),
  );
}

WatchlistController _watchlistController() {
  return WatchlistController(
    apiClient: ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/v1/accounts/${_testSession.accountId}/watchlist') {
          if (request.method == 'POST') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            return _jsonEnvelope(
              _watchlistJson(
                extraStockCode: body['stockCode'] as String?,
              ),
            );
          }
          return _jsonEnvelope(_watchlistJson());
        }
        if (path.startsWith(
          '/api/v1/accounts/${_testSession.accountId}/watchlist/',
        )) {
          return _jsonEnvelope(_watchlistJson(includeSamsung: false));
        }
        return http.Response('{}', 404);
      }),
      sessionProvider: () => _testSession,
    ),
  );
}

MarketDetailController _marketDetailController({
  bool viActive = false,
  String priceLimitState = 'NORMAL',
  List<Uri>? chartRequests,
  String stockMarketDataTime = '2026-06-18T06:00:00Z',
  String foreignOwnershipPredictionConfidenceLevel = 'TIME_SERIES_ADJUSTED',
  String foreignOwnershipPredictionConfidenceScore = '0.91',
  String foreignOwnershipPredictionModelVersion = 'test',
}) {
  return MarketDetailController(
    apiClient: ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path.startsWith('/api/v1/market/stocks/') &&
            path.endsWith('/realtime-subscription')) {
          return _jsonEnvelope({
            'stockCode': request.url.pathSegments[4],
            'subscribed': true,
          });
        }
        if (path == '/api/v1/stocks/035720' ||
            path == '/api/v1/stocks/005930') {
          final isSamsung = path.endsWith('/005930');
          return _jsonEnvelope({
            'stockCode': isSamsung ? '005930' : '035720',
            'stockName': isSamsung ? 'Samsung Electronics' : 'Kakao',
            'market': 'KOSPI',
            'sector': isSamsung ? 'Semiconductor' : 'IT',
            'baseCurrency': 'KRW',
            'displayCurrency': 'USD',
            'currentPriceKrw': isSamsung ? '82400' : '54200',
            'localCurrencyPrice': isSamsung ? '54.00' : '35.50',
            'changeRate': '+1.23%',
            'volume': isSamsung ? 18300000 : 1200000,
            'marketDataTime': stockMarketDataTime,
            'foreignOwnershipRate': '27.1',
            'foreignLimitExhaustionRate': '27.1',
            'predictedForeignOwnershipRateMin': '27.0',
            'predictedForeignOwnershipRateMax': '27.6',
            'predictedForeignLimitExhaustionRateMin': '27.0',
            'predictedForeignLimitExhaustionRateMax': '27.6',
            'foreignOwnershipPredictionConfidenceLevel':
                foreignOwnershipPredictionConfidenceLevel,
            'foreignOwnershipPredictionConfidenceScore':
                foreignOwnershipPredictionConfidenceScore,
            'foreignOwnershipPredictionModelVersion':
                foreignOwnershipPredictionModelVersion,
            'foreignOwnershipBaseDate': '2026-06-17',
            'viActive': viActive,
            'singlePriceTrading': false,
            'priceLimitState': priceLimitState,
            'tradingHalted': false,
            'orderable': true,
            'dataSource': 'Stock-exchange-BE',
            'servedAt': stockMarketDataTime,
          });
        }
        if (path.startsWith('/api/v1/market/stocks/') &&
            path.endsWith('/chart')) {
          chartRequests?.add(request.url);
          final stockCode = request.url.pathSegments[4];
          final isSamsung = stockCode == '005930';
          final interval = request.url.queryParameters['interval'] ?? '1m';
          final chartPoints = _chartPointsForInterval(
            interval: interval,
            isSamsung: isSamsung,
          );
          return _jsonEnvelope({
            'dataSource': 'Stock-exchange-BE',
            'stockCode': stockCode,
            'interval': interval,
            'from': request.url.queryParameters['from'] ?? '2026-06-01',
            'to': request.url.queryParameters['to'] ?? '2026-06-18',
            'baseCurrency': 'KRW',
            'displayCurrency': 'USD',
            'pointCount': chartPoints.length,
            'points': chartPoints,
            'servedAt': '2026-06-18T06:00:00Z',
          });
        }
        if (path.startsWith('/api/v1/market/stocks/') &&
            path.endsWith('/orderbook')) {
          return _jsonEnvelope({
            'dataSource': 'Stock-exchange-BE',
            'stockCode': request.url.pathSegments[4],
            'market': 'KOSPI',
            'baseCurrency': 'KRW',
            'displayCurrency': 'USD',
            'asks': <Object?>[],
            'bids': <Object?>[],
            'marketDataTime': stockMarketDataTime,
            'servedAt': stockMarketDataTime,
          });
        }
        if (path == '/api/v1/stocks/035720/global-peers' ||
            path == '/api/v1/stocks/005930/global-peers') {
          final isSamsung = path.contains('/005930/');
          return _jsonEnvelope({
            'stockCode': isSamsung ? '005930' : '035720',
            'stockName': isSamsung ? 'Samsung Electronics' : 'Kakao',
            'headline': isSamsung
                ? 'Samsung Electronics is the Micron of South Korea'
                : 'Kakao is the Block of South Korea',
            'summary': isSamsung
                ? 'Samsung Electronics anchors Korea memory semiconductor exports with global-scale manufacturing.'
                : 'Kakao combines messaging, commerce, payments, and financial services into a local platform ecosystem.',
            'primaryPeer': {
              'rank': 1,
              'ticker': 'SQ',
              'companyName': 'Block Inc.',
              'exchange': 'NYSE',
              'country': 'US',
              'similarityScore': '0.88',
              'businessTags': ['payments', 'platform'],
              'sector': 'Technology',
              'industry': 'Digital payments',
              'businessModel':
                  'Digital commerce and payments platform with financial service expansion.',
              'scaleBucket': 'LARGE_CAP',
              'fiscalYear': 2025,
              'marketCapUsd': '42000000000',
              'revenueUsd': '22000000000',
              'operatingIncomeUsd': '1200000000',
              'netIncomeUsd': '900000000',
              'financialDataSource': 'TEST',
              'financialSimilarityScore': '0.77',
              'matchedFactors': [
                'Sector and industry are both platform-led technology businesses.',
                'Revenue model mixes payments, commerce, and ecosystem services.',
              ],
              'rationale':
                  'Both companies anchor consumer ecosystems and expand monetization through financial services.',
            },
            'peers': [
              {
                'rank': 2,
                'ticker': 'PYPL',
                'companyName': 'PayPal Holdings Inc.',
                'exchange': 'NASDAQ',
                'country': 'US',
                'similarityScore': '0.81',
                'businessTags': ['digital payments'],
                'sector': 'Financial Technology',
                'industry': 'Payments',
                'businessModel':
                    'Global checkout and wallet network monetized by payment processing.',
                'scaleBucket': 'LARGE_CAP',
                'fiscalYear': 2025,
                'marketCapUsd': '72000000000',
                'revenueUsd': '31000000000',
                'operatingIncomeUsd': '5700000000',
                'netIncomeUsd': '4200000000',
                'financialDataSource': 'TEST',
                'financialSimilarityScore': '0.71',
                'matchedFactors': [
                  'Both companies monetize consumer payment rails and merchant services.',
                ],
                'rationale':
                    'PayPal provides a global payments benchmark for Kakao Pay-style financial services.',
              },
              {
                'rank': 3,
                'ticker': 'SHOP',
                'companyName': 'Shopify Inc.',
                'exchange': 'NYSE',
                'country': 'CA',
                'similarityScore': '0.76',
                'businessTags': ['commerce platform'],
                'sector': 'Technology',
                'industry': 'E-commerce software',
                'businessModel':
                    'Merchant operating system with payments and commerce monetization.',
                'scaleBucket': 'LARGE_CAP',
                'fiscalYear': 2025,
                'marketCapUsd': '105000000000',
                'revenueUsd': '9200000000',
                'operatingIncomeUsd': '1100000000',
                'netIncomeUsd': '850000000',
                'financialDataSource': 'TEST',
                'financialSimilarityScore': '0.69',
                'matchedFactors': [
                  'Commerce platform revenue connects merchants, payments, and ecosystem tools.',
                ],
                'rationale':
                    'Shopify gives a commerce ecosystem comparison for Kakao merchant services.',
              },
            ],
            'confidenceScore': '0.88',
            'confidenceLevel': 'HIGH',
            'modelVersion': 'test',
            'dataSource': 'Hana-OmniLens-API',
            'servedAt': '2026-06-18T06:00:00Z',
          });
        }
        return http.Response('{}', 404);
      }),
    ),
  );
}

NotificationController _notificationController() {
  return NotificationController(
    apiClient: ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/intelligence')) {
          if (request.url.path.contains('/005930/')) {
            return _jsonEnvelope(_samsungIntelligenceJson());
          }
          return _jsonEnvelope(_stockIntelligenceJson());
        }
        if (request.url.path.endsWith('/notifications/devices')) {
          return _jsonEnvelope({
            'accountId': _testSession.accountId,
            'activeCount': 0,
            'totalCount': 0,
            'devices': <Object?>[],
          });
        }
        if (request.url.path.endsWith('/notifications')) {
          return _jsonEnvelope(_notificationInboxJson());
        }
        return http.Response('{}', 404);
      }),
    ),
  );
}

MarketDetailController _loadingMarketDetailController() {
  return _LoadingMarketDetailController();
}

class _LoadingMarketDetailController extends MarketDetailController {
  _LoadingMarketDetailController()
      : super(
          apiClient: ExchangeApiClient(
            baseUri: Uri.parse('http://localhost:3000'),
            httpClient: MockClient((request) async => http.Response('{}', 404)),
          ),
        );

  @override
  Future<void> loadStock({
    required String stockCode,
    String currency = 'USD',
    String interval = '1d',
    DateTime? from,
    DateTime? to,
  }) async {
    value = const MarketDetailState.loading();
  }

  @override
  Future<void> subscribeRealtimeSource({
    required String stockCode,
    String session = 'REGULAR',
  }) async {}

  @override
  Future<void> unsubscribeRealtimeSource({
    required String stockCode,
    String session = 'REGULAR',
  }) async {}
}

MarketNewsController _marketNewsController() {
  return MarketNewsController(
    apiClient: ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/v1/market/news') {
          return _jsonEnvelope(_marketNewsJson());
        }
        if (request.url.path == '/api/v1/market/news/MKT-NEWS-001') {
          return _jsonEnvelope(_marketNewsDetailJson());
        }
        return http.Response('{}', 404);
      }),
    ),
  );
}

MarketCalendarController _marketCalendarController() {
  return MarketCalendarController(
    apiClient: ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/v1/market/calendar') {
          return _jsonEnvelope(_marketCalendarJson());
        }
        return http.Response('{}', 404);
      }),
    ),
  );
}

MarketIndexController _marketIndexController() {
  return MarketIndexController(
    apiClient: ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/v1/market/indices') {
          return _jsonEnvelope({
            'dataSource': 'Stock-exchange-BE',
            'indexCount': 3,
            'indices': [
              _indexJson('KOSPI', 'KOSPI', '2570.94', '-12.15', '-0.47'),
              _indexJson('KOSDAQ', 'KOSDAQ', '812.26', '+3.51', '+0.43'),
              _indexJson('KRX100', 'KRX 100', '5709.43', '-21.53', '-0.38'),
            ],
          });
        }
        if (request.url.path.startsWith('/api/v1/market/indices/') &&
            request.url.path.endsWith('/intraday')) {
          final code = request.url.pathSegments[4];
          return _jsonEnvelope({
            'dataSource': 'Stock-exchange-BE',
            'indexCode': code,
            'pointCount': 4,
            'points': [
              {'bucketStart': '2026-06-18T00:00:00Z', 'closeValue': 100.0},
              {'bucketStart': '2026-06-18T00:01:00Z', 'closeValue': 101.0},
              {'bucketStart': '2026-06-18T00:02:00Z', 'closeValue': 99.5},
              {'bucketStart': '2026-06-18T00:03:00Z', 'closeValue': 102.0},
            ],
          });
        }
        return http.Response('{}', 404);
      }),
    ),
  );
}

MarketQuoteController _marketQuoteController({
  List<MarketQuote> seedQuotes = seedMarketQuotes,
}) {
  return MarketQuoteController(
    seedQuotes: seedQuotes,
    apiClient: ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/v1/market/quotes') {
          return _jsonEnvelope({
            'dataSource': 'Stock-exchange-BE',
            'marketCoverage': 'KOREA',
            'displayCurrency': 'USD',
            'transport': {
              'snapshot': 'REST',
              'realtime': 'WebSocket',
            },
            'cache': {'status': 'HIT'},
            'quoteCount': seedQuotes.length,
            'quotes': seedQuotes.map(_quoteJson).toList(),
            'servedAt': '2026-06-18T06:00:00Z',
          });
        }
        if (request.url.path == '/api/v1/stocks/search') {
          final query = request.url.queryParameters['query'] ?? '';
          if (query.toLowerCase().contains('samsung')) {
            return _jsonEnvelope({
              'query': query,
              'marketFilter': 'ALL',
              'displayCurrency': 'USD',
              'resultCount': 2,
              'results': [
                {
                  'stockCode': '005930',
                  'stockName': 'Samsung Electronics',
                  'market': 'KOSPI',
                  'sector': 'Semiconductor',
                  'dataSource': 'Stock-exchange-BE',
                },
                {
                  'stockCode': '07747',
                  'stockName':
                      'CSOP Samsung Electronics Daily (2x) Leveraged Product',
                  'market': 'HKEX',
                  'sector': 'ETF',
                  'dataSource': 'Stock-exchange-BE',
                },
              ],
              'servedAt': '2026-06-18T06:00:00Z',
            });
          }
          return _jsonEnvelope({
            'query': query,
            'marketFilter': 'ALL',
            'displayCurrency': 'USD',
            'resultCount': 2,
            'results': [
              {
                'stockCode': '035720',
                'stockName': 'Kakao (카카오)',
                'market': 'KOSPI',
                'sector': 'IT',
                'dataSource': 'Stock-exchange-BE',
              },
              {
                'stockCode': '323410',
                'stockName': 'KakaoBank (카카오뱅크)',
                'market': 'KOSPI',
                'sector': 'Bank',
                'dataSource': 'Stock-exchange-BE',
              },
            ],
            'servedAt': '2026-06-18T06:00:00Z',
          });
        }
        return http.Response('{}', 404);
      }),
    ),
  );
}

List<Map<String, Object?>> _chartPointsForInterval({
  required String interval,
  required bool isSamsung,
}) {
  if (interval == '30m') {
    return [
      _chartPointJson(
        tradeDate: '2026-06-26T09:00:00',
        openPriceKrw: isSamsung ? '79200' : '52000',
        highPriceKrw: isSamsung ? '80100' : '52500',
        lowPriceKrw: isSamsung ? '78900' : '51800',
        closePriceKrw: isSamsung ? '79500' : '52000',
        openLocalCurrencyPrice: isSamsung ? '51.90' : '34.00',
        highLocalCurrencyPrice: isSamsung ? '52.49' : '34.33',
        lowLocalCurrencyPrice: isSamsung ? '51.70' : '33.87',
        closeLocalCurrencyPrice: isSamsung ? '52.10' : '34.00',
        volume: isSamsung ? 9100000 : 640000,
      ),
      _chartPointJson(
        tradeDate: '2026-07-03T15:30:00',
        openPriceKrw: isSamsung ? '81200' : '53600',
        highPriceKrw: isSamsung ? '83600' : '54800',
        lowPriceKrw: isSamsung ? '80800' : '53200',
        closePriceKrw: isSamsung ? '82400' : '54200',
        openLocalCurrencyPrice: isSamsung ? '53.21' : '35.10',
        highLocalCurrencyPrice: isSamsung ? '54.79' : '35.90',
        lowLocalCurrencyPrice: isSamsung ? '52.95' : '34.88',
        closeLocalCurrencyPrice: isSamsung ? '54.00' : '35.50',
        volume: isSamsung ? 18300000 : 1200000,
      ),
    ];
  }
  if (interval == '1d') {
    return [
      _chartPointJson(
        tradeDate: '2026-06-02',
        openPriceKrw: isSamsung ? '76000' : '45800',
        highPriceKrw: isSamsung ? '76800' : '46300',
        lowPriceKrw: isSamsung ? '75500' : '45600',
        closePriceKrw: isSamsung ? '76200' : '45800',
        openLocalCurrencyPrice: isSamsung ? '49.81' : '30.00',
        highLocalCurrencyPrice: isSamsung ? '50.34' : '30.33',
        lowLocalCurrencyPrice: isSamsung ? '49.48' : '29.87',
        closeLocalCurrencyPrice: isSamsung ? '49.94' : '30.00',
        volume: isSamsung ? 7500000 : 410000,
      ),
      _chartPointJson(
        tradeDate: '2026-07-03',
        openPriceKrw: isSamsung ? '81200' : '53600',
        highPriceKrw: isSamsung ? '83600' : '54800',
        lowPriceKrw: isSamsung ? '80800' : '53200',
        closePriceKrw: isSamsung ? '82400' : '54200',
        openLocalCurrencyPrice: isSamsung ? '53.21' : '35.10',
        highLocalCurrencyPrice: isSamsung ? '54.79' : '35.90',
        lowLocalCurrencyPrice: isSamsung ? '52.95' : '34.88',
        closeLocalCurrencyPrice: isSamsung ? '54.00' : '35.50',
        volume: isSamsung ? 18300000 : 1200000,
      ),
    ];
  }
  return [
    _chartPointJson(
      tradeDate: '2026-07-03T15:30:00',
      openPriceKrw: isSamsung ? '81200' : '53600',
      highPriceKrw: isSamsung ? '83600' : '54800',
      lowPriceKrw: isSamsung ? '80800' : '53200',
      closePriceKrw: isSamsung ? '82400' : '54200',
      openLocalCurrencyPrice: isSamsung ? '53.21' : '35.10',
      highLocalCurrencyPrice: isSamsung ? '54.79' : '35.90',
      lowLocalCurrencyPrice: isSamsung ? '52.95' : '34.88',
      closeLocalCurrencyPrice: isSamsung ? '54.00' : '35.50',
      volume: isSamsung ? 18300000 : 1200000,
    ),
  ];
}

Map<String, Object?> _chartPointJson({
  required String tradeDate,
  required String openPriceKrw,
  required String highPriceKrw,
  required String lowPriceKrw,
  required String closePriceKrw,
  required String openLocalCurrencyPrice,
  required String highLocalCurrencyPrice,
  required String lowLocalCurrencyPrice,
  required String closeLocalCurrencyPrice,
  required int volume,
}) {
  return {
    'tradeDate': tradeDate,
    'openPriceKrw': openPriceKrw,
    'highPriceKrw': highPriceKrw,
    'lowPriceKrw': lowPriceKrw,
    'closePriceKrw': closePriceKrw,
    'localCurrency': 'USD',
    'openLocalCurrencyPrice': openLocalCurrencyPrice,
    'highLocalCurrencyPrice': highLocalCurrencyPrice,
    'lowLocalCurrencyPrice': lowLocalCurrencyPrice,
    'closeLocalCurrencyPrice': closeLocalCurrencyPrice,
    'volume': volume,
    'adjusted': false,
  };
}

MarketQuoteController _accountMarketQuoteController() {
  return MarketQuoteController(
    apiClient: ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        if (request.url.path ==
            '/api/v1/accounts/${_testSession.accountId}/market/quotes/watchlist') {
          return _jsonEnvelope({
            'dataSource': 'Stock-exchange-BE',
            'marketCoverage': 'KOREA',
            'displayCurrency': 'USD',
            'transport': {
              'snapshot': 'REST',
              'realtime': 'WebSocket',
            },
            'cache': {'status': 'HIT'},
            'quoteCount': 1,
            'quotes': [
              _quoteJson(
                seedMarketQuotes.firstWhere(
                  (quote) => quote.stockCode == '005930',
                ),
              ),
            ],
            'servedAt': '2026-06-18T06:00:00Z',
          });
        }
        if (request.url.path ==
            '/api/v1/accounts/${_testSession.accountId}/market/quotes/portfolio') {
          return _jsonEnvelope({
            'dataSource': 'Stock-exchange-BE',
            'marketCoverage': 'KOREA',
            'displayCurrency': 'USD',
            'transport': {
              'snapshot': 'REST',
              'realtime': 'WebSocket',
            },
            'cache': {'status': 'HIT'},
            'quoteCount': seedMarketQuotes.length,
            'quotes': seedMarketQuotes.map(_quoteJson).toList(),
            'servedAt': '2026-06-18T06:00:00Z',
          });
        }
        return http.Response('{}', 404);
      }),
      sessionProvider: () => _testSession,
    ),
  );
}

Map<String, Object?> _indexJson(
  String indexCode,
  String indexName,
  String currentValue,
  String changeValue,
  String changeRate,
) {
  return {
    'indexCode': indexCode,
    'indexName': indexName,
    'market': 'KOREA',
    'currentValue': currentValue,
    'changeSign': changeValue.startsWith('-') ? '-' : '+',
    'changeValue': changeValue,
    'changeRate': changeRate,
    'accumulatedVolume': 1000000,
    'accumulatedTradingValue': 500000000,
    'marketDataTime': '2026-06-18T06:00:00Z',
    'source': 'TEST',
  };
}

Map<String, Object?> _quoteJson(MarketQuote quote) {
  return {
    'stockCode': quote.stockCode,
    'stockName': quote.stockName,
    'market': quote.market,
    'currentPriceKrw': quote.currentPriceKrw,
    'changeRate': quote.changeRate,
    'volume': quote.volume,
    'localCurrency': quote.localCurrency,
    'localCurrencyPrice': quote.localCurrencyPrice,
    'fxRate': quote.fxRate,
    'fxRateSource': quote.fxRateSource,
    'fxStale': quote.fxStale,
    'marketDataTime': quote.marketDataTime?.toUtc().toIso8601String(),
    'badge': quote.badge,
  };
}

MarketQuote _marketQuoteForCode(String stockCode, int index) {
  return MarketQuote(
    stockCode: stockCode,
    stockName: index == 0 ? 'Samsung Electronics' : 'Holding $index',
    market: 'KOSPI',
    currentPriceKrw: '${82000 + index * 1000}',
    changeRate: index.isEven ? '+1.23%' : '-0.38%',
    volume: 18000000 - index * 100000,
    localCurrency: 'USD',
    localCurrencyPrice: '${54 + index}.00',
    fxRate: '1525.93',
    fxRateTime: null,
    fxRateSource: 'Hana-OmniLens-API',
    fxStale: false,
    badge: 'Live',
  );
}

Map<String, Object?> _accountJson() {
  return {
    'accountId': _testSession.accountId,
    'currency': 'USD',
    'cashBalanceUsd': '50000.00',
    'lastLedgerEntryId': 'LEDGER-1',
    'updatedAt': '2026-06-18T06:00:00Z',
  };
}

Map<String, Object?> _watchlistJson({
  bool includeSamsung = true,
  String? extraStockCode,
}) {
  final items = <Map<String, Object?>>[
    if (includeSamsung)
      {
        'stockCode': '005930',
        'stockName': 'Samsung Electronics',
        'market': 'KOSPI',
        'targetingMode': 'WATCHLIST',
        'addedAt': '2026-06-18T06:00:00Z',
      },
    if (extraStockCode != null && extraStockCode != '005930')
      {
        'stockCode': extraStockCode,
        'stockName': extraStockCode == '035720' ? 'Kakao' : 'Unknown stock',
        'market': 'KOSPI',
        'targetingMode': 'WATCHLIST',
        'addedAt': '2026-06-18T06:01:00Z',
      },
  ];
  return {
    'userId': 'hana',
    'accountId': _testSession.accountId,
    'itemCount': items.length,
    'targetingMode': 'WATCHLIST',
    'items': items,
    'servedAt': '2026-06-18T06:01:00Z',
  };
}

Map<String, Object?> _portfolioJson() {
  return {
    'accountId': _testSession.accountId,
    'currency': 'USD',
    'cashBalanceUsd': '50000.00',
    'totalMarketValueUsd': '0.00',
    'totalAssetValueUsd': '50000.00',
    'realizedPnlUsd': '0.00',
    'unrealizedPnlUsd': '0.00',
    'tradingMode': 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
    'holdings': List<Object?>.generate(
      60,
      (index) => {
        'stockCode': index == 0 ? '005930' : '000${index + 100}',
        'stockName': index == 0 ? 'Samsung Electronics' : 'Holding $index',
        'quantity': 100,
        'averagePriceUsd': '50.00',
        'currentPriceUsd': '50.00',
        'marketValueUsd': '5000.00',
        'unrealizedPnlUsd': '0.00',
        'unrealizedPnlRate': '+0.00%',
      },
    ),
    'recentTrades': <Object?>[],
  };
}

Map<String, Object?> _notificationInboxJson() {
  return {
    'accountId': _testSession.accountId,
    'unreadCount': 1,
    'totalCount': 1,
    'notifications': [
      {
        'notificationId': 'LOCAL-NTF-0001',
        'eventId': 'ALERT-SAMSUNG-1',
        'subjectType': 'STOCK',
        'subjectId': '005930',
        'sourceType': 'DISCLOSURE',
        'title': 'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025',
        'summary': 'Dividend payout translated by OmniLens.',
        'originalUrl': 'https://dart.fss.or.kr/report',
        'primaryStockCode': '005930',
        'matchedStockCodes': ['005930'],
        'matchReasons': ['WATCHLIST'],
        'glossaryTerms': [
          _glossaryTerm(
            sourceTerm: 'Daejangju',
            englishTerm: 'Market Leader',
            category: 'MARKET',
            description:
                'Refers to the leading stock in a particular sector or the entire market that dictates the overall trend.',
          ),
        ],
        'translationQualityFlags': ['GLOSSARY_MATCHED'],
        'deliveryStatus': 'DELIVERED',
        'deliveryProvider': 'LOCAL_NOOP_PUSH',
        'deliveryAttemptCount': 1,
        'deliveredAt': '2026-06-18T06:00:00Z',
        'lastDeliveryError': null,
        'read': false,
        'createdAt': '2026-06-18T06:00:00Z',
        'readAt': null,
      },
    ],
    'servedAt': '2026-06-18T06:01:00Z',
  };
}

Map<String, Object?> _samsungIntelligenceJson() {
  return {
    'stockCode': '005930',
    'dataSource': 'HANA_OMNILENS_AI_ANALYZED_EVENT',
    'itemCount': 1,
    'items': [
      {
        'eventId': 'ALERT-SAMSUNG-1',
        'sourceType': 'DISCLOSURE',
        'title': 'SAMSUNG ELEC: Dividend Payout Confirmed for FY2025',
        'summary': 'Dividend payout translated by OmniLens.',
        'summaryLines': {
          'what': 'Samsung Electronics confirmed its dividend payout.',
          'why': 'Shareholder returns influence foreign investor interest.',
          'impact': 'Investors may compare the payout with large-cap peers.',
        },
        'translatedSummary': 'Dividend payout translated by OmniLens.',
        'originalContent': '삼성전자 공시 전문',
        'translatedContent':
            'SAMSUNG ELEC: Daejangju for FY2025 disclosure text.',
        'imageUrls': <Object?>[],
        'contentAvailability': 'FULL_TEXT',
        'originalUrl': 'https://dart.fss.or.kr/report',
        'primaryStockCode': '005930',
        'relatedStocks': ['005930'],
        'sentiment': 'POSITIVE',
        'importance': 'HIGH',
        'riskLevel': 'LOW',
        'clusterKey': 'samsung-disclosure',
        'glossaryTerms': [
          _glossaryTerm(
            sourceTerm: 'Daejangju',
            englishTerm: 'Market Leader',
            category: 'MARKET',
            description:
                'Refers to the leading stock in a particular sector or the entire market that dictates the overall trend.',
          ),
        ],
        'translationQualityFlags': ['GLOSSARY_MATCHED'],
        'watchlistTarget': true,
        'holderTarget': false,
        'publishedAt': '2026-06-18T05:55:00Z',
        'receivedAt': '2026-06-18T06:00:00Z',
        'targetCount': 1,
      },
    ],
    'servedAt': '2026-06-18T06:01:00Z',
  };
}

Map<String, Object?> _stockIntelligenceJson() {
  return {
    'stockCode': '035720',
    'dataSource': 'HANA_OMNILENS_AI_ANALYZED_EVENT',
    'itemCount': 2,
    'items': [
      {
        'eventId': 'NEWS-1',
        'sourceType': 'NEWS',
        'title': 'Kakao expands global content partnerships',
        'summary': '카카오는 신규 콘텐츠 제휴를 체결했다. '
            '해외 수익화 확대가 주요 배경이다. '
            '투자자는 플랫폼 성장 재평가를 확인해야 한다.',
        'summaryLines': {
          'what': '() crisis intraday Korean stock market.',
          'why': '.',
          'impact':
              '(WTI) 72.69 3% surge (-4.60%), (-3.43%) stock price, SK (-6.34%), (-10.25%) IT· ·.',
        },
        'translatedSummary':
            'Kakao signs new content distribution partnerships.',
        'originalContent': '카카오 뉴스 전문',
        'translatedContent': 'Kakao full translated news content.',
        'imageUrls': ['https://news.example.com/kakao.jpg'],
        'contentAvailability': 'FULL_TEXT',
        'originalUrl': 'https://news.example.com/kakao',
        'primaryStockCode': '035720',
        'relatedStocks': ['035720'],
        'sentiment': 'POSITIVE',
        'importance': 'HIGH',
        'riskLevel': 'LOW',
        'clusterKey': 'kakao-news',
        'glossaryTerms': <Object?>[],
        'translationQualityFlags': ['GLOSSARY_MATCHED'],
        'watchlistTarget': true,
        'holderTarget': false,
        'publishedAt': '2026-06-18T05:55:00Z',
        'receivedAt': '2026-06-18T06:00:00Z',
        'targetCount': 1,
      },
      {
        'eventId': 'DISCLOSURE-1',
        'sourceType': 'DISCLOSURE',
        'title': 'Kakao files major shareholding disclosure',
        'summary': 'Kakao published an English translated disclosure.',
        'summaryLines': {
          'what': 'Kakao filed a major shareholding disclosure.',
          'why': 'Ownership updates can affect governance expectations.',
          'impact': 'Monitor follow-up investor reaction.',
        },
        'translatedSummary':
            'Kakao published an English translated disclosure.',
        'originalContent': '카카오 공시 전문',
        'translatedContent': 'Kakao full translated disclosure content.',
        'imageUrls': <Object?>[],
        'contentAvailability': 'FULL_TEXT',
        'originalUrl': 'https://dart.fss.or.kr/report',
        'primaryStockCode': '035720',
        'relatedStocks': ['035720'],
        'sentiment': 'NEUTRAL',
        'importance': 'MEDIUM',
        'riskLevel': 'MEDIUM',
        'clusterKey': 'kakao-disclosure',
        'glossaryTerms': <Object?>[],
        'translationQualityFlags': ['DART_TRANSLATED'],
        'watchlistTarget': false,
        'holderTarget': true,
        'publishedAt': '2026-06-18T05:10:00Z',
        'receivedAt': '2026-06-18T05:20:00Z',
        'targetCount': 1,
      },
    ],
    'servedAt': '2026-06-18T06:01:00Z',
  };
}

Map<String, Object?> _glossaryTerm({
  required String sourceTerm,
  required String englishTerm,
  required String category,
  String? description,
}) {
  return {
    'sourceTerm': sourceTerm,
    'normalizedTerm': sourceTerm,
    'englishTerm': englishTerm,
    'category': category,
    if (description != null) 'description': description,
  };
}

Map<String, Object?> _marketNewsJson() {
  return {
    'newsCount': 1,
    'news': [
      {
        'newsId': 'MKT-NEWS-001',
        'query': 'Korea market',
        'title': '국내 증시 반등',
        'translatedTitle': 'Korea market rebounds as chip stocks recover',
        'summary': '시장 요약',
        'summaryLines': {
          'what': 'KOSPI rebounded on semiconductor buying.',
          'why': 'Foreign inflows returned to large-cap exporters.',
          'impact': 'Risk appetite may improve for Korean equities.',
        },
        'translatedSummary':
            'KOSPI rebounded as investors bought semiconductor exporters.',
        'originalContent': '원문 전문',
        'translatedContent': 'Full translated market news content.',
        'imageUrls': ['https://news.example.com/market.jpg'],
        'contentAvailability': 'FULL_TEXT',
        'originalUrl': 'https://news.example.com/market',
        'canonicalUrl': 'https://news.example.com/market',
        'sourceLicensePolicy': 'LINK_ONLY',
        'glossaryTerms': <Object?>[],
        'duplicateKey': 'market-news-key',
        'publishedAt': '2026-06-18T04:00:00Z',
        'createdAt': '2026-06-18T04:05:00Z',
      },
    ],
  };
}

Map<String, Object?> _marketCalendarJson() {
  return {
    'dataSource': 'KOREA_EXCHANGE_SESSION_SCHEDULE',
    'market': 'KOSPI/KOSDAQ',
    'timezone': 'Asia/Seoul',
    'currentTime': '2026-07-06T09:15:00+09:00',
    'currentDate': '2026-07-06',
    'currentStatus': 'REGULAR_SESSION',
    'eventCount': 3,
    'events': [
      {
        'eventId': 'KRX-2026-07-06-CLOSING_CALL_AUCTION',
        'title': 'Closing call auction',
        'market': 'KOSPI/KOSDAQ',
        'eventType': 'CLOSING_CALL_AUCTION',
        'scheduledAt': '2026-07-06T15:20:00+09:00',
        'timeLabel': '15:20 KST',
        'dateLabel': 'Jul 6',
        'importance': 'HIGH',
        'status': 'UPCOMING',
        'minutesUntil': 365,
      },
      {
        'eventId': 'KRX-2026-07-06-REGULAR_MARKET_CLOSE',
        'title': 'Regular market closes',
        'market': 'KOSPI/KOSDAQ',
        'eventType': 'REGULAR_MARKET_CLOSE',
        'scheduledAt': '2026-07-06T15:30:00+09:00',
        'timeLabel': '15:30 KST',
        'dateLabel': 'Jul 6',
        'importance': 'HIGH',
        'status': 'UPCOMING',
        'minutesUntil': 375,
      },
      {
        'eventId': 'KRX-2026-07-06-AFTER_HOURS_SINGLE_PRICE',
        'title': 'After-hours single-price session',
        'market': 'KOSPI/KOSDAQ',
        'eventType': 'AFTER_HOURS_SINGLE_PRICE',
        'scheduledAt': '2026-07-06T16:00:00+09:00',
        'timeLabel': '16:00 KST',
        'dateLabel': 'Jul 6',
        'importance': 'MEDIUM',
        'status': 'UPCOMING',
        'minutesUntil': 405,
      },
    ],
    'servedAt': '2026-07-06T00:15:00Z',
  };
}

Map<String, Object?> _marketNewsDetailJson() {
  return {
    ...(_marketNewsJson()['news']! as List<Object?>).first!
        as Map<String, Object?>,
    'translatedContent': 'Detailed translated market article from OmniLens.\n\n'
        'Daejangju stocks led the recovery while foreign investors '
        'returned to large-cap exporters.',
    'glossaryTerms': [
      {
        'sourceTerm': 'Daejangju',
        'normalizedTerm': '대장주',
        'englishTerm': 'Market Leader',
        'category': 'market_slang',
        'description':
            'Refers to the leading stock in a particular sector or the entire market that dictates the overall trend.',
      },
    ],
  };
}

http.Response _jsonEnvelope(Map<String, Object?> data) {
  return http.Response(
    jsonEncode({
      'success': true,
      'status': 200,
      'code': 'COMMON_000',
      'message': 'OK',
      'data': data,
      'timestamp': '2026-06-18T06:00:00Z',
    }),
    200,
    headers: const {'content-type': 'application/json'},
  );
}

http.Response _jsonErrorEnvelope({
  required int status,
  required String code,
  required String message,
}) {
  return http.Response(
    jsonEncode({
      'success': false,
      'status': status,
      'code': code,
      'message': message,
      'timestamp': '2026-06-18T06:00:00Z',
    }),
    status,
    headers: const {'content-type': 'application/json'},
  );
}

Iterable<TextSpan> _allTextSpans(InlineSpan span) sync* {
  if (span is! TextSpan) {
    return;
  }

  yield span;
  for (final child in span.children ?? const <InlineSpan>[]) {
    yield* _allTextSpans(child);
  }
}

Finder _findAssetImage(String assetName) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == assetName,
  );
}

Finder _findNetworkImage(String url) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Image &&
        widget.image is NetworkImage &&
        (widget.image as NetworkImage).url == url,
  );
}

void _expectRect(Rect actual, Rect expected, {double tolerance = 1}) {
  expect(actual.left, closeTo(expected.left, tolerance));
  expect(actual.top, closeTo(expected.top, tolerance));
  expect(actual.width, closeTo(expected.width, tolerance));
  expect(actual.height, closeTo(expected.height, tolerance));
}
