import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/account_controller.dart';
import 'core/exchange_api_client.dart';
import 'core/exchange_session_controller.dart';
import 'core/market_detail_controller.dart';
import 'core/market_quote_controller.dart';
import 'core/market_quote_live_client.dart';
import 'core/notification_controller.dart';
import 'core/secure_exchange_session_store.dart';
import 'core/tax_controller.dart';
import 'core/trade_controller.dart';

class StockExchangeApp extends StatelessWidget {
  const StockExchangeApp({
    super.key,
    this.sessionController,
    this.accountController,
    this.tradeController,
    this.marketDetailController,
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        scaffoldBackgroundColor: const Color(0xFFF7FAFC),
        useMaterial3: true,
      ),
      home: ExchangeShell(
        sessionController: sessionController,
        accountController: accountController,
        tradeController: tradeController,
        marketDetailController: marketDetailController,
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
  int _selectedIndex = 0;
  http.Client? _ownedHttpClient;
  late final ExchangeEnvironment _environment;
  late final ExchangeApiClient _apiClient;
  late final ExchangeSessionController _sessionController;
  late final AccountController _accountController;
  late final TradeController _tradeController;
  late final MarketDetailController _marketDetailController;
  late final MarketQuoteController _marketQuoteController;
  late final MarketQuoteController _watchlistQuoteController;
  late final MarketQuoteController _portfolioQuoteController;
  late final NotificationController _notificationController;
  late final TaxController _taxController;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hana X'),
        actions: [
          _SessionAction(sessionController: _sessionController),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _WalletBadge(accountController: _accountController),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            MarketScreen(
              sessionController: _sessionController,
              tradeController: _tradeController,
              marketDetailController: _marketDetailController,
              marketQuoteController: _marketQuoteController,
            ),
            PortfolioScreen(
              sessionController: _sessionController,
              accountController: _accountController,
              tradeController: _tradeController,
              watchlistQuoteController: _watchlistQuoteController,
              portfolioQuoteController: _portfolioQuoteController,
            ),
            OrdersScreen(
              sessionController: _sessionController,
              tradeController: _tradeController,
            ),
            AlertsScreen(
              sessionController: _sessionController,
              notificationController: _notificationController,
            ),
            TaxScreen(
              sessionController: _sessionController,
              taxController: _taxController,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Market',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Tax',
          ),
        ],
      ),
    );
  }
}

class MarketScreen extends StatefulWidget {
  const MarketScreen({
    super.key,
    required this.sessionController,
    required this.tradeController,
    required this.marketDetailController,
    required this.marketQuoteController,
  });

  final ExchangeSessionController sessionController;
  final TradeController tradeController;
  final MarketDetailController marketDetailController;
  final MarketQuoteController marketQuoteController;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  static const List<String> _homePopularStockCodes = [
    '005930',
    '000660',
    '035720',
    '035420',
    '005380',
    '000270',
    '068270',
    '105560',
    '055550',
    '086790',
  ];

  String _selectedMarket = 'ALL';
  String _searchQuery = '';
  Timer? _searchDebounceTimer;
  bool _isSearchingStocks = false;
  List<StockSearchItem> _stockSearchResults = const [];
  String? _stockSearchError;

  String? get _marketQuery => _selectedMarket == 'ALL' ? null : _selectedMarket;

  @override
  void initState() {
    super.initState();
    final quoteState = widget.marketQuoteController.value;
    if (quoteState.status == MarketQuoteStatus.idle &&
        quoteState.quotes.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadHomeSnapshot();
        }
      });
    }
    if (widget.marketQuoteController.canSubscribeLive &&
        quoteState.liveStatus == MarketQuoteLiveStatus.disconnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _subscribeHomeLive();
        }
      });
    }
  }

  void _loadHomeSnapshot() {
    widget.marketQuoteController.loadSnapshot(
      market: _marketQuery,
      stockCodes: _homePopularStockCodes,
    );
  }

  void _subscribeHomeLive() {
    if (!widget.marketQuoteController.canSubscribeLive) {
      return;
    }
    widget.marketQuoteController.subscribeLive(
      market: _marketQuery,
      stockCodes: _homePopularStockCodes,
    );
  }

  void _selectMarket(String market) {
    if (_selectedMarket == market) {
      return;
    }
    setState(() {
      _selectedMarket = market;
    });
    _loadHomeSnapshot();
    _subscribeHomeLive();
  }

  void _searchStocks(String query) {
    _searchDebounceTimer?.cancel();
    final normalized = query.trim();
    setState(() {
      _searchQuery = normalized;
      _stockSearchError = null;
      if (normalized.isEmpty) {
        _isSearchingStocks = false;
        _stockSearchResults = const [];
      }
    });
    if (normalized.isEmpty) {
      return;
    }
    _searchDebounceTimer = Timer(
      const Duration(milliseconds: 250),
      () => _loadStockSearchResults(normalized),
    );
  }

  void _openStockDetails(MarketQuote quote) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (context) => StockDetailScreen(
          sessionController: widget.sessionController,
          marketDetailController: widget.marketDetailController,
          marketQuoteController: widget.marketQuoteController,
          tradeController: widget.tradeController,
          stockCode: quote.stockCode,
          title: quote.stockName,
        ),
      ),
    )
        .then((_) {
      if (mounted) {
        _subscribeHomeLive();
      }
    });
  }

  void _openStockSearchResult(StockSearchItem item) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (context) => StockDetailScreen(
          sessionController: widget.sessionController,
          marketDetailController: widget.marketDetailController,
          marketQuoteController: widget.marketQuoteController,
          tradeController: widget.tradeController,
          stockCode: item.stockCode,
          title: item.stockName,
        ),
      ),
    )
        .then((_) {
      if (mounted) {
        _subscribeHomeLive();
      }
    });
  }

  Future<void> _loadStockSearchResults(String query) async {
    if (!mounted || query != _searchQuery) {
      return;
    }
    setState(() {
      _isSearchingStocks = true;
      _stockSearchError = null;
    });
    try {
      final response = await widget.marketQuoteController.searchStocks(
        query: query,
        market: _marketQuery,
        limit: 20,
      );
      if (!mounted || query != _searchQuery) {
        return;
      }
      setState(() {
        _stockSearchResults = response.results;
        _isSearchingStocks = false;
      });
    } on Object {
      if (!mounted || query != _searchQuery) {
        return;
      }
      setState(() {
        _stockSearchResults = const [];
        _isSearchingStocks = false;
        _stockSearchError = 'Unable to search Korean stocks.';
      });
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSearchQuery = _searchQuery.isNotEmpty;
    return _ScreenFrame(
      title: 'Korea Market',
      subtitle: 'Live Korea stock quotes with KRW and USD pricing.',
      children: [
        _SearchField(onChanged: _searchStocks),
        if (hasSearchQuery)
          _StockSearchResultsPanel(
            query: _searchQuery,
            isLoading: _isSearchingStocks,
            results: _stockSearchResults,
            errorMessage: _stockSearchError,
            onSelect: _openStockSearchResult,
          )
        else ...[
          _MarketFilters(
            selectedMarket: _selectedMarket,
            onSelected: _selectMarket,
          ),
          _PopularStocksPanel(
            marketQuoteController: widget.marketQuoteController,
            selectedMarket: _marketQuery,
            stockCodes: _homePopularStockCodes,
            onSelectQuote: _openStockDetails,
          ),
        ],
      ],
    );
  }
}

class StockDetailScreen extends StatelessWidget {
  const StockDetailScreen({
    super.key,
    required this.sessionController,
    required this.marketDetailController,
    required this.marketQuoteController,
    required this.tradeController,
    required this.stockCode,
    required this.title,
  });

  final ExchangeSessionController sessionController;
  final MarketDetailController marketDetailController;
  final MarketQuoteController marketQuoteController;
  final TradeController tradeController;
  final String stockCode;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$title $stockCode'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StockDetailPanel(
              sessionController: sessionController,
              marketDetailController: marketDetailController,
              marketQuoteController: marketQuoteController,
              tradeController: tradeController,
              initialStockCode: stockCode,
            ),
          ],
        ),
      ),
    );
  }
}

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({
    super.key,
    required this.sessionController,
    required this.accountController,
    required this.tradeController,
    required this.watchlistQuoteController,
    required this.portfolioQuoteController,
  });

  final ExchangeSessionController sessionController;
  final AccountController accountController;
  final TradeController tradeController;
  final MarketQuoteController watchlistQuoteController;
  final MarketQuoteController portfolioQuoteController;

  @override
  Widget build(BuildContext context) {
    return _ScreenFrame(
      title: 'Portfolio',
      subtitle: 'USD cash, holdings, and account scoped Korea stock quotes.',
      children: [
        _BalancePanel(
          sessionController: sessionController,
          accountController: accountController,
        ),
        _HoldingsPanel(
          sessionController: sessionController,
          tradeController: tradeController,
        ),
        _AccountQuoteSnapshotPanel(
          title: 'Held stock prices',
          emptyTitle: 'No holdings quotes',
          emptyBody: 'No holding prices are available yet.',
          marketQuoteController: portfolioQuoteController,
          sessionController: sessionController,
          accountScope: MarketQuoteAccountScope.portfolio,
          onRefresh: (accountId) =>
              portfolioQuoteController.loadPortfolioSnapshot(
            accountId: accountId,
          ),
        ),
        _AccountQuoteSnapshotPanel(
          title: 'Watchlist prices',
          emptyTitle: 'No watchlist quotes',
          emptyBody: 'No watchlist prices are available yet.',
          marketQuoteController: watchlistQuoteController,
          sessionController: sessionController,
          accountScope: MarketQuoteAccountScope.watchlist,
          onRefresh: (accountId) =>
              watchlistQuoteController.loadWatchlistSnapshot(
            accountId: accountId,
          ),
        ),
        _InfoPanel(
          icon: Icons.point_of_sale,
          title: 'USD cash ledger',
          body: 'Deposits and trades update the Stock-exchange-BE ledger.',
          meta: 'Available cash USD 12,450.00',
        ),
      ],
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,
    required this.sessionController,
    required this.tradeController,
  });

  final ExchangeSessionController sessionController;
  final TradeController tradeController;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    widget.sessionController.addListener(_loadTradeHistory);
    _loadTradeHistory();
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_loadTradeHistory);
    super.dispose();
  }

  void _loadTradeHistory() {
    final accountId = widget.sessionController.session?.accountId;
    if (accountId != null && accountId.isNotEmpty) {
      widget.tradeController.loadTradeHistory(accountId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ScreenFrame(
      title: 'Orders',
      subtitle: 'Buy and sell history from the exchange ledger.',
      children: [
        _TradeHistoryPanel(
          sessionController: widget.sessionController,
          tradeController: widget.tradeController,
        ),
      ],
    );
  }
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({
    super.key,
    required this.sessionController,
    required this.notificationController,
  });

  final ExchangeSessionController sessionController;
  final NotificationController notificationController;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    widget.sessionController.addListener(_loadSignedInAlerts);
    _loadSignedInAlerts();
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_loadSignedInAlerts);
    super.dispose();
  }

  void _loadSignedInAlerts() {
    final accountId = widget.sessionController.session?.accountId;
    if (accountId != null && accountId.isNotEmpty) {
      widget.notificationController.loadAlerts(accountId: accountId);
    } else {
      widget.notificationController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ScreenFrame(
      title: 'Alerts',
      subtitle: 'AI translated news and disclosures for your stocks.',
      children: [
        _AlertInboxPanel(
          sessionController: widget.sessionController,
          notificationController: widget.notificationController,
        ),
      ],
    );
  }
}

class TaxScreen extends StatelessWidget {
  const TaxScreen({
    super.key,
    required this.sessionController,
    required this.taxController,
  });

  final ExchangeSessionController sessionController;
  final TaxController taxController;

  @override
  Widget build(BuildContext context) {
    return _ScreenFrame(
      title: 'Tax Refund',
      subtitle: 'Document status, refund estimate, and recapture risk.',
      children: [
        _TaxRefundStatusPanel(
          sessionController: sessionController,
          taxController: taxController,
        ),
        _TaxRefundRequestPanel(
          sessionController: sessionController,
          taxController: taxController,
        ),
        const _InfoPanel(
          icon: Icons.warning_amber_outlined,
          title: 'Recapture risk',
          body:
              'Advance refund completion includes a clear post-review risk notice.',
          meta: 'Risk notice required before advance payment',
        ),
      ],
    );
  }
}

class _TaxRefundRequestPanel extends StatefulWidget {
  const _TaxRefundRequestPanel({
    required this.sessionController,
    required this.taxController,
  });

  final ExchangeSessionController sessionController;
  final TaxController taxController;

  @override
  State<_TaxRefundRequestPanel> createState() => _TaxRefundRequestPanelState();
}

class _TaxRefundRequestPanelState extends State<_TaxRefundRequestPanel> {
  final TextEditingController _taxYearController =
      TextEditingController(text: '2026');
  final TextEditingController _treatyCountryController =
      TextEditingController(text: 'US');
  final TextEditingController _residenceFileController =
      TextEditingController(text: 'residence.pdf');
  final TextEditingController _reducedTaxFileController =
      TextEditingController(text: 'reduced-tax.pdf');
  bool _advancePaymentRequested = true;

  @override
  void dispose() {
    _taxYearController.dispose();
    _treatyCountryController.dispose();
    _residenceFileController.dispose();
    _reducedTaxFileController.dispose();
    super.dispose();
  }

  Future<void> _attachSampleDocuments() async {
    final accountId = widget.sessionController.session?.accountId;
    await widget.taxController.uploadDocument(
      accountId: accountId,
      documentType: 'RESIDENCE_CERTIFICATE',
      fileName: _residenceFileController.text,
      bytes: _sampleDocumentBytes(_residenceFileController.text),
    );
    await widget.taxController.uploadDocument(
      accountId: accountId,
      documentType: 'REDUCED_TAX_APPLICATION',
      fileName: _reducedTaxFileController.text,
      bytes: _sampleDocumentBytes(_reducedTaxFileController.text),
    );
  }

  Future<void> _submitRefundRequest() {
    return widget.taxController.submitRefundCase(
      accountId: widget.sessionController.session?.accountId,
      taxYear: int.tryParse(_taxYearController.text.trim()) ?? 2026,
      treatyCountry: _treatyCountryController.text,
      residenceCertificateFileName: _residenceFileController.text,
      reducedTaxApplicationFileName: _reducedTaxFileController.text,
      advancePaymentRequested: _advancePaymentRequested,
    );
  }

  Future<void> _syncHanaStatus() {
    return widget.taxController.syncRefundStatus(
      widget.sessionController.session?.accountId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ExchangeSessionState>(
      valueListenable: widget.sessionController,
      builder: (context, sessionState, child) {
        return ValueListenableBuilder<TaxState>(
          valueListenable: widget.taxController,
          builder: (context, taxState, child) {
            final isSignedIn = sessionState.isSignedIn;
            final isLoading = taxState.status == TaxStatus.loading;
            final colorScheme = Theme.of(context).colorScheme;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.upload_file_outlined,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tax document upload and refund request',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: 140,
                            child: TextField(
                              controller: _taxYearController,
                              enabled: isSignedIn && !isLoading,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Tax year',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: TextField(
                              controller: _treatyCountryController,
                              enabled: isSignedIn && !isLoading,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Treaty country',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: TextField(
                              controller: _residenceFileController,
                              enabled: isSignedIn && !isLoading,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Residence file',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: TextField(
                              controller: _reducedTaxFileController,
                              enabled: isSignedIn && !isLoading,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Reduced tax file',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Switch(
                            value: _advancePaymentRequested,
                            onChanged: isSignedIn && !isLoading
                                ? (value) => setState(() {
                                      _advancePaymentRequested = value;
                                    })
                                : null,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Request advance refund review'),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: isSignedIn && !isLoading
                                ? _attachSampleDocuments
                                : null,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Attach sample documents'),
                          ),
                          FilledButton.icon(
                            onPressed: isSignedIn && !isLoading
                                ? _submitRefundRequest
                                : null,
                            icon: const Icon(Icons.request_quote_outlined),
                            label: const Text('Submit refund request'),
                          ),
                          OutlinedButton.icon(
                            onPressed: isSignedIn && !isLoading
                                ? _syncHanaStatus
                                : null,
                            icon: const Icon(Icons.sync),
                            label: const Text('Sync Hana status'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoPanel(
                        icon: Icons.fact_check_outlined,
                        title: 'Uploaded document metadata',
                        body: taxState.uploadedDocuments.isEmpty
                            ? 'No uploaded document metadata yet.'
                            : taxState.uploadedDocuments
                                .map(
                                  (document) =>
                                      '${document.documentType} ${document.originalFileName}',
                                )
                                .join(' / '),
                        meta:
                            'POST /accounts/{accountId}/tax/documents and refund-cases',
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Uint8List _sampleDocumentBytes(String fileName) {
    return Uint8List.fromList(
      utf8.encode('sample tax document for $fileName'),
    );
  }
}

class _TaxRefundStatusPanel extends StatelessWidget {
  const _TaxRefundStatusPanel({
    required this.sessionController,
    required this.taxController,
  });

  final ExchangeSessionController sessionController;
  final TaxController taxController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ExchangeSessionState>(
      valueListenable: sessionController,
      builder: (context, sessionState, child) {
        return ValueListenableBuilder<TaxState>(
          valueListenable: taxController,
          builder: (context, taxState, child) {
            final accountId = sessionState.session?.accountId;
            final isSignedIn = sessionState.isSignedIn;
            final isLoading = taxState.status == TaxStatus.loading;
            final refundCase = taxState.refundCase;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Government verification',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (refundCase != null)
                            _SmallBadge(label: refundCase.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isSignedIn
                            ? 'Account $accountId / Stock-exchange-BE tax status'
                            : 'Sign in to load tax refund status.',
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: isSignedIn && !isLoading
                              ? () => taxController.loadRefundStatus(accountId)
                              : null,
                          icon: isLoading
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.verified_outlined),
                          label: const Text('Refresh tax status'),
                        ),
                      ),
                      if (taxState.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        _InfoPanel(
                          icon: Icons.error_outline,
                          title: 'Tax status unavailable',
                          body: taxState.errorMessage!,
                          meta: 'Bearer auth account tax endpoint',
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (refundCase == null)
                        const _InfoPanel(
                          icon: Icons.receipt_long_outlined,
                          title: 'Refund case pending',
                          body: 'Tax refund status will show government sync '
                              'state, reference number, and refund split after loading.',
                          meta: 'GET /accounts/{accountId}/tax/refund-status',
                        )
                      else ...[
                        Wrap(
                          spacing: 16,
                          runSpacing: 10,
                          children: [
                            _Metric(
                              label: 'Reference',
                              value: refundCase.referenceDisplay,
                            ),
                            _Metric(
                              label: 'Tax year',
                              value: '${refundCase.taxYear}',
                            ),
                            _Metric(
                              label: 'Treaty country',
                              value: refundCase.treatyCountry,
                            ),
                            _Metric(
                              label: 'Refund',
                              value: refundCase.refundDisplay,
                            ),
                            _Metric(
                              label: 'Matched sells',
                              value: '${refundCase.matchedTradeCount}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _TaxRefundSplit(caseData: refundCase),
                        const SizedBox(height: 12),
                        _InfoPanel(
                          icon: Icons.account_balance_outlined,
                          title: 'Government verification reference',
                          body: 'Status ${refundCase.status} / reference '
                              '${refundCase.referenceDisplay}',
                          meta: '${refundCase.dataSource} / updated '
                              '${refundCase.updatedAt?.toUtc().toIso8601String() ?? 'unknown'}',
                        ),
                        _TaxDocumentChecklist(caseData: refundCase),
                        _TaxStatusTimeline(caseData: refundCase),
                        _TaxInputSummary(caseData: refundCase),
                        _TaxAdvanceReceipt(caseData: refundCase),
                        _TaxRecaptureNotice(caseData: refundCase),
                        if (refundCase.matchedTrades.isNotEmpty)
                          _TaxMatchedTradeRow(
                            trade: refundCase.matchedTrades.first,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TaxDocumentChecklist extends StatelessWidget {
  const _TaxDocumentChecklist({required this.caseData});

  final TaxRefundCase caseData;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      icon: Icons.fact_check_outlined,
      title: 'Submitted tax documents',
      body: 'Residence certificate ${caseData.residenceCertificateFileName} / '
          'reduced tax form ${caseData.reducedTaxApplicationFileName}',
      meta: 'Documents are linked to refund case ${caseData.referenceDisplay}',
    );
  }
}

class _TaxStatusTimeline extends StatelessWidget {
  const _TaxStatusTimeline({required this.caseData});

  final TaxRefundCase caseData;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TaxTimelineStep('Documents received', caseData.createdAt != null),
      _TaxTimelineStep('Sell ledger matched', caseData.matchedTradeCount > 0),
      _TaxTimelineStep(
        'Government sync ${caseData.status}',
        caseData.updatedAt != null,
      ),
      _TaxTimelineStep(
        'Advance review requested',
        caseData.advancePaymentRequested,
      ),
    ];
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Refund status timeline',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              ...steps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        step.complete
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        color: step.complete
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(step.label)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaxTimelineStep {
  const _TaxTimelineStep(this.label, this.complete);

  final String label;
  final bool complete;
}

class _TaxInputSummary extends StatelessWidget {
  const _TaxInputSummary({required this.caseData});

  final TaxRefundCase caseData;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      icon: Icons.request_quote_outlined,
      title: 'Refund input from sell trades',
      body: 'Total sells USD ${caseData.totalSellAmountUsd} / '
          'taxable realized PnL USD '
          '${caseData.taxableRealizedPnlUsd}',
      meta: 'Profit USD ${caseData.realizedProfitUsd} / '
          'loss USD ${caseData.realizedLossUsd} / '
          'net USD ${caseData.netRealizedPnlUsd}',
    );
  }
}

class _TaxRecaptureNotice extends StatelessWidget {
  const _TaxRecaptureNotice({required this.caseData});

  final TaxRefundCase caseData;

  @override
  Widget build(BuildContext context) {
    final message = caseData.status == 'RECAPTURE_RISK'
        ? 'Post-payment review found a recapture risk. Keep documents ready '
            'before using advance funds.'
        : 'Advance payment can be reviewed later. Recapture risk is shown '
            'here if Hana returns RECAPTURE_RISK.';
    final meta = caseData.advancePaymentEligible
        ? 'Advance payment eligible / requested ${caseData.advancePaymentRequested}'
        : 'Advance payment not eligible yet';
    return _InfoPanel(
      icon: Icons.policy_outlined,
      title: 'Post-payment recapture notice',
      body: message,
      meta: meta,
    );
  }
}

class _TaxAdvanceReceipt extends StatelessWidget {
  const _TaxAdvanceReceipt({required this.caseData});

  final TaxRefundCase caseData;

  @override
  Widget build(BuildContext context) {
    if (caseData.status != 'ADVANCE_PAID') {
      return _InfoPanel(
        icon: Icons.receipt_long_outlined,
        title: 'Advance refund receipt',
        body:
            'Advance payment receipt is issued after Hana returns ADVANCE_PAID.',
        meta: 'Current status ${caseData.status}',
      );
    }

    final paidAt =
        caseData.updatedAt?.toUtc().toIso8601String() ?? 'pending timestamp';
    return _InfoPanel(
      icon: Icons.receipt_long,
      title: 'Advance refund receipt',
      body:
          'Receipt ${caseData.referenceDisplay} confirms advance refund ${caseData.refundDisplay}.',
      meta:
          'Paid at $paidAt / post-review recapture risk notice remains active',
    );
  }
}

class _TaxRefundSplit extends StatelessWidget {
  const _TaxRefundSplit({required this.caseData});

  final TaxRefundCase caseData;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Withholding tax split',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            _SplitBar(
              label: 'Treaty tax kept',
              value: caseData.treatyDisplay,
              ratio: caseData.treatyRatio,
            ),
            const SizedBox(height: 10),
            _SplitBar(
              label: 'Refundable difference',
              value: caseData.refundDisplay,
              ratio: caseData.refundRatio,
            ),
            const SizedBox(height: 10),
            Text('Original withholding ${caseData.withholdingDisplay}'),
          ],
        ),
      ),
    );
  }
}

class _SplitBar extends StatelessWidget {
  const _SplitBar({
    required this.label,
    required this.value,
    required this.ratio,
  });

  final String label;
  final String value;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(value),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: ratio),
      ],
    );
  }
}

class _TaxMatchedTradeRow extends StatelessWidget {
  const _TaxMatchedTradeRow({required this.trade});

  final TaxMatchedTrade trade;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      icon: Icons.sell_outlined,
      title: 'Matched sell trade',
      body: '${trade.stockName} ${trade.quantity} shares / '
          'realized PnL USD ${trade.realizedPnlUsd}',
      meta: '${trade.tradeId} / gross USD ${trade.grossAmountUsd}',
    );
  }
}

class _ScreenFrame extends StatelessWidget {
  const _ScreenFrame({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class _SessionAction extends StatelessWidget {
  const _SessionAction({required this.sessionController});

  final ExchangeSessionController sessionController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ExchangeSessionState>(
      valueListenable: sessionController,
      builder: (context, sessionState, child) {
        final isSignedIn = sessionState.isSignedIn;
        return TextButton.icon(
          onPressed: () => _showAuthDialog(context, sessionController),
          icon: Icon(isSignedIn ? Icons.person : Icons.login),
          label: Text(isSignedIn ? sessionState.session!.username : 'Sign in'),
        );
      },
    );
  }
}

Future<void> _showAuthDialog(
  BuildContext context,
  ExchangeSessionController sessionController,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => _AuthDialog(sessionController: sessionController),
  );
}

class _AuthDialog extends StatefulWidget {
  const _AuthDialog({required this.sessionController});

  final ExchangeSessionController sessionController;

  @override
  State<_AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<_AuthDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    await widget.sessionController.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );
    if (mounted && widget.sessionController.value.isSignedIn) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _signUp() async {
    await widget.sessionController.signUpAndLogin(
      username: _usernameController.text,
      password: _passwordController.text,
    );
    if (mounted && widget.sessionController.value.isSignedIn) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ExchangeSessionState>(
      valueListenable: widget.sessionController,
      builder: (context, sessionState, child) {
        final isSignedIn = sessionState.isSignedIn;
        final isLoading = sessionState.status == ExchangeSessionStatus.loading;

        return AlertDialog(
          icon: Icon(isSignedIn ? Icons.verified_user : Icons.lock_outline),
          title: Text(isSignedIn ? 'Account' : 'Sign in'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: isSignedIn
                ? Text(
                    '${sessionState.session!.username}\n'
                    'Account ${sessionState.session!.accountId}',
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _usernameController,
                        enabled: !isLoading,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Username',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        enabled: !isLoading,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Password',
                        ),
                      ),
                      if (sessionState.errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          sessionState.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (isSignedIn)
              FilledButton.icon(
                onPressed: () async {
                  await widget.sessionController.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              )
            else ...[
              OutlinedButton(
                onPressed: isLoading ? null : _signUp,
                child: const Text('Create account'),
              ),
              FilledButton.icon(
                onPressed: isLoading ? null : _signIn,
                icon: isLoading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: const Text('Sign in'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SessionStatusPanel extends StatefulWidget {
  const _SessionStatusPanel({required this.sessionController});

  final ExchangeSessionController sessionController;

  @override
  State<_SessionStatusPanel> createState() => _SessionStatusPanelState();
}

class _SessionStatusPanelState extends State<_SessionStatusPanel> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: ValueListenableBuilder<ExchangeSessionState>(
            valueListenable: widget.sessionController,
            builder: (context, sessionState, child) {
              return switch (sessionState.status) {
                ExchangeSessionStatus.signedIn => _SignedInSessionView(
                    sessionState: sessionState,
                    onRefresh: widget.sessionController.refresh,
                    onSignOut: widget.sessionController.signOut,
                  ),
                ExchangeSessionStatus.loading => _AuthFormView(
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    sessionState: sessionState,
                    onSignIn: null,
                    onSignUp: null,
                  ),
                _ => _AuthFormView(
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    sessionState: sessionState,
                    onSignIn: _signIn,
                    onSignUp: _signUp,
                  ),
              };
            },
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() {
    return widget.sessionController.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _signUp() {
    return widget.sessionController.signUpAndLogin(
      username: _usernameController.text,
      password: _passwordController.text,
    );
  }
}

class _AuthFormView extends StatelessWidget {
  const _AuthFormView({
    required this.usernameController,
    required this.passwordController,
    required this.sessionState,
    required this.onSignIn,
    required this.onSignUp,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final ExchangeSessionState sessionState;
  final VoidCallback? onSignIn;
  final VoidCallback? onSignUp;

  @override
  Widget build(BuildContext context) {
    final isLoading = sessionState.status == ExchangeSessionStatus.loading;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign in with username and password',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Session uses bearer auth from Stock-exchange-BE.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: usernameController,
          enabled: !isLoading,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Username',
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: passwordController,
          enabled: !isLoading,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Password',
          ),
          obscureText: true,
          textInputAction: TextInputAction.done,
        ),
        if (sessionState.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            sessionState.errorMessage!,
            style: TextStyle(color: colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onSignIn,
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: const Text('Sign in'),
            ),
            OutlinedButton.icon(
              onPressed: onSignUp,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Create account'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SignedInSessionView extends StatelessWidget {
  const _SignedInSessionView({
    required this.sessionState,
    required this.onRefresh,
    required this.onSignOut,
  });

  final ExchangeSessionState sessionState;
  final VoidCallback onRefresh;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final session = sessionState.session!;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.verified_user_outlined, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signed in as ${session.username}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text('Account ${session.accountId}'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh session'),
                  ),
                  TextButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: const ValueKey('market-stock-search-field'),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search all Korean stocks',
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _StockSearchResultsPanel extends StatelessWidget {
  const _StockSearchResultsPanel({
    required this.query,
    required this.isLoading,
    required this.results,
    required this.errorMessage,
    required this.onSelect,
  });

  final String query;
  final bool isLoading;
  final List<StockSearchItem> results;
  final String? errorMessage;
  final ValueChanged<StockSearchItem> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLoading) const LinearProgressIndicator(minHeight: 2),
        if (isLoading) const SizedBox(height: 12),
        if (errorMessage != null)
          _InfoPanel(
            icon: Icons.search_off,
            title: 'Search unavailable',
            body: errorMessage!,
            meta: '',
          )
        else if (!isLoading && results.isEmpty)
          _InfoPanel(
            icon: Icons.search_off,
            title: 'No matching stocks',
            body: 'No Korean stock matches "$query".',
            meta: '',
          )
        else
          ...results.map(
            (result) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                key: ValueKey('stock-search-result-${result.stockCode}'),
                onTap: () => onSelect(result),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      _StockSearchAvatar(result: result),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HighlightedStockName(
                              name: result.stockName,
                              query: query,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${result.stockCode} / ${result.market}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StockSearchAvatar extends StatelessWidget {
  const _StockSearchAvatar({required this.result});

  final StockSearchItem result;

  @override
  Widget build(BuildContext context) {
    final color = switch (result.market) {
      'KOSDAQ' => const Color(0xFF2563EB),
      'KONEX' => const Color(0xFF7C3AED),
      _ => const Color(0xFF0F766E),
    };
    final label = result.stockName.isEmpty
        ? result.stockCode
        : result.stockName.substring(0, math.min(result.stockName.length, 2));

    return CircleAvatar(
      radius: 28,
      backgroundColor: color.withAlpha(24),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _HighlightedStockName extends StatelessWidget {
  const _HighlightedStockName({
    required this.name,
    required this.query,
  });

  final String name;
  final String query;

  @override
  Widget build(BuildContext context) {
    final normalizedName = name.toLowerCase();
    final normalizedQuery = query.toLowerCase();
    final start = normalizedName.indexOf(normalizedQuery);
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );
    if (start < 0 || normalizedQuery.isEmpty) {
      return Text(name,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    }

    final end = start + query.length;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: name.substring(0, start)),
          TextSpan(
            text: name.substring(start, end),
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          TextSpan(text: name.substring(end)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _MarketFilters extends StatelessWidget {
  const _MarketFilters({
    required this.selectedMarket,
    required this.onSelected,
  });

  final String selectedMarket;
  final ValueChanged<String> onSelected;

  static const _markets = ['ALL', 'KOSPI', 'KOSDAQ'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _markets
            .map(
              (market) => ChoiceChip(
                label: Text(market == 'ALL' ? 'All' : market),
                selected: selectedMarket == market,
                onSelected: (_) => onSelected(market),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AlertInboxPanel extends StatelessWidget {
  const _AlertInboxPanel({
    required this.sessionController,
    required this.notificationController,
  });

  final ExchangeSessionController sessionController;
  final NotificationController notificationController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ExchangeSessionState>(
      valueListenable: sessionController,
      builder: (context, sessionState, _) {
        return ValueListenableBuilder<NotificationState>(
          valueListenable: notificationController,
          builder: (context, alertState, _) {
            final accountId = sessionState.session?.accountId;
            final isSignedIn = accountId != null && accountId.isNotEmpty;
            final isLoading = alertState.status == NotificationStatus.loading;
            final inbox = alertState.inbox;
            final feed = alertState.feed;
            final devices = alertState.devices;
            final filteredNotifications = alertState.filteredNotifications;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Integrated alert inbox',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Refresh alerts',
                            onPressed: isSignedIn && !isLoading
                                ? () => notificationController.loadAlerts(
                                      accountId: accountId,
                                    )
                                : null,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _AlertFilters(
                        selectedFilter: alertState.selectedFilter,
                        onSelected: notificationController.setFilter,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _Metric(
                            label: 'Unread',
                            value: '${inbox?.unreadCount ?? 0}',
                          ),
                          _Metric(
                            label: 'Total',
                            value: '${inbox?.totalCount ?? 0}',
                          ),
                          _Metric(
                            label: 'K-News',
                            value: '${feed?.itemCount ?? 0}',
                          ),
                          _Metric(
                            label: 'Push devices',
                            value: '${devices?.activeCount ?? 0}',
                          ),
                        ],
                      ),
                      if (!isSignedIn) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Sign in to load watchlist and portfolio alerts.',
                        ),
                      ] else if (isLoading) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                      ] else if (alertState.status ==
                          NotificationStatus.failure) ...[
                        const SizedBox(height: 12),
                        Text(alertState.errorMessage ??
                            'Unable to load alerts.'),
                      ],
                      const SizedBox(height: 12),
                      if (filteredNotifications.isEmpty)
                        const Text('No alert notifications for this filter.')
                      else
                        ...filteredNotifications
                            .take(4)
                            .map((item) => _NotificationRow(
                                  accountId: accountId,
                                  item: item,
                                  notificationController:
                                      notificationController,
                                )),
                      const SizedBox(height: 12),
                      _NotificationDevicePanel(
                        accountId: accountId,
                        devices: devices,
                        notificationController: notificationController,
                      ),
                      const SizedBox(height: 12),
                      _StockIntelligencePanel(feed: feed),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NotificationDevicePanel extends StatelessWidget {
  const _NotificationDevicePanel({
    required this.accountId,
    required this.devices,
    required this.notificationController,
  });

  final String? accountId;
  final NotificationDeviceList? devices;
  final NotificationController notificationController;

  @override
  Widget build(BuildContext context) {
    final activeDevices = devices?.devices
            .where((device) => device.active)
            .toList(growable: false) ??
        const <NotificationDevice>[];
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phonelink_ring_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Push device registration',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: accountId == null
                      ? null
                      : () => notificationController.registerLocalDevice(
                            accountId: accountId,
                          ),
                  icon: const Icon(Icons.add_alert_outlined),
                  label: const Text('Register'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (activeDevices.isEmpty)
              const Text(
                'No active push device is registered for this account.',
              )
            else
              ...activeDevices.take(3).map(
                    (device) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(device.displayLabel)),
                          TextButton(
                            onPressed: accountId == null
                                ? null
                                : () => notificationController.disableDevice(
                                      accountId: accountId,
                                      deviceTokenId: device.deviceTokenId,
                                    ),
                            child: const Text('Disable'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _AlertFilters extends StatelessWidget {
  const _AlertFilters({
    required this.selectedFilter,
    required this.onSelected,
  });

  final NotificationFilter selectedFilter;
  final ValueChanged<NotificationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: NotificationFilter.values
          .map(
            (filter) => ChoiceChip(
              label: Text(filter.label),
              selected: selectedFilter == filter,
              onSelected: (_) => onSelected(filter),
            ),
          )
          .toList(),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.accountId,
    required this.item,
    required this.notificationController,
  });

  final String? accountId;
  final NotificationItem item;
  final NotificationController notificationController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item.read
                    ? Icons.mark_email_read_outlined
                    : Icons.mark_email_unread,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(item.summary),
                    const SizedBox(height: 8),
                    Text(
                      '${item.sourceType} / ${item.targetLabel} / ${item.primaryStockCode}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    _AlertSignalWrap(
                      labels: [
                        item.sourceType,
                        item.targetLabel,
                      ],
                    ),
                    if (item.originalUrl.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.originalUrl,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                      ),
                    ],
                    _TranslationQualityWrap(
                      glossaryTerms: item.glossaryTerms,
                      qualityFlags: item.translationQualityFlags,
                    ),
                    const SizedBox(height: 10),
                    _PushDeliveryTimeline(item: item),
                  ],
                ),
              ),
              TextButton(
                onPressed: item.read || accountId == null
                    ? null
                    : () => notificationController.markRead(
                          accountId: accountId,
                          notificationId: item.notificationId,
                        ),
                child: const Text('Read'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PushDeliveryTimeline extends StatelessWidget {
  const _PushDeliveryTimeline({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lastDeliveryError = item.lastDeliveryError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: colorScheme.outlineVariant),
        Row(
          children: [
            Icon(
              item.deliveryNeedsAttention
                  ? Icons.sync_problem_outlined
                  : Icons.notifications_active_outlined,
              size: 18,
              color: item.deliveryNeedsAttention
                  ? colorScheme.error
                  : colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Push delivery timeline',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusChip(
              icon: Icons.schedule_outlined,
              label: 'Created ${_compactTimestamp(item.createdAt)}',
            ),
            _StatusChip(
              icon: _deliveryStatusIcon(item.deliveryStatusLabel),
              label: item.deliveryStatusLabel,
            ),
            _StatusChip(
              icon: Icons.cloud_queue_outlined,
              label: item.deliveryProviderLabel,
            ),
            _StatusChip(
              icon: Icons.replay_outlined,
              label: item.deliveryAttemptLabel,
            ),
            _StatusChip(
              icon: item.read
                  ? Icons.mark_email_read_outlined
                  : Icons.mark_email_unread_outlined,
              label: item.read
                  ? 'Read ${_compactTimestamp(item.readAt)}'
                  : 'Unread',
            ),
            if (item.deliveredAt != null)
              _StatusChip(
                icon: Icons.done_all_outlined,
                label: 'Delivered ${_compactTimestamp(item.deliveredAt)}',
              ),
          ],
        ),
        if (lastDeliveryError != null && lastDeliveryError.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            lastDeliveryError,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
          ),
        ],
      ],
    );
  }
}

IconData _deliveryStatusIcon(String status) {
  switch (status.toUpperCase()) {
    case 'DELIVERED':
      return Icons.done_all_outlined;
    case 'FAILED':
      return Icons.error_outline;
    case 'RETRYING':
      return Icons.sync_problem_outlined;
    default:
      return Icons.schedule_outlined;
  }
}

String _compactTimestamp(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final iso = value.toUtc().toIso8601String();
  return iso.replaceFirst('T', ' ').replaceFirst(RegExp(r'\.\d+Z$'), 'Z');
}

class _StockIntelligencePanel extends StatelessWidget {
  const _StockIntelligencePanel({required this.feed});

  final StockIntelligenceFeed? feed;

  @override
  Widget build(BuildContext context) {
    final items = feed?.items ?? const <StockIntelligenceItem>[];
    if (items.isEmpty) {
      return const Text('No K-News intelligence feed yet.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'K-News intelligence feed',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ...items.take(3).expand(
              (item) => [
                _InfoPanel(
                  icon: Icons.article_outlined,
                  title: item.title,
                  body: item.displaySummary,
                  meta: '${item.importance} / ${item.sentiment} / '
                      '${item.targetLabel} / ${item.contentAvailability} / ${item.originalUrl}',
                ),
                if (item.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      item.imageUrls.first,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ],
                if (item.contentPreview.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.contentPreview,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                _AlertSignalWrap(
                  labels: [
                    item.sourceType,
                    item.importance,
                    item.sentiment,
                    item.riskLevel,
                    item.targetLabel,
                  ],
                ),
                _TranslationQualityWrap(
                  glossaryTerms: item.glossaryTerms,
                  qualityFlags: item.translationQualityFlags,
                  bottomPadding: 12,
                ),
              ],
            ),
      ],
    );
  }
}

class _AlertSignalWrap extends StatelessWidget {
  const _AlertSignalWrap({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final visibleLabels = labels
        .where((label) => label.isNotEmpty && label != 'All')
        .toSet()
        .toList();
    if (visibleLabels.isEmpty) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: visibleLabels
            .map(
              (label) => Chip(
                label: Text(label),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TranslationQualityWrap extends StatelessWidget {
  const _TranslationQualityWrap({
    required this.glossaryTerms,
    required this.qualityFlags,
    this.bottomPadding = 0,
  });

  final List<AlertGlossaryTerm> glossaryTerms;
  final List<String> qualityFlags;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final labels = [
      ...qualityFlags.where((flag) => flag.isNotEmpty),
      ...glossaryTerms.map((term) => term.displayLabel),
    ];
    if (labels.isEmpty) {
      return SizedBox(height: bottomPadding);
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: bottomPadding),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: labels
            .take(4)
            .map(
              (label) => Chip(
                avatar: Icon(
                  Icons.translate_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                label: Text(label),
                visualDensity: VisualDensity.compact,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PopularStocksPanel extends StatelessWidget {
  const _PopularStocksPanel({
    required this.marketQuoteController,
    required this.selectedMarket,
    required this.stockCodes,
    required this.onSelectQuote,
  });

  final MarketQuoteController marketQuoteController;
  final String? selectedMarket;
  final List<String> stockCodes;
  final ValueChanged<MarketQuote> onSelectQuote;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MarketQuoteState>(
      valueListenable: marketQuoteController,
      builder: (context, quoteState, child) {
        final popularQuotes = _popularQuotes(
          quoteState.quotes,
          selectedMarket,
          stockCodes,
        );
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.surface,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Popular stocks',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      _SmallBadge(label: selectedMarket ?? 'ALL'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (popularQuotes.isEmpty)
                    Text(
                      'Popular stock movers will appear after quote data loads.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    )
                  else
                    ...popularQuotes.indexed.map(
                      (entry) => _PopularStockRow(
                        rank: entry.$1 + 1,
                        quote: entry.$2,
                        onTap: () => onSelectQuote(entry.$2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static List<MarketQuote> _popularQuotes(
    List<MarketQuote> quotes,
    String? selectedMarket,
    List<String> stockCodes,
  ) {
    final allowed = stockCodes.toSet();
    final filtered = quotes
        .where(
          (quote) =>
              allowed.contains(quote.stockCode) &&
              (selectedMarket == null || quote.market == selectedMarket),
        )
        .toList()
      ..sort((left, right) => right.volume.compareTo(left.volume));
    return filtered.toList(growable: false);
  }
}

class _PopularStockRow extends StatelessWidget {
  const _PopularStockRow({
    required this.rank,
    required this.quote,
    required this.onTap,
  });

  final int rank;
  final MarketQuote quote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final positive = _isPositiveMove(quote.changeRate);
    final afterHoursMove = quote.afterHoursChangeRate ?? '';
    final afterHoursPositive = _isPositiveMove(afterHoursMove);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '$rank',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quote.stockName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${quote.stockCode} / ${quote.market}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 112,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    quote.localCurrencyDisplay,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _rateDisplay(quote.changeRate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: positive
                              ? Colors.teal.shade700
                              : colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (quote.hasAfterHoursPrice) ...[
                    const SizedBox(height: 4),
                    Text(
                      'AH ${quote.afterHoursLocalCurrencyDisplay}',
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (afterHoursMove.trim().isNotEmpty)
                      Text(
                        _rateDisplay(afterHoursMove),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: afterHoursPositive
                              ? Colors.teal.shade700
                              : colorScheme.error,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountQuoteSnapshotPanel extends StatelessWidget {
  const _AccountQuoteSnapshotPanel({
    required this.title,
    required this.emptyTitle,
    required this.emptyBody,
    required this.marketQuoteController,
    required this.sessionController,
    required this.accountScope,
    required this.onRefresh,
  });

  final String title;
  final String emptyTitle;
  final String emptyBody;
  final MarketQuoteController marketQuoteController;
  final ExchangeSessionController sessionController;
  final MarketQuoteAccountScope accountScope;
  final Future<void> Function(String? accountId) onRefresh;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ExchangeSessionState>(
      valueListenable: sessionController,
      builder: (context, sessionState, child) {
        return ValueListenableBuilder<MarketQuoteState>(
          valueListenable: marketQuoteController,
          builder: (context, quoteState, child) {
            final accountId = sessionState.session?.accountId;
            final isSignedIn = sessionState.isSignedIn;
            final isLoading = quoteState.status == MarketQuoteStatus.loading;
            final snapshot = quoteState.snapshot;
            if (isSignedIn &&
                quoteState.status == MarketQuoteStatus.idle &&
                quoteState.quotes.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onRefresh(accountId);
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (isLoading) const LinearProgressIndicator(minHeight: 2),
                if (isLoading) const SizedBox(height: 12),
                if (quoteState.errorMessage != null &&
                    quoteState.quotes.isNotEmpty)
                  _InfoPanel(
                    icon: Icons.info_outline,
                    title: 'Prices may be delayed',
                    body: 'Keeping the latest prices on screen.',
                    meta: 'Account prices',
                  ),
                if (quoteState.quotes.isEmpty)
                  _InfoPanel(
                    icon: Icons.list_alt_outlined,
                    title: quoteState.errorMessage == null
                        ? emptyTitle
                        : 'Prices temporarily unavailable',
                    body: isSignedIn
                        ? quoteState.errorMessage ?? emptyBody
                        : 'Sign in to load this account scope.',
                    meta: snapshot == null
                        ? 'Account prices'
                        : '${snapshot.quoteCount} quotes',
                  )
                else
                  ...quoteState.quotes.map(
                    (quote) => _QuoteRow(quote: quote, onTap: () {}),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({
    required this.quote,
    required this.onTap,
  });

  final MarketQuote quote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        quote.stockName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    _SmallBadge(label: quote.market),
                  ],
                ),
                const SizedBox(height: 6),
                Text(quote.stockCode),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _Metric(
                        label: 'KRW', value: quote.krwDisplay, tabular: true),
                    _Metric(
                      label: quote.localCurrency,
                      value: quote.localCurrencyDisplay,
                      tabular: true,
                    ),
                    _Metric(
                      label: 'Move',
                      value: _rateDisplay(quote.changeRate),
                    ),
                    _Metric(label: 'Volume', value: '${quote.volume}'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _isPositiveMove(String value) => !value.trim().startsWith('-');

bool isKoreaRegularMarketOpen(DateTime utcNow) {
  final koreaNow = utcNow.toUtc().add(const Duration(hours: 9));
  final weekday = koreaNow.weekday;
  if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
    return false;
  }
  final minutes = koreaNow.hour * 60 + koreaNow.minute;
  const openMinutes = 9 * 60;
  const closeMinutes = 15 * 60 + 30;
  return minutes >= openMinutes && minutes < closeMinutes;
}

String marketQuoteLiveStatusLabel(
  MarketQuoteLiveStatus status,
  MarketQuote? liveQuote, {
  DateTime? nowUtc,
}) {
  if (liveQuote?.hasAfterHoursPrice ?? false) {
    return 'After-hours';
  }
  if (!isKoreaRegularMarketOpen(nowUtc ?? DateTime.now().toUtc())) {
    return 'Closed';
  }
  if (status == MarketQuoteLiveStatus.live && liveQuote != null) {
    return 'Live';
  }
  if (status == MarketQuoteLiveStatus.connecting) {
    return 'Connecting';
  }
  return 'Delayed';
}

String _rateDisplay(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.endsWith('%')) {
    return trimmed;
  }
  return '$trimmed%';
}

double? _decimalValue(String value) {
  final normalized = value.replaceAll(',', '').trim();
  return double.tryParse(normalized);
}

class _ChartPeriodRange {
  const _ChartPeriodRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  factory _ChartPeriodRange.fromPeriod(String period) {
    final to = DateTime.now().toUtc();
    final days = switch (period) {
      '1D' => 5,
      '1W' => 7,
      '1M' => 30,
      _ => 30,
    };
    return _ChartPeriodRange(
      from: to.subtract(Duration(days: days)),
      to: to,
    );
  }
}

class _StockDetailPanel extends StatefulWidget {
  const _StockDetailPanel({
    required this.sessionController,
    required this.marketDetailController,
    required this.marketQuoteController,
    required this.tradeController,
    this.initialStockCode,
  });

  final ExchangeSessionController sessionController;
  final MarketDetailController marketDetailController;
  final MarketQuoteController marketQuoteController;
  final TradeController tradeController;
  final String? initialStockCode;

  @override
  State<_StockDetailPanel> createState() => _StockDetailPanelState();
}

class _StockDetailPanelState extends State<_StockDetailPanel> {
  late final String _stockCode;
  String _selectedPeriod = '1D';
  Timer? _orderBookRefreshTimer;
  bool _isRefreshingOrderBook = false;
  final List<_LivePricePoint> _livePricePoints = [];
  String? _lastLivePriceKey;

  @override
  void initState() {
    super.initState();
    _stockCode = widget.initialStockCode ?? '005930';
    widget.marketQuoteController.addListener(_recordLivePricePoint);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSelectedPeriod();
        if (widget.marketQuoteController.canSubscribeLive) {
          widget.marketQuoteController.subscribeLive(stockCodes: [_stockCode]);
        }
        _startOrderBookRefresh();
      }
    });
  }

  void _loadSelectedPeriod() {
    final chartRange = _ChartPeriodRange.fromPeriod(_selectedPeriod);
    widget.marketDetailController.loadStock(
      stockCode: _stockCode,
      interval: '1d',
      from: chartRange.from,
      to: chartRange.to,
    );
  }

  void _startOrderBookRefresh() {
    _orderBookRefreshTimer?.cancel();
    _orderBookRefreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshOrderBook(),
    );
  }

  Future<void> _refreshOrderBook() async {
    if (_isRefreshingOrderBook) {
      return;
    }
    _isRefreshingOrderBook = true;
    try {
      await widget.marketDetailController.refreshOrderBook(
        stockCode: _stockCode,
      );
    } finally {
      _isRefreshingOrderBook = false;
    }
  }

  void _recordLivePricePoint() {
    final quote = _liveQuoteForStockCode(
      _stockCode,
      widget.marketQuoteController.value.quotes,
    );
    if (quote == null) {
      return;
    }
    final price = _decimalValue(quote.localCurrencyPrice);
    if (price == null) {
      return;
    }
    final key = quote.liveUpdateKey;
    if (_lastLivePriceKey == key) {
      return;
    }
    _lastLivePriceKey = key;
    final point = _LivePricePoint(
      at: quote.marketDataTime ?? quote.publishedAt ?? DateTime.now().toUtc(),
      price: price,
      volume: quote.volume,
      currency: quote.localCurrency,
    );
    if (!mounted) {
      _livePricePoints.add(point);
      _trimLivePricePoints();
      return;
    }
    setState(() {
      _livePricePoints.add(point);
      _trimLivePricePoints();
    });
  }

  void _trimLivePricePoints() {
    const maxLivePoints = 240;
    if (_livePricePoints.length > maxLivePoints) {
      _livePricePoints.removeRange(
        0,
        _livePricePoints.length - maxLivePoints,
      );
    }
  }

  @override
  void dispose() {
    _orderBookRefreshTimer?.cancel();
    widget.marketQuoteController.removeListener(_recordLivePricePoint);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MarketDetailState>(
      valueListenable: widget.marketDetailController,
      builder: (context, detailState, child) {
        final isLoading = detailState.status == MarketDetailStatus.loading;
        final detail = detailState.detail;
        final chart = detailState.chart;
        final orderBook = detailState.orderBook;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          detail == null ? 'Stock detail' : detail.stockName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      if (detail != null) _SmallBadge(label: detail.stockCode),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (detailState.errorMessage != null)
                    _InfoPanel(
                      icon: Icons.error_outline,
                      title: 'Stock detail unavailable',
                      body: detailState.errorMessage!,
                      meta: 'Try again shortly.',
                    ),
                  if (detail == null)
                    const _InfoPanel(
                      icon: Icons.query_stats,
                      title: 'Loading stock detail',
                      body: 'Preparing price, chart, and quotes.',
                      meta: '',
                    )
                  else
                    ValueListenableBuilder<MarketQuoteState>(
                      valueListenable: widget.marketQuoteController,
                      builder: (context, quoteState, child) {
                        final liveQuote = _liveQuoteForDetail(
                          detail,
                          quoteState.quotes,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailLivePricePanel(
                              detail: detail,
                              liveQuote: liveQuote,
                              liveStatus: quoteState.liveStatus,
                            ),
                            _MarketHistoryChartPanel(
                              chart: chart,
                              selectedPeriod: _selectedPeriod,
                              livePoints: List.unmodifiable(_livePricePoints),
                              fallbackCandle:
                                  _fallbackCandle(detail, liveQuote),
                              isLoading: isLoading,
                              onPeriodSelected: (period) {
                                setState(() {
                                  _selectedPeriod = period;
                                });
                                _loadSelectedPeriod();
                              },
                            ),
                            _OrderBookPreview(orderBook: orderBook),
                            _ForeignOwnershipGaugePanel(detail: detail),
                            _DetailTradeActionBar(
                              sessionController: widget.sessionController,
                              tradeController: widget.tradeController,
                              detail: detail,
                              liveQuote: liveQuote,
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailLivePricePanel extends StatelessWidget {
  const _DetailLivePricePanel({
    required this.detail,
    required this.liveQuote,
    required this.liveStatus,
  });

  final StockDetail detail;
  final MarketQuote? liveQuote;
  final MarketQuoteLiveStatus liveStatus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentCurrency = liveQuote?.localCurrency ?? detail.displayCurrency;
    final currentPrice =
        liveQuote?.localCurrencyDisplay ?? detail.localCurrencyDisplay;
    final currentKrw = liveQuote?.krwDisplay ?? detail.krwDisplay;
    final currentMove = liveQuote?.changeRate ?? detail.changeRate;
    final positive = _isPositiveMove(currentMove);
    final quote = liveQuote;
    final afterHoursQuote =
        quote != null && quote.hasAfterHoursPrice ? quote : null;
    final afterHoursMove = afterHoursQuote?.afterHoursChangeRate ?? '';
    final afterHoursPositive = _isPositiveMove(afterHoursMove);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentPrice,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '$currentCurrency / $currentKrw',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                _rateDisplay(currentMove),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: positive ? Colors.teal.shade700 : colorScheme.error,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              _SmallBadge(
                label: marketQuoteLiveStatusLabel(liveStatus, liveQuote),
              ),
            ],
          ),
          if (afterHoursQuote != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'After-hours',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  afterHoursQuote.afterHoursLocalCurrencyDisplay,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  afterHoursQuote.afterHoursKrwDisplay,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (afterHoursMove.trim().isNotEmpty)
                  Text(
                    _rateDisplay(afterHoursMove),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: afterHoursPositive
                          ? Colors.teal.shade700
                          : colorScheme.error,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

MarketQuote? _liveQuoteForDetail(StockDetail detail, List<MarketQuote> quotes) {
  return _liveQuoteForStockCode(detail.stockCode, quotes);
}

MarketQuote? _liveQuoteForStockCode(
    String stockCode, List<MarketQuote> quotes) {
  for (final quote in quotes) {
    if (quote.stockCode == stockCode) {
      return quote;
    }
  }
  return null;
}

_ChartCandle? _fallbackCandle(StockDetail detail, MarketQuote? liveQuote) {
  final price = _decimalValue(
    liveQuote?.localCurrencyPrice ?? detail.localCurrencyPrice,
  );
  if (price == null || price <= 0) {
    return null;
  }
  return _ChartCandle(
    at: liveQuote?.marketDataTime ?? detail.marketDataTime ?? DateTime.now(),
    open: price,
    high: price,
    low: price,
    close: price,
    volume: liveQuote?.volume ?? detail.volume,
    currency: liveQuote?.localCurrency ?? detail.displayCurrency,
  );
}

class _DetailTradeActionBar extends StatelessWidget {
  const _DetailTradeActionBar({
    required this.sessionController,
    required this.tradeController,
    required this.detail,
    required this.liveQuote,
  });

  final ExchangeSessionController sessionController;
  final TradeController tradeController;
  final StockDetail detail;
  final MarketQuote? liveQuote;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ExchangeSessionState>(
      valueListenable: sessionController,
      builder: (context, sessionState, child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openOrderSheet(context, 'SELL'),
                  icon: const Icon(Icons.sell_outlined),
                  label: const Text('Sell'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openOrderSheet(context, 'BUY'),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Buy'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openOrderSheet(BuildContext context, String side) {
    if (!sessionController.value.isSignedIn) {
      _showAuthDialog(context, sessionController);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DetailOrderSheet(
        sessionController: sessionController,
        tradeController: tradeController,
        detail: detail,
        liveQuote: liveQuote,
        side: side,
      ),
    );
  }
}

class _DetailOrderSheet extends StatefulWidget {
  const _DetailOrderSheet({
    required this.sessionController,
    required this.tradeController,
    required this.detail,
    required this.liveQuote,
    required this.side,
  });

  final ExchangeSessionController sessionController;
  final TradeController tradeController;
  final StockDetail detail;
  final MarketQuote? liveQuote;
  final String side;

  @override
  State<_DetailOrderSheet> createState() => _DetailOrderSheetState();
}

class _DetailOrderSheetState extends State<_DetailOrderSheet> {
  late final TextEditingController _quantityController;
  late final TextEditingController _limitPriceController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _limitPriceController = TextEditingController(
      text: _defaultOrderPrice(widget.detail, widget.liveQuote),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _limitPriceController.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  double get _limitPrice =>
      double.tryParse(_limitPriceController.text.trim()) ?? 0;

  Future<void> _checkOrderability() async {
    await widget.tradeController.checkOrderability(
      accountId: widget.sessionController.session?.accountId,
      stockCode: widget.detail.stockCode,
      side: widget.side,
      quantity: _quantity,
    );
  }

  Future<void> _submitOrder() async {
    await widget.tradeController.executeTrade(
      accountId: widget.sessionController.session?.accountId,
      stockCode: widget.detail.stockCode,
      side: widget.side,
      quantity: _quantity,
      limitPriceUsd: _limitPrice,
    );
    if (mounted && widget.tradeController.value.errorMessage == null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final isBuy = widget.side == 'BUY';

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, viewInsets.bottom + 16),
      child: ValueListenableBuilder<TradeState>(
        valueListenable: widget.tradeController,
        builder: (context, tradeState, child) {
          final isLoading = tradeState.status == TradeStatus.loading;
          final orderability = tradeState.orderability;
          final canSubmit = !isLoading &&
              (orderability == null || orderability.canPlaceMockOrder);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${isBuy ? 'Buy' : 'Sell'} ${widget.detail.stockName}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Qty',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _limitPriceController,
                      enabled: !isLoading,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Limit ${widget.detail.displayCurrency}',
                      ),
                    ),
                  ),
                ],
              ),
              if (orderability != null) ...[
                const SizedBox(height: 12),
                Text(
                  orderability.summary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: orderability.canPlaceMockOrder
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.error,
                      ),
                ),
              ],
              if (tradeState.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  tradeState.errorMessage!,
                  style: TextStyle(color: colorScheme.error),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : _checkOrderability,
                      child: const Text('Check'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: canSubmit ? _submitOrder : null,
                      child: Text(isBuy ? 'Buy' : 'Sell'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

String _defaultOrderPrice(StockDetail detail, MarketQuote? liveQuote) {
  final parsed = _decimalValue(
    liveQuote?.localCurrencyPrice ?? detail.localCurrencyPrice,
  );
  return (parsed ?? 0).toStringAsFixed(2);
}

class _ForeignOwnershipGaugePanel extends StatelessWidget {
  const _ForeignOwnershipGaugePanel({required this.detail});

  final StockDetail detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ownershipRate = _percentValue(detail.foreignOwnershipRate);
    final limitRate = _percentValue(detail.foreignLimitExhaustionRate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.speed_outlined, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Foreign ownership',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  _SmallBadge(label: detail.foreignOwnershipBaseDate),
                ],
              ),
              const SizedBox(height: 12),
              _GaugeLine(
                key: const ValueKey('foreign-ownership-rate-gauge'),
                label: 'Ownership',
                valueLabel: '${detail.foreignOwnershipRate}%',
                value: ownershipRate,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              _GaugeLine(
                key: const ValueKey('foreign-limit-rate-gauge'),
                label: 'Limit exhaustion',
                valueLabel: '${detail.foreignLimitExhaustionRate}%',
                value: limitRate,
                color: colorScheme.tertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static double _percentValue(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '').trim()) ?? 0.0;
    return (parsed / 100).clamp(0.0, 1.0).toDouble();
  }
}

class _GaugeLine extends StatelessWidget {
  const _GaugeLine({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.color,
  });

  final String label;
  final String valueLabel;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              valueLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _MarketHistoryChartPanel extends StatelessWidget {
  const _MarketHistoryChartPanel({
    required this.chart,
    required this.selectedPeriod,
    required this.livePoints,
    required this.fallbackCandle,
    required this.isLoading,
    required this.onPeriodSelected,
  });

  final MarketChart? chart;
  final String selectedPeriod;
  final List<_LivePricePoint> livePoints;
  final _ChartCandle? fallbackCandle;
  final bool isLoading;
  final ValueChanged<String> onPeriodSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final points = chart?.points ?? const <MarketChartPoint>[];
    final latestPoint = chart?.latestPoint;
    final historySeries = points
        .map(_ChartCandle.fromPoint)
        .whereType<_ChartCandle>()
        .toList(growable: false);
    final liveSeries = _liveCandles(livePoints);
    final mergedSeries = selectedPeriod == '1D' && liveSeries.length >= 2
        ? liveSeries
        : _mergeLiveCandles(historySeries, liveSeries);
    final series = mergedSeries.isNotEmpty
        ? mergedSeries
        : [
            if (fallbackCandle case final candle?) candle,
          ];
    final hasChartData = series.isNotEmpty;
    final minLow = hasChartData
        ? series.map((candle) => candle.low).reduce(math.min)
        : null;
    final maxHigh = hasChartData
        ? series.map((candle) => candle.high).reduce(math.max)
        : null;
    final latestLivePoint = liveSeries.isEmpty ? null : liveSeries.last;
    final displayCurrency =
        latestLivePoint?.currency ?? chart?.displayCurrency ?? 'USD';
    final chartRange = chart;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Price chart',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '1D', label: Text('1D')),
                    ButtonSegment(value: '1W', label: Text('1W')),
                    ButtonSegment(value: '1M', label: Text('1M')),
                  ],
                  selected: {selectedPeriod},
                  onSelectionChanged: isLoading
                      ? null
                      : (selected) => onPeriodSelected(selected.single),
                ),
              ),
              const SizedBox(height: 10),
              if (!hasChartData)
                Text(
                  'Chart data is not available yet.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                )
              else ...[
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: CustomPaint(
                    key: const ValueKey('market-history-candle-volume-chart'),
                    painter: _MarketCandleVolumePainter(
                      candles: series,
                      upColor: Colors.teal.shade700,
                      neutralColor: colorScheme.outline,
                      downColor: colorScheme.error,
                      gridColor: colorScheme.outlineVariant,
                      labelColor: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _Metric(
                      label: 'Latest',
                      value: latestLivePoint == null
                          ? latestPoint?.closeLocalDisplay ??
                              '$displayCurrency ${series.last.close.toStringAsFixed(2)}'
                          : '$displayCurrency ${latestLivePoint.close.toStringAsFixed(2)}',
                    ),
                    _Metric(
                      label: 'KRW close',
                      value: latestPoint?.closeKrwDisplay ?? '-',
                    ),
                    _Metric(
                      label: 'Range',
                      value:
                          '$displayCurrency ${minLow!.toStringAsFixed(2)} - ${maxHigh!.toStringAsFixed(2)}',
                    ),
                    _Metric(
                      label: 'Volume',
                      value:
                          '${latestLivePoint?.volume ?? latestPoint?.volume ?? 0}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (chartRange != null)
                  Text(
                    '${chartRange.from} - ${chartRange.to}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCandle {
  const _ChartCandle({
    required this.at,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.currency,
  });

  final DateTime? at;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;
  final String? currency;

  bool get isUp => close >= open;

  static _ChartCandle? fromPoint(MarketChartPoint point) {
    final open = _decimalValue(point.openLocalCurrencyPrice);
    final high = _decimalValue(point.highLocalCurrencyPrice);
    final low = _decimalValue(point.lowLocalCurrencyPrice);
    final close = _decimalValue(point.closeLocalCurrencyPrice);
    if (open == null || high == null || low == null || close == null) {
      return null;
    }
    return _ChartCandle(
      at: DateTime.tryParse(point.tradeDate),
      open: open,
      high: high,
      low: low,
      close: close,
      volume: point.volume,
      currency: null,
    );
  }

  _ChartCandle mergeLivePoint(_LivePricePoint point) {
    return _ChartCandle(
      at: at,
      open: open,
      high: math.max(high, point.price),
      low: math.min(low, point.price),
      close: point.price,
      volume: math.max(volume, point.volume),
      currency: point.currency,
    );
  }

  _ChartCandle mergeLiveCandle(_ChartCandle candle) {
    return _ChartCandle(
      at: at,
      open: open,
      high: math.max(high, candle.high),
      low: math.min(low, candle.low),
      close: candle.close,
      volume: math.max(volume, candle.volume),
      currency: candle.currency ?? currency,
    );
  }
}

List<_ChartCandle> _liveCandles(List<_LivePricePoint> points) {
  if (points.isEmpty) {
    return const <_ChartCandle>[];
  }
  final candles = <_ChartCandle>[];
  DateTime? currentBucket;
  for (final point in points) {
    final bucket = _minuteBucket(point.at);
    if (currentBucket == null || bucket != currentBucket) {
      currentBucket = bucket;
      candles.add(
        _ChartCandle(
          at: bucket,
          open: point.price,
          high: point.price,
          low: point.price,
          close: point.price,
          volume: point.volume,
          currency: point.currency,
        ),
      );
    } else {
      candles[candles.length - 1] = candles.last.mergeLivePoint(point);
    }
  }
  return candles.length > 48 ? candles.sublist(candles.length - 48) : candles;
}

List<_ChartCandle> _mergeLiveCandles(
  List<_ChartCandle> historySeries,
  List<_ChartCandle> liveSeries,
) {
  if (liveSeries.isEmpty) {
    return historySeries;
  }
  if (historySeries.isEmpty) {
    return liveSeries;
  }

  final merged = List<_ChartCandle>.of(historySeries);
  var current = merged.removeLast();
  for (final liveCandle in liveSeries) {
    current = current.mergeLiveCandle(liveCandle);
  }
  merged.add(current);
  return merged;
}

DateTime _minuteBucket(DateTime at) {
  final utc = at.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day, utc.hour, utc.minute);
}

class _LivePricePoint {
  const _LivePricePoint({
    required this.at,
    required this.price,
    required this.volume,
    required this.currency,
  });

  final DateTime at;
  final double price;
  final int volume;
  final String currency;
}

class _MarketCandleVolumePainter extends CustomPainter {
  const _MarketCandleVolumePainter({
    required this.candles,
    required this.upColor,
    required this.neutralColor,
    required this.downColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<_ChartCandle> candles;
  final Color upColor;
  final Color neutralColor;
  final Color downColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || candles.isEmpty) {
      return;
    }

    final priceHeight = size.height * 0.72;
    final volumeTop = priceHeight + 18;
    final volumeHeight = math.max(size.height - volumeTop, 1.0);
    final gridPaint = Paint()
      ..color = gridColor.withAlpha(150)
      ..strokeWidth = 1;

    final minLow = candles.map((candle) => candle.low).reduce(math.min);
    final maxHigh = candles.map((candle) => candle.high).reduce(math.max);
    final priceRange = math.max(maxHigh - minLow, 0.01);
    final maxVolume = math.max(
      candles.map((candle) => candle.volume).reduce(math.max),
      1,
    );
    final slotWidth = math.min(size.width / math.max(candles.length, 12), 18.0);
    final chartWidth = slotWidth * candles.length;
    final startX = math.max((size.width - chartWidth) / 2, 0.0);
    final bodyWidth = math.max(math.min(slotWidth * 0.58, 8), 3).toDouble();

    double priceY(double price) {
      return priceHeight - ((price - minLow) / priceRange * priceHeight);
    }

    final midY = priceY(candles.last.close);
    _drawDashedLine(
        canvas, Offset(0, midY), Offset(size.width, midY), gridPaint);
    canvas.drawLine(
      Offset(0, volumeTop - 8),
      Offset(size.width, volumeTop - 8),
      gridPaint,
    );

    for (var index = 0; index < candles.length; index += 1) {
      final candle = candles[index];
      final x = startX + slotWidth * index + slotWidth / 2;
      final color = candle.isUp
          ? downColor
          : candle.close < candle.open
              ? Colors.blue.shade600
              : neutralColor;
      final wickPaint = Paint()
        ..color = color.withAlpha(185)
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(x, priceY(candle.high)),
        Offset(x, priceY(candle.low)),
        wickPaint,
      );

      final openY = priceY(candle.open);
      final closeY = priceY(candle.close);
      final top = math.min(openY, closeY).toDouble();
      final height = math.max((openY - closeY).abs(), 2.0).toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - bodyWidth / 2, top, bodyWidth, height),
          const Radius.circular(1.5),
        ),
        Paint()..color = color,
      );

      final volumeRatio = candle.volume / maxVolume;
      final volumeBarHeight = (volumeHeight * volumeRatio).toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - bodyWidth / 2,
            volumeTop + volumeHeight - volumeBarHeight,
            bodyWidth,
            volumeBarHeight,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = color.withAlpha(80),
      );
    }

    _drawPriceLabel(
      canvas,
      label: 'High ${maxHigh.toStringAsFixed(2)}',
      anchor: Offset(8, priceY(maxHigh) - 18),
    );
    _drawPriceLabel(
      canvas,
      label: 'Low ${minLow.toStringAsFixed(2)}',
      anchor: Offset(8, priceY(minLow) + 4),
    );
  }

  @override
  bool shouldRepaint(covariant _MarketCandleVolumePainter oldDelegate) {
    return candles != oldDelegate.candles ||
        upColor != oldDelegate.upColor ||
        neutralColor != oldDelegate.neutralColor ||
        downColor != oldDelegate.downColor ||
        gridColor != oldDelegate.gridColor ||
        labelColor != oldDelegate.labelColor;
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 6.0;
    const gapWidth = 6.0;
    var x = start.dx;
    while (x < end.dx) {
      canvas.drawLine(Offset(x, start.dy),
          Offset(math.min(x + dashWidth, end.dx), end.dy), paint);
      x += dashWidth + gapWidth;
    }
  }

  void _drawPriceLabel(Canvas canvas,
      {required String label, required Offset anchor}) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: labelColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, anchor);
  }
}

class _OrderBookPreview extends StatelessWidget {
  const _OrderBookPreview({required this.orderBook});

  final MarketOrderBook? orderBook;

  @override
  Widget build(BuildContext context) {
    final asks = orderBook?.asks.take(5).toList() ?? const <OrderBookLevel>[];
    final bids = orderBook?.bids.take(5).toList() ?? const <OrderBookLevel>[];
    final colorScheme = Theme.of(context).colorScheme;

    if (orderBook == null) {
      return const _InfoPanel(
        icon: Icons.stacked_line_chart,
        title: 'Order book',
        body: 'Preparing quote levels.',
        meta: '',
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.stacked_bar_chart, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Order book',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  _SmallBadge(label: orderBook!.market),
                ],
              ),
              const SizedBox(height: 12),
              _OrderBookHeader(displayCurrency: orderBook!.displayCurrency),
              ...asks.reversed.map(
                (level) => _OrderBookLevelRow(
                  level: level,
                  side: _OrderBookSide.ask,
                ),
              ),
              Divider(color: colorScheme.outlineVariant, height: 14),
              ...bids.map(
                (level) => _OrderBookLevelRow(
                  level: level,
                  side: _OrderBookSide.bid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _OrderBookSide { ask, bid }

class _OrderBookHeader extends StatelessWidget {
  const _OrderBookHeader({required this.displayCurrency});

  final String displayCurrency;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text('Price ($displayCurrency)', style: style)),
          SizedBox(width: 96, child: Text('KRW', style: style)),
          SizedBox(
            width: 88,
            child: Text('Qty', textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }
}

class _OrderBookLevelRow extends StatelessWidget {
  const _OrderBookLevelRow({
    required this.level,
    required this.side,
  });

  final OrderBookLevel level;
  final _OrderBookSide side;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sideColor =
        side == _OrderBookSide.ask ? colorScheme.error : Colors.teal.shade700;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              level.localCurrencyPrice,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: sideColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          SizedBox(width: 96, child: Text(level.priceKrw)),
          SizedBox(
            width: 88,
            child: Text(
              '${level.quantity}',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.body,
    this.meta = '',
  });

  final IconData icon;
  final String title;
  final String body;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(body),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        meta,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalancePanel extends StatefulWidget {
  const _BalancePanel({
    required this.sessionController,
    required this.accountController,
  });

  final ExchangeSessionController sessionController;
  final AccountController accountController;

  @override
  State<_BalancePanel> createState() => _BalancePanelState();
}

class _BalancePanelState extends State<_BalancePanel> {
  final TextEditingController _amountController =
      TextEditingController(text: '1000.00');

  @override
  void initState() {
    super.initState();
    widget.sessionController.addListener(_loadSignedInAccount);
    _loadSignedInAccount();
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_loadSignedInAccount);
    _amountController.dispose();
    super.dispose();
  }

  void _loadSignedInAccount() {
    final session = widget.sessionController.session;
    if (session != null) {
      widget.accountController.loadAccount(session.accountId);
    } else {
      widget.accountController.clear();
    }
  }

  Future<void> _deposit() async {
    final amount = num.tryParse(_amountController.text.trim());
    await widget.accountController.depositUsd(
      accountId: widget.sessionController.session?.accountId,
      amount: amount ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<ExchangeSessionState>(
      valueListenable: widget.sessionController,
      builder: (context, sessionState, child) {
        return ValueListenableBuilder<AccountState>(
          valueListenable: widget.accountController,
          builder: (context, accountState, child) {
            final isSignedIn = sessionState.isSignedIn;
            final isLoading = accountState.status == AccountStatus.loading;
            final cashDisplay = accountState.account?.cashDisplay ?? 'USD 0.00';
            final ledgerId = accountState.account?.lastLedgerEntryId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.primaryContainer,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('USD cash'),
                                const SizedBox(height: 4),
                                Text(
                                  cashDisplay,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isSignedIn
                                      ? 'Exchange ledger balance.'
                                      : 'Sign in to load your USD account.',
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: isSignedIn && !isLoading
                                ? () => widget.accountController.loadAccount(
                                      sessionState.session?.accountId,
                                    )
                                : null,
                            icon: isLoading
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.sync),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              enabled: isSignedIn && !isLoading,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'USD deposit amount',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed:
                                isSignedIn && !isLoading ? _deposit : null,
                            icon: const Icon(Icons.add),
                            label: const Text('Deposit'),
                          ),
                        ],
                      ),
                      if (ledgerId != null) ...[
                        const SizedBox(height: 8),
                        Text('Last ledger entry $ledgerId'),
                      ],
                      if (accountState.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          accountState.errorMessage!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HoldingsPanel extends StatefulWidget {
  const _HoldingsPanel({
    required this.sessionController,
    required this.tradeController,
  });

  final ExchangeSessionController sessionController;
  final TradeController tradeController;

  @override
  State<_HoldingsPanel> createState() => _HoldingsPanelState();
}

class _HoldingsPanelState extends State<_HoldingsPanel> {
  @override
  void initState() {
    super.initState();
    widget.sessionController.addListener(_loadSignedInPortfolio);
    _loadSignedInPortfolio();
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_loadSignedInPortfolio);
    super.dispose();
  }

  void _loadSignedInPortfolio() {
    final session = widget.sessionController.session;
    if (session != null) {
      widget.tradeController.loadPortfolio(session.accountId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<ExchangeSessionState>(
      valueListenable: widget.sessionController,
      builder: (context, sessionState, child) {
        return ValueListenableBuilder<TradeState>(
          valueListenable: widget.tradeController,
          builder: (context, tradeState, child) {
            final isSignedIn = sessionState.isSignedIn;
            final isLoading = tradeState.status == TradeStatus.loading;
            final portfolio = tradeState.portfolio;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Holdings',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: isSignedIn && !isLoading
                                ? () => widget.tradeController.loadPortfolio(
                                      sessionState.session?.accountId,
                                    )
                                : () => _showAuthDialog(
                                      context,
                                      widget.sessionController,
                                    ),
                            icon: isLoading
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(isSignedIn ? Icons.sync : Icons.login),
                            label: Text(isSignedIn ? 'Refresh' : 'Sign in'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _TradeMetricStrip(portfolio: portfolio),
                      const SizedBox(height: 12),
                      if (!isSignedIn)
                        const Text('Sign in to view your holdings.')
                      else if (portfolio == null)
                        const Text('Portfolio loads from Stock-exchange-BE.')
                      else if (portfolio.holdings.isEmpty)
                        const Text('No held stocks yet.')
                      else
                        ...portfolio.holdings.map(_HoldingRow.new),
                      if (tradeState.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          tradeState.errorMessage!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TradeHistoryPanel extends StatefulWidget {
  const _TradeHistoryPanel({
    required this.sessionController,
    required this.tradeController,
  });

  final ExchangeSessionController sessionController;
  final TradeController tradeController;

  @override
  State<_TradeHistoryPanel> createState() => _TradeHistoryPanelState();
}

class _TradeHistoryPanelState extends State<_TradeHistoryPanel> {
  @override
  void initState() {
    super.initState();
    widget.sessionController.addListener(_loadSignedInHistory);
    _loadSignedInHistory();
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_loadSignedInHistory);
    super.dispose();
  }

  void _loadSignedInHistory() {
    final session = widget.sessionController.session;
    if (session != null) {
      widget.tradeController.loadTradeHistory(session.accountId);
      widget.tradeController.loadOrderHistory(session.accountId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<ExchangeSessionState>(
      valueListenable: widget.sessionController,
      builder: (context, sessionState, child) {
        return ValueListenableBuilder<TradeState>(
          valueListenable: widget.tradeController,
          builder: (context, tradeState, child) {
            final isSignedIn = sessionState.isSignedIn;
            final isLoading = tradeState.status == TradeStatus.loading;
            final trades = tradeState.tradeHistory.isNotEmpty
                ? tradeState.tradeHistory
                : tradeState.portfolio?.recentTrades ??
                    const <TradeExecution>[];
            final orders = tradeState.orderHistory;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Orders and fills',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: isSignedIn && !isLoading
                                ? () {
                                    widget.tradeController.loadTradeHistory(
                                      sessionState.session?.accountId,
                                    );
                                    widget.tradeController.loadOrderHistory(
                                      sessionState.session?.accountId,
                                    );
                                  }
                                : () => _showAuthDialog(
                                      context,
                                      widget.sessionController,
                                    ),
                            icon: isLoading
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(isSignedIn ? Icons.sync : Icons.login),
                            label: Text(isSignedIn ? 'Refresh' : 'Sign in'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!isSignedIn)
                        const Text('Sign in to view orders and fills.')
                      else if (orders.isEmpty && trades.isEmpty)
                        const Text('No order record yet.')
                      else ...[
                        ...orders.map(_TradeOrderRow.new),
                        ...trades.map(_TradeLedgerRow.new),
                      ],
                      if (tradeState.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          tradeState.errorMessage!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MockTradePanel extends StatefulWidget {
  const _MockTradePanel({
    required this.sessionController,
    required this.tradeController,
  });

  final ExchangeSessionController sessionController;
  final TradeController tradeController;

  @override
  State<_MockTradePanel> createState() => _MockTradePanelState();
}

class _MockTradePanelState extends State<_MockTradePanel> {
  final TextEditingController _stockCodeController =
      TextEditingController(text: '005930');
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final TextEditingController _limitPriceController =
      TextEditingController(text: '50.00');
  String _side = 'BUY';

  @override
  void initState() {
    super.initState();
    widget.sessionController.addListener(_loadSignedInPortfolio);
    _loadSignedInPortfolio();
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_loadSignedInPortfolio);
    _stockCodeController.dispose();
    _quantityController.dispose();
    _limitPriceController.dispose();
    super.dispose();
  }

  void _loadSignedInPortfolio() {
    final session = widget.sessionController.session;
    if (session != null) {
      widget.tradeController.loadPortfolio(session.accountId);
    }
  }

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  double get _limitPrice =>
      double.tryParse(_limitPriceController.text.trim()) ?? 0;

  Future<void> _checkOrderability() async {
    await widget.tradeController.checkOrderability(
      accountId: widget.sessionController.session?.accountId,
      stockCode: _stockCodeController.text.trim(),
      side: _side,
      quantity: _quantity,
    );
    if (!mounted) {
      return;
    }
    final orderability = widget.tradeController.value.orderability;
    if (orderability == null ||
        (orderability.canPlaceMockOrder && orderability.warnings.isEmpty)) {
      return;
    }
    await _showOrderabilityDialog(orderability);
  }

  Future<void> _executeTrade() {
    return widget.tradeController.executeTrade(
      accountId: widget.sessionController.session?.accountId,
      stockCode: _stockCodeController.text.trim(),
      side: _side,
      quantity: _quantity,
      limitPriceUsd: _limitPrice,
    );
  }

  Future<void> _showOrderabilityDialog(TradeOrderability orderability) {
    final isBlocked = !orderability.canPlaceMockOrder;
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(isBlocked ? Icons.block : Icons.warning_amber_outlined),
          title: Text(isBlocked ? 'Mock order blocked' : 'Mock order warning'),
          content: Text(orderability.summary),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<ExchangeSessionState>(
      valueListenable: widget.sessionController,
      builder: (context, sessionState, child) {
        return ValueListenableBuilder<TradeState>(
          valueListenable: widget.tradeController,
          builder: (context, tradeState, child) {
            final isSignedIn = sessionState.isSignedIn;
            final isLoading = tradeState.status == TradeStatus.loading;
            final orderability = tradeState.orderability;
            final portfolio = tradeState.portfolio;
            final canExecute = isSignedIn &&
                !isLoading &&
                (orderability?.canPlaceMockOrder ?? true);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mock order pad',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Exchange mock ledger only. No KIS order is sent.',
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: isSignedIn && !isLoading
                                ? () => widget.tradeController.loadPortfolio(
                                      sessionState.session?.accountId,
                                    )
                                : null,
                            icon: const Icon(Icons.account_balance_wallet),
                            label: const Text('Portfolio'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'BUY', label: Text('BUY')),
                          ButtonSegment(value: 'SELL', label: Text('SELL')),
                        ],
                        selected: {_side},
                        onSelectionChanged: isLoading
                            ? null
                            : (selected) {
                                setState(() {
                                  _side = selected.single;
                                });
                              },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _stockCodeController,
                              enabled: isSignedIn && !isLoading,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Stock code',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _quantityController,
                              enabled: isSignedIn && !isLoading,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Qty',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 140,
                            child: TextField(
                              controller: _limitPriceController,
                              enabled: isSignedIn && !isLoading,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Limit USD',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: isSignedIn && !isLoading
                                ? _checkOrderability
                                : null,
                            icon: const Icon(Icons.rule),
                            label: const Text('Check orderability'),
                          ),
                          FilledButton.icon(
                            onPressed: canExecute ? _executeTrade : null,
                            icon: isLoading
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.receipt_long),
                            label: const Text('Place mock order'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _TradeMetricStrip(portfolio: portfolio),
                      if (orderability != null) ...[
                        const SizedBox(height: 12),
                        _InfoPanel(
                          icon: orderability.canPlaceMockOrder
                              ? Icons.check_circle_outline
                              : Icons.block,
                          title: 'Orderability',
                          body: orderability.summary,
                          meta:
                              '${orderability.orderabilitySource} / ${orderability.tradingMode}',
                        ),
                      ],
                      if (tradeState.lastOrder != null) ...[
                        const SizedBox(height: 12),
                        _InfoPanel(
                          icon: tradeState.lastOrder!.isFilled
                              ? Icons.receipt_long
                              : Icons.pending_actions,
                          title: tradeState.lastOrder!.isFilled
                              ? 'Last filled order'
                              : 'Last pending order',
                          body: tradeState.lastOrder!.summary,
                          meta: tradeState.lastOrder!.message,
                        ),
                      ],
                      if (portfolio != null &&
                          portfolio.holdings.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...portfolio.holdings.take(3).map(_HoldingRow.new),
                      ],
                      if (portfolio != null) ...[
                        const SizedBox(height: 12),
                        _RealizedPnlPanel(portfolio: portfolio),
                      ],
                      if (tradeState.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          tradeState.errorMessage!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TradeMetricStrip extends StatelessWidget {
  const _TradeMetricStrip({required this.portfolio});

  final PortfolioSnapshot? portfolio;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _Metric(
          label: 'Cash',
          value: 'USD ${portfolio?.cashBalanceUsd ?? '0.00'}',
        ),
        _Metric(
          label: 'Market value',
          value: 'USD ${portfolio?.totalMarketValueUsd ?? '0.00'}',
        ),
        _Metric(
          label: 'Realized PnL',
          value: 'USD ${portfolio?.realizedPnlUsd ?? '0.00'}',
        ),
        _Metric(
          label: 'Unrealized PnL',
          value: 'USD ${portfolio?.unrealizedPnlUsd ?? '0.00'}',
        ),
      ],
    );
  }
}

class _RealizedPnlPanel extends StatelessWidget {
  const _RealizedPnlPanel({required this.portfolio});

  final PortfolioSnapshot portfolio;

  @override
  Widget build(BuildContext context) {
    final sellTrades =
        portfolio.recentTrades.where((trade) => trade.isSell).take(3).toList();

    if (sellTrades.isEmpty) {
      return _InfoPanel(
        icon: Icons.receipt_long_outlined,
        title: 'Sell trades and realized PnL',
        body: 'No sell trade has realized profit or loss yet.',
        meta: 'Tax refund input waits for a completed sell trade.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoPanel(
          icon: Icons.request_quote_outlined,
          title: 'Sell trades and realized PnL',
          body:
              'Portfolio realized PnL USD ${portfolio.realizedPnlUsd} feeds tax refund input.',
          meta: 'Recent sell trades are from the Stock-exchange-BE ledger.',
        ),
        ...sellTrades.map(_SellTradeRow.new),
      ],
    );
  }
}

class _SellTradeRow extends StatelessWidget {
  const _SellTradeRow(this.trade);

  final TradeExecution trade;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      icon: Icons.trending_up,
      title: 'Realized sell trade',
      body: '${trade.stockName} ${trade.quantity} shares / '
          'realized PnL ${trade.realizedPnlDisplay}',
      meta: '${trade.tradeId} / gross USD ${trade.grossAmountUsd} / '
          'remaining ${trade.remainingQuantity}',
    );
  }
}

class _TradeLedgerRow extends StatelessWidget {
  const _TradeLedgerRow(this.trade);

  final TradeExecution trade;

  @override
  Widget build(BuildContext context) {
    final isSell = trade.isSell;
    return _InfoPanel(
      icon: isSell ? Icons.sell_outlined : Icons.add_shopping_cart,
      title: '${trade.side} ${trade.stockName}',
      body:
          '${trade.quantity} shares at USD ${trade.executionPriceUsd} / gross USD ${trade.grossAmountUsd}',
      meta:
          '${trade.tradeId} / realized ${trade.realizedPnlDisplay} / cash after USD ${trade.cashBalanceUsdAfter}',
    );
  }
}

class _TradeOrderRow extends StatelessWidget {
  const _TradeOrderRow(this.order);

  final TradeOrderPlacement order;

  @override
  Widget build(BuildContext context) {
    final isSell = order.side.toUpperCase() == 'SELL';
    return _InfoPanel(
      icon: order.isFilled
          ? Icons.check_circle_outline
          : Icons.pending_actions_outlined,
      title: '${order.status} ${order.side} ${order.stockName}',
      body:
          '${order.quantity} shares / limit USD ${order.limitPriceUsd} / last USD ${order.observedPriceUsd}',
      meta:
          '${order.orderId} / ${isSell ? 'sell' : 'buy'} limit order / ${order.message}',
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow(this.holding);

  final MockHolding holding;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      icon: Icons.inventory_2_outlined,
      title: holding.stockName,
      body:
          '${holding.quantity} shares / avg USD ${holding.averagePriceUsd} / current USD ${holding.currentPriceUsd}',
      meta:
          'Value USD ${holding.marketValueUsd} / Unrealized USD ${holding.unrealizedPnlUsd} (${holding.unrealizedPnlRate}%)',
    );
  }
}

class _WalletBadge extends StatelessWidget {
  const _WalletBadge({required this.accountController});

  final AccountController accountController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccountState>(
      valueListenable: accountController,
      builder: (context, accountState, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 16),
                const SizedBox(width: 6),
                Text(accountState.account?.cashDisplay ?? 'USD 0.00'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.tabular = false,
  });

  final String label;
  final String value;
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures:
                    tabular ? const [FontFeature.tabularFigures()] : null,
              ),
        ),
      ],
    );
  }
}
