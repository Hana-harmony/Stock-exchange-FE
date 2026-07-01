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
    expect(find.byKey(const ValueKey('accounts-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('accounts-page-title')), findsOneWidget);
    expect(find.text('Total Assets'), findsOneWidget);
    expect(find.text(r'$5,0000.000'), findsOneWidget);
    expect(find.text('-10,000,000(-14.48%)'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('640-0200-0000-0 [ISA(Brokerage)]'), findsOneWidget);

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
        matching: find.text('카카오'),
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
      tester
          .getRect(find.byKey(const ValueKey('accounts-holdings-filter-row'))),
      const Rect.fromLTWH(0, 402, 402, 56),
    );
    _expectRect(
      tester
          .getRect(find.byKey(const ValueKey('accounts-market-scope-segment'))),
      const Rect.fromLTWH(269, 412, 121, 36),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('accounts-table-header'))),
      const Rect.fromLTWH(0, 458, 402, 48),
    );
    _expectRect(
      tester.getRect(find.byKey(const ValueKey('accounts-holding-row-0'))),
      const Rect.fromLTWH(0, 506, 402, 62),
    );

    final totalPositions = tester.widget<RichText>(
      find.byKey(const ValueKey('accounts-total-positions')),
    );
    expect(totalPositions.text.toPlainText(), 'Total 60 Positions');
    expect(find.text(r'$5,0000.000'), findsOneWidget);
    expect(find.text('-10,000,000(-14.48%)'), findsOneWidget);
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

void _expectRect(Rect actual, Rect expected, {double tolerance = 1}) {
  expect(actual.left, closeTo(expected.left, tolerance));
  expect(actual.top, closeTo(expected.top, tolerance));
  expect(actual.width, closeTo(expected.width, tolerance));
  expect(actual.height, closeTo(expected.height, tolerance));
}
