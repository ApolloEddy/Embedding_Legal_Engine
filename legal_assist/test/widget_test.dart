// Basic Flutter widget test for Legal Assist

import 'package:flutter_test/flutter_test.dart';
import 'package:legal_assist/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LegalAssistApp());

    // Verify that the app title is displayed
    expect(find.text('Legal Assist'), findsOneWidget);
  });
}
