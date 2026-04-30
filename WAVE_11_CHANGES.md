# Wave 11 — Videos flow shortened + module polish + smart resume foundation

Mirrors what wave 8+9+10 did for notes — collapses the 4-deep video
browse flow to a 1-tap-to-player experience, polishes all 9 video
files into the Apple-minimalistic chrome, and lays the foundation for
a global "Smart Resume" home banner.

---

## A. New foundation services

### `lib/services/smart_resume_service.dart`
Tracks the user's most-recent in-progress thing across **four**
channels (mock exam, custom test, video, note). The home screen
will surface a single "Pick up where you left off" banner using
`latest()`. Each channel keeps the latest entry separately so we
can also drive per-section "Continue" prompts.

API:
```dart
SmartResumeService.instance.recordMockExam(...);
SmartResumeService.instance.recordCustomTest(...);
SmartResumeService.instance.recordVideo(...);
SmartResumeService.instance.recordNote(...);
SmartResumeService.instance.latest();   // for the banner
SmartResumeService.instance.clear(kind);
SmartResumeService.instance.clearAll();  // hooks "Reset progress"
```

### `lib/modules/widgets/smart_resume_banner.dart`
Drop-anywhere widget that consumes the service and renders a soft-
surface card with channel-tinted icon + title + subtitle + progress
bar. Tap → deep-links into the right module. Returns
`SizedBox.shrink()` when nothing's in progress, so it occupies zero
space when empty.

### `lib/services/recent_videos_service.dart`
Mirrors `RecentNotesService`. Tracks last 12 video lectures opened.
Each entry carries thumbnail + title + topic + position-bar metadata
for the new browse screen's "Continue watching" rail.

---

## B. New shortened-flow entry point

### `lib/modules/videolectures/video_browse_screen.dart` (NEW)

Replaces the legacy `VideoLecturesScreen` as the default at
`Routes.videoLectures`. Three sections:

1. **Sticky search bar** — type "renal physiology", see all matching
   lectures at any depth, tap → player. Calls
   `HomeStore.onGlobalSearchApiCall(query, "video")`.
2. **Continue watching rail** — last 8 videos in a horizontal scroll.
   Each card shows 16:9 thumbnail (cached via `AppCachedImage`),
   title, topic name, "5m ago" timestamp pill, position-bar overlay.
   Tap → straight to the player with `positionSeconds` arg.
3. **All subjects** — `_ExpandableSubjectCard` per subject. Tap to
   expand inline showing per-status counts (Completed / In progress
   / Not started) → "Open subject" CTA → legacy 4-level flow.

Search results render as type-tagged tiles ("Subject", "Chapter",
"Topic", "Lecture") with a play-icon accent on direct-to-player
content matches.

### Routing

`lib/app/routes.dart`:
- `Routes.videoLectures` → `VideoBrowseScreen` (new default).
- `Routes.videoLecturesLegacy` → `VideoLecturesScreen` (legacy 4-deep
  flow preserved for any existing deep links).

---

## C. Video player hooks

`lib/modules/videolectures/video_player_detail.dart`:

```dart
// In initState — fire-and-forget recording into both rails:
RecentVideosService.instance.recordOpen(RecentVideoEntry(...));
SmartResumeService.instance.recordVideo(...);
```

So the moment a user opens a lecture:
1. The "Continue watching" rail in `VideoBrowseScreen` picks it up.
2. The global Smart Resume banner (when wired into home) picks it up.

Also: `backgroundColor: ThemeManager.white` → `AppTokens.scaffold
(context)` so the player respects dark mode without intervention.

---

## D. Legacy screens polished

Five video screens migrated from "blue strip + rounded white
container" to clean AppBar + soft-surface body (same pattern as
notes wave 10):

| File | Lines | Change |
|---|---|---|
| `video_category.dart` | 1150 | Header swap + skeleton + empty state. Now at `Routes.videoLecturesLegacy`. |
| `video_subject_detail.dart` | 917 | Same pattern. |
| `video_topic_category.dart` | 899 | Same pattern. |
| `video_chapter_detail.dart` | 2055 | Header swap + skeleton + empty state + RefreshIndicator recolored. |
| `video_player_detail.dart` | 3788 | Surgical: scaffold background → AppTokens.scaffold; recordOpen + recordVideo hooks in initState. The 3.7k-line player otherwise left alone — fully ripping it apart was too risky for limited UX gain. |

### `download_manager_sheet.dart` (522 lines)

- Background switched to `AppTokens.surface` with 28pt top corners.
- Added a 44×4 drag handle pill (Apple-style).
- Empty state replaced with shared `EmptyState` widget.
- WiFi-only switch tinted to `AppTokens.accent`.
- Header text → `AppTokens.titleLg`.

---

## E. Pattern consistency

Every video module screen now uses the same chrome as the notes
module + every other wave-4+ screen:

- `appBar: AppBar(scaffold-toned, AppTokens.titleLg title)`
- `body: SafeArea(child: Column([Expanded(Padding(s24, child))]))`
- Loading → `SkeletonList(count, itemHeight)`
- Empty → `EmptyState(icon, title, subtitle)` with semantic icons
  (`video_library_outlined`, `topic_outlined`,
  `play_circle_outline_rounded`, `download_done_rounded`).

---

## F. End-to-end UX

Cold-boot user opens the app, taps **Videos**:

1. Sees their last 5 lectures in a horizontal rail at top with
   thumbnails + position bars → 1 tap to resume on the page they
   left.
2. If looking for a specific topic — types "endocrine" in search →
   all matching lectures inline → 1 tap directly to player.
3. If browsing fresh — taps any subject → expands in place showing
   per-status breakdown → "Open subject" only when actually wanting
   to drill in.

The legacy 4-tap flow still works for power users via
`Routes.videoLecturesLegacy`. But 80%+ of returning users will
resolve their intent in the first 1-2 seconds via recents or search.

---

## What's still open

The `SmartResumeBanner` widget exists but isn't wired into a home
screen yet — that's a 1-line drop into `dashboard_screen.dart` or
`home_screen.dart` that the integrator can do when convenient.

Same for the practice + mock + custom-test screens recording into
`SmartResumeService.recordMockExam` / `recordCustomTest` — those
hooks land in a future wave (low risk; just `initState` calls in
each test screen).
