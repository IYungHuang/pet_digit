# Firebase Staging Client Verification Report

## Scope

Tasks 1-5 of `docs/superpowers/plans/2026-09-20-firebase-staging-client.md`:
native app identity migration, explicit `FirebaseEnvironment` staging mode,
Apple staging `FirebaseOptions` + App Check dependency, debug-only App Check
and Anonymous Auth bootstrap, and a Firestore-backed membership gate on every
staging room read/write/stream. This report covers Task 6's local
verification gate. No Cloud Functions were deployed by this work.

Note: the client-side membership gate is UX plus a client-side fail-safe, not
the access boundary — real enforcement is server-side Firestore Security
Rules and App Check, owned by the backend and out of this branch's scope.

## Automated gate

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
git diff --check
```

- `dart format`: found 10 files with pre-existing formatting drift unrelated
  to this branch's own diffs (`lib/chat/data/fake_chat_repository.dart`,
  `lib/chat/domain/chat_message.dart`, `lib/chat/domain/chat_models.dart`,
  `lib/chat/domain/message_content.dart`, `lib/chat/domain/message_status.dart`,
  `lib/chat/presentation/chat_shell.dart`, `lib/pet/domain/pet_effects.dart`,
  `test/chat_domain_test.dart`, `test/media_picker_service_test.dart`,
  `test/native_app_identity_test.dart`). Applied `dart format` (formatting
  only, no logic change) so the gate is clean; re-run confirms zero changed
  files.
- `flutter analyze`: No issues found.
- `flutter test`: **368/368 passed.**
- `git diff --check`: clean, no whitespace errors.

## macOS debug staging build

```bash
flutter build macos --debug --dart-define=CHAT_TRANSPORT=staging
```

Build succeeded: `build/macos/Build/Products/Debug/chat_pet_mvp.app`.
`CFBundleIdentifier` confirmed as `com.iyunghuang.petdigitchat`.

## Signed native Auth/App Check verification — BLOCKED

```bash
codesign -dv --verbose=4 build/macos/Build/Products/Debug/chat_pet_mvp.app
```

Output shows `CodeDirectory ... flags=0x2(adhoc)` and `Signature=adhoc`, not
`Authority=Apple Development:`. `macos/Runner.xcodeproj/project.pbxproj` has
`CODE_SIGN_IDENTITY = "-"` (ad hoc) for the Runner target's Debug/Profile/
Release configurations; two valid `Apple Development:` identities exist in
the local keychain (`app-user@fiami.com.tw`, `APP 共用`), but no
`DEVELOPMENT_TEAM` is wired into the target.

Per the plan's Task 6 Step 4 contract, this halts the signed-run gate: **the
signed development run (App Check debug-token emission, Anonymous UID
capture from a running app, `waiting`-state screenshot) was not performed.**
This gate is recorded as blocked, not passed. Functions are not deployed.

Unblocking requires choosing a `DEVELOPMENT_TEAM` for the Runner target and
switching `CODE_SIGN_IDENTITY`/`CODE_SIGN_STYLE` to a real Apple Development
identity — an Xcode signing configuration decision for whoever owns the
Apple Developer account, outside this task's file scope
(`lib/`, `README.md`, `docs/reports/`).

## Security diff check

```bash
rg -n "PRIVATE KEY|service_account|FIREBASE_APP_CHECK_DEBUG_TOKEN[[:space:]]*=" \
  lib macos ios android test integration_test
git status --short
```

`rg`: no matches (no credential values committed). `git status --short`:
only `README.md` plus the ten pre-existing formatting fixes above — no
service-account keys, debug tokens, or signing material staged.

## Not covered by this report

- App Check debug-token registration in the Firebase console.
- Anonymous UID capture from a running signed app.
- Admin seeding of `rooms/{roomId}/members/{uid}` with `active: true`.
- Cloud Functions deployment.

These remain explicit, separately authorized external steps, blocked on
resolving the signing identity above.
