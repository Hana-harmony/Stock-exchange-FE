import 'package:flutter/foundation.dart';

import 'currency_format.dart';
import 'exchange_api_client.dart';

enum MarketDetailStatus { idle, loading, loaded, failure }

class MarketDetailState {
  const MarketDetailState({
    required this.status,
    this.detail,
    this.chart,
    this.orderBook,
    this.errorMessage,
  });

  const MarketDetailState.idle()
      : status = MarketDetailStatus.idle,
        detail = null,
        chart = null,
        orderBook = null,
        errorMessage = null;

  const MarketDetailState.loading({this.detail, this.chart, this.orderBook})
      : status = MarketDetailStatus.loading,
        errorMessage = null;

  const MarketDetailState.loaded({
    required this.detail,
    required this.chart,
    required this.orderBook,
  })  : status = MarketDetailStatus.loaded,
        errorMessage = null;

  const MarketDetailState.failure({
    required this.errorMessage,
    this.detail,
    this.chart,
    this.orderBook,
  }) : status = MarketDetailStatus.failure;

  final MarketDetailStatus status;
  final StockDetail? detail;
  final MarketChart? chart;
  final MarketOrderBook? orderBook;
  final String? errorMessage;
}

class StockDetail {
  const StockDetail({
    required this.stockCode,
    required this.stockName,
    required this.market,
    required this.sector,
    required this.baseCurrency,
    required this.displayCurrency,
    required this.currentPriceKrw,
    required this.localCurrencyPrice,
    required this.changeRate,
    required this.volume,
    required this.marketDataTime,
    required this.foreignOwnershipRate,
    required this.foreignLimitExhaustionRate,
    required this.predictedForeignOwnershipRateMin,
    required this.predictedForeignOwnershipRateMax,
    required this.predictedForeignLimitExhaustionRateMin,
    required this.predictedForeignLimitExhaustionRateMax,
    required this.foreignOwnershipPredictionConfidenceLevel,
    required this.foreignOwnershipPredictionConfidenceScore,
    required this.foreignOwnershipPredictionModelVersion,
    required this.foreignOwnershipBaseDate,
    required this.viActive,
    required this.singlePriceTrading,
    required this.priceLimitState,
    required this.tradingHalted,
    required this.orderable,
    required this.dataSource,
    required this.servedAt,
  });

  final String stockCode;
  final String stockName;
  final String market;
  final String sector;
  final String baseCurrency;
  final String displayCurrency;
  final String currentPriceKrw;
  final String localCurrencyPrice;
  final String changeRate;
  final int volume;
  final DateTime? marketDataTime;
  final String foreignOwnershipRate;
  final String foreignLimitExhaustionRate;
  final String predictedForeignOwnershipRateMin;
  final String predictedForeignOwnershipRateMax;
  final String predictedForeignLimitExhaustionRateMin;
  final String predictedForeignLimitExhaustionRateMax;
  final String foreignOwnershipPredictionConfidenceLevel;
  final String foreignOwnershipPredictionConfidenceScore;
  final String foreignOwnershipPredictionModelVersion;
  final String foreignOwnershipBaseDate;
  final bool viActive;
  final bool singlePriceTrading;
  final String priceLimitState;
  final bool tradingHalted;
  final bool orderable;
  final String dataSource;
  final DateTime? servedAt;

  String get krwDisplay => formatCurrencyDisplay(baseCurrency, currentPriceKrw);

  String get localCurrencyDisplay =>
      formatCurrencyDisplay(displayCurrency, localCurrencyPrice);

  String get predictedOwnershipRangeDisplay =>
      '$predictedForeignOwnershipRateMin% - $predictedForeignOwnershipRateMax%';

  String get predictedLimitRangeDisplay =>
      '$predictedForeignLimitExhaustionRateMin% - $predictedForeignLimitExhaustionRateMax%';

  String get predictionModelDisplay =>
      '$foreignOwnershipPredictionModelVersion / $foreignOwnershipPredictionConfidenceLevel'
      ' $foreignOwnershipPredictionConfidenceScore';

  String get normalizedPriceLimitState {
    final normalized = priceLimitState.trim().toUpperCase();
    return switch (normalized) {
      'UPPER' || 'UPPER_LIMIT' => 'UPPER',
      'LOWER' || 'LOWER_LIMIT' => 'LOWER',
      'NORMAL' => 'NORMAL',
      _ => 'NORMAL',
    };
  }

  String get priceLimitDisplay {
    return switch (normalizedPriceLimitState) {
      'UPPER' => 'Upper limit',
      'LOWER' => 'Lower limit',
      _ => 'Normal',
    };
  }

  String get riskBadge {
    if (tradingHalted) {
      return 'Trading halted';
    }
    if (viActive) {
      return 'VI active';
    }
    if (singlePriceTrading) {
      return 'Single-price trading';
    }
    if (normalizedPriceLimitState != 'NORMAL') {
      return priceLimitDisplay;
    }
    return orderable ? 'Orderable' : 'Restricted';
  }

  static StockDetail fromJson(Map<String, dynamic> json) {
    final foreignOwnershipRate = _string(
      json['foreignOwnershipRate'],
      fallback: '0',
    );
    final foreignLimitExhaustionRate = _string(
      json['foreignLimitExhaustionRate'],
      fallback: '0',
    );

    return StockDetail(
      stockCode: _string(json['stockCode'], fallback: ''),
      stockName: _string(json['stockName'], fallback: 'Unknown stock'),
      market: _string(json['market'], fallback: 'UNKNOWN'),
      sector: _string(json['sector'], fallback: 'UNKNOWN'),
      baseCurrency: _string(json['baseCurrency'], fallback: 'KRW'),
      displayCurrency: _string(json['displayCurrency'], fallback: 'USD'),
      currentPriceKrw: _string(json['currentPriceKrw'], fallback: '0'),
      localCurrencyPrice: _string(json['localCurrencyPrice'], fallback: '0'),
      changeRate: _string(json['changeRate'], fallback: '0'),
      volume: _int(json['volume']),
      marketDataTime: _dateTime(json['marketDataTime']),
      foreignOwnershipRate: foreignOwnershipRate,
      foreignLimitExhaustionRate: foreignLimitExhaustionRate,
      predictedForeignOwnershipRateMin: _string(
        json['predictedForeignOwnershipRateMin'],
        fallback: foreignOwnershipRate,
      ),
      predictedForeignOwnershipRateMax: _string(
        json['predictedForeignOwnershipRateMax'],
        fallback: foreignOwnershipRate,
      ),
      predictedForeignLimitExhaustionRateMin: _string(
        json['predictedForeignLimitExhaustionRateMin'],
        fallback: foreignLimitExhaustionRate,
      ),
      predictedForeignLimitExhaustionRateMax: _string(
        json['predictedForeignLimitExhaustionRateMax'],
        fallback: foreignLimitExhaustionRate,
      ),
      foreignOwnershipPredictionConfidenceLevel: _string(
        json['foreignOwnershipPredictionConfidenceLevel'],
        fallback: 'UNKNOWN',
      ),
      foreignOwnershipPredictionConfidenceScore: _string(
        json['foreignOwnershipPredictionConfidenceScore'],
        fallback: '0',
      ),
      foreignOwnershipPredictionModelVersion: _string(
        json['foreignOwnershipPredictionModelVersion'],
        fallback: 'unknown',
      ),
      foreignOwnershipBaseDate: _string(
        json['foreignOwnershipBaseDate'],
        fallback: 'unknown',
      ),
      viActive: json['viActive'] as bool? ?? false,
      singlePriceTrading: json['singlePriceTrading'] as bool? ?? false,
      priceLimitState: _string(json['priceLimitState'], fallback: 'NORMAL'),
      tradingHalted: json['tradingHalted'] as bool? ?? false,
      orderable: json['orderable'] as bool? ?? true,
      dataSource: _string(json['dataSource'], fallback: 'Stock-exchange-BE'),
      servedAt: _dateTime(json['servedAt']),
    );
  }
}

class MarketChart {
  const MarketChart({
    required this.dataSource,
    required this.stockCode,
    required this.interval,
    required this.from,
    required this.to,
    required this.baseCurrency,
    required this.displayCurrency,
    required this.pointCount,
    required this.points,
    required this.servedAt,
  });

  final String dataSource;
  final String stockCode;
  final String interval;
  final String from;
  final String to;
  final String baseCurrency;
  final String displayCurrency;
  final int pointCount;
  final List<MarketChartPoint> points;
  final DateTime? servedAt;

  MarketChartPoint? get latestPoint =>
      points.isEmpty ? null : points[points.length - 1];

  static MarketChart fromJson(Map<String, dynamic> json) {
    final pointValues = json['points'];

    return MarketChart(
      dataSource: _string(json['dataSource'], fallback: 'Stock-exchange-BE'),
      stockCode: _string(json['stockCode'], fallback: ''),
      interval: _string(json['interval'], fallback: '1d'),
      from: _string(json['from'], fallback: ''),
      to: _string(json['to'], fallback: ''),
      baseCurrency: _string(json['baseCurrency'], fallback: 'KRW'),
      displayCurrency: _string(json['displayCurrency'], fallback: 'USD'),
      pointCount: _int(json['pointCount']),
      points: pointValues is List
          ? pointValues
              .map((value) => MarketChartPoint.fromJson(_map(value)))
              .toList()
          : const [],
      servedAt: _dateTime(json['servedAt']),
    );
  }
}

class MarketChartPoint {
  const MarketChartPoint({
    required this.tradeDate,
    required this.openPriceKrw,
    required this.highPriceKrw,
    required this.lowPriceKrw,
    required this.closePriceKrw,
    required this.localCurrency,
    required this.openLocalCurrencyPrice,
    required this.highLocalCurrencyPrice,
    required this.lowLocalCurrencyPrice,
    required this.closeLocalCurrencyPrice,
    required this.volume,
    required this.adjusted,
  });

  final String tradeDate;
  final String openPriceKrw;
  final String highPriceKrw;
  final String lowPriceKrw;
  final String closePriceKrw;
  final String localCurrency;
  final String openLocalCurrencyPrice;
  final String highLocalCurrencyPrice;
  final String lowLocalCurrencyPrice;
  final String closeLocalCurrencyPrice;
  final int volume;
  final bool adjusted;

  String get closeKrwDisplay => formatCurrencyDisplay('KRW', closePriceKrw);

  String get closeLocalDisplay =>
      formatCurrencyDisplay(localCurrency, closeLocalCurrencyPrice);

  static MarketChartPoint fromJson(Map<String, dynamic> json) {
    return MarketChartPoint(
      tradeDate: _string(json['tradeDate'], fallback: ''),
      openPriceKrw: _string(json['openPriceKrw'], fallback: '0'),
      highPriceKrw: _string(json['highPriceKrw'], fallback: '0'),
      lowPriceKrw: _string(json['lowPriceKrw'], fallback: '0'),
      closePriceKrw: _string(json['closePriceKrw'], fallback: '0'),
      localCurrency: _string(json['localCurrency'], fallback: 'USD'),
      openLocalCurrencyPrice: _string(
        json['openLocalCurrencyPrice'],
        fallback: '0',
      ),
      highLocalCurrencyPrice: _string(
        json['highLocalCurrencyPrice'],
        fallback: '0',
      ),
      lowLocalCurrencyPrice: _string(
        json['lowLocalCurrencyPrice'],
        fallback: '0',
      ),
      closeLocalCurrencyPrice: _string(
        json['closeLocalCurrencyPrice'],
        fallback: '0',
      ),
      volume: _int(json['volume']),
      adjusted: json['adjusted'] as bool? ?? false,
    );
  }
}

class MarketOrderBook {
  const MarketOrderBook({
    required this.dataSource,
    required this.stockCode,
    required this.market,
    required this.baseCurrency,
    required this.displayCurrency,
    required this.asks,
    required this.bids,
    required this.marketDataTime,
    required this.servedAt,
  });

  final String dataSource;
  final String stockCode;
  final String market;
  final String baseCurrency;
  final String displayCurrency;
  final List<OrderBookLevel> asks;
  final List<OrderBookLevel> bids;
  final DateTime? marketDataTime;
  final DateTime? servedAt;

  OrderBookLevel? get bestAsk => asks.isEmpty ? null : asks.first;

  OrderBookLevel? get bestBid => bids.isEmpty ? null : bids.first;

  static MarketOrderBook fromJson(Map<String, dynamic> json) {
    final askValues = json['asks'];
    final bidValues = json['bids'];

    return MarketOrderBook(
      dataSource: _string(json['dataSource'], fallback: 'Stock-exchange-BE'),
      stockCode: _string(json['stockCode'], fallback: ''),
      market: _string(json['market'], fallback: 'UNKNOWN'),
      baseCurrency: _string(json['baseCurrency'], fallback: 'KRW'),
      displayCurrency: _string(json['displayCurrency'], fallback: 'USD'),
      asks: askValues is List
          ? askValues
              .map((value) => OrderBookLevel.fromJson(_map(value)))
              .toList()
          : const [],
      bids: bidValues is List
          ? bidValues
              .map((value) => OrderBookLevel.fromJson(_map(value)))
              .toList()
          : const [],
      marketDataTime: _dateTime(json['marketDataTime']),
      servedAt: _dateTime(json['servedAt']),
    );
  }
}

class OrderBookLevel {
  const OrderBookLevel({
    required this.priceKrw,
    required this.localCurrencyPrice,
    required this.quantity,
    required this.orderCount,
  });

  final String priceKrw;
  final String localCurrencyPrice;
  final int quantity;
  final int orderCount;

  String displayPrice(String baseCurrency, String displayCurrency) {
    return '${formatCurrencyDisplay(baseCurrency, priceKrw)} / '
        '${formatCurrencyDisplay(displayCurrency, localCurrencyPrice)}';
  }

  static OrderBookLevel fromJson(Map<String, dynamic> json) {
    return OrderBookLevel(
      priceKrw: _string(json['priceKrw'], fallback: '0'),
      localCurrencyPrice: _string(json['localCurrencyPrice'], fallback: '0'),
      quantity: _int(json['quantity']),
      orderCount: _int(json['orderCount']),
    );
  }
}

class GlobalPeerMatch {
  const GlobalPeerMatch({
    required this.stockCode,
    required this.stockName,
    required this.headline,
    required this.summary,
    required this.peers,
    required this.confidenceScore,
    required this.confidenceLevel,
    required this.modelVersion,
    required this.dataSource,
    required this.servedAt,
  });

  final String stockCode;
  final String stockName;
  final String headline;
  final String summary;
  final List<GlobalPeerMatchPeer> peers;
  final String confidenceScore;
  final String confidenceLevel;
  final String modelVersion;
  final String dataSource;
  final DateTime? servedAt;

  GlobalPeerMatchPeer? get primaryPeer => peers.isEmpty ? null : peers.first;

  static GlobalPeerMatch fromJson(Map<String, dynamic> json) {
    final peerValues = json['peers'];
    final primaryValue = json['primaryPeer'];
    final parsedPeers = peerValues is List
        ? peerValues
            .map((value) => GlobalPeerMatchPeer.fromJson(_map(value)))
            .toList()
        : <GlobalPeerMatchPeer>[];
    final primaryPeer = primaryValue == null
        ? null
        : GlobalPeerMatchPeer.fromJson(_map(primaryValue));
    final peers = <GlobalPeerMatchPeer>[
      if (primaryPeer != null) primaryPeer,
      ...parsedPeers.where(
        (peer) => primaryPeer == null || peer.ticker != primaryPeer.ticker,
      ),
    ];

    return GlobalPeerMatch(
      stockCode: _string(json['stockCode'], fallback: ''),
      stockName: _string(json['stockName'], fallback: 'Unknown stock'),
      headline: _string(json['headline'], fallback: ''),
      summary: _string(json['summary'], fallback: ''),
      peers: peers,
      confidenceScore: _string(json['confidenceScore'], fallback: '0'),
      confidenceLevel: _string(json['confidenceLevel'], fallback: 'UNKNOWN'),
      modelVersion: _string(json['modelVersion'], fallback: 'unknown'),
      dataSource: _string(json['dataSource'], fallback: 'Hana-OmniLens-API'),
      servedAt: _dateTime(json['servedAt']),
    );
  }
}

class GlobalPeerMatchPeer {
  const GlobalPeerMatchPeer({
    required this.rank,
    required this.ticker,
    required this.companyName,
    required this.exchange,
    required this.country,
    required this.similarityScore,
    required this.businessTags,
    required this.sector,
    required this.industry,
    required this.businessModel,
    required this.scaleBucket,
    required this.fiscalYear,
    required this.marketCapUsd,
    required this.revenueUsd,
    required this.operatingIncomeUsd,
    required this.netIncomeUsd,
    required this.financialDataSource,
    required this.financialSimilarityScore,
    required this.matchedFactors,
    required this.rationale,
  });

  final int rank;
  final String ticker;
  final String companyName;
  final String exchange;
  final String country;
  final String similarityScore;
  final List<String> businessTags;
  final String sector;
  final String industry;
  final String businessModel;
  final String scaleBucket;
  final int fiscalYear;
  final String marketCapUsd;
  final String revenueUsd;
  final String operatingIncomeUsd;
  final String netIncomeUsd;
  final String financialDataSource;
  final String financialSimilarityScore;
  final List<String> matchedFactors;
  final String rationale;

  String get displayName =>
      ticker.isEmpty ? companyName : '$companyName ($ticker)';

  static GlobalPeerMatchPeer fromJson(Map<String, dynamic> json) {
    return GlobalPeerMatchPeer(
      rank: _int(json['rank']),
      ticker: _string(json['ticker'], fallback: ''),
      companyName: _string(json['companyName'], fallback: 'Unknown peer'),
      exchange: _string(json['exchange'], fallback: ''),
      country: _string(json['country'], fallback: ''),
      similarityScore: _string(json['similarityScore'], fallback: '0'),
      businessTags: _stringList(json['businessTags']),
      sector: _string(json['sector'], fallback: ''),
      industry: _string(json['industry'], fallback: ''),
      businessModel: _string(json['businessModel'], fallback: ''),
      scaleBucket: _string(json['scaleBucket'], fallback: ''),
      fiscalYear: _int(json['fiscalYear']),
      marketCapUsd: _string(json['marketCapUsd'], fallback: ''),
      revenueUsd: _string(json['revenueUsd'], fallback: ''),
      operatingIncomeUsd: _string(json['operatingIncomeUsd'], fallback: ''),
      netIncomeUsd: _string(json['netIncomeUsd'], fallback: ''),
      financialDataSource: _string(json['financialDataSource'], fallback: ''),
      financialSimilarityScore: _string(
        json['financialSimilarityScore'],
        fallback: '0',
      ),
      matchedFactors: _stringList(json['matchedFactors']),
      rationale: _string(json['rationale'], fallback: ''),
    );
  }
}

class _MarketDetailCacheEntry {
  const _MarketDetailCacheEntry({
    required this.detail,
    required this.chart,
    required this.orderBook,
  });

  final StockDetail detail;
  final MarketChart chart;
  final MarketOrderBook orderBook;
}

class MarketDetailController extends ValueNotifier<MarketDetailState> {
  MarketDetailController({required ExchangeApiClient apiClient})
      : _apiClient = apiClient,
        super(const MarketDetailState.idle());

  final ExchangeApiClient _apiClient;
  final Map<String, _MarketDetailCacheEntry> _periodCache = {};

  Future<void> loadStock({
    required String stockCode,
    String currency = 'USD',
    String interval = '1d',
    DateTime? from,
    DateTime? to,
  }) async {
    final normalizedStockCode = stockCode.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(normalizedStockCode)) {
      value = MarketDetailState.failure(
        errorMessage: 'Enter a 6 digit Korean stock code.',
        detail: value.detail,
        chart: value.chart,
        orderBook: value.orderBook,
      );
      return;
    }

    final chartTo = to ?? DateTime.now().toUtc();
    final chartFrom = from ?? chartTo.subtract(const Duration(days: 30));
    final fromDate = _dateOnly(chartFrom);
    final toDate = _dateOnly(chartTo);
    final cacheKey = _periodCacheKey(
      stockCode: normalizedStockCode,
      currency: currency,
      interval: interval,
      from: fromDate,
      to: toDate,
    );
    final cached = _periodCache[cacheKey];
    final currentDetail = _sameStockDetail(value.detail, normalizedStockCode)
        ? value.detail
        : cached?.detail;
    var nextDetail = currentDetail;
    var nextChart = cached?.chart;
    var nextOrderBook = cached?.orderBook ??
        (_sameStockDetail(value.detail, normalizedStockCode)
            ? value.orderBook
            : null);
    value = MarketDetailState.loading(
      detail: nextDetail,
      chart: nextChart,
      orderBook: nextOrderBook,
    );

    String? errorMessage;
    void captureError(Object error) {
      errorMessage ??= error is ExchangeApiException
          ? _stockDetailErrorMessage(error)
          : 'Unable to load stock detail, chart, and order book.';
    }

    Future<_MarketDetailLoadResult> loadDetail() async {
      try {
        final detailResponse = await _apiClient.getStockDetail(
          stockCode: normalizedStockCode,
          currency: currency,
        );
        return _MarketDetailLoadResult.detail(
          StockDetail.fromJson(detailResponse.data ?? {}),
        );
      } on Object catch (error) {
        return _MarketDetailLoadResult.error(
          _MarketDetailLoadSegment.detail,
          error,
        );
      }
    }

    Future<_MarketDetailLoadResult> loadChart() async {
      try {
        final chartResponse = await _apiClient.getMarketChart(
          stockCode: normalizedStockCode,
          from: fromDate,
          to: toDate,
          interval: interval,
          currency: currency,
        );
        return _MarketDetailLoadResult.chart(
          MarketChart.fromJson(chartResponse.data ?? {}),
        );
      } on Object catch (error) {
        return _MarketDetailLoadResult.error(
          _MarketDetailLoadSegment.chart,
          error,
        );
      }
    }

    Future<_MarketDetailLoadResult> loadOrderBook() async {
      try {
        final orderBookResponse = await _apiClient.getOrderBook(
          stockCode: normalizedStockCode,
          currency: currency,
        );
        return _MarketDetailLoadResult.orderBook(
          MarketOrderBook.fromJson(orderBookResponse.data ?? {}),
        );
      } on Object catch (error) {
        return _MarketDetailLoadResult.error(
          _MarketDetailLoadSegment.orderBook,
          error,
        );
      }
    }

    void publishLoadingState() {
      value = MarketDetailState.loading(
        detail: nextDetail,
        chart: nextChart,
        orderBook: nextOrderBook,
      );
    }

    final pending = <_MarketDetailLoadSegment, Future<_MarketDetailLoadResult>>{
      _MarketDetailLoadSegment.detail: loadDetail(),
      _MarketDetailLoadSegment.chart: loadChart(),
      _MarketDetailLoadSegment.orderBook: loadOrderBook(),
    };

    while (pending.isNotEmpty) {
      final completed = await Future.any(
        pending.entries.map((entry) async {
          return _IndexedMarketDetailLoadResult(
            segment: entry.key,
            result: await entry.value,
          );
        }),
      );
      pending.remove(completed.segment);

      final result = completed.result;
      final error = result.error;
      if (error != null) {
        captureError(error);
        continue;
      }

      switch (result.segment) {
        case _MarketDetailLoadSegment.detail:
          nextDetail = result.detail;
        case _MarketDetailLoadSegment.chart:
          nextChart = result.chart;
        case _MarketDetailLoadSegment.orderBook:
          nextOrderBook = result.orderBook;
      }
      publishLoadingState();
    }

    final detail = nextDetail;
    final chart = nextChart;
    final orderBook = nextOrderBook;
    if (detail != null && chart != null && orderBook != null) {
      _periodCache[cacheKey] = _MarketDetailCacheEntry(
        detail: detail,
        chart: chart,
        orderBook: orderBook,
      );

      value = MarketDetailState.loaded(
        detail: detail,
        chart: chart,
        orderBook: orderBook,
      );
      return;
    }

    final hasPartialData = detail != null || chart != null || orderBook != null;
    if (hasPartialData) {
      value = MarketDetailState.failure(
        errorMessage: errorMessage ??
            'Some stock detail data is temporarily unavailable.',
        detail: detail,
        chart: chart,
        orderBook: orderBook,
      );
      return;
    }

    value = MarketDetailState.failure(
      errorMessage:
          errorMessage ?? 'Unable to load stock detail, chart, and order book.',
      detail: null,
      chart: null,
      orderBook: null,
    );
  }

  Future<GlobalPeerMatch> loadGlobalPeers({required String stockCode}) async {
    final normalizedStockCode = stockCode.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(normalizedStockCode)) {
      throw const ExchangeApiException(
        status: 400,
        code: 'STOCK_INVALID_CODE',
        message: 'Enter a 6 digit Korean stock code.',
      );
    }
    final response = await _apiClient.getGlobalPeers(
      stockCode: normalizedStockCode,
    );
    return GlobalPeerMatch.fromJson(response.data ?? {});
  }

  Future<void> refreshOrderBook({
    required String stockCode,
    String currency = 'USD',
  }) async {
    final normalizedStockCode = stockCode.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(normalizedStockCode)) {
      return;
    }

    try {
      final response = await _apiClient.getOrderBook(
        stockCode: normalizedStockCode,
        currency: currency,
      );
      value = MarketDetailState(
        status: _statusAfterOrderBookRefresh(value),
        detail: value.detail,
        chart: value.chart,
        orderBook: MarketOrderBook.fromJson(response.data ?? {}),
        errorMessage: value.status == MarketDetailStatus.failure
            ? value.errorMessage
            : null,
      );
    } on Object {
      value = MarketDetailState(
        status: value.status,
        detail: value.detail,
        chart: value.chart,
        orderBook: value.orderBook,
        errorMessage: value.errorMessage,
      );
    }
  }

  Future<void> subscribeRealtimeSource({
    required String stockCode,
    String session = 'REGULAR',
  }) async {
    final normalizedStockCode = stockCode.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(normalizedStockCode)) {
      return;
    }
    try {
      await _apiClient.subscribeRealtimeSource(
        stockCode: normalizedStockCode,
        session: session,
      );
    } on Object {
      // 원천 구독 실패는 상세 화면 표시를 막지 않는다.
    }
  }

  Future<void> unsubscribeRealtimeSource({
    required String stockCode,
    String session = 'REGULAR',
  }) async {
    final normalizedStockCode = stockCode.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(normalizedStockCode)) {
      return;
    }
    try {
      await _apiClient.unsubscribeRealtimeSource(
        stockCode: normalizedStockCode,
        session: session,
      );
    } on Object {
      // 상세 화면 종료 중 구독 해제 실패는 사용자 흐름에 전파하지 않는다.
    }
  }
}

enum _MarketDetailLoadSegment {
  detail,
  chart,
  orderBook,
}

class _MarketDetailLoadResult {
  const _MarketDetailLoadResult._({
    required this.segment,
    this.detail,
    this.chart,
    this.orderBook,
    this.error,
  });

  factory _MarketDetailLoadResult.detail(StockDetail detail) {
    return _MarketDetailLoadResult._(
      segment: _MarketDetailLoadSegment.detail,
      detail: detail,
    );
  }

  factory _MarketDetailLoadResult.chart(MarketChart chart) {
    return _MarketDetailLoadResult._(
      segment: _MarketDetailLoadSegment.chart,
      chart: chart,
    );
  }

  factory _MarketDetailLoadResult.orderBook(MarketOrderBook orderBook) {
    return _MarketDetailLoadResult._(
      segment: _MarketDetailLoadSegment.orderBook,
      orderBook: orderBook,
    );
  }

  factory _MarketDetailLoadResult.error(
    _MarketDetailLoadSegment segment,
    Object error,
  ) {
    return _MarketDetailLoadResult._(
      segment: segment,
      error: error,
    );
  }

  final _MarketDetailLoadSegment segment;
  final StockDetail? detail;
  final MarketChart? chart;
  final MarketOrderBook? orderBook;
  final Object? error;
}

class _IndexedMarketDetailLoadResult {
  const _IndexedMarketDetailLoadResult({
    required this.segment,
    required this.result,
  });

  final _MarketDetailLoadSegment segment;
  final _MarketDetailLoadResult result;
}

MarketDetailStatus _statusAfterOrderBookRefresh(MarketDetailState state) {
  if (state.detail != null && state.chart != null) {
    return MarketDetailStatus.loaded;
  }
  return state.status;
}

String _stockDetailErrorMessage(ExchangeApiException error) {
  if (error.status == 503 || error.code.startsWith('MARKET_')) {
    return 'Market data is temporarily unavailable.';
  }
  return error.message;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry('$key', value));
  }
  return {};
}

String _string(Object? value, {required String fallback}) {
  if (value == null) {
    return fallback;
  }
  final text = '$value';
  return text.isEmpty ? fallback : text;
}

int _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? 0;
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value.map((item) => '$item').where((item) => item.isNotEmpty).toList();
}

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

String _dateOnly(DateTime value) {
  return value.toUtc().toIso8601String().substring(0, 10);
}

String _periodCacheKey({
  required String stockCode,
  required String currency,
  required String interval,
  required String from,
  required String to,
}) {
  return '$stockCode|$currency|$interval|$from|$to';
}

bool _sameStockDetail(StockDetail? detail, String stockCode) {
  return detail != null && detail.stockCode == stockCode;
}
