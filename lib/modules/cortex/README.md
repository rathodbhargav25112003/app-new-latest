# Cortex AI v2/v3 — Flutter Integration

**For the dev shipping the app changes.** Everything you need to wire the Cortex AI upgrade is in this folder. The legacy `AskQuestionScreen` keeps working — these new screens replace it on the bottom-nav tab and add new entry points across the MCQ + result screens.

---

## What this delivers

- **Multi-turn chat** — students can drill down ("explain that more") instead of single-shot Q&A
- **Streaming responses** via SSE (token-by-token rendering, ~10× perceived speed)
- **5 chat modes** — general, MCQ-anchored, mistake debrief, patient/examiner roleplay, OSCE viva, topic deep-dive
- **Mistake debrief** — bottom sheet on wrong answers; structured "why I was wrong"
- **Related MCQs** — pure DB carousel, zero AI cost
- **Mnemonic + Diagram (Mermaid)** generators
- **Auto-flashcards** from any Cortex reply
- **Saved snippets** with chat-search across all history
- **Persistent memory** — Cortex remembers weak topics + preferences
- **Daily usage cap** with transparent "X of N today" badge

All backed by the new `/api/cortex/*` endpoints already deployed on the API. The legacy `POST /api/getExplanation` continues to work unchanged so nothing breaks during rollout.

---

## File layout (new)

```
lib/
  models/
    cortex_models.dart                    ← all Cortex JSON models
  modules/cortex/
    README.md                             ← this file
    cortex_service.dart                   ← API + raw SSE streaming
    cortex_integration_helpers.dart       ← drop-in helpers for existing screens
    cortex_home_screen.dart               ← landing page (replaces AskQuestion)
    cortex_chat_screen.dart               ← active chat with streaming
    cortex_mode_start_screen.dart         ← roleplay/OSCE/deep-dive/mnemonic/diagram
    cortex_memory_screen.dart             ← weak topics, prefs, notes
    cortex_snippets_screen.dart           ← saved snippet library
    store/
      cortex_store.dart                   ← MobX store
    widgets/
      cortex_bubble.dart                  ← message bubble (markdown + actions)
      cortex_usage_badge.dart             ← "X of N today" pill
      related_mcqs_carousel.dart          ← post-attempt suggestions
      mistake_debrief_sheet.dart          ← modal "Why was I wrong?"
```

## Files modified

```
lib/
  helpers/constants.dart                  ← added 20 cortex* endpoints
  app/routes.dart                         ← added 5 route constants + cases
  app/app.dart                            ← Provider<CortexStore> in MultiProvider
  modules/bottom/home_screen_second.dart  ← AskQuestionScreen → CortexHomeScreen
```

## Files NOT yet modified — manual edits needed (3 spots)

You need to make 3 small drop-ins in your existing test screens. Each is one line. Detailed below.

---

## Edit 1: `test_exam_screen.dart` — upgrade Ask Cortex AI button

Find the existing onTap that calls `getExplanation()` (look for `onGetExplanationCall` or similar) and replace with:

```dart
import 'package:shusruta_lms/modules/cortex/cortex_integration_helpers.dart';

// On the "Ask Cortex AI" button onTap:
CortexIntegrationHelpers.openAskCortex(
  context,
  questionId: currentQuestion.id,
  examId: examId,           // optional but recommended
  userExamId: userExamId,   // optional but recommended
);
```

**What changes for the user:**
- First tap on the question: creates a new chat scoped to this MCQ; server auto-loads the question + options + correct + brief explanation as context
- Subsequent taps: resumes the same chat — they can drill down ("why is option B wrong?", "give me a related case", "make a mnemonic")
- All streamed in real time

**Backward-compat:** the legacy `getExplanation()` endpoint still works exactly as before if you can't migrate this screen yet. Skip this step and the new chatbot tab still works.

---

## Edit 2: `test_report_details_screen.dart` — add "Why was I wrong?" button

For each wrong-answer result row, add:

```dart
import 'package:shusruta_lms/modules/cortex/cortex_integration_helpers.dart';

// In the build of the result row, after the "Correct: X / You: Y" line,
// when userAnswer != correctAnswer:
if (userAnswer != correctAnswer)
  ElevatedButton.icon(
    onPressed: () => CortexIntegrationHelpers.showMistakeDebrief(
      context,
      questionId: question.id,
      selectedOption: userAnswer,
      correctOption: correctAnswer,
      examId: examId,
      userExamId: userExamId,
      examType: 'regular',  // 'mock' for mock exams
    ),
    icon: const Icon(Icons.lightbulb_outline, size: 16),
    label: const Text('Why was I wrong?'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange.shade50,
      foregroundColor: Colors.orange.shade800,
      elevation: 0,
    ),
  ),
```

**What it does:** opens a bottom sheet that streams a 5-section diagnostic ("Why my choice was tempting", "The cognitive trap", "Why the correct answer wins", "The teaching point", "NEET SS exam tip"). Bonus side-effect: the topic of the wrong question is auto-recorded in the student's persistent memory as a weak topic for future personalization.

---

## Edit 3: `test_report_details_screen.dart` — Related-MCQs carousel

Below each question row in the report, add:

```dart
import 'package:shusruta_lms/modules/cortex/cortex_integration_helpers.dart';

// Below each question's result row in the list:
CortexIntegrationHelpers.relatedMcqs(
  questionId: question.id,
  examType: 'regular',
  onTap: (mcq) {
    // Optional: navigate to that exam, jump to question_number
    // Or just let it noop — the carousel can be informational.
  },
),
```

**What it does:** shows 5 MCQs from the same topic/subtopic horizontally. Pure DB query — no AI cost, no daily-cap hit, no token spend.

---

## How it all wires together

### Bottom nav (already done)

The "Ask Cortex.ai" tab in `home_screen_second.dart` now opens `CortexHomeScreen` instead of the legacy `AskQuestionScreen`. The legacy screen file `dashboard/ask_question.dart` is left in place untouched (not used) so you can roll back instantly if needed by undoing the 1-line import + 1-line widget swap.

### Provider tree

`CortexStore` is registered in `app.dart` MultiProvider, alongside every other store. Pulled via:
```dart
final store = Provider.of<CortexStore>(context, listen: false);
```

### State flow

```
User taps "Ask Cortex" on MCQ
    ↓
CortexIntegrationHelpers.openAskCortex(context, questionId, ...)
    ↓
CortexStore.findOrCreateMcqChat()          → POST /api/cortex/chat (context_kind:'mcq')
    ↓
CortexChatScreen.routeForChat(chat)        → opens chat viewer
    ↓
User types message → Composer.onSend
    ↓
CortexStore.sendMessageStreaming()         → POST /api/cortex/chat/:id/message?stream=true
    ↓
SSE deltas append to assistant bubble in real time
    ↓
Done → CortexStore.refreshUsage()          → GET /api/cortex/usage
    ↓
Badge auto-updates everywhere
```

### Streaming implementation

Uses raw `dart:io` `HttpClient` — no extra dependency. Reads `text/event-stream` line by line, parses each `data: {...}` event, yields `CortexDelta`/`CortexDone`/`CortexMeta`/`CortexError` events to the store. Works on iOS, Android, web Flutter.

### Daily cap

`CortexStore.usage.value.remaining` is observable. The composer in `CortexChatScreen` shows a red banner + disables input when cap is hit. 429 with `code: CORTEX_RATE_LIMIT` triggers a friendly dialog. `CortexUsageBadge` widget shows "X of N today" everywhere.

### Markdown rendering

`flutter_markdown` is already in `pubspec.yaml` (`0.7.7+1`). All Cortex bubbles render markdown with custom styles matching the app theme. Code blocks, tables, bold, headings all work.

### Mermaid diagrams

The diagram generator returns raw Mermaid syntax in `mermaid_source`. The mode-start screen shows the markdown explanation; rendering Mermaid graphically requires a Mermaid widget (e.g., a webview or `flutter_svg` + a Mermaid-to-SVG service). This is left for a future iteration — for now the source is shown for users who can read Mermaid (or copy to mermaid.live).

---

## Routes (all named — already registered)

```dart
Routes.cortexHome          // 'cortexHome'      — landing page
Routes.cortexChat          // 'cortexChat'      — active chat (args: { chat_id })
Routes.cortexModeStart     // 'cortexModeStart' — mode launcher (args: { mode_id, mode_label })
Routes.cortexMemory        // 'cortexMemory'    — settings + weak topics
Routes.cortexSnippets      // 'cortexSnippets'  — saved snippets
```

Navigate with:
```dart
Navigator.of(context).pushNamed(Routes.cortexMemory);
Navigator.of(context).pushNamed(Routes.cortexChat, arguments: {'chat_id': '...'});
```

---

## API endpoints used

All in `lib/helpers/constants.dart`:

| Constant | URL | Purpose |
|---|---|---|
| `cortexUsage` | `/api/cortex/usage` | Daily cap + counters |
| `cortexChats` | `/api/cortex/chats` | List user's chats |
| `cortexChat` | `/api/cortex/chat` | POST new / GET :id / PATCH :id / DELETE :id |
| `cortexChatMessage` | `/api/cortex/chat/:id/message` | POST (`?stream=true` for SSE) |
| `cortexMistakeDebrief` | `/api/cortex/mistake-debrief` | POST (?stream=true for SSE) |
| `cortexRelatedMcqs` | `/api/cortex/related-mcqs/:id` | GET |
| `cortexRoleplay` | `/api/cortex/roleplay` | POST (?stream=true) |
| `cortexOsceViva` | `/api/cortex/osce-viva` | POST (?stream=true) |
| `cortexTopicDeepDive` | `/api/cortex/topic-deep-dive` | POST (?stream=true) |
| `cortexMnemonic` | `/api/cortex/mnemonic` | POST |
| `cortexDiagram` | `/api/cortex/diagram` | POST (mermaid_source) |
| `cortexSummarize` | `/api/cortex/chat/:id/summarize` | POST |
| `cortexFollowups` | `/api/cortex/message/:id/follow-ups` | GET |
| `cortexFlashcards` | `/api/cortex/message/:id/flashcards` | POST |
| `cortexSnippet` | `/api/cortex/message/:id/snippet` | POST |
| `cortexSnippets` | `/api/cortex/snippets` | GET |
| `cortexSearch` | `/api/cortex/search?q=…` | GET |
| `cortexExport` | `/api/cortex/chat/:id/export` | GET |
| `cortexMemory` | `/api/cortex/memory` | GET / PATCH |
| `cortexQuickPrompts` | `/api/cortex/quick-prompts` | GET |

---

## QA checklist

After deploying, verify:

- [ ] **Bottom-nav tap "Ask Cortex.ai"** → opens `CortexHomeScreen` (not the old chat UI)
- [ ] **Type a prompt + send** → streaming reply with typing indicator
- [ ] **Tap a follow-up chip** → auto-sends drilldown
- [ ] **Snippets icon (bookmark)** → toggles saved state, appears in `Saved snippets` list
- [ ] **Generate flashcards** button on assistant bubble → modal with 5 cards
- [ ] **Pin / archive / rename / export / delete** in chat menu → all work
- [ ] **Search** → returns highlighted matches
- [ ] **Memory & settings**:
  - Tone toggle saves
  - Notes save (Save button appears when dirty)
  - Weak topics chip → opens deep-dive chat on that topic
- [ ] **Modes** (5 of them) → each launches correctly
- [ ] **Daily cap reached** → composer disabled, red banner shown
- [ ] **MCQ Ask Cortex** (after wiring Edit 1) → multi-turn drilldown
- [ ] **Result-screen "Why was I wrong?"** (after Edit 2) → bottom sheet streams debrief
- [ ] **Related MCQs carousel** (after Edit 3) → 5 cards below each result row

---

## Rollback plan

If something breaks badly:

1. **Bottom nav rollback** (1 line) — in `home_screen_second.dart`, revert the two `CortexHomeScreen()` references back to `AskQuestionScreen()`. The legacy file is untouched.

2. **Server endpoints** — `/api/cortex/*` are additive. The legacy `/api/getExplanation` endpoint is unchanged and still works. The old `AskQuestionScreen` flow still hits it.

3. **Provider tree** — leaving `CortexStore` registered is harmless if no screen reads it.

---

## Cost expectations

Claude Sonnet (default model) ≈ $3 / $15 per 1M tokens. Average chat turn:
- ~1500 input tokens (system prompt + history + user msg)
- ~600 output tokens (typical reply)
- = ~$0.014 per turn

At the default daily cap of 100 messages/user/day, that's ~$1.40 / user / day max.

You can override the cap via env var `CORTEX_DAILY_CAP` on the server.

---

## Questions / issues

- Server logic: `api-ruchir-optimization/src/business/cortex.business.js` — every function is documented inline.
- Detailed API spec: `api-ruchir-optimization/docs/CORTEX_AI_INTEGRATION_GUIDE.md`.
- This Flutter integration: code is heavily commented, especially `cortex_service.dart` (SSE pump) and `cortex_store.dart` (streaming state machine).
