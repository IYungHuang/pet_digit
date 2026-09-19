# Phase 5: Chat Media Picker, Preview & Validation Implementation Plan

Status: complete; size enforcement continued in Phase 6; real playback completed in Phase 7.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement native media picking via `image_picker`, comprehensive media format validation (`jpg`, `png`, `gif`, `webp`, `mp4`, `mov`), local and remote image preview rendering, and an interactive video player boundary modal, while preserving Riverpod architecture and pet overlay bubble interactions.

**Architecture:**
- `MediaPolicy` in domain layer owns format validation and MIME mapping.
- `MediaPickerService` in application layer abstracts image and video acquisition (`image_picker` default, fake/mock for tests).
- UI composer triggers picker, validates via `MediaPolicy`, and yields friendly non-blocking error feedback if invalid.
- Media message cards render local image previews (`File`), network/asset images, and video preview cards with duration badge.
- Image tap/preview action opens full image viewer; video tap/play action opens video player boundary modal.
- Pet bubble target bounds remain synchronized by `clientId`.

**Tech Stack:** Flutter, Dart, Riverpod, `image_picker`, Freezed domain models.

**Spec:** `docs/chat-message-architecture.md`, `docs/chat-room-ui-ux-spec.md`, `docs/handoff/chat-room-ui-handoff.md`.

---

### Task 1: Enhance MediaPolicy with file validation and MIME resolution

**Files:**
- Modify: `lib/chat/domain/media_policy.dart`
- Modify: `test/chat_message_domain_test.dart`

**Behavior:**
- Map extensions (`jpg`, `jpeg`, `png`, `gif`, `webp`, `mp4`, `mov`) to canonical MIME types (`image/jpeg`, `image/png`, `image/gif`, `image/webp`, `video/mp4`, `video/quicktime`).
- Add `MediaValidationResult` with `isValid`, `kind`, `mimeType`, `errorMessage`.
- Add `MediaPolicy.validate({required String path, String? mimeType, int? sizeBytes})`.
- Reject unsupported files (e.g. `.pdf`, `.txt`, `.mp3`) with clear error message.

- [x] **Step 1: Write failing unit tests for MediaPolicy validation**
- [x] **Step 2: Run tests and verify failure**
- [x] **Step 3: Implement validation and MIME resolution in MediaPolicy**
- [x] **Step 4: Run unit tests and verify success**

---

### Task 2: Implement MediaPickerService abstraction and Riverpod wiring

**Files:**
- Create: `lib/chat/application/media_picker_service.dart`
- Modify: `lib/chat/presentation/chat_providers.dart`
- Create: `test/media_picker_service_test.dart`

**Behavior:**
- Define `MediaPickerSource` (camera, gallery).
- Define `PickedMediaFile` (path, name, mimeType, kind, sizeBytes, durationMs).
- Define `MediaPickerService` interface (`pickImage`, `pickVideo`).
- Implement `NativeMediaPickerService` using `ImagePicker` with automatic `MediaPolicy` validation.
- Implement `FakeMediaPickerService` for controllable testing.
- Expose `mediaPickerServiceProvider` in `chat_providers.dart`.

- [x] **Step 1: Write failing tests for MediaPickerService**
- [x] **Step 2: Run tests and verify failure**
- [x] **Step 3: Implement MediaPickerService and provider**
- [x] **Step 4: Run tests and verify success**

---

### Task 3: Implement Image Preview Viewer & Video Player Boundary Modals

**Files:**
- Create: `lib/chat/presentation/widgets/media_preview_dialog.dart`
- Modify: `lib/chat/presentation/chat_shell.dart`

**Behavior:**
- Full-screen or dialog `ImagePreviewDialog`: displays local/remote image, filename, zoom/dismiss affordance.
- `VideoPlayerBoundaryDialog`: displays video title, format/MIME, local/remote path, duration, and real `video_player` controls for playable local/HTTP sources; fake or unavailable sources use explicit fallback.
- Ensure dialog presentation does not break pet world controller state.

- [x] **Step 1: Write widget tests for image preview and video player boundary dialogs**
- [x] **Step 2: Implement dialog widgets**
- [x] **Step 3: Run widget tests and verify pass**

---

### Task 4: Upgrade Chat Message Cards for rich media preview

**Files:**
- Modify: `lib/chat/presentation/chat_shell.dart`

**Behavior:**
- `_ImageMessageCard`: displays actual image when `localPath` exists (`Image.file`), or `Image.network`/`Image.asset`, with graceful fallback for fake URLs.
- `_VideoMessageCard`: displays video thumbnail/placeholder with play icon, video duration badge, and filename.
- Progress overlay during `uploading` status with percentage indicator.
- Tap play icon or preview button opens preview dialog.
- Bubble tap maintains pet interaction targeting (`_interact(message)`).

- [x] **Step 1: Update message card rendering in chat_shell.dart**
- [x] **Step 2: Verify pet bounds synchronization remains functional**
- [x] **Step 3: Run widget tests**

---

### Task 5: Upgrade Composer Attachment Flow with Native Picker & Validation

**Files:**
- Modify: `lib/chat/presentation/chat_shell.dart`
- Modify: `test/chat_shell_test.dart`

**Behavior:**
- Attachment action opens action sheet/dialog with options:
  - 🖼️ 相簿照片 (Photo Gallery)
  - 📷 拍照 (Take Photo)
  - 🎬 相簿影片 (Video Gallery)
  - 🎥 錄影 (Record Video)
  - 圖片（fake） & 影片（fake） (preserved for testing)
- Validates picked media via `MediaPolicy`.
- Shows `SnackBar` error on invalid format without clearing text field.
- Successfully picked media creates `MessageDraft` and triggers optimistic upload.

- [x] **Step 1: Add widget tests for attachment picker and validation error**
- [x] **Step 2: Implement composer attachment flow with MediaPickerService and SnackBar feedback**
- [x] **Step 3: Run all widget tests and verify pass**

---

### Task 6: Full Regression Verification & Documentation Update

**Files:**
- Modify: `docs/handoff/chat-room-ui-handoff.md`
- Run: `flutter test`
- Run: `flutter analyze`

- [x] **Step 1: Run full test suite and confirm all tests pass**
- [x] **Step 2: Run flutter analyze and confirm clean output**
- [x] **Step 3: Update docs/handoff/chat-room-ui-handoff.md with Phase 5 completion**
