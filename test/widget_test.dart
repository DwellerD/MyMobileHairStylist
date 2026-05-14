import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_hair_salon/app.dart';

void main() {
  testWidgets('welcome screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HairSalonApp(),
      ),
    );

    expect(find.text('Premium in-home hair care'), findsOneWidget);
  });
}
