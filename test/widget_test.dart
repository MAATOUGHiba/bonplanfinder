import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_finder/main.dart';

void main() {
  testWidgets('renders BonPlanFinder splash flow', (WidgetTester tester) async {
    await tester.pumpWidget(RestaurantFinderApp());
    expect(find.text('Preparing BonPlanFinder...'), findsOneWidget);
  });
}
