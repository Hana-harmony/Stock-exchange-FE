part of '../../exchange_pages.dart';

class _StockDetailSnapshot {
  const _StockDetailSnapshot({
    required this.stockCode,
    required this.stockName,
    required this.logoUrl,
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
    required this.showsForeignOwnershipEstimate,
    required this.isForeignOwnershipTradingUnavailable,
    required this.isTradeEnabled,
    required this.estimatedOwnershipLabel,
    required this.estimatedRange,
    required this.estimatedRangeMax,
    required this.estimatedLimitExhaustionRange,
    required this.currentForeignOwnershipRatio,
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
  final String logoUrl;
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
  final bool showsForeignOwnershipEstimate;
  final bool isForeignOwnershipTradingUnavailable;
  final bool isTradeEnabled;
  final String estimatedOwnershipLabel;
  final String estimatedRange;
  final String estimatedRangeMax;
  final String estimatedLimitExhaustionRange;
  final String currentForeignOwnershipRatio;
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
    List<MarketChartPoint>? chartPoints,
    bool useQuoteChangeRate = false,
    DateTime? nowUtc,
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
    final chartMetrics =
        _StockChartMetrics.fromPoints(chartPoints ?? chart?.points);
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
    final sourceChangeRateRaw = quote?.changeRate ?? detail?.changeRate;
    final sourceChangeRate = !useQuoteChangeRate || sourceChangeRateRaw == null
        ? null
        : _formatPercentDisplay(sourceChangeRateRaw);
    final changeAmount = sourceChangeRate != null
        ? _formatSignedCurrencyDifferenceFromRate(
            displayCurrency,
            currentLocalRaw,
            sourceChangeRate,
          )
        : (detail != null || quote != null) && chartMetrics != null
            ? _formatSignedCurrencyDifference(
                displayCurrency,
                currentLocalRaw,
                previousCloseRaw,
              )
            : fallback.changeAmount;
    final changeRate = sourceChangeRate ??
        ((detail != null || quote != null) && chartMetrics != null
            ? chartMetrics.returnRate(currentLocalRaw)
            : _formatPercentDisplay(fallback.changeRate));
    final isForeignOwnershipTradingUnavailable =
        _isForeignOwnershipTradingUnavailable(detail);
    final showsForeignOwnershipEstimate =
        !isForeignOwnershipTradingUnavailable &&
            _showsForeignOwnershipEstimate(detail);
    final estimateMaxRaw = showsForeignOwnershipEstimate
        ? detail!.predictedForeignOwnershipRateMax
        : fallback.estimatedMax;
    final maxLimitExhaustionRate = showsForeignOwnershipEstimate
        ? _parsePercent('${detail!.predictedForeignLimitExhaustionRateMax}%')
        : 0;
    final limitForeignRatio = showsForeignOwnershipEstimate
        ? _foreignOwnershipLimitRatio(detail!)
        : fallback.limitForeignRatio;
    final isForeignLimitAlert =
        showsForeignOwnershipEstimate && maxLimitExhaustionRate >= 90;
    final estimateMax = _parseAmount(estimateMaxRaw);
    final estimatedRangeMax =
        showsForeignOwnershipEstimate && estimateMax != null
            ? '${estimateMax.toStringAsFixed(2)}%'
            : '$estimateMaxRaw%';
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
      logoUrl: detail?.logoUrl ?? '',
      marketStatusLabel: _marketStatusLabel(
        quote: quote,
        detail: detail,
        fallback: fallback,
        nowUtc: nowUtc,
      ),
      currentPrice: currentPrice,
      currentPriceKrwDisplay: currentPriceKrwDisplay,
      currentPriceKrwRaw: currentPriceKrwRaw,
      previousCloseKrwRaw: previousCloseKrwRaw,
      changeAmount: changeAmount == '+0' ? '+USD 0.00' : changeAmount,
      changeRate: changeRate,
      isPositive: !changeRate.trim().startsWith('-'),
      highPrice: chartMetrics?.highLocalDisplay ?? fallback.highPrice,
      lowPrice: chartMetrics?.lowLocalDisplay ?? fallback.lowPrice,
      volume: _resolvedVolumeDisplay(
        quoteVolume: quote?.volume,
        detailVolume: detail?.volume,
        chartVolume: chartMetrics?.totalVolume,
        fallback: fallback.volume,
      ),
      previousClose: previousClose,
      countryBadgeAsset: _isHongKongMarket(market)
          ? AppAssets.countryBadgeHk
          : AppAssets.countryBadgeKr,
      showKoreaFlag: !_isHongKongMarket(market),
      showsForeignOwnershipEstimate: showsForeignOwnershipEstimate,
      isForeignOwnershipTradingUnavailable:
          isForeignOwnershipTradingUnavailable,
      isTradeEnabled: !isForeignOwnershipTradingUnavailable &&
          (detail?.orderable ?? true) &&
          !(quote?.tradingHalted ?? false) &&
          !(quote?.circuitBreakerActive ?? false),
      estimatedOwnershipLabel: _estimatedOwnershipLabel(
        detail,
        nowUtc: nowUtc,
      ),
      estimatedRange: showsForeignOwnershipEstimate
          ? _formatRange(
              detail!.predictedForeignOwnershipRateMin,
              detail.predictedForeignOwnershipRateMax,
              fallback.estimatedRange,
              fractionDigits: 2,
            )
          : fallback.estimatedRange,
      estimatedRangeMax: estimatedRangeMax,
      estimatedLimitExhaustionRange: showsForeignOwnershipEstimate
          ? _formatRange(
              detail!.predictedForeignLimitExhaustionRateMin,
              detail.predictedForeignLimitExhaustionRateMax,
              fallback.estimatedRange,
            )
          : fallback.estimatedRange,
      currentForeignOwnershipRatio: showsForeignOwnershipEstimate
          ? '${detail!.foreignOwnershipRate}%'
          : '${fallback.previousDayRatio}%',
      limitForeignRatio: limitForeignRatio,
      alertProgress: (maxLimitExhaustionRate / 100).clamp(0, 1),
      foreignLimitCardTitle: isForeignLimitAlert
          ? 'Foreign Ownership Limit Alert'
          : 'Foreign Ownership Forecast',
      foreignLimitCardDescription: isForeignLimitAlert
          ? 'Based on stock-level walk-forward validation\nwith an empirical 90% prediction interval'
          : 'Based on the latest foreign ownership data\nand the forecast model',
      foreignLimitCardMessage: _foreignLimitCardMessage(
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

String _resolvedVolumeDisplay({
  required int? quoteVolume,
  required int? detailVolume,
  required int? chartVolume,
  required String fallback,
}) {
  for (final candidate in [quoteVolume, detailVolume, chartVolume]) {
    if (candidate != null && candidate > 0) {
      return _formatCompactNumber(candidate);
    }
  }
  return fallback;
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

  static _StockChartMetrics? fromPoints(List<MarketChartPoint>? points) {
    points ??= const <MarketChartPoint>[];
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

String _marketStatusLabel({
  required MarketQuote? quote,
  required StockDetail? detail,
  required _StockDetailFallback fallback,
  DateTime? nowUtc,
}) {
  final timestamp = quote?.marketDataTime ?? detail?.marketDataTime;
  final formatted = _formatMarketStatus(timestamp, nowUtc: nowUtc);
  if (formatted != null) {
    return formatted;
  }
  if (quote != null) {
    return quote.isAfterHours
        ? 'After-hours quote updating'
        : 'Live quote updating';
  }
  if (detail != null) {
    return 'Market status updating';
  }
  return fallback.marketStatus;
}

bool _showsForeignOwnershipEstimate(StockDetail? detail) {
  if (detail == null) {
    return false;
  }
  final confidenceLevel =
      detail.foreignOwnershipPredictionConfidenceLevel.trim().toUpperCase();
  const hiddenLevels = {
    '',
    'UNKNOWN',
    'NO_SNAPSHOT',
    'NO_FRESH_SNAPSHOT',
    'NOT_APPLICABLE',
    'FOREIGN_LIMIT_NOT_APPLICABLE',
  };
  if (hiddenLevels.contains(confidenceLevel)) {
    return false;
  }

  final minOwnership = _parseAmount(detail.predictedForeignOwnershipRateMin);
  final maxOwnership = _parseAmount(detail.predictedForeignOwnershipRateMax);
  final minExhaustion =
      _parseAmount(detail.predictedForeignLimitExhaustionRateMin);
  final maxExhaustion =
      _parseAmount(detail.predictedForeignLimitExhaustionRateMax);
  return minOwnership != null &&
      maxOwnership != null &&
      minExhaustion != null &&
      maxExhaustion != null;
}

String _estimatedOwnershipLabel(StockDetail? detail, {DateTime? nowUtc}) {
  final baseDate = DateTime.tryParse(detail?.foreignOwnershipBaseDate ?? '');
  if (baseDate == null) {
    return 'Estimated ownership';
  }
  var targetDate = DateTime.utc(baseDate.year, baseDate.month, baseDate.day)
      .add(const Duration(days: 1));
  while (!_isKoreanRegularSessionWeekday(targetDate)) {
    targetDate = targetDate.add(const Duration(days: 1));
  }
  final nowKst =
      (nowUtc ?? DateTime.now()).toUtc().add(const Duration(hours: 9));
  final today = DateTime.utc(nowKst.year, nowKst.month, nowKst.day);
  return targetDate == today
      ? "Today's estimated ownership"
      : 'Next trading day estimated ownership';
}

bool _isForeignOwnershipTradingUnavailable(StockDetail? detail) {
  return detail?.foreignOwnershipPredictionConfidenceLevel
          .trim()
          .toUpperCase() ==
      'FOREIGN_LIMIT_ZERO_NOT_ACQUIRABLE';
}

String _foreignOwnershipLimitRatio(StockDetail detail) {
  final ownershipRate = _parseAmount(detail.foreignOwnershipRate);
  final exhaustionRate = _parseAmount(detail.foreignLimitExhaustionRate);
  if (ownershipRate == null || exhaustionRate == null) {
    return '--';
  }
  if (ownershipRate == 0 && exhaustionRate == 0) {
    return '0.00%';
  }
  if (exhaustionRate <= 0) {
    return '--';
  }
  final limitRate = ownershipRate * 100 / exhaustionRate;
  return '${limitRate.toStringAsFixed(2)}%';
}

String _foreignLimitCardMessage({
  required bool isAlert,
  required String estimatedRangeMax,
  required String limitForeignRatio,
}) {
  if (!isAlert) {
    return 'The estimated maximum foreign ownership '
        '($estimatedRangeMax) remains below the foreign ownership cap '
        '($limitForeignRatio).';
  }
  return 'The estimated maximum foreign ownership '
      '($estimatedRangeMax) is close to the foreign ownership cap '
      '($limitForeignRatio). '
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
  final sign = numeric > 0 ? '+' : '';
  return '$sign${numeric.toStringAsFixed(2)}%';
}

String _formatSignedCurrencyDifferenceFromRate(
  String currency,
  String currentRaw,
  String rateRaw,
) {
  final current = _parseAmount(currentRaw);
  final rate = double.tryParse(rateRaw.replaceAll('%', '').trim());
  if (current == null || rate == null || rate <= -100) {
    return '--';
  }
  final previous = current / (1 + (rate / 100));
  final difference = current - previous;
  final sign = difference > 0
      ? '+'
      : difference < 0
          ? '-'
          : '';
  return '$sign${formatCurrencyDisplay(currency, difference.abs().toStringAsFixed(2))}';
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
