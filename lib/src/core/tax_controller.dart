import 'package:flutter/foundation.dart';

import 'exchange_api_client.dart';

enum TaxStatus {
  idle,
  loading,
  loaded,
  failure,
}

class TaxState {
  const TaxState({
    required this.status,
    this.refundCase,
    this.errorMessage,
  });

  const TaxState.idle()
      : status = TaxStatus.idle,
        refundCase = null,
        errorMessage = null;

  const TaxState.loading({this.refundCase})
      : status = TaxStatus.loading,
        errorMessage = null;

  const TaxState.loaded(this.refundCase)
      : status = TaxStatus.loaded,
        errorMessage = null;

  const TaxState.failure({
    required this.errorMessage,
    this.refundCase,
  }) : status = TaxStatus.failure;

  final TaxStatus status;
  final TaxRefundCase? refundCase;
  final String? errorMessage;
}

class TaxRefundCase {
  const TaxRefundCase({
    required this.caseId,
    required this.accountId,
    required this.taxYear,
    required this.treatyCountry,
    required this.residenceCertificateFileName,
    required this.reducedTaxApplicationFileName,
    required this.advancePaymentRequested,
    required this.status,
    required this.currency,
    required this.totalSellAmountUsd,
    required this.realizedProfitUsd,
    required this.realizedLossUsd,
    required this.netRealizedPnlUsd,
    required this.taxableRealizedPnlUsd,
    required this.estimatedWithholdingTaxUsd,
    required this.estimatedTreatyTaxUsd,
    required this.estimatedRefundUsd,
    required this.advancePaymentEligible,
    required this.matchedTradeCount,
    required this.matchedTrades,
    required this.dataSource,
    required this.createdAt,
    required this.updatedAt,
  });

  final String caseId;
  final String accountId;
  final int taxYear;
  final String treatyCountry;
  final String residenceCertificateFileName;
  final String reducedTaxApplicationFileName;
  final bool advancePaymentRequested;
  final String status;
  final String currency;
  final String totalSellAmountUsd;
  final String realizedProfitUsd;
  final String realizedLossUsd;
  final String netRealizedPnlUsd;
  final String taxableRealizedPnlUsd;
  final String estimatedWithholdingTaxUsd;
  final String estimatedTreatyTaxUsd;
  final String estimatedRefundUsd;
  final bool advancePaymentEligible;
  final int matchedTradeCount;
  final List<TaxMatchedTrade> matchedTrades;
  final String dataSource;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get referenceDisplay => caseId.isEmpty ? 'Not issued' : caseId;

  String get refundDisplay => '$currency $estimatedRefundUsd';

  String get withholdingDisplay => '$currency $estimatedWithholdingTaxUsd';

  String get treatyDisplay => '$currency $estimatedTreatyTaxUsd';

  double get refundRatio {
    final withholding = double.tryParse(estimatedWithholdingTaxUsd) ?? 0;
    final refund = double.tryParse(estimatedRefundUsd) ?? 0;
    if (withholding <= 0) {
      return 0;
    }
    return (refund / withholding).clamp(0, 1).toDouble();
  }

  double get treatyRatio {
    final withholding = double.tryParse(estimatedWithholdingTaxUsd) ?? 0;
    final treaty = double.tryParse(estimatedTreatyTaxUsd) ?? 0;
    if (withholding <= 0) {
      return 0;
    }
    return (treaty / withholding).clamp(0, 1).toDouble();
  }

  static TaxRefundCase fromJson(Map<String, dynamic> json) {
    return TaxRefundCase(
      caseId: _string(json['caseId'], fallback: ''),
      accountId: _string(json['accountId'], fallback: ''),
      taxYear: _int(json['taxYear']),
      treatyCountry: _string(json['treatyCountry'], fallback: 'US'),
      residenceCertificateFileName:
          _string(json['residenceCertificateFileName'], fallback: ''),
      reducedTaxApplicationFileName:
          _string(json['reducedTaxApplicationFileName'], fallback: ''),
      advancePaymentRequested:
          json['advancePaymentRequested'] as bool? ?? false,
      status: _string(json['status'], fallback: 'NOT_SUBMITTED'),
      currency: _string(json['currency'], fallback: 'USD'),
      totalSellAmountUsd:
          _string(json['totalSellAmountUsd'], fallback: '0.00'),
      realizedProfitUsd: _string(json['realizedProfitUsd'], fallback: '0.00'),
      realizedLossUsd: _string(json['realizedLossUsd'], fallback: '0.00'),
      netRealizedPnlUsd: _string(json['netRealizedPnlUsd'], fallback: '0.00'),
      taxableRealizedPnlUsd:
          _string(json['taxableRealizedPnlUsd'], fallback: '0.00'),
      estimatedWithholdingTaxUsd:
          _string(json['estimatedWithholdingTaxUsd'], fallback: '0.00'),
      estimatedTreatyTaxUsd:
          _string(json['estimatedTreatyTaxUsd'], fallback: '0.00'),
      estimatedRefundUsd:
          _string(json['estimatedRefundUsd'], fallback: '0.00'),
      advancePaymentEligible: json['advancePaymentEligible'] as bool? ?? false,
      matchedTradeCount: _int(json['matchedTradeCount']),
      matchedTrades: _list(json['matchedTrades'])
          .map((value) => TaxMatchedTrade.fromJson(_map(value)))
          .toList(),
      dataSource: _string(
        json['dataSource'],
        fallback: 'EXCHANGE_MOCK_LEDGER_REALIZED_PNL',
      ),
      createdAt: _dateTime(json['createdAt']),
      updatedAt: _dateTime(json['updatedAt']),
    );
  }
}

class TaxMatchedTrade {
  const TaxMatchedTrade({
    required this.tradeId,
    required this.stockCode,
    required this.stockName,
    required this.quantity,
    required this.grossAmountUsd,
    required this.realizedPnlUsd,
    required this.executedAt,
  });

  final String tradeId;
  final String stockCode;
  final String stockName;
  final int quantity;
  final String grossAmountUsd;
  final String realizedPnlUsd;
  final DateTime? executedAt;

  static TaxMatchedTrade fromJson(Map<String, dynamic> json) {
    return TaxMatchedTrade(
      tradeId: _string(json['tradeId'], fallback: ''),
      stockCode: _string(json['stockCode'], fallback: ''),
      stockName: _string(json['stockName'], fallback: 'Unknown stock'),
      quantity: _int(json['quantity']),
      grossAmountUsd: _string(json['grossAmountUsd'], fallback: '0.00'),
      realizedPnlUsd: _string(json['realizedPnlUsd'], fallback: '0.00'),
      executedAt: _dateTime(json['executedAt']),
    );
  }
}

class TaxController extends ValueNotifier<TaxState> {
  TaxController({required ExchangeApiClient apiClient})
      : _apiClient = apiClient,
        super(const TaxState.idle());

  final ExchangeApiClient _apiClient;

  Future<void> loadRefundStatus(String? accountId) async {
    if (accountId == null || accountId.isEmpty) {
      value = TaxState.failure(
        errorMessage: 'Sign in to load tax refund status.',
        refundCase: value.refundCase,
      );
      return;
    }

    value = TaxState.loading(refundCase: value.refundCase);
    try {
      final response = await _apiClient.getTaxRefundStatus(accountId);
      value = TaxState.loaded(
        TaxRefundCase.fromJson(response.data ?? {}),
      );
    } on ExchangeApiException catch (error) {
      value = TaxState.failure(
        errorMessage: error.message,
        refundCase: value.refundCase,
      );
    } on Object {
      value = TaxState.failure(
        errorMessage: 'Unable to load tax refund status.',
        refundCase: value.refundCase,
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
  return value is List ? value : const [];
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
