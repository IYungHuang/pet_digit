# Chat Pet MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a runnable Flutter prototype where a pixel-art pet inhabits local fake chat rooms and reacts to chat content.

**Architecture:** Keep fake chat/domain data separate from Flutter presentation. Render a normal chat list below a `PetWorldOverlay`; drive pet behavior through `PetWorldController` and `PetInteractable` objects.

**Tech Stack:** Flutter SDK, Dart, `CustomPainter`, `AnimationController`, Flutter test package. No third-party dependency.

**Spec:** `docs/superpowers/specs/2026-09-18-chat-pet-mvp-design.md`

## Global Constraints

- Local fake data only; no backend, login, LLM, or networking.
- macOS, iOS, and Android-compatible Flutter widgets.
- No external image assets required for prototype.
- Chat UI and pet/game overlay remain separate.
- Domain behavior remains unit-testable without Flutter rendering.

---

### Task 1: Scaffold project and domain model

**Files:**
- Create: `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`
- Create: `lib/chat/domain/chat_models.dart`
- Create: `lib/chat/data/fake_chat_repository.dart`
- Test: `test/chat_domain_test.dart`

**Interfaces:**
- `ChatRoom`, `ChatMessage`, `MessageKind`.
- `FakeChatRepository.rooms` and `roomById(String id)`.

- [ ] Write failing tests for fake rooms and message kinds.
- [ ] Run `flutter test test/chat_domain_test.dart`; expect missing-library failure.
- [ ] Add minimal Flutter scaffold and domain models.
- [ ] Run focused test; expect pass.

### Task 2: Add pet world abstractions and state machine

**Files:**
- Create: `lib/pet/domain/pet_world.dart`
- Create: `lib/pet/domain/pet_world_controller.dart`
- Test: `test/pet_world_test.dart`

**Interfaces:**
- `PetState { idle, walk, run, jump, observe, pounce }`.
- `PetInteractable` with `id`, `kind`, `position`, `interactionFor(PetEvent event)`.
- `WorldObjectKind { platform, emojiToy, animatedToy }`.
- `PetWorldController.loadRoom(ChatRoom)`, `tick(Duration)`, `interact(String objectId)`.

- [ ] Write failing tests for platform discovery, emoji reaction, GIF reaction, and room reset.
- [ ] Run focused test; expect failure before implementation.
- [ ] Implement abstractions and deterministic controller.
- [ ] Run focused test; expect pass.

### Task 3: Build chat UI and room switching

**Files:**
- Create: `lib/chat/presentation/chat_shell.dart`
- Modify: `lib/app.dart`
- Test: `test/chat_shell_test.dart`

- [ ] Write widget test for room title, messages, and room switch action.
- [ ] Run test; expect failure before widgets exist.
- [ ] Implement responsive Material chat shell with room selector and message cards.
- [ ] Run widget test; expect pass.

### Task 4: Build pet overlay and pixel-art painter

**Files:**
- Create: `lib/pet/presentation/pet_world_overlay.dart`
- Create: `lib/pet/presentation/pixel_pet.dart`
- Modify: `lib/chat/presentation/chat_shell.dart`

- [ ] Add periodic controller ticks through `AnimationController`.
- [ ] Paint small 8-bit corgi from rectangles, with state-dependent pose.
- [ ] Position overlay over message list and make emoji/GIF objects tappable.
- [ ] Verify room switching reloads overlay world.

### Task 5: Documentation and verification

**Files:**
- Create: `README.md`

- [ ] Document prerequisites, `flutter pub get`, `flutter run -d macos`, mobile run commands, architecture, and extension points.
- [ ] Run `dart format .`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Review acceptance criteria against implementation and report any gap.
