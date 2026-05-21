import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_hair_salon/app.dart';

void main() {
  testWidgets('welcome screen renders', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(
        child: HairSalonApp(),
      ),
    );

    expect(find.text('Luxury in-home hair care for modern households'), findsOneWidget);
  });
}
