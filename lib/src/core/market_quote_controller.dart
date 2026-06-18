import 'package:flutter/foundation.dart';

import 'exchange_api_client.dart';

enum MarketQuoteStatus {
  idle,
  loading,
  loaded,
  failure,
}

class MarketQuoteState {
  const MarketQuoteState({
    required this.status,
    required this.quotes,
    this.snapshot,
    this.errorMessage,
  });

  const MarketQuoteState.idle({List<MarketQuote> seedQuotes = const []})
      : status = MarketQuoteStatus.idle,
        quotes = seedQuotes,
        snapshot = null,
        errorMessage = null;

  const MarketQuoteState.loading({
    required this.quotes,
    this.snapshot,
  })  : status = MarketQuoteStatus.loading,
        errorMessage = null;

  MarketQuoteState.loaded(MarketQuoteSnapshot loadedSnapshot)
      : status = MarketQuoteStatus.loaded,
        quotes = loadedSnapshot.quotes,
        snapshot = loadedSnapshot,
        errorMessage = null;

  const MarketQuoteState.failure({
    required this.errorMessage,
    required this.quotes,
    this.snapshot,
  }) : status = MarketQuoteStatus.failure;

  final MarketQuoteStatus status;
  final List<MarketQuote> quotes;
  final MarketQuoteSnapshot? snapshot;
  final String? errorMessage;
}

class MarketQuoteSnapshot {
  const MarketQuoteSnapshot({
    required this.dataSource,
    required this.marketCoverage,
    required this.displayCurrency,
    required this.transportSnapshot,
    required this.transportRealtime,
    required this.cacheStatus,
    required this.quoteCount,
    required this.quotes,
    required this.servedAt,
  });

  final String dataSource;
  final String marketCoverage;
  final String displayCurrency;
  final String transportSnapshot;
  final String transportRealtime;
  final String cacheStatus;
  final int quoteCount;
  final List<MarketQuote> quotes;
  final DateTime? servedAt;

  static MarketQuoteSnapshot fromJson(Map<String, dynamic> json) {
    final transport = _map(json['transport']);
    final cache = _map(json['cache']);
    final quoteValues = json['quotes'];

    return MarketQuoteSnapshot(
      dataSource: _string(json['dataSource'], fallback: 'Stock-exchange-BE'),
      marketCoverage: _string(json['marketCoverage'], fallback: 'ALL'),
      displayCurrency: _string(json['displayCurrency'], fallback: 'USD'),
      transportSnapshot: _string(transport['snapshot'], fallback: 'REST'),
      transportRealtime: _string(transport['realtime'], fallback: 'WebSocket'),
      cacheStatus: _string(cache['status'], fallback: 'UNKNOWN'),
      quoteCount: json['quoteCount'] is int ? json['quoteCount'] as int : 0,
      quotes: quoteValues is List
          ? quoteValues.map((value) => MarketQuote.fromJson(_map(value))).toList()
          : const [],
      servedAt: _dateTime(json['servedAt']),
    );
  }
}

class MarketQuote {
  const MarketQuote({
    required this.stockCode,
    required this.stockName,
    required this.market,
    required this.currentPriceKrw,
    required this.changeRate,
    required this.volume,
    required this.localCurrency,
    required this.localCurrencyPrice,
    required this.fxRate,
    required this.fxRateTime,
    required this.fxRateSource,
    required this.fxStale,
    this.badge = 'Live',
  });

  final String stockCode;
  final String stockName;
  final String market;
  final String currentPriceKrw;
  final String changeRate;
  final int volume;
  final String localCurrency;
  final String localCurrencyPrice;
  final String fxRate;
  final DateTime? fxRateTime;
  final String fxRateSource;
  final bool fxStale;
  final String badge;

  String get krwDisplay => 'KRW $currentPriceKrw';

  String get localCurrencyDisplay => '$localCurrency $localCurrencyPrice';

  String get fxMeta {
    final time = fxRateTime?.toUtc().toIso8601String() ?? 'unknown time';
    final stale = fxStale ? ' / stale' : '';
    return 'FX $fxRate / $time / source $fxRateSource$stale';
  }

  static MarketQuote fromJson(Map<String, dynamic> json) {
    return MarketQuote(
      stockCode: _string(json['stockCode'], fallback: ''),
      stockName: _string(json['stockName'], fallback: 'Unknown stock'),
      market: _string(json['market'], fallback: 'UNKNOWN'),
      currentPriceKrw: _string(json['currentPriceKrw'], fallback: '0'),
      changeRate: _string(json['changeRate'], fallback: '0'),
      volume: json['volume'] is int ? json['volume'] as int : 0,
      localCurrency: _string(json['localCurrency'], fallback: 'USD'),
      localCurrencyPrice: _string(json['localCurrencyPrice'], fallback: '0'),
      fxRate: _string(json['fxRate'], fallback: '0'),
      fxRateTime: _dateTime(json['fxRateTime']),
      fxRateSource: _string(json['fxRateSource'], fallback: 'UNKNOWN'),
      fxStale: json['fxStale'] as bool? ?? false,
      badge: _string(json['market'], fallback: 'Live'),
    );
  }
}

class MarketQuoteController extends ValueNotifier<MarketQuoteState> {
  MarketQuoteController({
    required ExchangeApiClient apiClient,
    List<MarketQuote> seedQuotes = const [],
  })  : _apiClient = apiClient,
        super(MarketQuoteState.idle(seedQuotes: seedQuotes));

  final ExchangeApiClient _apiClient;

  Future<void> loadSnapshot({
    String? market,
    String currency = 'USD',
  }) async {
    return _load(
      loader: () => _apiClient.getMarketQuotes(
        market: market,
        currency: currency,
      ),
    );
  }

  Future<void> loadWatchlistSnapshot({
    required String? accountId,
    String? market,
    String currency = 'USD',
  }) async {
    if (accountId == null || accountId.isEmpty) {
      value = MarketQuoteState.failure(
        errorMessage: 'Sign in to load watchlist quotes.',
        quotes: value.quotes,
        snapshot: value.snapshot,
      );
      return;
    }

    return _load(
      loader: () => _apiClient.getWatchlistQuotes(
        accountId,
        market: market,
        currency: currency,
      ),
    );
  }

  Future<void> loadPortfolioSnapshot({
    required String? accountId,
    String? market,
    String currency = 'USD',
  }) async {
    if (accountId == null || accountId.isEmpty) {
      value = MarketQuoteState.failure(
        errorMessage: 'Sign in to load portfolio quotes.',
        quotes: value.quotes,
        snapshot: value.snapshot,
      );
      return;
    }

    return _load(
      loader: () => _apiClient.getPortfolioQuotes(
        accountId,
        market: market,
        currency: currency,
      ),
    );
  }

  Future<void> _load({
    required Future<ApiEnvelope<Map<String, dynamic>>> Function() loader,
  }) async {
    value = MarketQuoteState.loading(
      quotes: value.quotes,
      snapshot: value.snapshot,
    );

    try {
      final response = await loader();
      final snapshot = MarketQuoteSnapshot.fromJson(response.data ?? {});
      value = MarketQuoteState.loaded(snapshot);
    } on ExchangeApiException catch (error) {
      value = MarketQuoteState.failure(
        errorMessage: error.message,
        quotes: value.quotes,
        snapshot: value.snapshot,
      );
    } on Object {
      value = MarketQuoteState.failure(
        errorMessage: 'Unable to load market quotes.',
        quotes: value.quotes,
        snapshot: value.snapshot,
      );
    }
  }
}

const List<MarketQuote> seedMarketQuotes = [
  MarketQuote(
    stockCode: '005930',
    stockName: 'Samsung Electronics',
    market: 'KOSPI',
    currentPriceKrw: '82400',
    changeRate: '+1.23%',
    volume: 18300000,
    localCurrency: 'USD',
    localCurrencyPrice: '54.00',
    fxRate: '1525.93',
    fxRateTime: null,
    fxRateSource: 'Hana-OmniLens-API',
    fxStale: false,
    badge: 'Watchlist',
  ),
  MarketQuote(
    stockCode: '035420',
    stockName: 'NAVER',
    market: 'KOSPI',
    currentPriceKrw: '183700',
    changeRate: '-0.38%',
    volume: 925000,
    localCurrency: 'USD',
    localCurrencyPrice: '120.41',
    fxRate: '1525.59',
    fxRateTime: null,
    fxRateSource: 'Hana-OmniLens-API',
    fxStale: false,
    badge: 'Portfolio',
  ),
];

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

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
