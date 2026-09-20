# Task 4 Report: Firebase staging bootstrap

## Delivered

- Replaced the staging fail-closed placeholder with Apple Firebase options,
  debug-only App Check activation, and idempotent anonymous authentication.
- Added pure bootstrap policy helpers and regression tests for the App Check
  guard and anonymous sign-in behavior.
- Injected the one initialized `FirebaseEnvironment` through the root Riverpod
  scope; startup errors render `FirebaseStartupFailureApp`, never fake chat.
- Preserved the Emulator initialization path unchanged.
- Regenerated macOS plugin and CocoaPods metadata so `firebase_app_check` is
  registered and linked in the native app.

## TDD evidence

- RED: `flutter test test/firebase_bootstrap_test.dart test/app_test.dart`
  failed because `firebase_bootstrap.dart`, policy/auth APIs, and failure app
  were absent.
- GREEN: the same focused command passed with 3 tests.

## Verification

- `flutter test test/firebase_bootstrap_test.dart test/firebase_environment_test.dart test/firebase_emulator_integration_test.dart test/app_test.dart` — 8 passed.
- `flutter analyze` — no issues.
- `flutter build macos --debug` — built
  `build/macos/Build/Products/Debug/chat_pet_mvp.app`.
- `git diff --check` — clean.

## Concerns

- App Check debug-token registration and the staging Firebase membership smoke
  test require controlled external Firebase Console/backend state; neither was
  performed locally.
- Native build completed with existing transitive CocoaPods deployment-target
  warnings for macOS 10.11/10.12.
