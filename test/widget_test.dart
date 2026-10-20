import 'package:flutter_test/flutter_test.dart';
import 'package:sharenest/main.dart';

void main() {
  testWidgets('ShareNest home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ShareNestApp());

    expect(find.text('Hello, Ayush'), findsOneWidget);
    expect(find.textContaining('Shared money,'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}
