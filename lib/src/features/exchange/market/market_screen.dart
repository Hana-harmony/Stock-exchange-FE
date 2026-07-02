part of '../exchange_pages.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({
    super.key,
    required this.sessionController,
    required this.tradeController,
    required this.marketDetailController,
    required this.marketIndexController,
    required this.marketQuoteController,
    required this.notificationController,
    required this.onNavigateToAccounts,
  });

  final ExchangeSessionController sessionController;
  final TradeController tradeController;
  final MarketDetailController marketDetailController;
  final MarketIndexController marketIndexController;
  final MarketQuoteController marketQuoteController;
  final NotificationController notificationController;
  final VoidCallback onNavigateToAccounts;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  static const _marketCategories = <({String label, double width})>[
    (label: 'Stocks', width: 58),
    (label: 'Cryto', width: 46),
    (label: 'Options', width: 65),
    (label: 'ETFs', width: 41),
    (label: 'Overview', width: 78),
    (label: 'More', width: 43),
  ];

  int _selectedCategoryIndex = 0;

  static const _marketIndicators = <_MarketIndicatorData>[
    _MarketIndicatorData(
      previous: 'Prev 0.5%',
      consensus: 'Cons 0.5%',
      actual: 'Act --',
      indicator: 'Retail Sales (MOM)',
    ),
    _MarketIndicatorData(
      previous: 'Prev 0.5%',
      consensus: 'Cons 0.5%',
      actual: 'Act --',
      indicator: 'Retail Sales (MOM)',
    ),
    _MarketIndicatorData(
      previous: 'Prev 0.5%',
      consensus: 'Cons 0.5%',
      actual: 'Act --',
      indicator: 'Retail Sales (MOM)',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadLiveMarketData();
  }

  Future<void> _loadLiveMarketData() async {
    await Future.wait([
      widget.marketIndexController.loadSnapshot(),
      widget.marketQuoteController.loadSnapshot(),
    ]);
    unawaited(widget.marketIndexController.subscribeLive());
    unawaited(widget.marketQuoteController.subscribeLive());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.marketIndexController,
        widget.marketQuoteController,
      ]),
      builder: (context, _) {
        final indexState = widget.marketIndexController.value;
        final quoteState = widget.marketQuoteController.value;
        final marketStatusCards = _buildMarketStatusCards(indexState);
        final trendingStocks = _buildTrendingStocks(quoteState);

        return ListView(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
          children: [
            SizedBox(
              height: 41,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 10),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedCategoryIndex;
                    final category = _marketCategories[index];
                    return _MarketCategoryTab(
                      label: category.label,
                      width: category.width,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      },
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 18),
                  itemCount: _marketCategories.length,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _MarketStatusSection(
              cards: marketStatusCards,
              indicators: _marketIndicators,
              isLoading: indexState.status == MarketIndexStatus.loading,
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
                  if (quoteState.status == MarketQuoteStatus.loading &&
                      trendingStocks.isEmpty)
                    const _MutedInfoCard(
                      title: 'Loading stocks',
                      body: 'Live Korea market quotes are being loaded.',
                    )
                  else if (trendingStocks.isEmpty)
                    const _MutedInfoCard(
                      title: 'No stocks',
                      body: 'No live market quotes are available yet.',
                    )
                  else
                    for (var index = 0; index < trendingStocks.length; index++)
                      _TrendingStockTile(
                        stock: trendingStocks[index],
                        rank: index + 1,
                        onTap: () => _openTrendingStock(trendingStocks[index]),
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
    Navigator.of(context).push(
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
          isFavorite: false,
          onFavoriteToggle: () {},
          onNavigateToAccounts: () {
            Navigator.of(context).pop();
            widget.onNavigateToAccounts();
          },
        ),
      ),
    );
  }

  List<_MarketStatusCardData> _buildMarketStatusCards(MarketIndexState state) {
    return state.indices.take(3).map((index) {
      final changeRate = _parsePercent(index.changeRate);
      return _MarketStatusCardData(
        title: index.indexName,
        value: index.currentValue,
        change:
            '${_signedText(index.changeValue)} ${_signedPercent(changeRate)}',
        isPositive: changeRate >= 0,
        points: _normalizeSparkline(
          state.intradaySeriesFor(index.indexCode),
          fallback: double.tryParse(index.currentValue.replaceAll(',', '')),
        ),
      );
    }).toList(growable: false);
  }

  List<_TrendingStock> _buildTrendingStocks(MarketQuoteState state) {
    final sorted = List<MarketQuote>.of(state.quotes)
      ..sort((a, b) => b.volume.compareTo(a.volume));
    return sorted.take(10).map((quote) {
      final changeRate = _parsePercent(quote.changeRate);
      return _TrendingStock(
        symbol: quote.stockCode,
        name: quote.stockName,
        market: quote.market,
        priceDisplay: quote.localCurrencyDisplay,
        changeDisplay: _signedPercent(changeRate),
        isPositive: changeRate >= 0,
      );
    }).toList(growable: false);
  }
}

class _MarketStatusSection extends StatelessWidget {
  const _MarketStatusSection({
    required this.cards,
    required this.indicators,
    required this.isLoading,
  });

  final List<_MarketStatusCardData> cards;
  final List<_MarketIndicatorData> indicators;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('market-status-section'),
      children: [
        if (cards.isEmpty)
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
                const _MarketIndicatorTimeBlock(time: '21:30', date: 'Jun 17'),
                const SizedBox(width: 20),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (var index = 0;
                            index < indicators.length;
                            index++) ...[
                          _MarketIndicatorSummary(
                            key: ValueKey('market-indicator-summary-$index'),
                            data: indicators[index],
                          ),
                          if (index != indicators.length - 1) ...[
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
              Text(
                data.change,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.28,
                      color: valueColor,
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
      width: 45,
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
                    letterSpacing: -0.28,
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

  final _MarketIndicatorData data;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.24,
          color: AppColors.gray600,
        );
    final indicatorStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: AppColors.gray900,
        );

    return SizedBox(
      width: 160,
      height: 41,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 17,
            child: Row(
              children: [
                SizedBox(
                  width: 53,
                  child: Text(data.previous, style: labelStyle),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 57,
                  child: Text(data.consensus, style: labelStyle),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 34,
                  child: Text(data.actual, style: labelStyle),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(data.indicator, style: indicatorStyle),
        ],
      ),
    );
  }
}

class _MarketStatusSparklinePainter extends CustomPainter {
  const _MarketStatusSparklinePainter({
    required this.color,
    required this.points,
  });

  final Color color;
  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final dx = (size.width / (points.length - 1)) * index;
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
    return oldDelegate.color != color || oldDelegate.points != points;
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
    final leadingWidth = stock.isPositive ? 277.0 : 280.0;
    final symbolWidth = stock.isPositive ? 215.0 : 218.0;
    final trailingWidth = stock.isPositive ? 73.0 : 70.0;

    return InkWell(
      key: ValueKey('trending-stock-${stock.symbol}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 65,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: leadingWidth,
                height: 45,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 45,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 25,
                          child: Text(
                            '$rank',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
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
                      height: 45,
                      child: Align(
                        alignment: Alignment.center,
                        child: _SearchResultAvatar(
                          stockCode: stock.symbol,
                          stockName: stock.name,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: symbolWidth,
                      height: 45,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 25,
                            child: Text(
                              stock.symbol,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontSize: 18,
                                    height: 25 / 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.gray750,
                                  ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                            child: Text(
                              stock.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 14,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.28,
                                    color: AppColors.gray600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: trailingWidth,
                height: 45,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 25,
                      child: Text(
                        stock.changeDisplay,
                        maxLines: 1,
                        textAlign: TextAlign.end,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  height: 25 / 18,
                                  fontWeight: FontWeight.w500,
                                  color: changeColor,
                                ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                      child: Text(
                        stock.priceDisplay,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.28,
                              color: AppColors.gray900,
                            ),
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

class _MarketCategoryTab extends StatelessWidget {
  const _MarketCategoryTab({
    required this.label,
    required this.width,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final double width;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppUnderlineTab(
      label: label,
      width: width,
      isSelected: isSelected,
      onTap: onTap,
      fontSize: 18,
      lineHeight: 25 / 18,
      fontWeightSelected: FontWeight.w600,
      fontWeightUnselected: FontWeight.w500,
      activeColor: AppColors.gray1000,
      inactiveColor: AppColors.gray600,
      underlineWidth: width,
      underlineHeight: 3,
    );
  }
}

class _TrendingStock {
  const _TrendingStock({
    required this.symbol,
    required this.name,
    required this.market,
    required this.priceDisplay,
    required this.changeDisplay,
    required this.isPositive,
  });

  final String symbol;
  final String name;
  final String market;
  final String priceDisplay;
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
  });

  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final List<double> points;
}

class _MarketIndicatorData {
  const _MarketIndicatorData({
    required this.previous,
    required this.consensus,
    required this.actual,
    required this.indicator,
  });

  final String previous;
  final String consensus;
  final String actual;
  final String indicator;
}

List<double> _normalizeSparkline(List<double> values, {double? fallback}) {
  final source = values.isNotEmpty ? values : [if (fallback != null) fallback];
  if (source.length < 2) {
    return const [0.5, 0.5];
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
