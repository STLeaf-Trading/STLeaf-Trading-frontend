import 'package:flutter_test/flutter_test.dart';
import 'package:stleaf_trading/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const STLeafApp());
    expect(find.byType(STLeafApp), findsOneWidget);
  });
}
