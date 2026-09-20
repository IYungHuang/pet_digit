import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/app.dart';

void main() {
  testWidgets('startup failure never renders fake chat', (tester) async {
    await tester.pumpWidget(
      const FirebaseStartupFailureApp(message: 'Firebase staging failed'),
    );

    expect(find.text('Firebase staging failed'), findsOneWidget);
    expect(find.text('Pixel Pals'), findsNothing);
  });
}
