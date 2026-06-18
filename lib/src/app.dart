import 'package:flutter/material.dart';

class StockExchangeApp extends StatelessWidget {
  const StockExchangeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hana Local Exchange',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        scaffoldBackgroundColor: const Color(0xFFF7FAFC),
        useMaterial3: true,
      ),
      home: const ExchangeShell(),
    );
  }
}

class ExchangeShell extends StatefulWidget {
  const ExchangeShell({super.key});

  @override
  State<ExchangeShell> createState() => _ExchangeShellState();
}

class _ExchangeShellState extends State<ExchangeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hana Local Exchange'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: _WalletBadge(),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            MarketScreen(),
            PortfolioScreen(),
            AlertsScreen(),
            TaxScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Market',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Tax',
          ),
        ],
      ),
    );
  }
}

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ScreenFrame(
      title: 'Korea Market',
      subtitle: 'Live KRX quotes with KRW and USD pricing.',
      children: [
        _SearchField(),
        _MarketFilters(),
        _StatusStrip(),
        _QuoteRow(
          symbol: '005930',
          name: 'Samsung Electronics',
          priceKrw: 'KRW 82,400',
          priceUsd: 'USD 54.00',
          change: '+1.23%',
          badge: 'Watchlist',
        ),
        _QuoteRow(
          symbol: '035420',
          name: 'NAVER',
          priceKrw: 'KRW 183,700',
          priceUsd: 'USD 120.41',
          change: '-0.38%',
          badge: 'Portfolio',
        ),
        _InfoPanel(
          icon: Icons.currency_exchange,
          title: 'FX applied',
          body: 'USD prices use the latest KRW/USD rate from Stock-exchange-BE.',
          meta: 'FX 2026-06-18 06:00 UTC / source Hana-OmniLens-API',
        ),
      ],
    );
  }
}

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ScreenFrame(
      title: 'Portfolio',
      subtitle: 'Mock USD trading ledger. No real order is sent.',
      children: [
        _BalancePanel(),
        _QuoteRow(
          symbol: '035420',
          name: 'NAVER',
          priceKrw: 'KRW 183,700',
          priceUsd: 'USD 120.41',
          change: '+USD 318.20',
          badge: 'Holding',
        ),
        _InfoPanel(
          icon: Icons.point_of_sale,
          title: 'Mock USD cash',
          body: 'Deposit, buy, and sell actions update only the exchange ledger.',
          meta: 'Available cash USD 12,450.00',
        ),
      ],
    );
  }
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ScreenFrame(
      title: 'Alerts',
      subtitle: 'AI translated news and disclosures for your stocks.',
      children: [
        _AlertFilters(),
        _InfoPanel(
          icon: Icons.article_outlined,
          title: 'Samsung disclosure translated',
          body: 'AI summary, sentiment, importance, and event tags appear here.',
          meta: 'Original link / My Portfolio / High importance',
        ),
        _InfoPanel(
          icon: Icons.link,
          title: 'K-News timeline',
          body: 'Watchlist and portfolio filters keep real-time push alerts focused.',
          meta: 'All / My Portfolio / Watchlist',
        ),
      ],
    );
  }
}

class TaxScreen extends StatelessWidget {
  const TaxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ScreenFrame(
      title: 'Tax Refund',
      subtitle: 'Document status, refund estimate, and recapture risk.',
      children: [
        _InfoPanel(
          icon: Icons.upload_file_outlined,
          title: 'Documents',
          body: 'Certificate of residence and tax treaty forms are tracked here.',
          meta: 'Submitted / Verification pending',
        ),
        _InfoPanel(
          icon: Icons.payments_outlined,
          title: 'Refund estimate',
          body: 'Realized gains from mock sell history feed the refund input data.',
          meta: 'Estimated refund USD 84.30',
        ),
        _InfoPanel(
          icon: Icons.warning_amber_outlined,
          title: 'Recapture risk',
          body: 'Advance refund completion includes a clear post-review risk notice.',
          meta: 'Risk notice required before advance payment',
        ),
      ],
    );
  }
}

class _ScreenFrame extends StatelessWidget {
  const _ScreenFrame({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: SearchBar(
        leading: Icon(Icons.search),
        hintText: 'Search all Korean stocks',
      ),
    );
  }
}

class _MarketFilters extends StatelessWidget {
  const _MarketFilters();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(label: Text('All'), selected: true),
          ChoiceChip(label: Text('KOSPI'), selected: false),
          ChoiceChip(label: Text('KOSDAQ'), selected: false),
          ChoiceChip(label: Text('Watchlist'), selected: false),
          ChoiceChip(label: Text('Portfolio'), selected: false),
        ],
      ),
    );
  }
}

class _AlertFilters extends StatelessWidget {
  const _AlertFilters();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(label: Text('All'), selected: true),
          ChoiceChip(label: Text('My Portfolio'), selected: false),
          ChoiceChip(label: Text('Watchlist'), selected: false),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatusChip(icon: Icons.wifi_tethering, label: 'WebSocket live'),
          _StatusChip(icon: Icons.sync, label: 'REST snapshot ready'),
          _StatusChip(icon: Icons.schedule, label: 'No stale ticks'),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({
    required this.symbol,
    required this.name,
    required this.priceKrw,
    required this.priceUsd,
    required this.change,
    required this.badge,
  });

  final String symbol;
  final String name;
  final String priceKrw;
  final String priceUsd;
  final String change;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  _SmallBadge(label: badge),
                ],
              ),
              const SizedBox(height: 6),
              Text(symbol),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _Metric(label: 'KRW', value: priceKrw),
                  _Metric(label: 'USD', value: priceUsd),
                  _Metric(label: 'Move', value: change),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.body,
    required this.meta,
  });

  final IconData icon;
  final String title;
  final String body;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(body),
                    const SizedBox(height: 8),
                    Text(
                      meta,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
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

class _BalancePanel extends StatelessWidget {
  const _BalancePanel();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.primaryContainer,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mock USD cash'),
                    SizedBox(height: 4),
                    Text(
                      'USD 12,450.00',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add),
                label: const Text('Deposit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletBadge extends StatelessWidget {
  const _WalletBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 16),
            SizedBox(width: 6),
            Text('USD 12,450'),
          ],
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
