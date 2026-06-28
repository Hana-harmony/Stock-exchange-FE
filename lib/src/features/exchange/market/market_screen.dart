part of '../exchange_pages.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({
    super.key,
    required this.sessionController,
    required this.tradeController,
    required this.marketDetailController,
    required this.marketIndexController,
    required this.marketQuoteController,
    required this.notificationController,
  });

  final ExchangeSessionController sessionController;
  final TradeController tradeController;
  final MarketDetailController marketDetailController;
  final Object marketIndexController;
  final MarketQuoteController marketQuoteController;
  final NotificationController notificationController;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  static const _marketCategories = <({String label, double width})>[
    (label: 'Stocks', width: 58),
    (label: 'Cryto', width: 46),
    (label: 'Options', width: 65),
    (label: 'ETFs', width: 41),
    (label: 'Overview', width: 78),
    (label: 'More', width: 43),
  ];

  int _selectedCategoryIndex = 0;

  static const _heroCards = <String>[
    AppAssets.stockCardRed,
    AppAssets.stockCardGreen,
    AppAssets.stockCardRed,
  ];

  static const _trendingStocks = <_TrendingStock>[
    _TrendingStock(
      symbol: 'NVDA',
      name: 'NVIDIA',
      market: 'NASDAQ',
      priceDisplay: '205.190',
      changeDisplay: '+37.25%',
      isPositive: true,
    ),
    _TrendingStock(
      symbol: 'NVDA',
      name: 'NVIDIA',
      market: 'NASDAQ',
      priceDisplay: '205.190',
      changeDisplay: '-37.25%',
      isPositive: false,
    ),
    _TrendingStock(
      symbol: 'NVDA',
      name: 'NVIDIA',
      market: 'NASDAQ',
      priceDisplay: '205.190',
      changeDisplay: '-37.25%',
      isPositive: false,
    ),
    _TrendingStock(
      symbol: 'NVDA',
      name: 'NVIDIA',
      market: 'NASDAQ',
      priceDisplay: '205.190',
      changeDisplay: '+37.25%',
      isPositive: true,
    ),
    _TrendingStock(
      symbol: 'NVDA',
      name: 'NVIDIA',
      market: 'NASDAQ',
      priceDisplay: '205.190',
      changeDisplay: '+37.25%',
      isPositive: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      children: [
        SizedBox(
          height: 41,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 10),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedCategoryIndex;
                final category = _marketCategories[index];
                return _MarketCategoryTab(
                  label: category.label,
                  width: category.width,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 18),
              itemCount: _marketCategories.length,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            children: [
              SizedBox(
                height: 134,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.large),
                      child: Image.asset(
                        _heroCards[index],
                        width: 120,
                        height: 134,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemCount: _heroCards.length,
                ),
              ),
              const SizedBox(height: 20),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.gray1000,
                  borderRadius: BorderRadius.circular(AppRadii.large),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.large),
                  child: SizedBox(
                    height: 77,
                    width: double.infinity,
                    child: ClipRect(
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        alignment: Alignment.centerLeft,
                        child: Image.asset(AppAssets.marketDataContainer),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Trending Stocks',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: 24,
                                  height: 31 / 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gray1000,
                                ),
                      ),
                    ),
                    SizedBox.square(
                      dimension: 36,
                      child: Center(
                        child: Image.asset(
                          AppAssets.rightArrow,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              for (var index = 0; index < _trendingStocks.length; index++)
                _TrendingStockTile(
                  stock: _trendingStocks[index],
                  rank: index + 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendingStockTile extends StatelessWidget {
  const _TrendingStockTile({
    required this.stock,
    required this.rank,
  });

  final _TrendingStock stock;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final changeColor =
        stock.isPositive ? AppColors.green500 : AppColors.red500;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 65,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 277,
                height: 45,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 45,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 25,
                          child: Text(
                            '$rank',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  height: 25 / 18,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray1000,
                                ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 34,
                      height: 45,
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.gray200),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 215,
                      height: 45,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 25,
                            child: Text(
                              stock.symbol,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                    fontSize: 18,
                                    height: 25 / 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.gray1000,
                                  ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                            child: Text(
                              stock.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.gray600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 73,
                height: 45,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 25,
                      child: Text(
                        stock.changeDisplay,
                        maxLines: 1,
                        textAlign: TextAlign.end,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  height: 25 / 18,
                                  fontWeight: FontWeight.w500,
                                  color: changeColor,
                                ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                      child: Text(
                        stock.priceDisplay,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.gray1000,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketCategoryTab extends StatelessWidget {
  const _MarketCategoryTab({
    required this.label,
    required this.width,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final double width;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppUnderlineTab(
      label: label,
      width: width,
      isSelected: isSelected,
      onTap: onTap,
      fontSize: 17,
      fontWeightSelected: FontWeight.w700,
      fontWeightUnselected: FontWeight.w400,
      activeColor: AppColors.gray1000,
      inactiveColor: AppColors.gray600,
      underlineWidth: width,
      underlineHeight: 3,
    );
  }
}

class _TrendingStock {
  const _TrendingStock({
    required this.symbol,
    required this.name,
    required this.market,
    required this.priceDisplay,
    required this.changeDisplay,
    required this.isPositive,
  });

  final String symbol;
  final String name;
  final String market;
  final String priceDisplay;
  final String changeDisplay;
  final bool isPositive;
}
