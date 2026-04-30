# LMS Feature Rollout — Implementation Guide

**Branch (app):** `ruchir-fixes-new` on `github.com/sushrutalgs/app`
**Branch (api):** `ruchir-fixes-new` on `github.com/sushrutalgs/api`
**Target app version:** Flutter (Shushruta LMS), API: Node 18 / Mongoose 7

This guide documents every change pushed in this rollout so a developer inheriting the work has everything needed to ship, debug, or extend the features. It is split into three parts:

1. **Backend (API)** — new Mongoose models, routes/endpoints, cron jobs, hooks into existing business logic
2. **Client (Flutter app)** — new API service methods, widgets, screens, route wiring
3. **Operational** — deployment checklist, env vars, outstanding work

---

## 1. Feature Map

| # | Feature | Backend surface | Client surface |
|---|---------|-----------------|----------------|
| 1 | Video bookmarks | `VideoBookmark` model + 3 endpoints | FAB cluster on video player + bottom sheet |
| 2 | Continue where you left off ("Resume Banner") | `resume` endpoint aggregates last-watched/last-attempted | Horizontal card strip on home screen |
| 3 | Study streak | `UserStreak` model + `streak` endpoint + daily activity hook | Streak card on Progress tab |
| 4 | Analytics summary | `analytics/summary` endpoint | Analytics card on Progress tab |
| 5 | Topic mastery | `topicMastery` aggregation endpoint | Mastery card on Progress tab |
| 6 | Spaced repetition review queue (SM-2) | `ReviewQueueItem` model + `review/next` + `review/answer` + auto-enqueue on wrong answers | Review Queue screen with rating buttons |
| 7 | Push study reminders | `DevicePushToken` + `UserPreferences` models + FCM reminder cron | FCM token registration on login |

---

## 2. Backend — Models

All models live under `api-ruchir-optimization/src/models/`.

### 2.1 `videoBookmark.model.js`
```js
{
  user_id: ObjectId (ref User, index),
  content_id: ObjectId (ref Content, index),
  position_seconds: Number,
  label: String (default ''),
  created_at: Date,
  updated_at: Date,
  deleted_at: Date (soft-delete),
}
```
**Unique-ish:** compound index on `(user_id, content_id, position_seconds)` to avoid dupes if user taps bookmark twice at same frame.

### 2.2 `userStreak.model.js`
```js
{
  user_id: ObjectId (ref User, unique),
  current_streak: Number (default 0),
  longest_streak: Number (default 0),
  last_activity_date: String,    // "YYYY-MM-DD" in user's TZ
  activity_dates: [String],      // rolling last 14 days for UI dots
  updated_at: Date,
}
```

### 2.3 `reviewQueueItem.model.js` (SM-2)
```js
{
  user_id: ObjectId (ref User, index),
  question_id: ObjectId (ref Question, index),
  question_source: String,       // 'test' | 'mock' | 'manual'
  status: String,                // 'new' | 'learning' | 'review' | 'retired'
  ease_factor: Number (default 2.5),
  interval_days: Number (default 0),
  repetitions: Number (default 0),
  next_review_at: Date (index),
  last_rating: String,           // 'again' | 'hard' | 'good' | 'easy'
  last_reviewed_at: Date,
  created_at: Date,
  updated_at: Date,
  deleted_at: Date,
}
```
Compound index: `(user_id, next_review_at)` for the "due now" query.

### 2.4 `devicePushToken.model.js`
```js
{
  user_id: ObjectId (ref User, index),
  fcm_token: String (unique),
  platform: String,              // 'android' | 'ios' | 'web'
  is_live: Boolean (default true),
  last_seen_at: Date,
  created_at: Date,
  updated_at: Date,
}
```

### 2.5 `userPreferences.model.js`
```js
{
  user_id: ObjectId (ref User, unique),
  reminder_enabled: Boolean (default false),
  reminder_time: String,         // "HH:MM" 24h
  reminder_days: [Number],       // 0=Sun..6=Sat
  reminder_timezone: String,     // IANA, e.g. "Asia/Kolkata"
  last_fired_date: String,       // "YYYY-MM-DD" in user TZ, anti-spam
  updated_at: Date,
}
```

---

## 3. Backend — Routes

All routes live under `api-ruchir-optimization/src/routes/`, auto-mounted under `/api/user/*` by the app's route loader. Each route file exports a standard `(router) => {}` function.

### 3.1 Video bookmarks — `videoBookmark.route.js`
| Method | Path | Body / Query | Returns |
|--------|------|--------------|---------|
| POST | `/video-bookmark` | `{ content_id, position_seconds, label? }` | created bookmark |
| GET | `/video-bookmark` | `?content_id=...` | `{ bookmarks: [...] }` ordered by `position_seconds` asc |
| DELETE | `/video-bookmark/:id` | — | `{ ok: true }` |

### 3.2 Resume banner — `resume.route.js`
| Method | Path | Query | Returns |
|--------|------|-------|---------|
| GET | `/resume` | `?limit=6` | `{ items: [{ type:'video'|'test'|'notes', id, title, thumbnail?, progress?, updated_at }] }` sorted newest first |

Internal logic: merges last ~20 `UserAnswer`s, `UserVideoProgress` rows, `UserNotes` opens, dedupes by content, returns top N.

### 3.3 Streak — `userStreak.route.js`
| Method | Path | Returns |
|--------|------|---------|
| GET | `/streak` | `{ current_streak, longest_streak, activity_dates:[...], today_active: boolean }` |

Side-effect: `_touchStreak(user_id)` is called from `user_answer.business.js` and `user_video.business.js` on every activity write. It reads `UserStreak`, computes YYYY-MM-DD in user TZ, updates `current_streak` (bump if yesterday, reset if gap, unchanged if same day) and pushes to `activity_dates`.

### 3.4 Analytics summary — `userAnalytics.route.js`
| Method | Path | Query | Returns |
|--------|------|-------|---------|
| GET | `/analytics/summary` | `?days=30` | `{ total_questions, correct, accuracy, time_spent_minutes, per_day:[{date,count}] }` |

### 3.5 Topic mastery — `topicMastery.route.js`
| Method | Path | Returns |
|--------|------|---------|
| GET | `/topic-mastery` | `{ topics: [{ topic_name, subtopic_name?, attempts, correct, accuracy }] }` sorted accuracy asc |

Aggregation pipeline: `UserAnswer.aggregate([{$match:{user_id}}, {$group:{_id:'$topicName', attempts:{$sum:1}, correct:{$sum:{$cond:['$is_correct',1,0]}}}}, {$project:{accuracy:{$divide:['$correct','$attempts']}}}, {$sort:{accuracy:1}}])`.

### 3.6 Review queue — `reviewQueue.route.js`
| Method | Path | Body / Query | Returns |
|--------|------|--------------|---------|
| GET | `/review/next` | `?limit=20` | `{ items:[ReviewQueueItem with populated question] }` — due items (`next_review_at <= now`) |
| POST | `/review/answer` | `{ item_id, rating:'again'\|'hard'\|'good'\|'easy', time_spent_ms }` | updated item |
| POST | `/review/enqueue` | `{ question_id, question_source }` | upserted item |

**SM-2 update rule** (inside `POST /review/answer`):
```
switch rating:
  'again':  repetitions=0; interval=1; ease = max(1.3, ease-0.2);
  'hard':   interval = repetitions===0 ? 1 : Math.ceil(interval*1.2); repetitions++; ease = max(1.3, ease-0.15);
  'good':   interval = repetitions===0 ? 1 : repetitions===1 ? 6 : Math.round(interval*ease); repetitions++;
  'easy':   interval = repetitions===0 ? 4 : Math.round(interval*ease*1.3); repetitions++; ease += 0.15;
next_review_at = now + interval days
status: repetitions<2 ? 'learning' : 'review'; ease>=2.8 && interval>60 ? 'retired'
```

### 3.7 FCM — `devicePushToken.route.js` + `userPreferences.route.js`
| Method | Path | Body | Returns |
|--------|------|------|---------|
| POST | `/device/fcm` | `{ fcm_token, platform? }` | upserted token |
| DELETE | `/device/fcm` | `{ fcm_token }` | soft-marks `is_live=false` |
| GET | `/user-preferences` | — | preferences doc or defaults |
| PUT | `/user-preferences` | partial doc | updated preferences |

---

## 4. Backend — Cron

### 4.1 FCM study reminder cron
Inserted in `api-ruchir-optimization/src/cronjobs/cron.js` **inside `if (isMainWorker)` block** so it only fires from the master worker. Runs every minute.

Pseudocode:
```js
cron.schedule('* * * * *', async () => {
  const now = new Date();
  const prefs = await UserPreferencesModel.find({ reminder_enabled: true }).lean();

  for (const p of prefs) {
    const tz = p.reminder_timezone || 'Asia/Kolkata';
    const parts = new Intl.DateTimeFormat('en-GB', {
      timeZone: tz, hour: '2-digit', minute: '2-digit',
      weekday: 'short', year: 'numeric', month: '2-digit', day: '2-digit',
      hour12: false
    }).formatToParts(now);
    const localHM = `${hour}:${minute}`;
    const localWeekday = weekdayMap[short];   // Sun=0..Sat=6
    const localDateKey = `${year}-${month}-${day}`;

    if (localHM !== p.reminder_time) continue;
    if (!p.reminder_days.includes(localWeekday)) continue;
    if (p.last_fired_date === localDateKey) continue;    // anti-spam

    const tokens = await DevicePushTokenModel
      .find({ user_id: p.user_id, is_live: true })
      .distinct('fcm_token');
    if (!tokens.length) continue;

    // Chunk sends (FCM multicast caps at 500)
    for (let i=0; i<tokens.length; i+=500) {
      await admin.messaging().sendEachForMulticast({
        tokens: tokens.slice(i, i+500),
        notification: { title:'Time to study 📚', body:'Your daily review queue is ready.' },
        android: { priority:'high' },
        apns: { payload:{ aps:{ sound:'default' } } },
        webpush: { headers:{ Urgency:'high' } },
        data: { route: '/reviewQueue' },
      });
    }

    await UserPreferencesModel.updateOne(
      { _id: p._id },
      { $set: { last_fired_date: localDateKey } }
    );
  }
});
```

**Why `Intl.DateTimeFormat` instead of moment-timezone?** moment-timezone was not in `package.json`; adding it would require a deploy. Node 18's built-in `Intl` with `formatToParts` gives the exact slots we need.

---

## 5. Backend — Hooks into existing business logic

### 5.1 Auto-enqueue wrong answers
`api-ruchir-optimization/src/business/user_answer.business.js` — added helper and two hook sites:

```js
async function _enqueueWrongAnswer({ user_id, question_id, question_source }) {
  try {
    const uf = require('@/business/userFeatures.business').default; // lazy to break circular
    await uf.enqueueForReview({ user_id, question_id, question_source });
  } catch (e) {
    console.warn('[ReviewQueue] enqueue failed (non-fatal):', e.message);
  }
}

// Inside update path (existing answer flipping correct → wrong):
if (is_correct === false && existingUserAnswer.is_correct !== false) {
  _enqueueWrongAnswer({...});
}

// Inside create path (new wrong answer):
if (is_correct === false) {
  _enqueueWrongAnswer({...});
}
```

The `require()` is lazy on purpose — `userFeatures.business.js` imports `user_answer.business.js` back for streak hooks. Top-level require → circular death.

### 5.2 Streak touch
Both `user_answer.business.js` and `user_video.business.js` call `userFeatures.business._touchStreak(user_id)` fire-and-forget on every write.

---

## 6. Client — API Service

All new methods appended to `app-update_fixes_merge/lib/api_service/api_service.dart` before the class-closing `}`.

Shared helper:
```dart
Future<String?> _authToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(PrefsTitles.accessToken);
}
```

Methods (signatures only — bodies are thin HTTP JSON wrappers):
```dart
Future<Map<String,dynamic>?> createVideoBookmark({required String contentId, required int positionSeconds, String? label});
Future<List<dynamic>> listVideoBookmarks({required String contentId});
Future<bool> deleteVideoBookmark(String bookmarkId);
Future<List<dynamic>> getResumeList({int limit = 6});
Future<Map<String,dynamic>> getUserStreak();
Future<Map<String,dynamic>> getUserAnalyticsSummary({int days = 30});
Future<Map<String,dynamic>> getReviewNext({int limit = 20});
Future<Map<String,dynamic>?> submitReviewAnswer({required String itemId, required String rating, required int timeSpentMs});
Future<Map<String,dynamic>?> enqueueForReview({required String questionId, required String questionSource});
Future<List<dynamic>> getTopicMastery();
Future<bool> registerUserDeviceFcm({required String fcmToken, String platform = 'android'});
Future<bool> unregisterUserDeviceFcm({required String fcmToken});
Future<Map<String,dynamic>> getUserPreferences();
Future<Map<String,dynamic>?> updateUserPreferences(Map<String,dynamic> patch);
```

URL constants in `lib/helpers/constants.dart` under `// ───── User features ─────`:
```dart
static const String videoBookmark = "/api/user/video-bookmark";
static const String resumeList    = "/api/user/resume";
static const String userStreak    = "/api/user/streak";
static const String analyticsSummary = "/api/user/analytics/summary";
static const String reviewNext    = "/api/user/review/next";
static const String reviewAnswer  = "/api/user/review/answer";
static const String reviewEnqueue = "/api/user/review/enqueue";
static const String topicMastery  = "/api/user/topic-mastery";
static const String deviceFcm     = "/api/user/device/fcm";
static const String userPreferences = "/api/user/user-preferences";
```

---

## 7. Client — Widgets & Screens

### 7.1 ResumeBanner — `lib/modules/widgets/resume_banner.dart`
- Horizontal `ListView.separated` of `_ResumeCard` tiles
- Fetches `getResumeList(limit:6)` in initState; silent `SizedBox.shrink` if empty or error
- `onItemTap(item)` callback receives raw API item; Home screen switches on `item['type']` → routes to `Routes.videoPlayer` / `Routes.testCategory` / `Routes.notesCategory`
- Dark-mode aware via `ThemeManager.currentTheme == AppTheme.Dark` (from `helpers/colors.dart`)

**Integration** — in `home_screen.dart`, placed above the "Continue Your Learning" section:
```dart
ResumeBanner(onItemTap: (item) {
  switch (item['type']) {
    case 'video': Navigator.pushNamed(context, Routes.videoPlayer, arguments: ...); break;
    case 'test':  Navigator.pushNamed(context, Routes.testCategory); break;
    case 'notes': Navigator.pushNamed(context, Routes.notesCategory); break;
  }
}),
```

### 7.2 Video Bookmarks — `lib/modules/widgets/video_bookmarks_sheet.dart`
Exports:
- `showVideoBookmarksSheet({context, contentId, onSeek})` — opens `DraggableScrollableSheet` with list; tap row → `onSeek(seconds)` + `Navigator.pop`; trailing delete icon calls API
- `VideoBookmarkFab` widget — `FloatingActionButton.extended` labelled "Bookmark"; on tap reads current position, prompts for label (AlertDialog), POSTs create, shows SnackBar

**Integration** — `lib/modules/videolectures/video_player_detail.dart`:
1. Import: `package:shusruta_lms/modules/widgets/video_bookmarks_sheet.dart`
2. Added single property on the existing Scaffold:
```dart
floatingActionButton: (!isFullScreen && _playerControllerBuilt && (widget.contentId ?? '').isNotEmpty)
  ? _VideoBookmarkFabCluster(
      contentId: widget.contentId!,
      getPosition: () {
        try { return _betterPlayerController.videoPlayerController?.value.position ?? Duration.zero; }
        catch (_) { return Duration.zero; }
      },
      onSeek: (sec) {
        try { _betterPlayerController.seekTo(Duration(seconds: sec)); }
        catch (e) { debugPrint('[Bookmark] seek failed: $e'); }
      },
    )
  : null,
```
3. Added `_VideoBookmarkFabCluster` StatelessWidget at EOF — vertical `Column` of small "list" FAB (opens sheet) + main "Bookmark" FAB (saves new).

**Why this is safe:** only one Scaffold exists in the file; we touched one property and added one widget at EOF. The entire Observer/Orientation/SafeArea tree is untouched. No playback-adjacent code changed.

### 7.3 Learning Insights — `lib/modules/progress/learning_insights_section.dart`
`LearningInsightsSection` StatefulWidget with `onReviewTap` callback.

`initState` → `Future.wait([apiStreak, apiAnalyticsSummary, apiTopicMastery])` with per-request silent `.catchError` so one endpoint failing doesn't blank the section.

Layout (top → bottom):
1. `_StreakCard` — orange fire icon, `current_streak` number huge, `longest_streak` subtext, `_WeekDots` 7-day strip (filled = active day), "Open review queue" CTA wired to `onReviewTap`
2. `_AnalyticsCard` — green insights icon, two `_StatTile`s side-by-side (Questions, Accuracy %), `time_spent_minutes` subtext
3. `_TopicMasteryCard` — sorts topics by accuracy asc, renders two `_MasteryGroup`s:
   - "Needs work" (weakest 3) — red LinearProgressIndicator
   - "Strongest" (top 3) — green LinearProgressIndicator

**Integration** — `lib/modules/progress/progress_screen.dart` — inject before closing `],` of main Column:
```dart
LearningInsightsSection(
  onReviewTap: () => Navigator.of(context).pushNamed(Routes.reviewQueue),
),
const SizedBox(height: 32),
```

### 7.4 Review Queue — `lib/modules/review/review_queue_screen.dart`
`ReviewQueueScreen` StatefulWidget with `static Route<dynamic> route(RouteSettings)` factory.

State:
- `_items: List<dynamic>` from `getReviewNext(limit:20)`
- `_cursor: int` — current question index
- `_showAnswer: bool` — flipped by "Show Answer" button
- `_cardStartAt: DateTime` — timer for `time_spent_ms`

Flow:
1. `_load()` → sets `_items`, resets cursor to 0
2. Render: `LinearProgressIndicator(value: cursor / items.length)` + chip row (interval_days, ease_factor) + stem + options (correct option green when `_showAnswer`) + explanation block
3. Footer:
   - If `!_showAnswer` → full-width "Show Answer" button
   - If `_showAnswer` → 4 buttons in a row: Again (red #E53935) / Hard (orange #FB8C00) / Good (green #43A047) / Easy (blue #1E88E5)
4. Tap rating → `_rate('good')` → `submitReviewAnswer(itemId, rating, DateTime.now()-cardStartAt)` → advance cursor
5. Cursor past end → `_sessionComplete()` state with "Review more" button
6. Empty response → `_allCaughtUp()` state with "Come back tomorrow" message

**Route registration** — `lib/app/routes.dart`:
```dart
import '../modules/review/review_queue_screen.dart';

static const String reviewQueue = "reviewQueue";

// In onGenerateRouted switch:
case reviewQueue:
  { return ReviewQueueScreen.route(routeSettings); }
```

### 7.5 FCM token registration on login
`lib/modules/login/store/login_store.dart` — existing method `onCreateNotificationToken(fcmToken)` extended with one fire-and-forget call at the end:
```dart
_apiService.registerUserDeviceFcm(fcmToken: fcmToken).catchError((e) {
  debugPrint('[FCM] register failed: $e');
});
```
Non-breaking: errors swallowed, existing flow untouched.

---

## 8. Operational

### 8.1 Deployment checklist
- [ ] Pull `ruchir-fixes-new` on API server → `npm install` (no new deps, but safe) → restart PM2/systemd
- [ ] Confirm `FIREBASE_SERVICE_ACCOUNT_JSON` env var is set (used by `admin.messaging()`)
- [ ] Confirm `CRON_WORKER_ENABLED=true` if you run multiple API instances (only the master should cron)
- [ ] On first request, new Mongoose models auto-create collections — no migration required
- [ ] Pull `ruchir-fixes-new` on app repo → `flutter pub get` → rebuild APK/IPA
- [ ] Test FCM end-to-end: set reminder in app → wait for minute to match → check device notification

### 8.2 Env vars (unchanged but relevant)
| Var | Purpose |
|-----|---------|
| `FIREBASE_SERVICE_ACCOUNT_JSON` | FCM admin SDK auth |
| `DB_URL` | MongoDB connection |
| `API_BASE_URL` (client `.env`) | All `/api/user/*` calls |

### 8.3 Monitoring
- Cron log prefix `[Reminder]` — watch for per-user failure bursts
- Auto-enqueue log prefix `[ReviewQueue]` — non-fatal warnings if userFeatures not loaded yet
- FCM token register log prefix `[FCM]` on client

### 8.4 Rollback
- API: revert `ruchir-fixes-new` merge. New collections stay, but harmless (no writes without the code).
- App: previous APK/IPA has no references to new routes; safe rollback.

---

## 9. Outstanding / Deferred

| Item | Reason | Suggested next step |
|------|--------|---------------------|
| Tier-3.15 master report refactor | Large scope (ranking, percentile bands, export) — needs separate design review | Schedule a design session; lift scope into its own branch |
| Review queue offline cache | Current impl requires network | Add Hive box mirroring `_items`; re-sync on reconnect |
| Streak recovery "freeze tokens" (1 miss allowed) | Product decision pending | Add `freeze_tokens` field on `UserStreak` once product approves |
| Admin dashboard FCM broadcast | Out of scope for this rollout | Build a new `/api/admin/fcm/broadcast` route + admin UI later |
| In-app review rating prompt | Flutter `in_app_review` package not in pubspec | Add dep + trigger after N successful review sessions |

---

## 10. File Inventory (this rollout)

### API — new
- `src/models/videoBookmark.model.js`
- `src/models/userStreak.model.js`
- `src/models/reviewQueueItem.model.js`
- `src/models/devicePushToken.model.js`
- `src/models/userPreferences.model.js`
- `src/routes/videoBookmark.route.js`
- `src/routes/resume.route.js`
- `src/routes/userStreak.route.js`
- `src/routes/userAnalytics.route.js`
- `src/routes/topicMastery.route.js`
- `src/routes/reviewQueue.route.js`
- `src/routes/devicePushToken.route.js`
- `src/routes/userPreferences.route.js`
- `src/business/userFeatures.business.js`

### API — modified
- `src/business/user_answer.business.js` (hook `_enqueueWrongAnswer` + `_touchStreak`)
- `src/business/user_video.business.js` (hook `_touchStreak`)
- `src/cronjobs/cron.js` (FCM reminder cron inside `isMainWorker`)

### App — new
- `lib/modules/widgets/resume_banner.dart`
- `lib/modules/widgets/video_bookmarks_sheet.dart`
- `lib/modules/progress/learning_insights_section.dart`
- `lib/modules/review/review_queue_screen.dart`

### App — modified
- `lib/api_service/api_service.dart` (14 new methods + `_authToken`)
- `lib/helpers/constants.dart` (11 URL constants)
- `lib/modules/login/store/login_store.dart` (FCM register fire-and-forget)
- `lib/modules/home/home_screen.dart` (ResumeBanner)
- `lib/modules/progress/progress_screen.dart` (LearningInsightsSection)
- `lib/modules/videolectures/video_player_detail.dart` (FAB cluster)
- `lib/app/routes.dart` (`reviewQueue` route)

---

## 11. Quick test script (curl)

```bash
TOKEN="<user-jwt>"
BASE="https://api.sushruta.in"

# Resume
curl -H "Authorization: Bearer $TOKEN" "$BASE/api/user/resume?limit=6"

# Streak
curl -H "Authorization: Bearer $TOKEN" "$BASE/api/user/streak"

# Analytics
curl -H "Authorization: Bearer $TOKEN" "$BASE/api/user/analytics/summary?days=30"

# Topic mastery
curl -H "Authorization: Bearer $TOKEN" "$BASE/api/user/topic-mastery"

# Review queue
curl -H "Authorization: Bearer $TOKEN" "$BASE/api/user/review/next?limit=5"

# Submit rating
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"item_id":"<id>","rating":"good","time_spent_ms":12000}' \
  "$BASE/api/user/review/answer"

# Enable reminders
curl -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"reminder_enabled":true,"reminder_time":"19:00","reminder_days":[1,2,3,4,5],"reminder_timezone":"Asia/Kolkata"}' \
  "$BASE/api/user/user-preferences"
```

---

**Author:** Claude (for Ruchir)
**Date:** 2026-04-18
**Commit trail:** see `ruchir-fixes-new` branch, commits up to and including `d173b30`.
