# Firebase Staging Client Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect macOS Flutter debug builds to Firebase staging with stable native identity, `asia-east1` Functions, Anonymous Auth, App Check debug attestation, and explicit membership-gated room connection.

**Architecture:** `FirebaseEnvironment` remains the single composition selector. Fake stays default, Emulator retains local hooks, and staging initializes checked-in public Apple options plus debug-only App Check and Anonymous Auth. Riverpod selects Firebase adapters for Emulator and staging but does not connect a staging room until an explicit membership-ready signal is present.

**Tech Stack:** Flutter, Dart, Riverpod, Firebase Core/Auth/Firestore/Storage/Functions/App Check, FlutterFire Apple SDK, Flutter test.

**Spec:** `docs/superpowers/specs/2026-09-20-firebase-staging-client-design.md`

## Global Constraints

- Native app identifier is exactly `com.iyunghuang.petdigitchat`.
- Firebase project is exactly `pet-digit-backend`.
- Flutter and backend Functions region is exactly `asia-east1`.
- Allowed `CHAT_TRANSPORT` values are `fake`, `emulator`, and `staging`; unknown values fail startup.
- Fake remains default and must not initialize Firebase.
- App Check debug provider is allowed only in `kDebugMode`; profile/release staging fails closed.
- Never commit App Check debug tokens, service-account keys, or signing material.
- Staging must never silently fall back to fake adapters.
- Client cannot create or elevate room membership.

---

### Task 1: Native application identity migration

**Files:**
- Create: `test/native_app_identity_test.dart`
- Modify: `macos/Runner/Configs/AppInfo.xcconfig`
- Modify: `macos/Runner.xcodeproj/project.pbxproj`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Modify: `android/app/build.gradle.kts`
- Delete: `android/app/src/main/kotlin/com/example/chat_pet_mvp/MainActivity.kt`
- Create: `android/app/src/main/kotlin/com/iyunghuang/petdigitchat/MainActivity.kt`

**Interfaces:**
- Consumes: approved identifier `com.iyunghuang.petdigitchat`.
- Produces: native projects with no `com.example` identifier and Android activity package matching Gradle namespace.

- [ ] **Step 1: Write failing static contract test**

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const id = 'com.iyunghuang.petdigitchat';
  test('all native targets use approved app identifier', () {
    final files = <String>[
      'macos/Runner/Configs/AppInfo.xcconfig',
      'macos/Runner.xcodeproj/project.pbxproj',
      'ios/Runner.xcodeproj/project.pbxproj',
      'android/app/build.gradle.kts',
    ];
    for (final path in files) {
      final content = File(path).readAsStringSync();
      expect(content, isNot(contains('com.example')), reason: path);
      expect(content, contains(id), reason: path);
    }
    expect(
      File('android/app/src/main/kotlin/com/example/chat_pet_mvp/MainActivity.kt')
          .existsSync(),
      isFalse,
    );
    expect(
      File('android/app/src/main/kotlin/com/iyunghuang/petdigitchat/MainActivity.kt')
          .readAsStringSync(),
      contains('package com.iyunghuang.petdigitchat'),
    );
  });
}
```

- [ ] **Step 2: Verify RED**

Run: `flutter test test/native_app_identity_test.dart`

Expected: FAIL because native files retain `com.example` and new Android activity path is absent.

- [ ] **Step 3: Apply identity migration**

Set macOS/iOS app targets to `com.iyunghuang.petdigitchat`, test targets to `com.iyunghuang.petdigitchat.RunnerTests`, Android `namespace` and `applicationId` to `com.iyunghuang.petdigitchat`, and move `MainActivity.kt` with:

```kotlin
package com.iyunghuang.petdigitchat

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

- [ ] **Step 4: Verify GREEN**

Run: `flutter test test/native_app_identity_test.dart`

Expected: PASS.

Run: `rg -n "com\\.example" macos ios android`

Expected: no matches.

- [ ] **Step 5: Commit task**

```bash
git add macos ios android test/native_app_identity_test.dart
git commit -m "chore(app): set stable native application identity"
```

---

### Task 2: Explicit Firebase environment and region contract

**Files:**
- Modify: `test/firebase_environment_test.dart`
- Modify: `lib/firebase/firebase_environment.dart`
- Modify: `lib/chat/presentation/chat_providers.dart`
- Modify: `test/firebase_emulator_integration_test.dart`
- Modify: `integration_test/firebase_emulator_test.dart`

**Interfaces:**
- Produces: `const firebaseFunctionsRegion = 'asia-east1'`, `FirebaseEnvironmentMode.staging`, `FirebaseEnvironment.staging()`, `bool get usesBackendTransport`, and strict `FirebaseEnvironment.fromTransportValue(String value)`.
- Consumers: Tasks 3–5 use these APIs for initialization and provider composition.

- [ ] **Step 1: Add failing environment tests**

Add assertions:

```dart
test('staging targets production project and Taiwan Functions region', () {
  final environment = FirebaseEnvironment.staging();
  expect(environment.mode, FirebaseEnvironmentMode.staging);
  expect(environment.projectId, 'pet-digit-backend');
  expect(environment.functionsRegion, 'asia-east1');
  expect(environment.usesBackendTransport, isTrue);
});

test('unknown transport fails closed', () {
  expect(
    () => FirebaseEnvironment.fromTransportValue('stagng'),
    throwsFormatException,
  );
});
```

- [ ] **Step 2: Verify RED**

Run: `flutter test test/firebase_environment_test.dart`

Expected: compilation failure for missing staging APIs.

- [ ] **Step 3: Implement strict environment selection**

Use this public shape:

```dart
const firebaseFunctionsRegion = 'asia-east1';

enum FirebaseEnvironmentMode { fake, emulator, staging }

static FirebaseEnvironment fromTransportValue(String value) => switch (value) {
  'fake' => const FirebaseEnvironment(mode: FirebaseEnvironmentMode.fake),
  'emulator' => localEmulator(),
  'staging' => staging(),
  _ => throw FormatException('Unsupported CHAT_TRANSPORT: $value'),
};

bool get usesBackendTransport => mode != FirebaseEnvironmentMode.fake;
```

Give every environment `functionsRegion: firebaseFunctionsRegion`. Make `fromDartDefine()` delegate to `fromTransportValue`.

- [ ] **Step 4: Replace region literals and provider special-case**

Use `firebaseFunctionsRegion` in `FirebaseFunctions.instanceFor`. Change `useBackendTransportProvider` to read `environment.usesBackendTransport`. Replace every Emulator test `us-central1` literal with the shared constant.

- [ ] **Step 5: Verify GREEN and drift absence**

Run:

```bash
flutter test test/firebase_environment_test.dart test/firebase_emulator_integration_test.dart
rg -n "us-central1|productionPlaceholder" lib test integration_test
```

Expected: tests PASS; `rg` returns no matches.

- [ ] **Step 6: Commit task**

```bash
git add lib/firebase lib/chat/presentation/chat_providers.dart test integration_test
git commit -m "refactor(firebase): define explicit staging environment"
```

---

### Task 3: Apple staging options and App Check dependency

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Create: `lib/firebase/firebase_options_staging.dart`
- Create: `test/firebase_staging_options_test.dart`

**Interfaces:**
- Produces: `StagingFirebaseOptions.currentPlatform` returning Apple `FirebaseOptions` for iOS/macOS.
- Consumers: Task 4 staging bootstrap.

- [ ] **Step 1: Write failing public-config contract test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_pet_mvp/firebase/firebase_options_staging.dart';

void main() {
  test('staging Apple options target registered Firebase app', () {
    final options = StagingFirebaseOptions.apple;
    expect(options.projectId, 'pet-digit-backend');
    expect(options.appId, '1:473616221902:ios:5613d495e3d6f07c3a729f');
    expect(options.messagingSenderId, '473616221902');
    expect(options.storageBucket, 'pet-digit-backend.firebasestorage.app');
    expect(options.iosBundleId, 'com.iyunghuang.petdigitchat');
  });
}
```

- [ ] **Step 2: Verify RED**

Run: `flutter test test/firebase_staging_options_test.dart`

Expected: compile failure because `firebase_options_staging.dart` does not exist.

- [ ] **Step 3: Add compatible Firebase App Check package**

Add this exact constraint to `pubspec.yaml`, then run `flutter pub get`:

```yaml
firebase_app_check: ^0.3.2+10
```

Expected: resolution stays on Firebase Core 3.x-compatible packages and updates
only required transitive dependencies.

- [ ] **Step 4: Implement staging options**

Create one Apple `FirebaseOptions` using Firebase app ID `1:473616221902:ios:5613d495e3d6f07c3a729f`, sender `473616221902`, project `pet-digit-backend`, bucket `pet-digit-backend.firebasestorage.app`, bundle ID `com.iyunghuang.petdigitchat`, and API key from Firebase `apps:sdkconfig`. `currentPlatform` accepts only iOS/macOS and throws `UnsupportedError` elsewhere until those Firebase apps are registered.

- [ ] **Step 5: Verify GREEN and secret boundary**

Run:

```bash
flutter test test/firebase_staging_options_test.dart
git diff --check
```

Expected: PASS. Confirm no service-account JSON, private key, debug token, or signing material appears in diff.

- [ ] **Step 6: Commit task**

```bash
git add pubspec.yaml pubspec.lock lib/firebase/firebase_options_staging.dart test/firebase_staging_options_test.dart
git commit -m "feat(firebase): add Apple staging configuration"
```

---

### Task 4: Debug-only App Check, Anonymous Auth, and root composition

**Files:**
- Create: `lib/firebase/firebase_bootstrap.dart`
- Create: `test/firebase_bootstrap_test.dart`
- Modify: `lib/firebase/firebase_environment.dart`
- Modify: `lib/main.dart`
- Modify: `lib/app.dart`
- Create: `test/app_test.dart`

**Interfaces:**
- Produces: `FirebaseBootstrapPolicy.validateAppCheckMode({required bool staging, required bool debugBuild})`, `ensureAnonymousFirebaseUser({required bool hasCurrentUser, required Future<void> Function() signInAnonymously})`, one initialized environment injected into Riverpod, `FirebaseStartupFailureApp`, and `FirebaseEnvironment.initialize()` staging sequence.
- Consumers: Task 5 reads resulting authenticated UID and membership state.

- [ ] **Step 1: Write failing policy and auth tests**

```dart
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

// test/app_test.dart
testWidgets('startup failure never renders fake chat', (tester) async {
  await tester.pumpWidget(
    const FirebaseStartupFailureApp(message: 'Firebase staging failed'),
  );
  expect(find.text('Firebase staging failed'), findsOneWidget);
  expect(find.text('Pixel Pals'), findsNothing);
});
```

- [ ] **Step 2: Verify RED**

Run: `flutter test test/firebase_bootstrap_test.dart test/app_test.dart`

Expected: compile failure for missing bootstrap APIs.

- [ ] **Step 3: Implement pure bootstrap policy**

Implement policy methods exactly as tested. Keep Firebase SDK calls outside pure policy helpers.

- [ ] **Step 4: Wire staging initialization**

For staging:

```dart
FirebaseBootstrapPolicy.validateAppCheckMode(
  staging: true,
  debugBuild: kDebugMode,
);
await Firebase.initializeApp(options: StagingFirebaseOptions.currentPlatform);
await FirebaseAppCheck.instance.activate(
  appleProvider: AppleProvider.debug,
);
await ensureAnonymousFirebaseUser(
  hasCurrentUser: FirebaseAuth.instance.currentUser != null,
  signInAnonymously: () async {
    await FirebaseAuth.instance.signInAnonymously();
  },
);
```

Keep Emulator initialization and emulator hooks unchanged. `main.dart` creates
and initializes one environment instance, then passes that exact instance to
`ChatPetApp(environment: environment)`. `ChatPetApp` overrides
`firebaseEnvironmentProvider` in its root `ProviderScope`; it must not create a
second environment. On startup failure, `main.dart` renders
`FirebaseStartupFailureApp(message: error.toString())` and never renders fake
chat.

- [ ] **Step 5: Verify GREEN**

Run:

```bash
flutter test test/firebase_bootstrap_test.dart test/firebase_environment_test.dart test/firebase_emulator_integration_test.dart test/app_test.dart
flutter analyze
```

Expected: PASS.

- [ ] **Step 6: Commit task**

```bash
git add lib/firebase lib/main.dart lib/app.dart test/firebase_bootstrap_test.dart test/app_test.dart
git commit -m "feat(firebase): bootstrap protected staging session"
```

---

### Task 5: Membership-gated staging room state machine

**Files:**
- Modify: `lib/chat/presentation/chat_providers.dart`
- Modify: `lib/chat/presentation/chat_shell.dart`
- Modify: `test/chat_riverpod_test.dart`
- Modify: `test/chat_shell_test.dart`

**Interfaces:**
- Consumes: authenticated `FirebaseAuth.currentUser`, `FirebaseEnvironment.usesBackendTransport`.
- Produces: `StagingMembershipStatus`, `roomMembershipProbeProvider`, and
  `stagingMembershipControllerProvider`; every staging room read, write, and
  background stream remains blocked until access probe succeeds.

Use these exact APIs:

```dart
enum StagingMembershipStatus { notRequired, waiting, checking, ready, denied }
typedef RoomMembershipProbe = Future<void> Function(String roomId);

class StagingMembershipController
    extends StateNotifier<StagingMembershipStatus> {
  StagingMembershipController({
    required StagingMembershipStatus initialState,
    required RoomMembershipProbe probe,
  });

  Future<bool> verify(String roomId);
}

final roomMembershipProbeProvider = Provider<RoomMembershipProbe>((ref) {
  final environment = ref.watch(firebaseEnvironmentProvider);
  if (environment.mode != FirebaseEnvironmentMode.staging) {
    return (_) async {};
  }
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  if (firestore == null || auth == null) {
    throw StateError('Staging Firebase providers are unavailable');
  }
  return (roomId) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('Staging user is not authenticated');
    final member = await firestore
        .doc('rooms/$roomId/members/$uid')
        .get();
    if (!member.exists || member.data()?['active'] != true) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Active room membership is required',
      );
    }
  };
});
final stagingMembershipControllerProvider = StateNotifierProvider<
    StagingMembershipController, StagingMembershipStatus>((ref) {
  final environment = ref.watch(firebaseEnvironmentProvider);
  return StagingMembershipController(
    initialState: environment.mode == FirebaseEnvironmentMode.staging
        ? StagingMembershipStatus.waiting
        : StagingMembershipStatus.notRequired,
    probe: ref.watch(roomMembershipProbeProvider),
  );
});
```

`verify()` returns `true` only after state becomes `ready`; all denied/error
paths return `false` after state becomes `denied`.

- [ ] **Step 1: Write failing lifecycle and gate tests**

Add tests for exact transitions:

```dart
expect(controller.state, StagingMembershipStatus.waiting);
final checking = controller.verify('friends');
expect(controller.state, StagingMembershipStatus.checking);
await checking;
expect(controller.state, StagingMembershipStatus.ready);
```

Override probe to throw `FirebaseException(plugin: 'cloud_firestore', code:
'permission-denied')` and verify `waiting → checking → denied`. Verify denied
state does not connect repository or invalidate room projection. Verify
`chatConnectionProvider`, `roomMessagesProvider`, `messageDeltaProvider`,
`messageConnectionStateProvider`, and `sendMessageProvider` cannot reach
Firebase repository while status is not `ready`.

- [ ] **Step 2: Verify RED**

Run: `flutter test test/chat_riverpod_test.dart`

Expected: compile failure because membership state/controller APIs do not exist.

- [ ] **Step 3: Implement membership state and access probe**

Add:

```dart
enum StagingMembershipStatus { notRequired, waiting, checking, ready, denied }

typedef RoomMembershipProbe = Future<void> Function(String roomId);
```

`roomMembershipProbeProvider` reads
`rooms/{roomId}/members/{currentUid}` through Firestore and succeeds only when
document exists with `active == true`. Controller starts `notRequired` outside
staging and `waiting` in staging. `verify()` sets `checking`, awaits probe, then
sets `ready`; `permission-denied`, missing, or inactive membership sets `denied`.
It never marks ready before proof.

- [ ] **Step 4: Gate all room-scoped providers**

Gate `chatConnectionProvider`, `roomMessagesProvider`, `messageDeltaProvider`,
`messageConnectionStateProvider`, and `sendMessageProvider`. Before `ready`, no
repository connect/send/watch call may occur. Use an empty delta stream and a
non-connected connection state while waiting. Do not invalidate or replace the
current room projection on denied access. Fake and Emulator bypass the gate via
`notRequired`.

Add one `_roomAccessAllowed(Ref ref)` helper that returns true for `ready` or
`notRequired`. When false, `sendMessageProvider` returns a function whose Future
completes with `StateError('Room membership is not ready')` before reading the
repository. Read/stream providers check the same helper before obtaining or
calling repository methods.

- [ ] **Step 5: Expose waiting/checking/denied UI**

In `ChatShell`, show staging-only states containing authenticated UID:

- `waiting`: administrator membership required, Retry enabled.
- `checking`: progress indicator, Retry disabled.
- `denied`: access not ready, Retry enabled.
- `ready`/`notRequired`: no membership banner.

Disable composer and attachment actions unless status is `ready` or
`notRequired`. Retry calls controller `verify(roomId)`; only successful
transition invalidates active room/connection providers. Denied transition
preserves current projection.

- [ ] **Step 6: Verify GREEN**

Run:

```bash
flutter test test/chat_riverpod_test.dart test/chat_shell_test.dart
flutter analyze
```

Expected: PASS; fake UI tests remain unchanged.

- [ ] **Step 7: Commit task**

```bash
git add lib/chat/presentation test/chat_riverpod_test.dart test/chat_shell_test.dart
git commit -m "feat(chat): gate staging room connection on membership"
```

---

### Task 6: Local verification, documentation, and review gate

**Files:**
- Modify: `README.md`
- Create: `docs/reports/2026-09-20-firebase-staging-client.md`

**Interfaces:**
- Consumes: Tasks 1–5 complete.
- Produces: reproducible staging launch instructions and evidence for Functions deployment gate.

- [ ] **Step 1: Document staging launch**

Document:

```bash
flutter run -d macos --dart-define=CHAT_TRANSPORT=staging
```

Include controlled App Check debug-token capture/registration, log cleanup, Anonymous UID capture, admin membership seed requirement, and explicit retry. State that Functions are not deployed by this frontend task.

- [ ] **Step 2: Run full automated gate**

Run:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
git diff --check
```

Expected: formatter clean, analyze clean, all tests PASS, diff check PASS.

- [ ] **Step 3: Build macOS debug staging app**

Run:

```bash
flutter build macos --debug --dart-define=CHAT_TRANSPORT=staging
```

Expected: build succeeds with bundle ID `com.iyunghuang.petdigitchat`.

- [ ] **Step 4: Run signed-development staging app**

Run:

```bash
flutter run -d macos --debug --dart-define=CHAT_TRANSPORT=staging
```

Expected: signed development app starts, does not show fake messages, reaches
membership `waiting`, displays Anonymous UID, and emits App Check debug token to
controlled local console. Stop app after capture; do not deploy Functions.

Verify signing identity:

```bash
codesign -dv --verbose=4 build/macos/Build/Products/Debug/chat_pet_mvp.app 2>&1
```

Expected: output includes `Authority=Apple Development:`. If absent, stop and
record signed native Auth/App Check verification as blocked; do not claim this
gate passed and do not deploy Functions.

- [ ] **Step 5: Perform security diff check**

Run:

```bash
rg -n "PRIVATE KEY|service_account|FIREBASE_APP_CHECK_DEBUG_TOKEN[[:space:]]*=" \
  lib macos ios android test integration_test
git status --short
```

Expected: `rg` returns no credential values; only scoped implementation/docs
changes appear in status.

- [ ] **Step 6: Request independent peer review**

Reviewer checks platform identifiers, strict environment selection, App Check debug guard, options safety, region consistency, membership gate, provider invalidation scope, tests, and absence of Functions deployment.

- [ ] **Step 7: Fix findings and rerun full gate**

Expected: reviewer verdict `APPROVE`; full automated gate remains green.

- [ ] **Step 8: Commit final report**

```bash
git add README.md docs/reports/2026-09-20-firebase-staging-client.md
git commit -m "docs(firebase): record staging client verification"
```

- [ ] **Step 9: Stop before external deployment**

Report branch commits, worktree status, Firebase Apple app registration, and exact remaining external sequence: launch debug build, register App Check debug token, capture Anonymous UID, seed active membership, then separately authorize Functions deployment.
