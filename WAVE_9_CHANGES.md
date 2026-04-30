# Wave 9 — Notes reader chrome polish + login crash fix

Completes the cosmetic upgrade to the PDF reader and closes the
runtime exception users were hitting on the email login screen.

---

## A. Login screen render exception — fixed

`lib/modules/login/login_screen.dart` was throwing
"RenderFlex children have non-zero flex but incoming height
constraints are unbounded" on every cold-boot.

Root cause: `KeyboardActions` wraps its child in a
`SingleChildScrollView` (unbounded height). The Column inside that
viewport had a `Spacer()` before the support footer — Spacer requires
bounded space and crashes inside a scrollable.

Fix: replace `const Spacer()` with `const SizedBox(height: AppTokens.s32)`.
The support footer now sits below the CTA in a natural scroll layout.

Audited the other auth screens (`pin_entry_screen`,
`verify_change_mobile_otp`, `login_with_phone_screen`,
`google_signup_form`) — they either don't use a SingleChildScrollView
parent or wrap the Column in a `SizedBox(height: MediaQuery.size.height)`
that gives bounded height back. No further fixes needed.

---

## B. PDF reader chrome — Apple-style polish

`lib/modules/notes/notes_read_view.dart`:

### Header strip
**Before:** Bright `ThemeManager.blueFinalDark` blue strip with white
back arrow + title + "Mark as Read" pill + bookmark icon. Mismatched
the new wave-4+ design language.

**After:** Apple Books-style ink-tone header (`AppTokens.ink(context)`,
nearly-black). Houses:
- Back button (saves last page + annotations on dispose).
- Title (single-line ellipsis) + Mark-as-read pill underneath.
- New "Reading options" button → opens `ReadingPreferencesSheet`.
- New "Share" button → triggers system share with the PDF link.
- Bookmark toggle with `AppFeedback.success` confirm + Haptics.

The Mark-as-read pill itself is now state-aware: `success(context)
.withOpacity(0.18)` background when complete, white-on-ink when not.
Icon flips between `Icons.check_circle_rounded` and
`Icons.circle_outlined`.

### Save FAB
**Before:** Plain `FloatingActionButton(backgroundColor: blueprimary,
child: Icon(Icons.save))`.

**After:** Custom 56×56 accent-color circle with soft shadow, haptic
on tap, and an `AppFeedback.success(context, 'Notes saved')` toast
when annotations export successfully. Matches the rest of the app's
design vocabulary.

### Body
Background switches from `ThemeManager.white` to `AppTokens.scaffold
(context)` so dark mode is automatic.

---

## C. Share helper extension

`lib/helpers/share_helpers.dart` — added `openUrlAsLink(ctx, text, url)`
for sharing a labelled URL (used by the reader to share PDF links).
Composes "{text}\n{url}{appTag}" and routes through the existing
share-or-clipboard fallback.

---

## D. Offline notes empty + loading

`lib/modules/notes/offline_category_list.dart`:
- `CircularProgressIndicator` while loading → `SkeletonList(count: 5,
  itemHeight: 88)`.
- "No Offline Notes Found" plain text → `EmptyState({icon:
  Icons.cloud_off_rounded, title: 'No offline notes', subtitle:
  'Notes you download for offline reading will appear here.'})`.

---

## E. Wired in earlier-wave services

The reader now imports:
- `app_tokens.dart` — for the chrome ink color, accent, scaffold.
- `app_feedback.dart` — for save / bookmark toasts.
- `haptics.dart` — every action fires the right haptic tier.
- `share_helpers.dart` — for the new Share action.
- `reading_preferences_service.dart` + `reading_preferences_sheet.dart`
  — wired through the Reading Options button.
- `recent_notes_service.dart` — `recordOpen` already plumbed in
  wave 8; entry now flows correctly into the new browse home rail.

---

## What's still open

- Polish on the legacy 4-deep notes screens
  (`notes_subject_detail` / `notes_topic_category` /
  `notes_chapter_detail`) — these still show the old blue strip +
  rounded white container pattern. They're reachable only via the
  expandable category card's "Open subject" CTA; most users will go
  through the new browse home / search / recents instead.
- `notes_category` legacy entry (now at `Routes.notesLegacy`) hasn't
  been polished — same reason.
- The 4 remaining offline tree screens (`offline_subcategory_list`,
  `offline_topic_list`, `offline_title_list`, `downloaded_notes`) —
  same pattern.

These can be done in a follow-up wave when the UX team confirms the
new browse / search flow has bedded in.
