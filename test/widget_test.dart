import 'package:flutter_test/flutter_test.dart';
import 'package:khmt2411005_mailehuyhoang_casestudy2/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskManagerApp(isLoggedIn: false));
    expect(find.byType(TaskManagerApp), findsOneWidget);
  });
}
