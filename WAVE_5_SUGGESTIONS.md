# Wave 5 Upgrade Suggestions — Sushruta LMS

> Ideas worth considering once wave 4.x (Apple-minimalistic UI polish) lands.
> Grouped by **impact** (How much will users notice it?) and **effort** (How
> long to ship?).

---

## A. Quick wins — high value / low effort

These are 1-day shippable and visibly upgrade the product.

### A1. Pull-to-refresh on every list surface
Right now lists in `notifications_screen`, `continue_watching_screen`,
`progress_screen`, `home_screen` (featured rails) don't refresh when the user
gestures down. Adding `RefreshIndicator` everywhere is an Apple/Material
expectation. Add a tiny shared helper:

```dart
// lib/helpers/refresh_helper.dart
Widget refreshable({required Widget child, required Future<void> Function() onRefresh}) =>
  RefreshIndicator(
    color: AppTokens.accent(ctx),
    backgroundColor: AppTokens.surface(ctx),
    onRefresh: onRefresh,
    child: child,
  );
```

### A2. Skeleton placeholders instead of CircularProgressIndicators
We have `AuthSkeleton` for auth flows. Promote it to a generic
`AppSkeleton` and use it on:
- `progress_screen` while loading metrics
- `notifications_screen` while loading the list
- `home_screen` featured rails
- `continue_watching_screen` tabs

Spinners feel old; skeletons feel modern.

### A3. Haptic feedback on key actions
Already have `vibration` in pubspec. Wire `HapticFeedback.selectionClick()`
on:
- Bottom nav tab change
- MCQ option select
- Bookmark toggle
- Pull-to-refresh trigger
- Submit-test confirmation

```dart
import 'package:flutter/services.dart';
HapticFeedback.selectionClick();   // light tick
HapticFeedback.mediumImpact();     // success-ish
HapticFeedback.heavyImpact();      // destructive-confirm
```

### A4. Empty states everywhere
We added rich empty states to `search_screen` and `continue_watching_screen`.
Same treatment is missing on:
- `bookmark_main_list` / `bookmark_question_list`
- `notifications_screen` (already has one — verify copy)
- Recent reports list

Use a single `_EmptyState({required icon, title, subtitle})` and inline-import.

### A5. SnackBar standardization
Currently each screen builds its own SnackBar with different shapes /
backgrounds. Promote to `AppFeedback`:

```dart
// lib/helpers/app_feedback.dart
class AppFeedback {
  static void success(BuildContext ctx, String msg) => _show(ctx, msg, AppTokens.success(ctx));
  static void error(BuildContext ctx, String msg)   => _show(ctx, msg, AppTokens.danger(ctx));
  static void info(BuildContext ctx, String msg)    => _show(ctx, msg, AppTokens.ink(ctx));
  static void _show(BuildContext ctx, String msg, Color bg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppTokens.radius12),
      content: Text(msg, style: AppTokens.body(ctx).copyWith(color: Colors.white)),
    ));
  }
}
```

### A6. Bottom-sheet drag handle everywhere
We have it on `moreMenuBottomSheetContainer`. Add the same 44×4 pill to
every `showModalBottomSheet` we own. Apple does this on every sheet.

---

## B. Medium-impact UX upgrades

### B1. Resumable uploads / downloads
Notes PDFs are downloaded with a single `http.get`. If the network drops,
the user starts over. Use `dio` with `CancelToken` + range-request resume.
Plus a tiny in-app download manager screen showing progress.

### B2. Offline-first for notes & MCQs
We download PDFs but the MCQ bank still requires network. Cache the last
50 attempted questions per topic in `dbhelper.dart` so a user on metro
WiFi can keep practicing offline.

### B3. App-wide search across history
The current `search_screen` queries the server. Add a local cache layer
so recent searches are instant. Bonus: surface "Recent" chips above the
filter row.

### B4. Reading-mode for notes (sepia + serif + reading width)
Long PDFs are tiring on screen. Add a "Reading mode" toggle in
`notes_viewer.dart` that swaps to:
- Sepia background (`#FAF1E4`)
- Serif text rendering
- Justified, ~70-char-wide column

### B5. Universal share-sheet
Right now we have `WhatsApp` quick-share for question text. Add a generic
`Share.share(...)` flow (via `share_plus`) so users can send an MCQ +
explanation to any app. Big distribution lever.

### B6. Spaced-repetition surface
We log `bookmark` and `marked-for-review` in TestCategoryStore. Build a
"Daily review" screen that surfaces 20 questions/day from the user's
bookmarked + marked-incorrect pool, weighted by the date last seen.
This is the killer feature for medical exam prep.

### B7. Streak-based celebration screens
We track streak server-side via `streak.business.js`. Add a celebratory
sheet on day-7, day-30, day-100 with confetti animation
(`confetti` pub package).

### B8. Push notifications back to streak / new-content
We have FCM wired (`fcmtoken` in profile). Backend already pushes; surface
preferences UI:
- Daily reminder time
- New content notifications
- Streak risk alerts (8 PM "you'll lose your streak")

### B9. Custom MCQ session (filter by topic + difficulty + length)
Right now MCQ practice uses preset chunks. Add a "Custom session" sheet:
slider for #questions, multi-select topics, multi-select difficulty,
checkbox "only unattempted". Powered by the existing
`getQuestionPallete` endpoint.

### B10. "Recently viewed" on home
Top of `home_screen.dart`, show 3 horizontally-scrolling cards with
"Continue from where you left" — last 3 things across video/note/quiz.
Distinct from "Continue Your Learning" which has separate tabs.

---

## C. Polish + UX consistency

### C1. Haptics on segmented control switch
The new segmented TabBars (`continue_watching_screen`,
`featured_video_view`) feel flat. `HapticFeedback.selectionClick()` on
tab change makes them feel premium.

### C2. Promote `AppFeedback` (see A5) site-wide
Rip out raw `ScaffoldMessenger.of(context).showSnackBar(...)` and use
the helper.

### C3. Settings screen unification
Right now profile / about / delete-history / device-sessions live in
different places. Promote all to a single "Settings" screen accessed
via one entry point with grouped sections (Account, Subscription,
Privacy, Devices, Help). Classic iOS settings pattern.

### C4. Dark-mode pass on remaining surfaces
Several screens still hardcode `AppColors.white` / `AppColors.black`.
Audit + replace with `AppTokens.surface(ctx)` / `AppTokens.ink(ctx)`.
Worth a dedicated wave.

### C5. Replace `ThemeManager.primaryColor` references
Same pattern — search for `ThemeManager.primaryColor` and replace with
`AppTokens.accent(ctx)`. About 80 call sites left.

### C6. Replace `Dimensions.PADDING_SIZE_*` references
Codemod from `Dimensions.PADDING_SIZE_*` → `AppTokens.s*`. ~600 call
sites — mechanical but tedious.

---

## D. New utilities to add to the codebase

### D1. `lib/helpers/app_feedback.dart` (see A5)
Standardize all snackbars + toasts. Adopt site-wide.

### D2. `lib/helpers/safe_async.dart`
A wrapper for the common pattern:

```dart
try {
  setState(() { _loading = true; });
  await someApiCall();
  if (!mounted) return;
  setState(() { _loading = false; _data = ...; });
} catch (e) {
  if (!mounted) return;
  setState(() { _loading = false; });
  AppFeedback.error(ctx, "Couldn't load");
}
```

### D3. `lib/helpers/value_formatters.dart`
Centralize `Duration` → "12:34:56", `int` → "1.2K", "₹1,200", "12 May
2025" formatters. Right now they're scattered across screens.

### D4. `lib/helpers/connectivity_aware.dart`
A mixin for any State<T> that auto-refetches when connectivity returns:

```dart
mixin ConnectivityAware<T extends StatefulWidget> on State<T> {
  late StreamSubscription _sub;
  Future<void> onReconnect();
  @override
  void initState() {
    super.initState();
    _sub = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) onReconnect();
    });
  }
  @override
  void dispose() { _sub.cancel(); super.dispose(); }
}
```

### D5. `lib/helpers/keyboard_dismiss.dart`
Tap-anywhere-to-dismiss-keyboard wrapper. Apple does this on every
form. Our forms currently force the user to tap the system "done"
key.

```dart
class TapToDismissKeyboard extends StatelessWidget {
  final Widget child;
  const TapToDismissKeyboard({required this.child});
  @override
  Widget build(BuildContext context) =>
    GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: child,
    );
}
```

### D6. `lib/helpers/network_image_cached.dart`
Replace raw `Image.network(...)` with `cached_network_image` everywhere.
Faster, prevents flicker on rebuild, persists across sessions.

### D7. `lib/helpers/launch_helpers.dart`
Centralize `_launchURL`, `_launchEmail`, `_launchWhatsApp`. Currently
defined 5+ times across screens.

### D8. `lib/helpers/permission_helper.dart`
Wrap `Permission.storage.request()` with rationale UI for first-time
asks. Right now the storage prompt comes out of nowhere.

---

## E. Heavy-lift, high-reward features

### E1. Widget tests + golden files
We have zero widget tests. Set up a `test/widgets/` folder with golden
file tests for every AppToken-using widget. Catches design-token
regressions on every PR.

### E2. Typography & color theme via Material 3 ThemeData
Currently we sidestep Theme.of(ctx) and read AppTokens directly.
Eventually wire an `AppTheme.light()` / `AppTheme.dark()` that maps
AppTokens onto Material 3 ColorScheme + TextTheme. Lets us use
`Theme.of(ctx).colorScheme.primary` everywhere and get hover/focus
states for free.

### E3. Riverpod migration
MobX + Provider works but Riverpod 2.x is the modern Flutter standard
and gives compile-time safety + much better testability. Big change but
pays for itself once we hit 50+ stores.

### E4. Full localization
Hardcoded English strings everywhere. Add `flutter_localizations` and
extract every string to `lib/l10n/app_en.arb`. Even if we ship English-
only initially, having the foundation ready means Hindi adds in days.

### E5. Crash + perf monitoring beyond Crashlytics
Sentry or Datadog gives breadcrumbs + Apdex scores. Crashlytics is
crash-only.

### E6. App Store Optimization
- Add metadata localization
- App preview videos (we have onboarding carousel — repurpose)
- Tag every screenshot with conversion hooks ("3,500+ NEET SS questions")

### E7. In-app upgrade prompt for power users
Track engagement (sessions/week, questions/week). At threshold (e.g.
"used app 7 days in past 14"), prompt for App Store rating via
`in_app_review`. Most powerful retention lever in mobile.

### E8. Background sync
Keep streaks alive even when the user opens the app for 5 seconds.
Use `workmanager` to sync streaks + bookmarks every 6h. Extends
streak engagement.

### E9. Question authoring/QA portal (admin-only)
Currently admins author MCQs in a separate web admin. Pull authoring
in-app for senior moderators. Big internal-tooling win.

### E10. Offline-first sync engine
Plumb a generic "offline queue" that buffers all writes
(bookmark, mark-as-attempted, notes, highlights) when offline and
flushes when online. Currently each store handles its own offline
state and they're inconsistent.

---

## F. Backend-side ideas (worth coordinating)

### F1. WebSocket live updates
Push live notification, live streak counter, live "you got beaten in
percentile" toasts via WebSocket. We have Redis already; add socket.io
to the Express app.

### F2. AI-generated topic summaries
Already wired Claude AI for similar-questions. Add a daily cron that
generates 1-paragraph topic summaries for each subject and surfaces
them as "Today's reading" on home.

### F3. Personalized question difficulty
Use the existing `confidenceCalibration` + `topicHeatmap` to dynamically
serve questions at the user's edge of competence (90% accuracy is
boring; 60% is frustrating; 75% is the sweet spot).

### F4. Cohort competition / leaderboard
Pure-play motivation. Show "you're in the top 12% of NEET SS aspirants
this week" badge on home.

### F5. Backend cost telemetry
Track Claude API spend per user; surface to admin so we can spot abuse
or feature on engaged learners.

---

## Prioritization recommendation

If I had to ship just 5 of these next week:

1. **A3 — Haptics everywhere** (1 day, instantly feels premium)
2. **A2 — Skeletons replacing spinners** (2 days, modernizes whole app)
3. **A5 + D1 — AppFeedback helper** (1 day, unblocks 50+ snackbar
   sites for cleanup)
4. **B6 — Daily review surface** (4-5 days, killer feature for prep)
5. **A1 — Pull-to-refresh** (1 day, table-stakes UX)

That's a 2-week sprint with massive perceived value.

If I had a quarter:

1. C5 + C6 — finish the AppTokens migration (1 week, no regressions)
2. B6 — Daily review (1 week)
3. B8 — Push notifications wave (1 week)
4. B9 — Custom MCQ session (1 week)
5. E2 — Material 3 theme (1 week)
6. D2-D8 — All helper utilities (3 days, scattered)

End of quarter: app feels Apple-grade, retention metrics jump, code
quality double-digits cleaner.
