import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:busylight_buddy/main.dart';

void main() {
  testWidgets('App smoke test — renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BusylightApp(),
      ),
    );
    expect(find.text('BusyLight'), findsOneWidget);
  });
}