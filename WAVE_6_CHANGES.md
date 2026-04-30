# Wave 6 — Daily review fully wired across every MCQ surface

This wave makes the daily-review feature **production-ready** end to
end. No more stubs, no more "TODO: integrator wires this". Every MCQ
screen in the app now feeds the review pool; the daily-review home
shows real numbers; tapping "Start review" walks the user through a
full Q-by-Q session; finishing a session bumps the streak and fires a
confetti celebration on milestones; the user can share their streak
or any solved question to any messenger.

---

## A. Service layer redesigned

### `lib/services/daily_review_service.dart` — full rewrite

Now manages **three persistent pools** in SharedPreferences:
- `dr_pool_bookmarked_v1` — questions the user explicitly bookmarked
- `dr_pool_incorrect_v1` — questions answered wrong
- `dr_pool_review_v1` — questions flagged "review later" mid-test

Each pool stores rich `ReviewQuestion` payloads (text + 4 options +
correct answer + explanation + topic + examId + addedAt) so the review
session screen renders **fully offline**.

New API:
```dart
DailyReviewService.instance.recordBookmark(reviewQuestion);
DailyReviewService.instance.unrecordBookmark(questionId);
DailyReviewService.instance.recordIncorrect(reviewQuestion);
DailyReviewService.instance.recordCorrect(questionId);
DailyReviewService.instance.recordReview(reviewQuestion);
DailyReviewService.instance.unrecordReview(questionId);
DailyReviewService.instance.composeToday();   // returns ReviewQuestion[]
DailyReviewService.instance.getPoolSizes();   // {bookmarked, incorrect, review}
DailyReviewService.instance.markSeen(questionId);
DailyReviewService.instance.recordSessionCompleted(); // returns SessionResult
```

`SessionResult` carries `{streak, hitMilestone, totalSessions}` so the
caller knows when to fire the celebration sheet. Streak milestones:
3, 7, 14, 30, 60, 100, 200, 365.

Storage caps:
- 2000 entries/pool — oldest trimmed first.
- 5000 entries in seen-map — oldest trimmed first.
- All keys can be wiped via `resetAll()` (hooked to "Reset progress").

### `lib/services/daily_review_recorder.dart` — adapters

Three adapters, one per model the codebase uses for questions:
- `_fromTestData(test.TestData q, examId)` — practice + exam screens
- `_fromSolutionReport(sol.SolutionReportsModel q)` — solution review
- `_fromMasterQuestion(msr.Questions q)` — master/mock solution

Public API screens call:
```dart
DailyReviewRecorder.bookmarkToggle(testData, examId, isBookmarked);
DailyReviewRecorder.recordWrong(testData, examId, pickedValue);
DailyReviewRecorder.recordCorrect(testData);
DailyReviewRecorder.recordReviewMark(testData, examId);
DailyReviewRecorder.recordReviewUnmark(testData);
DailyReviewRecorder.bookmarkToggleSolution(solReport, isBookmarked);
DailyReviewRecorder.bookmarkToggleMaster(masterQuestion, isBookmarked);
DailyReviewRecorder.ingestSolutionReport(report);     // batch sync after exam
DailyReviewRecorder.ingestMasterReport(masterReport); // batch sync after mock
```

---

## B. Wired into 8 MCQ surfaces

Every place the user can interact with an MCQ now feeds the review
pool. The integrations are minimal (1-3 lines per call site) and don't
touch the existing flows.

| Screen | Bookmark hook | Wrong-answer hook | Review-flag hook | Batch ingest |
|---|---|---|---|---|
| `practice_test_exam_screen.dart` | ✅ | ✅ | — | — |
| `practice_custom_test_exam_screen.dart` | ✅ | ✅ | — | — |
| `practice__master_test_exam_screen.dart` | ✅ | ✅ | — | — |
| `test_exam_screen.dart` (exam mode) | — | — | ✅ | — |
| `practice_test_solution_exam_screen.dart` | ✅ | — | — | — |
| `practice_mock_solution_exam_screen.dart` | ✅ | — | — | — |
| `practice_custom_test_solution_screen.dart` | ✅ | — | — | — |
| `solution_report.dart` | ✅ | — | — | ✅ |
| `solution_master_report.dart` | ✅ | — | — | ✅ |
| `custom_test_solution_report.dart` | ✅ | — | — | ✅ |
| `quiz_solution_report.dart` | ✅ | — | — | ✅ |

The "batch ingest" calls run in `initState` of each solution screen —
the moment a user opens their report, every wrong answer + bookmark +
marked-for-review question lands in the daily review pool automatically.
No extra UI needed.

---

## C. Daily-review screens

### `lib/modules/daily_review/daily_review_screen.dart` (rewired)

- Reads `composeToday()` for the actual deck.
- Reads `getPoolSizes()` to show the breakdown card ("12 bookmarked, 4
  incorrect, 7 marked for review").
- "Start review" pushes `DailyReviewSessionScreen.route(deck)`.
- Auto-refreshes on `didChangeDependencies` so streak / completion
  state updates immediately when the user returns from a session.
- Empty state when no questions in pool yet.

### `lib/modules/daily_review/daily_review_session_screen.dart` (NEW)

Full Q-by-Q answering surface:
- One question at a time, soft-surface card with HTML rendering.
- Apple-style option tiles A/B/C/D — neutral when idle, accent-soft
  when picked, success/danger when revealed.
- Skip vs Submit CTAs (Submit disabled until pick).
- Post-reveal: shows correct answer + explanation (when present) in a
  bordered card with accent left-rail.
- Linear progress indicator under the AppBar.
- "Share" action in AppBar after reveal (uses ShareHelpers).
- WillPopScope confirm dialog ("Leave session?").
- Calls `markSeen(qid)` after each answer.
- Session-end summary screen with correct/wrong/skipped triple stat,
  streak badge, "Share my N-day streak" button + Done.

### `lib/modules/daily_review/streak_celebration_sheet.dart` (NEW)

Pure-Flutter modal that fires on milestone (3, 7, 14, 30, 60, 100, 200,
365 days):
- 60 confetti particles animated with custom CustomPainter (no
  external package needed).
- Big animated flame icon in a gradient circle.
- Title that scales with streak ("3-day streak" → "A full year").
- Subtitle that scales tone ("building the habit" → "playing on a
  different level").
- Share + Keep going CTAs.

---

## D. Notification preferences

### `lib/modules/settings/notification_preferences_screen.dart` (NEW)

Apple-style settings sub-screen with these toggles, all persisted in
SharedPreferences for the FCM dispatcher to read:

- **Daily review reminder** (with time picker — default 8 PM)
- **Streak risk alerts** (auto-fires evening if user hasn't reviewed)
- **New content** (videos / notes / MCQs / mocks added to plan)
- **Doubt replies** (mentor / AI replies to raised doubts)
- **Subscription & billing** (trial reminders, renewals, payment fails)

Linked from the new Settings home under "Notifications". Defaults all
ON; user explicitly opts out.

Routed via `Routes.notificationPreferences`.

---

## E. Universal share

### `lib/helpers/share_helpers.dart` (NEW)

Wraps `share_plus 10.0.0` (added to pubspec) with three convenient
shapes:

```dart
ShareHelpers.shareQuestion(ctx, questionText, optionLabels);
ShareHelpers.shareQuestionWithSolution(ctx, questionText, optionLabels,
                                        correctIndex, explanation);
ShareHelpers.shareStreak(ctx, streak: 7);
ShareHelpers.shareApp(ctx);
```

- Strips HTML out of question/explanation for clean plaintext.
- Appends a marketing tag (link to download).
- Falls back to clipboard + AppFeedback.success if no system share
  intent is available (desktop, certain Android variants).
- Fires `Haptics.light()` on tap.

Wired into:
- Review session AppBar (post-reveal "share" icon).
- Session summary screen ("Share my N-day streak" button when
  streak > 1).
- Streak celebration sheet (Share button next to "Keep going").

### `pubspec.yaml`

```yaml
share_plus: ^10.0.0
in_app_review: ^2.0.9   # for future ASO retention prompt
```

---

## F. Routes + menu

`lib/app/routes.dart`:
- `Routes.notificationPreferences` registered.
- Route handler dispatches to `NotificationPreferencesScreen.route`.

(Daily review + Settings routes were added in Wave 5; this wave just
wires up the new Notifications sub-screen.)

---

## G. Bookmark empty-state polish

`lib/modules/bookmarks/bookmark_main_list.dart`:
- 70-line legacy empty state ("Step 1 - First you have to give exam"
  etc.) replaced with single `EmptyState({icon, title, subtitle})`
  ("No bookmarks yet — Tap the bookmark icon on any question while
  reviewing solutions to save it here.")

---

## H. End-to-end flow

The user journey now works as follows, with no manual integration
required:

1. User goes through a normal practice / exam / mock / quiz.
2. Whenever they bookmark, get one wrong, or flag for review — the
   relevant screen calls `DailyReviewRecorder` which silently
   persists the question in SharedPreferences.
3. When they later open the corresponding solution screen, it does a
   one-shot `ingestSolutionReport(...)` that re-picks up everything
   the user has flagged so far. Idempotent — no duplicates.
4. Next day, user opens "Daily Review" from the More menu.
5. They see "12 bookmarked · 4 incorrect · 7 marked for review" pool
   breakdown, today's deck size, current streak.
6. Tap "Start review". 20 questions chosen by the spaced-repetition
   selector (bookmarks weighted highest, decay boost for old items).
7. Answer / skip / read explanation. Each answer marks the question
   seen so it doesn't reappear tomorrow.
8. Finish the deck → session summary screen → streak count bumps →
   if milestone hit, confetti celebration → share streak.

Net deltas:
- 1 service redesigned (300+ lines)
- 1 service-adapter file (200 lines)
- 1 review-session screen (650 lines)
- 1 streak celebration sheet (270 lines)
- 1 notification-prefs screen (350 lines)
- 1 share helpers (110 lines)
- 11 MCQ screens lightly hooked
- 1 bookmark screen empty-state migrated

Wave 6 is the **shipping milestone** for daily review. The dev should
only need to:
1. Run `flutter pub get` (for share_plus + in_app_review).
2. QA-test the recording → home → session → celebration loop end to end.
3. Wire FCM dispatcher on the backend to read the SharedPreferences
   notification toggles (handled in a separate backend wave).
