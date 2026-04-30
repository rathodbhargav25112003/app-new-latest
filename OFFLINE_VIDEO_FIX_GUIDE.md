# Offline Video Download Fix — Implementation Guide

## Summary of Bugs Fixed

### Bug 1: "All videos in topic show as downloaded" (or none show correctly)
**Root cause:** Every video list item used a `FutureBuilder` calling `_checkIfVideoDownloaded()` which made a **SQLite query + file existence check PER ITEM on EVERY widget rebuild**. During scrolling, setState, or any state change, this triggered N database queries simultaneously, causing:
- Stale/wrong results (futures completing out of order)
- Massive UI lag on screens with 20+ videos
- False positives/negatives depending on timing

**Fix:** Replaced with a cached `ObservableSet<String> downloadedVideoIds` in the MobX store. Loaded once when a screen mounts, updated instantly when downloads complete or are deleted. List items now use `Observer` + `store.isVideoDownloadedCached(titleId)` — zero DB queries during scrolling.

### Bug 2: App crashes/becomes very buggy during download
**Root cause:** The download stream listener updated MobX state (`setDownloadProgress`) on **every chunk received** — sometimes hundreds of times per second. Each update triggered Observer rebuilds across the widget tree, overwhelming the Flutter rendering pipeline.

**Fix:** Added `setDownloadProgressThrottled()` which only pushes updates to MobX observers every **500ms** (always fires at 0% and 100%). Download I/O still runs at full speed, only the UI notifications are throttled.

### Bug 3: Chapter detail downloads used generic filename + no encryption
**Root cause:** `video_chapter_detail.dart` saved downloads as `video_$quality.mp4` — the **same filename for every video**, so downloading a second video would overwrite the first. Also didn't encrypt (unlike `video_player_detail.dart` which uses AES-256-GCM).

**Fix:** Now uses unique filenames `video_{titleId}_{quality}.enc` with full encryption matching the player screen's pattern. Also added duplicate-download prevention (`if (store.isDownloading(titleId)) return`).

### Bug 4: Hardcoded `isDownloaded: false` across 7 navigation points
**Root cause:** When navigating to the video player, screens passed `'isDownloaded': false` regardless of actual download status:
- `video_chapter_detail.dart:750` (Content type navigation)
- `video_topic_category.dart:862`
- `video_category.dart:882`
- `video_subject_detail.dart:723`
- `continue_watching_screen.dart:602`

**Fix:** All now check `store.isVideoDownloadedCached(titleId)` to pass the correct value.

---

## Files Changed

### Core (must regenerate MobX codegen after changes):
1. **`lib/modules/videolectures/store/video_category_store.dart`** — Added:
   - `ObservableSet<String> downloadedVideoIds` — in-memory cache
   - `loadDownloadedIds(List<String> titleIds)` — batch DB load + file verify
   - `markDownloaded(titleId)` / `markNotDownloaded(titleId)` — instant updates
   - `isVideoDownloadedCached(titleId)` — O(1) lookup
   - `setDownloadProgressThrottled(titleId, progress)` — 500ms throttle
   - `_lastProgressUpdateMs` map for throttle timing
   - Added `import 'dart:io'` and `import '../../../helpers/dbhelper.dart'`

2. **`lib/modules/videolectures/store/video_category_store.g.dart`** — Updated generated MobX code for new observables + actions. **IMPORTANT: Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate this properly.** The manual edits will work but running codegen is the correct approach.

### Video list screens:
3. **`lib/modules/videolectures/video_chapter_detail.dart`** — Major changes:
   - `_getVideoList()` now calls `store.loadDownloadedIds(allIds)` after loading topics
   - Replaced both `FutureBuilder<bool>` (grid + list builders) with `Observer` using cached set
   - `_downloadVideo()` completely rewritten: unique filenames, encryption, throttled progress, `markDownloaded()` on complete, `markNotDownloaded()` on delete
   - Both delete handlers (dialog + bottom sheet) now call `store.markNotDownloaded(tid)`
   - Added imports: `offline_encryptor.dart`, `secure_keys.dart`
   - Navigation `isDownloaded: false` → `store.isVideoDownloadedCached()`

4. **`lib/modules/videolectures/video_player_detail.dart`** — Download progress now uses `setDownloadProgressThrottled()`, calls `markDownloaded()` after DB insert

5. **`lib/modules/videolectures/video_topic_category.dart`** — `isDownloaded: false` → `store.isVideoDownloadedCached()`

6. **`lib/modules/videolectures/video_category.dart`** — `isDownloaded: false` → `store.isVideoDownloadedCached()`

7. **`lib/modules/videolectures/video_subject_detail.dart`** — `isDownloaded: false` → `store.isVideoDownloadedCached()`

8. **`lib/modules/dashboard/continue_watching_screen.dart`** — `isDownloaded: false` → `store.isVideoDownloadedCached()` for video entries

---

## Build Steps

```bash
# 1. Regenerate MobX store code
cd app-update_fixes_merge
flutter pub run build_runner build --delete-conflicting-outputs

# 2. Verify no compile errors
flutter analyze

# 3. Build and test
flutter run
```

---

## Testing Checklist

### Download flow:
- [ ] Open a topic with 5+ videos
- [ ] Download one video — verify only THAT video shows green "Downloaded" checkmark
- [ ] Download a second video — verify first stays downloaded, second updates correctly
- [ ] During download: scroll the list up/down rapidly — app should NOT lag or crash
- [ ] During download: progress % should update smoothly (not flickering)
- [ ] Cancel/leave screen during download — return to see correct state

### Download status:
- [ ] Videos NOT downloaded show blue download icon
- [ ] Videos that ARE downloaded show green checkmark + "Downloaded" text
- [ ] After deleting a downloaded video, it immediately reverts to download icon
- [ ] Navigate to player from a downloaded video — player should detect offline file

### Encryption:
- [ ] Downloaded files are `.enc` not `.mp4` (check app documents directory)
- [ ] Encrypted videos play correctly when offline
- [ ] No leftover `.tmp.mp4` files after successful downloads

### Edge cases:
- [ ] Try downloading the same video twice — should be prevented (no duplicate)
- [ ] Download on slow network — progress should be smooth, no crash
- [ ] Kill app during download, reopen — no ghost "downloading" state
- [ ] Switch between WiFi and mobile data during download — should handle gracefully

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│ VideoCategoryStore (MobX)                           │
│                                                      │
│  downloadedVideoIds: ObservableSet<String>  ← cache │
│  downloadingVideos:  ObservableSet<String>           │
│  downloadProgressMap: ObservableMap<String,int>      │
│                                                      │
│  loadDownloadedIds() → batch DB + file verify        │
│  markDownloaded()    → instant set add               │
│  markNotDownloaded() → instant set remove            │
│  setDownloadProgressThrottled() → 500ms gate         │
└──────────────┬───────────────────┬──────────────────┘
               │                   │
    ┌──────────▼──────────┐  ┌─────▼──────────────────┐
    │ Video List Screen   │  │ Video Player Screen     │
    │ (chapter_detail)    │  │ (player_detail)         │
    │                     │  │                          │
    │ Observer per item   │  │ _downloadVideo()         │
    │ → cached lookup     │  │ → stream + encrypt       │
    │ → zero DB queries   │  │ → throttled progress     │
    │ → instant updates   │  │ → markDownloaded()       │
    └─────────────────────┘  └──────────────────────────┘
               │
    ┌──────────▼──────────┐
    │ SQLite (DbHelper)   │
    │ video_table          │
    │                      │
    │ Only queried on:     │
    │ - Screen mount       │
    │ - Download complete  │
    │ - Delete             │
    └──────────────────────┘
```
