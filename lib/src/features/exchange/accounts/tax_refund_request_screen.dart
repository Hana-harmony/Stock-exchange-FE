part of '../exchange_pages.dart';

class TaxRefundRequestScreen extends StatefulWidget {
  const TaxRefundRequestScreen({
    super.key,
    required this.accountId,
    required this.taxController,
    this.filePicker,
  });

  final String accountId;
  final TaxController taxController;
  final Future<XFile?> Function()? filePicker;

  @override
  State<TaxRefundRequestScreen> createState() => _TaxRefundRequestScreenState();
}

class _TaxRefundRequestScreenState extends State<TaxRefundRequestScreen> {
  var _step = 0;
  final Map<String, _PickedTaxDocumentFile> _selectedFiles = {};

  static const _maxUploadBytes = 10 * 1024 * 1024;
  static const _allowedExtensions = {'pdf', 'png', 'jpg', 'jpeg', 'txt'};
  static const _documentTypeGroup = XTypeGroup(
    label: 'Tax documents',
    extensions: ['pdf', 'png', 'jpg', 'jpeg', 'txt'],
    mimeTypes: [
      'application/pdf',
      'image/png',
      'image/jpeg',
      'text/plain',
    ],
    uniformTypeIdentifiers: [
      'com.adobe.pdf',
      'public.png',
      'public.jpeg',
      'public.plain-text',
    ],
  );

  static const _documents = <_TaxRequiredDocument>[
    _TaxRequiredDocument(
      type: 'RESIDENCE_CERTIFICATE',
      title: 'Certificate of Tax Residence',
      listDescription:
          'Verifies your tax residency to determine eligibility for treaty tax benefits.',
      uploadTitle: 'Upload\nCertificate of\nTax Residence',
      uploadDescription:
          'Upload your Certificate of Tax Residence\nto verify your tax residency.',
      infoTitle: 'Why is Certificate of Tax Residence required?',
      infoText:
          'This document verifies your tax residency and confirms your eligibility to claim tax treaty benefits in accordance with the applicable tax regulations.',
      badge: 'Document 1',
      uploadStep: 2,
      analyzingStep: 3,
    ),
    _TaxRequiredDocument(
      type: 'APOSTILLE',
      title: 'Apostille Certificate',
      listDescription:
          'Certifies the authenticity of your official documents for international use.',
      uploadTitle: 'Upload\nApostille Certificate',
      uploadDescription:
          'Upload your Certificate of Tax Residence\nto verify your tax residency.',
      infoTitle: 'Why is an Apostille required?',
      infoText:
          'It is required for the Certificate of Residence to be recognized as a public document holding legal effect by public authorities and financial institutions in Korea.',
      badge: 'Document 2',
      uploadStep: 4,
      analyzingStep: 5,
    ),
    _TaxRequiredDocument(
      type: 'REDUCED_TAX_APPLICATION',
      title: 'Reduced Withholding\nTax Rate Application',
      listDescription:
          'Requests the application of the reduced withholding tax rate on eligible dividend income.',
      uploadTitle: 'Upload\nReduced Withholding\nTax Rate Application',
      uploadDescription:
          'Upload your completed application to\nrequest the reduced withholding tax rate.',
      infoTitle: 'Why is a Reduced Withholding\nTax Rate Application required?',
      infoText:
          'This application allows you to request a reduced withholding tax rate under the applicable tax treaty.',
      badge: 'Document 3',
      uploadStep: 6,
      analyzingStep: 7,
    ),
  ];

  @override
  void initState() {
    super.initState();
    widget.taxController.addListener(_handleTaxState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.taxController.loadRefundStatus(widget.accountId);
    });
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
      return _isVerified(_uploaded(document.type));
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
    final _PickedTaxDocumentFile? file;
    try {
      file = await _pickTaxDocumentFile(widget.filePicker);
    } on _TaxFileSelectionException catch (error) {
      if (mounted) {
        await _showUploadError(error.message);
      }
      return;
    }
    if (file == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _selectedFiles[document.type] = file!;
        _step = document.analyzingStep;
      });
    }

    await widget.taxController.uploadDocument(
      accountId: widget.accountId,
      documentType: document.type,
      fileName: file.name,
      bytes: file.bytes,
      contentType: file.contentType,
    );
    if (!mounted) {
      return;
    }

    final uploaded = _uploaded(document.type);
    if (!_isVerified(uploaded)) {
      setState(() {
        _step = document.uploadStep;
      });
      await _showVerificationFailure(uploaded?.verification);
      return;
    }

    if (document.type == 'REDUCED_TAX_APPLICATION') {
      await _submitVerifiedDocuments();
      return;
    }

    setState(() {
      _step = document.type == 'RESIDENCE_CERTIFICATE' ? 4 : 6;
    });
  }

  Future<void> _submitVerifiedDocuments() async {
    if (!_hasAllDocuments) {
      await _showUploadError(
        'Complete OCR verification for every required document.',
      );
      return;
    }
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
    if (!mounted) {
      return;
    }
    if (widget.taxController.value.status == TaxStatus.failure) {
      setState(() {
        _step = 6;
      });
      await _showSubmissionError(
        'The verified documents could not be submitted. Please try again.',
      );
      return;
    }
    setState(() {
      _step = 8;
    });
    await widget.taxController.syncRefundStatus(widget.accountId);
    if (!mounted) {
      return;
    }
    if (widget.taxController.value.status == TaxStatus.failure) {
      await _showSubmissionError(
        'Your documents were saved, but status sync failed. Retry status sync.',
      );
    }
  }

  Future<void> _retryStatusSync() async {
    await widget.taxController.syncRefundStatus(widget.accountId);
    if (!mounted || widget.taxController.value.status != TaxStatus.failure) {
      return;
    }
    await _showSubmissionError(
      'Status sync failed. Your submitted documents remain safely saved.',
    );
  }

  Future<void> _showVerificationFailure(
    TaxDocumentVerification? verification,
  ) {
    final reasons = <String>[
      ...?verification?.rejectionReasons,
      ...?verification?.missingRequiredFields.map(
        (field) => 'Missing required field: $field',
      ),
    ];
    final message = reasons.isNotEmpty
        ? reasons.join('\n')
        : widget.taxController.value.errorMessage ??
            'The document could not be verified. Upload a clearer valid document.';
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        key: const ValueKey('tax-verification-failure-dialog'),
        title: const Text('Document verification failed'),
        content: Text(message),
        actions: [
          FilledButton(
            key: const ValueKey('tax-reupload-dialog-action'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Upload again'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUploadError(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload failed'),
        content: _TaxFileErrorPanel(message: message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSubmissionError(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('tax-submission-error-dialog'),
        title: const Text('Status update failed'),
        content: _TaxFileErrorPanel(message: message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
            if (_showsProgress) _TaxSegmentProgressBar(filled: _filledSegments),
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

  bool get _showsProgress => _step >= 1 && _step <= 7;

  int get _filledSegments {
    if (_step <= 1) {
      return 1;
    }
    if (_step <= 3) {
      return 2;
    }
    if (_step <= 5) {
      return 3;
    }
    return 4;
  }

  Widget _buildStep(BuildContext context, TaxState state, bool loading) {
    final existingSubmission = state.refundCase;
    if (_step == 0 &&
        existingSubmission != null &&
        existingSubmission.caseId.isNotEmpty &&
        existingSubmission.status != 'NOT_SUBMITTED') {
      return _TaxSubmittedStep(
        refundCase: existingSubmission,
        onConfirm: () => Navigator.of(context).pop(),
        onReview: () => setState(() {
          widget.taxController.beginReplacement();
          _selectedFiles.clear();
          _step = 1;
        }),
        isExistingSubmission: true,
      );
    }
    if (_step == 0) {
      return _TaxLandingStep(
        documents: _documents,
        loading: loading,
        onApply: () => setState(() => _step = 1),
      );
    }
    if (_step == 1) {
      return _TaxConsentStep(
        loading: loading,
        onCancel: () => Navigator.of(context).pop(),
        onAgree: () => setState(() => _step = 2),
      );
    }
    final uploadDocument = _documentForUploadStep(_step);
    if (uploadDocument != null) {
      return _TaxDocumentUploadStep(
        key: ValueKey('tax-document-step-${uploadDocument.type}'),
        document: uploadDocument,
        uploaded: _uploaded(uploadDocument.type),
        loading: loading,
        onUpload: () => _upload(uploadDocument),
      );
    }
    final analyzingDocument = _documentForAnalyzingStep(_step);
    if (analyzingDocument != null) {
      return _TaxAnalyzingStep(
        key: ValueKey('tax-analyzing-step-${analyzingDocument.type}'),
        verification: _uploaded(analyzingDocument.type)?.verification,
        selectedFile: _selectedFiles[analyzingDocument.type],
      );
    }
    return _TaxSubmittedStep(
      refundCase: state.refundCase,
      onConfirm: () => Navigator.of(context).pop(),
      onReview: state.status == TaxStatus.failure
          ? _retryStatusSync
          : () => setState(() => _step = 0),
      isExistingSubmission: false,
      syncFailed: state.status == TaxStatus.failure,
      syncing: state.status == TaxStatus.loading,
    );
  }

  _TaxRequiredDocument? _documentForUploadStep(int step) {
    for (final document in _documents) {
      if (document.uploadStep == step) {
        return document;
      }
    }
    return null;
  }

  _TaxRequiredDocument? _documentForAnalyzingStep(int step) {
    for (final document in _documents) {
      if (document.analyzingStep == step) {
        return document;
      }
    }
    return null;
  }
}

bool _isVerified(TaxDocumentUpload? upload) {
  return upload?.isVerified ?? false;
}

Future<_PickedTaxDocumentFile?> _pickTaxDocumentFile(
  Future<XFile?> Function()? picker,
) async {
  final selected = await (picker?.call() ??
      openFile(acceptedTypeGroups: [
        _TaxRefundRequestScreenState._documentTypeGroup,
      ]));
  if (selected == null) {
    return null;
  }
  final fileName = _safeTaxFileName(selected.name);
  if (!_isAllowedTaxFileName(fileName)) {
    throw const _TaxFileSelectionException(
      'Upload PDF, PNG, JPG, JPEG, or TXT documents only.',
    );
  }
  final length = await selected.length();
  if (length <= 0) {
    throw const _TaxFileSelectionException('Select a non-empty file.');
  }
  if (length > _TaxRefundRequestScreenState._maxUploadBytes) {
    throw const _TaxFileSelectionException('File must be 10 MB or smaller.');
  }
  final bytes = await selected.readAsBytes();
  if (bytes.isEmpty) {
    throw const _TaxFileSelectionException('Select a non-empty file.');
  }
  if (bytes.length > _TaxRefundRequestScreenState._maxUploadBytes) {
    throw const _TaxFileSelectionException('File must be 10 MB or smaller.');
  }
  return _PickedTaxDocumentFile(
    name: fileName,
    bytes: bytes,
    contentType: selected.mimeType ?? _contentTypeForTaxFile(fileName),
  );
}

String _safeTaxFileName(String rawName) {
  final normalized = rawName.replaceAll('\\', '/');
  final fileName = normalized.substring(normalized.lastIndexOf('/') + 1).trim();
  return fileName.isEmpty ? 'tax-document' : fileName;
}

bool _isAllowedTaxFileName(String fileName) {
  final extension = _taxFileExtension(fileName);
  return _TaxRefundRequestScreenState._allowedExtensions.contains(extension);
}

String _taxFileExtension(String fileName) {
  final index = fileName.lastIndexOf('.');
  if (index < 0 || index == fileName.length - 1) {
    return '';
  }
  return fileName.substring(index + 1).toLowerCase();
}

String _contentTypeForTaxFile(String fileName) {
  switch (_taxFileExtension(fileName)) {
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'txt':
      return 'text/plain';
    default:
      return 'application/octet-stream';
  }
}

class _PickedTaxDocumentFile {
  const _PickedTaxDocumentFile({
    required this.name,
    required this.bytes,
    required this.contentType,
  });

  final String name;
  final Uint8List bytes;
  final String contentType;
}

class _TaxFileSelectionException implements Exception {
  const _TaxFileSelectionException(this.message);

  final String message;
}

class _TaxRequiredDocument {
  const _TaxRequiredDocument({
    required this.type,
    required this.title,
    required this.listDescription,
    required this.uploadTitle,
    required this.uploadDescription,
    required this.infoTitle,
    required this.infoText,
    required this.badge,
    required this.uploadStep,
    required this.analyzingStep,
  });

  final String type;
  final String title;
  final String listDescription;
  final String uploadTitle;
  final String uploadDescription;
  final String infoTitle;
  final String infoText;
  final String badge;
  final int uploadStep;
  final int analyzingStep;
}

class _TaxRequestHeader extends StatelessWidget {
  const _TaxRequestHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 4),
        child: Row(
          children: [
            Image.asset(AppAssets.logoSymbol, width: 36, height: 36),
            const Spacer(),
            _TaxHeaderIconButton(
              tooltip: 'Information',
              onPressed: () {},
              child: const Icon(
                Icons.info_outline,
                size: 22,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(width: 4),
            _TaxHeaderIconButton(
              tooltip: 'Close',
              onPressed: onClose,
              child: const Icon(
                Icons.close,
                size: 24,
                color: AppColors.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaxHeaderIconButton extends StatelessWidget {
  const _TaxHeaderIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        icon: child,
      ),
    );
  }
}

class _TaxSegmentProgressBar extends StatelessWidget {
  const _TaxSegmentProgressBar({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            for (var index = 0; index < 4; index++) ...[
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: index < filled
                        ? AppColors.orange500
                        : AppColors.gray200,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              if (index != 3) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaxLandingStep extends StatelessWidget {
  const _TaxLandingStep({
    required this.documents,
    required this.loading,
    required this.onApply,
  });

  final List<_TaxRequiredDocument> documents;
  final bool loading;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return _TaxScreenWithBottomAction(
      key: const ValueKey('tax-landing-step'),
      primaryLabel: 'Apply Reduced Rate',
      primaryKey: const ValueKey('tax-apply-button'),
      primaryLoading: loading,
      onPrimary: onApply,
      child: _TaxFitContent(
        padding: const EdgeInsets.fromLTRB(0, 32, 0, 132),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reduced Withholding\nTax Rate Available',
              textAlign: TextAlign.center,
              style: _taxTitleStyle(context),
            ),
            const SizedBox(height: 12),
            const _TaxRateSummary(),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Required Documents',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      height: 25 / 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray1000,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < documents.length; index++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _TaxRequiredDocumentCard(document: documents[index]),
              ),
              if (index != documents.length - 1) const _TaxDocumentConnector(),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaxRateSummary extends StatelessWidget {
  const _TaxRateSummary();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '22%',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                    height: 31 / 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray500,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.gray500,
                  ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: AppColors.gray500, size: 20),
            const SizedBox(width: 8),
            Text(
              '16.5%',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 38,
                    height: 53 / 38,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '*Including Local Taxes',
          style: _taxBodyStyle(context, fontSize: 14),
        ),
      ],
    );
  }
}

class _TaxRequiredDocumentCard extends StatelessWidget {
  const _TaxRequiredDocumentCard({required this.document});

  final _TaxRequiredDocument document;

  @override
  Widget build(BuildContext context) {
    final cardHeight = document.title.contains('\n') ? 116.0 : 91.0;
    final badgeWidth = document.badge == 'Document 1' ? 95.0 : 97.0;
    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: Text(
              document.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    height: 25 / 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange500,
                  ),
            ),
          ),
          Positioned(
            left: 16,
            top: document.title.contains('\n') ? 66 : 41,
            right: 16,
            child: Text(
              document.listDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _taxBodyStyle(context, fontSize: 12),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: badgeWidth,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFDDDDDD)),
              child: Text(
                document.badge,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxDocumentConnector extends StatelessWidget {
  const _TaxDocumentConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, size: 16, color: AppColors.gray700),
        ),
      ),
    );
  }
}

class _TaxConsentStep extends StatelessWidget {
  const _TaxConsentStep({
    required this.loading,
    required this.onCancel,
    required this.onAgree,
  });

  final bool loading;
  final VoidCallback onCancel;
  final VoidCallback onAgree;

  @override
  Widget build(BuildContext context) {
    return _TaxScreenWithBottomAction(
      key: const ValueKey('tax-consent-step'),
      primaryLabel: 'Agree to All',
      primaryKey: const ValueKey('tax-agree-button'),
      primaryLoading: loading,
      onPrimary: onAgree,
      secondaryLabel: 'Cancel',
      onSecondary: onCancel,
      child: _TaxFitContent(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 152),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consent to the\nCollection and Use of\nPersonal Information',
              style: _taxTitleStyle(context),
            ),
            const SizedBox(height: 20),
            Text(
              'Upload the required documents to process\nyour tax reassessment claim. Your documents\nare securely protected under the GLBA\nand used only for this service.',
              style: _taxBodyStyle(context),
            ),
            const SizedBox(height: 24),
            Text(
              'You may refuse to provide your consent.\nHowever, doing so may restrict your use of\nthe tax reassessment claim service.',
              style: _taxBodyStyle(context),
            ),
            const SizedBox(height: 112),
            const _TaxCollectedInfoPanel(),
          ],
        ),
      ),
    );
  }
}

class _TaxCollectedInfoPanel extends StatelessWidget {
  const _TaxCollectedInfoPanel();

  @override
  Widget build(BuildContext context) {
    const lines = [
      'Full Name',
      'Resident Registration Number (RRN)',
      'Original Tax-Related Documents',
      'Bank Account Information',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Information Collected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  height: 25 / 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray1000,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              for (final line in lines) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.orange500,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        line,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray700,
                            ),
                      ),
                    ),
                  ],
                ),
                if (line != lines.last) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TaxDocumentUploadStep extends StatelessWidget {
  const _TaxDocumentUploadStep({
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
    return _TaxScreenWithBottomAction(
      primaryLabel: uploaded == null ? 'Upload File' : 'Re-upload File',
      primaryKey: ValueKey('tax-upload-${document.type}'),
      primaryLoading: loading,
      onPrimary: loading ? null : onUpload,
      child: _TaxFitContent(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 152),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(document.uploadTitle, style: _taxTitleStyle(context)),
            const SizedBox(height: 12),
            Text(document.uploadDescription, style: _taxBodyStyle(context)),
            const SizedBox(height: 46),
            const SizedBox(
              height: 240,
              child: _TaxUploadIllustration(),
            ),
            _TaxInfoCallout(title: document.infoTitle, body: document.infoText),
            if (uploaded != null) ...[
              const SizedBox(height: 10),
              _TaxSelectedFilePanel(uploaded: uploaded!),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaxUploadIllustration extends StatelessWidget {
  const _TaxUploadIllustration();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Transform.translate(
        offset: const Offset(16, 0),
        child: Image.asset(
          AppAssets.taxUploadDocument,
          width: 294,
          height: 240,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _TaxInfoCallout extends StatelessWidget {
  const _TaxInfoCallout({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final height = title.contains('\n') ? 134.0 : 129.0;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.orange100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  height: 17 / 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.gray700,
                ),
          ),
        ],
      ),
    );
  }
}

class _TaxAnalyzingStep extends StatelessWidget {
  const _TaxAnalyzingStep({
    super.key,
    required this.verification,
    required this.selectedFile,
  });

  final TaxDocumentVerification? verification;
  final _PickedTaxDocumentFile? selectedFile;

  @override
  Widget build(BuildContext context) {
    return _TaxFitContent(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analyzing\nYour Documents...', style: _taxTitleStyle(context)),
          const SizedBox(height: 12),
          Text(
            'Using OCR to extract and validate\nthe information in your uploaded documents.',
            style: _taxBodyStyle(context),
          ),
          const SizedBox(height: 121),
          _TaxDocumentAnalysisPreview(
            verification: verification,
            selectedFile: selectedFile,
          ),
        ],
      ),
    );
  }
}

class _TaxDocumentAnalysisPreview extends StatefulWidget {
  const _TaxDocumentAnalysisPreview({
    required this.verification,
    required this.selectedFile,
  });

  final TaxDocumentVerification? verification;
  final _PickedTaxDocumentFile? selectedFile;

  @override
  State<_TaxDocumentAnalysisPreview> createState() =>
      _TaxDocumentAnalysisPreviewState();
}

class _TaxDocumentAnalysisPreviewState
    extends State<_TaxDocumentAnalysisPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ((widget.verification?.progressPercent ?? 0) / 100)
        .clamp(0.0, 1.0)
        .toDouble();
    final stage = widget.verification?.stageDisplay ?? 'Uploading to Exchange';
    return Center(
      child: Container(
        width: 358,
        height: 460,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gray200),
          boxShadow: AppShadows.card,
        ),
        child: Stack(
          children: [
            Positioned.fill(child: _buildSelectedDocumentPreview()),
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) => Positioned(
                left: 0,
                right: 0,
                top: 12 + (_scanController.value * 344),
                child: Container(
                  height: 2,
                  decoration: const BoxDecoration(
                    color: AppColors.orange500,
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(255, 121, 27, 0.45),
                        blurRadius: 12,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.orange500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$stage · ${(progress * 100).round()}%',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      height: 17 / 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray700,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: progress == 0 ? null : progress,
                        backgroundColor: AppColors.gray200,
                        color: AppColors.orange500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDocumentPreview() {
    final selectedFile = widget.selectedFile;
    if (selectedFile == null) {
      return _TaxVerificationPanel(
        verification: widget.verification,
        verifying: true,
      );
    }
    if (selectedFile.contentType.startsWith('image/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          selectedFile.bytes,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const Center(
            child: Text('Unable to preview the uploaded image'),
          ),
        ),
      );
    }
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_outlined,
              size: 72, color: AppColors.orange500),
          SizedBox(height: 12),
          Text('Encrypted PDF uploaded for OCR'),
        ],
      ),
    );
  }
}

class _TaxSubmittedStep extends StatelessWidget {
  const _TaxSubmittedStep({
    required this.refundCase,
    required this.onConfirm,
    required this.onReview,
    required this.isExistingSubmission,
    this.syncFailed = false,
    this.syncing = false,
  });

  final TaxRefundCase? refundCase;
  final VoidCallback onConfirm;
  final VoidCallback onReview;
  final bool isExistingSubmission;
  final bool syncFailed;
  final bool syncing;

  @override
  Widget build(BuildContext context) {
    return _TaxScreenWithBottomAction(
      key: const ValueKey('tax-submitted-step'),
      primaryLabel: 'Confirm',
      primaryKey: const ValueKey('tax-confirm-button'),
      primaryLoading: syncing,
      onPrimary: onConfirm,
      secondaryLabel: syncFailed
          ? 'Retry Status Sync'
          : isExistingSubmission
              ? 'Submit again'
              : 'Review Documents',
      onSecondary: onReview,
      stackedSecondary: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 150),
        child: Column(
          children: [
            Text(
              refundCase?.status == 'COMPLETED'
                  ? 'Tax Filing Complete!'
                  : 'Documents Submitted!',
              textAlign: TextAlign.center,
              style: _taxTitleStyle(context)?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 12),
            Text(
              refundCase?.status == 'COMPLETED'
                  ? 'Your correction request has been processed by Hana OmniLens.'
                  : isExistingSubmission
                      ? 'Your verified documents are in review. Start a new submission only when the documents need to be updated.'
                      : "All required documents have been submitted successfully. We'll review them and notify you of the next steps.",
              textAlign: TextAlign.center,
              style: _taxBodyStyle(context),
            ),
            if (syncFailed) ...[
              const SizedBox(height: 16),
              const _TaxFileErrorPanel(
                message:
                    'Your documents are saved. Status sync needs to be retried.',
              ),
            ],
            const Spacer(),
            const SizedBox(
              height: 308,
              width: double.infinity,
              child: _TaxSubmittedIllustration(),
            ),
            const Spacer(),
            if (refundCase != null)
              Text(
                '${refundCase!.refundDisplay} · Case ${refundCase!.referenceDisplay}',
                textAlign: TextAlign.center,
                style: _taxBodyStyle(context, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaxSubmittedIllustration extends StatelessWidget {
  const _TaxSubmittedIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TaxSubmittedIllustrationPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _TaxSubmittedIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 370;
    canvas.scale(scale);
    final paper = Paint()..color = const Color(0xFFF1F2F4);
    final paperLine = Paint()
      ..color = const Color(0xFFD9DCE0)
      ..strokeWidth = 4;
    final folder = Paint()..color = const Color(0xFFD7D9DD);
    final orange = Paint()..color = const Color(0xFFFF9A47);
    final coinEdge = Paint()
      ..color = const Color(0xFFFFC58F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final document = Path()
      ..moveTo(106, 26)
      ..lineTo(230, 26)
      ..lineTo(272, 68)
      ..lineTo(272, 202)
      ..lineTo(106, 202)
      ..close();
    canvas.drawPath(document, paper);
    canvas.drawLine(const Offset(130, 104), const Offset(239, 104), paperLine);
    canvas.drawLine(const Offset(130, 124), const Offset(220, 124), paperLine);
    final folderPath = Path()
      ..moveTo(160, 147)
      ..lineTo(218, 147)
      ..lineTo(236, 165)
      ..lineTo(306, 165)
      ..lineTo(326, 280)
      ..lineTo(142, 280)
      ..close();
    canvas.drawPath(folderPath, folder);
    canvas.drawCircle(const Offset(102, 228), 61, orange);
    canvas.drawCircle(const Offset(102, 228), 59, coinEdge);
    canvas.drawCircle(const Offset(290, 88), 28, orange);
    canvas.drawCircle(const Offset(290, 88), 26, coinEdge);
    final dollar = TextPainter(
      text: const TextSpan(
          text: '\$',
          style: TextStyle(
              color: AppColors.white,
              fontSize: 61,
              fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    dollar.paint(canvas, const Offset(84, 192));
    final smallDollar = TextPainter(
      text: const TextSpan(
          text: '\$',
          style: TextStyle(
              color: AppColors.white,
              fontSize: 29,
              fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    smallDollar.paint(canvas, const Offset(282, 70));
  }

  @override
  bool shouldRepaint(covariant _TaxSubmittedIllustrationPainter oldDelegate) =>
      false;
}

class _TaxScreenWithBottomAction extends StatelessWidget {
  const _TaxScreenWithBottomAction({
    super.key,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryKey,
    this.primaryLoading = false,
    this.secondaryLabel,
    this.onSecondary,
    this.stackedSecondary = false,
  });

  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final Key? primaryKey;
  final bool primaryLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool stackedSecondary;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              16,
              24,
              16,
              34 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(255, 255, 255, 0),
                  AppColors.white,
                  AppColors.white,
                ],
                stops: [0, 0.2, 1],
              ),
            ),
            child: stackedSecondary
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TaxPrimaryButton(
                        key: primaryKey,
                        label: primaryLabel,
                        loading: primaryLoading,
                        onPressed: onPrimary,
                      ),
                      if (secondaryLabel != null) ...[
                        const SizedBox(height: 12),
                        _TaxSecondaryButton(
                          label: secondaryLabel!,
                          onPressed: onSecondary,
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      if (secondaryLabel != null) ...[
                        SizedBox(
                          width: 120,
                          child: _TaxSecondaryButton(
                            label: secondaryLabel!,
                            onPressed: onSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: _TaxPrimaryButton(
                          key: primaryKey,
                          label: primaryLabel,
                          loading: primaryLoading,
                          onPressed: onPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _TaxFitContent extends StatelessWidget {
  const _TaxFitContent({
    required this.padding,
    required this.child,
  });

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: padding,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: math.max(0, constraints.maxWidth - padding.horizontal),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _TaxPrimaryButton extends StatelessWidget {
  const _TaxPrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: _exchangePrimaryButtonStyle(
          backgroundColor: AppColors.orange500,
          radius: 8,
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _TaxSecondaryButton extends StatelessWidget {
  const _TaxSecondaryButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gray700,
          side: const BorderSide(color: AppColors.gray300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 18,
                height: 25 / 18,
                fontWeight: FontWeight.w600,
              ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _TaxVerificationPanel extends StatelessWidget {
  const _TaxVerificationPanel({
    required this.verification,
    required this.verifying,
  });

  final TaxDocumentVerification? verification;
  final bool verifying;

  @override
  Widget build(BuildContext context) {
    final verified = verification?.isHanaMontanaVerified ?? false;
    final blocked = verification != null && !verified;
    final color = blocked
        ? AppColors.red500
        : verified
            ? AppColors.green500
            : AppColors.orange500;
    final progress =
        ((verification?.progressPercent ?? 0) / 100).clamp(0.0, 1.0).toDouble();
    final text = verifying
        ? verification == null
            ? 'Uploading to OmniLens · Verifying with Hana Montana OCR'
            : '${verification!.stageDisplay} · ${verification!.progressPercent}%'
        : verification == null
            ? 'Waiting for OCR verification'
            : verified
                ? 'VERIFIED · Hana Montana OCR ${verification!.confidenceDisplay}'
                : _blockedVerificationText(verification!);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              verifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.orange500,
                      ),
                    )
                  : Icon(
                      verified ? Icons.verified_outlined : Icons.error_outline,
                      color: color,
                      size: 20,
                    ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
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
          if (verifying) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: progress == 0 ? null : progress,
                backgroundColor: AppColors.gray200,
                color: AppColors.orange500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _blockedVerificationText(TaxDocumentVerification verification) {
  if (verification.verificationStatus == 'PENDING') {
    return 'PENDING · Hana Montana OCR has not approved this document yet';
  }
  if (verification.manualReviewRequired) {
    return 'MANUAL REVIEW · Re-upload a clearer approved document';
  }
  if (verification.source != 'HANNAH_MONTANA_AI_TAX_OCR') {
    return 'UNVERIFIED SOURCE · Hana Montana OCR verification required';
  }
  return '${verification.verificationStatus} · Re-upload required';
}

class _TaxSelectedFilePanel extends StatelessWidget {
  const _TaxSelectedFilePanel({required this.uploaded});

  final TaxDocumentUpload uploaded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            color: AppColors.orange500,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Previously uploaded document · ${_formatTaxFileSize(uploaded.sizeBytes)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _taxBodyStyle(context, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxFileErrorPanel extends StatelessWidget {
  const _TaxFileErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red500, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: _taxBodyStyle(context, fontSize: 13)?.copyWith(
                color: AppColors.red500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTaxFileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}

TextStyle? _taxTitleStyle(BuildContext context) {
  return Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontSize: 28,
        height: 39 / 28,
        fontWeight: FontWeight.w600,
        color: AppColors.slate600,
      );
}

TextStyle? _taxBodyStyle(BuildContext context, {double fontSize = 16}) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: fontSize,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: AppColors.gray600,
      );
}
