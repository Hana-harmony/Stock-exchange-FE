import 'dart:async';

import 'package:flutter/foundation.dart';

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
  });

  const MarketQuoteState.idle({List<MarketQuote> seedQuotes = const []})
      : status = MarketQuoteStatus.idle,
        quotes = seedQuotes,
        liveStatus = MarketQuoteLiveStatus.disconnected,
        snapshot = null,
        errorMessage = null,
        liveMessage = null,
        lastTickAt = null;

  const MarketQuoteState.loading({
    required this.quotes,
    this.liveStatus = MarketQuoteLiveStatus.disconnected,
    this.snapshot,
    this.liveMessage,
    this.lastTickAt,
  })  : status = MarketQuoteStatus.loading,
        errorMessage = null;

  MarketQuoteState.loaded(
    MarketQuoteSnapshot loadedSnapshot, {
    this.liveStatus = MarketQuoteLiveStatus.disconnected,
    this.liveMessage,
    this.lastTickAt,
  })
      : status = MarketQuoteStatus.loaded,
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
  }) : status = MarketQuoteStatus.failure;

  final MarketQuoteStatus status;
  final List<MarketQuote> quotes;
  final MarketQuoteLiveStatus liveStatus;
  final MarketQuoteSnapshot? snapshot;
  final String? errorMessage;
  final String? liveMessage;
  final DateTime? lastTickAt;

  MarketQuoteState copyWith({
    MarketQuoteStatus? status,
    List<MarketQuote>? quotes,
    MarketQuoteLiveStatus? liveStatus,
    MarketQuoteSnapshot? snapshot,
    String? errorMessage,
    String? liveMessage,
    DateTime? lastTickAt,
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
      liveStatus: value.liveStatus,
      snapshot: value.snapshot,
      liveMessage: value.liveMessage,
      lastTickAt: value.lastTickAt,
    );

    try {
      final response = await loader();
      final snapshot = MarketQuoteSnapshot.fromJson(response.data ?? {});
      value = MarketQuoteState.loaded(
        snapshot,
        liveStatus: value.liveStatus,
        liveMessage: value.liveMessage,
        lastTickAt: value.lastTickAt,
      );
    } on ExchangeApiException catch (error) {
      value = MarketQuoteState.failure(
        errorMessage: error.message,
        quotes: value.quotes,
        liveStatus: value.liveStatus,
        snapshot: value.snapshot,
        liveMessage: value.liveMessage,
        lastTickAt: value.lastTickAt,
      );
    } on Object {
      value = MarketQuoteState.failure(
        errorMessage: 'Unable to load market quotes.',
        quotes: value.quotes,
        liveStatus: value.liveStatus,
        snapshot: value.snapshot,
        liveMessage: value.liveMessage,
        lastTickAt: value.lastTickAt,
      );
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
      );
      return;
    }

    final delay = _liveReconnectDelays[_liveReconnectAttempt];
    _liveReconnectAttempt += 1;
    value = value.copyWith(
      liveStatus: MarketQuoteLiveStatus.connecting,
      liveMessage:
          '$reason Reconnecting quote WebSocket in ${delay.inSeconds}s.',
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
      nextQuotes[index] = tick;
    } else {
      nextQuotes.insert(0, tick);
    }

    value = value.copyWith(
      quotes: nextQuotes,
      liveStatus: MarketQuoteLiveStatus.live,
      liveMessage: 'Live tick ${tick.stockCode} received.',
      lastTickAt: DateTime.now().toUtc(),
      clearErrorMessage: true,
    );
  }

  @override
  void dispose() {
    _liveReconnectTimer?.cancel();
    _liveSubscription?.cancel();
    super.dispose();
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
