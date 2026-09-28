import 'package:flutter_test/flutter_test.dart';
import 'package:task_earn/main.dart';

void main() {
  testWidgets('Task Earn opens login screen', (tester) async {
    await tester.pumpWidget(const TaskEarnApp());
    expect(find.text('Task Earn'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
