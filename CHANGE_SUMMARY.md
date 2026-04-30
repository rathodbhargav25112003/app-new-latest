# Sushruta LMS — Change Summary, last few days

> Generated 2026-04-30. Covers the **exam attempt overhaul** initiative.
> For the integration recipes referenced below, see [EXAM_INTEGRATION_GUIDE_V2.md](EXAM_INTEGRATION_GUIDE_V2.md).
> For architectural detail, see [EXAM_ATTEMPT_INTEGRATION_GUIDE.md](EXAM_ATTEMPT_INTEGRATION_GUIDE.md).

## At a glance

Three repo-spanning waves of work shipped in the last few days, all on
the exam-attempt experience:

| Wave | What | Lines added | Lines changed | Files | Repos |
|---|---|---|---|---|---|
| 1 — Foundation | Resume / heartbeat / pause / submit + section-mode + crash recovery + idempotency | ~3,170 | ~9 | 15 | both |
| 2 — Depth | Full analytics + Claude AI suite + admin ops + planner hooks + 11 widgets | ~3,520 | ~3 | 23 | both |
| 2.1 — Integration | `PostAttemptAnalyticsPanel` + `ExamAttemptAttachment` + Insights wired into 2 highest-traffic solution screens + extended `McqSolutionActionBar` | this PR | small | 5 | app |

Earlier in the same week the **MCQ Review v3** wave landed (`mcq_review_v3` module, 22 features, `McqSolutionActionBar` wired into both solution screens). Wave-2.1 builds on top of that work — the existing action bar is *extended* rather than replaced.

---

## API repo (`api-ruchir-optimization`, branch `ruchir-optimization`)

### Wave 1 — `b1ea54b` Exam attempt foundation

Schema (additive, default-safe — no migration required):

* **User_exam** new fields: `status` enum (`in_progress`/`paused`/`submitted`/`abandoned`), `last_saved_at`, `current_question_id`, `current_section_id`, `time_remaining_ms`, `paused_at`, `submitted_at`, `device_id`. Three new compound indexes for the resume queries + sweeper.
* **UserSectionExam** promoted to a structured schema: per-section `status` enum, `time_remaining_ms`, `started_at`, `submitted_at`, `current_question_id`, denormalised `questions_answered`. Top-level `current_section_id` pointer.
* **MasterExam** new `mode: 'continuous' | 'sectioned'` enum (legacy `isSection` boolean stays for back-compat).
* **QuizUserExam** got the same lifecycle fields as User_exam.

Endpoints (kebab-case, `mw(['user','admin'])`):

* `GET /api/exam-attempt/:id/state` — full resume payload
* `POST /api/exam-attempt/:id/heartbeat` — idempotent autosave + answers diff + per-section timers
* `POST /api/exam-attempt/:id/pause` / `/resume`
* `POST /api/exam-attempt/:id/submit` — atomic finalize
* `GET /api/users/me/in-progress` — drives the boot-time resume prompt
* Quiz variants of all of the above

Cross-cutting:

* `src/utils/idempotency.util.js` — Redis-backed middleware, 24h replay cache, 425 on in-flight collision, fail-open if Redis is down. Wired on heartbeat, submit, and the four legacy `/api/UserAnswer/*` endpoints.
* Anti-double-attempt guard via `X-Device-Id` (409 `ACTIVE_SESSION_ELSEWHERE` with `stale_since_ms` so the client can show a "wait N min" countdown).
* Sweeper cron flips `in_progress` → `paused` after 5 min idle.

### Wave 2 — `ce7914e` Full analytics + Claude AI + admin ops + planner hooks

Analytics (extending `examAnalytics.business.js` + `.route.js`):

| Endpoint | What |
|---|---|
| `GET .../analytics/heatmap` | Topic + subtopic weakness, ranked by `(1 - accuracy) × √count` |
| `GET .../analytics/time-pressure` | 4 quadrants: rushed/lingered × correct/wrong with question ids per bucket |
| `GET .../analytics/confidence-calibration` | 10 confidence bins + accuracy + Brier score |
| `GET .../analytics/cohort-percentile` | Your %ile + 10-bin score histogram |
| `POST .../remediation` | Spawns a fresh `isPractice` `User_exam` scoped to wrong answers, fire-and-forget enrols into the existing `ReviewQueue` |
| `POST .../why-wrong/:question_id` | Claude Sonnet explanation, cached 30d in Redis |
| `POST .../ai/pattern-summary` | Sonnet 4–6 sentences fed by heatmap + wrong stems, cached 14d |
| `POST /api/question/:id/ai/similar` | Sonnet 3 generated MCQs, cached 30d (question-scoped, shared across users) |

Doubt chat (#22) — new model + business + routes:

* `DoubtChat` model: one thread per `(user, question)` with a message[] array + per-turn token accounting.
* `GET /api/doubt-chat/:question_id` (auto-creates), `POST .../message`, `POST .../close`.
* Hard caps: 30 turns / thread, 2000 chars / message, 1024 max output tokens / reply.

Streak (#24) — new model + business:

* `Streak` model with current/longest/`last_active_date`/total/`last_milestone`.
* IST-based day boundary (no UTC drift at midnight).
* Milestones at 3, 7, 14, 30, 60, 100, 200, 365 — fires `EventHelper.onStreakMilestone` exactly once per crossing.
* `recordActivity` hook wired into `submitAttempt` so streak ticks up automatically.
* `GET /api/users/me/streak`.

Spaced-rep (#17) — REST routes wrapping the existing `reviewQueue.business`:

* `GET /api/spaced-rep/due` and `POST /api/spaced-rep/grade/:id`.

Question reports (#34) — new model + routes:

* `POST /api/question-report` (deduped by `(user, question, reason)` server-side).
* `GET /api/admin/question-reports` with per-question open count.
* `PATCH /api/admin/question-report/:id` for resolve / dismiss.

Mock scheduling (#33) — new model + routes + cron:

* `POST/GET/PATCH/DELETE /api/admin/mock-schedule[s]`.
* `GET /api/mock-schedules/active` for the user-side "what's open right now".
* Cron every 5 min fires the pre-mock notification via `EventHelper.onNewContentAvailable`, marks `notify_sent`.

Live mock dashboard (#35):

* `GET /api/admin/live-mock/:exam_id?since_minutes=120` returns status counts, answered histogram, avg score among submits in window. Refresh every 30s for a "live" feel.

In-progress reminder cron (#26):

* Daily 6pm IST, finds users with a paused attempt 1 h to 7 d old, fires `EventHelper.onInactiveReminder(reason='paused_exam_attempt')`, capped 200/day.

Planner integration (#30-32):

* `GET /api/users/me/weak-topics-for-planner` — top weak topics across recent submitted attempts.
* `GET /api/users/me/mock-trajectory` — submitted-mock score + predicted-rank for the planner timeline.
* `GET /api/users/me/planner-suggested-practice` — one-tap "what should I practise now" suggestion.

### Files added / modified, last few days (API repo)

```
A  src/business/doubtChat.business.js
A  src/business/examAnalytics.business.js
A  src/business/examAttempt.business.js
A  src/business/streak.business.js
A  src/models/doubtChat.model.js
A  src/models/mockSchedule.model.js
A  src/models/questionReport.model.js
A  src/models/streak.model.js
A  src/routes/examAnalytics.route.js
A  src/routes/examAttempt.route.js
A  src/routes/examExtras.route.js
A  src/routes/examOps.route.js
A  src/utils/idempotency.util.js

M  src/cronjobs/cron.js                     (+3 cron jobs: sweeper, in-progress reminder, mock notify)
M  src/models/masterExam.model.js           (mode enum)
M  src/models/quizUserExam.model.js         (lifecycle fields)
M  src/models/userExam.model.js             (lifecycle fields, indexes)
M  src/models/userSectionExam.model.js      (structured per-section progress)
M  src/routes/user_answer.route.js          (idempotency middleware on 4 endpoints)
```

Total: 13 new files, 6 modified.

---

## App repo (`app-update_fixes_merge`, branch `ruchir-new-app-upgrade-ui`)

### Wave 1 — `2d036c9` API client + crash-recovery cache + resume orchestrator

* `lib/api_service/exam_attempt_api.dart` — typed wrapper for the new `/api/exam-attempt/*`, `/api/quiz-attempt/*`, `/api/users/me/in-progress*` endpoints. DTOs: `ResumeState`, `ResumeAttempt`, `ResumeAnswer`, `ResumeSection`, `InProgressAttempt`, `HeartbeatResult`, `SubmitResult`, `AnswerPatch`, `SectionTime`. Typed exceptions: `ActiveSessionElsewhere` (409), `AttemptFinalized` (410), `ExamAttemptException`. Auto-attaches `Authorization`, `X-Device-Id`, UUIDv4 `Idempotency-Key`.
* `lib/services/local_attempt_cache.dart` — SharedPreferences-backed snapshot of attempt pointer + timers + full answers map; survives any kind of process death. `upsertAnswer` / `updatePointer` mutators the store calls inline. Active-attempts side index for cheap iteration on app boot. `evictStale()` to drop snapshots older than 7 days.
* `lib/services/resume_orchestrator.dart` — `findResumable()` merges `/in-progress` server list with local snapshots; flags `localFresher` when local has unsynced edits. `startHeartbeat` / `stopHeartbeat` drive the periodic 15s heartbeat without the orchestrator needing a direct ref to the store. `flushNow()` for `AppLifecycleState.paused` last-chance saves.

### Wave 2 — `7d4ea01` Analytics API client + 11 widgets + proctor service

Flutter API client:

* `lib/api_service/exam_analytics_api.dart` — typed wrapper for the analytics + AI suite (heatmap, time-pressure, calibration, cohort percentile, remediation, why-wrong, pattern summary, similar questions, doubt-chat, streak, spaced-rep, mock schedules, question report) with full DTOs.

Stand-alone widgets under `lib/modules/new_exam_component/widgets/`:

* `section_navigator.dart` — sectioned-mode tile list with status / per-section timer / answered-count badge, drives both sectioned-normal and sectioned-mock flows.
* `pause_resume_button.dart` — app-bar button with confirmation dialog and 410 / 409 handling.
* `pace_meter.dart` — "X min behind" pure-UI indicator (no API).
* `review_only_filter.dart` — ChoiceChip group + filter helper.
* `zoomable_question_image.dart` — pinch-zoom inline + tap-to-fullscreen.
* `highlight_text.dart` — drag-select to highlight stem, persisted via SharedPreferences.
* `doubt_chat_sheet.dart` — bottom-sheet multi-turn chat (#22).
* `post_attempt_widgets.dart` — `TopicHeatmapView` / `TimePressureQuadrant` / `ConfidenceCalibrationChart` / `PatternSummaryCard` / `WhyWrongDrawer` / `CohortPercentileBar`.

Services:

* `lib/services/proctor_service.dart` — `WidgetsBindingObserver`-based fullscreen lock + app-switch counter. `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)` hides system bars; `didChangeAppLifecycleState` increments the counter on each `AppLifecycleState.paused`.

All widgets are theme-agnostic — read `Theme.of(context)`, no hard-coded brand palette, no new pubspec dependencies. Drop into the existing exam_screen scaffold and they pick up the app's theme automatically.

### Wave 2.1 — this commit (Integration pass)

New drop-ins:

* `lib/modules/new_exam_component/widgets/post_attempt_analytics_panel.dart` — bundles every analytics widget (pattern summary, cohort percentile, heatmap, time-pressure, calibration, remediation CTA) into one widget. Each section fetches its own data lazily — failures in one don't block the others.
* `lib/modules/new_exam_component/widgets/exam_attempt_attachment.dart` — `WidgetsBindingObserver` mixin that owns heartbeat + crash-recovery cache + pause/resume bridge for any attempt screen. Integrator supplies a `readState` closure that pulls from whatever store/controller they use — keeps the helper compatible with the existing `exam_store`, custom-test stores, and quiz stores without modification.

McqSolutionActionBar extension:

* New action: **Doubt chat** — bottom-sheet multi-turn Sonnet conversation pinned to the question (persists across sessions per `(user, question)`).
* New action: **Similar Qs** — Claude generates 3 variants on the same concept; rendered inline.
* "Why I was wrong" now routes to the new Sonnet `whyWrong` endpoint via `WhyWrongDrawer` (cached 30 d), with a "Ask a follow-up" button that opens the doubt-chat sheet. Falls back to the existing Cortex mistake-debrief when `userExamId` isn't available.
* Report flow now hits the dedicated `/api/question-report` endpoint instead of the legacy `[REPORT:reason]` discussion-post hack. Falls back gracefully on error.

Solution screens — Insights button wired live in:

* `lib/modules/test/practice_test_solution_exam_screen.dart`
* `lib/modules/masterTest/practice_mock_solution_exam_screen.dart`

### Files added / modified, last few days (App repo)

```
A  EXAM_ATTEMPT_INTEGRATION_GUIDE.md             (wave 1 & 2 overview)
A  EXAM_INTEGRATION_GUIDE_V2.md                  (per-screen recipes)
A  CHANGE_SUMMARY.md                             (this file)

A  lib/api_service/exam_attempt_api.dart
A  lib/api_service/exam_analytics_api.dart
A  lib/services/local_attempt_cache.dart
A  lib/services/resume_orchestrator.dart
A  lib/services/proctor_service.dart
A  lib/modules/new_exam_component/widgets/section_navigator.dart
A  lib/modules/new_exam_component/widgets/pause_resume_button.dart
A  lib/modules/new_exam_component/widgets/pace_meter.dart
A  lib/modules/new_exam_component/widgets/review_only_filter.dart
A  lib/modules/new_exam_component/widgets/zoomable_question_image.dart
A  lib/modules/new_exam_component/widgets/highlight_text.dart
A  lib/modules/new_exam_component/widgets/doubt_chat_sheet.dart
A  lib/modules/new_exam_component/widgets/post_attempt_widgets.dart
A  lib/modules/new_exam_component/widgets/post_attempt_analytics_panel.dart
A  lib/modules/new_exam_component/widgets/exam_attempt_attachment.dart

M  lib/modules/mcq_review_v3/widgets/mcq_solution_action_bar.dart   (wave 2.1 hooks)
M  lib/modules/test/practice_test_solution_exam_screen.dart          (Insights button)
M  lib/modules/masterTest/practice_mock_solution_exam_screen.dart    (Insights button)
```

Total: 15 new files, 3 modified.

---

## Integration coverage

What's **live in users' hands** after wave 2.1:

* The two highest-traffic solution screens (practice + mock) now show an **Insights** icon in the app bar that opens the full analytics suite (heatmap, time-pressure, calibration, cohort percentile, pattern summary, "Practice my mistakes" CTA).
* Inside those same screens, every per-question action bar now includes **Doubt chat** + **Similar Qs**, and "Why I was wrong" routes through the cached Sonnet endpoint with a follow-up bridge.
* Question reports now hit the dedicated endpoint with server-side dedup.

What's **drop-in ready but not yet wired**:

* All 12 attempt screens — `ExamAttemptAttachment` + `PauseResumeButton` are imported with one line + 3 method blocks; see [EXAM_INTEGRATION_GUIDE_V2.md §3](EXAM_INTEGRATION_GUIDE_V2.md#3-attempt-screen-wiring--examattemptattachment).
* Solution screens C–H — same 3-step recipe as A and B; one PR per screen.
* Boot-time resume prompt — wire once in `app/app.dart` or the post-login splash; see [§4](EXAM_INTEGRATION_GUIDE_V2.md#4-boot-time-resume-prompt).
* `ProctorService` — for mock attempts only; one-line attach in `initState`, one-line detach in `dispose`.

What's **deferred** (not in this initiative):

* Web-specific tab-switch detection (`visibilitychange`) — mobile app-switch already covered.
* FCM push wiring for mock-schedule + in-progress reminders — backend fires the events; existing notification system picks them up. If new FCM templates are needed, that's a separate task on the notification side.
* Offline mode (download exam → attempt offline → sync) — significant additional infra; not in scope.

---

## Reading order for someone catching up

1. [EXAM_ATTEMPT_INTEGRATION_GUIDE.md](EXAM_ATTEMPT_INTEGRATION_GUIDE.md) — architectural overview, state machine, full endpoint reference, idempotency conventions, anti-double-attempt UX, backfill SQL.
2. [EXAM_INTEGRATION_GUIDE_V2.md](EXAM_INTEGRATION_GUIDE_V2.md) — screen-by-screen integration recipes (the 3-step Insights pattern, the `ExamAttemptAttachment` 6-step pattern).
3. This file (`CHANGE_SUMMARY.md`) — the "what changed when" index.

---

End of summary.
