# Wave 10 — Notes legacy drill-down + offline tree polish

Closes the deferred polish from wave 9. Eight more notes-module
screens migrated from the "blue strip + rounded white container"
pattern to clean Apple-style AppBar + soft-surface body, with
`SkeletonList` loading and `EmptyState` empty-states.

These screens are reachable now only via the legacy 4-deep flow
(category card → "Open subject" CTA → chapters → topics → notes)
or via the offline-notes hamburger entry. Most users hit the
wave-8 browse home → search → recents flow instead, but for the
ones who do drill in, the chrome now matches the rest of the app.

---

## Files polished

### Online tree (4 files)

| File | Lines | Change |
|---|---|---|
| `notes_category.dart` | 858 | Header swap + skeleton + empty state. Now at `Routes.notesLegacy`. |
| `notes_subject_detail.dart` | 909 | Header swap + skeleton + empty state. |
| `notes_topic_category.dart` | 892 | Header swap + skeleton + empty state. |
| `notes_chapter_detail.dart` | 1514 | Header swap + skeleton + empty state + RefreshIndicator color. |

### Offline tree (4 files)

| File | Lines | Change |
|---|---|---|
| `offline_subcategory_list.dart` | 389 | Header swap + skeleton + empty state. |
| `offline_topic_list.dart` | 387 | Header swap + skeleton + empty state. |
| `offline_title_list.dart` | 393 | Header swap + skeleton. |
| `downloaded_notes.dart` | 476 | Header swap + skeleton + 2 empty states (no files / error). |

---

## The unified pattern applied to all 8 files

**Before:**
```dart
return Scaffold(
  backgroundColor: ThemeManager.white,
  body: Container(
    color: ThemeManager.blueFinalDark,           // blue strip
    child: Column(
      children: [
        Padding(
          padding: ...,                          // header padding
          child: Row(
            children: [
              IconButton(icon: arrow_back),      // back
              Text("Title", color: white),       // title
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: ThemeManager.mainBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28.8),  // rounded white container
                topRight: Radius.circular(28.8),
              ),
            ),
            child: Column(...),
          ),
        ),
      ],
    ),
  ),
);
```

**After:**
```dart
return Scaffold(
  backgroundColor: AppTokens.scaffold(context),
  appBar: AppBar(
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: AppTokens.scaffold(context),
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_rounded,
          color: AppTokens.ink(context), size: 18),
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    title: Text("Title", style: AppTokens.titleLg(context)),
    centerTitle: false,
  ),
  body: SafeArea(
    child: Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTokens.s24, AppTokens.s8, AppTokens.s24, 0),
            child: Column(...),
          ),
        ),
      ],
    ),
  ),
);
```

**Loading state**: `Center(CircularProgressIndicator)` →
`SkeletonList(count: N, itemHeight: ...)`

**Empty state**: `Text("We're sorry, there's no content available
right now. Please check back later...")` → `EmptyState(icon, title,
subtitle)` with semantic icons:
- `Icons.menu_book_outlined` for empty subjects/notes
- `Icons.topic_outlined` for empty topics
- `Icons.picture_as_pdf_outlined` for empty notes within a chapter
- `Icons.cloud_off_rounded` for empty offline storage
- `Icons.error_outline_rounded` for read errors

---

## Why this finishes the notes module

The notes module entry point at `Routes.notesCategory` shows the
new wave-8 browse home (search + recents + expandable categories).
Users who type in the search bar or tap a recent never see the
legacy chain. But power users tapping "Open subject" inside an
expanded category card flow into:

1. `notes_subject_detail` (Subject → Subcategories) — polished
2. `notes_topic_category` (Subcategory → Topics) — polished
3. `notes_chapter_detail` (Topic → Notes leaf list) — polished
4. `notes_read_view` (PDF reader) — polished in wave 9

Plus the offline detour (Settings → Offline notes):
1. `offline_category_list` — polished in wave 9
2. `offline_subcategory_list` — polished now
3. `offline_topic_list` — polished now
4. `offline_title_list` — polished now
5. `downloaded_notes` — polished now

**Every notes screen now uses AppTokens, SkeletonList, EmptyState,
and the standard AppBar pattern.** The module is fully bedded in
with the rest of the app's wave-4+ design language.
