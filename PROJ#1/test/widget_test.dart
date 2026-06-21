import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_trello/main.dart';
import 'package:flutter_trello/services/demo_repository.dart';

void main() {
  testWidgets('renders dashboard after demo session restore', (tester) async {
    await tester.pumpWidget(
      FlutterTrelloApp(repository: DemoRepository(firebaseReady: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('FlutterTrello'), findsWidgets);
    expect(find.text('Mobile Launch Board'), findsWidgets);
    expect(find.text('Here is what your team is working on.'), findsWidgets);
  });
}
