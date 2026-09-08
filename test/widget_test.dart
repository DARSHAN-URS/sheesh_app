import 'package:flutter_test/flutter_test.dart';
import 'package:sheesh_app/main.dart';

void main() {
  testWidgets('Sheesh app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SheeshApp());
    expect(find.text('Sheesh'), findsWidgets);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
