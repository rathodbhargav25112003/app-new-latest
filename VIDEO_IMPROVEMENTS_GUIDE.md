# Video Experience — Complete Improvements Guide

## Overview

18 improvements across offline downloads, video playback, cross-platform compatibility, and security. This guide covers every change for the frontend dev to review, test, and complete remaining MobX codegen.

---

## 1. Bugs Fixed

### 1.1 "All videos show as downloaded" (false positives)
- **Root cause:** `FutureBuilder` per list item → N SQLite queries per rebuild, stale results
- **Fix:** In-memory `ObservableSet<String> downloadedVideoIds` in MobX store. Loaded once on screen mount, updated instantly on download/delete.
- **Files:** `video_category_store.dart`, `video_category_store.g.dart`, `video_chapter_detail.dart`

### 1.2 App crashes during download
- **Root cause:** MobX `setDownloadProgress()` fired on every HTTP chunk (hundreds/sec)
- **Fix:** `setDownloadProgressThrottled()` — updates UI every 500ms max; always fires at 0% and 100%
- **File:** `video_category_store.dart`

### 1.3 Downloads overwrite each other
- **Root cause:** Generic filename `video_$quality.mp4` for all videos
- **Fix:** Unique filenames `video_{titleId}_{quality}.enc`
- **File:** `video_chapter_detail.dart`

### 1.4 No encryption on chapter_detail downloads
- **Root cause:** Only `video_player_detail.dart` encrypted; `video_chapter_detail.dart` saved plaintext
- **Fix:** Added AES-256-GCM encryption matching player screen pattern
- **File:** `video_chapter_detail.dart`

### 1.5 `isDownloaded: false` hardcoded across 5 navigation points
- **Files fixed:** `video_chapter_detail.dart`, `video_topic_category.dart`, `video_category.dart`, `video_subject_detail.dart`, `continue_watching_screen.dart`
- **Fix:** All now use `store.isVideoDownloadedCached(titleId)`

### 1.6 Sort-in-itemBuilder infinite rebuild loop
- **Root cause:** Sort inside itemBuilder → triggers rebuild → sort again → infinite loop
- **Fix:** Moved sort logic into `_filterVideos()` method
- **File:** `video_chapter_detail.dart`

---

## 2. New Features

### 2.1 Download Queue Service (`lib/services/download_service.dart`) — NEW FILE
Singleton download manager ensuring smooth multi-video downloads:
- **One-at-a-time queue** — prevents bandwidth saturation and memory spikes
- **HTTP Range resume** — interrupted downloads continue from last byte
- **WiFi-only mode** — persisted via SharedPreferences, auto-pauses on cellular
- **AES-256-GCM encryption** — encrypts immediately after download, deletes temp file
- **Space check** — sanity check before starting
- **Temp cleanup** — clears leftover `.tmp.mp4` files on app start
- **Callbacks:** `onTaskUpdated`, `onTaskCompleted`, `onTaskFailed`, `onQueueChanged`
- **Task states:** queued → downloading → encrypting → completed (or failed/paused/cancelled)

Key APIs:
```dart
DownloadService.instance.enqueue(titleId: ..., url: ..., quality: ..., title: ...);
DownloadService.instance.enqueueMultiple(List<Map<String, String>> videos);
DownloadService.instance.cancel(titleId);
DownloadService.instance.pauseActive();
DownloadService.instance.resumePaused(titleId);
DownloadService.instance.getStorageInfo(); // → {totalMB, fileCount, formatted}
DownloadService.instance.deleteAllDownloads();
```

### 2.2 Download Manager Sheet (`lib/modules/videolectures/widgets/download_manager_sheet.dart`) — NEW FILE
Bottom sheet UI showing:
- Active download with animated progress bar
- "Encrypting..." status indicator
- Queued items with position numbers
- Failed items with retry button
- Completed items with file sizes
- Storage usage bar (count + total size)
- WiFi-only toggle switch
- "Clear All" with confirmation dialog
- Auto-refresh every 1 second

Usage: `DownloadManagerSheet.show(context);`

### 2.3 "Download All" Button (topic level)
- Added in `video_chapter_detail.dart` header row
- Shows when not all videos are downloaded
- Uses `DownloadService.enqueueMultiple()` to queue all undownloaded videos
- Picks optimal quality per video (540p preferred, falls back to 360p or first available)
- Opens Download Manager sheet after queuing
- "X offline" badge shows count of downloaded videos

### 2.4 Auto Quality Selection
- WiFi → 720p, Mobile data → 360p, Unknown → 540p
- Applied on first load, user can still manually change
- **File:** `video_player_detail.dart` → `_autoSelectQuality()`

### 2.5 Playback Speed Persistence
- Speed saved to SharedPreferences on change
- Restored on next video open via `_loadSavedPlaybackSpeed()`
- **File:** `video_player_detail.dart`

### 2.6 Error Retry UI
- Replaced useless `Text("errorMessage")` with actionable retry UI
- "Retry" button reloads same quality, "Try Lower Quality" drops to next tier
- **File:** `video_player_detail.dart`

### 2.7 Fixed Video Cache Key
- Was: `DateTime.now().toString()` — never caches, always reloads
- Now: `'${widget.titleId}_$_selectedQuality'` — proper cache hit on revisit
- **File:** `video_player_detail.dart`

### 2.8 WillPopScope → PopScope Migration
- Replaced deprecated `WillPopScope` with `PopScope(canPop: true, onPopInvokedWithResult: ...)`
- **File:** `video_player_detail.dart`

---

## 3. Security Improvements

### 3.1 Vimeo Token Removed from Client
**CRITICAL:** The Vimeo API token was hardcoded in two files:
- `video_player_detail.dart` line 134: `'1e289a70eeb453f30380ce3d00f80256'`
- `custom_macos_player.dart` line 22: `'1e289a70eeb453f30380ce3d00f80256'`

Flutter apps are decompilable — anyone can extract this token.

**Fix:** Server-side proxy at `GET /api/video/vimeo-url/:vimeoId`:
- API receives vimeoId, calls Vimeo API with server-side `process.env.VIMEO_ACCESS_TOKEN`
- Returns best quality progressive URL to client
- Client never sees the Vimeo token

**Files changed:**
- `video_player_detail.dart` → `_fetchVideoUrl()` now calls `$baseUrl/video/vimeo-url/$vimeoId`
- `custom_macos_player.dart` → Same proxy approach
- `api/src/controllers/video.controller.js` → New `getVimeoUrl` endpoint
- `api/src/routes/video.route.js` → Route registered

**IMPORTANT:** Set `VIMEO_ACCESS_TOKEN` in your server environment variables.

---

## 4. Cross-Platform Video Compatibility

### BunnyCDN (new) + Vimeo (legacy)
- **Android/iOS:** BetterPlayer handles HLS (`.m3u8`) and MP4 natively
- **macOS/Windows:** FlickManager + video_player for Vimeo progressive MP4 via server proxy
- **HLS from BunnyCDN:** Works out of the box on mobile; desktop uses MP4 fallback
- **Quality selection:** User picks from available qualities (BunnyCDN provides multiple renditions)

### Provider routing logic:
1. If video has `hlsLink` (BunnyCDN) → use BetterPlayer with HLS
2. If video has Vimeo URL → extract Vimeo ID → use server proxy for progressive MP4
3. Offline → use encrypted local file with AES-256-GCM decryption

---

## 5. All Changed Files

### New Files
| File | Purpose |
|------|---------|
| `lib/services/download_service.dart` | Download queue manager (singleton) |
| `lib/modules/videolectures/widgets/download_manager_sheet.dart` | Download progress UI |
| `VIDEO_IMPROVEMENTS_GUIDE.md` | This guide |

### Modified — Core Store
| File | Changes |
|------|---------|
| `lib/modules/videolectures/store/video_category_store.dart` | `downloadedVideoIds` ObservableSet, `loadDownloadedIds()`, `markDownloaded()`, `markNotDownloaded()`, `isVideoDownloadedCached()`, `setDownloadProgressThrottled()` |
| `lib/modules/videolectures/store/video_category_store.g.dart` | MobX codegen for new observables/actions — **MUST REGENERATE** |

### Modified — Screens
| File | Changes |
|------|---------|
| `lib/modules/videolectures/video_chapter_detail.dart` | Download All button, DownloadManager icon, offline count badge, `_downloadAllVideos()`, encrypted downloads, Observer-based status, fixed sort loop |
| `lib/modules/videolectures/video_player_detail.dart` | Auto quality, speed persistence, error retry UI, cache key fix, Vimeo proxy, PopScope, throttled progress |
| `lib/modules/videolectures/custom_macos_player.dart` | Vimeo proxy (removed hardcoded token) |
| `lib/modules/videolectures/video_topic_category.dart` | `isDownloaded` fix |
| `lib/modules/videolectures/video_category.dart` | `isDownloaded` fix |
| `lib/modules/videolectures/video_subject_detail.dart` | `isDownloaded` fix |
| `lib/modules/dashboard/continue_watching_screen.dart` | `isDownloaded` fix |

### Modified — App Entry
| File | Changes |
|------|---------|
| `lib/main.dart` | `DownloadService.instance.init()` on startup |

### Modified — API
| File | Changes |
|------|---------|
| `api/src/controllers/video.controller.js` | `getVimeoUrl` endpoint |
| `api/src/routes/video.route.js` | `GET /api/video/vimeo-url/:vimeoId` route |

---

## 6. Build Steps

```bash
# 1. CRITICAL — Regenerate MobX store code
cd app-update_fixes_merge
flutter pub run build_runner build --delete-conflicting-outputs

# 2. Verify compilation
flutter analyze

# 3. Ensure packages are installed
flutter pub get

# 4. Run
flutter run
```

### API deployment:
```bash
# Ensure VIMEO_ACCESS_TOKEN is set in .env
cd api-ruchir-optimization
npm run deploy  # or your deployment command
```

---

## 7. Testing Checklist

### Download Queue
- [ ] Download one video → verify progress bar, encryption, green checkmark on complete
- [ ] Tap "Download All" → verify all undownloaded videos queued
- [ ] Open Download Manager sheet → verify active, queued, completed sections
- [ ] During download: scroll video list rapidly → no lag or crash
- [ ] Kill app mid-download → reopen → no ghost "downloading" state, temp files cleaned
- [ ] Toggle WiFi-only ON → switch to mobile data → download should pause
- [ ] Failed download → tap retry → should resume

### Download Status
- [ ] Only downloaded videos show green checkmark (not all)
- [ ] Delete a download → immediately reverts to download icon
- [ ] Navigate away and back → status persists correctly
- [ ] "X offline" badge updates in real-time

### Video Playback
- [ ] BunnyCDN HLS video plays on Android/iOS
- [ ] BunnyCDN MP4 plays on all platforms
- [ ] Vimeo video plays on desktop (macOS/Windows) via server proxy
- [ ] Offline encrypted video plays after decryption
- [ ] Quality auto-selected: WiFi=720p, Mobile=360p
- [ ] Playback speed persists across videos
- [ ] Error → retry button works, "Try Lower Quality" drops quality tier

### Cross-Platform
- [ ] Android: HLS + MP4 + offline
- [ ] iOS: HLS + MP4 + offline
- [ ] macOS: Vimeo proxy + MP4
- [ ] Windows: Vimeo proxy + MP4

### Security
- [ ] `VIMEO_ACCESS_TOKEN` is NOT in any client code (search codebase for the old token)
- [ ] Server proxy returns valid Vimeo URL
- [ ] Downloaded files are `.enc` not `.mp4`

---

## 8. Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ DownloadService (singleton)                                  │
│                                                              │
│  Queue<DownloadTask>    ← one active, rest wait             │
│  _downloadAndEncrypt()  ← HTTP stream → temp → AES → .enc  │
│  wifiOnly toggle        ← persisted SharedPreferences       │
│  HTTP Range resume      ← continues interrupted downloads   │
│                                                              │
│  Callbacks → UI updates                                      │
└────────────┬────────────────────────────────────────────────┘
             │
┌────────────▼────────────────────────────────────────────────┐
│ VideoCategoryStore (MobX)                                    │
│                                                              │
│  downloadedVideoIds: ObservableSet<String>   ← O(1) lookup  │
│  downloadProgressMap: ObservableMap<String,int>               │
│  downloadingVideos: ObservableSet<String>                     │
│                                                              │
│  loadDownloadedIds()      → batch DB + file verify           │
│  markDownloaded()         → instant set add                  │
│  markNotDownloaded()      → instant set remove               │
│  setDownloadProgressThrottled() → 500ms gate                 │
└────────────┬──────────────┬─────────────────────────────────┘
             │              │
  ┌──────────▼────────┐  ┌─▼──────────────────────┐
  │ Chapter Detail     │  │ Video Player Detail     │
  │                    │  │                          │
  │ Observer per item  │  │ BetterPlayer (mobile)    │
  │ Download All btn   │  │ FlickManager (desktop)   │
  │ Manager sheet      │  │ Auto quality + speed     │
  │ Offline badge      │  │ Error retry UI           │
  └────────────────────┘  └──────────────────────────┘
             │
  ┌──────────▼────────┐     ┌──────────────────────┐
  │ SQLite (DbHelper) │     │ Server Proxy          │
  │ video_table        │     │ /api/video/vimeo-url  │
  │                    │     │ → Vimeo API            │
  │ Queried only on:   │     │ → Returns best URL     │
  │ - Screen mount     │     │ → Token stays server   │
  │ - Download done    │     └──────────────────────┘
  │ - Delete           │
  └─────────��──────────┘
```
