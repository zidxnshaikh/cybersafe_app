// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cybersafe/main.dart';
import 'package:cybersafe/providers/threat_provider.dart';

void main() {
  testWidgets('home screen shows the CyberSafe tools', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThreatProvider(),
        child: const MaterialApp(home: CyberSafeHomeScreen()),
      ),
    );

    expect(find.text('CyberSafe'), findsOneWidget);
    expect(find.text('Phishing & Scam Link Analyzer'), findsOneWidget);
    expect(find.text('1930 Helpline'), findsOneWidget);
  });
}
