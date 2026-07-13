part of '../../exchange_pages.dart';

class _AlertStatusBanner extends StatelessWidget {
  const _AlertStatusBanner({
    super.key,
    required this.iconAssetPath,
    required this.title,
    required this.description,
    required this.infoKey,
    required this.onInfoTap,
  });

  static const double height = 60;

  final String iconAssetPath;
  final String title;
  final String description;
  final Key infoKey;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: height),
      decoration: BoxDecoration(
        color: const Color(0xFF353A41),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Image.asset(
                      iconAssetPath,
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: AppColors.red500,
                            ),
                      ),
                    ),
                  ],
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                        color: AppColors.gray200,
                      ),
                ),
              ],
            ),
          ),
          InkWell(
            key: infoKey,
            onTap: onInfoTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                AppAssets.infoIcon,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViTriggeredBanner extends StatelessWidget {
  const _ViTriggeredBanner({
    required this.onInfoTap,
  });

  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    return _AlertStatusBanner(
      key: const ValueKey('vi-triggered-banner'),
      iconAssetPath: AppAssets.warningViIcon,
      title: 'VI triggered!',
      description: 'Trading may be temporarily halted.',
      infoKey: const ValueKey('vi-triggered-banner-info'),
      onInfoTap: onInfoTap,
    );
  }
}

class _CircuitBreakerTriggeredBanner extends StatelessWidget {
  const _CircuitBreakerTriggeredBanner({
    required this.onInfoTap,
  });

  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    return _AlertStatusBanner(
      key: const ValueKey('circuit-breaker-triggered-banner'),
      iconAssetPath: AppAssets.warningViIcon,
      title: 'Circuit breaker triggered!',
      description: 'Market-wide trading is temporarily halted.',
      infoKey: const ValueKey('circuit-breaker-triggered-banner-info'),
      onInfoTap: onInfoTap,
    );
  }
}

class _LowLimitReachedBanner extends StatelessWidget {
  const _LowLimitReachedBanner({
    required this.onInfoTap,
  });

  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    return _AlertStatusBanner(
      key: const ValueKey('low-limit-reached-banner'),
      iconAssetPath: AppAssets.chartDownMini,
      title: 'Lower limit reached!',
      description: 'Trading is limited at the daily price cap.',
      infoKey: const ValueKey('low-limit-reached-banner-info'),
      onInfoTap: onInfoTap,
    );
  }
}

class _ViInfoPanel extends StatelessWidget {
  const _ViInfoPanel();

  @override
  Widget build(BuildContext context) {
    return _StockAlertInfoPanelFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                AppAssets.warningViIcon,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                'VI triggered!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.red500,
                      fontSize: 18,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Trading may be temporarily halted.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'VI is a temporary volatility interruption used to pause trading when price movement becomes too sharp.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                  color: AppColors.gray700,
                ),
          ),
        ],
      ),
    );
  }
}

class _CircuitBreakerInfoPanel extends StatelessWidget {
  const _CircuitBreakerInfoPanel();

  @override
  Widget build(BuildContext context) {
    return _StockAlertInfoPanelFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                AppAssets.warningViIcon,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Circuit breaker triggered!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.red500,
                        fontSize: 18,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Market-wide trading is temporarily halted.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'A circuit breaker pauses the entire market after a sharp index decline. Trading resumes according to the exchange schedule.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                  color: AppColors.gray700,
                ),
          ),
        ],
      ),
    );
  }
}

class _LowLimitInfoPanel extends StatelessWidget {
  const _LowLimitInfoPanel();

  @override
  Widget build(BuildContext context) {
    return _StockAlertInfoPanelFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                AppAssets.chartDownMini,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lower limit reached!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.red500,
                        fontSize: 18,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Trading is limited at the daily price cap.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'The stock has reached its exchange-defined lower daily limit. Orders can still be placed, but executions are restricted around the capped price.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                  color: AppColors.gray700,
                ),
          ),
        ],
      ),
    );
  }
}

class _StockAlertInfoPanelFrame extends StatelessWidget {
  const _StockAlertInfoPanelFrame({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: _bottomSheetOuterPadding,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(_bottomSheetRadius),
          ),
          child: Padding(
            padding: _bottomSheetContentPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _BottomSheetDragHandle(),
                const SizedBox(height: 18),
                child,
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: _exchangePrimaryButtonStyle(
                      backgroundColor: AppColors.orange500,
                      padding: _secondaryActionPadding,
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSheetDragHandle extends StatelessWidget {
  const _BottomSheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _AlertRestrictionDialog extends StatelessWidget {
  const _AlertRestrictionDialog({
    required this.dialogKey,
    required this.confirmKey,
    required this.title,
    required this.description,
  });

  static const double _dialogWidth = 360;
  static const double _dialogHeight = 200;
  static const double _buttonHeight = 46;

  final Key dialogKey;
  final Key confirmKey;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 21),
          child: Container(
            key: dialogKey,
            width: _dialogWidth,
            height: _dialogHeight,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
            child: SizedBox(
              height: _dialogHeight - 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray1000,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 3,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.4,
                          letterSpacing: -0.28,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray600,
                        ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: _buttonHeight,
                    child: FilledButton(
                      key: confirmKey,
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1550),
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Confirm',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.white,
                              fontSize: 18,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ViRestrictionDialog extends StatelessWidget {
  const _ViRestrictionDialog();

  @override
  Widget build(BuildContext context) {
    return const _AlertRestrictionDialog(
      dialogKey: ValueKey('vi-restriction-dialog'),
      confirmKey: ValueKey('vi-restriction-confirm'),
      title: 'Volatility Interruption Triggered!',
      description: 'A VI has been triggered for this stock.\n'
          'Real-time executions are temporarily restricted, and\n'
          'orders will be processed through call auction trading.',
    );
  }
}

class _ForeignLimitBuyWarningDialog extends StatelessWidget {
  const _ForeignLimitBuyWarningDialog();

  @override
  Widget build(BuildContext context) {
    return const _AlertRestrictionDialog(
      dialogKey: ValueKey('foreign-limit-buy-warning-dialog'),
      confirmKey: ValueKey('foreign-limit-buy-warning-confirm'),
      title: 'Foreign Ownership Limit Warning!',
      description: 'Foreign ownership is expected to reach its limit today.\n'
          'Your buy order may fail to execute because the\n'
          'remaining foreign ownership quota is limited.',
    );
  }
}

class _PriceLimitRestrictionDialog extends StatelessWidget {
  const _PriceLimitRestrictionDialog();

  @override
  Widget build(BuildContext context) {
    return const _AlertRestrictionDialog(
      dialogKey: ValueKey('price-limit-restriction-dialog'),
      confirmKey: ValueKey('price-limit-restriction-confirm'),
      title: 'Price Limit Reached!',
      description: 'This stock has reached the daily price limit.\n'
          'Orders may be delayed due to pending orders at the\n'
          'limit price.',
    );
  }
}
