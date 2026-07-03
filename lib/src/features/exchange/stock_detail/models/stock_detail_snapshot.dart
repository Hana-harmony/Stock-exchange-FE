part of '../../exchange_pages.dart';

class _StockDetailSnapshot {
  const _StockDetailSnapshot({
    required this.stockCode,
    required this.stockName,
    required this.marketStatusLabel,
    required this.currentPrice,
    required this.currentPriceKrwDisplay,
    required this.currentPriceKrwRaw,
    required this.previousCloseKrwRaw,
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
    required this.foreignLimitCardTitle,
    required this.foreignLimitCardDescription,
    required this.foreignLimitCardMessage,
    required this.isForeignLimitAlert,
    required this.accountDisplay,
    required this.orderAccountDisplay,
    required this.averagePrice,
    required this.returnRate,
    required this.isHoldingReturnPositive,
    required this.sharesDisplay,
    required this.marketValue,
    required this.marketValueChange,
    required this.isMarketValueChangePositive,
    required this.costDisplay,
  });

  final String stockCode;
  final String stockName;
  final String marketStatusLabel;
  final String currentPrice;
  final String currentPriceKrwDisplay;
  final String currentPriceKrwRaw;
  final String previousCloseKrwRaw;
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
  final String foreignLimitCardTitle;
  final String foreignLimitCardDescription;
  final String foreignLimitCardMessage;
  final bool isForeignLimitAlert;
  final String accountDisplay;
  final String orderAccountDisplay;
  final String averagePrice;
  final String returnRate;
  final bool isHoldingReturnPositive;
  final String sharesDisplay;
  final String marketValue;
  final String marketValueChange;
  final bool isMarketValueChangePositive;
  final String costDisplay;

  factory _StockDetailSnapshot.fromControllers({
    required String stockCode,
    required String fallbackTitle,
    required String fallbackMarket,
    required String fallbackSector,
    required MarketDetailState detailState,
    MarketQuote? liveQuote,
    required TradeState tradeState,
  }) {
    final detail =
        detailState.detail?.stockCode == stockCode ? detailState.detail : null;
    final quote = liveQuote?.stockCode == stockCode ? liveQuote : null;
    final chart = detail != null ? detailState.chart : null;
    final market = quote?.market ?? detail?.market ?? fallbackMarket;
    final fallback = _StockDetailFallback.forStock(
      stockCode: stockCode,
      stockName: fallbackTitle,
      market: market,
      sector: fallbackSector,
    );
    final chartMetrics = _StockChartMetrics.fromChart(chart);
    final displayCurrency =
        quote?.localCurrency ?? detail?.displayCurrency ?? 'USD';
    final currentLocalRaw = quote?.effectiveLocalCurrencyPrice ??
        detail?.localCurrencyPrice ??
        fallback.currentPrice;
    final currentPrice = quote?.localCurrencyDisplay ??
        detail?.localCurrencyDisplay ??
        fallback.currentPrice;
    final currentPriceKrwDisplay = quote?.krwDisplay ??
        detail?.krwDisplay ??
        fallback.currentPriceKrwDisplay;
    final currentPriceKrwRaw = quote?.currentPriceKrw ??
        detail?.currentPriceKrw ??
        fallback.currentPriceKrwRaw;
    final previousCloseKrwRaw =
        chartMetrics?.baselineKrwRaw ?? fallback.previousCloseKrwRaw;
    final previousClose =
        chartMetrics?.baselineLocalDisplay ?? fallback.previousClose;
    final previousCloseRaw =
        chartMetrics?.baselineLocalRaw ?? fallback.previousClose;
    final changeAmount =
        (detail != null || quote != null) && chartMetrics != null
            ? _formatSignedCurrencyDifference(
                displayCurrency,
                currentLocalRaw,
                previousCloseRaw,
              )
            : fallback.changeAmount;
    final changeRate = quote != null
        ? _formatPercentDisplay(quote.changeRate)
        : detail != null && chartMetrics != null
            ? chartMetrics.returnRate(detail.localCurrencyPrice)
            : _formatPercentDisplay(detail?.changeRate ?? fallback.changeRate);
    final maxLimitRate = _parsePercent(
      '${detail?.predictedForeignLimitExhaustionRateMax ?? fallback.estimatedMax}%',
    );
    final limitForeignRatio =
        detail == null ? fallback.limitForeignRatio : '100.00%';
    final limitValue = _parsePercent(limitForeignRatio);
    final confidenceLevel =
        detail?.foreignOwnershipPredictionConfidenceLevel.toUpperCase() ?? '';
    final isForeignLimitApplicable = detail == null ||
        (!confidenceLevel.contains('NOT_APPLICABLE') &&
            !confidenceLevel.contains('UNRESTRICTED'));
    final isForeignLimitAlert = isForeignLimitApplicable && maxLimitRate >= 90;
    final estimatedRangeMax =
        '${detail?.predictedForeignLimitExhaustionRateMax ?? fallback.estimatedMax}%';
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
      stockName: quote?.stockName ?? detail?.stockName ?? fallback.stockName,
      marketStatusLabel: _formatMarketStatus(
            quote?.marketDataTime ?? detail?.marketDataTime,
          ) ??
          fallback.marketStatus,
      currentPrice: currentPrice,
      currentPriceKrwDisplay: currentPriceKrwDisplay,
      currentPriceKrwRaw: currentPriceKrwRaw,
      previousCloseKrwRaw: previousCloseKrwRaw,
      changeAmount: changeAmount == '+0' ? '+USD 0.00' : changeAmount,
      changeRate: changeRate,
      isPositive: !changeRate.trim().startsWith('-'),
      highPrice: chartMetrics?.highLocalDisplay ?? fallback.highPrice,
      lowPrice: chartMetrics?.lowLocalDisplay ?? fallback.lowPrice,
      volume: quote == null
          ? chartMetrics == null
              ? fallback.volume
              : _formatCompactNumber(chartMetrics.totalVolume)
          : _formatCompactNumber(quote.volume),
      previousClose: previousClose,
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
      limitForeignRatio: limitForeignRatio,
      alertProgress:
          limitValue == 0 ? 0 : (maxLimitRate / limitValue).clamp(0, 1),
      foreignLimitCardTitle: isForeignLimitAlert
          ? 'Foreign Ownership Limit Alert'
          : 'Foreign Ownership Forecast',
      foreignLimitCardDescription: isForeignLimitAlert
          ? 'Based on a time-series regression analysis\nwith a 95% confidence interval'
          : 'Based on the latest foreign ownership data\nand today forecast model',
      foreignLimitCardMessage: _foreignLimitCardMessage(
        isApplicable: isForeignLimitApplicable,
        isAlert: isForeignLimitAlert,
        estimatedRangeMax: estimatedRangeMax,
        limitForeignRatio: limitForeignRatio,
      ),
      isForeignLimitAlert: isForeignLimitAlert,
      accountDisplay: portfolio != null && portfolio.accountId.isNotEmpty
          ? 'Account ${portfolio.accountId}'
          : fallback.accountDisplay,
      orderAccountDisplay: portfolio != null && portfolio.accountId.isNotEmpty
          ? '${portfolio.accountId} [ISA(Brokerage)]'
          : fallback.orderAccountDisplay,
      averagePrice:
          holding != null ? holding.averagePriceDisplay : fallback.averagePrice,
      returnRate: holding != null
          ? _formatPercentDisplay(holding.unrealizedPnlRate)
          : fallback.returnRate,
      isHoldingReturnPositive: holding == null
          ? !fallback.returnRate.trim().startsWith('-')
          : !_formatPercentDisplay(holding.unrealizedPnlRate).startsWith('-'),
      sharesDisplay: holding != null
          ? '${holding.quantity} Shares'
          : fallback.sharesDisplay,
      marketValue:
          holding != null ? holding.marketValueDisplay : fallback.marketValue,
      marketValueChange: holding != null
          ? '(${holding.unrealizedPnlDisplay})'
          : fallback.marketValueChange,
      isMarketValueChangePositive: holding == null
          ? !fallback.marketValueChange.contains('-')
          : !holding.unrealizedPnlUsd.trim().startsWith('-'),
      costDisplay: holding == null
          ? fallback.costDisplay
          : _formatHoldingCostDisplay(holding),
    );
  }
}

class _StockChartMetrics {
  const _StockChartMetrics({
    required this.currency,
    required this.highLocalValue,
    required this.lowLocalValue,
    required this.baselineLocalRaw,
    required this.baselineKrwRaw,
    required this.totalVolume,
  });

  final String currency;
  final double highLocalValue;
  final double lowLocalValue;
  final String baselineLocalRaw;
  final String baselineKrwRaw;
  final int totalVolume;

  String get highLocalDisplay =>
      formatCurrencyDisplay(currency, highLocalValue.toStringAsFixed(2));

  String get lowLocalDisplay =>
      formatCurrencyDisplay(currency, lowLocalValue.toStringAsFixed(2));

  String get baselineLocalDisplay =>
      formatCurrencyDisplay(currency, baselineLocalRaw);

  String returnRate(String currentRaw) {
    final baseline = _parseAmount(baselineLocalRaw);
    final current = _parseAmount(currentRaw);
    if (baseline == null || baseline == 0 || current == null) {
      return '0.00%';
    }
    final rate = ((current - baseline) / baseline) * 100;
    final sign = rate > 0 ? '+' : '';
    return '$sign${rate.toStringAsFixed(2)}%';
  }

  static _StockChartMetrics? fromChart(MarketChart? chart) {
    final points = chart?.points ?? const <MarketChartPoint>[];
    if (points.isEmpty) {
      return null;
    }
    final localHighs = points
        .map((point) => _parseAmount(point.highLocalCurrencyPrice))
        .whereType<double>()
        .toList(growable: false);
    final localLows = points
        .map((point) => _parseAmount(point.lowLocalCurrencyPrice))
        .whereType<double>()
        .toList(growable: false);
    if (localHighs.isEmpty || localLows.isEmpty) {
      return null;
    }
    return _StockChartMetrics(
      currency: points.last.localCurrency,
      highLocalValue: localHighs.reduce(math.max),
      lowLocalValue: localLows.reduce(math.min),
      baselineLocalRaw: points.first.openLocalCurrencyPrice,
      baselineKrwRaw: points.first.openPriceKrw,
      totalVolume: points.fold<int>(0, (sum, point) => sum + point.volume),
    );
  }
}

String _foreignLimitCardMessage({
  required bool isApplicable,
  required bool isAlert,
  required String estimatedRangeMax,
  required String limitForeignRatio,
}) {
  if (!isApplicable) {
    return 'This stock is not currently subject to a foreign ownership ceiling. '
        'The estimate is shown for reference, not as a trading restriction signal.';
  }
  if (!isAlert) {
    return 'The estimated maximum foreign limit exhaustion '
        '($estimatedRangeMax) remains below the restriction threshold '
        '($limitForeignRatio). Trading restriction risk is not elevated at this level.';
  }
  return 'The estimated maximum foreign ownership ratio '
      '($estimatedRangeMax) is close to the limit ($limitForeignRatio). '
      'Trading may be restricted once the limit is reached.';
}

String _formatPercentDisplay(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '0.00%';
  }
  final numeric = double.tryParse(trimmed.replaceAll('%', ''));
  if (numeric == null) {
    return trimmed.endsWith('%') ? trimmed : '$trimmed%';
  }
  final sign = numeric > 0 && !trimmed.startsWith('+') ? '+' : '';
  return '$sign${numeric.toStringAsFixed(2)}%';
}

String _formatHoldingCostDisplay(MockHolding holding) {
  final average = double.tryParse(holding.averagePriceUsd.replaceAll(',', ''));
  if (average == null) {
    return holding.averagePriceDisplay;
  }
  return formatCurrencyDisplay(
      'USD', (average * holding.quantity).toStringAsFixed(2));
}

class _StockDetailFallback {
  const _StockDetailFallback({
    required this.stockName,
    required this.marketStatus,
    required this.currentPrice,
    required this.currentPriceKrwDisplay,
    required this.currentPriceKrwRaw,
    required this.previousCloseKrwRaw,
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
    required this.orderAccountDisplay,
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
  final String currentPriceKrwDisplay;
  final String currentPriceKrwRaw;
  final String previousCloseKrwRaw;
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
  final String orderAccountDisplay;
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
    const estimatedMin = 0.0;
    const estimatedMax = 0.0;
    return _StockDetailFallback(
      stockName: stockName,
      marketStatus: 'Loading market data',
      currentPrice: 'USD --',
      currentPriceKrwDisplay: 'KRW --',
      currentPriceKrwRaw: '0',
      previousCloseKrwRaw: '0',
      changeAmount: '--',
      changeRate: '0.00%',
      highPrice: '--',
      lowPrice: '--',
      volume: '--',
      previousClose: '--',
      estimatedRange:
          '${estimatedMin.toStringAsFixed(2)}%~${estimatedMax.toStringAsFixed(2)}%',
      estimatedMax: estimatedMax.toStringAsFixed(2),
      previousDayRatio: estimatedMin.toStringAsFixed(2),
      limitForeignRatio: '100.00%',
      accountDisplay: 'Sign in to view cash balance',
      orderAccountDisplay: 'Sign in to trade',
      averagePrice: '--',
      returnRate: '--',
      sharesDisplay: '--',
      marketValue: '--',
      marketValueChange: '',
      costDisplay: '--',
    );
  }
}
