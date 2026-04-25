import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_pro/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const TaxiProApp());
    expect(find.text('Taxi Pro Tunisia'), findsOneWidget);
  });
}
