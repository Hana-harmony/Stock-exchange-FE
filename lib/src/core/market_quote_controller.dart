import 'dart:async';

import 'package:flutter/foundation.dart';

import 'currency_format.dart';
import 'exchange_api_client.dart';
import 'market_quote_live_client.dart';

enum MarketQuoteStatus {
  idle,
  loading,
  loaded,
  failure,
}

enum MarketQuoteLiveStatus {
  disconnected,
  connecting,
  live,
  failure,
}

class MarketQuoteState {
  const MarketQuoteState({
    required this.status,
    required this.quotes,
    this.liveStatus = MarketQuoteLiveStatus.disconnected,
    this.snapshot,
    this.errorMessage,
    this.liveMessage,
    this.lastTickAt,
    this.liveStale = false,
  });

  const MarketQuoteState.idle({List<MarketQuote> seedQuotes = const []})
      : status = MarketQuoteStatus.idle,
        quotes = seedQuotes,
        liveStatus = MarketQuoteLiveStatus.disconnected,
        snapshot = null,
        errorMessage = null,
        liveMessage = null,
        lastTickAt = null,
        liveStale = false;

  const MarketQuoteState.loading({
    required this.quotes,
    this.liveStatus = MarketQuoteLiveStatus.disconnected,
    this.snapshot,
    this.liveMessage,
    this.lastTickAt,
    this.liveStale = false,
  })  : status = MarketQuoteStatus.loading,
        errorMessage = null;

  MarketQuoteState.loaded(
    MarketQuoteSnapshot loadedSnapshot, {
    this.liveStatus = MarketQuoteLiveStatus.disconnected,
    this.liveMessage,
    this.lastTickAt,
    this.liveStale = false,
  })  : status = MarketQuoteStatus.loaded,
        quotes = loadedSnapshot.quotes,
        snapshot = loadedSnapshot,
        errorMessage = null;

  const MarketQuoteState.failure({
    required this.errorMessage,
    required this.quotes,
    this.liveStatus = MarketQuoteLiveStatus.disconnected,
    this.snapshot,
    this.liveMessage,
    this.lastTickAt,
    this.liveStale = false,
  }) : status = MarketQuoteStatus.failure;

  final MarketQuoteStatus status;
  final List<MarketQuote> quotes;
  final MarketQuoteLiveStatus liveStatus;
  final MarketQuoteSnapshot? snapshot;
  final String? errorMessage;
  final String? liveMessage;
  final DateTime? lastTickAt;
  final bool liveStale;

  MarketQuoteState copyWith({
    MarketQuoteStatus? status,
    List<MarketQuote>? quotes,
    MarketQuoteLiveStatus? liveStatus,
    MarketQuoteSnapshot? snapshot,
    String? errorMessage,
    String? liveMessage,
    DateTime? lastTickAt,
    bool? liveStale,
    bool clearErrorMessage = false,
    bool clearLiveMessage = false,
  }) {
    return MarketQuoteState(
      status: status ?? this.status,
      quotes: quotes ?? this.quotes,
      liveStatus: liveStatus ?? this.liveStatus,
      snapshot: snapshot ?? this.snapshot,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      liveMessage: clearLiveMessage ? null : liveMessage ?? this.liveMessage,
      lastTickAt: lastTickAt ?? this.lastTickAt,
      liveStale: liveStale ?? this.liveStale,
    );
  }
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
          ? quoteValues
              .map((value) => MarketQuote.fromJson(_map(value)))
              .toList()
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
    this.marketSession = 'REGULAR',
    this.afterHoursPriceKrw,
    this.afterHoursLocalCurrencyPrice,
    this.afterHoursChangeRate,
    this.afterHoursVolume,
    this.afterHoursMarketDataTime,
    required this.localCurrency,
    required this.localCurrencyPrice,
    required this.fxRate,
    required this.fxRateTime,
    required this.fxRateSource,
    required this.fxStale,
    this.marketDataTime,
    this.publishedAt,
    this.badge = 'Live',
  });

  final String stockCode;
  final String stockName;
  final String market;
  final String currentPriceKrw;
  final String changeRate;
  final int volume;
  final String marketSession;
  final String? afterHoursPriceKrw;
  final String? afterHoursLocalCurrencyPrice;
  final String? afterHoursChangeRate;
  final int? afterHoursVolume;
  final DateTime? afterHoursMarketDataTime;
  final String localCurrency;
  final String localCurrencyPrice;
  final String fxRate;
  final DateTime? fxRateTime;
  final String fxRateSource;
  final bool fxStale;
  final DateTime? marketDataTime;
  final DateTime? publishedAt;
  final String badge;

  String get krwDisplay => formatCurrencyDisplay('KRW', currentPriceKrw);

  String get localCurrencyDisplay =>
      formatCurrencyDisplay(localCurrency, effectiveLocalCurrencyPrice);

  String get effectiveLocalCurrencyPrice {
    final parsedLocal = _positiveDouble(localCurrencyPrice);
    if (parsedLocal != null) {
      return parsedLocal.toStringAsFixed(2);
    }

    final parsedKrw = _positiveDouble(currentPriceKrw);
    final parsedFx = _positiveDouble(fxRate);
    if (parsedKrw == null || parsedFx == null) {
      return localCurrencyPrice;
    }
    final converted =
        parsedFx < 1 ? parsedKrw * parsedFx : parsedKrw / parsedFx;
    return converted.toStringAsFixed(2);
  }

  bool get isAfterHours => marketSession.toUpperCase() == 'AFTER_HOURS';

  bool get hasAfterHoursPrice =>
      afterHoursLocalCurrencyPrice != null &&
      afterHoursLocalCurrencyPrice!.trim().isNotEmpty;

  String get afterHoursLocalCurrencyDisplay => formatCurrencyDisplay(
        localCurrency,
        afterHoursLocalCurrencyPrice ?? localCurrencyPrice,
      );

  String get afterHoursKrwDisplay =>
      'KRW ${afterHoursPriceKrw ?? currentPriceKrw}';

  String get fxTimeDisplay =>
      fxRateTime == null ? 'unknown time' : _displayTime(fxRateTime!);

  String get liveUpdateKey =>
      publishedAt?.toUtc().toIso8601String() ??
      marketDataTime?.toUtc().toIso8601String() ??
      localCurrencyPrice;

  String get fxMeta {
    final stale = fxStale ? ' / stale' : '';
    return 'FX $fxRate / $fxTimeDisplay / source $fxRateSource$stale';
  }

  MarketQuote mergeRegularTick(MarketQuote tick) {
    return MarketQuote(
      stockCode: stockCode,
      stockName: stockName.trim().isEmpty ? tick.stockName : stockName,
      market: market.trim().isEmpty ? tick.market : market,
      currentPriceKrw: tick.currentPriceKrw,
      changeRate: tick.changeRate,
      volume: tick.volume,
      marketSession: tick.marketSession,
      afterHoursPriceKrw: tick.afterHoursPriceKrw,
      afterHoursLocalCurrencyPrice: tick.afterHoursLocalCurrencyPrice,
      afterHoursChangeRate: tick.afterHoursChangeRate,
      afterHoursVolume: tick.afterHoursVolume,
      afterHoursMarketDataTime: tick.afterHoursMarketDataTime,
      localCurrency: tick.localCurrency,
      localCurrencyPrice: tick.localCurrencyPrice,
      fxRate: tick.fxRate,
      fxRateTime: tick.fxRateTime,
      fxRateSource: tick.fxRateSource,
      fxStale: tick.fxStale,
      marketDataTime: tick.marketDataTime,
      publishedAt: tick.publishedAt,
      badge: tick.badge,
    );
  }

  static MarketQuote fromJson(Map<String, dynamic> json) {
    return MarketQuote(
      stockCode: _string(json['stockCode'], fallback: ''),
      stockName: _string(json['stockName'], fallback: 'Unknown stock'),
      market: _string(json['market'], fallback: 'UNKNOWN'),
      currentPriceKrw: _string(json['currentPriceKrw'], fallback: '0'),
      changeRate: _string(json['changeRate'], fallback: '0'),
      volume: json['volume'] is int ? json['volume'] as int : 0,
      marketSession: _string(json['marketSession'], fallback: 'REGULAR'),
      afterHoursPriceKrw: _nullableString(json['afterHoursPriceKrw']),
      afterHoursLocalCurrencyPrice:
          _nullableString(json['afterHoursLocalCurrencyPrice']),
      afterHoursChangeRate: _nullableString(json['afterHoursChangeRate']),
      afterHoursVolume: json['afterHoursVolume'] is int
          ? json['afterHoursVolume'] as int
          : null,
      afterHoursMarketDataTime: _dateTime(json['afterHoursMarketDataTime']),
      localCurrency: _string(json['localCurrency'], fallback: 'USD'),
      localCurrencyPrice: _string(json['localCurrencyPrice'], fallback: '0'),
      fxRate: _string(json['fxRate'], fallback: '0'),
      fxRateTime: _dateTime(json['fxRateTime']),
      fxRateSource: _string(json['fxRateSource'], fallback: 'UNKNOWN'),
      fxStale: json['fxStale'] as bool? ?? false,
      marketDataTime: _dateTime(json['marketDataTime']),
      publishedAt: _dateTime(json['publishedAt']),
      badge: _string(json['market'], fallback: 'Live'),
    );
  }

  MarketQuote mergeAfterHoursTick(MarketQuote tick) {
    return MarketQuote(
      stockCode: stockCode,
      stockName: tick.stockName.isEmpty ? stockName : tick.stockName,
      market: tick.market.isEmpty ? market : tick.market,
      currentPriceKrw: currentPriceKrw,
      changeRate: changeRate,
      volume: volume,
      marketSession: tick.marketSession,
      afterHoursPriceKrw: tick.afterHoursPriceKrw ?? tick.currentPriceKrw,
      afterHoursLocalCurrencyPrice:
          tick.afterHoursLocalCurrencyPrice ?? tick.localCurrencyPrice,
      afterHoursChangeRate: tick.afterHoursChangeRate ?? tick.changeRate,
      afterHoursVolume: tick.afterHoursVolume ?? tick.volume,
      afterHoursMarketDataTime:
          tick.afterHoursMarketDataTime ?? tick.marketDataTime,
      localCurrency: tick.localCurrency,
      localCurrencyPrice: localCurrencyPrice,
      fxRate: tick.fxRate,
      fxRateTime: tick.fxRateTime,
      fxRateSource: tick.fxRateSource,
      fxStale: tick.fxStale,
      marketDataTime: marketDataTime,
      publishedAt: tick.publishedAt,
      badge: badge,
    );
  }
}

class MarketQuoteController extends ValueNotifier<MarketQuoteState> {
  MarketQuoteController({
    required ExchangeApiClient apiClient,
    MarketQuoteLiveClient? liveClient,
    List<Duration> liveReconnectDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 3),
      Duration(seconds: 5),
    ],
    List<MarketQuote> seedQuotes = const [],
  })  : _apiClient = apiClient,
        _liveClient = liveClient,
        _liveReconnectDelays = liveReconnectDelays,
        super(MarketQuoteState.idle(seedQuotes: seedQuotes));

  final ExchangeApiClient _apiClient;
  final MarketQuoteLiveClient? _liveClient;
  final List<Duration> _liveReconnectDelays;
  StreamSubscription<Map<String, dynamic>>? _liveSubscription;
  Timer? _liveReconnectTimer;
  MarketQuoteLiveSubscription? _activeLiveRequest;
  int _liveReconnectAttempt = 0;

  bool get canSubscribeLive => _liveClient != null;

  bool get hasGeneralLiveSubscription {
    final request = _activeLiveRequest;
    return request != null &&
        request.accountId == null &&
        request.accountScope == null &&
        request.stockCodes.isEmpty;
  }

  MarketQuote? quoteFor(String stockCode) {
    final normalized = stockCode.trim();
    if (normalized.isEmpty) {
      return null;
    }
    for (final quote in value.quotes) {
      if (quote.stockCode == normalized) {
        return quote;
      }
    }
    return null;
  }

  Future<StockSearchResponse> searchStocks({
    required String query,
    String? market,
    String currency = 'USD',
    int limit = 20,
  }) async {
    final response = await _apiClient.searchStocks(
      query: query,
      market: market,
      currency: currency,
      limit: limit,
    );
    return StockSearchResponse.fromJson(response.data ?? {});
  }

  Future<StockSearchRankingResponse> loadSearchRankings({
    int windowHours = 24,
    int limit = 10,
  }) async {
    final response = await _apiClient.getStockSearchRankings(
      windowHours: windowHours,
      limit: limit,
    );
    return StockSearchRankingResponse.fromJson(response.data ?? {});
  }

  Future<void> recordSearchSelection(StockSearchItem item) async {
    try {
      await _apiClient.recordStockSearchEvent(
        stockCode: item.stockCode,
        stockName: item.stockName,
        market: item.market,
        sector: item.sector,
      );
    } on Object {
      // 검색 통계 적재 실패는 종목 상세 진입을 막지 않는다.
    }
  }

  Future<void> loadSnapshot({
    String? market,
    String currency = 'USD',
    List<String> stockCodes = const [],
  }) async {
    return _load(
      loader: () => _apiClient.getMarketQuotes(
        market: market,
        currency: currency,
        stockCodes: stockCodes,
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
      liveStatus: value.liveStatus,
      snapshot: value.snapshot,
      liveMessage: value.liveMessage,
      lastTickAt: value.lastTickAt,
      liveStale: value.liveStale,
    );

    try {
      final response = await _loadWithTimeoutRetry(loader);
      final snapshot = MarketQuoteSnapshot.fromJson(response.data ?? {});
      value = MarketQuoteState.loaded(
        _snapshotWithVisibleLiveQuotes(snapshot, value.quotes),
        liveStatus: value.liveStatus,
        liveMessage: value.liveMessage,
        lastTickAt: value.lastTickAt,
        liveStale: value.liveStale,
      );
    } on ExchangeApiException catch (error) {
      value = MarketQuoteState.failure(
        errorMessage: error.message,
        quotes: value.quotes,
        liveStatus: value.liveStatus,
        snapshot: value.snapshot,
        liveMessage: value.liveMessage,
        lastTickAt: value.lastTickAt,
        liveStale: value.liveStale,
      );
    } on Object {
      value = MarketQuoteState.failure(
        errorMessage: 'Unable to load market quotes.',
        quotes: value.quotes,
        liveStatus: value.liveStatus,
        snapshot: value.snapshot,
        liveMessage: value.liveMessage,
        lastTickAt: value.lastTickAt,
        liveStale: value.liveStale,
      );
    }
  }

  Future<ApiEnvelope<Map<String, dynamic>>> _loadWithTimeoutRetry(
    Future<ApiEnvelope<Map<String, dynamic>>> Function() loader,
  ) async {
    try {
      return await loader();
    } on ExchangeApiException catch (error) {
      if (error.code != 'EXCHANGE_API_TIMEOUT') {
        rethrow;
      }
      // 첫 캐시 생성 중 지연되는 quote API는 한 번 더 확인한다.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return loader();
    }
  }

  Future<void> subscribeLive({
    String? market,
    List<String> stockCodes = const [],
    String? accountId,
    MarketQuoteAccountScope? accountScope,
  }) async {
    final liveClient = _liveClient;
    if (liveClient == null) {
      value = value.copyWith(
        liveStatus: MarketQuoteLiveStatus.failure,
        liveMessage: 'Quote WebSocket client is not configured.',
      );
      return;
    }

    await unsubscribeLive();
    final liveRequest = MarketQuoteLiveSubscription(
      market: market,
      stockCodes: stockCodes,
      accountId: accountId,
      accountScope: accountScope,
    );
    _activeLiveRequest = liveRequest;
    _liveReconnectAttempt = 0;
    value = value.copyWith(
      liveStatus: MarketQuoteLiveStatus.connecting,
      liveMessage: 'Connecting quote WebSocket.',
      liveStale: false,
      clearErrorMessage: true,
    );

    _openLiveSubscription(liveClient, liveRequest);
  }

  Future<void> unsubscribeLive() async {
    _activeLiveRequest = null;
    _liveReconnectAttempt = 0;
    _liveReconnectTimer?.cancel();
    _liveReconnectTimer = null;
    await _liveSubscription?.cancel();
    _liveSubscription = null;
    if (value.liveStatus != MarketQuoteLiveStatus.disconnected) {
      value = value.copyWith(
        liveStatus: MarketQuoteLiveStatus.disconnected,
        liveMessage: 'Quote WebSocket disconnected.',
        liveStale: false,
      );
    }
  }

  void _openLiveSubscription(
    MarketQuoteLiveClient liveClient,
    MarketQuoteLiveSubscription liveRequest,
  ) {
    _liveSubscription = liveClient.subscribe(liveRequest).listen(
      (tick) {
        _liveReconnectAttempt = 0;
        _applyLiveTick(MarketQuote.fromJson(tick));
      },
      onError: (_) => _scheduleLiveReconnect(
        liveClient,
        liveRequest,
        reason: 'Quote WebSocket disconnected.',
      ),
      onDone: () => _scheduleLiveReconnect(
        liveClient,
        liveRequest,
        reason: 'Quote WebSocket closed.',
      ),
    );
  }

  void _scheduleLiveReconnect(
    MarketQuoteLiveClient liveClient,
    MarketQuoteLiveSubscription liveRequest, {
    required String reason,
  }) {
    if (_activeLiveRequest != liveRequest) {
      return;
    }
    if (_liveReconnectAttempt >= _liveReconnectDelays.length) {
      value = value.copyWith(
        liveStatus: MarketQuoteLiveStatus.failure,
        liveMessage: '$reason Reconnect attempts exhausted.',
        liveStale: value.lastTickAt != null,
      );
      return;
    }

    final delay = _liveReconnectDelays[_liveReconnectAttempt];
    _liveReconnectAttempt += 1;
    value = value.copyWith(
      liveStatus: MarketQuoteLiveStatus.connecting,
      liveMessage:
          '$reason Reconnecting quote WebSocket in ${delay.inSeconds}s.',
      liveStale: value.lastTickAt != null,
    );

    _liveReconnectTimer?.cancel();
    _liveReconnectTimer = Timer(delay, () {
      if (_activeLiveRequest == liveRequest) {
        _openLiveSubscription(liveClient, liveRequest);
      }
    });
  }

  void _applyLiveTick(MarketQuote tick) {
    final nextQuotes = List<MarketQuote>.of(value.quotes);
    final index =
        nextQuotes.indexWhere((quote) => quote.stockCode == tick.stockCode);
    if (index >= 0) {
      nextQuotes[index] = tick.isAfterHours
          ? nextQuotes[index].mergeAfterHoursTick(tick)
          : nextQuotes[index].mergeRegularTick(tick);
    } else {
      nextQuotes.insert(0, tick);
    }

    value = value.copyWith(
      quotes: nextQuotes,
      liveStatus: MarketQuoteLiveStatus.live,
      liveMessage: 'Live tick ${tick.stockCode} received.',
      lastTickAt: DateTime.now().toUtc(),
      liveStale: false,
      clearErrorMessage: true,
    );
  }

  MarketQuoteSnapshot _snapshotWithVisibleLiveQuotes(
    MarketQuoteSnapshot snapshot,
    List<MarketQuote> visibleQuotes,
  ) {
    if (value.liveStatus != MarketQuoteLiveStatus.live ||
        visibleQuotes.isEmpty ||
        snapshot.quotes.isEmpty) {
      return snapshot;
    }
    final liveByCode = {
      for (final quote in visibleQuotes) quote.stockCode: quote,
    };
    final mergedQuotes = snapshot.quotes
        .map((quote) => liveByCode[quote.stockCode] ?? quote)
        .toList(growable: false);
    return MarketQuoteSnapshot(
      dataSource: snapshot.dataSource,
      marketCoverage: snapshot.marketCoverage,
      displayCurrency: snapshot.displayCurrency,
      transportSnapshot: snapshot.transportSnapshot,
      transportRealtime: snapshot.transportRealtime,
      cacheStatus: snapshot.cacheStatus,
      quoteCount: snapshot.quoteCount,
      quotes: mergedQuotes,
      servedAt: snapshot.servedAt,
    );
  }

  @override
  void dispose() {
    _liveReconnectTimer?.cancel();
    _liveSubscription?.cancel();
    super.dispose();
  }
}

class StockSearchResponse {
  const StockSearchResponse({
    required this.query,
    required this.marketFilter,
    required this.displayCurrency,
    required this.resultCount,
    required this.results,
  });

  final String query;
  final String marketFilter;
  final String displayCurrency;
  final int resultCount;
  final List<StockSearchItem> results;

  static StockSearchResponse fromJson(Map<String, dynamic> json) {
    final values = json['results'];
    return StockSearchResponse(
      query: _string(json['query'], fallback: ''),
      marketFilter: _string(json['marketFilter'], fallback: 'ALL'),
      displayCurrency: _string(json['displayCurrency'], fallback: 'USD'),
      resultCount: json['resultCount'] is int ? json['resultCount'] as int : 0,
      results: values is List
          ? values
              .map((value) => StockSearchItem.fromJson(_map(value)))
              .toList(growable: false)
          : const [],
    );
  }
}

class StockSearchItem {
  const StockSearchItem({
    required this.stockCode,
    required this.stockName,
    required this.market,
    required this.sector,
    required this.dataSource,
  });

  final String stockCode;
  final String stockName;
  final String market;
  final String sector;
  final String dataSource;

  static StockSearchItem fromJson(Map<String, dynamic> json) {
    return StockSearchItem(
      stockCode: _string(json['stockCode'], fallback: ''),
      stockName: _string(json['stockName'], fallback: 'Unknown stock'),
      market: _string(json['market'], fallback: 'UNKNOWN'),
      sector: _string(json['sector'], fallback: ''),
      dataSource: _string(json['dataSource'], fallback: ''),
    );
  }
}

class StockSearchRankingResponse {
  const StockSearchRankingResponse({
    required this.windowHours,
    required this.resultCount,
    required this.results,
    required this.servedAt,
  });

  final int windowHours;
  final int resultCount;
  final List<StockSearchRankingItem> results;
  final DateTime? servedAt;

  static StockSearchRankingResponse fromJson(Map<String, dynamic> json) {
    final values = json['results'];
    return StockSearchRankingResponse(
      windowHours: json['windowHours'] is int ? json['windowHours'] as int : 24,
      resultCount: json['resultCount'] is int ? json['resultCount'] as int : 0,
      results: values is List
          ? values
              .map((value) => StockSearchRankingItem.fromJson(_map(value)))
              .toList(growable: false)
          : const [],
      servedAt: _dateTime(json['servedAt']),
    );
  }
}

class StockSearchRankingItem {
  const StockSearchRankingItem({
    required this.rank,
    required this.stockCode,
    required this.stockName,
    required this.market,
    required this.sector,
    required this.searchCount,
    required this.lastSearchedAt,
  });

  final int rank;
  final String stockCode;
  final String stockName;
  final String market;
  final String sector;
  final int searchCount;
  final DateTime? lastSearchedAt;

  StockSearchItem toSearchItem() {
    return StockSearchItem(
      stockCode: stockCode,
      stockName: stockName,
      market: market,
      sector: sector,
      dataSource: 'Search analytics',
    );
  }

  static StockSearchRankingItem fromJson(Map<String, dynamic> json) {
    return StockSearchRankingItem(
      rank: json['rank'] is int ? json['rank'] as int : 0,
      stockCode: _string(json['stockCode'], fallback: ''),
      stockName: _string(json['stockName'], fallback: 'Unknown stock'),
      market: _string(json['market'], fallback: ''),
      sector: _string(json['sector'], fallback: ''),
      searchCount: json['searchCount'] is int ? json['searchCount'] as int : 0,
      lastSearchedAt: _dateTime(json['lastSearchedAt']),
    );
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

String? _nullableString(Object? value) {
  if (value == null) {
    return null;
  }
  final text = '$value'.trim();
  return text.isEmpty ? null : text;
}

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

double? _positiveDouble(String value) {
  final parsed = double.tryParse(value.replaceAll(',', '').trim());
  if (parsed == null || parsed <= 0) {
    return null;
  }
  return parsed;
}

String _displayTime(DateTime value) {
  final utc = value.toUtc();
  final kst = utc.add(const Duration(hours: 9));
  String two(int number) => number.toString().padLeft(2, '0');
  return '${kst.year}-${two(kst.month)}-${two(kst.day)} '
      '${two(kst.hour)}:${two(kst.minute)} KST';
}
