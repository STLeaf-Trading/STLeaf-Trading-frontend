import 'package:flutter_test/flutter_test.dart';
import 'package:stleaf_trading/main.dart';
import 'package:stleaf_trading/routes/app_router.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(STLeafApp(router: router));
    expect(find.byType(STLeafApp), findsOneWidget);
  });
}
