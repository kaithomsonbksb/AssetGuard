// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:assetguard/main.dart';

void main() {
  testWidgets('AssetGuard login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AssetGuardApp());

    // Verify that the login screen is displayed
    expect(find.text('AssetGuard Login'), findsOneWidget);
    expect(find.text('Asset Management System'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
