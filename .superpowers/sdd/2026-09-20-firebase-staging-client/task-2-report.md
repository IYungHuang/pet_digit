# Task 2 Report: Explicit Firebase environment and region contract

## Outcome

Implemented explicit fake, emulator, and staging Firebase environment modes with a shared Taiwan Functions region contract.

## Changes

- Added `firebaseFunctionsRegion = 'asia-east1'` and staging environment selection for `pet-digit-backend`.
- Added strict `fromTransportValue` parsing; unknown values throw `FormatException`; `fromDartDefine` delegates to it.
- Added `usesBackendTransport`; providers use it instead of emulator-specific mode checks.
- Replaced all Functions `us-central1` literals in app and emulator tests with the shared region constant.
- Added contract tests for staging configuration and fail-closed transport parsing.

## TDD evidence

- RED: `flutter test test/firebase_environment_test.dart` failed to compile because staging APIs and mode were missing.
- GREEN: implementation made the new tests pass.
- Fix round 1 RED: staging initialization reached `Firebase.initializeApp` and failed through Flutter binding instead of failing closed.
- Fix round 1 GREEN: staging initialization now throws its clear `StateError` before Firebase initialization or emulator wiring.

## Verification

- `flutter test test/firebase_environment_test.dart test/firebase_emulator_integration_test.dart` — 6 tests passed.
- `flutter analyze lib/firebase/firebase_environment.dart lib/chat/presentation/chat_providers.dart test/firebase_environment_test.dart test/firebase_emulator_integration_test.dart integration_test/firebase_emulator_test.dart` — no issues.
- `rg -n "us-central1|productionPlaceholder" lib test integration_test` — no matches.
- `git diff --check` — passed.

## Self-review

- Reviewed diff against every Task 2 step: public environment API, provider composition, shared-region consumers, test coverage, and literal removal all match the brief.
- Fix round 1: verified staging guard precedes all Firebase access; emulator mode remains the only mode that initializes demo options and emulator hosts.

## Concerns

- Flutter reports 39 packages with newer incompatible versions; no dependency changes made because outside task scope.
