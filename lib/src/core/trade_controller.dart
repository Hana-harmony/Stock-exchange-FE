import 'package:flutter/foundation.dart';

import 'currency_format.dart';
import 'exchange_api_client.dart';

enum TradeStatus { idle, loading, loaded, failure }

class TradeState {
  const TradeState({
    required this.status,
    this.portfolio,
    this.tradeHistory = const [],
    this.orderHistory = const [],
    this.orderability,
    this.lastTrade,
    this.lastOrder,
    this.errorMessage,
  });

  const TradeState.idle()
      : status = TradeStatus.idle,
        portfolio = null,
        tradeHistory = const [],
        orderHistory = const [],
        orderability = null,
        lastTrade = null,
        lastOrder = null,
        errorMessage = null;

  const TradeState.loading({
    this.portfolio,
    this.tradeHistory = const [],
    this.orderHistory = const [],
    this.orderability,
    this.lastTrade,
    this.lastOrder,
  })  : status = TradeStatus.loading,
        errorMessage = null;

  const TradeState.loaded({
    this.portfolio,
    this.tradeHistory = const [],
    this.orderHistory = const [],
    this.orderability,
    this.lastTrade,
    this.lastOrder,
  })  : status = TradeStatus.loaded,
        errorMessage = null;

  const TradeState.failure({
    required this.errorMessage,
    this.portfolio,
    this.tradeHistory = const [],
    this.orderHistory = const [],
    this.orderability,
    this.lastTrade,
    this.lastOrder,
  }) : status = TradeStatus.failure;

  final TradeStatus status;
  final PortfolioSnapshot? portfolio;
  final List<TradeExecution> tradeHistory;
  final List<TradeOrderPlacement> orderHistory;
  final TradeOrderability? orderability;
  final TradeExecution? lastTrade;
  final TradeOrderPlacement? lastOrder;
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

  String get cashBalanceDisplay =>
      formatCurrencyDisplay(currency, cashBalanceUsd);

  String get totalMarketValueDisplay =>
      formatCurrencyDisplay(currency, totalMarketValueUsd);

  String get totalAssetValueDisplay =>
      formatCurrencyDisplay(currency, totalAssetValueUsd);

  String get realizedPnlDisplay =>
      formatCurrencyDisplay(currency, realizedPnlUsd);

  String get unrealizedPnlDisplay =>
      formatCurrencyDisplay(currency, unrealizedPnlUsd);
  final List<MockHolding> holdings;
  final List<TradeExecution> recentTrades;

  static PortfolioSnapshot fromJson(Map<String, dynamic> json) {
    return PortfolioSnapshot(
      accountId: _string(json['accountId'], fallback: ''),
      currency: _string(json['currency'], fallback: 'USD'),
      cashBalanceUsd: _string(json['cashBalanceUsd'], fallback: '0.00'),
      totalMarketValueUsd: _string(
        json['totalMarketValueUsd'],
        fallback: '0.00',
      ),
      totalAssetValueUsd: _string(json['totalAssetValueUsd'], fallback: '0.00'),
      realizedPnlUsd: _string(json['realizedPnlUsd'], fallback: '0.00'),
      unrealizedPnlUsd: _string(json['unrealizedPnlUsd'], fallback: '0.00'),
      tradingMode: _string(
        json['tradingMode'],
        fallback: 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
      ),
      holdings: _list(
        json['holdings'],
      ).map((value) => MockHolding.fromJson(_map(value))).toList(),
      recentTrades: _list(
        json['recentTrades'],
      ).map((value) => TradeExecution.fromJson(_map(value))).toList(),
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

  String get averagePriceDisplay =>
      formatCurrencyDisplay('USD', averagePriceUsd);

  String get currentPriceDisplay =>
      formatCurrencyDisplay('USD', currentPriceUsd);

  String get marketValueDisplay => formatCurrencyDisplay('USD', marketValueUsd);

  String get unrealizedPnlDisplay =>
      formatCurrencyDisplay('USD', unrealizedPnlUsd);

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
    return 'Order can be submitted during Korea market hours.';
  }

  static TradeOrderability fromJson(Map<String, dynamic> json) {
    return TradeOrderability(
      stockCode: _string(json['stockCode'], fallback: ''),
      side: _string(json['side'], fallback: 'BUY'),
      quantity: _int(json['quantity']),
      canPlaceMockOrder: json['canPlaceMockOrder'] as bool? ?? false,
      blockingReasons: _list(json['blockingReasons']).map((v) => '$v').toList(),
      warnings: _list(json['warnings']).map((v) => '$v').toList(),
      orderabilitySource: _string(
        json['orderabilitySource'],
        fallback: 'Hana-OmniLens-API',
      ),
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
      'This buy order may not be filled if the foreign ownership limit is reached',
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

  String get realizedPnlDisplay => formatCurrencyDisplay('USD', realizedPnlUsd);

  String get summary => '$side $quantity $stockName at '
      '${formatCurrencyDisplay('USD', executionPriceUsd)} / gross '
      '${formatCurrencyDisplay('USD', grossAmountUsd)}';

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
      cashBalanceUsdAfter: _string(
        json['cashBalanceUsdAfter'],
        fallback: '0.00',
      ),
      tradingMode: _string(
        json['tradingMode'],
        fallback: 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
      ),
    );
  }
}

class TradeLedgerHistory {
  const TradeLedgerHistory({
    required this.accountId,
    required this.tradeCount,
    required this.trades,
  });

  final String accountId;
  final int tradeCount;
  final List<TradeExecution> trades;

  static TradeLedgerHistory fromJson(Map<String, dynamic> json) {
    return TradeLedgerHistory(
      accountId: _string(json['accountId'], fallback: ''),
      tradeCount: _int(json['tradeCount']),
      trades: _list(
        json['trades'],
      ).map((value) => TradeExecution.fromJson(_map(value))).toList(),
    );
  }
}

class TradeOrderPlacement {
  const TradeOrderPlacement({
    required this.orderId,
    required this.stockCode,
    required this.stockName,
    required this.side,
    required this.quantity,
    required this.orderType,
    required this.limitPriceUsd,
    required this.observedPriceUsd,
    required this.status,
    required this.message,
    this.tradeExecution,
  });

  final String orderId;
  final String stockCode;
  final String stockName;
  final String side;
  final int quantity;
  final String orderType;
  final String limitPriceUsd;
  final String observedPriceUsd;
  final String status;
  final String message;
  final TradeExecution? tradeExecution;

  bool get isFilled => status.toUpperCase() == 'FILLED';

  String get limitPriceDisplay => formatCurrencyDisplay('USD', limitPriceUsd);

  String get observedPriceDisplay =>
      formatCurrencyDisplay('USD', observedPriceUsd);

  String get summary {
    if (isFilled && tradeExecution != null) {
      return tradeExecution!.summary;
    }
    return '$side $quantity $stockName limit $limitPriceDisplay / '
        'waiting at $observedPriceDisplay';
  }

  static TradeOrderPlacement fromJson(Map<String, dynamic> json) {
    final tradeJson = json['tradeExecution'];
    return TradeOrderPlacement(
      orderId: _string(json['orderId'], fallback: ''),
      stockCode: _string(json['stockCode'], fallback: ''),
      stockName: _string(json['stockName'], fallback: 'Unknown stock'),
      side: _string(json['side'], fallback: 'BUY'),
      quantity: _int(json['quantity']),
      orderType: _string(json['orderType'], fallback: 'LIMIT'),
      limitPriceUsd: _string(json['limitPriceUsd'], fallback: '0.00'),
      observedPriceUsd: _string(json['observedPriceUsd'], fallback: '0.00'),
      status: _string(json['status'], fallback: 'PENDING'),
      message: _string(json['message'], fallback: ''),
      tradeExecution:
          tradeJson == null ? null : TradeExecution.fromJson(_map(tradeJson)),
    );
  }
}

class TradeOrderHistory {
  const TradeOrderHistory({
    required this.accountId,
    required this.orderCount,
    required this.orders,
  });

  final String accountId;
  final int orderCount;
  final List<TradeOrderPlacement> orders;

  static TradeOrderHistory fromJson(Map<String, dynamic> json) {
    return TradeOrderHistory(
      accountId: _string(json['accountId'], fallback: ''),
      orderCount: _int(json['orderCount']),
      orders: _list(
        json['orders'],
      ).map((value) => TradeOrderPlacement.fromJson(_map(value))).toList(),
    );
  }
}

class TradeController extends ValueNotifier<TradeState> {
  TradeController({required ExchangeApiClient apiClient})
      : _apiClient = apiClient,
        super(const TradeState.idle());

  final ExchangeApiClient _apiClient;

  void clear() {
    value = const TradeState.idle();
  }

  Future<void> loadPortfolio(String? accountId) async {
    if (accountId == null || accountId.isEmpty) {
      value = TradeState.failure(
        errorMessage: 'Sign in to load your portfolio.',
        portfolio: value.portfolio,
        tradeHistory: value.tradeHistory,
        orderHistory: value.orderHistory,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
        lastOrder: value.lastOrder,
      );
      return;
    }

    await _run(() async {
      final response = await _apiClient.getPortfolio(accountId);
      value = TradeState.loaded(
        portfolio: PortfolioSnapshot.fromJson(response.data ?? {}),
        tradeHistory: value.tradeHistory,
        orderHistory: value.orderHistory,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
        lastOrder: value.lastOrder,
      );
    });
  }

  Future<void> loadTradeHistory(String? accountId, {int limit = 50}) async {
    if (accountId == null || accountId.isEmpty) {
      value = TradeState.failure(
        errorMessage: 'Sign in to load trade history.',
        portfolio: value.portfolio,
        tradeHistory: value.tradeHistory,
        orderHistory: value.orderHistory,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
        lastOrder: value.lastOrder,
      );
      return;
    }

    await _run(() async {
      final response = await _apiClient.getTradeHistory(
        accountId,
        limit: limit,
      );
      final history = TradeLedgerHistory.fromJson(response.data ?? {});
      value = TradeState.loaded(
        portfolio: value.portfolio,
        tradeHistory: history.trades,
        orderHistory: value.orderHistory,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
        lastOrder: value.lastOrder,
      );
    });
  }

  Future<void> loadOrderHistory(String? accountId, {int limit = 50}) async {
    if (accountId == null || accountId.isEmpty) {
      value = TradeState.failure(
        errorMessage: 'Sign in to load order history.',
        portfolio: value.portfolio,
        tradeHistory: value.tradeHistory,
        orderHistory: value.orderHistory,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
        lastOrder: value.lastOrder,
      );
      return;
    }

    await _run(() async {
      final response = await _apiClient.getOrderHistory(
        accountId,
        limit: limit,
      );
      final history = TradeOrderHistory.fromJson(response.data ?? {});
      value = TradeState.loaded(
        portfolio: value.portfolio,
        tradeHistory: value.tradeHistory,
        orderHistory: history.orders,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
        lastOrder: value.lastOrder,
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
        tradeHistory: value.tradeHistory,
        orderHistory: value.orderHistory,
        orderability: TradeOrderability.fromJson(response.data ?? {}),
        lastTrade: value.lastTrade,
        lastOrder: value.lastOrder,
      );
    });
  }

  void clearOrderability() {
    value = TradeState.loaded(
      portfolio: value.portfolio,
      tradeHistory: value.tradeHistory,
      orderHistory: value.orderHistory,
      lastTrade: value.lastTrade,
      lastOrder: value.lastOrder,
    );
  }

  Future<void> executeTrade({
    required String? accountId,
    required String stockCode,
    required String side,
    required int quantity,
    required num limitPriceUsd,
  }) async {
    if (!_isValid(accountId, stockCode, quantity, limitPriceUsd)) {
      return;
    }

    await _run(() async {
      final response = await _apiClient.executeTrade(
        accountId: accountId!,
        stockCode: stockCode,
        side: side,
        quantity: quantity,
        limitPriceUsd: limitPriceUsd,
      );
      final order = TradeOrderPlacement.fromJson(response.data ?? {});
      final portfolioResponse = await _apiClient.getPortfolio(accountId);
      final historyResponse = await _apiClient.getTradeHistory(accountId);
      final orderHistoryResponse = await _apiClient.getOrderHistory(accountId);
      value = TradeState.loaded(
        portfolio: PortfolioSnapshot.fromJson(portfolioResponse.data ?? {}),
        tradeHistory: TradeLedgerHistory.fromJson(
          historyResponse.data ?? {},
        ).trades,
        orderHistory: TradeOrderHistory.fromJson(
          orderHistoryResponse.data ?? {},
        ).orders,
        orderability: value.orderability,
        lastTrade: order.tradeExecution,
        lastOrder: order,
      );
    });
  }

  bool _isValid(
    String? accountId,
    String stockCode,
    int quantity, [
    num? limitPriceUsd,
  ]) {
    if (accountId == null || accountId.isEmpty) {
      value = TradeState.failure(
        errorMessage: 'Sign in before placing an order.',
        portfolio: value.portfolio,
        tradeHistory: value.tradeHistory,
        orderHistory: value.orderHistory,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
        lastOrder: value.lastOrder,
      );
      return false;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(stockCode)) {
      value = TradeState.failure(
        errorMessage: 'Enter a 6 digit Korean stock code.',
        portfolio: value.portfolio,
        tradeHistory: value.tradeHistory,
        orderHistory: value.orderHistory,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
        lastOrder: value.lastOrder,
      );
      return false;
    }
    if (quantity < 1) {
      value = TradeState.failure(
        errorMessage: 'Quantity must be at least 1.',
        portfolio: value.portfolio,
        tradeHistory: value.tradeHistory,
        orderHistory: value.orderHistory,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
        lastOrder: value.lastOrder,
      );
      return false;
    }
    if (limitPriceUsd != null && limitPriceUsd <= 0) {
      value = TradeState.failure(
        errorMessage: 'Limit price must be greater than 0.',
        portfolio: value.portfolio,
        tradeHistory: value.tradeHistory,
        orderHistory: value.orderHistory,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
        lastOrder: value.lastOrder,
      );
      return false;
    }
    return true;
  }

  Future<void> _run(Future<void> Function() action) async {
    value = TradeState.loading(
      portfolio: value.portfolio,
      tradeHistory: value.tradeHistory,
      orderHistory: value.orderHistory,
      orderability: value.orderability,
      lastTrade: value.lastTrade,
      lastOrder: value.lastOrder,
    );
    try {
      await action();
    } on ExchangeApiException catch (error) {
      value = TradeState.failure(
        errorMessage: error.message,
        portfolio: value.portfolio,
        tradeHistory: value.tradeHistory,
        orderHistory: value.orderHistory,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
        lastOrder: value.lastOrder,
      );
    } on Object {
      value = TradeState.failure(
        errorMessage: 'Unable to process order.',
        portfolio: value.portfolio,
        tradeHistory: value.tradeHistory,
        orderHistory: value.orderHistory,
        orderability: value.orderability,
        lastTrade: value.lastTrade,
        lastOrder: value.lastOrder,
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
