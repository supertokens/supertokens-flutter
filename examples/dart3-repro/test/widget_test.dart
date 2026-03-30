import 'package:flutter_test/flutter_test.dart';

import 'package:dart3_repro/main.dart';

void main() {
  testWidgets('renders login flow shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Checking SuperTokens session...'), findsOneWidget);
  });
}
