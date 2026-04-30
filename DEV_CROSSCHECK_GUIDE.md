# Dev cross-check guide — exam attempt overhaul

> **Use this doc to:** verify the integrations land cleanly, confirm nothing existing is broken, then build the app.
> **Companion docs:**
> &nbsp;&nbsp;[CHANGE_SUMMARY.md](CHANGE_SUMMARY.md) — what changed in the last few days
> &nbsp;&nbsp;[EXAM_ATTEMPT_INTEGRATION_GUIDE.md](EXAM_ATTEMPT_INTEGRATION_GUIDE.md) — architectural overview, endpoint reference
> &nbsp;&nbsp;[EXAM_INTEGRATION_GUIDE_V2.md](EXAM_INTEGRATION_GUIDE_V2.md) — per-screen integration recipes

---

## 0. What changed in wave 2.3 (this PR)

Three things landed on top of wave 2.2:

1. **`McqSolutionActionBar` redesigned to minimalistic single-row layout.** Previously rendered 10 pills as a `Wrap` that consumed multiple lines on a phone. Now: 4 primary chips inline (Highlight, Notes, Ask Cortex, Why-wrong-when-relevant) + a single **More** chip that opens a bottom sheet with the rest (Doubt chat, Similar Qs, Listen, Mnemonic, Diagram, Review later, Discuss, Report). New `_CompactPill` helper — icon + 1-line label, designed so 5 fit on a 360dp phone without wrapping.
2. **`ExamAttemptAttachment` wired into the two primary attempt screens.** Both use the same 6-line pattern:
   * `lib/modules/test/practice_test_exam_screen.dart` (practice attempt — All Q / Answered Q paths both go through this screen with different filters)
   * `lib/modules/test/test_exam_screen.dart` (exam-mode attempt — full timer, no per-question reveal)
3. **Reveal-answer / ConfidenceRater status:** the widget exists in `lib/modules/mcq_review_v3/widgets/confidence_rater.dart` but is NOT actively imported anywhere in the codebase. If you see it in your build, it's coming from a local change or a different branch — confirm with the team and remove the import. The new minimal action bar deliberately does not surface a "Reveal answer" CTA.

The 6-line pattern for the next 10 attempt screens (attempt-screen 3a in §3 below) is now battle-tested on the 2 most-used screens, so propagating it is straightforward.

---

## 1. What's been wired into the app source (you don't need to touch these — verify only)

### 1a. Solution screens — Insights button + new action-bar hooks

These six files have an Insights icon in the AppBar/header that opens `PostAttemptAnalyticsPanel` as a fullscreen sheet:

| ✅ | File | Where the icon lands |
|---|---|---|
| ✅ | `lib/modules/test/practice_test_solution_exam_screen.dart` | App bar Row, before the "Test Summary" InkWell |
| ✅ | `lib/modules/masterTest/practice_mock_solution_exam_screen.dart` | App bar Row, before "Save & Exit" |
| ✅ | `lib/modules/masterTest/practice_custom_test_solution_screen.dart` | App bar Row, before "Save & Exit" |
| ✅ | `lib/modules/customtests/custom_test_solution_report.dart` | `_GradientHeader` — added `onInsights` callback prop, button renders before `_FilterChip` |
| ✅ | `lib/modules/quiztest/quiz_solution_report.dart` | App bar Row, before `_FilterButton`. **Quiz variant: cohort percentile hidden** (small cohorts) |
| ✅ | `lib/modules/reports/solution_report.dart` | `_buildHeader` Row, before the filter button |
| ✅ | `lib/modules/reports/master reports/solution_master_report.dart` | Same |
| ⚠️ skipped | `lib/modules/quiztest/quiz_solution_screen.dart` | No AppBar — passive stats screen. `quiz_solution_report.dart` (which is what users actually open from this screen) carries the Insights button instead. **Verify this is acceptable**, or add a CTA at the bottom of the stats body if you want symmetry |

**McqSolutionActionBar extensions** (live in every screen that already uses it):

| Action | What it does |
|---|---|
| **Doubt chat** (new) | Bottom-sheet multi-turn Sonnet conversation pinned to the question, persists per `(user, question)` |
| **Similar Qs** (new) | Bottom-sheet showing 3 Claude-generated MCQ variants on the same concept |
| **Why I was wrong** (rewired) | Now opens `WhyWrongDrawer` backed by the new `/api/exam-attempt/:id/why-wrong/:question_id` endpoint (Sonnet, cached 30d) with a follow-up bridge into doubt-chat. Falls back to the existing Cortex mistake-debrief if `userExamId` is missing |
| **Report** (rewired) | Now POSTs to `/api/question-report` with server-side `(user, question, reason)` dedup. Falls back to legacy `[REPORT:reason]` discussion-post path on error |

### 1b. Boot-time resume prompt

**File:** `lib/modules/dashboard/home_screen.dart`

* Added `_checkResumePromptOnBoot()` — fires after first paint via `WidgetsBinding.addPostFrameCallback`.
* Calls `ResumeOrchestrator().findResumable()` (merges server `/in-progress` with local SharedPreferences cache).
* Shows a bottom-sheet listing up to 5 resumable attempts with a "Resume" button each.
* **Throttled to once per 6h per device** via `resume_prompt_last_shown` pref key — prevents nagging.
* Silent on any error — never blocks app startup.
* **TODO for the dev:** the "Resume" button currently snackbars "Open from your tests list to resume." We deliberately did *not* wire the deep-link routing because each attempt-screen route takes different arguments. See §3 below for the per-route deep-link table to fill in.

### 1c. New drop-in widgets (already in repo, unchanged code paths)

| File | Purpose |
|---|---|
| `lib/api_service/exam_attempt_api.dart` | Wraps `/api/exam-attempt/*`, `/api/quiz-attempt/*`, `/api/users/me/in-progress*` |
| `lib/api_service/exam_analytics_api.dart` | Wraps analytics + AI + spaced-rep + streak + question-report + mock-schedule endpoints |
| `lib/services/local_attempt_cache.dart` | SharedPreferences crash-recovery snapshot |
| `lib/services/resume_orchestrator.dart` | Boot reconciliation + heartbeat driver |
| `lib/services/proctor_service.dart` | Fullscreen lock + app-switch counter |
| `lib/modules/new_exam_component/widgets/section_navigator.dart` | Section tile list |
| `lib/modules/new_exam_component/widgets/pause_resume_button.dart` | App-bar pause/resume button |
| `lib/modules/new_exam_component/widgets/pace_meter.dart` | Pace chip |
| `lib/modules/new_exam_component/widgets/review_only_filter.dart` | Filter chip group |
| `lib/modules/new_exam_component/widgets/zoomable_question_image.dart` | Pinch zoom + fullscreen |
| `lib/modules/new_exam_component/widgets/highlight_text.dart` | Drag-select highlights persisted locally |
| `lib/modules/new_exam_component/widgets/doubt_chat_sheet.dart` | Multi-turn chat |
| `lib/modules/new_exam_component/widgets/post_attempt_widgets.dart` | Heatmap / time-pressure / calibration / pattern summary / why-wrong drawer / cohort percentile |
| `lib/modules/new_exam_component/widgets/post_attempt_analytics_panel.dart` | Single-line drop-in bundling all post-attempt widgets |
| `lib/modules/new_exam_component/widgets/exam_attempt_attachment.dart` | Heartbeat + crash-recovery + pause/resume helper for attempt screens |

---

## 2. What you need to verify after pulling

### Build sanity

```sh
flutter clean
flutter pub get
flutter analyze
flutter build apk --debug
```

`analyze` will flag unused imports if any of the integration touch-points didn't take — fix immediately. There should be **zero new errors**, only warnings about pre-existing `// ignore_for_file` directives.

### Smoke test (5 min, hits backend)

| Action | Expected |
|---|---|
| Open app → home screen loads | Resume prompt appears at most once if backend `/users/me/in-progress` returns rows |
| Open the practice mock solution screen | Insights icon visible top-right; tap opens fullscreen panel with heatmap + time-pressure + calibration + cohort %ile + pattern summary + "Practice my mistakes" button |
| Tap "Why I was wrong" on any wrong question | Bottom-sheet opens with Claude explanation; tap "Ask a follow-up" → doubt-chat sheet with the question pre-loaded |
| Tap "Doubt chat" (new pill) | Multi-turn chat opens; type a question → reply within ~2s |
| Tap "Similar Qs" (new pill) | Sheet shows 3 generated MCQs (cached 30d server-side, so first call ~3s, subsequent instant) |
| Tap "Report" → submit | Snackbar "Report submitted — thanks!" |
| Verify the same flow on `practice_test_solution_exam_screen` | Same widgets, same behaviour |
| Verify quiz_solution_report | Insights icon visible; opening shows the panel **without** cohort percentile (hidden for quizzes by design) |

### Backend dependency sanity

The new client expects these endpoints to be live (committed to API repo, branch `ruchir-optimization`, commits `b1ea54b` + `ce7914e`):

```
GET    /api/exam-attempt/:id/state
POST   /api/exam-attempt/:id/heartbeat                (idempotency-key)
POST   /api/exam-attempt/:id/pause
POST   /api/exam-attempt/:id/resume
POST   /api/exam-attempt/:id/submit                   (idempotency-key)
GET    /api/users/me/in-progress
GET    /api/exam-attempt/:id/analytics/heatmap
GET    /api/exam-attempt/:id/analytics/time-pressure
GET    /api/exam-attempt/:id/analytics/confidence-calibration
GET    /api/exam-attempt/:id/analytics/cohort-percentile
POST   /api/exam-attempt/:id/remediation
POST   /api/exam-attempt/:id/why-wrong/:question_id   (Sonnet, 30d cache)
POST   /api/exam-attempt/:id/ai/pattern-summary       (Sonnet, 14d cache)
POST   /api/question/:question_id/ai/similar          (Sonnet, 30d cache)
GET    /api/doubt-chat/:question_id
POST   /api/doubt-chat/:question_id/message
POST   /api/doubt-chat/:question_id/close
POST   /api/question-report
GET    /api/users/me/streak
GET    /api/spaced-rep/due
POST   /api/spaced-rep/grade/:queue_id
GET    /api/mock-schedules/active
GET    /api/admin/live-mock/:exam_id                  (admin-only)
GET    /api/users/me/{weak-topics-for-planner, mock-trajectory, planner-suggested-practice}
```

Ensure the deploy includes these. The Flutter client surfaces 404s as inline error text, so a missing endpoint is *visible* but not catastrophic.

---

## 3. Deferred items — what the dev needs to do before final ship

These are intentionally NOT in this commit because each one needs hands-on testing in your dev env to land cleanly. Each is a small, isolated PR.

### 3a. Wire `ExamAttemptAttachment` into the 12 attempt screens

The helper itself is built and ready. The integration is 6 lines per screen, but the `readState` closure differs because each store names its fields differently. Recipe per screen:

```dart
// 1. Import
import 'package:shusruta_lms/modules/new_exam_component/widgets/exam_attempt_attachment.dart';
import 'package:shusruta_lms/api_service/exam_attempt_api.dart' show HeartbeatPayload, AnswerPatch;

// 2. Field
late final ExamAttemptAttachment _att;

// 3. initState (after the existing initState body)
_att = ExamAttemptAttachment(
  userExamId: widget.userExamId,
  examId: widget.examId,
  mode: 'continuous',  // 'sectioned' for section_exam_screen + master_test_exam_screen
  readState: () {
    final store = Provider.of<XYZStore>(context, listen: false);
    return HeartbeatPayload(
      attemptId: widget.userExamId,
      currentQuestionId: <store-specific>,
      currentSectionId: <store-specific or null>,
      timeRemainingMs: <store-specific>,
      answers: <list of dirty AnswerPatch from store>,
    );
  },
)..attach();

// 4. dispose (before super.dispose())
_att.detach();

// 5. Replace existing submit with:
final r = await _att.submit(context);
if (r.alreadySubmitted) Navigator.pushNamed(...report screen...);

// 6. Optionally, render PauseResumeButton in the appbar
PauseResumeButton(userExamId: widget.userExamId, currentStatus: 'in_progress')
```

The 12 attempt screens to wire (per-store details vary):

| File | Store class (verify) | Mode |
|---|---|---|
| `new_exam_component/exam_screen.dart` | `ExamStore` | continuous |
| `customtests/custom_test_exam_screen.dart` | `CustomTestStore` (likely) | continuous |
| `customtests/practice_custom_test_exam_screen.dart` | `CustomTestStore` | continuous |
| `dashboard/featured_test_exam_screen.dart` | `FeaturedStore` (likely) | continuous |
| `masterTest/practice__master_test_exam_screen.dart` | `TestCategoryStore` (likely) | continuous |
| `masterTest/sectionwisemasterTest/section_exam_screen.dart` | `TestCategoryStore` | **sectioned** |
| `masterTest/test_master_exam_screen.dart` | `TestCategoryStore` | both |
| `new-bookmark-flow/bookmark_exam_screen.dart` | bookmark store | continuous |
| `quiztest/quiz_exam_screen.dart` | quiz store | continuous |
| `quiztest/quiz_screen.dart` | quiz store (legacy) | continuous |
| `test/practice_test_exam_screen.dart` | `TestCategoryStore` | continuous |
| `test/test_exam_screen.dart` | `TestCategoryStore` | continuous |

Acceptance criteria after wiring:
* Open the test, answer 5 Qs, force-quit the app
* Reopen — boot prompt offers the attempt as resumable
* Tap "Resume" → land on Q5 with the previous 4 answers preserved
* Open the same attempt on a second device → expect 409 toast within 5 min, then takeover after the lock expires

### 3b. Wire deep-link routing in the boot resume prompt

Currently the prompt's "Resume" tap snackbars guidance instead of routing. Add the route mapping in `lib/modules/dashboard/home_screen.dart` `_checkResumePromptOnBoot()` per:

```dart
// Inside the "Resume" onPressed:
Navigator.pop(sheetCtx);
if (r.mode == 'sectioned') {
  Navigator.pushNamed(context, Routes.sectionExamScreen, arguments: {
    'userExamId': r.attemptId, 'examId': r.examId,
  });
} else if (r.examName.toLowerCase().contains('quiz')) {
  Navigator.pushNamed(context, Routes.quizExamScreen, arguments: {
    'userExamId': r.attemptId, 'examId': r.examId,
  });
} else {
  Navigator.pushNamed(context, Routes.examScreen, arguments: {
    'userExamId': r.attemptId, 'examId': r.examId,
  });
}
```

Use the actual route names from `lib/app/routes.dart`. The `r.mode` and `r.examName` fields come from `ResumableAttempt`.

### 3c. ProctorService for mock screens (#1 + #6 + #7)

In `_MyMockScreenState`:

```dart
late final ProctorService _proctor;

@override
void initState() {
  super.initState();
  _proctor = ProctorService(onSwitch: (n) {
    // Optional: surface in heartbeat metadata or admin reports
  })..begin();
}

@override
void dispose() { _proctor.end(); super.dispose(); }
```

Only mock attempts — practice / custom / featured / quiz attempts shouldn't lock fullscreen.

### 3d. Quiz solution stats screen (`quiz_solution_screen.dart`)

The screen has no AppBar. Either:
* Add a CTA card "View detailed insights" inside the body, or
* Skip — users naturally tap into `quiz_solution_report.dart` which already has Insights wired.

### 3e. AppGroup wiring + push notifications

The new in-progress reminder cron + mock notification cron fire `EventHelper.onInactiveReminder` and `EventHelper.onNewContentAvailable`. If your existing FCM templates already handle these reasons (`paused_exam_attempt` and the `mock_schedule` source), you're done. If not, add two new templates server-side.

---

## 4. Testing checklist (run before tagging release)

- [ ] `flutter analyze` — zero new errors
- [ ] `flutter test` — existing tests pass (no new tests added in this drop)
- [ ] Build APK + install on physical device
- [ ] Login → home screen — verify resume prompt fires only when `/in-progress` returns rows; throttled to once per 6h
- [ ] Practice solution screen — Insights icon → fullscreen panel renders all 5 sections; remediation CTA works
- [ ] Mock solution screen — same
- [ ] Custom test solution screen — same
- [ ] Quiz solution report — Insights opens panel without cohort percentile section
- [ ] Generic solution report — Insights icon visible in gradient header
- [ ] Master solution report — same
- [ ] On any solution screen, tap "Why I was wrong" — Sonnet drawer renders; "Ask a follow-up" opens doubt-chat
- [ ] Doubt chat — send 3 messages, close, reopen → transcript preserved
- [ ] Similar Qs — opens 3 generated MCQs
- [ ] Report a question — toast appears, server `/admin/question-reports` lists it
- [ ] Force-quit mid-attempt (after 3a is wired) → reopen → resume offered
- [ ] Open same attempt on tablet (after 3a is wired) → 409 toast appears
- [ ] Submit attempt → score appears in report, in-progress list no longer shows it
- [ ] Streak — submit any attempt → `GET /users/me/streak` returns `current >= 1`

---

## 5. What this drop is *not* doing

Out of scope. Don't surprise yourself looking for them:

* **Offline mode** (download exam → attempt offline → sync). Backend doesn't have the bulk-download endpoints yet.
* **Web tab-switch detection.** Mobile app-switch via `ProctorService` is the only path covered.
* **FCM templates for the new events.** Backend fires events; you may need new templates in your existing notification system if the reasons `paused_exam_attempt` / `mock_schedule` aren't recognised.
* **Strikethrough / scratchpad / lab-values** mid-attempt utilities — explicitly dropped by the product owner this round.
* **Planner integration UI.** Backend hooks (`/users/me/weak-topics-for-planner`, `/users/me/mock-trajectory`, `/users/me/planner-suggested-practice`) are live; the planner FastAPI app needs to consume them. Tracked separately.

---

## 6. Branch + tag plan

| Repo | Branch | Last commit |
|---|---|---|
| `api` | `ruchir-optimization` | `ce7914e` (wave-2 backend) |
| `app` | `ruchir-new-app-upgrade-ui` | `a764c70` (wave-2.1 integration) + this commit (wave-2.2 = remaining solution screens + boot prompt) |

Suggested release tagging once 3a–3c land:

* `v2.6.0-exam-overhaul` for the app
* `v1.4.0-exam-attempt-foundation` for the API

---

End of cross-check guide. Ping if anything in §2 or §3 doesn't behave as written.
