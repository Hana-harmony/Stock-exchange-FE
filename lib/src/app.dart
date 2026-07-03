import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/account_controller.dart';
import 'core/exchange_api_client.dart';
import 'core/exchange_session_controller.dart';
import 'core/market_detail_controller.dart';
import 'core/market_index_controller.dart';
import 'core/market_news_controller.dart';
import 'core/market_quote_controller.dart';
import 'core/market_quote_live_client.dart';
import 'core/notification_controller.dart';
import 'core/secure_exchange_session_store.dart';
import 'core/tax_controller.dart';
import 'core/trade_controller.dart';
import 'core/watchlist_controller.dart';
import 'ui/components/app_bottom_navigation.dart';
import 'ui/components/app_header.dart';
import 'ui/components/app_scaffold.dart';
import 'ui/screens/exchange_pages.dart';
import 'ui/theme/app_theme.dart';

export 'ui/screens/exchange_pages.dart'
    show MarketScreen, StockDetailScreen, marketQuoteLiveStatusLabel;

class StockExchangeApp extends StatelessWidget {
  const StockExchangeApp({
    super.key,
    this.sessionController,
    this.accountController,
    this.tradeController,
    this.marketDetailController,
    this.marketIndexController,
    this.marketNewsController,
    this.marketQuoteController,
    this.watchlistQuoteController,
    this.portfolioQuoteController,
    this.notificationController,
    this.taxController,
    this.watchlistController,
    this.sessionStore,
    this.nowProvider,
  });

  final ExchangeSessionController? sessionController;
  final AccountController? accountController;
  final TradeController? tradeController;
  final MarketDetailController? marketDetailController;
  final MarketIndexController? marketIndexController;
  final MarketNewsController? marketNewsController;
  final MarketQuoteController? marketQuoteController;
  final MarketQuoteController? watchlistQuoteController;
  final MarketQuoteController? portfolioQuoteController;
  final NotificationController? notificationController;
  final TaxController? taxController;
  final WatchlistController? watchlistController;
  final ExchangeSessionStore? sessionStore;
  final DateTime Function()? nowProvider;

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
        marketNewsController: marketNewsController,
        marketQuoteController: marketQuoteController,
        watchlistQuoteController: watchlistQuoteController,
        portfolioQuoteController: portfolioQuoteController,
        notificationController: notificationController,
        taxController: taxController,
        watchlistController: watchlistController,
        sessionStore: sessionStore,
        nowProvider: nowProvider,
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
    this.marketNewsController,
    this.marketQuoteController,
    this.watchlistQuoteController,
    this.portfolioQuoteController,
    this.notificationController,
    this.taxController,
    this.watchlistController,
    this.sessionStore,
    this.nowProvider,
  });

  final ExchangeSessionController? sessionController;
  final AccountController? accountController;
  final TradeController? tradeController;
  final MarketDetailController? marketDetailController;
  final MarketIndexController? marketIndexController;
  final MarketNewsController? marketNewsController;
  final MarketQuoteController? marketQuoteController;
  final MarketQuoteController? watchlistQuoteController;
  final MarketQuoteController? portfolioQuoteController;
  final NotificationController? notificationController;
  final TaxController? taxController;
  final WatchlistController? watchlistController;
  final ExchangeSessionStore? sessionStore;
  final DateTime Function()? nowProvider;

  @override
  State<ExchangeShell> createState() => _ExchangeShellState();
}

class _ExchangeShellState extends State<ExchangeShell> {
  static const _initialRecentSearches = <String>[];

  int _selectedIndex = 1;
  http.Client? _ownedHttpClient;
  late final ExchangeEnvironment _environment;
  late final ExchangeApiClient _apiClient;
  late final ExchangeSessionController _sessionController;
  late final AccountController _accountController;
  late final TradeController _tradeController;
  late final MarketDetailController _marketDetailController;
  late final MarketIndexController _marketIndexController;
  late final MarketNewsController _marketNewsController;
  late final MarketQuoteController _marketQuoteController;
  late final MarketQuoteController _watchlistQuoteController;
  late final MarketQuoteController _portfolioQuoteController;
  late final NotificationController _notificationController;
  late final TaxController _taxController;
  late final WatchlistController _watchlistController;
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
    _marketNewsController =
        widget.marketNewsController ?? _createMarketNewsController();
    _marketQuoteController =
        widget.marketQuoteController ?? _createMarketQuoteController();
    _watchlistQuoteController =
        widget.watchlistQuoteController ?? _createAccountQuoteController();
    _portfolioQuoteController =
        widget.portfolioQuoteController ?? _createAccountQuoteController();
    _notificationController =
        widget.notificationController ?? _createNotificationController();
    _taxController = widget.taxController ?? _createTaxController();
    _watchlistController =
        widget.watchlistController ?? _createWatchlistController();
    _notificationController.addListener(_handleNotificationStateChanged);
    _watchlistController.addListener(_handleWatchlistStateChanged);
    _sessionController.addListener(_handleSessionStateChanged);
    _sessionController.restore();
  }

  void _handleNotificationStateChanged() {
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
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

  MarketNewsController _createMarketNewsController() {
    return MarketNewsController(apiClient: _apiClient);
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

  WatchlistController _createWatchlistController() {
    return WatchlistController(apiClient: _apiClient);
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
    if (widget.marketNewsController == null) {
      _marketNewsController.dispose();
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
    _notificationController.removeListener(_handleNotificationStateChanged);
    if (widget.notificationController == null) {
      _notificationController.dispose();
    }
    _watchlistController.removeListener(_handleWatchlistStateChanged);
    _sessionController.removeListener(_handleSessionStateChanged);
    if (widget.watchlistController == null) {
      _watchlistController.dispose();
    }
    if (widget.taxController == null) {
      _taxController.dispose();
    }
    _ownedHttpClient?.close();
    super.dispose();
  }

  String get _selectedNavigationTitle =>
      appShellNavigationItems[_selectedIndex].label;

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

  void _handleSessionStateChanged() {
    final session = _sessionController.session;
    if (session == null) {
      if (mounted) {
        setState(() {
          _favoriteStockCodes.clear();
        });
      } else {
        _favoriteStockCodes.clear();
      }
      _accountController.clear();
      _tradeController.clear();
      _watchlistController.clear();
      return;
    }
    unawaited(_accountController.loadAccount(session.accountId));
    unawaited(_tradeController.loadPortfolio(session.accountId));
    unawaited(_watchlistController.load(session.accountId));
    unawaited(_notificationController.loadAlerts(accountId: session.accountId));
  }

  void _handleWatchlistStateChanged() {
    if (!mounted) {
      return;
    }
    final codes = _watchlistController.value.stockCodes;
    setState(() {
      _favoriteStockCodes
        ..clear()
        ..addAll(codes);
    });
  }

  Future<bool> _setFavoriteStock(String stockCode, bool nextIsFavorite) async {
    final session = _sessionController.session;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in before changing watchlist.')),
      );
      return false;
    }

    final wasFavorite = _favoriteStockCodes.contains(stockCode);
    setState(() {
      if (nextIsFavorite) {
        _favoriteStockCodes.add(stockCode);
      } else {
        _favoriteStockCodes.remove(stockCode);
      }
    });

    if (nextIsFavorite) {
      await _watchlistController.add(
        accountId: session.accountId,
        stockCode: stockCode,
      );
    } else {
      await _watchlistController.remove(
        accountId: session.accountId,
        stockCode: stockCode,
      );
    }

    final errorMessage = _watchlistController.value.errorMessage;
    if (errorMessage != null) {
      setState(() {
        if (wasFavorite) {
          _favoriteStockCodes.add(stockCode);
        } else {
          _favoriteStockCodes.remove(stockCode);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
      return false;
    }

    unawaited(
      _watchlistQuoteController.loadWatchlistSnapshot(
        accountId: session.accountId,
      ),
    );
    return true;
  }

  void _toggleFavoriteStock(String stockCode) {
    final nextIsFavorite = !_favoriteStockCodes.contains(stockCode);
    unawaited(_setFavoriteStock(stockCode, nextIsFavorite));
  }

  Future<void> _showNotificationPlaceholder() {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Material(
            color: Colors.transparent,
            child: NotificationInboxScreen(
              notificationController: _notificationController,
              accountId: _sessionController.session?.accountId,
              selectedNavigationIndex: _selectedIndex,
              onClose: () => Navigator.of(context).pop(),
              onNavigationSelected: (index) {
                Navigator.of(context).pop();
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showAiPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI assistant entry is not included in this page scope.'),
      ),
    );
  }

  void _openAccountsTabFromNestedFlow() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() {
      _selectedIndex = 2;
    });
  }

  void _openMyTabFromNestedFlow() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() {
      _selectedIndex = 4;
    });
  }

  Future<void> _openSearch() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SearchLandingScreen(
          sessionController: _sessionController,
          tradeController: _tradeController,
          marketDetailController: _marketDetailController,
          marketQuoteController: _marketQuoteController,
          marketNewsController: _marketNewsController,
          notificationController: _notificationController,
          recentSearches: _recentSearches,
          favoriteStockCodes: _favoriteStockCodes,
          onSearchCommitted: _rememberSearchQuery,
          onRemoveRecentSearch: _removeRecentSearch,
          onClearRecentSearches: _clearRecentSearches,
          onToggleFavoriteStock: _toggleFavoriteStock,
          onFavoriteChanged: _setFavoriteStock,
          onNavigateToAccounts: _openAccountsTabFromNestedFlow,
          nowProvider: widget.nowProvider,
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildHeader() {
    if (_selectedIndex == 2) {
      return null;
    }

    return AppHeader(
      title: _selectedNavigationTitle,
      showBrandMark: true,
      showDefaultActions: true,
      onAiTap: _showAiPlaceholder,
      onSearchTap: _openSearch,
      onNotificationTap: _showNotificationPlaceholder,
      hasUnreadNotifications:
          _notificationController.value.hasUnreadNotifications,
    );
  }

  Widget _buildIndexedBody() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        WatchlistScreen(
          sessionController: _sessionController,
          watchlistController: _watchlistController,
          marketDetailController: _marketDetailController,
          marketQuoteController: _watchlistQuoteController,
          tradeController: _tradeController,
          notificationController: _notificationController,
          onFavoriteChanged: _setFavoriteStock,
          onNavigateToAccounts: _openAccountsTabFromNestedFlow,
          onSignInTap: _openMyTabFromNestedFlow,
          nowProvider: widget.nowProvider,
        ),
        MarketScreen(
          sessionController: _sessionController,
          tradeController: _tradeController,
          marketDetailController: _marketDetailController,
          marketIndexController: _marketIndexController,
          marketQuoteController: _marketQuoteController,
          notificationController: _notificationController,
          favoriteStockCodes: _favoriteStockCodes,
          onFavoriteChanged: _setFavoriteStock,
          onNavigateToAccounts: _openAccountsTabFromNestedFlow,
          nowProvider: widget.nowProvider,
        ),
        AccountsScreen(
          sessionController: _sessionController,
          accountController: _accountController,
          tradeController: _tradeController,
          onSignInTap: _openMyTabFromNestedFlow,
        ),
        MarketNewsScreen(
          marketNewsController: _marketNewsController,
        ),
        MyScreen(
          sessionController: _sessionController,
          accountController: _accountController,
          tradeController: _tradeController,
          watchlistController: _watchlistController,
          onSignedOut: () {
            setState(() {
              _selectedIndex = 1;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: _buildHeader(),
      bodySafeAreaBottom: false,
      extendBody: _selectedIndex == 2,
      body: _buildIndexedBody(),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: appShellNavigationItems,
      ),
    );
  }
}
