# MCQ Review v3 — Flutter Integration

Companion to `lib/modules/cortex/`. Adds 22 features across the MCQ
review surface: confidence rating, multi-color highlighter, multi-note
sticky-notes, cohort time comparison, discussion threads, audio
explanations, mistake debrief, related MCQs, flashcard generation,
mnemonic + diagram quick actions, topic chips, focus / auto-advance /
speed-reading prefs, spaced-repetition review queue, performance
trends, AI study plan, scheduled tutor sessions.

All powered by 24 new API endpoints under `/api/cortex/*`,
`/api/discussion/*`, `/api/review-queue/*`, `/api/analytics/*`,
`/api/user-answer/confidence`. See server commit `e13e543`.

---

## Files added

```
lib/
  models/mcq_review_models.dart            ← all v3 JSON models
  modules/mcq_review_v3/
    README.md                              ← this file
    mcq_review_service.dart                ← API service
    reading_prefs.dart                     ← local SharedPreferences (focus, auto-advance, speed-reading, confidence-prompt, TTS-auto)
    widgets/
      mcq_solution_action_bar.dart         ← composite action bar — 1 widget bundles all features
      sticky_notes_panel.dart              ← multi-note panel + editor dialog
      highlighter_toolbar.dart             ← 4-color highlighter toolbar
      confidence_rater.dart                ← 0-100 slider with reveal button
      time_vs_avg.dart                     ← "you took 47s · cohort avg 32s"
      audio_explain_button.dart            ← TTS-friendly explanation generator
      discussion_sheet.dart                ← community thread modal
    screens/
      review_queue_screen.dart             ← daily SM-2 review queue + grading
      study_plan_screen.dart               ← Cortex-generated personalized plan
      scheduled_sessions_screen.dart       ← recurring tutor session reminders
      performance_trends_screen.dart       ← topic strength + calibration curve
      reading_settings_screen.dart         ← all the reading-prefs in one place
```

---

## Files modified

```
lib/helpers/constants.dart    ← +20 v3 endpoint constants
lib/app/routes.dart           ← +5 route constants + 5 onGenerateRouted cases
```

(No changes yet to `practice_test_solution_exam_screen.dart` — see "Drop-in plan" below.)

---

## Drop-in plan: upgrade the existing MCQ solution screen

The bundled `McqSolutionActionBar` widget replaces 90% of the manual
wiring. To upgrade the existing solution screen
(`lib/modules/test/practice_test_solution_exam_screen.dart`):

### Step 1 — Track question start time

Inside the `_PracticeTestSolutionExamScreenState` class, add:

```dart
DateTime? _questionStartedAt;
```

In `initState` and whenever `_currentQuestionIndex` changes, set:
```dart
_questionStartedAt = DateTime.now();
```

### Step 2 — Replace "View Answer" button with `ConfidenceRater`

Find the existing "View Ans" button (around line 1353). Replace its
container with:

```dart
import 'package:shusruta_lms/modules/mcq_review_v3/widgets/confidence_rater.dart';

ConfidenceRater(
  userAnswerId: currentUserAnswerId,            // your existing field
  questionStartedAt: _questionStartedAt ?? DateTime.now(),
  initial: 50,
  onReveal: () => setState(() => _viewAnswer = true), // your existing toggle
),
```

If the student opts out of confidence ratings (Reading settings →
"Prompt for confidence"), the rater renders a plain "Reveal answer"
button automatically.

### Step 3 — Replace the bottom action row with `McqSolutionActionBar`

Just below the explanation block, drop:

```dart
import 'package:shusruta_lms/modules/mcq_review_v3/widgets/mcq_solution_action_bar.dart';

if (_viewAnswer)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: McqSolutionActionBar(
      questionId: question.id,
      selectedOption: userSelectedOption,
      correctOption: question.correctOption,
      examId: examId,
      userExamId: userExamId,
      examType: 'regular',                         // 'mock' on mock-exam screens
      questionText: question.questionText,
      options: question.options,
      briefExplanation: question.explanation,
      wasWrong: userSelectedOption != question.correctOption,
      topic: question.topicName,
      subtopic: question.subtopicName,
      difficulty: question.difficulty,
      questionType: question.questionType,
      onOpenNotes: () => _openNotes(),               // your existing handler
      onToggleHighlighter: () => _toggleHighlighter(),// existing or new
    ),
  ),
```

This single widget includes:
- 🟡 Highlighter button
- 📝 Notes button
- ✨ Ask Cortex (multi-turn, MCQ-anchored)
- 🤔 Why I was wrong (only if `wasWrong == true`)
- 🔊 Listen (audio explain)
- 🧠 Mnemonic
- 📊 Diagram
- 🔁 Review later (add to SR queue)
- 💬 Discuss
- 🚩 Report
- Difficulty / Q-type / Topic chips (top of bar)

### Step 4 — Add `TimeVsAvg` widget

Below the action bar:

```dart
import 'package:shusruta_lms/modules/mcq_review_v3/widgets/time_vs_avg.dart';

TimeVsAvg(
  questionId: question.id,
  userTimeMs: userAnswer.timeSpentMs,  // pass null if not tracked
),
```

### Step 5 — Upgrade Sticky Notes

Replace the existing `CustomBottomStickNotesWindow` invocation with:

```dart
import 'package:shusruta_lms/modules/mcq_review_v3/widgets/sticky_notes_panel.dart';

StickyNotesPanel.show(
  context,
  notes: _stickyNotesForCurrentQ,                  // List<StickyNote>
  onSave: (note) async {
    await _persistNote(note);                      // your storage layer
    setState(() { /* refresh */ });
  },
  onDelete: (id) async {
    await _deleteNote(id);
    setState(() { /* refresh */ });
  },
);
```

Notes are local-only by default (`{title, body, color}`). Wire to your
existing notes API if you want server-side sync.

### Step 6 — Activate Highlighter

The Quill editor already supports highlighting via `attribute:
'background'`. Surface the toolbar:

```dart
import 'package:shusruta_lms/modules/mcq_review_v3/widgets/highlighter_toolbar.dart';

bool _highlighterActive = false;
String? _highlightColor; // 'yellow' | 'blue' | 'pink' | 'green'
bool _eraserMode = false;

if (_highlighterActive)
  HighlighterToolbar(
    activeColor: _highlightColor,
    eraserMode: _eraserMode,
    onSelectColor: (c) => setState(() {
      _highlightColor = c; _eraserMode = false;
    }),
    onToggleEraser: () => setState(() => _eraserMode = !_eraserMode),
    onClose: () => setState(() => _highlighterActive = false),
  ),
```

When the user selects text in the Quill editor while a color is
active, apply the `background` attribute with that color. Persist via
your existing `annotationData` JSON field.

### Step 7 — Auto-enroll wrong Qs into SR queue on submit

In your exam-submit handler:

```dart
import 'package:shusruta_lms/modules/mcq_review_v3/mcq_review_service.dart';

await McqReviewService().enrollFromAttempt(userExamId);
```

This bulk-enrolls every wrong answer + every correct-but-low-confidence
answer into the spaced-rep queue. Idempotent — safe to call multiple
times.

### Step 8 — Honor Reading Preferences

Watch `ReadingPrefs.I` in your screen:

```dart
import 'package:shusruta_lms/modules/mcq_review_v3/reading_prefs.dart';

@override
void initState() {
  super.initState();
  ReadingPrefs.I.addListener(_onPrefsChanged);
  ReadingPrefs.I.load();
}

void _onPrefsChanged() => setState(() {});

@override
void dispose() {
  ReadingPrefs.I.removeListener(_onPrefsChanged);
  super.dispose();
}

// Apply focus mode: hide app bar / nav
final hideChrome = ReadingPrefs.I.focusMode;

// Apply auto-advance:
if (ReadingPrefs.I.autoAdvance && _viewAnswer) {
  Timer(Duration(seconds: ReadingPrefs.I.autoAdvanceSeconds), () {
    if (mounted) _nextQuestion();
  });
}

// Apply speed-reading: bump font + tighter line height
final fontSize = ReadingPrefs.I.speedReading ? 16.0 : 13.0;
```

Add a settings entry-point (gear icon) that pushes:
```dart
Navigator.of(context).pushNamed(Routes.readingSettings);
```

---

## Mock-exam parallel screen

If you have a separate `mock_test_solution_exam_screen.dart` (or
similar) for mock exams, repeat steps 1–8 but pass `examType: 'mock'`
to `McqSolutionActionBar`. The backend automatically dispatches to
`MasterQuestionModel` for mock contexts.

---

## Linking the new screens from the menu

Three natural entry points:

1. **More menu** (in `MoreMenuBottomSheet`):
   - "🔁 Review queue" → `Navigator.pushNamed(Routes.reviewQueueV3)`
   - "📅 Study plan" → `Navigator.pushNamed(Routes.studyPlan)`
   - "⏰ Scheduled sessions" → `Navigator.pushNamed(Routes.scheduledSessions)`
   - "📈 Performance trends" → `Navigator.pushNamed(Routes.performanceTrends)`
   - "⚙️ Reading prefs" → `Navigator.pushNamed(Routes.readingSettings)`

2. **Cortex Home Screen** popup menu — already linked via the
   "Memory & Settings" + "Saved snippets" items. Add the new screens
   to the same menu if you want them all in one place.

3. **Bottom-nav badge** — show `reviewQueueStats.dueToday` count on
   the menu icon when > 0.

---

## API endpoints used

All in `lib/helpers/constants.dart`:

```
PATCH  /api/user-answer/confidence
POST   /api/review-queue/enroll-from-attempt
GET    /api/review-queue/due
GET    /api/review-queue/stats
POST   /api/review-queue/enroll
POST   /api/review-queue/:id/grade
PATCH  /api/review-queue/:id/status

GET    /api/discussion/q/:question_id
GET    /api/discussion/post/:id/replies
POST   /api/discussion/q/:question_id/post
PATCH  /api/discussion/post/:id
DELETE /api/discussion/post/:id
POST   /api/discussion/post/:id/upvote
POST   /api/discussion/post/:id/report
POST   /api/discussion/post/:id/accept

GET    /api/analytics/topic-trend?days=30&topic=…
GET    /api/analytics/calibration?days=90
GET    /api/analytics/question-time/:question_id
GET    /api/analytics/topic-strength?days=90

POST   /api/cortex/study-plan
GET    /api/cortex/study-plan
PATCH  /api/cortex/study-plan/item/:item_id
POST   /api/cortex/audio-explain
POST   /api/cortex/scheduled-session
GET    /api/cortex/scheduled-sessions
PATCH  /api/cortex/scheduled-session/:id
DELETE /api/cortex/scheduled-session/:id
```

---

## Optional packages (none required)

If you want **real text-to-speech** (currently the audio sheet just
shows the script), add to `pubspec.yaml`:

```yaml
flutter_tts: ^4.2.0
```

Then in `audio_explain_button.dart` uncomment the `_AudioPlaybackSheet`
TTS block (clearly marked).

For **Mermaid rendering** (currently the diagram source is shown as
a code block), wrap it in a webview pointing to mermaid.live:

```dart
WebView(
  initialUrl: Uri.dataFromString(
    '<html><body><pre class="mermaid">$mermaidSource</pre>'
    '<script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>'
    '<script>mermaid.initialize({startOnLoad:true});</script></body></html>',
    mimeType: 'text/html',
  ).toString(),
)
```

---

## QA checklist

- [ ] Open MCQ → confidence slider appears (or reveal button if opted out)
- [ ] Reveal answer → confidence + time persisted (network tab)
- [ ] Action bar visible below explanation with all buttons
- [ ] "Why was I wrong" only shows on wrong answers
- [ ] Mistake debrief modal streams reply + auto-enrolls weak topic
- [ ] "Listen" → script bottom sheet opens
- [ ] "Mnemonic" → opens mode start screen with `mnemonic` mode
- [ ] "Diagram" → opens mode start screen with `diagram` mode
- [ ] "Review later" → toast confirms enrollment
- [ ] "Discuss" → discussion sheet opens
- [ ] Topic chip → opens topic deep-dive Cortex chat
- [ ] Difficulty + Q-type chips render with correct colors
- [ ] Time-vs-avg badge appears (after sample size ≥ 5 cohort answers)
- [ ] Sticky notes → multi-note panel opens
- [ ] Highlighter toggle → toolbar slides in, 4 colors selectable
- [ ] Reading settings: focus mode, auto-advance, speed-reading, prompt-confidence all toggle and persist
- [ ] Submit exam → wrong Qs auto-enroll in SR queue
- [ ] Review queue screen → list + grade buttons work, stats update
- [ ] Study plan → generate works, items toggle complete
- [ ] Scheduled sessions → create + pause + delete work
- [ ] Performance trends → topic bars + calibration curve render
