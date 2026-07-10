part of '../exchange_pages.dart';

class _InvestmentInfoSection extends StatelessWidget {
  const _InvestmentInfoSection({
    required this.snapshot,
  });

  final _StockDetailSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.gray600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Cash Balance', style: mutedStyle),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                snapshot.accountDisplay,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mutedStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _StockInfoRow(label: 'Average Price', value: snapshot.averagePrice),
        const SizedBox(height: 16),
        _StockInfoRow(
          label: 'Return',
          value: snapshot.returnRate,
          valueColor: snapshot.isHoldingReturnPositive
              ? AppColors.green500
              : AppColors.red500,
        ),
        const SizedBox(height: 16),
        _StockInfoRow(label: 'Shares', value: snapshot.sharesDisplay),
        const SizedBox(height: 16),
        _StockInfoRow(
          label: 'Market Value',
          value: snapshot.marketValue,
          trailing: snapshot.marketValueChange,
          trailingColor: snapshot.isMarketValueChangePositive
              ? AppColors.green500
              : AppColors.red500,
        ),
        const SizedBox(height: 16),
        _StockInfoRow(label: 'Cost', value: snapshot.costDisplay),
      ],
    );
  }
}

class _ForeignOwnershipAlertCard extends StatelessWidget {
  const _ForeignOwnershipAlertCard({
    required this.snapshot,
  });

  final _StockDetailSnapshot snapshot;

  static const _outerBackgroundColor = Color(0xFFF5F6F6);
  static const _accentColor = Color(0xFFFF1550);
  static const _forecastColor = AppColors.green500;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        snapshot.isForeignLimitAlert ? _accentColor : _forecastColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _outerBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    snapshot.foreignLimitCardTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray1000,
                        ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: AppColors.gray500,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              snapshot.foreignLimitCardDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray600,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.estimatedOwnershipLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            height: 1.4,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      snapshot.estimatedRange,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: accentColor,
                                fontSize: 22,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: snapshot.alertProgress,
                        minHeight: 10,
                        backgroundColor: AppColors.gray300,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _AlertMetric(
                            label: 'Latest ownership',
                            value: snapshot.currentForeignOwnershipRatio,
                            alignEnd: false,
                          ),
                        ),
                        Expanded(
                          child: _AlertMetric(
                            label: 'Foreign ownership cap',
                            value: snapshot.limitForeignRatio,
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      snapshot.foreignLimitCardMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.gray800,
                            height: 1.4,
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
}

class _ForeignOwnershipTradingUnavailableCard extends StatelessWidget {
  const _ForeignOwnershipTradingUnavailableCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB8C5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Foreign ownership unavailable',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.red500,
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Foreign ownership is not permitted for this stock. Buying and selling are unavailable.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray800,
                    fontSize: 14,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertMetric extends StatelessWidget {
  const _AlertMetric({
    required this.label,
    required this.value,
    required this.alignEnd,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.gray900,
              ),
        ),
      ],
    );
  }
}

class _StockInfoRow extends StatelessWidget {
  const _StockInfoRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.gray1000,
    this.trailing,
    this.trailingColor,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String? trailing;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray1000,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: valueColor,
                      ),
                ),
                if (trailing != null)
                  TextSpan(
                    text: ' $trailing',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: trailingColor ?? valueColor,
                        ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _StockBottomActionBar extends StatelessWidget {
  const _StockBottomActionBar({
    required this.onSell,
    required this.onBuy,
    required this.isTradeEnabled,
  });

  final VoidCallback onSell;
  final VoidCallback onBuy;
  final bool isTradeEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 119,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.white.withValues(alpha: 0),
                  AppColors.white,
                ],
                stops: const [0, 0.2],
              ),
            ),
            child: SizedBox(
              height: 85,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _TradeActionButton(
                        key: const ValueKey('stock-detail-sell-button'),
                        label: 'Sell',
                        backgroundColor: AppColors.red500,
                        onTap: isTradeEnabled ? onSell : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TradeActionButton(
                        key: const ValueKey('stock-detail-buy-button'),
                        label: 'Buy',
                        backgroundColor: AppColors.green500,
                        onTap: isTradeEnabled ? onBuy : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 34,
            color: AppColors.white,
            child: Center(
              child: Image.asset(
                AppAssets.bottomHomeBar,
                width: 402,
                height: 34,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeActionButton extends StatelessWidget {
  const _TradeActionButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray300,
          disabledForegroundColor: AppColors.gray600,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
