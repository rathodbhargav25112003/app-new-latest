# Exam Attempt Integration Guide — v2 (per-screen wire-up)

> **Drop:** April 2026, second wave (wave-2.1 integration pass)
> **Companion to:** [EXAM_ATTEMPT_INTEGRATION_GUIDE.md](EXAM_ATTEMPT_INTEGRATION_GUIDE.md) (architectural overview, endpoint reference, state machine)
> **This doc:** the *exact* per-screen integration deltas — what's wired today, what's a one-liner away, what needs the next sprint.

---

## What changed in 2.1

Three new drop-in modules are shipped in this commit:

| File | Purpose | Where it goes |
|---|---|---|
| `lib/modules/new_exam_component/widgets/post_attempt_analytics_panel.dart` | `PostAttemptAnalyticsPanel(userExamId:)` — bundles heatmap, time-pressure, calibration, cohort percentile, pattern summary, remediation CTA in one widget | Solution / report screens |
| `lib/modules/new_exam_component/widgets/exam_attempt_attachment.dart` | `ExamAttemptAttachment` — `WidgetsBindingObserver` mixin that owns heartbeat + crash-recovery cache + pause/resume bridge | Attempt screens |
| (extended) `lib/modules/mcq_review_v3/widgets/mcq_solution_action_bar.dart` | Adds **Doubt chat**, **Similar Qs**, real `/api/question-report`, replaces "Why I was wrong" with the new Sonnet-cached `WhyWrongDrawer` (falls back to existing Cortex mistake-debrief when `userExamId` missing) | Already wired in solution screens — no caller changes needed |

Plus: **Insights** button shipped live in two solution screens (see §2 below).

---

## 1. Inventory — every MCQ-related screen in the repo

Attempt screens (where the user takes a test):

| # | File | Test type | Sectioned? |
|---|---|---|---|
| 1 | `lib/modules/new_exam_component/exam_screen.dart` | Master / mock | both |
| 2 | `lib/modules/customtests/custom_test_exam_screen.dart` | Custom | no |
| 3 | `lib/modules/customtests/practice_custom_test_exam_screen.dart` | Custom (practice) | no |
| 4 | `lib/modules/dashboard/featured_test_exam_screen.dart` | Featured | no |
| 5 | `lib/modules/masterTest/practice__master_test_exam_screen.dart` | Master (practice) | no |
| 6 | `lib/modules/masterTest/sectionwisemasterTest/section_exam_screen.dart` | Master (sectioned) | yes |
| 7 | `lib/modules/masterTest/test_master_exam_screen.dart` | Master | both |
| 8 | `lib/modules/new-bookmark-flow/bookmark_exam_screen.dart` | Bookmark practice | no |
| 9 | `lib/modules/quiztest/quiz_exam_screen.dart` | Daily quiz | no |
| 10 | `lib/modules/quiztest/quiz_screen.dart` | Quiz (legacy) | no |
| 11 | `lib/modules/test/practice_test_exam_screen.dart` | Practice | no |
| 12 | `lib/modules/test/test_exam_screen.dart` | Test | no |

Solution / review screens (post-submit review):

| # | File | Test type | `McqSolutionActionBar` already wired? | Wave-2 Insights wired in 2.1? |
|---|---|---|---|---|
| A | `lib/modules/test/practice_test_solution_exam_screen.dart` | Practice solution | ✅ (line ~2450) | ✅ **wired** — Insights icon in app-bar |
| B | `lib/modules/masterTest/practice_mock_solution_exam_screen.dart` | Mock solution | ✅ (line ~1221) | ✅ **wired** — Insights icon in app-bar |
| C | `lib/modules/masterTest/practice_custom_test_solution_screen.dart` | Custom solution | ⚠️ not yet | not yet |
| D | `lib/modules/customtests/custom_test_solution_report.dart` | Custom report | ⚠️ not yet | not yet |
| E | `lib/modules/quiztest/quiz_solution_report.dart` | Quiz report | ⚠️ not yet | not yet |
| F | `lib/modules/quiztest/quiz_solution_screen.dart` | Quiz solution | ⚠️ not yet | not yet |
| G | `lib/modules/reports/solution_report.dart` | Generic report | ⚠️ not yet | not yet |
| H | `lib/modules/reports/master reports/solution_master_report.dart` | Master report | ⚠️ not yet | not yet |

**Status:** action bar + wave-2 panel already live on the **two highest-traffic solution screens** (practice + mock). C–H are independent one-line additions and can ship one screen per PR.

---

## 2. The minimum-surface-area integration pattern

Adopted in 2.1 for solution screens. Reuse for C–H verbatim:

### Step 1 — add the import

```dart
import 'package:shusruta_lms/modules/new_exam_component/widgets/post_attempt_analytics_panel.dart';
```

### Step 2 — add the icon button to the existing app bar

```dart
if ((widget.userExamId ?? '').isNotEmpty)
  IconButton(
    icon: const Icon(Icons.insights_rounded),
    tooltip: 'Performance insights',
    onPressed: () => _openInsights(context),
  ),
```

### Step 3 — add the helper method on the State class

```dart
void _openInsights(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Performance insights')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: PostAttemptAnalyticsPanel(
          userExamId: widget.userExamId!,
          onRemediationCreated: (newId, count) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Remediation set ready ($count Qs). Find it in In-progress attempts.'),
            ));
          },
          // For quiz screens (E, F): pass `showCohortPercentile: false`
          // because daily quizzes have small cohorts and the percentile
          // misleads at low n.
        ),
      ),
    ),
  ));
}
```

That's it. Three edits, zero state changes, no risk to existing code paths.

---

## 3. Attempt-screen wiring — `ExamAttemptAttachment`

Same minimum-surface pattern for the 12 attempt screens. The helper owns:

* 15-second heartbeat to `/api/exam-attempt/:id/heartbeat`
* Local SharedPreferences mirror for sub-15s crash recovery
* `AppLifecycleState.paused` last-chance flush
* Pause / resume / submit bridge (returns typed `SubmitResult`, surfaces `409 ACTIVE_SESSION_ELSEWHERE` as a snackbar)

### Step 1 — declare the field

```dart
late final ExamAttemptAttachment _att;
```

### Step 2 — attach in `initState`

```dart
@override
void initState() {
  super.initState();
  _att = ExamAttemptAttachment(
    userExamId: widget.userExamId,
    examId: widget.examId,
    mode: 'continuous', // or 'sectioned' for #1, #6, #7
    readState: () => HeartbeatPayload(
      attemptId: widget.userExamId,
      currentQuestionId: store.question.value?.id,
      currentSectionId: store.currentSectionId.value,
      timeRemainingMs: store.tracker.value.remainingMs,
      answers: store.dirtyAnswers, // your store's pending-diff list
    ),
  )..attach();
}
```

### Step 3 — detach in `dispose`

```dart
@override
void dispose() {
  _att.detach();
  super.dispose();
}
```

### Step 4 — replace existing submit / pause / resume calls

```dart
final result = await _att.submit(context);  // atomic + idempotent
if (result.alreadySubmitted) { /* user double-tapped — route to report */ }
```

### Step 5 — render the `PauseResumeButton` in the app bar

```dart
PauseResumeButton(
  userExamId: widget.userExamId,
  currentStatus: 'in_progress',
  onPaused: () => Navigator.of(context).pop(),
  onResumed: () => setState(() {}),
)
```

### Step 6 — for sectioned screens (#1, #6, #7) render the navigator

```dart
SectionNavigator(
  sections: state.sections,
  activeSectionId: store.currentSectionId.value,
  onSectionTap: (s) => store.enterSection(s.sectionId),
  allowSubmitAll: true,
  onSubmitAll: () async {
    final r = await _att.submit(context);
    Navigator.of(context).pushNamed(Routes.solutionReport, arguments: { 'userexamId': widget.userExamId });
  },
)
```

---

## 4. Boot-time resume prompt

Wire once in `lib/app/app.dart` or wherever the post-login splash lives.

```dart
import 'package:shusruta_lms/services/resume_orchestrator.dart';

Future<void> _checkResumeOnStart() async {
  final list = await ResumeOrchestrator().findResumable();
  if (list.isEmpty || !mounted) return;
  showModalBottomSheet(
    context: context,
    builder: (_) => Column(
      children: list.map((r) => ListTile(
        title: Text(r.examName.isNotEmpty ? r.examName : 'In-progress attempt'),
        subtitle: Text('${r.questionsAnswered} answered · ${r.status}'),
        trailing: TextButton(
          child: const Text('Resume'),
          onPressed: () {
            Navigator.pop(context);
            // Route into the right attempt screen by mode:
            //   mode=='sectioned' → section_exam_screen
            //   mode=='continuous' && r.examName.contains('Mock') → test_master_exam_screen
            //   else → exam_screen
          },
        ),
      )).toList(),
    ),
  );
}
```

---

## 5. AppBar action menu — proctor + report shortcuts (optional)

For mock attempt screens (#1, #7) only, wire `ProctorService` so the
fullscreen lock + app-switch counter activates on enter:

```dart
late final ProctorService _proctor;
@override void initState() {
  super.initState();
  _proctor = ProctorService(onSwitch: (n) {
    // Optionally surface in heartbeat metadata via dirtyAnswers'
    // own "switches" field (not yet on AnswerPatch — defer to a
    // schema bump if you need server-side counts).
  })..begin();
}
@override void dispose() { _proctor.end(); super.dispose(); }
```

---

## 6. Per-screen status grid

Updated with this commit:

| Screen | `McqSolutionActionBar` | Wave-2 widgets | Status |
|---|---|---|---|
| **Attempt** screens | – | – | `ExamAttemptAttachment` ready to import; no screens wired yet (all 12 are independent one-line jobs) |
| **A** Practice solution | ✅ | ✅ Insights | **live** |
| **B** Mock solution | ✅ | ✅ Insights | **live** |
| **C** Master custom solution | ⚠️ | ⚠️ | one PR away — same 3-step recipe |
| **D** Custom report | ⚠️ | ⚠️ | same |
| **E** Quiz report | ⚠️ | ⚠️ | same; pass `showCohortPercentile:false` |
| **F** Quiz solution | ⚠️ | ⚠️ | same |
| **G** Solution report | ⚠️ | ⚠️ | same |
| **H** Master solution report | ⚠️ | ⚠️ | same |

Solution screens C–H all have the same shape (top-level Scaffold +
appbar + the rest is per-question rendering). Adding Insights to each
is a 3-line + 1-method patch using the recipe in §2.

For attempt screens, see §3 — `ExamAttemptAttachment` is the only
piece needed; the existing stores keep working as-is.

---

## 7. Quick-reference: the new endpoints, with one-line summaries

```
GET    /api/exam-attempt/:id/state                     — full resume payload
POST   /api/exam-attempt/:id/heartbeat                 — idempotent autosave
POST   /api/exam-attempt/:id/pause                     — explicit pause
POST   /api/exam-attempt/:id/resume                    — explicit resume
POST   /api/exam-attempt/:id/submit                    — atomic finalize
GET    /api/users/me/in-progress                       — boot-prompt list

GET    /api/exam-attempt/:id/analytics/heatmap         — topic weakness
GET    /api/exam-attempt/:id/analytics/time-pressure   — rushed/lingered × ✓/✗
GET    /api/exam-attempt/:id/analytics/confidence-calibration  — Brier + bins
GET    /api/exam-attempt/:id/analytics/cohort-percentile       — your %ile
POST   /api/exam-attempt/:id/remediation               — build practice set
POST   /api/exam-attempt/:id/why-wrong/:question_id    — Sonnet, cached 30d
POST   /api/exam-attempt/:id/ai/pattern-summary        — Sonnet, cached 14d
POST   /api/question/:question_id/ai/similar           — Sonnet, cached 30d

GET    /api/doubt-chat/:question_id                    — fetch / auto-create
POST   /api/doubt-chat/:question_id/message            — append + reply
POST   /api/doubt-chat/:question_id/close              — mark thread done

GET    /api/spaced-rep/due                             — due review cards
POST   /api/spaced-rep/grade/:queue_id                 — grade after review

GET    /api/users/me/streak                            — daily streak
POST   /api/question-report                            — flag a question
GET    /api/admin/question-reports                     — admin inbox
PATCH  /api/admin/question-report/:id                  — admin resolve
GET    /api/mock-schedules/active                      — unlocked mocks now
POST   /api/admin/mock-schedule                        — schedule a mock
GET    /api/admin/live-mock/:exam_id                   — live engagement

GET    /api/users/me/weak-topics-for-planner           — planner integration
GET    /api/users/me/mock-trajectory                   — planner timeline
GET    /api/users/me/planner-suggested-practice        — one-tap suggestion
```

Every write endpoint accepts an `Idempotency-Key` header (24h replay
cache in Redis). The Flutter `ExamAttemptApi` and `ExamAnalyticsApi`
clients auto-attach a UUIDv4 per call — you don't need to think about
it unless you want a stable key (the submit path already uses
`submit-<id>`).

---

End of v2 guide.
