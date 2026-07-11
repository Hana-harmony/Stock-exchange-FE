part of '../exchange_pages.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({
    super.key,
    required this.sessionController,
    required this.tradeController,
    required this.marketCalendarController,
    required this.marketDetailController,
    required this.marketIndexController,
    required this.marketQuoteController,
    required this.notificationController,
    required this.onNavigateToAccounts,
    required this.favoriteStockCodes,
    required this.onFavoriteChanged,
    this.nowProvider,
  });

  final ExchangeSessionController sessionController;
  final TradeController tradeController;
  final MarketCalendarController marketCalendarController;
  final MarketDetailController marketDetailController;
  final MarketIndexController marketIndexController;
  final MarketQuoteController marketQuoteController;
  final NotificationController notificationController;
  final VoidCallback onNavigateToAccounts;
  final Set<String> favoriteStockCodes;
  final Future<bool> Function(String stockCode, bool nextIsFavorite)
      onFavoriteChanged;
  final DateTime Function()? nowProvider;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  List<String> _marketTrendingStockCodes = _defaultTrendingStockCodes;
  Timer? _calendarClockTimer;
  DateTime? _lastCalendarRequestedAt;

  static const _defaultTrendingStockCodes = <String>[
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
  ];

  @override
  void initState() {
    super.initState();
    _startMarketCalendarClock();
    unawaited(_loadMarketCalendar());
    _loadLiveMarketData();
  }

  @override
  void didUpdateWidget(covariant MarketScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketCalendarController != widget.marketCalendarController) {
      unawaited(_loadMarketCalendar());
    }
  }

  @override
  void dispose() {
    _calendarClockTimer?.cancel();
    super.dispose();
  }

  void _startMarketCalendarClock() {
    _calendarClockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
        _loadMarketCalendarIfStale();
      }
    });
  }

  Future<void> _loadMarketCalendar() {
    _lastCalendarRequestedAt = DateTime.now();
    return widget.marketCalendarController.load(limit: 6);
  }

  void _loadMarketCalendarIfStale() {
    final lastRequestedAt = _lastCalendarRequestedAt;
    if (lastRequestedAt == null ||
        DateTime.now().difference(lastRequestedAt) >=
            const Duration(minutes: 1)) {
      unawaited(_loadMarketCalendar());
    }
  }

  Future<void> _loadLiveMarketData() async {
    unawaited(widget.marketIndexController.subscribeLive());
    final indexSnapshot = widget.marketIndexController.loadSnapshot();
    final seedStockCodes = await _resolveInitialTrendingStockCodes();
    _marketTrendingStockCodes = seedStockCodes;
    unawaited(_subscribeMarketTrendingStocks());
    await Future.wait([
      indexSnapshot,
      widget.marketQuoteController.loadSnapshot(stockCodes: seedStockCodes),
    ]);
    if (!mounted) {
      return;
    }
    await _subscribeMarketTrendingStocks();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.marketIndexController,
        widget.marketQuoteController,
        widget.marketCalendarController,
      ]),
      builder: (context, _) {
        final indexState = widget.marketIndexController.value;
        final quoteState = widget.marketQuoteController.value;
        final calendarState = widget.marketCalendarController.value;
        final marketStatusCards = _buildMarketStatusCards(indexState);
        final trendingStocks = _buildTrendingStocks(quoteState);
        final calendarHeader = _buildMarketCalendarHeader();
        final calendarEvents = _buildMarketCalendarEvents(calendarState);

        return ListView(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
          children: [
            const SizedBox(height: 24),
            _MarketStatusSection(
              cards: marketStatusCards,
              calendarHeader: calendarHeader,
              calendarEvents: calendarEvents,
              isLoading: indexState.status == MarketIndexStatus.loading,
              errorMessage: indexState.status == MarketIndexStatus.failure
                  ? indexState.errorMessage
                  : null,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: Column(
                children: [
                  SizedBox(
                    height: 36,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Trending Stocks',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontSize: 22,
                                  height: 31 / 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray1000,
                                ),
                          ),
                        ),
                        SizedBox.square(
                          dimension: 36,
                          child: Center(
                            child: Image.asset(
                              AppAssets.rightArrow,
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (quoteState.status == MarketQuoteStatus.failure &&
                      quoteState.errorMessage != null &&
                      quoteState.errorMessage!.isNotEmpty) ...[
                    _MutedInfoCard(
                      title: 'Market data unavailable',
                      body: quoteState.errorMessage!,
                    ),
                    if (trendingStocks.isNotEmpty) const SizedBox(height: 8),
                  ],
                  if (trendingStocks.isNotEmpty)
                    for (var index = 0; index < trendingStocks.length; index++)
                      _TrendingStockTile(
                        stock: trendingStocks[index],
                        rank: index + 1,
                        onTap: () => _openTrendingStock(trendingStocks[index]),
                      )
                  else if (quoteState.status == MarketQuoteStatus.loading)
                    const _TrendingStocksLoadingCard()
                  else if (quoteState.status != MarketQuoteStatus.failure)
                    const _MutedInfoCard(
                      title: 'No stocks',
                      body: 'No live market quotes are available yet.',
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _openTrendingStock(_TrendingStock stock) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (context) => StockDetailScreen(
          sessionController: widget.sessionController,
          marketDetailController: widget.marketDetailController,
          marketQuoteController: widget.marketQuoteController,
          tradeController: widget.tradeController,
          notificationController: widget.notificationController,
          stockCode: stock.symbol,
          title: stock.name,
          market: stock.market,
          sector: '',
          isFavorite: widget.favoriteStockCodes.contains(stock.symbol),
          onFavoriteChanged: widget.onFavoriteChanged,
          onNavigateToAccounts: () {
            Navigator.of(context).pop();
            widget.onNavigateToAccounts();
          },
          nowProvider: widget.nowProvider,
        ),
      ),
    )
        .whenComplete(() {
      if (mounted) {
        unawaited(
          _subscribeMarketTrendingStocks(),
        );
      }
    });
  }

  Future<void> _subscribeMarketTrendingStocks() {
    return widget.marketQuoteController
        .subscribeMarketLiveStocks(_marketTrendingStockCodes);
  }

  Future<List<String>> _resolveInitialTrendingStockCodes() async {
    return _fillTrendingStockCodes(const []);
  }

  List<String> _fillTrendingStockCodes(Iterable<String> primaryCodes) {
    final codes = <String>[];

    void addCode(String stockCode) {
      final normalized = stockCode.trim();
      if (normalized.isEmpty || codes.contains(normalized)) {
        return;
      }
      codes.add(normalized);
    }

    for (final stockCode in primaryCodes) {
      addCode(stockCode);
      if (codes.length == 10) {
        return codes;
      }
    }
    for (final stockCode in _defaultTrendingStockCodes) {
      addCode(stockCode);
      if (codes.length == 10) {
        return codes;
      }
    }
    return codes;
  }

  List<MarketQuote> _marketTrendingQuotes(MarketQuoteState state) {
    if (_marketTrendingStockCodes.isEmpty) {
      return List<MarketQuote>.of(state.quotes)
        ..sort((a, b) => b.volume.compareTo(a.volume));
    }

    final marketCodes = _marketTrendingStockCodes.toSet();
    final quotesByCode = <String, MarketQuote>{
      for (final quote in state.quotes)
        if (marketCodes.contains(quote.stockCode)) quote.stockCode: quote,
    };
    return _marketTrendingStockCodes
        .map((stockCode) => quotesByCode[stockCode])
        .whereType<MarketQuote>()
        .take(10)
        .toList(growable: false);
  }

  List<_MarketStatusCardData> _buildMarketStatusCards(MarketIndexState state) {
    return state.indices.take(3).map((index) {
      final changeRate = _parsePercent(index.changeRate);
      final chartProgress = _koreanRegularSessionProgress(index.marketDataTime);
      return _MarketStatusCardData(
        title: index.indexName,
        value: index.currentValue,
        change:
            '${_signedText(index.changeValue)} ${_signedPercent(changeRate)}',
        isPositive: changeRate >= 0,
        points: _normalizeSparkline(
          state.intradaySeriesFor(index.indexCode),
        ),
        chartProgress: chartProgress,
      );
    }).toList(growable: false);
  }

  List<_TrendingStock> _buildTrendingStocks(MarketQuoteState state) {
    final sorted = _marketTrendingQuotes(state);
    return sorted.take(10).map((quote) {
      final changeRate = _parsePercent(quote.changeRate);
      return _TrendingStock(
        symbol: quote.stockCode,
        name: quote.stockName,
        market: quote.market,
        priceDisplay: quote.localCurrencyDisplay,
        secondaryPriceDisplay: quote.krwDisplay,
        changeDisplay: _signedPercent(changeRate),
        isPositive: changeRate >= 0,
      );
    }).toList(growable: false);
  }

  _MarketCalendarHeaderData _buildMarketCalendarHeader() {
    final kst = _now().toUtc().add(const Duration(hours: 9));
    return _MarketCalendarHeaderData(
      time: _formatKoreanMarketCalendarTime(kst),
      date: _formatKoreanMarketCalendarDate(kst),
    );
  }

  List<_MarketCalendarEventData> _buildMarketCalendarEvents(
    MarketCalendarState state,
  ) {
    final events = state.calendar?.events ?? const <MarketCalendarEvent>[];
    if (events.isNotEmpty) {
      return events
          .take(6)
          .map(_toMarketCalendarEventData)
          .toList(growable: false);
    }
    if (state.status == MarketCalendarStatus.loading) {
      return const [
        _MarketCalendarEventData(
          label: 'Syncing',
          title: 'Korea market calendar',
          detail: 'Loading server events',
          isHighImportance: false,
        ),
      ];
    }
    if (state.status == MarketCalendarStatus.failure) {
      return [
        _MarketCalendarEventData(
          label: 'Error',
          title: 'Calendar unavailable',
          detail: state.errorMessage ?? 'Unable to load events',
          isHighImportance: true,
        ),
      ];
    }
    return const [
      _MarketCalendarEventData(
        label: 'Waiting',
        title: 'Korea market calendar',
        detail: 'No upcoming events yet',
        isHighImportance: false,
      ),
    ];
  }

  _MarketCalendarEventData _toMarketCalendarEventData(
    MarketCalendarEvent event,
  ) {
    final isHighImportance = event.importance.toUpperCase() == 'HIGH';
    final until = _marketCalendarRelativeLabel(event.scheduledAt);
    final detailParts = <String>[
      if (event.dateLabel.trim().isNotEmpty) event.dateLabel.trim(),
      if (event.timeLabel.trim().isNotEmpty) event.timeLabel.trim(),
    ];
    return _MarketCalendarEventData(
      label: '${isHighImportance ? 'High' : 'Medium'} · $until',
      title: event.title,
      detail: detailParts.isEmpty ? event.market : detailParts.join(' · '),
      isHighImportance: isHighImportance,
    );
  }

  String _marketCalendarRelativeLabel(DateTime? scheduledAt) {
    if (scheduledAt == null) {
      return 'upcoming';
    }
    final now = _now();
    final diff = scheduledAt.toUtc().difference(now.toUtc());
    if (diff.inMinutes <= 0) {
      return 'now';
    }
    if (diff.inMinutes < 60) {
      return 'in ${diff.inMinutes}m';
    }
    if (diff.inHours < 24) {
      return 'in ${diff.inHours}h';
    }
    return 'in ${diff.inDays}d';
  }

  DateTime _now() => widget.nowProvider?.call() ?? DateTime.now();
}

class _MarketStatusSection extends StatelessWidget {
  const _MarketStatusSection({
    required this.cards,
    required this.calendarHeader,
    required this.calendarEvents,
    required this.isLoading,
    this.errorMessage,
  });

  final List<_MarketStatusCardData> cards;
  final _MarketCalendarHeaderData calendarHeader;
  final List<_MarketCalendarEventData> calendarEvents;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('market-status-section'),
      children: [
        if (errorMessage != null && errorMessage!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _MutedInfoCard(
              title: 'Market indices unavailable',
              body: errorMessage!,
            ),
          ),
          if (cards.isNotEmpty) const SizedBox(height: 8),
        ],
        if (cards.isEmpty && (errorMessage == null || errorMessage!.isEmpty))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _MutedInfoCard(
              title: isLoading ? 'Loading indices' : 'No indices',
              body: isLoading
                  ? 'Today market index charts are being loaded.'
                  : 'No market index data is available yet.',
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  Expanded(
                    child: _MarketStatusCard(
                      key: ValueKey('market-status-card-$index'),
                      data: cards[index],
                    ),
                  ),
                  if (index != cards.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          key: const ValueKey('market-indicator-banner'),
          height: 77,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                _MarketIndicatorTimeBlock(
                  time: calendarHeader.time,
                  date: calendarHeader.date,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (var index = 0;
                            index < calendarEvents.length;
                            index++) ...[
                          _MarketIndicatorSummary(
                            key: ValueKey('market-indicator-summary-$index'),
                            data: calendarEvents[index],
                          ),
                          if (index != calendarEvents.length - 1) ...[
                            const SizedBox(width: 20),
                            const SizedBox(
                              width: 1,
                              height: 40,
                              child: ColoredBox(color: AppColors.gray200),
                            ),
                            const SizedBox(width: 19),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MarketStatusCard extends StatelessWidget {
  const _MarketStatusCard({super.key, required this.data});

  final _MarketStatusCardData data;

  @override
  Widget build(BuildContext context) {
    final valueColor = data.isPositive ? AppColors.green500 : AppColors.red500;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: SizedBox(
        height: 133.14,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray750,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                data.value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      height: 25 / 18,
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                    ),
              ),
              SizedBox(
                height: 20,
                width: double.infinity,
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    data.change,
                    maxLines: 1,
                    softWrap: false,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          color: valueColor,
                        ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 22.14,
                width: double.infinity,
                child: CustomPaint(
                  painter: _MarketStatusSparklinePainter(
                    color: valueColor,
                    points: data.points,
                    progress: data.chartProgress,
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

class _MarketIndicatorTimeBlock extends StatelessWidget {
  const _MarketIndicatorTimeBlock({required this.time, required this.date});

  final String time;
  final String date;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 25,
            child: Text(
              time,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    height: 25 / 18,
                    fontWeight: FontWeight.w400,
                    color: AppColors.gray750,
                  ),
            ),
          ),
          SizedBox(
            height: 20,
            child: Text(
              date,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    color: AppColors.orange500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketIndicatorSummary extends StatelessWidget {
  const _MarketIndicatorSummary({super.key, required this.data});

  final _MarketCalendarEventData data;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w400,
          color:
              data.isHighImportance ? AppColors.orange500 : AppColors.gray600,
        );
    final indicatorStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: AppColors.gray900,
        );

    final detailStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          height: 1.25,
          color: AppColors.gray600,
        );

    return SizedBox(
      width: 188,
      height: 58,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
          const SizedBox(height: 2),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: indicatorStyle,
          ),
          const SizedBox(height: 1),
          Text(
            data.detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: detailStyle,
          ),
        ],
      ),
    );
  }
}

class _MarketStatusSparklinePainter extends CustomPainter {
  const _MarketStatusSparklinePainter({
    required this.color,
    required this.points,
    required this.progress,
  });

  final Color color;
  final List<double> points;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final path = Path();
    final effectiveWidth = size.width * progress.clamp(0.0, 1.0);
    if (effectiveWidth <= 0) {
      return;
    }

    for (var index = 0; index < points.length; index++) {
      final dx = (effectiveWidth / (points.length - 1)) * index;
      final dy = size.height * (1 - points[index]);
      if (index == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MarketStatusSparklinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.points != points ||
        oldDelegate.progress != progress;
  }
}

class _TrendingStockTile extends StatelessWidget {
  const _TrendingStockTile({
    required this.stock,
    required this.rank,
    required this.onTap,
  });

  final _TrendingStock stock;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final changeColor =
        stock.isPositive ? AppColors.green500 : AppColors.red500;
    return InkWell(
      key: ValueKey('trending-stock-${stock.symbol}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 72,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 52,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 12,
                    child: Text(
                      '$rank',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            height: 25 / 18,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray1000,
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 34,
                height: 52,
                child: Align(
                  alignment: Alignment.center,
                  child: _SearchResultAvatar(
                    stockCode: stock.symbol,
                    stockName: stock.name,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stock.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  height: 25 / 18,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray750,
                                ),
                      ),
                      Text(
                        stock.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.28,
                              color: AppColors.gray600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 112,
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            stock.changeDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontSize: 16,
                                  height: 20 / 16,
                                  fontWeight: FontWeight.w600,
                                  color: changeColor,
                                ),
                          ),
                          Text(
                            stock.priceDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 14,
                                  height: 18 / 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray900,
                                ),
                          ),
                          Text(
                            stock.secondaryPriceDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontSize: 11,
                                  height: 14 / 11,
                                  color: AppColors.gray500,
                                ),
                          ),
                        ],
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

class _TrendingStocksLoadingCard extends StatelessWidget {
  const _TrendingStocksLoadingCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loading stocks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(
                minHeight: 4,
                color: AppColors.orange500,
                backgroundColor: AppColors.gray200,
              ),
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < 3; index++) ...[
              const _TrendingStockLoadingRow(),
              if (index != 2) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrendingStockLoadingRow extends StatelessWidget {
  const _TrendingStockLoadingRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          const _LoadingBlock(width: 34, height: 34, radius: 17),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LoadingBlock(width: 96, height: 10),
                SizedBox(height: 8),
                _LoadingBlock(width: 148, height: 9),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LoadingBlock(width: 64, height: 10),
              SizedBox(height: 8),
              _LoadingBlock(width: 46, height: 9),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({
    required this.width,
    required this.height,
    this.radius = 4,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

class _TrendingStock {
  const _TrendingStock({
    required this.symbol,
    required this.name,
    required this.market,
    required this.priceDisplay,
    required this.secondaryPriceDisplay,
    required this.changeDisplay,
    required this.isPositive,
  });

  final String symbol;
  final String name;
  final String market;
  final String priceDisplay;
  final String secondaryPriceDisplay;
  final String changeDisplay;
  final bool isPositive;
}

class _MarketStatusCardData {
  const _MarketStatusCardData({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.points,
    required this.chartProgress,
  });

  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final List<double> points;
  final double chartProgress;
}

class _MarketCalendarHeaderData {
  const _MarketCalendarHeaderData({
    required this.time,
    required this.date,
  });

  final String time;
  final String date;
}

class _MarketCalendarEventData {
  const _MarketCalendarEventData({
    required this.label,
    required this.title,
    required this.detail,
    required this.isHighImportance,
  });

  final String label;
  final String title;
  final String detail;
  final bool isHighImportance;
}

List<double> _normalizeSparkline(List<double> values) {
  final source = values;
  if (source.length < 2) {
    return const [];
  }
  final minValue = source.reduce((a, b) => a < b ? a : b);
  final maxValue = source.reduce((a, b) => a > b ? a : b);
  final spread = maxValue - minValue;
  if (spread == 0) {
    return List<double>.filled(source.length, 0.5);
  }
  return source
      .map((value) => ((value - minValue) / spread).clamp(0.0, 1.0))
      .toList(growable: false);
}

double _koreanRegularSessionProgress(DateTime? marketDataTime) {
  if (marketDataTime == null) {
    return 1;
  }
  // 한국 정규장 09:00-15:30 기준으로 오늘 진행된 구간까지만 그린다.
  final kst = marketDataTime.toUtc().add(const Duration(hours: 9));
  return _koreanRegularSessionProgressFromKst(kst);
}

double _koreanRegularSessionProgressFromKst(DateTime? kst) {
  if (kst == null) {
    return 1;
  }
  final currentMinutes = kst.hour * 60 + kst.minute;
  if (!_isKoreanRegularSessionWeekday(kst) ||
      currentMinutes < _koreanRegularOpenMinutes) {
    return 1;
  }
  if (currentMinutes >= _koreanRegularCloseMinutes) {
    return 1;
  }
  return (currentMinutes - _koreanRegularOpenMinutes) /
      (_koreanRegularCloseMinutes - _koreanRegularOpenMinutes);
}

String _signedPercent(double value) {
  final prefix = value >= 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(2)}%';
}

String _signedText(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '+0';
  }
  if (trimmed.startsWith('-') || trimmed.startsWith('+')) {
    return trimmed;
  }
  return '+$trimmed';
}

String _formatKoreanMarketCalendarTime(DateTime kst) {
  return '${kst.hour.toString().padLeft(2, '0')}:'
      '${kst.minute.toString().padLeft(2, '0')}';
}

String _formatKoreanMarketCalendarDate(DateTime kst) {
  return '${_monthLabels[kst.month - 1]} ${kst.day}';
}
