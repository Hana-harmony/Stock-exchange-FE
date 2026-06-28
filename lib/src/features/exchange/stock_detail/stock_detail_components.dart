part of '../exchange_pages.dart';

class _InvestmentInfoSection extends StatelessWidget {
  const _InvestmentInfoSection({
    required this.snapshot,
  });

  final _StockDetailSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.gray600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Cash Balance', style: mutedStyle),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                snapshot.accountDisplay,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mutedStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _StockInfoRow(label: 'Average Price', value: snapshot.averagePrice),
        const SizedBox(height: 16),
        _StockInfoRow(
          label: 'Return',
          value: snapshot.returnRate,
          valueColor: AppColors.red500,
        ),
        const SizedBox(height: 16),
        _StockInfoRow(label: 'Shares', value: snapshot.sharesDisplay),
        const SizedBox(height: 16),
        _StockInfoRow(
          label: 'Market Value',
          value: snapshot.marketValue,
          trailing: snapshot.marketValueChange,
          trailingColor: AppColors.red500,
        ),
        const SizedBox(height: 16),
        _StockInfoRow(label: 'Cost', value: snapshot.costDisplay),
      ],
    );
  }
}

class _ForeignOwnershipAlertCard extends StatelessWidget {
  const _ForeignOwnershipAlertCard({
    required this.snapshot,
  });

  final _StockDetailSnapshot snapshot;

  static const _outerBackgroundColor = Color(0xFFF5F6F6);
  static const _accentColor = Color(0xFFFF1550);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _outerBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Foreign Ownership Limit Alert',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray1000,
                        ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: AppColors.gray500,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Based on a time-series regression analysis\nwith a 95% confidence interval',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray600,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            height: 1.4,
                            color: _accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      snapshot.estimatedRange,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: _accentColor,
                                fontSize: 22,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: snapshot.alertProgress,
                        minHeight: 10,
                        backgroundColor: AppColors.gray300,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_accentColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _AlertMetric(
                            label: 'Previous Day',
                            value: snapshot.previousDayForeignRatio,
                            alignEnd: false,
                          ),
                        ),
                        Expanded(
                          child: _AlertMetric(
                            label: 'Limit',
                            value: snapshot.limitForeignRatio,
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'The estimated maximum foreign ownership ratio '
                      '(${snapshot.estimatedRangeMax}) is close to the limit '
                      '(${snapshot.limitForeignRatio}). Trading may be restricted once '
                      'the limit is reached.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.gray800,
                            height: 1.4,
                          ),
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

class _AlertMetric extends StatelessWidget {
  const _AlertMetric({
    required this.label,
    required this.value,
    required this.alignEnd,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.gray900,
              ),
        ),
      ],
    );
  }
}

class _StockInfoRow extends StatelessWidget {
  const _StockInfoRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.gray1000,
    this.trailing,
    this.trailingColor,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String? trailing;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray1000,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: valueColor,
                      ),
                ),
                if (trailing != null)
                  TextSpan(
                    text: ' $trailing',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: trailingColor ?? valueColor,
                        ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _StockBottomActionBar extends StatelessWidget {
  const _StockBottomActionBar({
    required this.onSell,
    required this.onBuy,
  });

  final VoidCallback onSell;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 119,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.white.withValues(alpha: 0),
                  AppColors.white,
                ],
                stops: const [0, 0.2],
              ),
            ),
            child: SizedBox(
              height: 85,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _TradeActionButton(
                        label: 'Sell',
                        backgroundColor: AppColors.red500,
                        onTap: onSell,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TradeActionButton(
                        label: 'Buy',
                        backgroundColor: AppColors.green500,
                        onTap: onBuy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 34,
            color: AppColors.white,
            child: Center(
              child: Image.asset(
                AppAssets.bottomHomeBar,
                width: 402,
                height: 34,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeActionButton extends StatelessWidget {
  const _TradeActionButton({
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _StockDetailSnapshot {
  const _StockDetailSnapshot({
    required this.stockCode,
    required this.stockName,
    required this.marketStatusLabel,
    required this.currentPrice,
    required this.changeAmount,
    required this.changeRate,
    required this.isPositive,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.previousClose,
    required this.countryBadgeAsset,
    required this.showKoreaFlag,
    required this.estimatedRange,
    required this.estimatedRangeMax,
    required this.previousDayForeignRatio,
    required this.limitForeignRatio,
    required this.alertProgress,
    required this.accountDisplay,
    required this.averagePrice,
    required this.returnRate,
    required this.sharesDisplay,
    required this.marketValue,
    required this.marketValueChange,
    required this.costDisplay,
  });

  final String stockCode;
  final String stockName;
  final String marketStatusLabel;
  final String currentPrice;
  final String changeAmount;
  final String changeRate;
  final bool isPositive;
  final String highPrice;
  final String lowPrice;
  final String volume;
  final String previousClose;
  final String countryBadgeAsset;
  final bool showKoreaFlag;
  final String estimatedRange;
  final String estimatedRangeMax;
  final String previousDayForeignRatio;
  final String limitForeignRatio;
  final double alertProgress;
  final String accountDisplay;
  final String averagePrice;
  final String returnRate;
  final String sharesDisplay;
  final String marketValue;
  final String marketValueChange;
  final String costDisplay;

  factory _StockDetailSnapshot.fromControllers({
    required String stockCode,
    required String fallbackTitle,
    required String fallbackMarket,
    required String fallbackSector,
    required MarketDetailState detailState,
    required TradeState tradeState,
  }) {
    final detail =
        detailState.detail?.stockCode == stockCode ? detailState.detail : null;
    final chart = detail != null ? detailState.chart : null;
    final market = detail?.market ?? fallbackMarket;
    final fallback = _StockDetailFallback.forStock(
      stockCode: stockCode,
      stockName: fallbackTitle,
      market: market,
      sector: fallbackSector,
    );
    final chartPoint = chart?.latestPoint;
    final currentPrice = detail?.currentPriceKrw ?? fallback.currentPrice;
    final previousClose = chartPoint?.openPriceKrw ?? fallback.previousClose;
    final changeRate = detail?.changeRate ?? fallback.changeRate;
    final changeAmount = detail != null && chartPoint != null
        ? _formatSignedDifference(currentPrice, previousClose)
        : fallback.changeAmount;
    final maxLimitRate = _parsePercent(
      '${detail?.predictedForeignLimitExhaustionRateMax ?? fallback.estimatedMax}%',
    );
    final limitValue = _parsePercent(fallback.limitForeignRatio);
    final portfolio = tradeState.portfolio;
    MockHolding? holding;
    if (portfolio != null) {
      for (final item in portfolio.holdings) {
        if (item.stockCode == stockCode) {
          holding = item;
          break;
        }
      }
    }

    return _StockDetailSnapshot(
      stockCode: stockCode,
      stockName: detail?.stockName ?? fallback.stockName,
      marketStatusLabel:
          _formatMarketStatus(detail?.marketDataTime) ?? fallback.marketStatus,
      currentPrice: currentPrice,
      changeAmount: changeAmount == '+0' ? fallback.changeAmount : changeAmount,
      changeRate: changeRate,
      isPositive: !changeRate.trim().startsWith('-'),
      highPrice: chartPoint?.highPriceKrw ?? fallback.highPrice,
      lowPrice: chartPoint?.lowPriceKrw ?? fallback.lowPrice,
      volume: chartPoint != null
          ? _formatCompactNumber(chartPoint.volume)
          : fallback.volume,
      previousClose: chartPoint?.closePriceKrw ?? fallback.previousClose,
      countryBadgeAsset: _isHongKongMarket(market)
          ? AppAssets.countryBadgeHk
          : AppAssets.countryBadgeKr,
      showKoreaFlag: !_isHongKongMarket(market),
      estimatedRange: _formatRange(
        detail?.predictedForeignLimitExhaustionRateMin,
        detail?.predictedForeignLimitExhaustionRateMax,
        fallback.estimatedRange,
      ),
      estimatedRangeMax:
          '${detail?.predictedForeignLimitExhaustionRateMax ?? fallback.estimatedMax}%',
      previousDayForeignRatio:
          '${detail?.foreignLimitExhaustionRate ?? fallback.previousDayRatio}%',
      limitForeignRatio: fallback.limitForeignRatio,
      alertProgress:
          limitValue == 0 ? 0 : (maxLimitRate / limitValue).clamp(0, 1),
      accountDisplay: portfolio != null && portfolio.accountId.isNotEmpty
          ? 'Account ${portfolio.accountId}'
          : fallback.accountDisplay,
      averagePrice: holding != null
          ? formatUsdAmount(holding.averagePriceUsd)
          : fallback.averagePrice,
      returnRate: holding?.unrealizedPnlRate ?? fallback.returnRate,
      sharesDisplay: holding != null
          ? '${holding.quantity} Shares'
          : fallback.sharesDisplay,
      marketValue: holding != null
          ? formatUsdAmount(holding.marketValueUsd)
          : fallback.marketValue,
      marketValueChange: holding != null
          ? '(${formatUsdAmount(holding.unrealizedPnlUsd)})'
          : fallback.marketValueChange,
      costDisplay: fallback.costDisplay,
    );
  }
}

class _StockDetailFallback {
  const _StockDetailFallback({
    required this.stockName,
    required this.marketStatus,
    required this.currentPrice,
    required this.changeAmount,
    required this.changeRate,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.previousClose,
    required this.estimatedRange,
    required this.estimatedMax,
    required this.previousDayRatio,
    required this.limitForeignRatio,
    required this.accountDisplay,
    required this.averagePrice,
    required this.returnRate,
    required this.sharesDisplay,
    required this.marketValue,
    required this.marketValueChange,
    required this.costDisplay,
  });

  final String stockName;
  final String marketStatus;
  final String currentPrice;
  final String changeAmount;
  final String changeRate;
  final String highPrice;
  final String lowPrice;
  final String volume;
  final String previousClose;
  final String estimatedRange;
  final String estimatedMax;
  final String previousDayRatio;
  final String limitForeignRatio;
  final String accountDisplay;
  final String averagePrice;
  final String returnRate;
  final String sharesDisplay;
  final String marketValue;
  final String marketValueChange;
  final String costDisplay;

  factory _StockDetailFallback.forStock({
    required String stockCode,
    required String stockName,
    required String market,
    required String sector,
  }) {
    if (stockCode == '005930') {
      return const _StockDetailFallback(
        stockName: 'Samsung Electronics',
        marketStatus: 'Market Closed Jun 5 15:30:00',
        currentPrice: '568000',
        changeAmount: '+39000',
        changeRate: '+6.43%',
        highPrice: '76,000',
        lowPrice: '76,000',
        volume: '76,000',
        previousClose: '76,000',
        estimatedRange: '38.78%~38.82%',
        estimatedMax: '38.82',
        previousDayRatio: '38.50',
        limitForeignRatio: '40.00%',
        accountDisplay: 'Account 010-2663-9046-0',
        averagePrice: '14,085',
        returnRate: '-16.15%',
        sharesDisplay: '80 Shares',
        marketValue: '52,425',
        marketValueChange: '(-20,000)',
        costDisplay: '2,201,740',
      );
    }

    final seed = stockCode.codeUnits.fold<int>(0, (sum, value) => sum + value);
    final price = 12000 + seed * 37;
    final prev = price - 240;
    final estimatedMin = 37 + (seed % 10) / 10;
    final estimatedMax = estimatedMin + 0.04;
    return _StockDetailFallback(
      stockName: stockName,
      marketStatus: 'Market Closed Jun 5 15:30:00',
      currentPrice: '$price',
      changeAmount: _formatSignedNumber(price - prev),
      changeRate: seed.isEven ? '+2.13%' : '-1.42%',
      highPrice: '$price',
      lowPrice: '$prev',
      volume: _formatCompactNumber(76000 + seed * 3),
      previousClose: '$prev',
      estimatedRange:
          '${estimatedMin.toStringAsFixed(2)}%~${estimatedMax.toStringAsFixed(2)}%',
      estimatedMax: estimatedMax.toStringAsFixed(2),
      previousDayRatio: estimatedMin.toStringAsFixed(2),
      limitForeignRatio: '40.00%',
      accountDisplay: 'Account 010-2663-9046-0',
      averagePrice: '${price - 550}',
      returnRate: seed.isEven ? '-3.18%' : '-1.42%',
      sharesDisplay: '${(seed % 90) + 10} Shares',
      marketValue: '${price * 3}',
      marketValueChange: '(-${(seed % 20) + 1},000)',
      costDisplay: '${price * 4}',
    );
  }
}
