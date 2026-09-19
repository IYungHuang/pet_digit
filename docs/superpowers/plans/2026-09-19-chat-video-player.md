# Phase 7: Real Video Playback

Status: complete

## Goal

Replace simulated video controls with a real, replaceable `video_player`
boundary while keeping fake/demo media safe in tests and desktop preview flows.

## Scope

- Add `video_player` dependency.
- Play valid local files selected by native picker.
- Play HTTP/HTTPS sources.
- Expose play/pause, seek, duration, and playback state.
- Show explicit fallback for fake paths, unsupported schemes, and initialization
  failures.

## Acceptance

- [x] Local and HTTP/HTTPS controllers are created only for valid sources.
- [x] Playback dialog owns controller lifecycle and disposes it on close.
- [x] Fake test source remains deterministic and renders fallback.
- [x] Existing image/video card flow remains unchanged.
- [x] `flutter analyze` passes.
- [x] Full `flutter test` passes.

## Next phase

Implement Dio/WebSocket adapters behind current repository/data-source seams;
do not move transport dependencies into domain models or widgets.
