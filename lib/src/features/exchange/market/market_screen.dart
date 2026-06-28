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
  static const _marketCategories = <String>[
    'Stocks',
    'Cryto',
    'Options',
    'ETFs',
    'Overview',
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
      priceDisplay: '205.19',
      changeDisplay: '+37.25%',
      isPositive: true,
    ),
    _TrendingStock(
      symbol: 'NVDA',
      name: 'NVIDIA',
      market: 'NASDAQ',
      priceDisplay: '205.19',
      changeDisplay: '-37.25%',
      isPositive: false,
    ),
    _TrendingStock(
      symbol: 'NVDA',
      name: 'NVIDIA',
      market: 'NASDAQ',
      priceDisplay: '205.19',
      changeDisplay: '-37.25%',
      isPositive: false,
    ),
    _TrendingStock(
      symbol: 'NVDA',
      name: 'NVIDIA',
      market: 'NASDAQ',
      priceDisplay: '205.19',
      changeDisplay: '+37.25%',
      isPositive: true,
    ),
    _TrendingStock(
      symbol: 'NVDA',
      name: 'NVIDIA',
      market: 'NASDAQ',
      priceDisplay: '205.19',
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
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedCategoryIndex;
              return _MarketCategoryTab(
                label: _marketCategories[index],
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 24),
            itemCount: _marketCategories.length,
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Trending Stocks',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 28,
                                height: 1.1,
                              ),
                    ),
                  ),
                  Image.asset(
                    AppAssets.rightArrow,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                ],
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.gray200),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  stock.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.gray600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 108,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stock.changeDisplay,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: changeColor,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  stock.priceDisplay,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketCategoryTab extends StatelessWidget {
  const _MarketCategoryTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 16,
          height: 1.1,
          fontWeight: FontWeight.w500,
          color: isSelected ? AppColors.gray1000 : AppColors.gray600,
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.orange500 : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(label, style: textStyle),
      ),
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
