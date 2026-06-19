import 'package:flutter/foundation.dart';

import 'exchange_api_client.dart';

enum TradeStatus {
  idle,
  loading,
  loaded,
  failure,
}

class TradeState {
  const TradeState({
    required this.status,
    this.portfolio,
    this.orderability,
    this.lastTrade,
    this.errorMessage,
  });

  const TradeState.idle()
      : status = TradeStatus.idle,
        portfolio = null,
        orderability = null,
        lastTrade = null,
        errorMessage = null;

  const TradeState.loading({
    this.portfolio,
    this.orderability,
    this.lastTrade,
  })  : status = TradeStatus.loading,
        errorMessage = null;

  const TradeState.loaded({
    this.portfolio,
    this.orderability,
    this.lastTrade,
  })  : status = TradeStatus.loaded,
        errorMessage = null;

  const TradeState.failure({
    required this.errorMessage,
    this.portfolio,
    this.orderability,
    this.lastTrade,
  }) : status = TradeStatus.failure;

  final TradeStatus status;
  final PortfolioSnapshot? portfolio;
  final TradeOrderability? orderability;
  final TradeExecution? lastTrade;
  final String? errorMessage;
}

class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.accountId,
    required this.currency,
    required this.cashBalanceUsd,
    required this.totalMarketValueUsd,
    required this.totalAssetValueUsd,
    required this.realizedPnlUsd,
    required this.unrealizedPnlUsd,
    required this.tradingMode,
    required this.holdings,
    required this.recentTrades,
  });

  final String accountId;
  final String currency;
  final String cashBalanceUsd;
  final String totalMarketValueUsd;
  final String totalAssetValueUsd;
  final String realizedPnlUsd;
  final String unrealizedPnlUsd;
  final String tradingMode;
  final List<MockHolding> holdings;
  final List<TradeExecution> recentTrades;

  static PortfolioSnapshot fromJson(Map<String, dynamic> json) {
    return PortfolioSnapshot(
      accountId: _string(json['accountId'], fallback: ''),
      currency: _string(json['currency'], fallback: 'USD'),
      cashBalanceUsd: _string(json['cashBalanceUsd'], fallback: '0.00'),
      totalMarketValueUsd:
          _string(json['totalMarketValueUsd'], fallback: '0.00'),
      totalAssetValueUsd: _string(json['totalAssetValueUsd'], fallback: '0.00'),
      realizedPnlUsd: _string(json['realizedPnlUsd'], fallback: '0.00'),
      unrealizedPnlUsd: _string(json['unrealizedPnlUsd'], fallback: '0.00'),
      tradingMode: _string(
        json['tradingMode'],
        fallback: 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
      ),
      holdings: _list(json['holdings'])
          .map((value) => MockHolding.fromJson(_map(value)))
          .toList(),
      recentTrades: _list(json['recentTrades'])
          .map((value) => TradeExecution.fromJson(_map(value)))
          .toList(),
    );
  }
}

class MockHolding {
  const MockHolding({
    required this.stockCode,
    required this.stockName,
    required this.quantity,
    required this.averagePriceUsd,
    required this.currentPriceUsd,
    required this.marketValueUsd,
    required this.unrealizedPnlUsd,
    required this.unrealizedPnlRate,
  });

  final String stockCode;
  final String stockName;
  final int quantity;
  final String averagePriceUsd;
  final String currentPriceUsd;
  final String marketValueUsd;
  final String unrealizedPnlUsd;
  final String unrealizedPnlRate;

  static MockHolding fromJson(Map<String, dynamic> json) {
    return MockHolding(
      stockCode: _string(json['stockCode'], fallback: ''),
      stockName: _string(json['stockName'], fallback: 'Unknown stock'),
      quantity: _int(json['quantity']),
      averagePriceUsd: _string(json['averagePriceUsd'], fallback: '0.00'),
      currentPriceUsd: _string(json['currentPriceUsd'], fallback: '0.00'),
      marketValueUsd: _string(json['marketValueUsd'], fallback: '0.00'),
      unrealizedPnlUsd: _string(json['unrealizedPnlUsd'], fallback: '0.00'),
      unrealizedPnlRate: _string(json['unrealizedPnlRate'], fallback: '0.00'),
    );
  }
}

class TradeOrderability {
  const TradeOrderability({
    required this.stockCode,
    required this.side,
    required this.quantity,
    required this.canPlaceMockOrder,
    required this.blockingReasons,
    required this.warnings,
    required this.orderabilitySource,
    required this.tradingMode,
  });

  final String stockCode;
  final String side;
  final int quantity;
  final bool canPlaceMockOrder;
  final List<String> blockingReasons;
  final List<String> warnings;
  final String orderabilitySource;
  final String tradingMode;

  String get summary {
    if (!canPlaceMockOrder && blockingReasons.isNotEmpty) {
      return 'Blocked: ${blockingReasons.map(_orderabilityMessage).join(', ')}';
    }
    if (warnings.isNotEmpty) {
      return 'Warnings: ${warnings.map(_orderabilityMessage).join(', ')}';
    }
    return 'Mock order is available.';
  }

  static TradeOrderability fromJson(Map<String, dynamic> json) {
    return TradeOrderability(
      stockCode: _string(json['stockCode'], fallback: ''),
      side: _string(json['side'], fallback: 'BUY'),
      quantity: _int(json['quantity']),
      canPlaceMockOrder: json['canPlaceMockOrder'] as bool? ?? false,
      blockingReasons: _list(json['blockingReasons']).map((v) => '$v').toList(),
      warnings: _list(json['warnings']).map((v) => '$v').toList(),
      orderabilitySource:
          _string(json['orderabilitySource'], fallback: 'Hana-OmniLens-API'),
      tradingMode: _string(
        json['tradingMode'],
        fallback: 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
      ),
    );
  }
}

String _orderabilityMessage(String code) {
  return switch (code) {
    'FOREIGN_LIMIT_EXCEEDED' =>
      'Foreign ownership limit would be exceeded',
    'TRADING_HALTED' => 'Trading is halted',
    'ORDER_NOT_ALLOWED' => 'Order is not allowed',
    'VI_ACTIVE' => 'Volatility interruption is active',
    'SINGLE_PRICE_TRADING' => 'Single-price trading is active',
    'BUY_AT_UPPER_LIMIT' => 'Buy order is at the upper price limit',
    'SELL_AT_LOWER_LIMIT' => 'Sell order is at the lower price limit',
    _ => code.replaceAll('_', ' ').toLowerCase(),
  };
}

class TradeExecution {
  const TradeExecution({
    required this.tradeId,
    required this.stockCode,
    required this.stockName,
    required this.side,
    required this.quantity,
    required this.executionPriceUsd,
    required this.grossAmountUsd,
    required this.realizedPnlUsd,
    required this.remainingQuantity,
    required this.cashBalanceUsdAfter,
    required this.tradingMode,
  });

  final String tradeId;
  final String stockCode;
  final String stockName;
  final String side;
  final int quantity;
  final String executionPriceUsd;
  final String grossAmountUsd;
  final String realizedPnlUsd;
  final int remainingQuantity;
  final String cashBalanceUsdAfter;
  final String tradingMode;

  bool get isSell => side.toUpperCase() == 'SELL';

  String get realizedPnlDisplay => 'USD $realizedPnlUsd';

  String get summary =>
      '$side $quantity $stockName at USD $executionPriceUsd / gross USD $grossAmountUsd';

  static TradeExecution fromJson(Map<String, dynamic> json) {
    return TradeExecution(
      tradeId: _string(json['tradeId'], fallback: ''),
      stockCode: _string(json['stockCode'], fallback: ''),
      stockName: _string(json['stockName'], fallback: 'Unknown stock'),
      side: _string(json['side'], fallback: 'BUY'),
      quantity: _int(json['quantity']),
      executionPriceUsd: _string(json['executionPriceUsd'], fallback: '0.00'),
      grossAmountUsd: _string(json['grossAmountUsd'], fallback: '0.00'),
      realizedPnlUsd: _string(json['realizedPnlUsd'], fallback: '0.00'),
      remainingQuantity: _int(json['remainingQuantity']),
      cashBalanceUsdAfter:
          _string(json['cashBalanceUsdAfter'], fallback: '0.00'),
      tradingMode: _string(
        json['tradingMode'],
        fallback: 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
      ),
    );
  }
}

class TradeController extends ValueNotifier<TradeState> {
  TradeController({required ExchangeApiClient apiClient})
      : _apiClient = apiClient,
        super(const TradeState.idle());

  final ExchangeApiClient _apiClient;

  Future<void> loadPortfolio(String? accountId) async {
    if (accountId == null || accountId.isEmpty) {
      value = TradeState.failure(
        errorMessage: 'Sign in to load mock portfolio.',
        portfolio: value.portfolio,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
      );
      return;
    }

    await _run(() async {
      final response = await _apiClient.getPortfolio(accountId);
      value = TradeState.loaded(
        portfolio: PortfolioSnapshot.fromJson(response.data ?? {}),
        orderability: value.orderability,
        lastTrade: value.lastTrade,
      );
    });
  }

  Future<void> checkOrderability({
    required String? accountId,
    required String stockCode,
    required String side,
    required int quantity,
  }) async {
    if (!_isValid(accountId, stockCode, quantity)) {
      return;
    }

    await _run(() async {
      final response = await _apiClient.checkOrderability(
        accountId: accountId!,
        stockCode: stockCode,
        side: side,
        quantity: quantity,
      );
      value = TradeState.loaded(
        portfolio: value.portfolio,
        orderability: TradeOrderability.fromJson(response.data ?? {}),
        lastTrade: value.lastTrade,
      );
    });
  }

  Future<void> executeTrade({
    required String? accountId,
    required String stockCode,
    required String side,
    required int quantity,
  }) async {
    if (!_isValid(accountId, stockCode, quantity)) {
      return;
    }

    await _run(() async {
      final response = await _apiClient.executeTrade(
        accountId: accountId!,
        stockCode: stockCode,
        side: side,
        quantity: quantity,
      );
      final trade = TradeExecution.fromJson(response.data ?? {});
      final portfolioResponse = await _apiClient.getPortfolio(accountId);
      value = TradeState.loaded(
        portfolio: PortfolioSnapshot.fromJson(portfolioResponse.data ?? {}),
        orderability: value.orderability,
        lastTrade: trade,
      );
    });
  }

  bool _isValid(String? accountId, String stockCode, int quantity) {
    if (accountId == null || accountId.isEmpty) {
      value = TradeState.failure(
        errorMessage: 'Sign in before placing a mock order.',
        portfolio: value.portfolio,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
      );
      return false;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(stockCode)) {
      value = TradeState.failure(
        errorMessage: 'Enter a 6 digit Korean stock code.',
        portfolio: value.portfolio,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
      );
      return false;
    }
    if (quantity < 1) {
      value = TradeState.failure(
        errorMessage: 'Quantity must be at least 1.',
        portfolio: value.portfolio,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
      );
      return false;
    }
    return true;
  }

  Future<void> _run(Future<void> Function() action) async {
    value = TradeState.loading(
      portfolio: value.portfolio,
      orderability: value.orderability,
      lastTrade: value.lastTrade,
    );
    try {
      await action();
    } on ExchangeApiException catch (error) {
      value = TradeState.failure(
        errorMessage: error.message,
        portfolio: value.portfolio,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
      );
    } on Object {
      value = TradeState.failure(
        errorMessage: 'Unable to process mock trade.',
        portfolio: value.portfolio,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
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

List<Object?> _list(Object? value) {
  if (value is List) {
    return value;
  }
  return const [];
}

String _string(Object? value, {required String fallback}) {
  if (value == null) {
    return fallback;
  }
  return '$value';
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
