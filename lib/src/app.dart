import 'package:flutter/material.dart';

class StockExchangeApp extends StatelessWidget {
  const StockExchangeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Exchange',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: const MarketDashboardScreen(),
    );
  }
}

class MarketDashboardScreen extends StatelessWidget {
  const MarketDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _MarketAppBar(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Korea Market',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text('Realtime KRW and USD quotes will stream here.'),
              SizedBox(height: 8),
              Text('Mock USD trading uses the exchange ledger only.'),
              SizedBox(height: 24),
              _QuotePlaceholder(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MarketAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Stock Exchange'),
    );
  }
}

class _QuotePlaceholder extends StatelessWidget {
  const _QuotePlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Waiting for Stock-exchange-BE quote WebSocket...'),
        ),
      ),
    );
  }
}
