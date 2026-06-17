import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tradementor_mobile/main.dart';

void main() {
  testWidgets('TradeMentor App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MarketProvider(),
        child: const TradeMentorApp(),
      ),
    );

    // Verify that TradeMentor is rendered on the screen.
    expect(find.text('TradeMentor'), findsAtLeastNWidgets(1));
  });
}
