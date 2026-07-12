import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_exchange_fe/src/core/exchange_api_client.dart';
import 'package:stock_exchange_fe/src/core/tax_controller.dart';
import 'package:stock_exchange_fe/src/features/exchange/exchange_pages.dart';

void main() {
  testWidgets('leaves OCR screen and offers retry when status sync fails',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var syncRequests = 0;
    final controller = TaxController(
      apiClient: ExchangeApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/tax/refund-status')) {
            return _jsonResponse(_taxCaseJson(status: 'NOT_SUBMITTED'));
          }
          if (request.url.path.endsWith('/tax/documents')) {
            final documentType = request.body.contains('RESIDENCE_CERTIFICATE')
                ? 'RESIDENCE_CERTIFICATE'
                : request.body.contains('APOSTILLE')
                    ? 'APOSTILLE'
                    : 'REDUCED_TAX_APPLICATION';
            final fileName = switch (documentType) {
              'RESIDENCE_CERTIFICATE' => 'residence.png',
              'APOSTILLE' => 'apostille.png',
              _ => 'reduced-tax.png',
            };
            return _jsonResponse({
              'documentId': 'DOC-$documentType',
              'documentType': documentType,
              'originalFileName': fileName,
              'sizeBytes': 12,
              'createdAt': '2026-07-12T15:26:00Z',
              'verification': _verifiedJson(documentType),
            });
          }
          if (request.url.path.endsWith('/tax/refund-cases')) {
            return _jsonResponse(_taxCaseJson(status: 'READY_FOR_HANA_SYNC'));
          }
          syncRequests += 1;
          if (syncRequests == 1) {
            return http.Response(
              jsonEncode({
                'success': false,
                'status': 502,
                'code': 'TAX_002',
                'message': 'Tax status synchronization failed.',
              }),
              502,
              headers: {'content-type': 'application/json'},
            );
          }
          return _jsonResponse(_taxCaseJson(status: 'SYNCED_WITH_HANA'));
        }),
      ),
    );
    addTearDown(controller.dispose);

    final files = <XFile>[
      XFile.fromData(Uint8List.fromList([1]),
          path: '/tmp/residence.png', mimeType: 'image/png'),
      XFile.fromData(Uint8List.fromList([2]),
          path: '/tmp/apostille.png', mimeType: 'image/png'),
      XFile.fromData(Uint8List.fromList([3]),
          path: '/tmp/reduced-tax.png', mimeType: 'image/png'),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaxRefundRequestScreen(
          accountId: 'ACC-ABC123456789',
          taxController: controller,
          filePicker: () async => files.removeAt(0),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tax-apply-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tax-agree-button')));
    await tester.pumpAndSettle();

    for (final type in const [
      'RESIDENCE_CERTIFICATE',
      'APOSTILLE',
      'REDUCED_TAX_APPLICATION',
    ]) {
      final remainingFiles = files.length;
      await tester.tap(find.byKey(ValueKey('tax-upload-$type')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      expect(files.length, remainingFiles - 1);
      if (type != 'REDUCED_TAX_APPLICATION') {
        expect(find.byType(AlertDialog), findsNothing);
        expect(controller.value.errorMessage, isNull);
        expect(controller.value.status, TaxStatus.loaded);
      }
      final uploaded = controller.value.uploadedDocuments.last;
      expect(
        [
          uploaded.documentType,
          uploaded.verification?.verificationStatus,
          uploaded.verification?.source,
          uploaded.verification?.manualReviewRequired,
        ],
        [type, 'VERIFIED', 'HANNAH_MONTANA_AI_TAX_OCR', false],
      );
    }

    expect(find.byKey(const ValueKey('tax-submitted-step')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tax-analyzing-step-REDUCED_TAX_APPLICATION')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('tax-submission-error-dialog')),
        findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Retry Status Sync'), findsOneWidget);

    await tester.tap(find.text('Retry Status Sync'));
    await tester.pumpAndSettle();

    expect(syncRequests, 2);
    expect(find.text('Retry Status Sync'), findsNothing);
    expect(find.text('Review Documents'), findsOneWidget);
  });
}

Map<String, Object?> _verifiedJson(String documentType) {
  return {
    'documentType': documentType,
    'fileName': '$documentType.png',
    'verificationStatus': 'VERIFIED',
    'ocrConfidence': 0.96,
    'fraudRiskScore': 0.01,
    'riskLevel': 'LOW',
    'manualReviewRequired': false,
    'extractedFields': {'residency_country_code': 'US'},
    'missingRequiredFields': <Object?>[],
    'rejectionReasons': <Object?>[],
    'documentModelVersion': 'hanah-tax-ocr-e2e-review-v1',
    'source': 'HANNAH_MONTANA_AI_TAX_OCR',
    'progressPercent': 100,
    'stage': 'VERIFICATION_COMPLETE',
    'updatedAt': '2026-07-12T15:26:35Z',
  };
}

Map<String, Object?> _taxCaseJson({required String status}) {
  return {
    'caseId': status == 'NOT_SUBMITTED' ? '' : 'TAX-CASE-1',
    'accountId': 'ACC-ABC123456789',
    'taxYear': 2026,
    'treatyCountry': 'US',
    'residenceCertificateFileName': 'residence.png',
    'reducedTaxApplicationFileName': 'reduced-tax.png',
    'advancePaymentRequested': true,
    'status': status,
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
    'matchedTrades': <Object?>[],
    'dataSource': 'EXCHANGE_MOCK_LEDGER_REALIZED_PNL',
    'createdAt': '2026-07-12T15:26:35Z',
    'updatedAt': '2026-07-12T15:26:36Z',
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
      'timestamp': '2026-07-12T15:26:36Z',
    }),
    200,
    headers: {'content-type': 'application/json'},
  );
}
