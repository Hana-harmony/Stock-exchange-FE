import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_exchange_fe/src/core/exchange_api_client.dart';
import 'package:stock_exchange_fe/src/core/tax_controller.dart';

void main() {
  test('loads latest tax refund status and split ratios', () async {
    final controller = TaxController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          expect(
            request.url.path,
            '/api/v1/accounts/ACC-ABC123456789/tax/refund-status',
          );
          return _jsonResponse(_taxCaseJson());
        }),
      ),
    );
    addTearDown(controller.dispose);

    await controller.loadRefundStatus('ACC-ABC123456789');

    expect(controller.value.status, TaxStatus.loaded);
    expect(controller.value.refundCase?.status, 'REFUND_APPROVED');
    expect(controller.value.refundCase?.referenceDisplay, 'TAX-CASE-1');
    expect(controller.value.refundCase?.refundDisplay, 'USD 1.40');
    expect(controller.value.refundCase?.refundRatio, closeTo(0.318, 0.001));
    expect(controller.value.refundCase?.treatyRatio, closeTo(0.681, 0.001));
    expect(
      controller.value.refundCase?.matchedTrades.single.stockCode,
      '005930',
    );
  });

  test('requires sign in before loading tax refund status', () async {
    var called = false;
    final controller = TaxController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          called = true;
          return _jsonResponse({});
        }),
      ),
    );
    addTearDown(controller.dispose);

    await controller.loadRefundStatus(null);

    expect(called, isFalse);
    expect(controller.value.status, TaxStatus.failure);
    expect(controller.value.errorMessage, 'Sign in to load tax refund status.');
  });

  test('uploads tax documents submits refund case and syncs status', () async {
    final paths = <String>[];
    final controller = TaxController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          paths.add('${request.method} ${request.url.path}');
          if (request.url.path.endsWith('/tax/documents')) {
            final isResidence = request.body.contains('RESIDENCE_CERTIFICATE');
            return _jsonResponse({
              'documentId': isResidence ? 'DOC-RES' : 'DOC-RED',
              'documentType': isResidence
                  ? 'RESIDENCE_CERTIFICATE'
                  : 'REDUCED_TAX_APPLICATION',
              'originalFileName':
                  isResidence ? 'residence.pdf' : 'reduced-tax.pdf',
              'sizeBytes': 12,
              'createdAt': '2026-06-18T06:00:00Z',
              'verification': _verificationJson(isResidence
                  ? 'RESIDENCE_CERTIFICATE'
                  : 'REDUCED_TAX_APPLICATION'),
            });
          }
          if (request.url.path.endsWith('/tax/refund-cases')) {
            expect(jsonDecode(request.body), {
              'taxYear': 2026,
              'treatyCountry': 'US',
              'residenceCertificateFileName': 'residence.pdf',
              'reducedTaxApplicationFileName': 'reduced-tax.pdf',
              'residenceCertificateDocumentId': 'DOC-RES',
              'reducedTaxApplicationDocumentId': 'DOC-RED',
              'advancePaymentRequested': true,
            });
            return _jsonResponse({
              ..._taxCaseJson(),
              'status': 'READY_FOR_HANA_SYNC',
            });
          }
          return _jsonResponse({
            ..._taxCaseJson(),
            'status': 'ADVANCE_PAID',
          });
        }),
      ),
    );
    addTearDown(controller.dispose);

    await controller.uploadDocument(
      accountId: 'ACC-ABC123456789',
      documentType: 'RESIDENCE_CERTIFICATE',
      fileName: 'residence.pdf',
      bytes: Uint8List.fromList(utf8.encode('residence')),
    );
    await controller.uploadDocument(
      accountId: 'ACC-ABC123456789',
      documentType: 'REDUCED_TAX_APPLICATION',
      fileName: 'reduced-tax.pdf',
      bytes: Uint8List.fromList(utf8.encode('reduced')),
    );
    await controller.submitRefundCase(
      accountId: 'ACC-ABC123456789',
      taxYear: 2026,
      treatyCountry: 'us',
      residenceCertificateFileName: 'residence.pdf',
      reducedTaxApplicationFileName: 'reduced-tax.pdf',
      advancePaymentRequested: true,
    );
    await controller.syncRefundStatus('ACC-ABC123456789');

    expect(controller.value.status, TaxStatus.loaded);
    expect(controller.value.uploadedDocuments, hasLength(2));
    expect(controller.hasVerifiedDocument('RESIDENCE_CERTIFICATE'), isTrue);
    expect(
      controller.value.uploadedDocuments.first.verification?.source,
      'HANNAH_MONTANA_AI_TAX_OCR',
    );
    expect(controller.value.refundCase?.status, 'ADVANCE_PAID');
    expect(paths, [
      'POST /api/v1/accounts/ACC-ABC123456789/tax/documents',
      'POST /api/v1/accounts/ACC-ABC123456789/tax/documents',
      'POST /api/v1/accounts/ACC-ABC123456789/tax/refund-cases',
      'POST /api/v1/accounts/ACC-ABC123456789/tax/refund-status/sync',
    ]);
  });
}

Map<String, Object?> _verificationJson(String documentType) {
  return {
    'documentType': documentType,
    'fileName': '$documentType.txt',
    'verificationStatus': 'VERIFIED',
    'ocrConfidence': 0.93,
    'fraudRiskScore': 0.02,
    'riskLevel': 'LOW',
    'manualReviewRequired': false,
    'extractedFields': {'residency_country_code': 'US'},
    'missingRequiredFields': <Object?>[],
    'rejectionReasons': <Object?>[],
    'documentModelVersion': 'hanah-tax-ocr-e2e-review-v1',
    'source': 'HANNAH_MONTANA_AI_TAX_OCR',
  };
}

http.Response _jsonResponse(Map<String, Object?> data) {
  return http.Response(
    jsonEncode({
      'success': true,
      'status': 200,
      'code': 'COMMON_000',
      'message': 'OK',
      'data': data,
      'timestamp': '2026-06-18T06:00:00Z',
    }),
    200,
    headers: {'content-type': 'application/json'},
  );
}

Map<String, Object?> _taxCaseJson() {
  return {
    'caseId': 'TAX-CASE-1',
    'accountId': 'ACC-ABC123456789',
    'taxYear': 2026,
    'treatyCountry': 'US',
    'residenceCertificateFileName': 'residence.pdf',
    'reducedTaxApplicationFileName': 'reduced-tax.pdf',
    'advancePaymentRequested': true,
    'status': 'REFUND_APPROVED',
    'currency': 'USD',
    'totalSellAmountUsd': '70.00',
    'realizedProfitUsd': '20.00',
    'realizedLossUsd': '0.00',
    'netRealizedPnlUsd': '20.00',
    'taxableRealizedPnlUsd': '20.00',
    'estimatedWithholdingTaxUsd': '4.40',
    'estimatedTreatyTaxUsd': '3.00',
    'estimatedRefundUsd': '1.40',
    'advancePaymentEligible': true,
    'matchedTradeCount': 1,
    'matchedTrades': [
      {
        'tradeId': 'TRD-1',
        'stockCode': '005930',
        'stockName': 'Samsung Electronics',
        'quantity': 1,
        'grossAmountUsd': '70.00',
        'realizedPnlUsd': '20.00',
        'executedAt': '2026-06-18T06:00:00Z',
      }
    ],
    'dataSource': 'EXCHANGE_MOCK_LEDGER_REALIZED_PNL',
    'createdAt': '2026-06-18T06:00:00Z',
    'updatedAt': '2026-06-18T06:30:00Z',
  };
}
