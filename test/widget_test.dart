import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thebrewcorner_employee/main.dart';

void main() {
  testWidgets('App boots to the login screen when logged out', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: EmployeeApp()));
    // Avoid pumpAndSettle: the initial "restoring session" state shows an
    // indeterminate CircularProgressIndicator, which animates forever.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('The Brew Corner'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
  });
}
