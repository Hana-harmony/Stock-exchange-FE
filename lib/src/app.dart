import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/exchange_api_client.dart';
import 'core/exchange_session_controller.dart';
import 'core/market_quote_controller.dart';
import 'core/market_quote_live_client.dart';

class StockExchangeApp extends StatelessWidget {
  const StockExchangeApp({
    super.key,
    this.sessionController,
    this.marketQuoteController,
    this.watchlistQuoteController,
    this.portfolioQuoteController,
  });

  final ExchangeSessionController? sessionController;
  final MarketQuoteController? marketQuoteController;
  final MarketQuoteController? watchlistQuoteController;
  final MarketQuoteController? portfolioQuoteController;

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
        marketQuoteController: marketQuoteController,
        watchlistQuoteController: watchlistQuoteController,
        portfolioQuoteController: portfolioQuoteController,
      ),
    );
  }
}

class ExchangeShell extends StatefulWidget {
  const ExchangeShell({
    super.key,
    this.sessionController,
    this.marketQuoteController,
    this.watchlistQuoteController,
    this.portfolioQuoteController,
  });

  final ExchangeSessionController? sessionController;
  final MarketQuoteController? marketQuoteController;
  final MarketQuoteController? watchlistQuoteController;
  final MarketQuoteController? portfolioQuoteController;

  @override
  State<ExchangeShell> createState() => _ExchangeShellState();
}

class _ExchangeShellState extends State<ExchangeShell> {
  int _selectedIndex = 0;
  http.Client? _ownedHttpClient;
  late final ExchangeEnvironment _environment;
  late final ExchangeApiClient _apiClient;
  late final ExchangeSessionController _sessionController;
  late final MarketQuoteController _marketQuoteController;
  late final MarketQuoteController _watchlistQuoteController;
  late final MarketQuoteController _portfolioQuoteController;

  @override
  void initState() {
    super.initState();
    _environment = const ExchangeEnvironment();
    _apiClient = _createApiClient();
    _sessionController = widget.sessionController ?? _createSessionController();
    _marketQuoteController =
        widget.marketQuoteController ?? _createMarketQuoteController();
    _watchlistQuoteController =
        widget.watchlistQuoteController ?? _createAccountQuoteController();
    _portfolioQuoteController =
        widget.portfolioQuoteController ?? _createAccountQuoteController();
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
      sessionStore: MemoryExchangeSessionStore(),
    );
  }

  MarketQuoteController _createMarketQuoteController() {
    return MarketQuoteController(
      apiClient: _apiClient,
      liveClient: MarketQuoteLiveClient(baseUri: _environment.apiBaseUri),
      seedQuotes: seedMarketQuotes,
    );
  }

  MarketQuoteController _createAccountQuoteController() {
    return MarketQuoteController(
      apiClient: _apiClient,
      liveClient: MarketQuoteLiveClient(baseUri: _environment.apiBaseUri),
    );
  }

  @override
  void dispose() {
    if (widget.sessionController == null) {
      _sessionController.dispose();
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
    _ownedHttpClient?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hana Local Exchange'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: _WalletBadge(),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            MarketScreen(
              sessionController: _sessionController,
              marketQuoteController: _marketQuoteController,
            ),
            PortfolioScreen(
              sessionController: _sessionController,
              watchlistQuoteController: _watchlistQuoteController,
              portfolioQuoteController: _portfolioQuoteController,
            ),
            const AlertsScreen(),
            const TaxScreen(),
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

class MarketScreen extends StatelessWidget {
  const MarketScreen({
    super.key,
    required this.sessionController,
    required this.marketQuoteController,
  });

  final ExchangeSessionController sessionController;
  final MarketQuoteController marketQuoteController;

  @override
  Widget build(BuildContext context) {
    return _ScreenFrame(
      title: 'Korea Market',
      subtitle: 'Live KRX quotes with KRW and USD pricing.',
      children: [
        _SessionStatusPanel(sessionController: sessionController),
        const _SearchField(),
        const _MarketFilters(),
        _QuoteSnapshotPanel(marketQuoteController: marketQuoteController),
      ],
    );
  }
}

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({
    super.key,
    required this.sessionController,
    required this.watchlistQuoteController,
    required this.portfolioQuoteController,
  });

  final ExchangeSessionController sessionController;
  final MarketQuoteController watchlistQuoteController;
  final MarketQuoteController portfolioQuoteController;

  @override
  Widget build(BuildContext context) {
    return _ScreenFrame(
      title: 'Portfolio',
      subtitle: 'Mock USD trading ledger. No real order is sent.',
      children: [
        _SessionStatusPanel(sessionController: sessionController),
        const _BalancePanel(),
        _AccountQuoteSnapshotPanel(
          title: 'Portfolio quote snapshot',
          emptyTitle: 'No holdings quotes',
          emptyBody: 'No holding quote snapshot is available yet.',
          marketQuoteController: portfolioQuoteController,
          sessionController: sessionController,
          accountScope: MarketQuoteAccountScope.portfolio,
          onRefresh: (accountId) => portfolioQuoteController.loadPortfolioSnapshot(
            accountId: accountId,
          ),
        ),
        _AccountQuoteSnapshotPanel(
          title: 'Watchlist quote snapshot',
          emptyTitle: 'No watchlist quotes',
          emptyBody: 'No watchlist quote snapshot is available yet.',
          marketQuoteController: watchlistQuoteController,
          sessionController: sessionController,
          accountScope: MarketQuoteAccountScope.watchlist,
          onRefresh: (accountId) => watchlistQuoteController.loadWatchlistSnapshot(
            accountId: accountId,
          ),
        ),
        _InfoPanel(
          icon: Icons.point_of_sale,
          title: 'Mock USD cash',
          body: 'Deposit, buy, and sell actions update only the exchange ledger.',
          meta: 'Available cash USD 12,450.00',
        ),
      ],
    );
  }
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ScreenFrame(
      title: 'Alerts',
      subtitle: 'AI translated news and disclosures for your stocks.',
      children: [
        _AlertFilters(),
        _InfoPanel(
          icon: Icons.article_outlined,
          title: 'Samsung disclosure translated',
          body: 'AI summary, sentiment, importance, and event tags appear here.',
          meta: 'Original link / My Portfolio / High importance',
        ),
        _InfoPanel(
          icon: Icons.link,
          title: 'K-News timeline',
          body: 'Watchlist and portfolio filters keep real-time push alerts focused.',
          meta: 'All / My Portfolio / Watchlist',
        ),
      ],
    );
  }
}

class TaxScreen extends StatelessWidget {
  const TaxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ScreenFrame(
      title: 'Tax Refund',
      subtitle: 'Document status, refund estimate, and recapture risk.',
      children: [
        _InfoPanel(
          icon: Icons.upload_file_outlined,
          title: 'Documents',
          body: 'Certificate of residence and tax treaty forms are tracked here.',
          meta: 'Submitted / Verification pending',
        ),
        _InfoPanel(
          icon: Icons.payments_outlined,
          title: 'Refund estimate',
          body: 'Realized gains from mock sell history feed the refund input data.',
          meta: 'Estimated refund USD 84.30',
        ),
        _InfoPanel(
          icon: Icons.warning_amber_outlined,
          title: 'Recapture risk',
          body: 'Advance refund completion includes a clear post-review risk notice.',
          meta: 'Risk notice required before advance payment',
        ),
      ],
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
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: SearchBar(
        leading: Icon(Icons.search),
        hintText: 'Search all Korean stocks',
      ),
    );
  }
}

class _MarketFilters extends StatelessWidget {
  const _MarketFilters();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(label: Text('All'), selected: true),
          ChoiceChip(label: Text('KOSPI'), selected: false),
          ChoiceChip(label: Text('KOSDAQ'), selected: false),
          ChoiceChip(label: Text('Watchlist'), selected: false),
          ChoiceChip(label: Text('Portfolio'), selected: false),
        ],
      ),
    );
  }
}

class _AlertFilters extends StatelessWidget {
  const _AlertFilters();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(label: Text('All'), selected: true),
          ChoiceChip(label: Text('My Portfolio'), selected: false),
          ChoiceChip(label: Text('Watchlist'), selected: false),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatusChip(icon: Icons.wifi_tethering, label: 'WebSocket live'),
          _StatusChip(icon: Icons.sync, label: 'REST snapshot ready'),
          _StatusChip(icon: Icons.schedule, label: 'No stale ticks'),
        ],
      ),
    );
  }
}

class _QuoteSnapshotPanel extends StatelessWidget {
  const _QuoteSnapshotPanel({required this.marketQuoteController});

  final MarketQuoteController marketQuoteController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MarketQuoteState>(
      valueListenable: marketQuoteController,
      builder: (context, quoteState, child) {
        final snapshot = quoteState.snapshot;
        final firstQuote =
            quoteState.quotes.isNotEmpty ? quoteState.quotes.first : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QuoteSnapshotActions(
              quoteState: quoteState,
              onRefresh: () => marketQuoteController.loadSnapshot(),
              onStartLive: () => marketQuoteController.subscribeLive(),
              onStopLive: () => marketQuoteController.unsubscribeLive(),
            ),
            const _StatusStrip(),
            _InfoPanel(
              icon: Icons.currency_exchange,
              title: 'FX applied',
              body: snapshot == null
                  ? 'USD prices use the latest KRW/USD rate from Stock-exchange-BE.'
                  : '${snapshot.quoteCount} quotes from ${snapshot.dataSource}.',
              meta: firstQuote?.fxMeta ??
                  'FX pending / source Stock-exchange-BE snapshot',
            ),
            if (quoteState.errorMessage != null)
              _InfoPanel(
                icon: Icons.error_outline,
                title: 'Snapshot unavailable',
                body: quoteState.errorMessage!,
                meta: 'Keeping the latest visible quote list on screen.',
              ),
            if (quoteState.quotes.isEmpty)
              const _InfoPanel(
                icon: Icons.search_off,
                title: 'No quotes',
                body: 'No Korean stock quote snapshot is available yet.',
                meta: 'Use REST snapshot refresh after the backend is running.',
              )
            else
              ...quoteState.quotes.map(_QuoteRow.fromMarketQuote),
          ],
        );
      },
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
            final isConnecting =
                quoteState.liveStatus == MarketQuoteLiveStatus.connecting;
            final isLive = quoteState.liveStatus == MarketQuoteLiveStatus.live;
            final snapshot = quoteState.snapshot;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AccountQuoteSnapshotActions(
                  title: title,
                  isSignedIn: isSignedIn,
                  isLoading: isLoading,
                  isConnecting: isConnecting,
                  isLive: isLive,
                  cacheStatus: snapshot?.cacheStatus ?? 'idle',
                  onRefresh: isLoading ? null : () => onRefresh(accountId),
                  onStartLive: isSignedIn && !isConnecting
                      ? () => marketQuoteController.subscribeLive(
                            accountId: accountId,
                            accountScope: accountScope,
                          )
                      : null,
                  onStopLive: isLive
                      ? () => marketQuoteController.unsubscribeLive()
                      : null,
                ),
                if (quoteState.liveMessage != null)
                  _InfoPanel(
                    icon: Icons.wifi_tethering,
                    title: 'Account live stream',
                    body: quoteState.liveMessage!,
                    meta: isSignedIn
                        ? 'Stock-exchange-BE account quote WebSocket topic'
                        : 'Sign in before opening account WebSocket topic.',
                  ),
                if (quoteState.errorMessage != null)
                  _InfoPanel(
                    icon: Icons.error_outline,
                    title: 'Snapshot unavailable',
                    body: quoteState.errorMessage!,
                    meta: 'Account scoped quote snapshot uses bearer auth.',
                  ),
                if (quoteState.quotes.isEmpty)
                  _InfoPanel(
                    icon: Icons.list_alt_outlined,
                    title: emptyTitle,
                    body: isSignedIn ? emptyBody : 'Sign in to load this account scope.',
                    meta: snapshot == null
                        ? 'REST snapshot pending'
                        : '${snapshot.quoteCount} quotes from ${snapshot.dataSource}',
                  )
                else
                  ...quoteState.quotes.map(_QuoteRow.fromMarketQuote),
              ],
            );
          },
        );
      },
    );
  }
}

class _AccountQuoteSnapshotActions extends StatelessWidget {
  const _AccountQuoteSnapshotActions({
    required this.title,
    required this.isSignedIn,
    required this.isLoading,
    required this.isConnecting,
    required this.isLive,
    required this.cacheStatus,
    required this.onRefresh,
    required this.onStartLive,
    required this.onStopLive,
  });

  final String title;
  final bool isSignedIn;
  final bool isLoading;
  final bool isConnecting;
  final bool isLive;
  final String cacheStatus;
  final VoidCallback? onRefresh;
  final VoidCallback? onStartLive;
  final VoidCallback? onStopLive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
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
                    const SizedBox(height: 4),
                    Text(isSignedIn
                        ? 'Cache $cacheStatus / account REST + WebSocket'
                        : 'Sign in required / account REST + WebSocket'),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: isLive ? onStopLive : onStartLive,
                    icon: isConnecting
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isLive ? Icons.wifi_off : Icons.wifi_tethering),
                    label: Text(isLive ? 'Stop' : 'Start live'),
                  ),
                  FilledButton.icon(
                    onPressed: isSignedIn && !isLoading ? onRefresh : null,
                    icon: isLoading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteSnapshotActions extends StatelessWidget {
  const _QuoteSnapshotActions({
    required this.quoteState,
    required this.onRefresh,
    required this.onStartLive,
    required this.onStopLive,
  });

  final MarketQuoteState quoteState;
  final VoidCallback onRefresh;
  final VoidCallback onStartLive;
  final VoidCallback onStopLive;

  @override
  Widget build(BuildContext context) {
    final isLoading = quoteState.status == MarketQuoteStatus.loading;
    final isConnecting =
        quoteState.liveStatus == MarketQuoteLiveStatus.connecting;
    final isLive = quoteState.liveStatus == MarketQuoteLiveStatus.live;
    final snapshot = quoteState.snapshot;
    final cacheStatus = snapshot?.cacheStatus ?? 'seed';
    final transport = snapshot == null
        ? 'REST snapshot / WebSocket later'
        : '${snapshot.transportSnapshot} snapshot / ${snapshot.transportRealtime} live';
    final liveLabel = switch (quoteState.liveStatus) {
      MarketQuoteLiveStatus.disconnected => 'WebSocket disconnected',
      MarketQuoteLiveStatus.connecting => 'WebSocket connecting',
      MarketQuoteLiveStatus.live => 'WebSocket live',
      MarketQuoteLiveStatus.failure => 'WebSocket unavailable',
    };
    final liveMessage = quoteState.liveMessage ?? liveLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REST quote snapshot',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text('Cache $cacheStatus / $transport'),
                    const SizedBox(height: 4),
                    Text(liveMessage),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: isLive
                        ? quoteState.status == MarketQuoteStatus.loading
                            ? null
                            : onStopLive
                        : isConnecting
                            ? null
                            : onStartLive,
                    icon: isConnecting
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isLive ? Icons.wifi_off : Icons.wifi_tethering),
                    label: Text(isLive ? 'Stop' : 'Start live'),
                  ),
                  FilledButton.icon(
                    onPressed: isLoading ? null : onRefresh,
                    icon: isLoading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
    required this.symbol,
    required this.name,
    required this.priceKrw,
    required this.priceUsd,
    required this.change,
    required this.badge,
  });

  factory _QuoteRow.fromMarketQuote(MarketQuote quote) {
    return _QuoteRow(
      symbol: quote.stockCode,
      name: quote.stockName,
      priceKrw: quote.krwDisplay,
      priceUsd: quote.localCurrencyDisplay,
      change: quote.changeRate,
      badge: quote.badge,
    );
  }

  final String symbol;
  final String name;
  final String priceKrw;
  final String priceUsd;
  final String change;
  final String badge;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  _SmallBadge(label: badge),
                ],
              ),
              const SizedBox(height: 6),
              Text(symbol),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _Metric(label: 'KRW', value: priceKrw),
                  _Metric(label: 'USD', value: priceUsd),
                  _Metric(label: 'Move', value: change),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.body,
    required this.meta,
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
                    const SizedBox(height: 8),
                    Text(
                      meta,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
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

class _BalancePanel extends StatelessWidget {
  const _BalancePanel();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.primaryContainer,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mock USD cash'),
                    SizedBox(height: 4),
                    Text(
                      'USD 12,450.00',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add),
                label: const Text('Deposit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletBadge extends StatelessWidget {
  const _WalletBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 16),
            SizedBox(width: 6),
            Text('USD 12,450'),
          ],
        ),
      ),
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
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

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
              ),
        ),
      ],
    );
  }
}
