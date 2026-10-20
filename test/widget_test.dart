import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_mmsd_apps/main.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
