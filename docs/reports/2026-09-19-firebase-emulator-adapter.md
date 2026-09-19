# Firebase Emulator Adapter Implementation Report

## Scope

- Firebase Auth, Firestore, Storage, and Functions adapter scaffold.
- Fake transport remains default.
- Emulator mode uses demo project `demo-pet-digit` and ports from backend
  `firebase.json`.
- No production Firebase options, service account, deploy, FCM, Redis, CDN, or
  media transcoding.

## Adapter boundary

```text
Firebase Auth / Firestore / Storage / Functions
  -> Firebase data sources and mapper
  -> MessageRepository / MessageStore
  -> Riverpod room projection
  -> ChatShell
```

Firestore uses bounded `orderBy(createdAt).limitToLast(50)` snapshots. Each
`docChanges` item becomes one `MessageDelta`; initial `added` events merge into
the repository store. No full-list replacement or history listener is used.

## Modes

`FirebaseEnvironment` supports `fake`, `emulator`, and
`production-placeholder`. `fake` is default. Emulator initialization uses
local demo options only and calls each Firebase SDK emulator hook.

## Tests

- `flutter analyze`: passed.
- `flutter test`: passed, 49 tests.
- Firebase mapper/environment/media validation tests: passed.
- Backend Emulator Suite startup: passed on Auth `9099`, Firestore `8080`,
  Storage `9199`, Functions `5001`, UI `4000`.
- Native `flutter drive` reached Firebase Auth emulator but host macOS
  Keychain access failed; adding Keychain entitlement requires development
  signing, unavailable in current workspace. Integration test remains opt-in
  and documented.

## Follow-up

- Run `flutter drive` on signed macOS target or device with Keychain access.
- Add production `GoogleService-Info.plist` / platform config only in a future
  production-specific change after project and credential review.
