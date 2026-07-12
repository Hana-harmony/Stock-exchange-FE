import 'package:flutter/foundation.dart';

import 'currency_format.dart';
import 'exchange_api_client.dart';

enum TaxStatus {
  idle,
  loading,
  loaded,
  failure,
}

const _verificationPollInterval = Duration(milliseconds: 700);
const _verificationPollAttempts = 120;

class TaxState {
  const TaxState({
    required this.status,
    this.refundCase,
    this.uploadedDocuments = const [],
    this.errorMessage,
  });

  const TaxState.idle()
      : status = TaxStatus.idle,
        refundCase = null,
        uploadedDocuments = const [],
        errorMessage = null;

  const TaxState.loading({
    this.refundCase,
    this.uploadedDocuments = const [],
  })  : status = TaxStatus.loading,
        errorMessage = null;

  const TaxState.loaded(
    this.refundCase, {
    this.uploadedDocuments = const [],
  })  : status = TaxStatus.loaded,
        errorMessage = null;

  const TaxState.failure({
    required this.errorMessage,
    this.refundCase,
    this.uploadedDocuments = const [],
  }) : status = TaxStatus.failure;

  final TaxStatus status;
  final TaxRefundCase? refundCase;
  final List<TaxDocumentUpload> uploadedDocuments;
  final String? errorMessage;
}

class TaxDocumentUpload {
  const TaxDocumentUpload({
    required this.documentId,
    required this.documentType,
    required this.originalFileName,
    required this.sizeBytes,
    required this.createdAt,
    this.verification,
  });

  final String documentId;
  final String documentType;
  final String originalFileName;
  final int sizeBytes;
  final DateTime? createdAt;
  final TaxDocumentVerification? verification;

  bool get isVerified => verification?.isHanaMontanaVerified ?? false;

  TaxDocumentUpload copyWith({
    TaxDocumentVerification? verification,
  }) {
    return TaxDocumentUpload(
      documentId: documentId,
      documentType: documentType,
      originalFileName: originalFileName,
      sizeBytes: sizeBytes,
      createdAt: createdAt,
      verification: verification ?? this.verification,
    );
  }

  static TaxDocumentUpload fromJson(Map<String, dynamic> json) {
    return TaxDocumentUpload(
      documentId: _string(json['documentId'], fallback: ''),
      documentType: _string(json['documentType'], fallback: ''),
      originalFileName: _string(json['originalFileName'], fallback: ''),
      sizeBytes: _int(json['sizeBytes']),
      createdAt: _dateTime(json['createdAt']),
      verification: json['verification'] == null
          ? null
          : TaxDocumentVerification.fromJson(_map(json['verification'])),
    );
  }
}

class TaxDocumentVerification {
  const TaxDocumentVerification({
    required this.verificationStatus,
    required this.ocrConfidence,
    required this.fraudRiskScore,
    required this.riskLevel,
    required this.manualReviewRequired,
    required this.extractedFields,
    required this.missingRequiredFields,
    required this.rejectionReasons,
    required this.documentModelVersion,
    required this.source,
    required this.progressPercent,
    required this.stage,
    this.updatedAt,
  });

  final String verificationStatus;
  final double ocrConfidence;
  final double fraudRiskScore;
  final String riskLevel;
  final bool manualReviewRequired;
  final Map<String, String> extractedFields;
  final List<String> missingRequiredFields;
  final List<String> rejectionReasons;
  final String documentModelVersion;
  final String source;
  final int progressPercent;
  final String stage;
  final DateTime? updatedAt;

  String get confidenceDisplay =>
      '${(ocrConfidence * 100).clamp(0, 100).toStringAsFixed(0)}%';

  bool get isHanaMontanaVerified {
    return verificationStatus == 'VERIFIED' &&
        !manualReviewRequired &&
        source == 'HANNAH_MONTANA_AI_TAX_OCR';
  }

  bool get isTerminal {
    return verificationStatus == 'VERIFIED' ||
        verificationStatus == 'REVIEW_REQUIRED' ||
        verificationStatus == 'REJECTED' ||
        verificationStatus == 'FAILED';
  }

  String get stageDisplay {
    switch (stage) {
      case 'UPLOADED_TO_EXCHANGE':
        return 'Uploaded to Exchange';
      case 'SENT_TO_OMNILENS':
        return 'Sent to OmniLens';
      case 'HANNAH_MONTANA_OCR':
        return 'Hana Montana OCR';
      case 'VERIFICATION_COMPLETE':
        return 'Verification complete';
      case 'VERIFICATION_FAILED':
        return 'Verification failed';
      default:
        return stage
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0]}${part.substring(1).toLowerCase()}')
            .join(' ');
    }
  }

  static TaxDocumentVerification fromJson(Map<String, dynamic> json) {
    return TaxDocumentVerification(
      verificationStatus: _string(json['verificationStatus'], fallback: ''),
      ocrConfidence: _double(json['ocrConfidence']),
      fraudRiskScore: _double(json['fraudRiskScore']),
      riskLevel: _string(json['riskLevel'], fallback: 'MEDIUM'),
      manualReviewRequired: json['manualReviewRequired'] as bool? ?? true,
      extractedFields: _stringMap(json['extractedFields']),
      missingRequiredFields: _list(json['missingRequiredFields'])
          .map((value) => '$value')
          .toList(growable: false),
      rejectionReasons: _list(json['rejectionReasons'])
          .map((value) => '$value')
          .toList(growable: false),
      documentModelVersion:
          _string(json['documentModelVersion'], fallback: 'unavailable'),
      source: _string(json['source'], fallback: 'HANA_OMNILENS_API'),
      progressPercent: _int(json['progressPercent']).clamp(0, 100).toInt(),
      stage: _string(json['stage'], fallback: 'QUEUED'),
      updatedAt: _dateTime(json['updatedAt']),
    );
  }
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

  String get refundDisplay =>
      formatCurrencyDisplay(currency, estimatedRefundUsd);

  String get withholdingDisplay =>
      formatCurrencyDisplay(currency, estimatedWithholdingTaxUsd);

  String get treatyDisplay =>
      formatCurrencyDisplay(currency, estimatedTreatyTaxUsd);

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
      totalSellAmountUsd: _string(json['totalSellAmountUsd'], fallback: '0.00'),
      realizedProfitUsd: _string(json['realizedProfitUsd'], fallback: '0.00'),
      realizedLossUsd: _string(json['realizedLossUsd'], fallback: '0.00'),
      netRealizedPnlUsd: _string(json['netRealizedPnlUsd'], fallback: '0.00'),
      taxableRealizedPnlUsd:
          _string(json['taxableRealizedPnlUsd'], fallback: '0.00'),
      estimatedWithholdingTaxUsd:
          _string(json['estimatedWithholdingTaxUsd'], fallback: '0.00'),
      estimatedTreatyTaxUsd:
          _string(json['estimatedTreatyTaxUsd'], fallback: '0.00'),
      estimatedRefundUsd: _string(json['estimatedRefundUsd'], fallback: '0.00'),
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

  String get grossAmountDisplay => formatCurrencyDisplay('USD', grossAmountUsd);

  String get realizedPnlDisplay => formatCurrencyDisplay('USD', realizedPnlUsd);

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

  void beginReplacement() {
    value = TaxState.loaded(
      value.refundCase,
      uploadedDocuments: const [],
    );
  }

  Future<void> loadRefundStatus(String? accountId) async {
    if (accountId == null || accountId.isEmpty) {
      value = TaxState.failure(
        errorMessage: 'Sign in to load tax refund status.',
        refundCase: value.refundCase,
      );
      return;
    }

    value = TaxState.loading(
      refundCase: value.refundCase,
      uploadedDocuments: value.uploadedDocuments,
    );
    try {
      final response = await _apiClient.getTaxRefundStatus(accountId);
      value = TaxState.loaded(
        TaxRefundCase.fromJson(response.data ?? {}),
        uploadedDocuments: value.uploadedDocuments,
      );
    } on ExchangeApiException catch (error) {
      value = TaxState.failure(
        errorMessage: error.message,
        refundCase: value.refundCase,
        uploadedDocuments: value.uploadedDocuments,
      );
    } on Object {
      value = TaxState.failure(
        errorMessage: 'Unable to load tax refund status.',
        refundCase: value.refundCase,
        uploadedDocuments: value.uploadedDocuments,
      );
    }
  }

  Future<void> uploadDocument({
    required String? accountId,
    required String documentType,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    if (accountId == null || accountId.isEmpty) {
      value = TaxState.failure(
        errorMessage: 'Sign in to upload tax documents.',
        refundCase: value.refundCase,
        uploadedDocuments: value.uploadedDocuments,
      );
      return;
    }
    if (fileName.trim().isEmpty || bytes.isEmpty) {
      value = TaxState.failure(
        errorMessage: 'Select a non-empty tax document file.',
        refundCase: value.refundCase,
        uploadedDocuments: value.uploadedDocuments,
      );
      return;
    }

    value = TaxState.loading(
      refundCase: value.refundCase,
      uploadedDocuments: value.uploadedDocuments,
    );
    try {
      final response = await _apiClient.uploadTaxDocument(
        accountId: accountId,
        documentType: documentType,
        fileName: fileName.trim(),
        bytes: bytes,
        contentType: contentType,
      );
      final uploaded = TaxDocumentUpload.fromJson(response.data ?? {});
      _emitDocument(uploaded, loading: true);
      final verifiedUpload = await _pollDocumentVerification(
        accountId: accountId,
        uploaded: uploaded,
      );
      _emitDocument(verifiedUpload, loading: false);
    } on ExchangeApiException catch (error) {
      value = TaxState.failure(
        errorMessage: error.message,
        refundCase: value.refundCase,
        uploadedDocuments: value.uploadedDocuments,
      );
    } on Object {
      value = TaxState.failure(
        errorMessage: 'Unable to upload tax document.',
        refundCase: value.refundCase,
        uploadedDocuments: value.uploadedDocuments,
      );
    }
  }

  Future<void> submitRefundCase({
    required String? accountId,
    required int taxYear,
    required String treatyCountry,
    required String residenceCertificateFileName,
    required String reducedTaxApplicationFileName,
    required bool advancePaymentRequested,
  }) async {
    if (accountId == null || accountId.isEmpty) {
      value = TaxState.failure(
        errorMessage: 'Sign in to submit a tax refund request.',
        refundCase: value.refundCase,
        uploadedDocuments: value.uploadedDocuments,
      );
      return;
    }

    final residenceDocument = _document('RESIDENCE_CERTIFICATE');
    final apostilleDocument = _document('APOSTILLE');
    final reducedTaxDocument = _document('REDUCED_TAX_APPLICATION');
    if (!hasVerifiedRequiredDocuments) {
      value = TaxState.failure(
        errorMessage:
            'Complete Hana Montana OCR verification for every required tax document before submitting.',
        refundCase: value.refundCase,
        uploadedDocuments: value.uploadedDocuments,
      );
      return;
    }
    value = TaxState.loading(
      refundCase: value.refundCase,
      uploadedDocuments: value.uploadedDocuments,
    );
    try {
      final response = await _apiClient.createTaxRefundCase(
        accountId: accountId,
        taxYear: taxYear,
        treatyCountry: treatyCountry.trim().isEmpty
            ? 'US'
            : treatyCountry.trim().toUpperCase(),
        residenceCertificateFileName:
            residenceCertificateFileName.trim().isEmpty
                ? residenceDocument?.originalFileName ?? 'residence.pdf'
                : residenceCertificateFileName.trim(),
        reducedTaxApplicationFileName:
            reducedTaxApplicationFileName.trim().isEmpty
                ? reducedTaxDocument?.originalFileName ?? 'reduced-tax.pdf'
                : reducedTaxApplicationFileName.trim(),
        residenceCertificateDocumentId: residenceDocument?.documentId,
        apostilleDocumentId: apostilleDocument?.documentId,
        reducedTaxApplicationDocumentId: reducedTaxDocument?.documentId,
        advancePaymentRequested: advancePaymentRequested,
      );
      value = TaxState.loaded(
        TaxRefundCase.fromJson(response.data ?? {}),
        uploadedDocuments: value.uploadedDocuments,
      );
    } on ExchangeApiException catch (error) {
      value = TaxState.failure(
        errorMessage: error.message,
        refundCase: value.refundCase,
        uploadedDocuments: value.uploadedDocuments,
      );
    } on Object {
      value = TaxState.failure(
        errorMessage: 'Unable to submit tax refund request.',
        refundCase: value.refundCase,
        uploadedDocuments: value.uploadedDocuments,
      );
    }
  }

  Future<void> syncRefundStatus(String? accountId) async {
    if (accountId == null || accountId.isEmpty) {
      value = TaxState.failure(
        errorMessage: 'Sign in to sync tax refund status.',
        refundCase: value.refundCase,
        uploadedDocuments: value.uploadedDocuments,
      );
      return;
    }

    value = TaxState.loading(
      refundCase: value.refundCase,
      uploadedDocuments: value.uploadedDocuments,
    );
    try {
      final response = await _apiClient.syncTaxRefundStatus(accountId);
      value = TaxState.loaded(
        TaxRefundCase.fromJson(response.data ?? {}),
        uploadedDocuments: value.uploadedDocuments,
      );
    } on ExchangeApiException catch (error) {
      value = TaxState.failure(
        errorMessage: error.message,
        refundCase: value.refundCase,
        uploadedDocuments: value.uploadedDocuments,
      );
    } on Object {
      value = TaxState.failure(
        errorMessage: 'Unable to sync tax refund status.',
        refundCase: value.refundCase,
        uploadedDocuments: value.uploadedDocuments,
      );
    }
  }

  TaxDocumentUpload? _document(String documentType) {
    for (final document in value.uploadedDocuments) {
      if (document.documentType == documentType) {
        return document;
      }
    }
    return null;
  }

  bool hasVerifiedDocument(String documentType) {
    return _document(documentType)?.verification?.isHanaMontanaVerified ??
        false;
  }

  bool get hasVerifiedRequiredDocuments {
    const requiredTypes = [
      'RESIDENCE_CERTIFICATE',
      'APOSTILLE',
      'REDUCED_TAX_APPLICATION',
    ];
    return requiredTypes.every(hasVerifiedDocument);
  }

  Future<TaxDocumentUpload> _pollDocumentVerification({
    required String accountId,
    required TaxDocumentUpload uploaded,
  }) async {
    var current = uploaded;
    if (current.verification?.isTerminal ?? false) {
      return current;
    }
    for (var attempt = 0; attempt < _verificationPollAttempts; attempt++) {
      await Future<void>.delayed(_verificationPollInterval);
      final response = await _apiClient.getTaxDocumentVerification(
        accountId: accountId,
        documentId: current.documentId,
      );
      final verification =
          TaxDocumentVerification.fromJson(response.data ?? {});
      current = current.copyWith(verification: verification);
      _emitDocument(current, loading: true);
      if (verification.isTerminal) {
        return current;
      }
    }
    throw const ExchangeApiException(
      status: 408,
      code: 'TAX_OCR_TIMEOUT',
      message: 'Hana Montana OCR verification is still in progress.',
    );
  }

  void _emitDocument(TaxDocumentUpload document, {required bool loading}) {
    final documents = [
      ...value.uploadedDocuments.where(
        (item) => item.documentType != document.documentType,
      ),
      document,
    ];
    value = loading
        ? TaxState.loading(
            refundCase: value.refundCase,
            uploadedDocuments: documents,
          )
        : TaxState.loaded(
            value.refundCase,
            uploadedDocuments: documents,
          );
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

double _double(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('$value') ?? 0;
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return value.map((key, value) => MapEntry('$key', '$value'));
}

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
