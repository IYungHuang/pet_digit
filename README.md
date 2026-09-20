# Chat Pet MVP

Flutter prototype: modern local chat UI with a small 8-bit pet living inside the conversation.

## Run

Prerequisites: Flutter 3.x with macOS, iOS, or Android toolchain.

```bash
flutter pub get
flutter run -d macos
```

Firebase transport stays fake by default. Firebase packages are included, but
no production Firebase options or project credentials are committed.

### Firebase Emulator mode

Start backend emulators first:

```bash
cd /Users/appgongyong/Documents/Codex/2026-09-18/pet_digit_backend
npm run emulator
```

Ports come from backend `firebase.json`: Auth `9099`, Firestore `8080`,
Storage `9199`, Functions `5001`, Emulator UI `4000`. Run app with:

```bash
flutter run -d macos --dart-define=CHAT_TRANSPORT=emulator
```

Environment modes: `fake` (default), `emulator`, and `staging`. Unknown
`CHAT_TRANSPORT` values fail startup.

### Firebase staging mode

Staging connects native macOS/iOS debug builds to the real `pet-digit-backend`
project (`asia-east1` Functions) with Anonymous Auth and App Check debug
attestation. It never deploys or touches Cloud Functions.

```bash
flutter run -d macos --dart-define=CHAT_TRANSPORT=staging
```

App Check debug provider only activates in `kDebugMode`; a profile/release
staging build fails closed instead of silently falling back to fake.

1. Launch the command above. On first run, `FirebaseAppCheck` prints a debug
   token to the local console — copy it and register it as a debug token for
   this app in the Firebase console (App Check → Apps → Manage debug tokens).
   Treat the token as a secret: never commit it, never paste it into a shared
   log. Clear it from your terminal scrollback once registered.
2. The app signs in anonymously and shows the resulting Firebase UID in a
   membership banner (`waiting` state) — capture that UID.
3. Client code cannot create or elevate room membership. An administrator
   must seed an active membership document at
   `rooms/{roomId}/members/{uid}` with `active: true` for the captured UID
   before the room becomes readable.
4. Once membership is seeded, press **Retry** in the banner. Only a
   successful retry connects the room; a denied retry preserves whatever
   projection was already on screen.

This task never deploys Functions. Deployment is a separate, explicitly
authorized step.

Fake/unit tests:

```bash
flutter analyze
flutter test
git diff --check
```

Native emulator integration test requires a signed macOS development target
with Firebase Keychain access. Standard driver command:

```bash
FIREBASE_EMULATOR_TEST=1 flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/firebase_emulator_test.dart \
  -d macos
```

It uses only local emulator hosts and a local-only FirebaseOptions placeholder.

For mobile, list devices with `flutter devices`, then run `flutter run -d <device-id>`.

## MVP interactions

- **切換聊天室**：頂部 Chip 可切換聊天室，重置寵物位置與世界物件。
- **訊息泡泡平台跳躍（如參考影片）**：點擊任一文字訊息泡泡，柯基會以平滑拋物線（Parabolic Jump Arc）跳躍並站上該泡泡頂端，並可在泡泡上巡邏與休息。
- **滾動 Emoji 追逐（如參考影片）**：點擊 Emoji 訊息，Emoji 會具備重力與反彈物理滾動彈跳，柯基會衝刺（Sprint）追趕並留下揚塵（Dust Puffs）粒子，追上後觸發撲玩。
- **GIF 專注互動（如參考影片）**：點擊 GIF 訊息，柯基會抬頭專注注視、豎耳擺尾並升起愛心粒子，接著跑向 GIF 並跳起將前爪搭在訊息卡下緣。

## Structure

```text
lib/
  app.dart                         Material app entry
  chat/
    data/fake_chat_repository.dart Local rooms and messages
    domain/chat_models.dart         Chat entities and world coordinates
    presentation/chat_shell.dart   Room selector, bubble geometry sync & message UI
  pet/
    domain/pet_world.dart           PetInteractable and world objects
    domain/pet_world_controller.dart State machine, continuous trajectories & behavior sequences
    domain/pet_effects.dart         Particles (dust, heart) and BouncingEmojiToy physics
    presentation/pixel_pet.dart     Pet wrapper widget with direction & frames
    presentation/pixel_pet_sprite.dart 8-bit Corgi sprite renderer (nearest-neighbor)
    presentation/pet_world_overlay.dart Overlay ticker, particles & toy rendering
assets/
  pets/                            Corgi sprite sheet and frame assets
test/
  chat_domain_test.dart
  pet_world_test.dart
  chat_shell_test.dart
  pixel_pet_sprite_test.dart
```

`ChatShell` knows chat presentation. `PetWorldOverlay` knows pet presentation. `PetWorldController` is the bridge and can later be replaced or extended without changing message rendering.

## Next extensions

- Replace rectangle painter with sprite-sheet or pixel-art assets.
- Add collision-aware platform coordinates from rendered message layout.
- Persist rooms and pet state behind `ChatRepository`.
- Add richer behavior tree for approach, watch, jump, and pounce sequences.
