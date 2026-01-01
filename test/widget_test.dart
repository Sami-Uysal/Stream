import 'package:flutter_test/flutter_test.dart';
import 'package:stream/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StreamApp());

    // Verify that the Home tab is present.
    expect(find.text('Home'), findsWidgets); // Might find multiple (Rail + Bar configs)
    
    // Verify initial state shows Home content
    expect(find.text('Home (Catalogs)'), findsOneWidget);
  });
}