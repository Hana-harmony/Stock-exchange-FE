part of '../exchange_pages.dart';

class _StockOrderEntryScreen extends StatefulWidget {
  const _StockOrderEntryScreen({
    required this.sessionController,
    required this.marketDetailController,
    required this.marketQuoteController,
    required this.tradeController,
    required this.notificationController,
    required this.stockCode,
    required this.snapshot,
    required this.initialIsFavorite,
    this.onFavoriteToggle,
    this.onViewAccounts,
  });

  final ExchangeSessionController sessionController;
  final MarketDetailController marketDetailController;
  final MarketQuoteController marketQuoteController;
  final TradeController tradeController;
  final NotificationController notificationController;
  final String stockCode;
  final _StockDetailSnapshot snapshot;
  final bool initialIsFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onViewAccounts;

  @override
  State<_StockOrderEntryScreen> createState() => _StockOrderEntryScreenState();
}

class _StockOrderEntryScreenState extends State<_StockOrderEntryScreen> {
  late bool _isFavorite;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late int _quantity;
  late int _price;
  bool _isSyncingQuantity = false;
  bool _isSyncingPrice = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialIsFavorite;
    _quantity = 3;
    _price = _parseEditableInt(widget.snapshot.currentPrice) ?? 0;
    _quantityController = TextEditingController(text: '3')
      ..addListener(_handleQuantityChanged);
    _priceController = TextEditingController(text: '$_price')
      ..addListener(_handlePriceChanged);
  }

  @override
  void dispose() {
    _quantityController
      ..removeListener(_handleQuantityChanged)
      ..dispose();
    _priceController
      ..removeListener(_handlePriceChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bodySafeAreaBottom: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          key: const ValueKey('stock-order-entry-screen'),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.gray100),
              ),
              child: Column(
                children: [
                  _StockDetailHeader(
                    snapshot: widget.snapshot,
                    showCompactTitle: true,
                    showCompactChange: false,
                    showBottomBorder: false,
                    compactTitleFontSize: 22,
                    compactTitleLineHeight: 1.4,
                    leadingTitleSpacing: 4,
                    isFavorite: _isFavorite,
                    onBack: () => Navigator.of(context).pop(),
                    onSearch: _openSearch,
                    onFavorite: _toggleFavorite,
                  ),
                  _StockOrderTopSection(snapshot: widget.snapshot),
                  const _StockOrderEntryTabs(),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 152,
                    child: _StockOrderQuoteList(
                      snapshot: widget.snapshot,
                      orderBook: widget.marketDetailController.value.orderBook,
                      onPriceTap: _applyPriceFromQuote,
                    ),
                  ),
                  Expanded(
                    child: _StockOrderFormPanel(
                      quantityController: _quantityController,
                      priceController: _priceController,
                      orderAmount: _quantity * _price,
                      onDecreaseQuantity: _decreaseQuantity,
                      onIncreaseQuantity: _increaseQuantity,
                      onDecreasePrice: _decreasePrice,
                      onIncreasePrice: _increasePrice,
                      onSubmit: _showAccountPinBottomSheet,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _StockHomeBar(),
    );
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    widget.onFavoriteToggle?.call();
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SearchLandingScreen(
          sessionController: widget.sessionController,
          tradeController: widget.tradeController,
          marketDetailController: widget.marketDetailController,
          marketQuoteController: widget.marketQuoteController,
          notificationController: widget.notificationController,
          recentSearches: const [],
          favoriteStockCodes:
              _isFavorite ? {widget.stockCode} : const <String>{},
          onSearchCommitted: (_) {},
          onRemoveRecentSearch: (_) {},
          onClearRecentSearches: () {},
          onToggleFavoriteStock: (_) {},
          onNavigateToAccounts: widget.onViewAccounts ?? () {},
        ),
      ),
    );
  }

  void _handleQuantityChanged() {
    if (_isSyncingQuantity) {
      return;
    }

    final nextValue = _parseEditableInt(_quantityController.text) ?? 0;
    if (nextValue == _quantity) {
      return;
    }
    setState(() {
      _quantity = nextValue;
    });
  }

  void _handlePriceChanged() {
    if (_isSyncingPrice) {
      return;
    }

    final nextValue = _parseEditableInt(_priceController.text) ?? 0;
    if (nextValue == _price) {
      return;
    }
    setState(() {
      _price = nextValue;
    });
  }

  void _decreaseQuantity() {
    final next = _quantity <= 1 ? 0 : _quantity - 1;
    _setQuantity(next);
  }

  void _increaseQuantity() {
    _setQuantity(_quantity + 1);
  }

  void _decreasePrice() {
    final step = _krxTickSize(_price > 0
        ? _price
        : _parseEditableInt(widget.snapshot.currentPrice) ?? 0);
    final next = _price <= step ? 0 : _price - step;
    _setPrice(next);
  }

  void _increasePrice() {
    final baseline = _price > 0
        ? _price
        : _parseEditableInt(widget.snapshot.currentPrice) ?? 0;
    _setPrice(_price + _krxTickSize(baseline));
  }

  void _applyPriceFromQuote(String price) {
    final next = _parseEditableInt(price);
    if (next == null) {
      return;
    }
    _setPrice(next);
  }

  void _setQuantity(int value) {
    final sanitized = value < 0 ? 0 : value;
    _isSyncingQuantity = true;
    _quantityController.value = TextEditingValue(
      text: sanitized == 0 ? '' : '$sanitized',
      selection: TextSelection.collapsed(
        offset: sanitized == 0 ? 0 : '$sanitized'.length,
      ),
    );
    _isSyncingQuantity = false;
    setState(() {
      _quantity = sanitized;
    });
  }

  void _setPrice(int value) {
    final sanitized = value < 0 ? 0 : value;
    _isSyncingPrice = true;
    _priceController.value = TextEditingValue(
      text: sanitized == 0 ? '' : '$sanitized',
      selection: TextSelection.collapsed(
        offset: sanitized == 0 ? 0 : '$sanitized'.length,
      ),
    );
    _isSyncingPrice = false;
    setState(() {
      _price = sanitized;
    });
  }

  Future<void> _showAccountPinBottomSheet() async {
    final isPinConfirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Account PIN',
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.5),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const _AccountPinBottomSheetDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: child,
        );
      },
    );

    if (isPinConfirmed != true || !mounted) {
      return;
    }

    final isOrderConfirmed = await _showOrderConfirmationDialog(
      confirmation: _OrderConfirmationDetails(
        stockName: widget.snapshot.stockName,
        orderPrice: _formatDialogOrderAmount(_price),
        quantity: _formatOrderQuantity(_quantity),
        totalAmount: _formatDialogOrderAmount(_quantity * _price),
      ),
    );

    if (isOrderConfirmed != true || !mounted) {
      return;
    }

    await _showOrderCompletedDialog();
  }

  Future<bool?> _showOrderConfirmationDialog({
    required _OrderConfirmationDetails confirmation,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Confirm buy order',
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.5),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _OrderConfirmationDialog(confirmation: confirmation);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  Future<void> _showOrderCompletedDialog() {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Order completed',
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.5),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _OrderCompletedDialog(
          onViewAccounts: () {
            Navigator.of(context).pop();
            widget.onViewAccounts?.call();
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}

class _StockOrderTopSection extends StatelessWidget {
  const _StockOrderTopSection({
    required this.snapshot,
  });

  final _StockDetailSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final priceColor =
        snapshot.isPositive ? AppColors.green500 : AppColors.red500;

    return SizedBox(
      key: const ValueKey('stock-order-top-section'),
      height: 158,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            SizedBox(
              height: 74,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 49,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  snapshot.currentPrice,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                        color: priceColor,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Padding(
                                padding: const EdgeInsets.only(top: 7),
                                child: Image.asset(
                                  snapshot.isPositive
                                      ? AppAssets.arrowUpBig
                                      : AppAssets.arrowDownBig,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: snapshot.changeAmount,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                      color: priceColor,
                                    ),
                              ),
                              TextSpan(
                                text: ' ${snapshot.changeRate}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                      color: priceColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: SizedBox(
                      width: 118,
                      child: Column(
                        children: [
                          _StockStatRow(
                              label: 'High', value: snapshot.highPrice),
                          _StockStatRow(label: 'Low', value: snapshot.lowPrice),
                          _StockStatRow(label: 'Vol', value: snapshot.volume),
                          _StockStatRow(
                            label: 'Prev',
                            value: snapshot.previousClose,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              key: const ValueKey('stock-order-account-info'),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          snapshot.orderAccountDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    color: AppColors.gray1000,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const _OrderChevronDownIcon(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockOrderEntryTabs extends StatelessWidget {
  const _StockOrderEntryTabs();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('stock-order-entry-tabs'),
      height: 41,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, top: 10),
          child: Row(
            children: const [
              _StockOrderTopTab(
                label: 'Buy',
                width: 32,
                isSelected: true,
              ),
              SizedBox(width: 18),
              _StockOrderTopTab(
                label: 'Sell',
                width: 30,
              ),
              SizedBox(width: 18),
              _StockOrderTopTab(
                label: 'Modify/Cancel',
                width: 119,
              ),
              SizedBox(width: 18),
              _StockOrderTopTab(
                label: 'Filled/Pending',
                width: 117,
              ),
              SizedBox(width: 18),
              _StockOrderTopTab(
                label: 'Scheduled Orders',
                width: 148,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockOrderTopTab extends StatelessWidget {
  const _StockOrderTopTab({
    required this.label,
    required this.width,
    this.isSelected = false,
  });

  final String label;
  final double width;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AppUnderlineTab(
      label: label,
      width: width,
      isSelected: isSelected,
      onTap: () {},
      fontSize: 18,
      lineHeight: 1.4,
      fontWeightSelected: FontWeight.w600,
      fontWeightUnselected: FontWeight.w500,
      activeColor: AppColors.gray1000,
      inactiveColor: AppColors.gray600,
    );
  }
}

class _StockOrderQuoteList extends StatelessWidget {
  const _StockOrderQuoteList({
    required this.snapshot,
    required this.orderBook,
    required this.onPriceTap,
  });

  static const _fallbackQuotes = [
    _OrderQuoteData(
      price: '223,000',
      changeRate: '+5.11%',
      quantity: '13,678',
      isPositive: true,
      isGrayBackground: true,
    ),
    _OrderQuoteData(
      price: '223,000',
      changeRate: '+5.11%',
      quantity: '13,678',
      isPositive: true,
    ),
    _OrderQuoteData(
      price: '223,000',
      changeRate: '+5.11%',
      quantity: '13,678',
      isPositive: true,
      isGrayBackground: true,
    ),
    _OrderQuoteData(
      price: '223,000',
      changeRate: '+5.11%',
      quantity: '13,678',
      isPositive: true,
    ),
    _OrderQuoteData(
      price: '223,000',
      changeRate: '-5.11%',
      quantity: '13,678',
      isPositive: false,
      isGrayBackground: true,
    ),
    _OrderQuoteData(
      price: '223,000',
      changeRate: '-5.11%',
      quantity: '13,678',
      isPositive: false,
      isGrayBackground: true,
    ),
    _OrderQuoteData(
      price: '223,000',
      changeRate: '-5.11%',
      quantity: '13,678',
      isPositive: false,
    ),
    _OrderQuoteData(
      price: '223,000',
      changeRate: '-5.11%',
      quantity: '13,678',
      isPositive: false,
      isGrayBackground: true,
    ),
    _OrderQuoteData(
      price: '223,000',
      changeRate: '-5.11%',
      quantity: '13,678',
      isPositive: false,
    ),
    _OrderQuoteData(
      price: '223,000',
      changeRate: '-5.11%',
      quantity: '13,678',
      isPositive: false,
      isGrayBackground: true,
    ),
    _OrderQuoteData(
      price: '223,000',
      changeRate: '-5.11%',
      quantity: '13,678',
      isPositive: false,
    ),
    _OrderQuoteData(
      price: '223,000',
      changeRate: '-5.11%',
      quantity: '13,678',
      isPositive: false,
      isGrayBackground: true,
    ),
  ];

  final _StockDetailSnapshot snapshot;
  final MarketOrderBook? orderBook;
  final ValueChanged<String> onPriceTap;

  @override
  Widget build(BuildContext context) {
    final quotes = _buildQuotes();

    return DecoratedBox(
      key: const ValueKey('stock-order-quote-list-shell'),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.gray100),
        ),
      ),
      child: ListView.builder(
        key: const PageStorageKey<String>('stock-order-quote-list'),
        padding: EdgeInsets.zero,
        itemCount: quotes.length,
        itemBuilder: (context, index) {
          final quote = quotes[index];
          return _StockOrderQuoteRow(
            data: quote,
            onTap: () => onPriceTap(quote.price),
          );
        },
      ),
    );
  }

  List<_OrderQuoteData> _buildQuotes() {
    final levels = [
      ...(orderBook?.asks ?? const <OrderBookLevel>[]),
      ...(orderBook?.bids ?? const <OrderBookLevel>[]),
    ];
    if (levels.isEmpty) {
      return _fallbackQuotes;
    }

    final referencePrice = _parseAmount(snapshot.previousClose) ??
        _parseAmount(snapshot.currentPrice);

    return List<_OrderQuoteData>.generate(levels.length, (index) {
      final level = levels[index];
      final price = _formatWholeAmount(level.priceKrw);
      final quantity = _formatWholeAmount(level.quantity.toString());
      final numericPrice = _parseAmount(level.priceKrw);
      final isPositive = referencePrice == null || numericPrice == null
          ? index < (orderBook?.asks.length ?? 0)
          : numericPrice >= referencePrice;

      return _OrderQuoteData(
        price: price,
        changeRate: _formatSignedPercent(
          current: numericPrice,
          reference: referencePrice,
          fallbackPositive: isPositive,
        ),
        quantity: quantity,
        isPositive: isPositive,
        isGrayBackground: index.isEven,
      );
    });
  }
}

class _StockOrderQuoteRow extends StatelessWidget {
  const _StockOrderQuoteRow({
    required this.data,
    required this.onTap,
  });

  final _OrderQuoteData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priceColor = data.isPositive ? AppColors.green500 : AppColors.red500;

    return Material(
      color: data.isGrayBackground ? AppColors.gray50 : AppColors.white,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        data.price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                  letterSpacing: -0.28,
                                  color: priceColor,
                                ),
                      ),
                      Text(
                        data.changeRate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                              letterSpacing: -0.28,
                              color: priceColor,
                            ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 60,
                  child: Text(
                    data.quantity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                          letterSpacing: -0.28,
                          color: AppColors.gray800,
                        ),
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

class _StockOrderFormPanel extends StatelessWidget {
  const _StockOrderFormPanel({
    required this.quantityController,
    required this.priceController,
    required this.orderAmount,
    required this.onDecreaseQuantity,
    required this.onIncreaseQuantity,
    required this.onDecreasePrice,
    required this.onIncreasePrice,
    required this.onSubmit,
  });

  final TextEditingController quantityController;
  final TextEditingController priceController;
  final int orderAmount;
  final VoidCallback onDecreaseQuantity;
  final VoidCallback onIncreaseQuantity;
  final VoidCallback onDecreasePrice;
  final VoidCallback onIncreasePrice;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('stock-order-form-panel'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OrderSettlementTabs(),
          const SizedBox(height: 20),
          const _OrderSelectField(label: 'Limit Order'),
          const SizedBox(height: 20),
          const _OrderCheckboxRow(),
          const SizedBox(height: 20),
          _OrderStepperField(
            label: 'Quantity',
            controller: quantityController,
            fieldKey: const ValueKey('stock-order-quantity-input'),
            onDecrease: onDecreaseQuantity,
            onIncrease: onIncreaseQuantity,
          ),
          const SizedBox(height: 20),
          _OrderStepperField(
            label: 'Price',
            controller: priceController,
            fieldKey: const ValueKey('stock-order-price-input'),
            onDecrease: onDecreasePrice,
            onIncrease: onIncreasePrice,
          ),
          const Spacer(),
          _OrderSubmitSection(
            orderAmount: orderAmount,
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _OrderSettlementTabs extends StatelessWidget {
  const _OrderSettlementTabs();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('stock-order-settlement-tabs'),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.03),
                      blurRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    'Cash',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: -0.28,
                          color: AppColors.gray700,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Text(
                  'Margin',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        letterSpacing: -0.28,
                        color: AppColors.gray600,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSelectField extends StatelessWidget {
  const _OrderSelectField({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('stock-order-select-field'),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        letterSpacing: -0.28,
                        color: AppColors.gray1000,
                      ),
                ),
              ),
              const SizedBox(width: 4),
              const _OrderChevronDownIcon(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCheckboxRow extends StatelessWidget {
  const _OrderCheckboxRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('stock-order-checkbox-row'),
      children: const [
        SizedBox(
          width: 58,
          child: _OrderCheckboxLabel(label: 'Market'),
        ),
        SizedBox(width: 16),
        SizedBox(
          width: 69,
          child: _OrderCheckboxLabel(label: 'Mid Price'),
        ),
      ],
    );
  }
}

class _OrderCheckboxLabel extends StatelessWidget {
  const _OrderCheckboxLabel({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _OrderCheckbox(),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  letterSpacing: -0.24,
                  color: AppColors.gray700,
                ),
          ),
        ),
      ],
    );
  }
}

class _OrderCheckbox extends StatelessWidget {
  const _OrderCheckbox();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.gray300,
        borderRadius: BorderRadius.circular(3),
      ),
      child: const SizedBox(
        width: 16,
        height: 16,
        child: Center(
          child: SizedBox(
            width: 12.5,
            height: 8.38,
            child: CustomPaint(
              painter: _OrderCheckPainter(),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderStepperField extends StatelessWidget {
  const _OrderStepperField({
    required this.label,
    required this.controller,
    required this.fieldKey,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final TextEditingController controller;
  final Key fieldKey;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('stock-order-stepper-$label'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
                letterSpacing: -0.28,
                color: AppColors.gray1000,
              ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.gray300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: fieldKey,
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      cursorColor: AppColors.gray1000,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            letterSpacing: -0.28,
                            color: AppColors.gray1000,
                          ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        isDense: true,
                        hintText: label,
                        hintStyle:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                  letterSpacing: -0.28,
                                  color: AppColors.gray600,
                                ),
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _OrderStepControls(
                    onDecrease: onDecrease,
                    onIncrease: onIncrease,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderStepControls extends StatelessWidget {
  const _OrderStepControls({
    required this.onDecrease,
    required this.onIncrease,
  });

  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OrderStepIconButton(
          buttonKey: const ValueKey('stock-order-step-minus'),
          onTap: onDecrease,
          child: const _OrderMinusIcon(),
        ),
        const SizedBox(width: 2),
        _OrderStepIconButton(
          buttonKey: const ValueKey('stock-order-step-plus'),
          onTap: onIncrease,
          child: const _OrderPlusIcon(),
        ),
      ],
    );
  }
}

class _OrderSubmitSection extends StatelessWidget {
  const _OrderSubmitSection({
    required this.orderAmount,
    required this.onSubmit,
  });

  final int orderAmount;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('stock-order-submit-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Order Amount',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      letterSpacing: -0.28,
                      color: AppColors.gray600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatOrderAmount(orderAmount),
                key: const ValueKey('stock-order-amount'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: AppColors.gray1000,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 45,
          child: _OrderSubmitButton(
            key: const ValueKey('stock-order-submit-button'),
            onTap: onSubmit,
          ),
        ),
      ],
    );
  }
}

class _AccountPinBottomSheetDialog extends StatefulWidget {
  const _AccountPinBottomSheetDialog();

  @override
  State<_AccountPinBottomSheetDialog> createState() =>
      _AccountPinBottomSheetDialogState();
}

class _AccountPinBottomSheetDialogState
    extends State<_AccountPinBottomSheetDialog> {
  static const _maxPinLength = 6;
  String _pin = '';

  bool get _isConfirmEnabled => _pin.length == _maxPinLength;

  void _appendDigit(String digit) {
    if (_pin.length >= _maxPinLength) {
      return;
    }
    setState(() {
      _pin = '$_pin$digit';
    });
  }

  void _dismiss() {
    Navigator.of(context).pop();
  }

  void _confirm() {
    if (!_isConfirmEnabled) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          key: const ValueKey('stock-order-pin-sheet'),
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 20,
                offset: Offset(4, 0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              _AccountPinInputSection(pin: _pin),
              _AccountPinKeypad(onDigitPressed: _appendDigit),
              _AccountPinActionBar(
                onCancel: _dismiss,
                onConfirm: _confirm,
                isConfirmEnabled: _isConfirmEnabled,
              ),
              const _StockHomeBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderConfirmationDetails {
  const _OrderConfirmationDetails({
    required this.stockName,
    required this.orderPrice,
    required this.quantity,
    required this.totalAmount,
  });

  final String stockName;
  final String orderPrice;
  final String quantity;
  final String totalAmount;
}

class _OrderConfirmationDialog extends StatelessWidget {
  const _OrderConfirmationDialog({
    required this.confirmation,
  });

  static const _dialogWidth = 360.0;
  static const _dialogHeight = 362.0;
  static const _contentHeight = 164.0;

  final _OrderConfirmationDetails confirmation;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 21),
          child: Container(
            key: const ValueKey('stock-order-confirm-dialog'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 69,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Confirm Buy Order',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                    letterSpacing: 0,
                                    color: AppColors.gray1000,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _OrderConfirmationCloseButton(
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 40,
                        child: Text(
                          'Please review your order details\nbefore placing your order.',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    letterSpacing: -0.28,
                                    color: AppColors.gray600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  key: const ValueKey('stock-order-confirm-details-card'),
                  height: _contentHeight,
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _OrderConfirmationSummaryRow(
                        label: 'Stock',
                        value: confirmation.stockName,
                      ),
                      const SizedBox(height: 12),
                      _OrderConfirmationSummaryRow(
                        label: 'Order Price',
                        value: confirmation.orderPrice,
                      ),
                      const SizedBox(height: 12),
                      _OrderConfirmationSummaryRow(
                        label: 'Quantity',
                        value: confirmation.quantity,
                      ),
                      const SizedBox(height: 12),
                      _OrderConfirmationSummaryRow(
                        label: 'Total Amount',
                        value: confirmation.totalAmount,
                        valueColor: AppColors.orange500,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 45,
                  child: Row(
                    children: [
                      _OrderConfirmationActionButton(
                        buttonKey: const ValueKey('stock-order-confirm-cancel'),
                        label: 'Cancel',
                        width: 120,
                        onPressed: () => Navigator.of(context).pop(),
                        textColor: AppColors.gray700,
                        backgroundColor: AppColors.white,
                        borderColor: AppColors.gray300,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _OrderConfirmationActionButton(
                          buttonKey:
                              const ValueKey('stock-order-confirm-submit'),
                          label: 'Confirm',
                          onPressed: () => Navigator.of(context).pop(true),
                          textColor: AppColors.white,
                          backgroundColor: AppColors.orange500,
                        ),
                      ),
                    ],
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

class _OrderCompletedDialog extends StatelessWidget {
  const _OrderCompletedDialog({
    required this.onViewAccounts,
  });

  static const _dialogWidth = 360.0;
  static const _dialogHeight = 180.0;

  final VoidCallback onViewAccounts;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 21),
          child: Container(
            key: const ValueKey('stock-order-complete-dialog'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 69,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Order Completed',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                    letterSpacing: 0,
                                    color: AppColors.gray1000,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 40,
                        width: double.infinity,
                        child: Text(
                          'Your buy order has been successfully submitted.\n'
                          'You can view your order details in the Accounts tab.',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    letterSpacing: -0.28,
                                    color: AppColors.gray600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: _OrderCompletedActionButton(
                    onPressed: onViewAccounts,
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

class _OrderConfirmationSummaryRow extends StatelessWidget {
  const _OrderConfirmationSummaryRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.gray1000,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    letterSpacing: 0,
                    color: AppColors.gray1000,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: 0,
                    color: valueColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderConfirmationCloseButton extends StatelessWidget {
  const _OrderConfirmationCloseButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('stock-order-confirm-close'),
        onTap: onPressed,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          width: 24,
          height: 24,
          child: _OrderCloseIcon(),
        ),
      ),
    );
  }
}

class _OrderConfirmationActionButton extends StatelessWidget {
  const _OrderConfirmationActionButton({
    this.buttonKey,
    required this.label,
    required this.onPressed,
    required this.textColor,
    required this.backgroundColor,
    this.borderColor,
    this.width,
  });

  final Key? buttonKey;
  final String label;
  final VoidCallback onPressed;
  final Color textColor;
  final Color backgroundColor;
  final Color? borderColor;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final buttonChild = Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: buttonKey,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border:
                borderColor == null ? null : Border.all(color: borderColor!),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    letterSpacing: 0,
                    color: textColor,
                  ),
            ),
          ),
        ),
      ),
    );

    if (width == null) {
      return buttonChild;
    }

    return SizedBox(
      width: width,
      child: buttonChild,
    );
  }
}

class _OrderCompletedActionButton extends StatelessWidget {
  const _OrderCompletedActionButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: const ValueKey('stock-order-complete-view-accounts'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gray300),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ImageIcon(
                  AssetImage(AppAssets.externalLinkIcon),
                  size: 24,
                  color: AppColors.gray700,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'View Accounts',
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            letterSpacing: 0,
                            color: AppColors.gray700,
                          ),
                    ),
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

class _OrderSubmitButton extends StatelessWidget {
  const _OrderSubmitButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.green500,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            'Buy',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: 0,
                  color: AppColors.white,
                ),
          ),
        ),
      ),
    );
  }
}

class _OrderStepIconButton extends StatelessWidget {
  const _OrderStepIconButton({
    required this.buttonKey,
    required this.onTap,
    required this.child,
  });

  final Key buttonKey;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 24,
          height: 24,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _OrderCloseIcon extends StatelessWidget {
  const _OrderCloseIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _OrderCloseIconPainter(),
      ),
    );
  }
}

class _OrderCloseIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray400
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const inset = 6.0;
    canvas.drawLine(
      const Offset(inset, inset),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _AccountPinInputSection extends StatelessWidget {
  const _AccountPinInputSection({
    required this.pin,
  });

  final String pin;

  @override
  Widget build(BuildContext context) {
    final displayText = pin.isEmpty
        ? 'Account PIN'
        : List.filled(pin.length, '●').join('\u00A0');
    final displayColor = pin.isEmpty ? AppColors.gray600 : AppColors.gray1000;

    return SizedBox(
      height: 133,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account PIN',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: AppColors.gray1000,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.gray300),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                displayText,
                key: const ValueKey('stock-order-pin-display'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: displayColor,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountPinKeypad extends StatelessWidget {
  const _AccountPinKeypad({
    required this.onDigitPressed,
  });

  static const _rows = [
    ['1', null, '2', '3'],
    ['4', '5', '6', null],
    ['7', '8', '9', '0'],
  ];

  final ValueChanged<String> onDigitPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Column(
        children: _rows
            .map(
              (row) => Expanded(
                child: Row(
                  children: row
                      .map(
                        (digit) => Expanded(
                          child: _AccountPinKeypadCell(
                            digit: digit,
                            onPressed: digit == null
                                ? null
                                : () => onDigitPressed(digit),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _AccountPinKeypadCell extends StatelessWidget {
  const _AccountPinKeypadCell({
    required this.digit,
    required this.onPressed,
  });

  final String? digit;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (digit == null || onPressed == null) {
      return const SizedBox.expand();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('stock-order-pin-key-$digit'),
        onTap: onPressed,
        splashFactory: NoSplash.splashFactory,
        highlightColor: AppColors.gray100.withValues(alpha: 0.6),
        child: Center(
          child: Text(
            digit!,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: AppColors.gray1000,
                ),
          ),
        ),
      ),
    );
  }
}

class _AccountPinActionBar extends StatelessWidget {
  const _AccountPinActionBar({
    required this.onCancel,
    required this.onConfirm,
    required this.isConfirmEnabled,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool isConfirmEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 77,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 45,
                child: OutlinedButton(
                  key: const ValueKey('stock-order-pin-cancel'),
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.gray700,
                    side: const BorderSide(color: AppColors.gray300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: AppColors.gray700,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 45,
                child: FilledButton(
                  key: const ValueKey('stock-order-pin-confirm'),
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: isConfirmEnabled
                        ? AppColors.orange500
                        : AppColors.orange300,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Confirm',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: AppColors.white,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockHomeBar extends StatelessWidget {
  const _StockHomeBar();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _OrderChevronDownIcon extends StatelessWidget {
  const _OrderChevronDownIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: SizedBox(
          width: 10,
          height: 6,
          child: CustomPaint(
            painter: _OrderChevronPainter(),
          ),
        ),
      ),
    );
  }
}

class _OrderMinusIcon extends StatelessWidget {
  const _OrderMinusIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 10,
      height: 2,
      child: CustomPaint(
        painter: _OrderMinusPainter(),
      ),
    );
  }
}

class _OrderPlusIcon extends StatelessWidget {
  const _OrderPlusIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 10,
      height: 10,
      child: CustomPaint(
        painter: _OrderPlusPainter(),
      ),
    );
  }
}

class _OrderChevronPainter extends CustomPainter {
  const _OrderChevronPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(0.75, 0.75)
      ..lineTo(size.width / 2, size.height - 0.75)
      ..lineTo(size.width - 0.75, 0.75);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrderMinusPainter extends CustomPainter {
  const _OrderMinusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0.75, size.height / 2),
      Offset(size.width - 0.75, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrderPlusPainter extends CustomPainter {
  const _OrderPlusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0.75, size.height / 2),
      Offset(size.width - 0.75, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0.75),
      Offset(size.width / 2, size.height - 0.75),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrderCheckPainter extends CustomPainter {
  const _OrderCheckPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(1.4, size.height * 0.5)
      ..lineTo(size.width * 0.4, size.height - 1.2)
      ..lineTo(size.width - 1.0, 1.0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrderQuoteData {
  const _OrderQuoteData({
    required this.price,
    required this.changeRate,
    required this.quantity,
    required this.isPositive,
    this.isGrayBackground = false,
  });

  final String price;
  final String changeRate;
  final String quantity;
  final bool isPositive;
  final bool isGrayBackground;
}

double? _parseAmount(String raw) {
  final normalized = raw.replaceAll(',', '').trim();
  return double.tryParse(normalized);
}

int? _parseEditableInt(String raw) {
  final normalized = raw.replaceAll(',', '').trim();
  return int.tryParse(normalized);
}

String _formatWholeAmount(String raw) {
  final digits = raw.replaceAll(',', '').trim();
  if (digits.isEmpty) {
    return raw;
  }

  final number = int.tryParse(digits);
  if (number == null) {
    return raw;
  }

  final sign = number < 0 ? '-' : '';
  final absoluteDigits = number.abs().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < absoluteDigits.length; index++) {
    if (index > 0 && (absoluteDigits.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(absoluteDigits[index]);
  }

  return '$sign$buffer';
}

String _formatSignedPercent({
  required double? current,
  required double? reference,
  required bool fallbackPositive,
}) {
  if (current == null || reference == null || reference == 0) {
    return fallbackPositive ? '+0.00%' : '-0.00%';
  }

  final delta = ((current - reference) / reference) * 100;
  final sign = delta >= 0 ? '+' : '';
  return '$sign${delta.toStringAsFixed(2)}%';
}

String _formatOrderAmount(int value) {
  return '\$${_formatWholeAmount('$value')}';
}

String _formatOrderQuantity(int quantity) {
  return '$quantity ${quantity == 1 ? 'Share' : 'Shares'}';
}

String _formatDialogOrderAmount(int value) {
  return '\$${_formatDialogGroupedAmount('$value')}';
}

String _formatDialogGroupedAmount(String raw) {
  final digits = raw.replaceAll(',', '').trim();
  if (digits.isEmpty) {
    return raw;
  }

  final number = int.tryParse(digits);
  if (number == null) {
    return raw;
  }

  final sign = number < 0 ? '-' : '';
  final absoluteDigits = number.abs().toString();
  final groups = <String>[];

  for (var end = absoluteDigits.length; end > 0; end -= 3) {
    final start = (end - 3).clamp(0, absoluteDigits.length);
    groups.insert(0, absoluteDigits.substring(start, end));
  }

  if (groups.length <= 1) {
    return '$sign${groups.first}';
  }

  final lastGroup = groups.removeLast();
  return '$sign${groups.join(',')}.$lastGroup';
}

int _krxTickSize(int price) {
  if (price < 2_000) {
    return 1;
  }
  if (price < 5_000) {
    return 5;
  }
  if (price < 20_000) {
    return 10;
  }
  if (price < 50_000) {
    return 50;
  }
  if (price < 200_000) {
    return 100;
  }
  if (price < 500_000) {
    return 500;
  }
  return 1000;
}
