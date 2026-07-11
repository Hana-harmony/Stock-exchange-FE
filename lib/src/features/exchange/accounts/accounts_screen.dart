part of '../exchange_pages.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({
    super.key,
    required this.sessionController,
    required this.accountController,
    required this.tradeController,
    required this.taxController,
    required this.onSignInTap,
  });

  final ExchangeSessionController sessionController;
  final AccountController accountController;
  final TradeController tradeController;
  final TaxController taxController;
  final VoidCallback onSignInTap;

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
    if (widget.taxController.value.refundCase?.accountId != accountId) {
      widget.taxController.loadRefundStatus(accountId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.sessionController,
        widget.accountController,
        widget.tradeController,
        widget.taxController,
      ]),
      builder: (context, _) {
        final session = widget.sessionController.session;
        if (session == null) {
          return _AccountsSignedOutState(onSignInTap: widget.onSignInTap);
        }

        final accountState = widget.accountController.value;
        final tradeState = widget.tradeController.value;
        final isAccountFailure = accountState.status == AccountStatus.failure &&
            accountState.account == null;
        final isPortfolioFailure = tradeState.status == TradeStatus.failure &&
            tradeState.portfolio == null;
        if (isAccountFailure || isPortfolioFailure) {
          return SafeArea(
            key: const ValueKey('accounts-load-error-state'),
            bottom: false,
            child: ListView(
              padding: AppInsets.compactScreen,
              children: [
                _ErrorStateCard(
                  title: 'Account unavailable',
                  message: accountState.errorMessage ??
                      tradeState.errorMessage ??
                      'Unable to load your account.',
                ),
              ],
            ),
          );
        }

        final isLoadingAccount = accountState.status == AccountStatus.loading ||
            accountState.account == null;
        final isLoadingPortfolio = tradeState.status == TradeStatus.loading ||
            tradeState.portfolio == null;
        if (isLoadingAccount || isLoadingPortfolio) {
          return const ColoredBox(
            key: ValueKey('accounts-loading-state'),
            color: AppColors.white,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.orange500),
              ),
            ),
          );
        }

        final snapshot = _AccountsScreenSnapshot.fromControllers(
          account: accountState.account,
          portfolio: tradeState.portfolio,
        );

        return ColoredBox(
          key: const ValueKey('accounts-screen'),
          color: AppColors.white,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _AccountsHeaderSection(
                  snapshot: snapshot,
                  selectedPrimaryTab: _selectedPrimaryTab,
                  onDeposit: () => _showDepositFlow(session.accountId),
                  onPrimaryTabSelected: (index) {
                    setState(() {
                      _selectedPrimaryTab = index;
                    });
                  },
                ),
                SizedBox(
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
                const SizedBox(height: 16),
                Expanded(
                  child: _AccountsHoldingsSection(
                    snapshot: snapshot,
                    showAllocationChart: _selectedPrimaryTab == 1,
                    selectedMarketScope: _selectedMarketScope,
                    onMarketScopeSelected: (index) {
                      setState(() {
                        _selectedMarketScope = index;
                      });
                    },
                  ),
                ),
                _TaxRefundEntryCard(
                  taxState: widget.taxController.value,
                  onTap: () => _openTaxRefundRequest(session.accountId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTaxRefundRequest(String accountId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TaxRefundRequestScreen(
          accountId: accountId,
          taxController: widget.taxController,
        ),
      ),
    );
  }

  Future<void> _showDepositFlow(String accountId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.white,
      builder: (context) => _DepositUsdSheet(
        accountId: accountId,
        accountController: widget.accountController,
      ),
    );
    if (widget.accountController.value.status == AccountStatus.loaded) {
      await widget.tradeController.loadPortfolio(accountId);
    }
  }
}

class _DepositUsdSheet extends StatefulWidget {
  const _DepositUsdSheet({
    required this.accountId,
    required this.accountController,
  });

  final String accountId;
  final AccountController accountController;

  @override
  State<_DepositUsdSheet> createState() => _DepositUsdSheetState();
}

class _DepositUsdSheetState extends State<_DepositUsdSheet> {
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  var _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  double? get _amount =>
      double.tryParse(_amountController.text.replaceAll(',', '').trim());

  Future<void> _continueToAccountPin() async {
    final amount = _amount;
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Enter an amount greater than USD 0.');
      return;
    }
    setState(() {
      _errorMessage = null;
      _submitting = true;
    });
    final pin = await _presentAccountPinBottomSheet(context);
    if (!mounted || pin == null) {
      if (mounted) {
        setState(() => _submitting = false);
      }
      return;
    }
    await _submit(amount, pin);
  }

  Future<void> _submit(double amount, String pin) async {
    await widget.accountController.depositUsd(
      accountId: widget.accountId,
      amount: amount,
      pin: pin,
    );
    if (!mounted) {
      return;
    }
    final state = widget.accountController.value;
    if (state.status == AccountStatus.loaded) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = false;
      _errorMessage = state.errorMessage ?? 'Unable to add USD.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add USD balance',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray1000,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the USD amount to add to your simulated trading balance.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray600,
                  ),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const ValueKey('deposit-amount-field'),
              controller: _amountController,
              focusNode: _amountFocusNode,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _continueToAccountPin(),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'USD ',
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                key: const ValueKey('deposit-error-message'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.red500,
                    ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                key: const ValueKey('deposit-continue-button'),
                onPressed: _submitting ? null : _continueToAccountPin,
                style: _exchangePrimaryButtonStyle(
                  backgroundColor: AppColors.orange500,
                  radius: 8,
                ),
                child: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaxRefundEntryCard extends StatelessWidget {
  const _TaxRefundEntryCard({
    required this.taxState,
    required this.onTap,
  });

  final TaxState taxState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final submitted = taxState.refundCase?.status == 'READY_FOR_HANA_SYNC' ||
        taxState.refundCase?.status == 'SYNCED_WITH_HANA' ||
        taxState.refundCase?.status == 'ADVANCE_PAID';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Material(
        key: const ValueKey('tax-refund-entry-card'),
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.green100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    size: 21,
                    color: AppColors.green500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reduced Withholding Tax Rate Available',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 15,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray900,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        submitted
                            ? 'Documents submitted for Hana review.'
                            : 'OCR verify and submit tax documents.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              height: 1.35,
                              color: AppColors.gray600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: AppColors.gray600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountsHeaderSection extends StatelessWidget {
  const _AccountsHeaderSection({
    required this.snapshot,
    required this.selectedPrimaryTab,
    required this.onDeposit,
    required this.onPrimaryTabSelected,
  });

  final _AccountsScreenSnapshot snapshot;
  final int selectedPrimaryTab;
  final VoidCallback onDeposit;
  final ValueChanged<int> onPrimaryTabSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AccountsPrimaryTabs(
          selectedIndex: selectedPrimaryTab,
          onSelected: onPrimaryTabSelected,
        ),
        _AccountsAccountSelector(accountLabel: snapshot.accountLabel),
        _AccountsSummaryCard(snapshot: snapshot, onDeposit: onDeposit),
      ],
    );
  }
}

class _AccountsSignedOutState extends StatelessWidget {
  const _AccountsSignedOutState({required this.onSignInTap});

  final VoidCallback onSignInTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const ValueKey('accounts-signed-out-state'),
      bottom: false,
      child: ListView(
        padding: AppInsets.compactScreen,
        children: [
          const _MutedInfoCard(
            title: 'Sign in required',
            body: 'Sign in to view your cash, assets, and portfolio.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              key: const ValueKey('accounts-sign-in-button'),
              onPressed: onSignInTap,
              style: _exchangePrimaryButtonStyle(
                backgroundColor: AppColors.orange500,
                radius: 8,
              ),
              child: const Text('Sign in'),
            ),
          ),
        ],
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
  ];

  static const _widths = <double>[56, 72];

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
    required this.onDeposit,
  });

  final _AccountsScreenSnapshot snapshot;
  final VoidCallback onDeposit;

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
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      snapshot.totalAssetsDisplay,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 31 / 22,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: FilledButton.icon(
                      key: const ValueKey('accounts-deposit-button'),
                      onPressed: onDeposit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange500,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add USD'),
                    ),
                  ),
                ],
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
    required this.showAllocationChart,
    required this.selectedMarketScope,
    required this.onMarketScopeSelected,
  });

  final _AccountsScreenSnapshot snapshot;
  final bool showAllocationChart;
  final int selectedMarketScope;
  final ValueChanged<int> onMarketScopeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('accounts-holdings-section'),
      children: [
        if (showAllocationChart)
          _PortfolioAllocationChart(holdings: snapshot.visibleHoldings),
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
        Expanded(
          child: snapshot.visibleHoldings.isEmpty
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _MutedInfoCard(
                    title: 'No holdings yet',
                    body:
                        'Your portfolio will appear here after trades settle.',
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: snapshot.visibleHoldings.length,
                  itemBuilder: (context, index) {
                    return _AccountsHoldingRow(
                      rowKey: ValueKey('accounts-holding-row-$index'),
                      item: snapshot.visibleHoldings[index],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PortfolioAllocationChart extends StatelessWidget {
  const _PortfolioAllocationChart({required this.holdings});

  final List<_AccountsHoldingSnapshot> holdings;

  @override
  Widget build(BuildContext context) {
    final total = holdings.fold<double>(
      0,
      (sum, item) => sum + item.marketValue,
    );
    final chartItems = holdings
        .where((item) => item.marketValue > 0 && total > 0)
        .take(5)
        .toList(growable: false);

    return SizedBox(
      key: const ValueKey('portfolio-allocation-chart'),
      height: 96,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio Allocation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    if (chartItems.isEmpty)
                      const Expanded(
                        child: ColoredBox(color: AppColors.gray200),
                      )
                    else
                      for (var index = 0; index < chartItems.length; index++)
                        Expanded(
                          flex: _allocationFlex(chartItems[index], total),
                          child: ColoredBox(
                            color: _allocationColor(index),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (var index = 0; index < chartItems.length; index++) ...[
                      _AllocationLegendItem(
                        color: _allocationColor(index),
                        label: chartItems[index].stockName,
                        percent: total == 0
                            ? '0.0%'
                            : '${(chartItems[index].marketValue / total * 100).toStringAsFixed(1)}%',
                      ),
                      if (index != chartItems.length - 1)
                        const SizedBox(width: 12),
                    ],
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

class _AllocationLegendItem extends StatelessWidget {
  const _AllocationLegendItem({
    required this.color,
    required this.label,
    required this.percent,
  });

  final Color color;
  final String label;
  final String percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: 8),
        ),
        const SizedBox(width: 6),
        Text(
          '$label $percent',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 12,
                color: AppColors.gray600,
              ),
        ),
      ],
    );
  }
}

int _allocationFlex(_AccountsHoldingSnapshot item, double total) {
  if (total <= 0) {
    return 1;
  }
  return math.max(1, (item.marketValue / total * 1000).round());
}

Color _allocationColor(int index) {
  const colors = [
    AppColors.orange500,
    AppColors.green500,
    Color(0xFF2E6BFF),
    Color(0xFF7A4DFF),
    AppColors.gray750,
  ];
  return colors[index % colors.length];
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
    final visibleHoldings = portfolio == null
        ? const <_AccountsHoldingSnapshot>[]
        : portfolio.holdings
            .map(_AccountsHoldingSnapshot.fromHolding)
            .toList(growable: false);

    final accountLabel = portfolio != null && portfolio.accountId.isNotEmpty
        ? '${portfolio.accountId} [ISA(Brokerage)]'
        : account != null && account.accountId.isNotEmpty
            ? '${account.accountId} [ISA(Brokerage)]'
            : 'Account loading';

    final cashBalance = _safeDouble(account?.cashBalanceUsd, fallback: 0);
    final holdingsValue = _safeDouble(
      portfolio?.totalMarketValueUsd,
      fallback: 0,
    );
    final totalAssetsValue = cashBalance + holdingsValue;
    final totalPnlValue = _safeDouble(
      portfolio?.unrealizedPnlUsd,
      fallback: 0,
    );
    final totalPnlRate = portfolio == null || portfolio.holdings.isEmpty
        ? '0.00%'
        : _portfolioReturnRate(portfolio);

    return _AccountsScreenSnapshot(
      accountLabel: accountLabel,
      totalAssetsDisplay: formatCurrencyDisplay(
        portfolio?.currency ?? account?.currency ?? 'USD',
        totalAssetsValue.toStringAsFixed(2),
      ),
      totalPnlDisplay:
          '${formatCurrencyDisplay('USD', totalPnlValue.toStringAsFixed(2))} ($totalPnlRate)',
      totalPnlValue: totalPnlValue,
      totalPositions: visibleHoldings.length,
      visibleHoldings: visibleHoldings,
    );
  }
}

class _AccountsHoldingSnapshot {
  const _AccountsHoldingSnapshot({
    required this.stockName,
    required this.quantity,
    required this.marketValue,
    required this.unrealizedPnlValue,
    required this.unrealizedPnlAmountDisplay,
    required this.unrealizedPnlRateDisplay,
    required this.marketValueDisplay,
    required this.costBasisDisplay,
  });

  final String stockName;
  final int quantity;
  final double marketValue;
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
      marketValue: marketValue,
      unrealizedPnlValue: unrealizedPnl,
      unrealizedPnlAmountDisplay:
          formatCurrencyDisplay('USD', unrealizedPnl.toStringAsFixed(2)),
      unrealizedPnlRateDisplay: _formatRateText(holding.unrealizedPnlRate),
      marketValueDisplay:
          formatCurrencyDisplay('USD', marketValue.toStringAsFixed(2)),
      costBasisDisplay:
          formatCurrencyDisplay('USD', costBasis.toStringAsFixed(2)),
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
