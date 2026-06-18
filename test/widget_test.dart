import 'package:flutter_test/flutter_test.dart';
import 'package:stock_exchange_fe/src/app.dart';

void main() {
  testWidgets('renders market dashboard shell', (tester) async {
    await tester.pumpWidget(const StockExchangeApp());

    expect(find.text('Stock Exchange'), findsOneWidget);
    expect(find.text('Korea Market'), findsOneWidget);
    expect(
      find.text('Realtime KRW and USD quotes will stream here.'),
      findsOneWidget,
    );
    expect(
      find.text('Mock USD trading uses the exchange ledger only.'),
      findsOneWidget,
    );
  });
}
