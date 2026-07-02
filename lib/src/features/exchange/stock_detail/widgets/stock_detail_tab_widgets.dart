part of '../../exchange_pages.dart';

enum _StockChartPeriod {
  oneDay('1D', '1m', 0),
  oneWeek('1W', '30m', 7),
  oneMonth('1M', '1d', 31);

  const _StockChartPeriod(this.label, this.apiInterval, this.lookbackDays);

  final String label;
  final String apiInterval;
  final int lookbackDays;

  DateTime toDate(DateTime now) => now.toUtc();

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
                            key: const ValueKey('stock-detail-tab-order'),
                            label: 'Order',
                            width: 48,
                            isSelected: controller.index == 0,
                            onTap: () => controller.animateTo(0),
                          ),
                          const SizedBox(width: 18),
                          AppUnderlineTab(
                            key: const ValueKey('stock-detail-tab-chart'),
                            label: 'Chart',
                            width: 47,
                            isSelected: controller.index == 1,
                            onTap: () => controller.animateTo(1),
                          ),
                          const SizedBox(width: 18),
                          AppUnderlineTab(
                            key: const ValueKey(
                              'stock-detail-tab-fundamentals',
                            ),
                            label: 'Fundamentals',
                            width: 116,
                            isSelected: controller.index == 2,
                            onTap: () => controller.animateTo(2),
                          ),
                          const SizedBox(width: 18),
                          AppUnderlineTab(
                            key: const ValueKey('stock-detail-tab-k-news'),
                            label: 'K-News',
                            width: 65,
                            isSelected: controller.index == 3,
                            onTap: () => controller.animateTo(3),
                          ),
                          const SizedBox(width: 18),
                          AppUnderlineTab(
                            key: const ValueKey(
                              'stock-detail-tab-disclosures',
                            ),
                            label: 'Disclosures',
                            width: 93,
                            isSelected: controller.index == 4,
                            onTap: () => controller.animateTo(4),
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

class _StockOrderTab extends StatelessWidget {
  const _StockOrderTab({
    required this.snapshot,
  });

  final _StockDetailSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('stock-order-tab'),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 140),
      children: [
        _ForeignOwnershipAlertCard(snapshot: snapshot),
        const SizedBox(height: 24),
        _InvestmentInfoSection(snapshot: snapshot),
        const SizedBox(height: 24),
        Container(
          height: 1,
          color: AppColors.gray200,
        ),
        const SizedBox(height: 24),
        _InvestmentInfoSection(snapshot: snapshot),
      ],
    );
  }
}

class _StockChartTab extends StatelessWidget {
  const _StockChartTab({
    required this.chart,
    required this.status,
    required this.errorMessage,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final MarketChart? chart;
  final MarketDetailStatus status;
  final String? errorMessage;
  final _StockChartPeriod selectedPeriod;
  final ValueChanged<_StockChartPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final points = chart?.points ?? const <MarketChartPoint>[];
    if (status == MarketDetailStatus.loading) {
      return ListView(
        key: const PageStorageKey<String>('stock-chart-tab-loading'),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
        children: [
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
        ],
      );
    }

    if (points.isEmpty) {
      return ListView(
        key: const PageStorageKey<String>('stock-chart-tab'),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
        children: [
          _MutedInfoCard(
            title: 'Chart unavailable',
            body: errorMessage ?? 'No chart data is available for this stock.',
          ),
        ],
      );
    }

    return ListView(
      key: const PageStorageKey<String>('stock-chart-tab'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
      children: [
        _StockChartPeriodSelector(
          selectedPeriod: selectedPeriod,
          onPeriodChanged: onPeriodChanged,
          isDisabled: false,
        ),
        const SizedBox(height: 14),
        _StockChartCard(
          chart: chart!,
          points: points,
          periodLabel: selectedPeriod.label,
        ),
        const SizedBox(height: 18),
        _StockChartSummary(points: points),
      ],
    );
  }
}

class _StockChartCard extends StatelessWidget {
  const _StockChartCard({
    required this.chart,
    required this.points,
    required this.periodLabel,
  });

  final MarketChart chart;
  final List<MarketChartPoint> points;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final latest = points.last;
    final firstLabel = _formatChartAxisTime(points.first.tradeDate);
    final lastLabel = _formatChartAxisTime(points.last.tradeDate);
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
                    '$periodLabel price chart',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray1000,
                        ),
                  ),
                ),
                Text(
                  latest.closeLocalDisplay,
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
              child: CustomPaint(
                painter: _StockDetailChartPainter(
                  points: points,
                  lineColor: _chartTrendColor(points),
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

class _StockFundamentalsTab extends StatelessWidget {
  const _StockFundamentalsTab({
    required this.snapshot,
    required this.detail,
  });

  final _StockDetailSnapshot snapshot;
  final StockDetail? detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('stock-fundamentals-tab'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
      children: [
        _FundamentalsSection(
          title: 'Market Status',
          rows: [
            _FundamentalsRowData('Market', detail?.market ?? '-'),
            _FundamentalsRowData('Sector', detail?.sector ?? '-'),
            _FundamentalsRowData('Status', snapshot.marketStatusLabel),
            _FundamentalsRowData('Risk', detail?.riskBadge ?? '-'),
          ],
        ),
        const SizedBox(height: 16),
        _FundamentalsSection(
          title: 'Foreign Ownership',
          rows: [
            _FundamentalsRowData(
              'Current ownership',
              '${detail?.foreignOwnershipRate ?? '-'}%',
            ),
            _FundamentalsRowData(
              'Limit exhaustion',
              snapshot.previousDayForeignRatio,
            ),
            _FundamentalsRowData(
              'Estimated exhaustion',
              snapshot.estimatedRange,
            ),
            _FundamentalsRowData(
              'Model',
              detail?.predictionModelDisplay ?? '-',
            ),
          ],
        ),
      ],
    );
  }
}

class _FundamentalsSection extends StatelessWidget {
  const _FundamentalsSection({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_FundamentalsRowData> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray1000,
                  ),
            ),
            const SizedBox(height: 14),
            for (final row in rows) ...[
              _StockInfoRow(label: row.label, value: row.value),
              if (row != rows.last) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _FundamentalsRowData {
  const _FundamentalsRowData(this.label, this.value);

  final String label;
  final String value;
}

class _StockDetailChartPainter extends CustomPainter {
  const _StockDetailChartPainter({
    required this.points,
    required this.lineColor,
  });

  final List<MarketChartPoint> points;
  final Color lineColor;

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
    final stepX = prices.length == 1 ? 0.0 : size.width / (prices.length - 1);

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
      ..lineTo(size.width, chartHeight)
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
        math.max(2.0, math.min(8.0, size.width / (volumes.length * 2.2)));
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
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
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
