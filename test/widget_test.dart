import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiz_ia/main.dart';

void main() {
  testWidgets('Pantry app loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PantryApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
