part of '../exchange_pages.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({
    super.key,
    required this.sessionController,
    required this.watchlistController,
    required this.marketDetailController,
    required this.marketQuoteController,
    required this.tradeController,
    required this.notificationController,
    required this.onFavoriteChanged,
    required this.onSignInTap,
    this.onNavigateToAccounts,
    this.nowProvider,
  });

  final ExchangeSessionController sessionController;
  final WatchlistController watchlistController;
  final MarketDetailController marketDetailController;
  final MarketQuoteController marketQuoteController;
  final TradeController tradeController;
  final NotificationController notificationController;
  final Future<bool> Function(String stockCode, bool nextIsFavorite)
      onFavoriteChanged;
  final VoidCallback onSignInTap;
  final VoidCallback? onNavigateToAccounts;
  final DateTime Function()? nowProvider;

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  String? _requestedAccountId;

  @override
  void initState() {
    super.initState();
    widget.sessionController.addListener(_ensureWatchlistLoaded);
    widget.watchlistController.addListener(_handleWatchlistChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureWatchlistLoaded();
    });
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_ensureWatchlistLoaded);
    widget.watchlistController.removeListener(_handleWatchlistChanged);
    widget.marketQuoteController.unsubscribeLive();
    super.dispose();
  }

  void _ensureWatchlistLoaded() {
    final accountId = widget.sessionController.session?.accountId;
    if (accountId == null || accountId.isEmpty) {
      _requestedAccountId = null;
      widget.watchlistController.clear();
      return;
    }
    if (accountId == _requestedAccountId) {
      return;
    }
    _requestedAccountId = accountId;
    unawaited(widget.watchlistController.load(accountId));
  }

  void _handleWatchlistChanged() {
    final accountId = widget.sessionController.session?.accountId;
    if (accountId == null || accountId.isEmpty) {
      return;
    }
    if (widget.watchlistController.value.status == WatchlistStatus.loaded) {
      unawaited(
        widget.marketQuoteController.loadWatchlistSnapshot(
          accountId: accountId,
          currency: 'USD',
        ),
      );
      unawaited(
        widget.marketQuoteController.subscribeLive(
          accountId: accountId,
          accountScope: MarketQuoteAccountScope.watchlist,
        ),
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.sessionController,
        widget.watchlistController,
        widget.marketQuoteController,
      ]),
      builder: (context, _) {
        final session = widget.sessionController.session;
        if (session == null) {
          return _WatchlistSignedOutState(onSignInTap: widget.onSignInTap);
        }

        final watchlistState = widget.watchlistController.value;
        final items =
            watchlistState.watchlist?.items ?? const <WatchlistItem>[];
        final quotesByCode = {
          for (final quote in widget.marketQuoteController.value.quotes)
            quote.stockCode: quote,
        };

        if (watchlistState.status == WatchlistStatus.loading && items.isEmpty) {
          return const _WatchlistLoadingState();
        }

        if (items.isEmpty) {
          return _WatchlistEmptyState(
            errorMessage: watchlistState.errorMessage,
            onRefresh: () => widget.watchlistController.load(session.accountId),
          );
        }

        return RefreshIndicator(
          color: AppColors.orange500,
          onRefresh: () => widget.watchlistController.load(session.accountId),
          child: ListView.separated(
            key: const ValueKey('watchlist-screen'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: items.length + 1,
            separatorBuilder: (_, index) =>
                index == 0 ? const SizedBox(height: 12) : const Divider(),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _WatchlistSummaryCard(
                  itemCount: items.length,
                  liveStatus: widget.marketQuoteController.value.liveStatus,
                );
              }
              final item = items[index - 1];
              final quote = quotesByCode[item.stockCode];
              return _WatchlistItemTile(
                item: item,
                quote: quote,
                onTap: () => _openStock(item),
                onRemove: () => widget.onFavoriteChanged(
                  item.stockCode,
                  false,
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openStock(WatchlistItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StockDetailScreen(
          sessionController: widget.sessionController,
          tradeController: widget.tradeController,
          marketDetailController: widget.marketDetailController,
          marketQuoteController: widget.marketQuoteController,
          notificationController: widget.notificationController,
          stockCode: item.stockCode,
          title: item.stockName,
          market: item.market,
          isFavorite: true,
          onFavoriteChanged: widget.onFavoriteChanged,
          onNavigateToAccounts: widget.onNavigateToAccounts,
          nowProvider: widget.nowProvider,
        ),
      ),
    );
  }
}

class _WatchlistSignedOutState extends StatelessWidget {
  const _WatchlistSignedOutState({required this.onSignInTap});

  final VoidCallback onSignInTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppInsets.compactScreen,
      children: [
        const _MutedInfoCard(
          title: 'Sign in required',
          body: 'Sign in to sync your saved stocks across devices.',
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: FilledButton(
            key: const ValueKey('watchlist-sign-in-button'),
            onPressed: onSignInTap,
            style: _exchangePrimaryButtonStyle(
              backgroundColor: AppColors.orange500,
              radius: 8,
            ),
            child: const Text('Sign in'),
          ),
        ),
      ],
    );
  }
}

class _WatchlistLoadingState extends StatelessWidget {
  const _WatchlistLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppInsets.compactScreen,
      children: const [
        _MutedInfoCard(
          title: 'Loading watchlist',
          body: 'Loading your saved stocks.',
        ),
      ],
    );
  }
}

class _WatchlistEmptyState extends StatelessWidget {
  const _WatchlistEmptyState({
    required this.errorMessage,
    required this.onRefresh,
  });

  final String? errorMessage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppInsets.compactScreen,
      children: [
        _MutedInfoCard(
          title: 'No watchlist stocks',
          body: errorMessage ??
              'Tap the heart on a stock detail page to add it here.',
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('watchlist-refresh-button'),
            onPressed: onRefresh,
            style: _exchangePrimaryButtonStyle(
              backgroundColor: AppColors.orange500,
            ),
            child: const Text('Try again'),
          ),
        ],
      ],
    );
  }
}

class _WatchlistSummaryCard extends StatelessWidget {
  const _WatchlistSummaryCard({
    required this.itemCount,
    required this.liveStatus,
  });

  final int itemCount;
  final MarketQuoteLiveStatus liveStatus;

  @override
  Widget build(BuildContext context) {
    final liveLabel = liveStatus == MarketQuoteLiveStatus.live ? ' · Live' : '';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Watchlist',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text('$itemCount stocks$liveLabel'),
          ],
        ),
      ),
    );
  }
}

class _WatchlistItemTile extends StatelessWidget {
  const _WatchlistItemTile({
    required this.item,
    required this.quote,
    required this.onTap,
    required this.onRemove,
  });

  final WatchlistItem item;
  final MarketQuote? quote;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final changeRate = quote?.changeRate ?? '0';
    final isPositive = !changeRate.trim().startsWith('-');
    return Material(
      color: AppColors.white,
      child: InkWell(
        key: ValueKey('watchlist-item-${item.stockCode}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              _StockLogoBadge(
                stockCode: item.stockCode,
                stockName: item.stockName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.stockName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray1000,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.stockCode} · ${item.market}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.gray600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    quote?.localCurrencyDisplay ?? 'Loading',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (quote != null)
                    Text(
                      quote!.krwDisplay,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.gray500,
                          ),
                    ),
                  Text(
                    '$changeRate%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isPositive
                              ? AppColors.green500
                              : AppColors.red500,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              IconButton(
                key: ValueKey('watchlist-remove-${item.stockCode}'),
                onPressed: onRemove,
                icon: const Icon(Icons.favorite, color: AppColors.red500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockLogoBadge extends StatelessWidget {
  const _StockLogoBadge({
    required this.stockCode,
    required this.stockName,
  });

  final String stockCode;
  final String stockName;

  @override
  Widget build(BuildContext context) {
    final logoAssetPath = _koreanStockLogoAssetPath(stockCode);
    if (logoAssetPath != null) {
      return Semantics(
        label: '$stockName logo',
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gray200),
          ),
          child: ClipOval(
            child: Image.asset(
              logoAssetPath,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      );
    }

    final colors = const [
      AppColors.green500,
      AppColors.orange500,
      AppColors.red500,
      AppColors.slate600,
      Color(0xFF6E56CF),
    ];
    final hash = stockCode.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    final initials = stockName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return CircleAvatar(
      radius: 18,
      backgroundColor: colors[hash % colors.length],
      child: Text(
        initials.isEmpty ? stockCode.substring(0, 2) : initials,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
