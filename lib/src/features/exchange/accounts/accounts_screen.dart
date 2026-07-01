part of '../exchange_pages.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({
    super.key,
    required this.sessionController,
    required this.accountController,
    required this.tradeController,
  });

  final ExchangeSessionController sessionController;
  final AccountController accountController;
  final TradeController tradeController;

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  int _selectedPrimaryTab = 1;
  int _selectedAssetFilter = 0;
  int _selectedMarketScope = 0;
  String? _requestedAccountId;

  @override
  void initState() {
    super.initState();
    widget.sessionController.addListener(_ensureAccountDataLoaded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureAccountDataLoaded();
    });
  }

  @override
  void didUpdateWidget(covariant AccountsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionController != widget.sessionController) {
      oldWidget.sessionController.removeListener(_ensureAccountDataLoaded);
      widget.sessionController.addListener(_ensureAccountDataLoaded);
      _requestedAccountId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureAccountDataLoaded();
      });
    }
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_ensureAccountDataLoaded);
    super.dispose();
  }

  void _ensureAccountDataLoaded() {
    final accountId = widget.sessionController.session?.accountId;
    if (accountId == null ||
        accountId.isEmpty ||
        accountId == _requestedAccountId) {
      return;
    }
    _requestedAccountId = accountId;

    if (widget.accountController.value.account?.accountId != accountId) {
      widget.accountController.loadAccount(accountId);
    }
    if (widget.tradeController.value.portfolio?.accountId != accountId) {
      widget.tradeController.loadPortfolio(accountId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.accountController,
        widget.tradeController,
      ]),
      builder: (context, _) {
        final snapshot = _AccountsScreenSnapshot.fromControllers(
          account: widget.accountController.value.account,
          portfolio: widget.tradeController.value.portfolio,
        );

        return ColoredBox(
          key: const ValueKey('accounts-screen'),
          color: AppColors.white,
          child: ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  height: 386,
                  child: _AccountsHeaderSection(
                    snapshot: snapshot,
                    selectedPrimaryTab: _selectedPrimaryTab,
                    onPrimaryTabSelected: (index) {
                      setState(() {
                        _selectedPrimaryTab = index;
                      });
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 352,
                  right: 0,
                  height: 34,
                  child: _AccountsAssetFilterTabs(
                    selectedIndex: _selectedAssetFilter,
                    onSelected: (index) {
                      setState(() {
                        _selectedAssetFilter = index;
                      });
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 402,
                  right: 0,
                  height: 476,
                  child: _AccountsHoldingsSection(
                    snapshot: snapshot,
                    selectedMarketScope: _selectedMarketScope,
                    onMarketScopeSelected: (index) {
                      setState(() {
                        _selectedMarketScope = index;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AccountsHeaderSection extends StatelessWidget {
  const _AccountsHeaderSection({
    required this.snapshot,
    required this.selectedPrimaryTab,
    required this.onPrimaryTabSelected,
  });

  final _AccountsScreenSnapshot snapshot;
  final int selectedPrimaryTab;
  final ValueChanged<int> onPrimaryTabSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 62),
        _AccountsPageTitle(),
        _AccountsPrimaryTabs(
          selectedIndex: selectedPrimaryTab,
          onSelected: onPrimaryTabSelected,
        ),
        _AccountsAccountSelector(accountLabel: snapshot.accountLabel),
        _AccountsSummaryCard(snapshot: snapshot),
      ],
    );
  }
}

class _AccountsPageTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('accounts-page-title'),
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: Image.asset(
                AppAssets.logoSymbol,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Accounts',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      height: 31 / 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray1000,
                    ),
              ),
            ),
            _AccountsHeaderIconButton(
              buttonKey: const ValueKey('accounts-header-more'),
              semanticLabel: 'Accounts More',
              assetPath: AppAssets.headerMoreIcon,
            ),
            const SizedBox(width: 4),
            _AccountsHeaderIconButton(
              buttonKey: const ValueKey('accounts-header-settings'),
              semanticLabel: 'Accounts Settings',
              assetPath: AppAssets.settingsIcon,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountsHeaderIconButton extends StatelessWidget {
  const _AccountsHeaderIconButton({
    required this.buttonKey,
    required this.semanticLabel,
    required this.assetPath,
  });

  final Key buttonKey;
  final String semanticLabel;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkResponse(
        key: buttonKey,
        onTap: () {},
        radius: 20,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Image.asset(
              assetPath,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountsPrimaryTabs extends StatelessWidget {
  const _AccountsPrimaryTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _tabs = <String>[
    'Assets',
    'Portfolio',
    'Domestic Stocks',
    'International Stocks',
    'Investment Returns',
  ];

  static const _widths = <double>[56, 72, 138, 164, 160];

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('accounts-primary-tabs'),
      height: 41,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (var index = 0; index < _tabs.length; index++) ...[
                AppUnderlineTab(
                  label: _tabs[index],
                  width: _widths[index],
                  height: index == selectedIndex ? 31 : 25,
                  isSelected: index == selectedIndex,
                  onTap: () => onSelected(index),
                  fontSize: 18,
                  lineHeight: 1.4,
                  fontWeightSelected: FontWeight.w600,
                  fontWeightUnselected: FontWeight.w500,
                  underlineWidth: _widths[index],
                ),
                if (index != _tabs.length - 1) const SizedBox(width: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountsAccountSelector extends StatelessWidget {
  const _AccountsAccountSelector({
    required this.accountLabel,
  });

  final String accountLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('accounts-account-selector'),
      height: 56,
      width: double.infinity,
      color: AppColors.gray100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              accountLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray900,
                  ),
            ),
          ),
          SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Image.asset(
                AppAssets.dropdownIcon,
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

class _AccountsSummaryCard extends StatelessWidget {
  const _AccountsSummaryCard({
    required this.snapshot,
  });

  final _AccountsScreenSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final isPositive = snapshot.totalPnlValue >= 0;
    final color = isPositive ? AppColors.green500 : AppColors.red500;
    final iconAsset =
        isPositive ? AppAssets.chartUpMini : AppAssets.chartDownMini;

    return SizedBox(
      key: const ValueKey('accounts-summary-section'),
      height: 149,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        child: Container(
          key: const ValueKey('accounts-summary-card'),
          width: double.infinity,
          height: 117,
          decoration: BoxDecoration(
            color: AppColors.slate600,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Assets',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                snapshot.totalAssetsDisplay,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      height: 31 / 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    iconAsset,
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    snapshot.totalPnlDisplay,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.28,
                          color: color,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountsAssetFilterTabs extends StatelessWidget {
  const _AccountsAssetFilterTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _tabs = <String>[
    'All',
    'Domestic',
    'International',
    'Foreign Currency (Cash Balance)',
  ];
  static const _widths = <double>[43, 93, 116, 264];

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('accounts-asset-filter-tabs'),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return SizedBox(
            key: ValueKey('accounts-asset-filter-tab-$index'),
            width: _widths[index],
            child: Material(
              color: isSelected ? AppColors.gray750 : AppColors.white,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(6),
                splashFactory: NoSplash.splashFactory,
                child: Ink(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected
                        ? null
                        : Border.all(color: AppColors.gray300),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _tabs[index],
                        maxLines: 1,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              height: 1.4,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.gray600,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _tabs.length,
      ),
    );
  }
}

class _AccountsHoldingsSection extends StatelessWidget {
  const _AccountsHoldingsSection({
    required this.snapshot,
    required this.selectedMarketScope,
    required this.onMarketScopeSelected,
  });

  final _AccountsScreenSnapshot snapshot;
  final int selectedMarketScope;
  final ValueChanged<int> onMarketScopeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('accounts-holdings-section'),
      children: [
        Container(
          key: const ValueKey('accounts-holdings-filter-row'),
          height: 56,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: RichText(
                  key: const ValueKey('accounts-total-positions'),
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Total ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray900,
                            ),
                      ),
                      TextSpan(
                        text: '${snapshot.totalPositions}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: AppColors.orange500,
                            ),
                      ),
                      TextSpan(
                        text: ' Positions',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray900,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _AccountsMarketScopeSegmentedControl(
                selectedIndex: selectedMarketScope,
                onSelected: onMarketScopeSelected,
              ),
            ],
          ),
        ),
        Container(
          key: const ValueKey('accounts-table-header'),
          height: 48,
          width: double.infinity,
          color: AppColors.gray50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: _AccountsTableHeaderTitle(
                  topLabel: 'Symbol',
                  bottomLabel: 'Quantity',
                ),
              ),
              const SizedBox(width: 20),
              const SizedBox(
                width: 80,
                child: _AccountsTableHeaderTitle(
                  topLabel: 'Unrealized P/L',
                  bottomLabel: 'Return (%)',
                  alignEnd: true,
                ),
              ),
              const SizedBox(width: 20),
              const SizedBox(
                width: 80,
                child: _AccountsTableHeaderTitle(
                  topLabel: 'Market Value',
                  bottomLabel: 'Cost Basis',
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 372,
          child: Column(
            children: [
              for (var index = 0;
                  index < snapshot.visibleHoldings.length;
                  index++)
                _AccountsHoldingRow(
                  rowKey: ValueKey('accounts-holding-row-$index'),
                  item: snapshot.visibleHoldings[index],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountsMarketScopeSegmentedControl extends StatelessWidget {
  const _AccountsMarketScopeSegmentedControl({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 121,
      height: 36,
      child: Container(
        key: const ValueKey('accounts-market-scope-segment'),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            SizedBox(
              width: 49,
              child: _AccountsMarketScopeOption(
                optionKey: const ValueKey('accounts-market-scope-local'),
                label: 'Local',
                isSelected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
            ),
            const SizedBox(width: 2),
            SizedBox(
              width: 60,
              child: _AccountsMarketScopeOption(
                optionKey: const ValueKey('accounts-market-scope-foreign'),
                label: 'Foreign',
                isSelected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountsMarketScopeOption extends StatelessWidget {
  const _AccountsMarketScopeOption({
    required this.optionKey,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final Key optionKey;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: isSelected ? AppColors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      boxShadow: isSelected
          ? const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.03),
                blurRadius: 2,
                offset: Offset(0, 4),
              ),
            ]
          : null,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: optionKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        splashFactory: NoSplash.splashFactory,
        child: Ink(
          decoration: decoration,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.28,
                      color: isSelected ? AppColors.gray700 : AppColors.gray600,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountsTableHeaderTitle extends StatelessWidget {
  const _AccountsTableHeaderTitle({
    required this.topLabel,
    required this.bottomLabel,
    this.alignEnd = false,
  });

  final String topLabel;
  final String bottomLabel;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            topLabel,
            maxLines: 1,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.24,
                  color: AppColors.gray600,
                ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            bottomLabel,
            maxLines: 1,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.24,
                  color: AppColors.gray600,
                ),
          ),
        ),
      ],
    );
  }
}

class _AccountsHoldingRow extends StatelessWidget {
  const _AccountsHoldingRow({
    required this.rowKey,
    required this.item,
  });

  final Key rowKey;
  final _AccountsHoldingSnapshot item;

  @override
  Widget build(BuildContext context) {
    final pnlColor =
        item.unrealizedPnlValue >= 0 ? AppColors.green500 : AppColors.red500;

    return SizedBox(
      key: rowKey,
      height: 62,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.stockName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray750,
                        ),
                  ),
                  Text(
                    '${item.quantity} Shares',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.28,
                          color: AppColors.gray600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.unrealizedPnlAmountDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: pnlColor,
                        ),
                  ),
                  Text(
                    item.unrealizedPnlRateDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.28,
                          color: pnlColor,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.marketValueDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray900,
                        ),
                  ),
                  Text(
                    item.costBasisDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.28,
                          color: AppColors.gray900,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountsScreenSnapshot {
  const _AccountsScreenSnapshot({
    required this.accountLabel,
    required this.totalAssetsDisplay,
    required this.totalPnlDisplay,
    required this.totalPnlValue,
    required this.totalPositions,
    required this.visibleHoldings,
  });

  final String accountLabel;
  final String totalAssetsDisplay;
  final String totalPnlDisplay;
  final double totalPnlValue;
  final int totalPositions;
  final List<_AccountsHoldingSnapshot> visibleHoldings;

  factory _AccountsScreenSnapshot.fromControllers({
    required MockUsdAccount? account,
    required PortfolioSnapshot? portfolio,
  }) {
    final hasPortfolio = portfolio != null;
    final baseHoldings = hasPortfolio && portfolio.holdings.isNotEmpty
        ? portfolio.holdings
            .map(_AccountsHoldingSnapshot.fromHolding)
            .toList(growable: false)
        : _fallbackHoldings;

    final visibleHoldings = [
      ...baseHoldings,
      ..._fallbackHoldings,
    ].take(6).toList(growable: false);

    final accountLabel = portfolio != null && portfolio.accountId.isNotEmpty
        ? '${portfolio.accountId} [ISA(Brokerage)]'
        : account != null && account.accountId.isNotEmpty
            ? '${account.accountId} [ISA(Brokerage)]'
            : '640-0200-0000-0 [ISA(Brokerage)]';

    final totalAssetsValue = _safeDouble(
      portfolio?.totalAssetValueUsd,
      fallback: 50000,
    );
    final totalPnlValue = _safeDouble(
      portfolio?.unrealizedPnlUsd,
      fallback: -10000,
    );
    final totalPnlRate = hasPortfolio && portfolio.holdings.isNotEmpty
        ? _portfolioReturnRate(portfolio!)
        : '-14.48%';

    return _AccountsScreenSnapshot(
      accountLabel: accountLabel,
      totalAssetsDisplay: hasPortfolio
          ? '\$${_formatThreeDecimalAmount(totalAssetsValue)}'
          : '\$5,0000.000',
      totalPnlDisplay: hasPortfolio
          ? '${_formatSignedThreeDecimalAmount(totalPnlValue)}($totalPnlRate)'
          : '-10,000,000(-14.48%)',
      totalPnlValue: totalPnlValue,
      totalPositions: portfolio?.holdings.length ?? 60,
      visibleHoldings: visibleHoldings,
    );
  }

  static final List<_AccountsHoldingSnapshot> _fallbackHoldings = List.generate(
    6,
    (index) {
      final isPositive = index == 0 || index >= 4;
      return _AccountsHoldingSnapshot(
        stockName: 'Samsung Electronics',
        quantity: 100,
        unrealizedPnlValue: isPositive ? 1 : -1,
        unrealizedPnlAmountDisplay: '00000000',
        unrealizedPnlRateDisplay: isPositive ? '205.19' : '-205.19',
        marketValueDisplay: '555.000',
        costBasisDisplay: '222.000',
      );
    },
  );
}

class _AccountsHoldingSnapshot {
  const _AccountsHoldingSnapshot({
    required this.stockName,
    required this.quantity,
    required this.unrealizedPnlValue,
    required this.unrealizedPnlAmountDisplay,
    required this.unrealizedPnlRateDisplay,
    required this.marketValueDisplay,
    required this.costBasisDisplay,
  });

  final String stockName;
  final int quantity;
  final double unrealizedPnlValue;
  final String unrealizedPnlAmountDisplay;
  final String unrealizedPnlRateDisplay;
  final String marketValueDisplay;
  final String costBasisDisplay;

  factory _AccountsHoldingSnapshot.fromHolding(MockHolding holding) {
    final marketValue = _safeDouble(holding.marketValueUsd, fallback: 0);
    final averagePrice = _safeDouble(holding.averagePriceUsd, fallback: 0);
    final unrealizedPnl = _safeDouble(holding.unrealizedPnlUsd, fallback: 0);
    final costBasis = averagePrice * holding.quantity;

    return _AccountsHoldingSnapshot(
      stockName: holding.stockName,
      quantity: holding.quantity,
      unrealizedPnlValue: unrealizedPnl,
      unrealizedPnlAmountDisplay:
          _formatSignedThreeDecimalAmount(unrealizedPnl),
      unrealizedPnlRateDisplay: _formatRateText(holding.unrealizedPnlRate),
      marketValueDisplay: _formatThreeDecimalAmount(marketValue),
      costBasisDisplay: _formatThreeDecimalAmount(costBasis),
    );
  }
}

double _safeDouble(String? raw, {required double fallback}) {
  if (raw == null) {
    return fallback;
  }
  final normalized = raw.replaceAll(',', '').replaceAll('\$', '').trim();
  return double.tryParse(normalized) ?? fallback;
}

String _formatRateText(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '0.00%';
  }
  return trimmed.contains('%') ? trimmed : '$trimmed%';
}

String _portfolioReturnRate(PortfolioSnapshot portfolio) {
  final costBasis = portfolio.holdings.fold<double>(
    0,
    (sum, holding) =>
        sum +
        (_safeDouble(holding.averagePriceUsd, fallback: 0) * holding.quantity),
  );
  if (costBasis == 0) {
    return '0.00%';
  }
  final unrealizedPnl = _safeDouble(portfolio.unrealizedPnlUsd, fallback: 0);
  final rate = (unrealizedPnl / costBasis) * 100;
  final sign = rate > 0 ? '+' : '';
  return '$sign${rate.toStringAsFixed(2)}%';
}

String _formatSignedThreeDecimalAmount(double value) {
  final sign = value < 0 ? '-' : '';
  return '$sign${_formatThreeDecimalAmount(value.abs())}';
}

String _formatThreeDecimalAmount(double value) {
  final fixed = value.toStringAsFixed(3);
  final parts = fixed.split('.');
  final whole = parts.first;
  final fraction = parts.last;
  final buffer = StringBuffer();

  for (var index = 0; index < whole.length; index++) {
    if (index > 0 && (whole.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(whole[index]);
  }

  return '${buffer.toString()}.$fraction';
}
