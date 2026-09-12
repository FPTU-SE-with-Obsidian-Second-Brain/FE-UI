import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian_app/main.dart';

void main() {
  testWidgets('SecondBrainApp starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const SecondBrainApp());
    expect(find.text('FPTU SE Second Brain'), findsOneWidget);
  });
}
