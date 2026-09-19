# Phase 6: Media Hardening

## Goal

Close media-flow gaps after Phase 5: enforce size limits, synchronize handoff
documentation, and keep video playback behind a replaceable boundary.

## Scope

- Enforce 50 MiB media limit through `MediaPolicy`.
- Pass picked file size into validation.
- Add tests for oversized image/video rejection.
- Update handoff and media plan status.
- Preserve current preview fallback for fake URLs and unsupported platforms.

## Non-goals

- Backend media upload.
- Transcoding or thumbnail generation.
- Offline media cache.
- Changing message repository contracts.

## Acceptance

- [x] Oversized image rejected before draft creation.
- [x] Oversized video rejected before draft creation.
- [x] Valid media at or below limit accepted.
- [x] Existing test suite remains green.
- [x] Handoff reflects Phase 5 complete and Phase 6 hardening.

Phase 7 video playback is tracked separately in
`2026-09-19-chat-video-player.md`.
