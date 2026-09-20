# Firebase Staging Client Design

Date: 2026-09-20

## Goal

Connect the Flutter app to Firebase project `pet-digit-backend` as a safe,
explicit staging environment while preserving the current fake-first default
and local Emulator workflow.

## Identity and registered app

- Native package/bundle ID: `com.iyunghuang.petdigitchat`.
- Apply the ID to every macOS/iOS build configuration and test target.
- Update Android `namespace`, `applicationId`, `MainActivity.kt` package, and
  source path. No native project file may retain `com.example`.
- Registered staging Apple app:
  `1:473616221902:ios:5613d495e3d6f07c3a729f`.
- Configure macOS first. Register Android separately before Android staging
  testing; do not invent or reuse Apple credentials for Android.

Firebase API keys and app IDs are public SDK configuration, not server
secrets. Service-account keys, App Check debug tokens, and signing material
must never enter Git.

## Environment model

Replace `productionPlaceholder` with explicit `staging` mode.

| Mode | Selection | Transport | Firebase target |
| --- | --- | --- | --- |
| Fake | default | fake adapters | none |
| Emulator | `CHAT_TRANSPORT=emulator` | Firebase adapters | local demo project |
| Staging | `CHAT_TRANSPORT=staging` | Firebase adapters | `pet-digit-backend` |

Both Emulator and staging use Functions region `asia-east1`. Fake remains the
default so ordinary UI development cannot accidentally consume Blaze resources.
Only `fake`, `emulator`, and `staging` are accepted transport values. Unknown or
misspelled values fail startup instead of silently selecting fake data.

## Bootstrap order

Staging startup runs in this order:

1. Initialize Firebase with checked-in staging Apple SDK options.
2. Activate Firebase App Check using the debug provider on macOS staging.
3. Reuse the current Firebase Auth user or sign in anonymously once.
4. Build Riverpod Firebase adapters for Auth, Firestore, Storage, and Functions.
5. Expose the authenticated UID and enter a waiting-for-membership state.
6. After an administrator seeds active membership, connect or explicitly retry
   the active room.

Initialization errors stop staging composition and surface a clear startup
error. Staging must never silently fall back to fake data.

## App Check boundary

- Backend staging keeps `APP_CHECK_MODE=enforce`.
- macOS staging uses the App Check debug provider only when `kDebugMode` is
  true. Profile or release builds selecting this provider fail closed.
- The provider emits its token once to a controlled local debug console so it
  can be registered manually in Firebase Console. Do not retain that output in
  CI logs, shared logs, documentation, or Git; clear captured output after
  registration.
- iOS production later uses App Attest with DeviceCheck fallback.
- Android production later uses Play Integrity.
- Functions deployment waits until the staging provider is active and its debug
  token is registered. Rejection and success paths are proven immediately after
  Functions deployment.

## Authentication and membership

Staging uses Firebase Anonymous Auth. Authentication establishes user identity;
it does not grant room access.

For smoke testing, an administrator creates:

```text
rooms/{roomId}
rooms/{roomId}/members/{uid}  active: true
```

The Flutter client cannot create or elevate membership. Product invite and
household membership flows remain future backend work.

## Configuration ownership

- Flutter and backend each own an `asia-east1` region constant; contract tests
  and staging smoke tests prevent cross-repository drift.
- `FirebaseEnvironment` owns mode, project, region, emulator hosts, and startup.
- Riverpod composition asks the environment whether Firebase transport is active;
  it does not special-case only Emulator mode.
- Generated/public Firebase options live in a staging-specific Dart file.
- App Check token registration remains external Firebase Console state.

## Testing and gates

Use TDD for runtime behavior:

- Environment tests: staging selection, project ID, region, backend transport.
- Bootstrap tests: anonymous sign-in only when no user exists.
- Static contract test: approved native package IDs and no `us-central1` drift.
- Static contract test: no native project identifier retains `com.example`.
- Existing Emulator tests: Firebase adapters and local bypass remain green.
- Full `flutter analyze` and `flutter test`.
- Build and run signed macOS staging app.
- After Functions deployment, confirm a client with missing or invalid App Check
  is rejected, then confirm the registered debug-token client succeeds.
- Create controlled room/member fixture and run text plus media smoke tests.
- Peer review and repository Git commit gate before merge.

## Deployment sequence

1. Implement and verify Flutter staging composition.
2. Register macOS App Check debug token.
3. Deploy backend Functions to staging only.
4. Call public `healthCheck`; confirm invalid/missing App Check is rejected by
   protected callable Functions.
5. Capture authenticated UID and seed one controlled room plus active membership.
6. Explicitly connect or retry the room, then confirm valid App Check requests
   reach authenticated callable Functions.
7. Verify text, image, video, delta synchronization, and tombstone behavior.

No production Firebase project, public room join, FCM, transcoding, CDN, or
Redis work belongs to this migration.
