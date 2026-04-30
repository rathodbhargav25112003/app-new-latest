# Exam Attempt Flow — Frontend Integration Guide

> **Drop:** April 2026 backend + Flutter foundations + second wave (analytics, AI, widgets)
> **Scope:** Resume / pause / heartbeat / atomic submit + section-mode + crash recovery + full analytics suite + Claude AI suite + drop-in widgets
> **Status:** API layer complete (incl. all analytics + Claude). Flutter API clients + crash-recovery + resume orchestrator + all widgets scaffolded. UI wire-up into the existing exam_store is the only remaining step.

## TL;DR — what changed in wave 2

**Backend extensions** (single commit on top of wave 1):
- `/exam-attempt/:id/analytics/confidence-calibration` — 10-bin calibration + Brier score
- `/exam-attempt/:id/analytics/cohort-percentile` — your score vs everyone else on the same exam
- `/exam-attempt/:id/remediation` — auto-builds a "practice my mistakes" attempt
- `/exam-attempt/:id/ai/pattern-summary` — Claude 200-word "what to study next"
- `/question/:id/ai/similar` — Claude 3 generated MCQs on the same concept
- `/doubt-chat/:question_id` (+ `/message`, `/close`) — multi-turn Claude doubt-chat
- `/spaced-rep/due` + `/spaced-rep/grade/:id` — wraps existing review queue
- `/users/me/streak` — daily activity streak (auto-incremented on submit)
- `/question-report` (+ admin `/admin/question-reports`) — flag bad questions
- `/admin/mock-schedule` (+ `/mock-schedules/active`) — admin schedules + user-side current
- `/admin/live-mock/:exam_id` — admin live engagement dashboard
- `/users/me/{weak-topics-for-planner, mock-trajectory, planner-suggested-practice}` — planner integration hooks
- Two new crons: in-progress reminder push (daily 6pm IST), mock schedule notifications (every 5 min)
- `recordActivity` fires on submit so streak ticks up automatically

**Flutter additions**:
- [exam_analytics_api.dart](lib/api_service/exam_analytics_api.dart) — typed client for the analytics + AI suite
- [proctor_service.dart](lib/services/proctor_service.dart) — fullscreen lock + app-switch counter (#27, #29)
- Widgets under [lib/modules/new_exam_component/widgets/](lib/modules/new_exam_component/widgets/):
  - `section_navigator.dart` (#Phase 2C)
  - `pause_resume_button.dart` (#Phase 2D)
  - `pace_meter.dart` (#10)
  - `review_only_filter.dart` (#11)
  - `zoomable_question_image.dart` (#12)
  - `highlight_text.dart` (#7) — local-persisted highlights via SharedPreferences
  - `post_attempt_widgets.dart` — heatmap / time-pressure / calibration / pattern summary / why-wrong drawer / cohort percentile bar
  - `doubt_chat_sheet.dart` — bottom-sheet multi-turn chat (#22)

All Flutter widgets are theme-agnostic — they read `Theme.of(context)` so the integrator can drop them into the existing scaffold and they'll match the app's color scheme automatically.

---

## 1. What shipped in this drop

### Backend (`api-ruchir-optimization`)
- New schema fields on `User_exam`, `UserSectionExam`, `MasterExam`, `QuizUserExam` (additive — no migration required)
- New REST endpoints under `/api/exam-attempt/*`, `/api/quiz-attempt/*`, `/api/users/me/in-progress`
- `Idempotency-Key` middleware on heartbeat, submit, and existing answer-submit routes
- Anti-double-attempt guard (409 `ACTIVE_SESSION_ELSEWHERE`)
- Sweeper cron — auto-flips stale `in_progress` attempts to `paused` after 5 min of silence
- `/api/exam-attempt/:id/analytics/heatmap` — topic weakness heatmap
- `/api/exam-attempt/:id/analytics/time-pressure` — rushed-vs-lingered quadrants
- `POST /api/exam-attempt/:id/why-wrong/:question_id` — Claude Sonnet explanation, 30-day Redis cache

### Flutter (`app-update_fixes_merge`)
- `lib/api_service/exam_attempt_api.dart` — typed wrapper over the new endpoints with DTOs and exception types
- `lib/services/local_attempt_cache.dart` — SharedPreferences-backed snapshot for crash recovery
- `lib/services/resume_orchestrator.dart` — boot-time resume detection + heartbeat driver

These are **stand-alone files**. The existing `exam_store.dart` is untouched. Wiring them into the existing flow is the next sprint's job; this guide tells you exactly how.

### What's deferred (next sprint)
See [§9 Deferred Work](#9-deferred-work). Short version: section-navigator widget, pause/resume button UI, mid-attempt utilities (strikethrough, highlight, scratchpad, lab-values drawer), the rest of the Claude AI hooks, the rest of the post-attempt analytics, planner integration, proctoring, engagement features.

---

## 2. The state machine

Every attempt is in one of four states. Old rows (created before this drop) default to `in_progress`; submit them by calling the new submit endpoint to flip them to `submitted`, OR run a one-time backfill (see §10).

```
   ┌───────────────┐  POST /pause   ┌──────────┐  POST /resume  ┌───────────────┐
   │ in_progress   │───────────────▶│ paused   │───────────────▶│ in_progress   │
   └───────┬───────┘                └────┬─────┘                └───────┬───────┘
           │                             │                              │
           │ POST /submit                │ POST /submit                 │ POST /submit
           ▼                             ▼                              ▼
   ┌──────────────────────────────────────────────────────────────────────────────┐
   │                          submitted (terminal)                                │
   └──────────────────────────────────────────────────────────────────────────────┘
   ┌──────────────────────────────────────────────────────────────────────────────┐
   │      abandoned — set by admin reset OR auto-expired past hard end_time       │
   └──────────────────────────────────────────────────────────────────────────────┘
```

**Terminal states reject all writes** — heartbeat / pause / resume / submit on a `submitted` or `abandoned` attempt return `410`.

The sweeper (1-minute cron) auto-flips `in_progress` → `paused` if no heartbeat in 5 min. The user's resume UX is unchanged either way; the difference is whether a *second device* trying to resume gets the 409 anti-double-attempt block.

---

## 3. Endpoint reference

All endpoints require `mw(['user', 'admin'])` — same JWT auth header as the rest of the app (`Authorization: <token>`, no Bearer prefix).

### `GET /api/exam-attempt/:id/state`
Full payload to remount the attempt UI. Use this on resume or first mount.

**Response shape**
```json
{
  "attempt": {
    "id": "...",
    "exam_id": "...",
    "status": "in_progress" | "paused" | "submitted" | "abandoned",
    "mode": "continuous" | "sectioned",
    "start_time": "...", "end_time": "...",
    "last_saved_at": "...", "paused_at": null, "submitted_at": null,
    "time_remaining_ms": 1234567,
    "current_question_id": "...",
    "current_section_id": null,
    "device_id": "abc123",
    "isPractice": false,
    "userExamType": "All Questions",
    "question_order": ["qid1", "qid2", ...]
  },
  "answers": [
    {
      "question_id": "...",
      "selected_option": "B",
      "attempted": true, "skipped": false,
      "marked_for_review": false, "bookmarks": false,
      "confidence": 80, "time_spent_ms": 24000
    }
  ],
  "sections": [
    {
      "section_id": "Anatomy",
      "status": "in_progress" | "available" | "submitted" | "locked",
      "time_remaining_ms": 1080000,
      "started_at": "...", "submitted_at": null,
      "current_question_id": "...",
      "questions_answered": 12
    }
  ]
}
```

### `POST /api/exam-attempt/:id/heartbeat`
Idempotent autosave. Send every 15 seconds during attempt + on `AppLifecycleState.paused` + on question navigation.

**Headers** — `Idempotency-Key: <uuid-v4>` (recommended), `X-Device-Id: <stable-device-id>`

**Body** (all fields optional)
```json
{
  "current_question_id": "...",
  "current_section_id": "Anatomy",
  "time_remaining_ms": 1234567,
  "sections_time_remaining": [
    { "section_id": "Anatomy", "time_remaining_ms": 1080000, "status": "in_progress" }
  ],
  "answers": [
    {
      "question_id": "...",
      "selected_option": "B",
      "attempted": true,
      "marked_for_review": false,
      "bookmarks": false,
      "confidence": 80,
      "time_spent_ms": 24000
    }
  ]
}
```

**Limits**
- 30 heartbeats / 5 sec / user (rate limit)
- Max 100 answers per heartbeat (defends against flood)
- Same `Idempotency-Key` replays the cached response (24h TTL); body changes ARE NOT detected — rotate the key for new logical actions

**Error codes**
- `409 ACTIVE_SESSION_ELSEWHERE` — your `X-Device-Id` differs from the attempt's claimed device, and the attempt is still fresh. Body includes `stale_since_ms`. Surface this to the user as "you have this exam open on another device — close it there or wait 5 minutes."
- `410 ATTEMPT_FINALIZED` — attempt already submitted/abandoned. Stop heartbeating.
- `404` — attempt not found
- `403` — attempt belongs to another user
- `425` — duplicate idempotency key still in flight; retry shortly
- `429` — heartbeat rate limit; back off

### `POST /api/exam-attempt/:id/pause`
Explicit pause. Body empty. Sets `status: paused`, `paused_at: now`. Same device check as heartbeat.

### `POST /api/exam-attempt/:id/resume`
Explicit resume. Body empty. Sets `status: in_progress`, clears `paused_at`. Refreshes `device_id` claim.

### `POST /api/exam-attempt/:id/submit`
Atomic finalize. Idempotent — second call on already-submitted attempt returns the same result with `already_submitted: true`.

**Headers** — `Idempotency-Key: submit-<attempt_id>` (the Flutter client uses this stable key by default — protects against double-tap)

**Response**
```json
{
  "ok": true,
  "already_submitted": false,
  "submitted_at": "...",
  "score": 82,
  "correctCount": 41,
  "incorrectCount": 7,
  "skippedCount": 2
}
```

After this you can still call `GET /api/getReportBySubmit/:id` (the existing report endpoint) for the full breakdown. The new submit endpoint only LOCKS the attempt; the report endpoint generates the human-readable result.

### `GET /api/users/me/in-progress?limit=20`
Drives the "Resume?" prompt on app open. Returns up to 20 resumable attempts (status `in_progress` or `paused`), sorted by `last_saved_at` desc.

```json
{
  "attempts": [
    {
      "id": "...",
      "exam_id": "...",
      "exam_name": "Mock Test 4",
      "mode": "sectioned",
      "status": "paused",
      "last_saved_at": "...",
      "paused_at": "...",
      "time_remaining_ms": 1234567,
      "current_question_id": "...",
      "current_section_id": "Anatomy",
      "questions_answered": 18,
      "isPractice": false
    }
  ]
}
```

### Quiz variants
Same shape, different model:
- `GET /api/quiz-attempt/:id/state`
- `POST /api/quiz-attempt/:id/heartbeat`
- `GET /api/users/me/in-progress-quizzes`

### Analytics + AI
- `GET /api/exam-attempt/:id/analytics/heatmap` — topic + subtopic weakness ranked by `weakness_score = (1 - accuracy) * sqrt(count)`. Color-rank UI directly off this score.
- `GET /api/exam-attempt/:id/analytics/time-pressure` — 4 quadrants `{ rushed_correct, rushed_wrong, lingered_correct, lingered_wrong, normal }` with question ids per bucket. Thresholds: `<20s = rushed`, `>2 min = lingered`.
- `POST /api/exam-attempt/:id/why-wrong/:question_id` — Claude Sonnet explanation, cached 30 days. Returns `{ text, cached, correct_option, student_choice, is_correct }`. Display `text` directly; it's plain prose + bullets.

---

## 4. Flutter integration — bare-minimum wiring

### 4a. App boot — surface the resume prompt

In your top-level `App` widget's `initState` (or wherever you currently boot user-state checks):

```dart
import 'lib/services/resume_orchestrator.dart';
import 'lib/services/local_attempt_cache.dart';

final _orchestrator = ResumeOrchestrator();

@override
void initState() {
  super.initState();
  _checkResume();
  WidgetsBinding.instance.addObserver(this); // for didChangeAppLifecycleState
}

Future<void> _checkResume() async {
  final list = await _orchestrator.findResumable();
  if (list.isEmpty) return;
  // Show a bottom sheet / dialog listing list[].examName, last_saved_at, status.
  // On tap: route into existing exam screen with `attemptId = list[i].attemptId`.
  // The exam_store will call ExamAttemptApi.getState(attemptId) on mount.
  showResumePrompt(list);
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
    _orchestrator.flushNow(); // last-chance heartbeat
  }
}
```

If `ResumableAttempt.localFresher == true`, the local cache has unsynced edits — call `flushNow()` BEFORE re-fetching `getState()` so the server picks them up.

### 4b. Inside the exam screen — replace the existing 1-min auto-save timer

Today, `exam_store.dart` runs a periodic timer that calls bulk-save every minute. Replace that with the orchestrator's heartbeat driver:

```dart
// In ExamStore, after the attempt loads and questionList is populated:
final orchestrator = ResumeOrchestrator();
orchestrator.startHeartbeat(
  attemptId: userExamId,
  interval: const Duration(seconds: 15),
  getPayload: () async => HeartbeatPayload(
    attemptId: userExamId,
    currentQuestionId: question.value?.id,
    currentSectionId: currentSectionId.value,
    timeRemainingMs: tracker.value.remainingMs,
    answers: dirtyAnswers, // ← only the answers touched since last heartbeat
  ),
);

// On dispose / submit:
orchestrator.stopHeartbeat();
```

The 15s cadence is a balance — fast enough that crash-recovery loses ≤15s, slow enough that the rate limit (30/5s) is impossible to hit.

### 4c. Local cache mirror — write before network

Inside the existing answer-tap handler in the store:

```dart
final cache = LocalAttemptCache();

void onAnswerTapped({
  required String questionId,
  required String option,
  required int timeSpentMs,
}) async {
  final patch = AnswerPatch(
    questionId: questionId,
    selectedOption: option,
    attempted: true,
    skipped: false,
    timeSpentMs: timeSpentMs,
  );

  // 1. Local mirror — instant durability across crashes.
  await cache.upsertAnswer(userExamId, patch);

  // 2. Add to dirtyAnswers list — picked up by next heartbeat.
  dirtyAnswers.add(patch);

  // 3. Update MobX observable as before.
  _updateLocalAnswerState(...);
}
```

`upsertAnswer` is fire-and-forget at the UI level — the next heartbeat will pick it up.

### 4d. Pause / Resume button

```dart
final api = ExamAttemptApi();

// pause:
await api.pause(userExamId);
orchestrator.stopHeartbeat();
// navigate back to home — the attempt is safe.

// resume (from the in-progress list tile):
await api.resume(attemptId);
final state = await api.getState(attemptId);
// hydrate exam_store from `state` — see §4a.
```

### 4e. Submit — replace the existing flow

```dart
final result = await api.submit(userExamId);
// result.alreadySubmitted == true → user double-tapped; just navigate to report.
// otherwise → result.score, result.correctCount, etc. are authoritative.
```

After submit:
- Stop the orchestrator heartbeat
- Delete the local cache snapshot: `await cache.delete(userExamId)`
- Navigate to existing report screen (uses `getReportBySubmit/:id`)

---

## 5. Section-mode flow

When `state.attempt.mode == 'sectioned'` (or `MasterExam.mode == 'sectioned'`, or legacy `isSection: true`), render the section navigator instead of the flat question list.

The state payload returns `state.sections[]` with one entry per section. Each section has:
- `status` — `locked | available | in_progress | submitted`
- `time_remaining_ms` — per-section timer; tick this down independently
- `current_question_id` — where the user was inside this section
- `questions_answered` — denormalized count for the navigator badge

**Section enter** — when the user taps into section X:
1. Send a heartbeat with `current_section_id: 'X'` AND `sections_time_remaining: [{ section_id: 'X', status: 'in_progress', time_remaining_ms: T }]`
2. Hydrate the question list filtered to that section's `question_id[]` (from `MockSection.sectionWise`)

**Section submit** — when the per-section timer hits zero OR user taps "Submit Section":
1. Send a heartbeat with `sections_time_remaining: [{ section_id: 'X', status: 'submitted' }]`
2. Move to the next available section (if any) OR show the final submit CTA if all sections are submitted

**Top-level submit** — call `POST /api/exam-attempt/:id/submit`. The server marks any still-`in_progress` sections as submitted automatically.

---

## 6. Idempotency-Key conventions

The Flutter client (`ExamAttemptApi`) auto-generates a UUIDv4 per heartbeat. Don't override unless you have a specific reason.

For submit, the client uses a stable key `submit-<attempt_id>` so a rapid double-tap never produces two submit requests.

For the existing answer-submit endpoints (`/api/UserAnswer/create`, `/v2/createV2`, `/v2/createFullTestAnswer`, `/createUserAnswerByType`) — the middleware now reads `Idempotency-Key`. **Send a fresh UUID per logical save action**. Do NOT reuse a key across question changes (different intent = different key).

When the server replays a cached response, it sets `X-Idempotent-Replay: 1`. Useful for client-side debugging — confirms the server didn't actually run the handler again.

---

## 7. Anti-double-attempt — the 409

If the user opens the same exam on phone + tablet:
1. Phone heartbeats first → claims `device_id = "phone-uuid"`
2. Tablet tries to heartbeat → server checks: phone's `last_saved_at` < 5 min ago → returns `409 ACTIVE_SESSION_ELSEWHERE` with `stale_since_ms: <how long since phone last saved>`

**Recommended UX**: a blocking dialog: *"This attempt is open on another device. Close it there, or wait {ceil((5min - stale_since)/60)} minutes for the lock to expire."*

When the dialog times out (or user taps "force takeover"), the tablet retries — by then the lock is stale enough to break and the tablet wins.

The 409 also fires on `pause`, `resume`, `submit` — all four endpoints validate the same way.

---

## 8. Local cache + server reconciliation

The orchestrator's `findResumable()` already does the reconciliation; you don't usually need to think about it. But the rule, for completeness:

- **Server-only** entry → fresh attempt with no local cache yet. Just hydrate from `getState()`.
- **Local-only** entry → app crashed between attempt creation and first heartbeat. Hydrate from local snapshot, then send an immediate heartbeat to register on the server.
- **Both, server fresher** → server wins. Drop the local snapshot.
- **Both, local fresher (>5s)** → flush local diff to server first via heartbeat, THEN re-fetch `getState()`.

`evictStale()` should be called once a week or so to drop snapshots older than 7 days — those are dead attempts the user has likely abandoned.

---

## 9. Deferred work

Carry-over for the next sprint. Each item is independently shippable.

### High-priority (recommended for V1.5)
- **Section navigator widget** — drives sectioned-normal AND sectioned-mock flows. Today the mock-exam UI has bespoke section logic; we want one widget that reads from `state.sections[]` and renders the same in both modes.
- **Pause/Resume buttons in attempt screen** — wired to the API methods in §4d. UI design: a small icon-button in the app bar, with a confirmation dialog on first pause.
- **Cross-device resume UX polish** — the 409 dialog from §7 + a "force takeover" path that does an extra `resume` call after the 5-min stale window.

### Mid-priority (feature parity with V1.0 plan)
- **Mid-attempt strikethrough / eliminate options** — local-only state, persists in `LocalAttemptSnapshot.answers[].metadata` (extend the DTO).
- **Per-question scratchpad** — same: local-only, sync via heartbeat metadata.
- **Lab values quick-ref drawer** — static content, no API needed.
- **Pace meter** — derive from `time_remaining_ms` + `question_order.length` + how many are answered. Pure UI math.
- **Review-only navigator** — filter the existing palette by `marked_for_review` or `attempted == false`.
- **Image zoom/pan** — `photo_view` package, drop-in.

### Post-attempt depth (Group C)
- **Topic heatmap UI** — endpoint already shipped (`/analytics/heatmap`); render as a 2-level grid colored by `weakness_score`.
- **Time-pressure UI** — endpoint shipped (`/analytics/time-pressure`); render as a 2×2 quadrant with question chips.
- **Confidence vs correctness chart** — needs a small new endpoint `/analytics/confidence-calibration` that buckets by 10-pt confidence bins. Easy follow-up.
- **Auto-built remediation set** — backend already has `ReviewQueueBusiness.enrollWrongFromAttempt`. Wire a button: "Practice my mistakes" → calls the existing `/api/review-queue/enroll-from-attempt` then routes into a custom test of those questions.
- **Spaced-repetition queue** — `ReviewQueueBusiness` exists; needs a new screen that pulls today's due reviews.
- **Cohort percentile** — needs a new endpoint that aggregates score distribution across all users on the same exam. Defer to a sprint that has time for the leaderboard rework.

### Claude AI hooks (Group D)
- **Why wrong?** ✅ shipped (`POST /why-wrong/:question_id`). UI: a button on each wrong question in the review screen → drawer with `text`.
- **Pattern summary after attempt** — needs `POST /api/exam-attempt/:id/ai-summary`; takes the heatmap output + wrong-answer set + asks Sonnet for a 200-word "what to study next". Defer.
- **Similar-question generator** — needs an endpoint that takes a wrong question + asks Claude to write 3-5 variants. Defer.
- **Doubt chat per question** — multi-turn; needs a chat session model. Bigger lift. Defer.
- **Plan delta** — integrates with the planner; defer until planner Phase-1 ships.

### Engagement (Group E)
- **Streaks + daily quiz** — needs a `Streak` model + cron. Defer.
- **Scheduled mock notifications** — FCM push integration; needs schedule model. Defer.
- **In-progress reminder push** — once-a-day nudge if `/in-progress` returns anything. Easy follow-up.
- **Tab-switch detection** — on web only. Use `visibilitychange`; report counts in heartbeat metadata. Defer.

### Proctoring (#29)
- **Mock fullscreen lock** — `wakelock_plus` + system UI mode tweaks. Half-day task.

### Planner integration (Group G)
- All 6 items wait on the planner's Phase-1 schema landing. Track separately.

### Admin / ops
- **Mock exam scheduling UI** — admin route + simple form. Straightforward.
- **Question-report inbox** — needs a `QuestionReport` model + admin filter view.
- **Live mock dashboard** — needs aggregate over `/in-progress` for a given exam id.

---

## 10. Backfilling existing rows

Rows created before this drop have `status: 'in_progress'` (default). Most of them are actually completed attempts with `score > 0` whose UI just never explicitly submitted. Run this one-time backfill on a maintenance window:

```js
// Old finished attempts — score was computed via getReportBySubmit
await UserExamModel.updateMany(
  { status: { $exists: false } },
  { $set: { status: 'submitted', submitted_at: new Date(), last_saved_at: new Date() } }
);
// Or, if you want to be more careful: only flip ones with score > 0
await UserExamModel.updateMany(
  { status: 'in_progress', score: { $gt: 0 }, end_time: { $lt: new Date() } },
  { $set: { status: 'submitted', submitted_at: '$end_time' } }
);
```

The sweeper will flip everything else to `paused` within 5 minutes of deploy.

---

## 11. Testing checklist

Before flipping the feature flag in production:

- [ ] Heartbeat from device A, then heartbeat from device B → device B gets 409 with `stale_since_ms < 300000`
- [ ] Wait 5+ minutes, repeat → device B succeeds, device A's next heartbeat gets 409
- [ ] Mid-attempt force-quit the app → reopen → resume prompt appears, all answers preserved
- [ ] Mid-attempt airplane-mode for 10s → toggle back → next heartbeat succeeds, no answer loss
- [ ] Submit twice with same idempotency key → both calls return identical body, second has `already_submitted: true`
- [ ] Submit twice with different idempotency keys → first wins, second hits the 410 path (because attempt is now `submitted`)
- [ ] Sectioned attempt: pause mid-section → resume → land back on `current_question_id`, section timer resumed
- [ ] Cross-section navigation triggers heartbeat with new `current_section_id`
- [ ] `/users/me/in-progress` returns only `in_progress` + `paused`, never `submitted`
- [ ] `whyWrong` second call on same (attempt, question) returns `cached: true` and skips Claude

---

## 12. Files added in this drop

### Backend
- `src/business/examAttempt.business.js` — lifecycle logic
- `src/business/examAnalytics.business.js` — heatmap + time-pressure + why-wrong
- `src/routes/examAttempt.route.js` — REST routes
- `src/routes/examAnalytics.route.js` — analytics routes
- `src/utils/idempotency.util.js` — Redis-backed idempotency middleware
- Existing files modified (additive): `src/models/userExam.model.js`, `src/models/userSectionExam.model.js`, `src/models/masterExam.model.js`, `src/models/quizUserExam.model.js`, `src/cronjobs/cron.js`, `src/routes/user_answer.route.js`

### Flutter
- `lib/api_service/exam_attempt_api.dart` — typed API client
- `lib/services/local_attempt_cache.dart` — SharedPreferences snapshot
- `lib/services/resume_orchestrator.dart` — boot + heartbeat coordinator

---

## Questions / handoff notes

The `device_id` value comes from `ApiService().getDeviceInfo()` which is already used across the app. It's stable per install — survives app updates, doesn't survive uninstall+reinstall. Good enough for the anti-double-attempt guard; an attempt orphaned by a reinstall will resume on the new install once the 5-min sweeper window passes.

If you hit a `425 Too Early` on heartbeat, that's an in-flight collision — your retry should back off ~500ms and try again with the SAME idempotency key. The middleware will then either replay the cached response (if the first one finished) or accept the new request (if the first one crashed).

For sectioned exams that don't have a `MockSection` blueprint (e.g. a normal exam with `mode: sectioned` enabled fresh) — the section list comes from question metadata grouping, NOT from `MockSection`. We'll wire that path during the section-navigator sprint. For now, sectioned mode only works on attempts whose underlying exam already has a `MockSection`.

---

End of guide.
