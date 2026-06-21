import 'package:flutter/foundation.dart';

import 'exchange_api_client.dart';

enum MarketDetailStatus {
  idle,
  loading,
  loaded,
  failure,
}

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

  const MarketDetailState.loading({
    this.detail,
    this.chart,
    this.orderBook,
  })  : status = MarketDetailStatus.loading,
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

  String get krwDisplay => '$baseCurrency $currentPriceKrw';

  String get localCurrencyDisplay => '$displayCurrency $localCurrencyPrice';

  String get predictedOwnershipRangeDisplay =>
      '$predictedForeignOwnershipRateMin% - $predictedForeignOwnershipRateMax%';

  String get predictedLimitRangeDisplay =>
      '$predictedForeignLimitExhaustionRateMin% - $predictedForeignLimitExhaustionRateMax%';

  String get predictionModelDisplay =>
      '$foreignOwnershipPredictionModelVersion / $foreignOwnershipPredictionConfidenceLevel'
      ' $foreignOwnershipPredictionConfidenceScore';

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
    if (priceLimitState != 'NORMAL') {
      return priceLimitState;
    }
    return orderable ? 'Orderable' : 'Restricted';
  }

  static StockDetail fromJson(Map<String, dynamic> json) {
    final foreignOwnershipRate =
        _string(json['foreignOwnershipRate'], fallback: '0');
    final foreignLimitExhaustionRate =
        _string(json['foreignLimitExhaustionRate'], fallback: '0');

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
      foreignOwnershipBaseDate:
          _string(json['foreignOwnershipBaseDate'], fallback: 'unknown'),
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
  final String closeLocalCurrencyPrice;
  final int volume;
  final bool adjusted;

  String get closeKrwDisplay => 'KRW $closePriceKrw';

  String get closeLocalDisplay => '$localCurrency $closeLocalCurrencyPrice';

  static MarketChartPoint fromJson(Map<String, dynamic> json) {
    return MarketChartPoint(
      tradeDate: _string(json['tradeDate'], fallback: ''),
      openPriceKrw: _string(json['openPriceKrw'], fallback: '0'),
      highPriceKrw: _string(json['highPriceKrw'], fallback: '0'),
      lowPriceKrw: _string(json['lowPriceKrw'], fallback: '0'),
      closePriceKrw: _string(json['closePriceKrw'], fallback: '0'),
      localCurrency: _string(json['localCurrency'], fallback: 'USD'),
      closeLocalCurrencyPrice:
          _string(json['closeLocalCurrencyPrice'], fallback: '0'),
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
    return '$baseCurrency $priceKrw / $displayCurrency $localCurrencyPrice';
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

class MarketDetailController extends ValueNotifier<MarketDetailState> {
  MarketDetailController({required ExchangeApiClient apiClient})
      : _apiClient = apiClient,
        super(const MarketDetailState.idle());

  final ExchangeApiClient _apiClient;

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
    value = MarketDetailState.loading(
      detail: value.detail,
      chart: value.chart,
      orderBook: value.orderBook,
    );

    try {
      final results = await Future.wait([
        _apiClient.getStockDetail(
          stockCode: normalizedStockCode,
          currency: currency,
        ),
        _apiClient.getMarketChart(
          stockCode: normalizedStockCode,
          from: _dateOnly(chartFrom),
          to: _dateOnly(chartTo),
          interval: interval,
          currency: currency,
        ),
        _apiClient.getOrderBook(
          stockCode: normalizedStockCode,
          currency: currency,
        ),
      ]);

      value = MarketDetailState.loaded(
        detail: StockDetail.fromJson(results[0].data ?? {}),
        chart: MarketChart.fromJson(results[1].data ?? {}),
        orderBook: MarketOrderBook.fromJson(results[2].data ?? {}),
      );
    } on ExchangeApiException catch (error) {
      value = MarketDetailState.failure(
        errorMessage: error.message,
        detail: value.detail,
        chart: value.chart,
        orderBook: value.orderBook,
      );
    } on Object {
      value = MarketDetailState.failure(
        errorMessage: 'Unable to load stock detail, chart, and order book.',
        detail: value.detail,
        chart: value.chart,
        orderBook: value.orderBook,
      );
    }
  }
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

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

String _dateOnly(DateTime value) {
  return value.toUtc().toIso8601String().substring(0, 10);
}
