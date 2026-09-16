// Basic smoke test: the app builds and shows the admin login screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:smartApp/main.dart';

void main() {
  testWidgets('App boots to the admin login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Smart Classroom IoT'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
