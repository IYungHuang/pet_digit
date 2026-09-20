import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/firebase/firebase_bootstrap.dart';

void main() {
  test('staging App Check fails closed outside debug builds', () {
    expect(
      () => FirebaseBootstrapPolicy.validateAppCheckMode(
        staging: true,
        debugBuild: false,
      ),
      throwsStateError,
    );
  });

  test('anonymous bootstrap signs in only when user is absent', () async {
    var calls = 0;

    await ensureAnonymousFirebaseUser(
      hasCurrentUser: false,
      signInAnonymously: () async => calls++,
    );
    await ensureAnonymousFirebaseUser(
      hasCurrentUser: true,
      signInAnonymously: () async => calls++,
    );

    expect(calls, 1);
  });
}
