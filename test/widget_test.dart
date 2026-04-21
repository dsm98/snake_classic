import 'package:flutter_test/flutter_test.dart';
import 'package:snake_classic/main.dart';

void main() {
  testWidgets('Snake app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SnakeApp());
    expect(find.byType(SnakeApp), findsOneWidget);
  });
}
