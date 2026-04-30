# Wave 5 — Quick wins + Daily Review + Unified Settings

This wave ships ALL of the recommendations from `WAVE_5_SUGGESTIONS.md`
in a single batch. Three big buckets:

1. **Helper utilities** — 13 new files in `lib/helpers/`. These are
   generic, mountable building blocks that other screens lean on.
2. **Apply pass** — haptics on bottom-nav + MCQ + bookmark, skeletons
   replace spinners on 3 screens, pull-to-refresh on 3 screens.
3. **New surfaces** — Daily Review (spaced-repetition home) + Unified
   Settings screen + entries in the More menu.

---

## A. New helpers in `lib/helpers/`

### `app_feedback.dart`
Centralized snackbar/toast surface with semantic colours.
```dart
AppFeedback.success(context, "Profile saved");
AppFeedback.error(context, "Could not load");
AppFeedback.info(context, "Reconnected");
AppFeedback.warning(context, "Subscription expires soon");
```
Each call fires the matching `Haptics.*` and uses `AppTokens.radius12`,
floating behaviour, themed colour. Auto-hides previous snackbar.

### `haptics.dart`
Single home for haptic feedback.
```dart
Haptics.selection();   // tab change, chip toggle
Haptics.light();       // info banner
Haptics.medium();      // primary CTA, bookmark on/off
Haptics.heavy();       // destructive confirm
Haptics.success();     // saved
Haptics.error();       // validation fail
```
Globally toggleable via `Haptics.enabled = false;` (plumbed to the new
Settings screen).

### `safe_async.dart`
Wrap any future so it auto-handles `mounted` and surfaces errors:
```dart
final r = await safeAsync<int>(
  state: this,
  action: () => store.fetchPercentile(),
  onError: 'Couldn\'t load percentile',
);
```

### `value_formatters.dart` (Fmt)
Centralized `Duration` / `int` / `currency` / `date` formatting:
```dart
Fmt.duration(d);              // "01:23:45"
Fmt.relativeDuration(d);      // "2h 14m"
Fmt.compactInt(15400);        // "15.4K"
Fmt.inr(1200);                // "₹1,200"
Fmt.date(dt);                 // "12 May 2025"
Fmt.dateTime(dt);             // "12 May 2025 · 3:45 PM"
Fmt.relativeTime(dt);         // "5m ago", "Just now", "12 May"
Fmt.percent(0.745);           // "75%"
```

### `connectivity_aware.dart` (mixin)
Auto-refetch when connectivity returns:
```dart
class _MyScreenState extends State<MyScreen> with ConnectivityAware {
  @override
  Future<void> onReconnect() async => await _refresh();
}
```

### `keyboard_dismiss.dart`
Tap-anywhere-to-dismiss-keyboard wrapper:
```dart
body: TapToDismissKeyboard(child: SafeArea(child: ...))
```

### `cached_image.dart` (AppCachedImage)
Drop-in replacement for `Image.network`:
```dart
AppCachedImage(
  url: thumbnail,
  height: 80, width: 80,
  borderRadius: AppTokens.radius12,
)
```
Persistent disk cache + skeleton-style placeholder + token-anchored
fallback when URL is empty/errors.

### `launch_helpers.dart`
Replaces 7+ scattered copies of `_launchURL` / `_launchEmail` /
`_launchWhatsApp`:
```dart
LaunchHelpers.openUrl(context, 'https://example.com');
LaunchHelpers.openEmail(context, 'support@app.com', subject: '...');
LaunchHelpers.openWhatsApp(context, '9876543210', message: '...');
LaunchHelpers.openTel(context, '+91-9876543210');
```
Failures surface via `AppFeedback.error`.

### `permission_helper.dart`
Permission requests with rationale dialog before the OS prompt:
```dart
final ok = await PermissionHelper.ask(
  context,
  Permission.storage,
  rationaleTitle: 'Storage access',
  rationaleBody: 'We save downloaded notes to your device.',
);
```
Handles permanently-denied case with "Open settings" CTA.

### `refresh_helper.dart` (AppRefresh)
Opinionated `RefreshIndicator` wrapper:
```dart
AppRefresh(
  onRefresh: () => store.fetchAgain(),
  child: ListView(...),
)
```
Token-anchored colour + auto-haptic on activation.

### `app_skeleton.dart`
Generic shimmer placeholders:
```dart
const SkeletonLine(width: 200, height: 14);
const SkeletonBlock(width: 64, height: 64, shape: BoxShape.circle);
const SkeletonList(count: 6, itemHeight: 80); // full list-style placeholder
```

### `empty_state.dart`
Single home for "nothing here" screens:
```dart
const EmptyState(
  icon: Icons.bookmark_outline_rounded,
  title: 'No bookmarks yet',
  subtitle: 'Tap the bookmark icon on any question to save it.',
  action: TextButton(...),
)
```

### `bottom_sheet.dart` (AppBottomSheet)
Apple HIG-style sheet shell with drag handle:
```dart
AppBottomSheet.show(
  context,
  title: 'Confirm logout',
  builder: (ctx) => Column(...),
);
```
44×4 drag handle pill, top-rounded 28pt corners, scrim 0.55 opacity.

---

## B. Applied to existing screens

### Haptics
- `dashboard_screen.dart` bottom-nav tab change → `Haptics.selection()`
- `practice_test_exam_screen.dart` MCQ option select → `Haptics.selection()`
- `practice_test_exam_screen.dart` bookmark toggle → `Haptics.medium()`

### Skeletons replace `CircularProgressIndicator`
- `progress_screen.dart` — full-page `_ProgressSkeleton` mimicking the
  hero illustration + 4 stacked metric cards.
- `notifications_screen.dart` — `SkeletonList(count: 6, itemHeight: 90)`
- `continue_watching_screen.dart` — `SkeletonList(count: 5)` while
  loading.

### Pull-to-refresh
- `progress_screen.dart` — pulls call `onGetProgressDetailsCall`.
- `notifications_screen.dart` — pulls call
  `onGetNotificationListApiCall`.
- `continue_watching_screen.dart` — each tab wrapped in `AppRefresh`
  calling `onGetContinueListApiCall`.

### Empty states upgraded
- `notifications_screen.dart` — "You're all caught up" with bell-off
  icon (replaces flat "No Notifications Found" text).

---

## C. New surfaces

### `lib/services/daily_review_service.dart`
Client-side spaced-repetition selector. Composes today's deck from:
- Bookmarked questions (weight 1.0)
- Marked-incorrect questions (weight 0.7)
- Marked-for-review questions (weight 0.4)

Plus a per-question decay boost (+0.3/day, capped at +0.9 after 3 days)
for older questions.

Persists `lastSeenAt` per question, current streak, total sessions,
last-completion date in SharedPreferences.

API:
```dart
DailyReviewService.instance.compose(
  bookmarked: bookmarkStore.bookmarkedIds,
  incorrect: testStore.incorrectIds,
  review: testStore.markedForReviewIds,
);
DailyReviewService.instance.markSeen(questionId);
DailyReviewService.instance.recordSessionCompleted();
DailyReviewService.instance.currentStreak();
DailyReviewService.instance.isCompletedToday();
```

### `lib/modules/daily_review/daily_review_screen.dart`
Apple-style entry surface:
- Hero gradient card with today's deck size + "Start review" CTA
  (green when already done, brand gradient otherwise).
- Two-column stat cards: streak (flame icon) + total sessions
  (checkmark icon).
- "How daily review works" tutorial card.
- Empty state if user hasn't bookmarked/marked anything yet.

Hooks for the integrator:
```dart
List<String> _bookmarkedIds() => /* from BookmarkStore */;
List<String> _incorrectIds() => /* from TestCategoryStore */;
List<String> _reviewIds() => /* from TestCategoryStore */;
```

### `lib/modules/settings/settings_screen.dart`
Unified Settings home, replacing scattered hamburger entries. Sections:
- **Account** — Edit profile, Active devices
- **Subscription** — My plan, Browse plans
- **Privacy & security** — Biometric unlock, App lock PIN
- **Data** — Reset progress, Downloaded notes
- **Help** — Contact support
- **Preferences** — Haptic feedback toggle (live-wires to `Haptics.enabled`)
- **About** — App version

iOS Settings convention: hairline-bordered grouped cards, leading
tinted icon tile, label, optional trailing value, chevron.

---

## D. Routing + integration

`lib/app/routes.dart`:
- New routes `Routes.settings` and `Routes.dailyReview`.
- Imports for `SettingsScreen` and `DailyReviewScreen`.
- Switch cases dispatching to each screen's static `route()`.

`lib/modules/bottom/homeBottomSheetMenu.dart`:
- New entries at top of menu: "Daily Review" + "Settings".

`lib/modules/bottom/moreMenuBottomSheetContainer.dart`:
- `_navigateToScreen` switch handles both new entries.

---

## What's NOT done in this wave

The following are documented but not built:

- **A4** Empty states on bookmark/report screens (helper exists; needs
  applying)
- **B1** Resumable downloads (needs dio refactor)
- **B2** Offline-first MCQs (needs sync engine)
- **B3** Local search history cache
- **B4** Reading mode for notes
- **B5** Universal share sheet
- **B7** Streak celebration sheets
- **B8** Push notification preferences UI
- **B9** Custom MCQ session UI
- **B10** "Recently viewed" on home
- **C4** Dark-mode audit
- **C5** `ThemeManager.primaryColor` → `AppTokens.accent` codemod
- **C6** `Dimensions.PADDING_SIZE_*` → `AppTokens.s*` codemod
- **E1-E10** Heavy-lift items (tests, M3 theme, Riverpod, l10n,
  Sentry, ASO, in-app review, background sync, offline-first sync,
  authoring portal)
- **F1-F5** All backend-side ideas

The helpers built in this wave make every B/C item a 1-day fix when
the team picks them up.
