part of '../exchange_pages.dart';

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({
    required this.query,
    required this.onTap,
  });

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            query,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}

class _MostSearchedRow extends StatelessWidget {
  const _MostSearchedRow({
    required this.item,
    required this.onTap,
  });

  final _MarketSearchPreview item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        item.isPositive ? AppColors.green500 : AppColors.red500;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 44,
              child: Center(
                child: Transform.scale(
                  scale: 44 / 34,
                  child: _SearchResultAvatar(
                    stockCode: item.symbol,
                    stockName: item.name,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.symbol,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.gray600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.priceDisplay,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item.changeDisplay,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.secondaryPriceDisplay,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      item.secondaryChangeDisplay,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingHeadlineRow extends StatelessWidget {
  const _TrendingHeadlineRow({
    required this.rank,
    required this.title,
  });

  final int rank;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.orange500,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.item,
    required this.query,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  final StockSearchItem item;
  final String query;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final countryBadgeAsset = _isHongKongMarket(item.market)
        ? AppAssets.countryBadgeHk
        : AppAssets.countryBadgeKr;

    return SizedBox(
      height: 65,
      child: InkWell(
        key: ValueKey('stock-search-result-${item.stockCode}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              _MarketBadge(assetPath: countryBadgeAsset),
              const SizedBox(width: 8),
              _SearchResultAvatar(
                stockCode: item.stockCode,
                stockName: item.stockName,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.stockCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text.rich(
                      TextSpan(
                        children: _buildDescriptionSpans(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _FavoriteButton(
                isFavorite: isFavorite,
                onTap: onFavoriteTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildDescriptionSpans(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.gray600,
          fontWeight: FontWeight.w400,
        );
    final highlightStyle = baseStyle?.copyWith(
      color: AppColors.orange500,
      fontWeight: FontWeight.w500,
    );
    final source = item.stockName;
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return [TextSpan(text: source, style: baseStyle)];
    }

    final lowerSource = source.toLowerCase();
    final lowerQuery = normalizedQuery.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final matchIndex = lowerSource.indexOf(lowerQuery, start);
      if (matchIndex == -1) {
        break;
      }
      if (matchIndex > start) {
        spans.add(
          TextSpan(
            text: source.substring(start, matchIndex),
            style: baseStyle,
          ),
        );
      }
      spans.add(
        TextSpan(
          text:
              source.substring(matchIndex, matchIndex + normalizedQuery.length),
          style: highlightStyle,
        ),
      );
      start = matchIndex + normalizedQuery.length;
    }

    if (spans.isEmpty) {
      return [TextSpan(text: source, style: baseStyle)];
    }

    if (start < source.length) {
      spans.add(
        TextSpan(
          text: source.substring(start),
          style: baseStyle,
        ),
      );
    }

    return spans;
  }
}

class _MarketSearchPreview {
  const _MarketSearchPreview({
    required this.symbol,
    required this.name,
    required this.priceDisplay,
    required this.changeDisplay,
    required this.secondaryPriceDisplay,
    required this.secondaryChangeDisplay,
    required this.isPositive,
  });

  final String symbol;
  final String name;
  final String priceDisplay;
  final String changeDisplay;
  final String secondaryPriceDisplay;
  final String secondaryChangeDisplay;
  final bool isPositive;
}

const _dummyStockSearchEntries = <_DummyStockSearchEntry>[
  _DummyStockSearchEntry(
    stockCode: '005930',
    stockName: 'Samsung Electronics',
    market: 'KOSPI',
    sector: 'Semiconductor',
    aliases: ['삼성전자', 'samsung', 'samsung electronics', '005930'],
  ),
  _DummyStockSearchEntry(
    stockCode: '07747',
    stockName: 'CSOP Samsung Electronics Daily (2x) Leveraged Product',
    market: 'HKEX',
    sector: 'ETF',
    aliases: [
      'csop samsung electronics',
      'samsung',
      'hong kong',
      'hk',
      '07747',
    ],
  ),
  _DummyStockSearchEntry(
    stockCode: '207940',
    stockName: 'Samsung Biologics',
    market: 'KOSPI',
    sector: 'Biotech',
    aliases: ['삼성바이오로직스', 'samsung biologics', 'samsung', '207940'],
  ),
  _DummyStockSearchEntry(
    stockCode: '006400',
    stockName: 'Samsung SDI',
    market: 'KOSPI',
    sector: 'Battery',
    aliases: ['삼성sdi', 'samsung sdi', 'samsung', '006400'],
  ),
  _DummyStockSearchEntry(
    stockCode: '028260',
    stockName: 'Samsung C&T',
    market: 'KOSPI',
    sector: 'Industrial',
    aliases: ['삼성물산', 'samsung c&t', 'samsung', '028260'],
  ),
  _DummyStockSearchEntry(
    stockCode: '000660',
    stockName: 'SK hynix',
    market: 'KOSPI',
    sector: 'Semiconductor',
    aliases: ['sk hynix', '하이닉스', 'sk하이닉스', '000660'],
  ),
  _DummyStockSearchEntry(
    stockCode: '035420',
    stockName: 'NAVER',
    market: 'KOSPI',
    sector: 'Internet',
    aliases: ['naver', '네이버', '035420'],
  ),
  _DummyStockSearchEntry(
    stockCode: '035720',
    stockName: '카카오',
    market: 'KOSPI',
    sector: 'IT',
    aliases: ['카카오', 'kakao', '035720'],
  ),
  _DummyStockSearchEntry(
    stockCode: '323410',
    stockName: '카카오뱅크',
    market: 'KOSPI',
    sector: 'Bank',
    aliases: ['카카오뱅크', 'kakaobank', 'kakao bank', '323410'],
  ),
  _DummyStockSearchEntry(
    stockCode: '005380',
    stockName: '현대차',
    market: 'KOSPI',
    sector: 'Automotive',
    aliases: ['현대차', 'hyundai', 'hyundai motor', '005380'],
  ),
  _DummyStockSearchEntry(
    stockCode: 'NVDA',
    stockName: 'NVIDIA',
    market: 'NASDAQ',
    sector: 'Semiconductor',
    aliases: ['nvda', 'nvidia'],
  ),
];

class _DummyStockSearchEntry {
  const _DummyStockSearchEntry({
    required this.stockCode,
    required this.stockName,
    required this.market,
    required this.sector,
    required this.aliases,
  });

  final String stockCode;
  final String stockName;
  final String market;
  final String sector;
  final List<String> aliases;

  StockSearchItem toSearchItem() {
    return StockSearchItem(
      stockCode: stockCode,
      stockName: stockName,
      market: market,
      sector: sector,
      dataSource: 'Dummy',
    );
  }
}

List<StockSearchItem> _searchDummyStocks(String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return const [];
  }

  return _dummyStockSearchEntries
      .where((entry) {
        return entry.aliases.any(
              (alias) => alias.toLowerCase().contains(normalized),
            ) ||
            entry.stockName.toLowerCase().contains(normalized) ||
            entry.stockCode.toLowerCase().contains(normalized);
      })
      .map((entry) => entry.toSearchItem())
      .toList(growable: false);
}
