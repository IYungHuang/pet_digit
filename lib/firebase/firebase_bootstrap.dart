class FirebaseBootstrapPolicy {
  const FirebaseBootstrapPolicy._();

  static void validateAppCheckMode({
    required bool staging,
    required bool debugBuild,
  }) {
    if (staging && !debugBuild) {
      throw StateError('Staging Firebase App Check requires a debug build.');
    }
  }
}

Future<void> ensureAnonymousFirebaseUser({
  required bool hasCurrentUser,
  required Future<void> Function() signInAnonymously,
}) async {
  if (!hasCurrentUser) await signInAnonymously();
}
