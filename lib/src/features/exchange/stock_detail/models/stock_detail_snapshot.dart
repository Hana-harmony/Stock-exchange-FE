part of '../../exchange_pages.dart';

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
    required this.orderAccountDisplay,
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
  final String orderAccountDisplay;
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
      orderAccountDisplay: portfolio != null && portfolio.accountId.isNotEmpty
          ? '${portfolio.accountId} [ISA(Brokerage)]'
          : fallback.orderAccountDisplay,
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
        orderAccountDisplay: '640-0200-0000-0 [ISA(Brokerage)]',
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
      orderAccountDisplay: '640-0200-0000-0 [ISA(Brokerage)]',
      averagePrice: '${price - 550}',
      returnRate: seed.isEven ? '-3.18%' : '-1.42%',
      sharesDisplay: '${(seed % 90) + 10} Shares',
      marketValue: '${price * 3}',
      marketValueChange: '(-${(seed % 20) + 1},000)',
      costDisplay: '${price * 4}',
    );
  }
}
