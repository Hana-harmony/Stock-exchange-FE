import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_exchange_fe/src/app.dart';
import 'package:stock_exchange_fe/src/core/exchange_api_client.dart';
import 'package:stock_exchange_fe/src/core/market_quote_controller.dart';
import 'package:stock_exchange_fe/src/ui/assets/app_assets.dart';
import 'package:stock_exchange_fe/src/ui/theme/app_tokens.dart';

void main() {
  testWidgets('renders markets landing page and navigates bottom tabs',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final marketQuoteController = _marketQuoteController();
    addTearDown(marketQuoteController.dispose);

    await tester.pumpWidget(
      _stockExchangeTestApp(marketQuoteController: marketQuoteController),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Markets'), findsOneWidget);
    expect(find.bySemanticsLabel('AI Assistant'), findsOneWidget);
    expect(find.bySemanticsLabel('Search'), findsOneWidget);
    expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
    expect(find.text('Trending Stocks'), findsOneWidget);
    expect(find.text('NVDA'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-Accounts')));
    await tester.pumpAndSettle();
    expect(find.text('Accounts tab'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Accounts'), findsOneWidget);
    expect(find.bySemanticsLabel('AI Assistant'), findsOneWidget);
    expect(find.bySemanticsLabel('Search'), findsOneWidget);
    expect(find.bySemanticsLabel('Notifications'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-WatchLists')));
    await tester.pumpAndSettle();
    expect(find.text('WatchLists tab'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'WatchLists'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-MY')));
    await tester.pumpAndSettle();
    expect(find.text('MY tab'), findsOneWidget);
    expect(find.text('알림보내기'), findsOneWidget);

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

    expect(notificationAsset().assetName, AppAssets.headerNotifications);

    await tester.tap(find.text('알림보내기'));
    await tester.pumpAndSettle();
    expect(notificationAsset().assetName, AppAssets.headerNotificationsNew);

    await tester.tap(find.bySemanticsLabel('Notifications'));
    await tester.pumpAndSettle();
    expect(notificationAsset().assetName, AppAssets.headerNotifications);
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
    expect(find.text('카카오뱅크'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stock-search-result-035720')));
    await tester.pumpAndSettle();

    expect(find.textContaining('카카오'), findsWidgets);
    expect(find.textContaining('035720'), findsOneWidget);
    expect(find.text('Order'), findsWidgets);
    expect(find.text('K-News'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stock-detail-tab-chart')));
    await tester.pumpAndSettle();
    expect(find.byKey(const PageStorageKey<String>('stock-chart-tab')),
        findsOneWidget);
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

    await tester.tap(find.byKey(const ValueKey('stock-news-layout-grid')));
    await tester.pumpAndSettle();

    expect(find.byKey(const PageStorageKey<String>('stock-k-news-tab')),
        findsOneWidget);
    expect(find.text('Card'), findsOneWidget);
  });

  testWidgets('shows temporary VI trigger button in fundamentals tab',
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

    await tester
        .tap(find.byKey(const ValueKey('stock-detail-tab-fundamentals')));
    await tester.pumpAndSettle();

    expect(find.byKey(const PageStorageKey<String>('stock-fundamentals-tab')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('stock-fundamentals-trigger-vi')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('stock-fundamentals-trigger-low-limit')),
        findsOneWidget);
    expect(find.text('VI발동 시키기'), findsOneWidget);
    expect(find.text('Low limit 발동 시키기'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('stock-fundamentals-trigger-vi')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('vi-triggered-banner')), findsOneWidget);
    expect(find.text('VI triggered!'), findsOneWidget);
    expect(find.text('Trading may be temporarily halted.'), findsOneWidget);
    expect(find.text('VI발동 끄기'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('vi-triggered-banner-info')));
    await tester.pumpAndSettle();

    expect(find.text('확인'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('stock-fundamentals-trigger-vi')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('vi-triggered-banner')), findsNothing);
    expect(find.text('VI발동 시키기'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('stock-fundamentals-trigger-low-limit')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('low-limit-reached-banner')),
      findsOneWidget,
    );
    expect(find.text('Lower limit reached!'), findsOneWidget);
    expect(
      find.text('Trading is limited at the daily price cap.'),
      findsOneWidget,
    );
    expect(find.text('Low limit 발동 끄기'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('low-limit-reached-banner-info')),
    );
    await tester.pumpAndSettle();

    expect(find.text('확인'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('stock-fundamentals-trigger-low-limit')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('low-limit-reached-banner')),
      findsNothing,
    );
    expect(find.text('Low limit 발동 시키기'), findsOneWidget);
  });

  testWidgets('blocks sell with VI warning modal when VI is triggered',
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

    await tester
        .tap(find.byKey(const ValueKey('stock-detail-tab-fundamentals')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('stock-fundamentals-trigger-vi')),
    );
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

    await tester
        .tap(find.byKey(const ValueKey('stock-detail-tab-fundamentals')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('stock-fundamentals-trigger-low-limit')),
    );
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

  testWidgets('shows samsung dummy results with orange query highlight',
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

StockExchangeApp _stockExchangeTestApp({
  required MarketQuoteController marketQuoteController,
}) {
  return StockExchangeApp(marketQuoteController: marketQuoteController);
}

MarketQuoteController _marketQuoteController() {
  return MarketQuoteController(
    seedQuotes: seedMarketQuotes,
    apiClient: ExchangeApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/v1/stocks/search') {
          expect(request.url.queryParameters['query'], '카카오');
          return _jsonEnvelope({
            'query': '카카오',
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

Iterable<TextSpan> _allTextSpans(InlineSpan span) sync* {
  if (span is! TextSpan) {
    return;
  }

  yield span;
  for (final child in span.children ?? const <InlineSpan>[]) {
    yield* _allTextSpans(child);
  }
}
