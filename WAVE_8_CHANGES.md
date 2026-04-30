# Wave 8 — Notes flow shortened from 4-deep to 1-tap-to-reader

The legacy notes browse was a 4-level drill-down:
**category → subcategory → topic → content → reader.** That's 4 taps
+ network calls on cold-boot before the user reaches the PDF they
already know they want.

This wave introduces three shortcuts that route around it:

1. **Search** at the top — type "endocrine", see all matching notes
   at any depth (including content-level), tap → reader. **1 tap.**
2. **Continue reading** rail — last 5 notes the user opened, persisted
   in SharedPreferences. **1 tap from the new browse home.**
3. **Expandable category cards** — tap a subject card → expands inline
   showing per-status counts, no new screen needed. The "Open subject"
   CTA inside the expansion still routes to the legacy 4-level flow
   for users who want to drill down from scratch.

The legacy `NotesScreen` is preserved at `Routes.notesLegacy` so any
deep links that pre-date this wave keep working.

---

## A. New services in `lib/services/`

### `recent_notes_service.dart`
Tracks the last 12 PDFs opened. Each entry carries enough metadata to
deep-link straight back to the reader:

```dart
RecentNotesService.instance.recordOpen(RecentNoteEntry(
  titleId: '...',
  title: '...',
  contentUrl: '...',
  topicId: '...', topicName: '...',
  subcategoryId: '...', subcategoryName: '...',
  categoryId: '...', categoryName: '...',
  lastPage: 12, isCompleted: false,
));
RecentNotesService.instance.top(8);          // for the rail
RecentNotesService.instance.updateProgress(  // pulled from reader
  titleId, lastPage: 24, isCompleted: false,
);
RecentNotesService.instance.clear();         // hooked to "Reset progress"
```

Idempotent — opening the same note twice promotes the existing entry
rather than duplicating. Bounded at 12 entries (oldest auto-trimmed).

### `reading_preferences_service.dart` (`ChangeNotifier`)
Persists PDF reader prefs:
- Background (Auto / Light / Sepia / Dark) → exposes `paperColor()` +
  `inkColor()` for the reader chrome.
- Brightness slider override (-1..1, -1 = follow system).
- Font scale (0.7..1.6).
- Keep-screen-awake toggle.
- Fit-to-width toggle.

Listeners (the reader chrome itself) react in real time as the user
slides the brightness or switches sepia → dark.

---

## B. New screens in `lib/modules/notes/`

### `notes_browse_screen.dart` — replaces NotesScreen as the default

The new entry point at `Routes.notesCategory`. Three sections, in
order of UX priority:

1. **Sticky search bar** at the top — Apple-style 48px row on a soft
   surface, leading magnifier, trailing clear. Triggers
   `HomeStore.onGlobalSearchApiCall(query, "pdf")` at length ≥ 3.

2. **Continue reading rail** — horizontal scroll of the user's most
   recent 8 notes. Each card shows:
   - Title + topic name
   - "Page 12" badge if the user has progress
   - "5m ago" relative timestamp
   - Tap → straight into `Routes.notesReadView` with the right deep-
     link arguments + `initialPage`

3. **All subjects** — `_ExpandableCategoryCard` per subject. Header
   shows icon + name + total notes count. Tap → expands inline (no
   new screen) to reveal:
   - Description
   - Per-status chips (Completed / In progress / Not started /
     Bookmarked) with semantic colors
   - Priority label badge
   - "Open subject" CTA → routes into the legacy 4-level flow

Search results render as type-tagged tiles ("Subject", "Chapter",
"Topic", "Note") with a `bolt` accent on direct-to-reader content
matches so the user knows which hits open the PDF directly.

Empty / loading / no-internet states all use the wave-5 `EmptyState`
+ `SkeletonList` helpers.

### `reading_preferences_sheet.dart` — Apple-style modal

Triggered from the PDF reader's toolbar (wired in wave 9). Controls:
- 4-way segmented control for background tone (Auto/Light/Sepia/Dark)
- Brightness slider with lock-to-system toggle
- Keep-awake + fit-to-width switches
- "Reset to defaults" button

Lives in the modal-bottom-sheet pattern with the standard 44×4 drag
handle pill + 28pt top-radius.

---

## C. Reader hook (`notes_read_view.dart`)

`initState` now records the open into `RecentNotesService`:

```dart
RecentNotesService.instance.recordOpen(
  RecentNoteEntry(
    titleId: widget.titleId!,
    title: widget.title,
    contentUrl: widget.fileUrl ?? '',
    topicId: widget.topicId,
    topicName: widget.topic_name,
    subcategoryId: widget.subcategoryId,
    subcategoryName: widget.subcategory_name,
    categoryId: widget.categoryId,
    categoryName: widget.category_name,
    lastPage: widget.pageNo,
    isCompleted: widget.isCompleted ?? false,
  ),
);
```

Fire-and-forget — failures don't block the reader from rendering.

Also imports the new tokens / haptics / share / reading-prefs helpers
in preparation for wave 9 chrome polish.

---

## D. Routes

`lib/app/routes.dart`:
- `Routes.notesCategory` → `NotesBrowseScreen` (new default).
- `Routes.notesLegacy` → `NotesScreen` (legacy 4-deep flow preserved).

Every existing deep link / navigator push to `Routes.notesCategory`
automatically benefits from the shortened flow with **zero call-site
changes**. The drill-down screens themselves (subject_detail,
topic_category, chapter_detail) still route through the legacy flow
and remain untouched in this wave — they're polished in wave 9.

---

## E. End-to-end UX

Cold-boot user opens the app, taps **Notes**:

1. Sees their last 5 PDFs in a horizontal rail at top → 1 tap to
   resume reading on the page they left off.
2. If looking for something new — types "endocrine" in the search
   bar → all matching notes appear inline → 1 tap directly to
   reader.
3. If browsing fresh — taps any subject card → it expands in place
   showing the breakdown → tap "Open subject" only when actually
   wanting to drill in.

The legacy 4-tap flow still works for power users who want it. But
80% of returning users will resolve their intent in the first 1-2
seconds via recents or search.

---

## What's coming in wave 9

- Polish the legacy `notes_category` / `subject_detail` /
  `topic_category` / `chapter_detail` screens with AppTokens (header
  swap from blue strip + rounded container → clean AppBar).
- Polish `notes_read_view` chrome — wire the reading prefs sheet,
  Apple-style top bar, share PDF action, save FAB redesign.
- Polish the 5 offline tree screens with the same pattern.
- Add `share_plus` integration for sharing PDF as file.

Wave 8 ships the foundations and the user-visible shortcut. Wave 9
applies the cosmetic polish to the existing screens that the
shortcuts route around.
