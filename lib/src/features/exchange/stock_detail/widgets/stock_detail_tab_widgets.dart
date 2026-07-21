part of '../../exchange_pages.dart';

enum _StockChartPeriod {
  oneDay('1D', '1m', 0),
  oneWeek('1W', '30m', 7),
  oneMonth('1M', '1d', 31);

  const _StockChartPeriod(this.label, this.apiInterval, this.lookbackDays);

  final String label;
  final String apiInterval;
  final int lookbackDays;

  DateTime toDate(DateTime now) => _lastKoreanRegularSessionDate(now);

  DateTime fromDate(DateTime now) {
    final to = toDate(now);
    if (lookbackDays == 0) {
      return to;
    }
    return to.subtract(Duration(days: lookbackDays));
  }
}

class _StockDetailTabs extends StatelessWidget {
  const _StockDetailTabs();

  static const double height = 51;

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);

    return SizedBox(
      height: 51,
      child: Column(
        children: [
          Container(
            height: 6,
            color: AppColors.gray200.withValues(alpha: 0.7),
          ),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return SizedBox(
                height: 45,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, top: 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          AppUnderlineTab(
                            key: const ValueKey('stock-detail-tab-chart'),
                            label: 'Chart',
                            width: 47,
                            isSelected: controller.index == 0,
                            onTap: () => controller.animateTo(0),
                          ),
                          const SizedBox(width: 18),
                          AppUnderlineTab(
                            key: const ValueKey('stock-detail-tab-k-news'),
                            label: 'K-News',
                            width: 65,
                            isSelected: controller.index == 1,
                            onTap: () => controller.animateTo(1),
                          ),
                          const SizedBox(width: 18),
                          AppUnderlineTab(
                            key: const ValueKey(
                              'stock-detail-tab-disclosures',
                            ),
                            label: 'Disclosures',
                            width: 93,
                            isSelected: controller.index == 2,
                            onTap: () => controller.animateTo(2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StockDetailTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => _StockDetailTabs.height;

  @override
  double get maxExtent => _StockDetailTabs.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: AppColors.white),
      child: _StockDetailTabs(),
    );
  }

  @override
  bool shouldRebuild(covariant _StockDetailTabsHeaderDelegate oldDelegate) {
    return false;
  }
}

class _StockChartTab extends StatelessWidget {
  const _StockChartTab({
    required this.snapshot,
    required this.chart,
    required this.chartPoints,
    required this.status,
    required this.errorMessage,
    required this.marketDataTime,
    required this.liveQuote,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final _StockDetailSnapshot snapshot;
  final MarketChart? chart;
  final List<MarketChartPoint>? chartPoints;
  final MarketDetailStatus status;
  final String? errorMessage;
  final DateTime? marketDataTime;
  final MarketQuote? liveQuote;
  final _StockChartPeriod selectedPeriod;
  final ValueChanged<_StockChartPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final rawPoints =
        chartPoints ?? chart?.points ?? const <MarketChartPoint>[];
    final oneDayPoints = selectedPeriod == _StockChartPeriod.oneDay
        ? _oneDayChartPointsWithLiveQuote(rawPoints, liveQuote)
        : rawPoints;
    final points = selectedPeriod == _StockChartPeriod.oneDay
        ? _visibleOneDayChartPoints(oneDayPoints, marketDataTime)
        : rawPoints;
    if (status == MarketDetailStatus.loading) {
      return ListView(
        key: const PageStorageKey<String>('stock-chart-tab-loading'),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
        children: [
          ..._foreignOwnershipStatusWidgets(snapshot),
          _StockChartPeriodSelector(
            selectedPeriod: selectedPeriod,
            onPeriodChanged: onPeriodChanged,
            isDisabled: true,
          ),
          const SizedBox(height: 18),
          const _MutedInfoCard(
            title: 'Loading chart',
            body: 'Price candles and volume are loading from the exchange.',
          ),
          const SizedBox(height: 18),
          const Center(
            key: ValueKey('stock-chart-loading'),
            child: CircularProgressIndicator(color: AppColors.orange500),
          ),
          const SizedBox(height: 24),
          _InvestmentInfoSection(snapshot: snapshot),
        ],
      );
    }

    if (points.isEmpty) {
      return ListView(
        key: const PageStorageKey<String>('stock-chart-tab'),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
        children: [
          ..._foreignOwnershipStatusWidgets(snapshot),
          _MutedInfoCard(
            title: 'Chart unavailable',
            body: errorMessage ?? 'No chart data is available for this stock.',
          ),
          const SizedBox(height: 24),
          _InvestmentInfoSection(snapshot: snapshot),
        ],
      );
    }

    return ListView(
      key: const PageStorageKey<String>('stock-chart-tab'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
      children: [
        ..._foreignOwnershipStatusWidgets(snapshot),
        _StockChartPeriodSelector(
          selectedPeriod: selectedPeriod,
          onPeriodChanged: onPeriodChanged,
          isDisabled: false,
        ),
        const SizedBox(height: 14),
        _StockChartCard(
          points: points,
          selectedPeriod: selectedPeriod,
          marketDataTime: marketDataTime,
        ),
        const SizedBox(height: 18),
        _StockChartSummary(points: points),
        const SizedBox(height: 24),
        _InvestmentInfoSection(snapshot: snapshot),
      ],
    );
  }
}

List<Widget> _foreignOwnershipStatusWidgets(_StockDetailSnapshot snapshot) {
  if (snapshot.isForeignOwnershipTradingUnavailable) {
    return const [
      _ForeignOwnershipTradingUnavailableCard(),
      SizedBox(height: 24),
    ];
  }
  if (snapshot.showsForeignOwnershipEstimate) {
    return [
      _ForeignOwnershipAlertCard(snapshot: snapshot),
      const SizedBox(height: 24),
    ];
  }
  return const [];
}

class _StockChartCard extends StatelessWidget {
  const _StockChartCard({
    required this.points,
    required this.selectedPeriod,
    required this.marketDataTime,
  });

  final List<MarketChartPoint> points;
  final _StockChartPeriod selectedPeriod;
  final DateTime? marketDataTime;

  @override
  Widget build(BuildContext context) {
    final latest = points.last;
    final isOneDay = selectedPeriod == _StockChartPeriod.oneDay;
    final chartProgress = isOneDay
        ? _stockOneDayChartProgress(
            marketDataTime: marketDataTime,
            points: points,
          )
        : 1.0;
    final firstLabel =
        isOneDay ? '09:00 KST' : _formatChartAxisTime(points.first.tradeDate);
    final lastLabel =
        isOneDay ? '15:30 KST' : _formatChartAxisTime(points.last.tradeDate);
    return DecoratedBox(
      key: const ValueKey('stock-chart-content'),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${selectedPeriod.label} price chart',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray1000,
                        ),
                  ),
                ),
                Text(
                  latest.closeLocalDisplay,
                  key: const ValueKey('stock-chart-latest-price'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              width: double.infinity,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _StockDetailChartPainter(
                    points: points,
                    lineColor: _chartTrendColor(points),
                    progress: chartProgress,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ChartAxisLabel(
                    label: firstLabel,
                    alignment: Alignment.centerLeft,
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ChartAxisLabel(
                    label: lastLabel,
                    alignment: Alignment.centerRight,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartAxisLabel extends StatelessWidget {
  const _ChartAxisLabel({
    required this.label,
    required this.alignment,
    required this.textAlign,
  });

  final String label;
  final Alignment alignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(
          label,
          maxLines: 2,
          textAlign: textAlign,
          style: _chartAxisStyle(context),
        ),
      ),
    );
  }
}

class _StockChartPeriodSelector extends StatelessWidget {
  const _StockChartPeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.isDisabled,
  });

  final _StockChartPeriod selectedPeriod;
  final ValueChanged<_StockChartPeriod> onPeriodChanged;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final period in _StockChartPeriod.values)
              Expanded(
                child: _StockChartPeriodButton(
                  period: period,
                  isSelected: period == selectedPeriod,
                  isDisabled: isDisabled,
                  onTap: () => onPeriodChanged(period),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StockChartPeriodButton extends StatelessWidget {
  const _StockChartPeriodButton({
    required this.period,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final _StockChartPeriod period;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('stock-chart-period-${period.label}'),
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.04),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: Text(
          period.label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDisabled
                    ? AppColors.gray500
                    : isSelected
                        ? AppColors.gray1000
                        : AppColors.gray600,
              ),
        ),
      ),
    );
  }
}

class _StockChartSummary extends StatelessWidget {
  const _StockChartSummary({required this.points});

  final List<MarketChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final high = points
        .map((point) => _parseAmount(point.highPriceKrw))
        .whereType<double>()
        .fold<double?>(null,
            (best, value) => best == null ? value : math.max(best, value));
    final low = points
        .map((point) => _parseAmount(point.lowPriceKrw))
        .whereType<double>()
        .fold<double?>(null,
            (best, value) => best == null ? value : math.min(best, value));
    final totalVolume = points.fold<int>(0, (sum, point) => sum + point.volume);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _StockInfoRow(
              label: 'High',
              value: high == null
                  ? '-'
                  : 'KRW ${_formatWholeAmount(high.round().toString())}',
            ),
            const SizedBox(height: 12),
            _StockInfoRow(
              label: 'Low',
              value: low == null
                  ? '-'
                  : 'KRW ${_formatWholeAmount(low.round().toString())}',
            ),
            const SizedBox(height: 12),
            _StockInfoRow(
              label: 'Volume',
              value: _formatCompactNumber(totalVolume),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockDetailChartPainter extends CustomPainter {
  const _StockDetailChartPainter({
    required this.points,
    required this.lineColor,
    required this.progress,
  });

  final List<MarketChartPoint> points;
  final Color lineColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final prices = points
        .map((point) => _parseAmount(point.closePriceKrw))
        .whereType<double>()
        .toList(growable: false);
    if (prices.isEmpty) {
      return;
    }

    final volumes = points.map((point) => point.volume).toList(growable: false);
    final minPrice = prices.reduce(math.min);
    final maxPrice = prices.reduce(math.max);
    final maxVolume = volumes.isEmpty ? 0 : volumes.reduce(math.max);
    final chartHeight = size.height * 0.72;
    final volumeTop = chartHeight + 18;
    final volumeHeight = size.height - volumeTop;
    final priceRange = math.max(maxPrice - minPrice, 1.0);
    final drawWidth = size.width * progress.clamp(0.02, 1.0);
    final stepX = prices.length == 1 ? 0.0 : drawWidth / (prices.length - 1);

    final gridPaint = Paint()
      ..color = AppColors.gray200
      ..strokeWidth = 1;
    for (final fraction in const [0.0, 0.5, 1.0]) {
      final y = chartHeight * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    for (var index = 0; index < prices.length; index++) {
      final x = stepX * index;
      final y =
          chartHeight - ((prices[index] - minPrice) / priceRange * chartHeight);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(drawWidth, chartHeight)
      ..lineTo(0, chartHeight)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.18),
            lineColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2.4,
    );

    final barWidth =
        math.max(2.0, math.min(8.0, drawWidth / (volumes.length * 2.2)));
    final volumePaint = Paint()..color = AppColors.gray300;
    for (var index = 0; index < volumes.length; index++) {
      final volumeRatio = maxVolume == 0 ? 0 : volumes[index] / maxVolume;
      final barHeight = volumeHeight * volumeRatio;
      final x = stepX * index - (barWidth / 2);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x.clamp(0, size.width - barWidth),
            volumeTop + volumeHeight - barHeight, barWidth, barHeight),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, volumePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StockDetailChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.progress != progress;
  }
}

double _stockOneDayChartProgress({
  required DateTime? marketDataTime,
  required List<MarketChartPoint> points,
}) {
  final cutoffKst = _oneDayChartCutoffKst(
    marketDataTime: marketDataTime,
    points: points,
  );
  if (cutoffKst == null) {
    return 1;
  }
  return _koreanRegularSessionProgressFromKst(cutoffKst);
}

DateTime? _parseKoreanChartTradeDate(String value) {
  final normalized = value.trim().replaceAll(' ', 'T');
  if (normalized.isEmpty) {
    return null;
  }
  return DateTime.tryParse(normalized);
}

List<MarketChartPoint> _visibleOneDayChartPoints(
  List<MarketChartPoint> points,
  DateTime? marketDataTime,
) {
  if (points.length < 2) {
    return points;
  }
  final cutoffKst = _oneDayChartCutoffKst(
    marketDataTime: marketDataTime,
    points: points,
  );
  if (cutoffKst == null) {
    return points;
  }
  final cutoffDayKey = _koreanDateKey(cutoffKst);
  final cutoffMinutes = cutoffKst.hour * 60 + cutoffKst.minute;
  final visible = points.where((point) {
    final tradeDate = _parseKoreanChartTradeDate(point.tradeDate);
    if (tradeDate == null) {
      return true;
    }
    final tradeDayKey = _koreanDateKey(tradeDate);
    if (tradeDayKey < cutoffDayKey) {
      return true;
    }
    if (tradeDayKey > cutoffDayKey) {
      return false;
    }
    final tradeMinutes = tradeDate.hour * 60 + tradeDate.minute;
    return tradeMinutes <= cutoffMinutes;
  }).toList(growable: false);
  return visible.isEmpty ? points.take(1).toList(growable: false) : visible;
}

List<MarketChartPoint> _oneDayChartPointsWithLiveQuote(
  List<MarketChartPoint> points,
  MarketQuote? liveQuote,
) {
  if (liveQuote == null || liveQuote.isAfterHours) {
    return points;
  }
  final liveKst = liveQuote.marketDataTime?.toUtc().add(
        const Duration(hours: 9),
      );
  if (liveKst == null || !_isOneDayRegularSessionTick(liveKst)) {
    return points;
  }
  final livePriceKrw = _parseAmount(liveQuote.currentPriceKrw);
  if (livePriceKrw == null || livePriceKrw <= 0) {
    return points;
  }

  final liveBucket = DateTime(
    liveKst.year,
    liveKst.month,
    liveKst.day,
    liveKst.hour,
    liveKst.minute,
  );
  final liveBucketText = _formatKoreanChartBucket(liveBucket);
  final livePriceText = _formatLiveChartAmount(liveQuote.currentPriceKrw);
  final liveLocalText =
      _formatLiveChartAmount(liveQuote.effectiveLocalCurrencyPrice);
  final next = List<MarketChartPoint>.of(points);
  final bucketIndex = next.indexWhere((point) {
    final tradeDate = _parseKoreanChartTradeDate(point.tradeDate);
    return tradeDate != null &&
        DateTime(
              tradeDate.year,
              tradeDate.month,
              tradeDate.day,
              tradeDate.hour,
              tradeDate.minute,
            ) ==
            liveBucket;
  });

  if (bucketIndex >= 0) {
    next[bucketIndex] = _mergeLiveQuoteIntoChartPoint(
      next[bucketIndex],
      liveQuote,
      livePriceKrw,
      livePriceText,
      liveLocalText,
    );
  } else {
    next.add(_liveQuoteChartPoint(
      liveQuote,
      liveBucketText,
      livePriceText,
      liveLocalText,
    ));
  }

  next.sort((left, right) {
    final leftDate = _parseKoreanChartTradeDate(left.tradeDate);
    final rightDate = _parseKoreanChartTradeDate(right.tradeDate);
    if (leftDate == null || rightDate == null) {
      return left.tradeDate.compareTo(right.tradeDate);
    }
    return leftDate.compareTo(rightDate);
  });
  return next;
}

bool _isOneDayRegularSessionTick(DateTime kst) {
  if (!_isKoreanRegularSessionWeekday(kst)) {
    return false;
  }
  final minutes = kst.hour * 60 + kst.minute;
  return minutes >= _koreanRegularOpenMinutes &&
      minutes <= _koreanRegularCloseMinutes;
}

MarketChartPoint _mergeLiveQuoteIntoChartPoint(
  MarketChartPoint point,
  MarketQuote liveQuote,
  double livePriceKrw,
  String livePriceText,
  String liveLocalText,
) {
  final highPrice = _parseAmount(point.highPriceKrw) ?? livePriceKrw;
  final lowPrice = _parseAmount(point.lowPriceKrw) ?? livePriceKrw;
  final isNewHigh = livePriceKrw > highPrice;
  final isNewLow = livePriceKrw < lowPrice;
  return point.copyWith(
    highPriceKrw: isNewHigh ? livePriceText : point.highPriceKrw,
    lowPriceKrw: isNewLow ? livePriceText : point.lowPriceKrw,
    closePriceKrw: livePriceText,
    localCurrency: liveQuote.localCurrency,
    highLocalCurrencyPrice:
        isNewHigh ? liveLocalText : point.highLocalCurrencyPrice,
    lowLocalCurrencyPrice:
        isNewLow ? liveLocalText : point.lowLocalCurrencyPrice,
    closeLocalCurrencyPrice: liveLocalText,
  );
}

MarketChartPoint _liveQuoteChartPoint(
  MarketQuote liveQuote,
  String tradeDate,
  String priceKrw,
  String localPrice,
) {
  return MarketChartPoint(
    tradeDate: tradeDate,
    openPriceKrw: priceKrw,
    highPriceKrw: priceKrw,
    lowPriceKrw: priceKrw,
    closePriceKrw: priceKrw,
    localCurrency: liveQuote.localCurrency,
    openLocalCurrencyPrice: localPrice,
    highLocalCurrencyPrice: localPrice,
    lowLocalCurrencyPrice: localPrice,
    closeLocalCurrencyPrice: localPrice,
    volume: 0,
    adjusted: false,
  );
}

String _formatKoreanChartBucket(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}T'
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}:00';
}

String _formatLiveChartAmount(String value) {
  final parsed = _parseAmount(value);
  if (parsed == null) {
    return value;
  }
  if (parsed == parsed.roundToDouble()) {
    return parsed.round().toString();
  }
  return parsed
      .toStringAsFixed(4)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(
        RegExp(r'\.$'),
        '',
      );
}

DateTime? _oneDayChartCutoffKst({
  required DateTime? marketDataTime,
  required List<MarketChartPoint> points,
}) {
  if (points.isEmpty) {
    return null;
  }
  final sessionDay = _chartSessionDay(points);
  if (sessionDay == null) {
    return null;
  }

  // 차트 API가 반환한 최신 분봉을 우선 사용해 상세 snapshot 지연으로 인한 잘림을 막는다.
  final latestPointKst = _parseKoreanChartTradeDate(points.last.tradeDate);
  if (_isOneDayRegularSessionCutoff(latestPointKst, sessionDay)) {
    return latestPointKst;
  }

  final referenceKst = marketDataTime?.toUtc().add(const Duration(hours: 9));
  if (_isOneDayRegularSessionCutoff(referenceKst, sessionDay)) {
    return referenceKst;
  }
  return null;
}

DateTime? _chartSessionDay(List<MarketChartPoint> points) {
  final tradeDate = _parseKoreanChartTradeDate(points.last.tradeDate);
  if (tradeDate == null) {
    return null;
  }
  return _koreanDateOnly(tradeDate);
}

bool _isOneDayRegularSessionCutoff(DateTime? kst, DateTime sessionDay) {
  if (kst == null || !_isKoreanRegularSessionWeekday(kst)) {
    return false;
  }
  if (_koreanDateKey(kst) != _koreanDateKey(sessionDay)) {
    return false;
  }
  final minutes = kst.hour * 60 + kst.minute;
  return minutes >= _koreanRegularOpenMinutes &&
      minutes < _koreanRegularCloseMinutes;
}

int _koreanDateKey(DateTime value) {
  return value.year * 10000 + value.month * 100 + value.day;
}

Color _chartTrendColor(List<MarketChartPoint> points) {
  if (points.length < 2) {
    return AppColors.green500;
  }
  final first = _parseAmount(points.first.closePriceKrw);
  final last = _parseAmount(points.last.closePriceKrw);
  if (first == null || last == null) {
    return AppColors.green500;
  }
  return last >= first ? AppColors.green500 : AppColors.red500;
}

TextStyle? _chartAxisStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.gray600,
      );
}

String _formatChartAxisTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value.replaceAll('T', ' ');
  }
  return formatEtWithKst(parsed);
}
