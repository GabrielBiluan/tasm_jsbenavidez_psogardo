import 'package:flutter_test/flutter_test.dart';
import 'package:tasm_jsbenavidez_psogardo/main.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskManagerApp());
    expect(find.byType(TaskManagerApp), findsOneWidget);
  });
}
