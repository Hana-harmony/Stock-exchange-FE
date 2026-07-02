import 'package:flutter_test/flutter_test.dart';
import 'package:stock_exchange_fe/src/core/currency_format.dart';
import 'package:stock_exchange_fe/src/core/tax_controller.dart';
import 'package:stock_exchange_fe/src/core/trade_controller.dart';

void main() {
  test('formats USD amounts with thousands commas and cents', () {
    expect(formatUsdAmount('1024.24'), '1,024.24');
    expect(formatUsdAmount('-2500000.5'), '-2,500,000.50');
    expect(formatCurrencyDisplay('USD', '1024'), 'USD 1,024.00');
    expect(formatCurrencyDisplay('KRW', '1024'), 'KRW 1,024');
  });

  test('formats trade summary USD values consistently', () {
    final trade = TradeExecution.fromJson({
      'tradeId': 'TRD-1',
      'stockCode': '005930',
      'stockName': 'Samsung Electronics',
      'side': 'SELL',
      'quantity': 2,
      'executionPriceUsd': '1024.24',
      'grossAmountUsd': '2048.48',
      'realizedPnlUsd': '1530.5',
      'remainingQuantity': 0,
      'cashBalanceUsdAfter': '10000',
      'tradingMode': 'EXCHANGE_MOCK_LEDGER_NOT_KIS_MOCK_TRADING',
    });

    expect(trade.realizedPnlDisplay, 'USD 1,530.50');
    expect(
      trade.summary,
      'SELL 2 Samsung Electronics at USD 1,024.24 / gross USD 2,048.48',
    );
  });

  test('formats tax refund USD values consistently', () {
    final refundCase = TaxRefundCase.fromJson({
      'caseId': 'TAX-CASE-1',
      'accountId': 'ACC-ABC123456789',
      'taxYear': 2026,
      'treatyCountry': 'US',
      'residenceCertificateFileName': 'residence.pdf',
      'reducedTaxApplicationFileName': 'reduced-tax.pdf',
      'advancePaymentRequested': true,
      'status': 'REFUND_APPROVED',
      'currency': 'USD',
      'totalSellAmountUsd': '2500.00',
      'realizedProfitUsd': '1530.50',
      'realizedLossUsd': '0.00',
      'netRealizedPnlUsd': '1530.50',
      'taxableRealizedPnlUsd': '1530.50',
      'estimatedWithholdingTaxUsd': '2400.40',
      'estimatedTreatyTaxUsd': '1376.16',
      'estimatedRefundUsd': '1024.24',
      'advancePaymentEligible': true,
      'matchedTradeCount': 0,
      'matchedTrades': const [],
      'dataSource': 'EXCHANGE_MOCK_LEDGER_REALIZED_PNL',
      'createdAt': '2026-06-18T06:00:00Z',
      'updatedAt': '2026-06-18T06:30:00Z',
    });

    expect(refundCase.refundDisplay, 'USD 1,024.24');
    expect(refundCase.withholdingDisplay, 'USD 2,400.40');
    expect(refundCase.treatyDisplay, 'USD 1,376.16');
  });
}
