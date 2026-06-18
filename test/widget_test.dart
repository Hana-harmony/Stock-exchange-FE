import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_exchange_fe/src/app.dart';

void main() {
  testWidgets('renders market shell with USD quote context', (tester) async {
    await tester.pumpWidget(const StockExchangeApp());

    expect(find.text('Hana Local Exchange'), findsOneWidget);
    expect(find.text('Korea Market'), findsOneWidget);
    expect(find.text('Sign in with username and password'), findsOneWidget);
    expect(find.text('Search all Korean stocks'), findsOneWidget);
    expect(find.text('WebSocket live'), findsOneWidget);
    expect(find.text('REST snapshot ready'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(find.text('USD 54.00'), findsOneWidget);
    expect(
      find.text('FX 2026-06-18 06:00 UTC / source Hana-OmniLens-API'),
      findsOneWidget,
    );
  });

  testWidgets('navigates portfolio, alerts, and tax tabs', (tester) async {
    await tester.pumpWidget(const StockExchangeApp());

    await tester.tap(_navigationDestination('Portfolio'));
    await tester.pumpAndSettle();
    expect(find.text('Mock USD cash'), findsWidgets);
    expect(find.text('Mock USD trading ledger. No real order is sent.'), findsOneWidget);

    await tester.tap(_navigationDestination('Alerts'));
    await tester.pumpAndSettle();
    expect(
      find.text('AI translated news and disclosures for your stocks.'),
      findsOneWidget,
    );
    expect(find.text('Original link / My Portfolio / High importance'), findsOneWidget);

    await tester.tap(_navigationDestination('Tax'));
    await tester.pumpAndSettle();
    expect(find.text('Tax Refund'), findsOneWidget);
    expect(find.text('Estimated refund USD 84.30'), findsOneWidget);
  });
}

Finder _navigationDestination(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is NavigationDestination && widget.label == label,
  );
}
