# Chat Pet MVP

Flutter prototype: modern local chat UI with a small 8-bit pet living inside the conversation.

## Run

Prerequisites: Flutter 3.x with macOS, iOS, or Android toolchain.

```bash
flutter pub get
flutter run -d macos
```

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
