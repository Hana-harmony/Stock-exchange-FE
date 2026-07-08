part of '../exchange_pages.dart';

class TaxRefundRequestScreen extends StatefulWidget {
  const TaxRefundRequestScreen({
    super.key,
    required this.accountId,
    required this.taxController,
  });

  final String accountId;
  final TaxController taxController;

  @override
  State<TaxRefundRequestScreen> createState() => _TaxRefundRequestScreenState();
}

class _TaxRefundRequestScreenState extends State<TaxRefundRequestScreen> {
  var _step = 0;

  static const _documents = <_TaxRequiredDocument>[
    _TaxRequiredDocument(
      type: 'RESIDENCE_CERTIFICATE',
      title: 'Certificate of Tax Residence',
      subtitle: 'Verifies your tax residency to determine eligibility.',
      fileName: 'residence-certificate.txt',
      sampleText: '''
United States of America
Certification of U.S. Tax Residency
US_USER_1234 987-65-4321
Year 2026
January 12, 2026
''',
    ),
    _TaxRequiredDocument(
      type: 'APOSTILLE',
      title: 'Apostille Certificate',
      subtitle: 'Certifies authenticity for international use.',
      fileName: 'apostille-certificate.txt',
      sampleText: '''
APOSTILLE
United States of America
Signed by Sample Notary
Secretary of State
Certificate No. 5008
''',
    ),
    _TaxRequiredDocument(
      type: 'REDUCED_TAX_APPLICATION',
      title: 'Reduced Withholding Tax Rate Application',
      subtitle: 'Requests the treaty withholding tax rate.',
      fileName: 'reduced-tax-application.txt',
      sampleText: '''
Application for Reduced Withholding Tax Rate
US_USER_1234 MARIA L CHEN
United States of America
Treaty dividend tax rate 15%
Signature date 2026-01-12
''',
    ),
  ];

  @override
  void initState() {
    super.initState();
    widget.taxController.addListener(_handleTaxState);
  }

  @override
  void dispose() {
    widget.taxController.removeListener(_handleTaxState);
    super.dispose();
  }

  void _handleTaxState() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _hasAllDocuments {
    return _documents.every((document) {
      final uploaded = _uploaded(document.type);
      return uploaded != null &&
          uploaded.verification?.verificationStatus != 'REJECTED';
    });
  }

  TaxDocumentUpload? _uploaded(String type) {
    for (final document in widget.taxController.value.uploadedDocuments) {
      if (document.documentType == type) {
        return document;
      }
    }
    return null;
  }

  Future<void> _upload(_TaxRequiredDocument document) async {
    final bytes = Uint8List.fromList(document.sampleText.codeUnits);
    await widget.taxController.uploadDocument(
      accountId: widget.accountId,
      documentType: document.type,
      fileName: document.fileName,
      bytes: bytes,
    );
    final uploaded = _uploaded(document.type);
    final rejected = uploaded?.verification?.verificationStatus == 'REJECTED';
    if (!mounted || rejected) {
      return;
    }
    final nextIndex = _documents.indexWhere((item) {
      final current = _uploaded(item.type);
      return current == null ||
          current.verification?.verificationStatus == 'REJECTED';
    });
    if (nextIndex == -1) {
      setState(() {
        _step = 4;
      });
    } else {
      setState(() {
        _step = nextIndex + 1;
      });
    }
  }

  Future<void> _submit() async {
    await widget.taxController.submitRefundCase(
      accountId: widget.accountId,
      taxYear: DateTime.now().toUtc().year,
      treatyCountry: 'US',
      residenceCertificateFileName:
          _uploaded('RESIDENCE_CERTIFICATE')?.originalFileName ?? '',
      reducedTaxApplicationFileName:
          _uploaded('REDUCED_TAX_APPLICATION')?.originalFileName ?? '',
      advancePaymentRequested: true,
    );
    if (!mounted || widget.taxController.value.status == TaxStatus.failure) {
      return;
    }
    setState(() {
      _step = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.taxController.value;
    final loading = state.status == TaxStatus.loading;
    return ColoredBox(
      color: AppColors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TaxRequestHeader(onClose: () => Navigator.of(context).pop()),
            _TaxProgressBar(step: _step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildStep(context, state, loading),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, TaxState state, bool loading) {
    if (_step == 0) {
      return _TaxIntroStep(
        loading: loading,
        onAgree: () => setState(() => _step = 1),
      );
    }
    if (_step >= 1 && _step <= 3) {
      final document = _documents[_step - 1];
      return _TaxDocumentStep(
        key: ValueKey('tax-document-step-${document.type}'),
        document: document,
        uploaded: _uploaded(document.type),
        loading: loading,
        onUpload: () => _upload(document),
      );
    }
    if (_step == 4) {
      return _TaxReviewStep(
        documents: _documents,
        uploadedForType: _uploaded,
        canSubmit: _hasAllDocuments && !loading,
        loading: loading,
        onSubmit: _submit,
      );
    }
    return _TaxSubmittedStep(
      refundCase: state.refundCase,
      onConfirm: () => Navigator.of(context).pop(),
      onReview: () => setState(() => _step = 4),
    );
  }
}

class _TaxRequiredDocument {
  const _TaxRequiredDocument({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.fileName,
    required this.sampleText,
  });

  final String type;
  final String title;
  final String subtitle;
  final String fileName;
  final String sampleText;
}

class _TaxRequestHeader extends StatelessWidget {
  const _TaxRequestHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: Column(
        children: [
          const SizedBox(height: 62),
          SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Image.asset(AppAssets.logoSymbol, width: 36, height: 36),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Tax Refund Request',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            height: 31 / 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray1000,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Information',
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline, size: 22),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxProgressBar extends StatelessWidget {
  const _TaxProgressBar({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final progress = (step / 5).clamp(0.12, 1.0).toDouble();
    return SizedBox(
      height: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.gray200,
            valueColor: const AlwaysStoppedAnimation(AppColors.green500),
          ),
        ),
      ),
    );
  }
}

class _TaxIntroStep extends StatelessWidget {
  const _TaxIntroStep({
    required this.loading,
    required this.onAgree,
  });

  final bool loading;
  final VoidCallback onAgree;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('tax-intro-step'),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Text(
          'Reduced Withholding\nTax Rate Available',
          style: _taxTitleStyle(context),
        ),
        const SizedBox(height: 10),
        Text(
          '22% -> 16.5%',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: 38,
                height: 53 / 38,
                fontWeight: FontWeight.w700,
                color: AppColors.green500,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '*Including Local Taxes',
          style: _taxBodyStyle(context, fontSize: 14),
        ),
        const SizedBox(height: 28),
        const _TaxInfoPanel(
          title: 'Information Collected',
          lines: [
            'Full Name',
            'Resident Registration Number (RRN)',
            'Original Tax-Related Documents',
            'Bank Account Information',
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 45,
          child: FilledButton(
            key: const ValueKey('tax-agree-button'),
            onPressed: loading ? null : onAgree,
            style: _exchangePrimaryButtonStyle(
              backgroundColor: AppColors.orange500,
              radius: 8,
            ),
            child: const Text('Agree to All'),
          ),
        ),
      ],
    );
  }
}

class _TaxDocumentStep extends StatelessWidget {
  const _TaxDocumentStep({
    super.key,
    required this.document,
    required this.uploaded,
    required this.loading,
    required this.onUpload,
  });

  final _TaxRequiredDocument document;
  final TaxDocumentUpload? uploaded;
  final bool loading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final verification = uploaded?.verification;
    final analyzing = loading && uploaded == null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Text('Upload\n${document.title}', style: _taxTitleStyle(context)),
        const SizedBox(height: 12),
        Text(document.subtitle, style: _taxBodyStyle(context)),
        const SizedBox(height: 42),
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Center(
            child: analyzing
                ? const CircularProgressIndicator(color: AppColors.orange500)
                : Icon(
                    uploaded == null
                        ? Icons.upload_file_outlined
                        : Icons.document_scanner_outlined,
                    size: 58,
                    color: uploaded == null
                        ? AppColors.gray500
                        : AppColors.green500,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        _TaxVerificationPanel(verification: verification),
        const SizedBox(height: 24),
        SizedBox(
          height: 45,
          child: FilledButton(
            key: ValueKey('tax-upload-${document.type}'),
            onPressed: loading ? null : onUpload,
            style: _exchangePrimaryButtonStyle(
              backgroundColor: AppColors.orange500,
              radius: 8,
            ),
            child: Text(uploaded == null ? 'Upload File' : 'Re-upload File'),
          ),
        ),
      ],
    );
  }
}

class _TaxReviewStep extends StatelessWidget {
  const _TaxReviewStep({
    required this.documents,
    required this.uploadedForType,
    required this.canSubmit,
    required this.loading,
    required this.onSubmit,
  });

  final List<_TaxRequiredDocument> documents;
  final TaxDocumentUpload? Function(String type) uploadedForType;
  final bool canSubmit;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('tax-review-step'),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Text('OCR Verification\nReady to Submit',
            style: _taxTitleStyle(context)),
        const SizedBox(height: 12),
        Text(
          'Review extracted document status before sending the case to Hana.',
          style: _taxBodyStyle(context),
        ),
        const SizedBox(height: 22),
        for (final document in documents) ...[
          _TaxDocumentStatusRow(
            title: document.title,
            upload: uploadedForType(document.type),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 14),
        SizedBox(
          height: 45,
          child: FilledButton(
            key: const ValueKey('tax-submit-button'),
            onPressed: canSubmit ? onSubmit : null,
            style: _exchangePrimaryButtonStyle(
              backgroundColor: AppColors.orange500,
              radius: 8,
            ),
            child: Text(loading ? 'Submitting...' : 'Submit Documents'),
          ),
        ),
      ],
    );
  }
}

class _TaxSubmittedStep extends StatelessWidget {
  const _TaxSubmittedStep({
    required this.refundCase,
    required this.onConfirm,
    required this.onReview,
  });

  final TaxRefundCase? refundCase;
  final VoidCallback onConfirm;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('tax-submitted-step'),
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
      children: [
        Text('Documents Submitted!', style: _taxTitleStyle(context)),
        const SizedBox(height: 12),
        Text(
          'All required documents have been submitted successfully. We will review them and notify you of the next steps.',
          style: _taxBodyStyle(context),
        ),
        const SizedBox(height: 32),
        Icon(
          Icons.check_circle_outline,
          size: 148,
          color: AppColors.green500,
        ),
        const SizedBox(height: 34),
        if (refundCase != null)
          _TaxInfoPanel(
            title: 'Estimated Refund',
            lines: [
              refundCase!.refundDisplay,
              'Case ${refundCase!.referenceDisplay}',
            ],
          ),
        const SizedBox(height: 24),
        SizedBox(
          height: 45,
          child: FilledButton(
            key: const ValueKey('tax-confirm-button'),
            onPressed: onConfirm,
            style: _exchangePrimaryButtonStyle(
              backgroundColor: AppColors.orange500,
              radius: 8,
            ),
            child: const Text('Confirm'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 45,
          child: OutlinedButton(
            key: const ValueKey('tax-review-documents-button'),
            onPressed: onReview,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gray900,
              side: const BorderSide(color: AppColors.gray300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Review Documents'),
          ),
        ),
      ],
    );
  }
}

class _TaxInfoPanel extends StatelessWidget {
  const _TaxInfoPanel({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
          ),
          const SizedBox(height: 12),
          for (final line in lines) ...[
            Row(
              children: [
                const Icon(Icons.check, size: 16, color: AppColors.green500),
                const SizedBox(width: 10),
                Expanded(child: Text(line, style: _taxBodyStyle(context))),
              ],
            ),
            if (line != lines.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TaxVerificationPanel extends StatelessWidget {
  const _TaxVerificationPanel({required this.verification});

  final TaxDocumentVerification? verification;

  @override
  Widget build(BuildContext context) {
    final status = verification?.verificationStatus ?? 'NOT_UPLOADED';
    final color = status == 'REJECTED'
        ? AppColors.red500
        : status == 'VERIFIED'
            ? AppColors.green500
            : AppColors.orange500;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_outlined, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              verification == null
                  ? 'Waiting for OCR verification'
                  : '$status · OCR ${verification!.confidenceDisplay}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: AppColors.gray900,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxDocumentStatusRow extends StatelessWidget {
  const _TaxDocumentStatusRow({
    required this.title,
    required this.upload,
  });

  final String title;
  final TaxDocumentUpload? upload;

  @override
  Widget build(BuildContext context) {
    final status = upload?.verification?.verificationStatus ?? 'MISSING';
    final blocked = status == 'REJECTED' || status == 'MISSING';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Icon(
            blocked ? Icons.error_outline : Icons.check_circle_outline,
            color: blocked ? AppColors.red500 : AppColors.green500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            status,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: blocked ? AppColors.red500 : AppColors.green500,
                ),
          ),
        ],
      ),
    );
  }
}

TextStyle? _taxTitleStyle(BuildContext context) {
  return Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontSize: 28,
        height: 39 / 28,
        fontWeight: FontWeight.w700,
        color: AppColors.gray1000,
      );
}

TextStyle? _taxBodyStyle(BuildContext context, {double fontSize = 16}) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: fontSize,
        height: 1.38,
        color: AppColors.gray700,
      );
}
