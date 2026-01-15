// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderos_utc/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Construye la app principal sin parámetros adicionales
    await tester.pumpWidget(const GanaderosUTCApp(initialRoute: ''));

    // Verifica que se construya un MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
