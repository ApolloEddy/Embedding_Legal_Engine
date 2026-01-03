// Basic Flutter widget test for Program A

import 'package:flutter_test/flutter_test.dart';
import 'package:program_a/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProgramAApp());

    // Verify that the app title is displayed
    expect(find.text('离线工具'), findsOneWidget);
  });
}
