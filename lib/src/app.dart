import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/account_controller.dart';
import 'core/exchange_api_client.dart';
import 'core/exchange_session_controller.dart';
import 'core/market_detail_controller.dart';
import 'core/market_index_controller.dart';
import 'core/market_quote_controller.dart';
import 'core/market_quote_live_client.dart';
import 'core/notification_controller.dart';
import 'core/secure_exchange_session_store.dart';
import 'core/tax_controller.dart';
import 'core/trade_controller.dart';
import 'ui/components/app_bottom_navigation.dart';
import 'ui/components/app_header.dart';
import 'ui/components/app_scaffold.dart';
import 'ui/screens/exchange_pages.dart';
import 'ui/theme/app_theme.dart';

export 'ui/screens/exchange_pages.dart'
    show MarketScreen, StockDetailScreen, marketQuoteLiveStatusLabel;

const _shellNavigationItems = <AppBottomNavigationItem>[
  AppBottomNavigationItem(
    label: 'WatchLists',
    defaultIconAsset: 'assets/icons/bottom_nav/watchlists_default.png',
    selectedIconAsset: 'assets/icons/bottom_nav/watchlists_selected.png',
  ),
  AppBottomNavigationItem(
    label: 'Markets',
    defaultIconAsset: 'assets/icons/bottom_nav/markets_default.png',
    selectedIconAsset: 'assets/icons/bottom_nav/markets_selected.png',
  ),
  AppBottomNavigationItem(
    label: 'Accounts',
    defaultIconAsset: 'assets/icons/bottom_nav/accounts_default.png',
    selectedIconAsset: 'assets/icons/bottom_nav/accounts_selected.png',
  ),
  AppBottomNavigationItem(
    label: 'Discover',
    defaultIconAsset: 'assets/icons/bottom_nav/discover_default.png',
    selectedIconAsset: 'assets/icons/bottom_nav/discover_selected.png',
  ),
  AppBottomNavigationItem(
    label: 'MY',
    defaultIconAsset: 'assets/icons/bottom_nav/my_default.png',
    selectedIconAsset: 'assets/icons/bottom_nav/my_selected.png',
  ),
];

class StockExchangeApp extends StatelessWidget {
  const StockExchangeApp({
    super.key,
    this.sessionController,
    this.accountController,
    this.tradeController,
    this.marketDetailController,
    this.marketIndexController,
    this.marketQuoteController,
    this.watchlistQuoteController,
    this.portfolioQuoteController,
    this.notificationController,
    this.taxController,
    this.sessionStore,
  });

  final ExchangeSessionController? sessionController;
  final AccountController? accountController;
  final TradeController? tradeController;
  final MarketDetailController? marketDetailController;
  final MarketIndexController? marketIndexController;
  final MarketQuoteController? marketQuoteController;
  final MarketQuoteController? watchlistQuoteController;
  final MarketQuoteController? portfolioQuoteController;
  final NotificationController? notificationController;
  final TaxController? taxController;
  final ExchangeSessionStore? sessionStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hana Local Exchange',
      theme: buildAppTheme(),
      home: ExchangeShell(
        sessionController: sessionController,
        accountController: accountController,
        tradeController: tradeController,
        marketDetailController: marketDetailController,
        marketIndexController: marketIndexController,
        marketQuoteController: marketQuoteController,
        watchlistQuoteController: watchlistQuoteController,
        portfolioQuoteController: portfolioQuoteController,
        notificationController: notificationController,
        taxController: taxController,
        sessionStore: sessionStore,
      ),
    );
  }
}

class ExchangeShell extends StatefulWidget {
  const ExchangeShell({
    super.key,
    this.sessionController,
    this.accountController,
    this.tradeController,
    this.marketDetailController,
    this.marketIndexController,
    this.marketQuoteController,
    this.watchlistQuoteController,
    this.portfolioQuoteController,
    this.notificationController,
    this.taxController,
    this.sessionStore,
  });

  final ExchangeSessionController? sessionController;
  final AccountController? accountController;
  final TradeController? tradeController;
  final MarketDetailController? marketDetailController;
  final MarketIndexController? marketIndexController;
  final MarketQuoteController? marketQuoteController;
  final MarketQuoteController? watchlistQuoteController;
  final MarketQuoteController? portfolioQuoteController;
  final NotificationController? notificationController;
  final TaxController? taxController;
  final ExchangeSessionStore? sessionStore;

  @override
  State<ExchangeShell> createState() => _ExchangeShellState();
}

class _ExchangeShellState extends State<ExchangeShell> {
  static const _initialRecentSearches = <String>[
    '삼성전자',
    '카카오',
    'NAVER',
  ];

  int _selectedIndex = 1;
  http.Client? _ownedHttpClient;
  late final ExchangeEnvironment _environment;
  late final ExchangeApiClient _apiClient;
  late final ExchangeSessionController _sessionController;
  late final AccountController _accountController;
  late final TradeController _tradeController;
  late final MarketDetailController _marketDetailController;
  late final MarketIndexController _marketIndexController;
  late final MarketQuoteController _marketQuoteController;
  late final MarketQuoteController _watchlistQuoteController;
  late final MarketQuoteController _portfolioQuoteController;
  late final NotificationController _notificationController;
  late final TaxController _taxController;
  List<String> _recentSearches = List<String>.from(_initialRecentSearches);
  final Set<String> _favoriteStockCodes = <String>{};

  @override
  void initState() {
    super.initState();
    _environment = const ExchangeEnvironment();
    _apiClient = _createApiClient();
    _sessionController = widget.sessionController ?? _createSessionController();
    _accountController = widget.accountController ?? _createAccountController();
    _tradeController = widget.tradeController ?? _createTradeController();
    _marketDetailController =
        widget.marketDetailController ?? _createMarketDetailController();
    _marketIndexController =
        widget.marketIndexController ?? _createMarketIndexController();
    _marketQuoteController =
        widget.marketQuoteController ?? _createMarketQuoteController();
    _watchlistQuoteController =
        widget.watchlistQuoteController ?? _createAccountQuoteController();
    _portfolioQuoteController =
        widget.portfolioQuoteController ?? _createAccountQuoteController();
    _notificationController =
        widget.notificationController ?? _createNotificationController();
    _taxController = widget.taxController ?? _createTaxController();
    _sessionController.restore();
  }

  ExchangeApiClient _createApiClient() {
    _ownedHttpClient = http.Client();
    return ExchangeApiClient(
      baseUri: _environment.apiBaseUri,
      httpClient: _ownedHttpClient!,
      sessionProvider: () => _sessionController.session,
    );
  }

  ExchangeSessionController _createSessionController() {
    return ExchangeSessionController(
      apiClient: _apiClient,
      sessionStore: widget.sessionStore ?? SecureExchangeSessionStore(),
    );
  }

  AccountController _createAccountController() {
    return AccountController(apiClient: _apiClient);
  }

  TradeController _createTradeController() {
    return TradeController(apiClient: _apiClient);
  }

  MarketDetailController _createMarketDetailController() {
    return MarketDetailController(apiClient: _apiClient);
  }

  MarketIndexController _createMarketIndexController() {
    return MarketIndexController(
      apiClient: _apiClient,
      liveClient: MarketIndexLiveClient(baseUri: _environment.apiBaseUri),
    );
  }

  MarketQuoteController _createMarketQuoteController() {
    return MarketQuoteController(
      apiClient: _apiClient,
      liveClient: MarketQuoteLiveClient(baseUri: _environment.apiBaseUri),
    );
  }

  MarketQuoteController _createAccountQuoteController() {
    return MarketQuoteController(
      apiClient: _apiClient,
      liveClient: MarketQuoteLiveClient(baseUri: _environment.apiBaseUri),
    );
  }

  TaxController _createTaxController() {
    return TaxController(apiClient: _apiClient);
  }

  NotificationController _createNotificationController() {
    return NotificationController(apiClient: _apiClient);
  }

  @override
  void dispose() {
    if (widget.sessionController == null) {
      _sessionController.dispose();
    }
    if (widget.accountController == null) {
      _accountController.dispose();
    }
    if (widget.tradeController == null) {
      _tradeController.dispose();
    }
    if (widget.marketDetailController == null) {
      _marketDetailController.dispose();
    }
    if (widget.marketIndexController == null) {
      _marketIndexController.dispose();
    }
    if (widget.marketQuoteController == null) {
      _marketQuoteController.dispose();
    }
    if (widget.watchlistQuoteController == null) {
      _watchlistQuoteController.dispose();
    }
    if (widget.portfolioQuoteController == null) {
      _portfolioQuoteController.dispose();
    }
    if (widget.notificationController == null) {
      _notificationController.dispose();
    }
    if (widget.taxController == null) {
      _taxController.dispose();
    }
    _ownedHttpClient?.close();
    super.dispose();
  }

  String get _selectedNavigationTitle =>
      _shellNavigationItems[_selectedIndex].label;

  void _rememberSearchQuery(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return;
    }
    setState(() {
      _recentSearches = [
        normalized,
        ..._recentSearches.where((item) => item != normalized),
      ].take(6).toList(growable: false);
    });
  }

  void _removeRecentSearch(String query) {
    setState(() {
      _recentSearches = _recentSearches
          .where((item) => item != query)
          .toList(growable: false);
    });
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches = <String>[];
    });
  }

  void _toggleFavoriteStock(String stockCode) {
    setState(() {
      if (_favoriteStockCodes.contains(stockCode)) {
        _favoriteStockCodes.remove(stockCode);
      } else {
        _favoriteStockCodes.add(stockCode);
      }
    });
  }

  void _showNotificationPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications view is not included in this page scope.'),
      ),
    );
  }

  Future<void> _openSearch() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SearchLandingScreen(
          sessionController: _sessionController,
          tradeController: _tradeController,
          marketDetailController: _marketDetailController,
          marketQuoteController: _marketQuoteController,
          recentSearches: _recentSearches,
          favoriteStockCodes: _favoriteStockCodes,
          onSearchCommitted: _rememberSearchQuery,
          onRemoveRecentSearch: _removeRecentSearch,
          onClearRecentSearches: _clearRecentSearches,
          onToggleFavoriteStock: _toggleFavoriteStock,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader() {
    if (_selectedIndex == 1) {
      return AppHeader(
        title: 'Markets',
        showBrandMark: true,
        showDefaultActions: true,
        onSearchTap: _openSearch,
        onNotificationTap: _showNotificationPlaceholder,
      );
    }

    return AppHeader(title: _selectedNavigationTitle);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: _buildHeader(),
      bodySafeAreaBottom: false,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const ShellPlaceholderScreen(
            title: 'WatchLists',
            description:
                'This tab is intentionally left as a placeholder while the Markets flow is implemented.',
          ),
          MarketScreen(
            sessionController: _sessionController,
            tradeController: _tradeController,
            marketDetailController: _marketDetailController,
            marketIndexController: _marketIndexController,
            marketQuoteController: _marketQuoteController,
          ),
          const ShellPlaceholderScreen(
            title: 'Accounts',
            description:
                'The account summary flow is outside the current page specification.',
          ),
          const ShellPlaceholderScreen(
            title: 'Discover',
            description:
                'Discover remains a placeholder until its dedicated page specification is provided.',
          ),
          const ShellPlaceholderScreen(
            title: 'MY',
            description:
                'MY remains a placeholder until the account and settings pages are specified.',
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: _shellNavigationItems,
      ),
    );
  }
}
