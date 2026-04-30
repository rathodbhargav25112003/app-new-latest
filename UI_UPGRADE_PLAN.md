# Sushruta LMS · In-place UI/UX Upgrade Plan

> **Principle:** upgrade the app that exists today. No new routes, no renamed screens, no broken API contracts, no migration to Material 3, no font changes. Every improvement lands on an existing file/widget/store.  
> **Inputs preserved:** all twelve mockup clusters (08 store + flipbook, 10 explorer, 11 exam engine, 12 analytics+) are retained as the **feature/polish target** — they just land on the real screens below instead of replacing them.

---

## 0. What we are NOT changing

- `lib/app/routes.dart` — all 150+ named routes stay.
- `lib/api_service/api_service.dart` — no signature changes; additive methods only if backend is ready.
- MobX store public APIs — `@observable` / `@action` surface stays stable; internals can be refactored.
- Material 2 (`useMaterial3: false`). No M3 migration.
- Fonts: Jost / DM Sans remain. No font swap.
- Primary colour `#0048D0` stays the brand anchor.
- Navigation model: bottom-tab `DashboardScreen` stays. Drawer stays. Named-route pattern stays.

This is a **polish + absorb** pass, not a redesign.

---

## 1. Design-system upgrade (one-time — propagates everywhere)

File: `lib/helpers/colors.dart`, `lib/helpers/dimensions.dart`, and a new helper `lib/helpers/app_theme.dart` (already referenced in many places — extend, don't replace).

| Token | Today | Upgrade | Why |
|---|---|---|---|
| Primary | `#0048D0` | keep | Brand anchor |
| Accent-soft | not defined | `#E6EEFF` (light) / `#0D1B3D` (dark) | For chip backgrounds, selected-row fills — avoids heavy primary blocks |
| Success | `#33AD48` | keep, add `success-soft` `#E8F7EB` | Report screens, paid-plan chips |
| Error | `#FF0000` | soften to `#E23B3B` + `error-soft` `#FDECEC` | Reduce retinal burn on form validation |
| Warning | not defined | `#E89B20` + `warning-soft` `#FDF3E0` | Timer <5 min, low-stock badges |
| Surface-1/2/3 | ad-hoc greys | define three neutral surfaces: `#FFFFFF`, `#F6F7FA`, `#EDEFF4` (light) / `#0B0C10`, `#12141A`, `#1A1D25` (dark) | Replaces the "some cards look flat, some elevated" inconsistency |
| Border | ad-hoc | `#E6E8EE` light / `#1F232D` dark | Consistent hairline everywhere |
| Shadow tiers | ad-hoc | `shadow-1`, `shadow-2`, `shadow-3` via `BoxShadow` presets in `app_theme.dart` | Plan cards, tiles, dialogs all pick the same tier |
| Radii | varied 5/10/15/20/25 | standardise 8 / 12 / 16 / 20 / 28 | Still Apple-ish, but predictable |
| Tap target | 36–44 mixed | enforce ≥44pt | Fixes auth + report-filter chips |

**Typography scale** (same fonts, tightened): the `Dimensions` class gets semantic entries — `displayLg`, `displayMd`, `titleLg`, `titleMd`, `bodyLg`, `body`, `caption`, `overline`. Negative letter-spacing only on `display*`. `fontFeatures: [FontFeature.tabularFigures()]` for any numeric-heavy screen (timer, score, price).

**Dark-mode audit:** run through every `AppColorsDark` use-site and replace hard-coded greys with the new three-tier surface tokens. Fixes the "dark overlay text contrast fails WCAG" issue in home carousels.

**Shared components — upgrade once, every screen benefits:**

| Widget | File | Change |
|---|---|---|
| `CustomButton` | `modules/widgets/custom_button.dart` | Add variants: `primary`, `secondary`, `ghost`, `danger`, `block`. Loading state shows inline spinner, not a full overlay. Press state scales 0.98. Disabled state uses `surface-2` + muted text. |
| `SearchFiled` | `helpers/comman_widget.dart` | Add focus-ring (1.5px accent), leading search icon with 10pt inset, inline clear-button, placeholder in `caption` size. Responds to new focus animation in `app_theme.dart`. |
| `BookmarkWidget` | `helpers/comman_widget.dart` | Replace "filled circle" with outlined + filled states, 200ms spring when toggled, haptic `HapticFeedback.selectionClick()`. |
| Card/Tile surface | no single wrapper today | Introduce `AppCard` in `modules/widgets/app_card.dart` — wraps `Container` with surface-1 + shadow-1 + radius-16. Incrementally replace scattered `Container` decorations. |
| `ToastWidget` | `modules/widgets/bottom_toast.dart` | Queue support, position above bottom-nav, severity colour (info/ok/warn/bad), auto-dismiss 3s with pause-on-touch. |
| `NetworkAlertWidget` | `core/network/NetworkAlertWidget.dart` | Inline banner (not full-screen dialog) except on auth screens. |
| `NoInternetConnection` | `modules/widgets/no_internet_connection.dart` | Illustration + "Retry" CTA + shows queued actions. |
| `QuestionPallet` | `modules/test/question_pallet.dart` | Colour-tier rebuild (see §5 Tests) — same widget, stronger legend + sticky header. |
| Empty-state | none | New `AppEmptyState({icon, title, body, cta})` under `modules/widgets/empty_state.dart`. Used by Bookmarks, Search, Offline-notes, History, Review-queue. |
| Skeleton | none | New `AppSkeleton` (Shimmer-based) under `modules/widgets/skeleton.dart`. Replaces blank-screen loading on Home, Tests, Reports, Notes, Videos. |

---

## 2. Navigation polish (no route changes)

- **Bottom tab bar** (`dashboard_screen.dart`): glass-blur surface (`backdrop`: `BackdropFilter` with sigma 18), rounded-top 20pt, 10pt inset from edge on iPad/large screens. Icons: pick one source (Phosphor or Cupertino) and stick. Active tab: accent label + 2pt top indicator. Bottom safe-area respected.
- **AppBars**: unify title style (`titleMd`, weight 600, -0.2 letter-spacing). Remove elevation; use hairline border instead.
- **Drawer** (if surfaced anywhere): same colour tokens as tab bar, no Material-default blue headers.
- **Breadcrumbs** for deep trees (Notes, Tests, Bookmarks 3-4 levels): add a single-line breadcrumb under the AppBar using `Wrap` + chevron separators. No new routes — just reads `ModalRoute.of(context)` stack.
- **Responsive**: existing `1300px` breakpoint stays. Below 1300 keeps current phone/tablet behaviour. Above 1300 on macOS/web we already have a layout — just apply the new surface tokens.

---

## 3. Screen-by-screen upgrade map

Each entry = **existing file → polish deltas + mockup input absorbed**. No new screens.

### 3.1 Auth (11 screens)

| Screen | Polish deltas | Mockup input absorbed |
|---|---|---|
| `main_splash_screen.dart`, `splash_screen.dart` | One splash, not two — second becomes a 300ms fade-through routed inside the first. Keep Lottie. Version-check moves inline (no full-screen block). | Mockup 01 single-screen auth entry (absorbed as transition, not new route) |
| `login_with_phone_screen.dart` | Larger phone field, country flag prefix, inline OTP step (stepper dots at top), error toast (queued) on failure — was silent. Loading state on OTP button. | Mockup 01 login polish |
| `login_screen.dart` (email fallback) | Show/hide password toggle, inline validation on blur, same stepper visual | Mockup 01 auth polish |
| `signup_with_phone_screen.dart` / `signup_screen.dart` | Password strength bar (weak/ok/strong), terms checkbox with linked privacy/terms text, progress "1 of 2" at top | Mockup 01 signup |
| `verify_otp.dart` / `verify_otp_mail.dart` / `verify_otp_phone.dart` | Consolidate visual treatment of OTP boxes (6 cells, 48pt tall, auto-advance, paste support, 60s resend timer with countdown ring) — three files still exist, they just use the same `OtpField` widget now | Mockup 01 OTP cell polish |
| `forgot_password.dart` / `forgot_email.dart` | Step indicators, same field polish | Mockup 01 |
| `edit_profile.dart`, `google_signup_form.dart`, `preparing_for_screen.dart` | State dropdown becomes searchable (autocomplete), exam-preparing-for becomes a chip grid instead of radio list | Mockup 03 profile polish |

**API:** no changes. **Routes:** no changes.

---

### 3.2 Home / Dashboard (7 screens)

| Screen | Polish deltas | Mockup input absorbed |
|---|---|---|
| `dashboard_screen.dart` | Tab bar glass polish (§2). Cortex.ai tab: accent dot badge when unread. | Mockup 02 tab bar |
| `home_screen.dart` | **Biggest win target.** Collapse current 10-carousel wall into 4 high-signal sections: (1) Resume banner, (2) Today's plan (reads from existing store — if empty, collapsed), (3) Quick access grid (Videos/Notes/Tests/Mocks/Bookmarks/Live), (4) Featured carousel — capped at 6 items. Existing data stores untouched; we just render fewer carousels by default with an "Show all sections" affordance. Skeleton loader replaces blank first paint. Dark overlay gets a gradient scrim so text passes AA. | Mockup 02 home restructure; skeleton loader; scrim fix |
| `profile_screen.dart` (tab) | Form groups with section headers, each field has `titleSm` label + inline validation. Password change becomes its own row with chevron (opens existing edit screen). Theme toggle moves into a Settings group with switch + live preview tint. Logout becomes visible (not in overflow). | Mockup 03 profile |
| `search_screen.dart` | Sticky category chip row under search, recent searches chip row, "no results" empty state (AppEmptyState). Result list uses AppCard with 80pt thumbnail + metadata chips. | Mockup 10 explorer chip row pattern |
| `notifications_screen.dart` | Date-grouped sections ("Today", "Yesterday", "This week"), unread dot, swipe-to-mark-read, bulk "Mark all read" AppBar action. | Mockup 09 notifications |
| `continue_watching_screen.dart` | Thumbnail with progress bar overlay, last-watched timestamp, context chip (subject/chapter). | Mockup 04 continue watching |
| `featured_test_exam_screen.dart` | AppCard hero, chips for duration/questions/marks, primary CTA is "Start" with a secondary "Instructions" ghost button. | Mockup 06 test lobby |

**Store:** `HomeStore` gains a computed `visibleSections` observable based on user prefs — no API change.

---

### 3.3 Video Lectures (6 screens)

| Screen | Polish deltas | Mockup input absorbed |
|---|---|---|
| `video_category.dart` | Grid → 2-col on phone, 3 on tablet, 4 on iPad/laptop. Offline badge becomes a chip on card corner. | Mockup 04 category |
| `video_subject_detail.dart`, `video_chapter_detail.dart`, `video_topic_category.dart` | Collapsible chapter headers with progress %, video row has inline download icon with progress (replaces silent background download), duration and estimated-watch chip, completion tick. | Mockup 04 list polish |
| `video_player_detail.dart` | Buffering indicator visible, fullscreen 200ms transition, chapter list as right-side panel on tablet landscape / laptop. **Player controls**: scrubber with chapter markers, playback-speed chips, quality chip, bookmark FAB animates to sheet. Transcript/notes side panel reads from existing API if transcript field present; gracefully hides if not. | Mockup 04 player |

**API:** unchanged. If transcript endpoint does not exist yet the panel is hidden behind a feature flag read from `AppConfig`.

---

### 3.4 Notes (10 screens)

| Screen | Polish deltas | Mockup input absorbed |
|---|---|---|
| `notes_category.dart` / `notes_subject_detail.dart` / `notes_chapter_detail.dart` / `notes_topic_category.dart` | Same grid/list polish as Videos. Offline indicator becomes a small cloud-with-check icon on any row that has a downloaded copy — visible **before** tapping. Download size shown before kicking off download (confirm sheet). | Mockup 05 notes polish |
| `notes_read_view.dart` | PSPDFKit stays. Add: in-doc search (native PSPDFKit API), TOC drawer on left (reads PDF outline if present), page-thumbnail strip on bottom, highlight tool polish, **last-read page** persisted per document in existing `NotesStore`. | Mockup 05 reader + TOC |
| `downloaded_notes.dart` / `offline_category_list.dart` / `offline_topic_list.dart` / `offline_title_list.dart` / `offline_subcategory_list.dart` | Collapse the 4-level offline hierarchy by showing a single flat "Downloaded" list with category chip filter at top — keeps the existing screens live for deep-link compatibility but defaults to the flat view. | Mockup 10 explorer shorter flow |

---

### 3.5 Tests / Exams (17 screens)

This is where **Mockup 11 (advanced exam engine) fully absorbs** into existing screens — no new routes.

| Screen | Polish deltas | Mockup input absorbed |
|---|---|---|
| `test_category.dart` / `test_subject_detail.dart` / `test_chapter_detail.dart` / `show_test_screen.dart` / `select_test_list.dart` | Card polish, offline chip, duration/questions/difficulty chips, Start/Resume CTA states. | Mockup 06 |
| `test_instruction_screen.dart` | Instructions become a sheet with bullets + icons instead of wall of text. "I understand" checkbox enables Start. | Mockup 11 lobby |
| `test_exam_screen.dart` (master live) | Timer ring with conic gradient (Flutter: `CustomPainter` arc) replacing text-only countdown. **Warning state** when <5 min: ring turns warn colour + haptic tick. **Tools row** pinned to AppBar: Calculator (opens bottom sheet with existing scientific calc — add one if not present, small widget), Scratchpad (full-screen modal with a `TextField` + optional `Signature` pad — persisted per-question in local store), Flag-for-review toggle. Back-button intercept → "Save & Exit" dialog. | Mockup 11 tools, timer, save-on-exit |
| `practice_test_exam_screen.dart` | Same tools, plus inline "Show answer" that slides up solution card. | Mockup 11 practice |
| `practice_test_solution_exam_screen.dart` | Side-by-side layout on tablet/laptop, stacked on phone. | Mockup 11 |
| `question_pallet.dart` | Legend chip row stays visible, stronger colour distinction (fill vs outline vs solid), sticky section header if exam has sections (used by master sectionwise). | Mockup 11 palette |
| `test_report_screen.dart` | Score ring (conic gradient), KPI row (accuracy / time / rank if available), **collapsible sections** (Overall, Topic-wise, Time analysis, Mistakes) to reduce overwhelm. Retry CTA surfaced. | Mockup 12 analytics sections |
| `test_report_details_screen.dart` | Question-by-question cards with inline "My answer" / "Correct answer" pills, collapsible explanation, bookmark button inline. | Mockup 06 review |
| `mca_analysis_screen.dart` | Chart with legend + tooltip on tap, empty-state when data missing. | Mockup 12 |
| `quiz_screen.dart`, `quiz_exam_screen.dart`, `quiz_solution_screen.dart`, `quiz_solution_report_screen.dart` | Same polish family as the full exam stack. Simplified layout stays. | Mockup 11 |

**New in-exam tools** (Calculator, Scratchpad) land as **bottom-sheet widgets** reused across `test_exam_screen.dart`, `practice_test_exam_screen.dart`, `custom_test_exam_screen.dart`, `test_master_exam_screen.dart`, `section_exam_screen.dart`, `quiz_exam_screen.dart`. One widget file: `modules/test/tools/exam_tools.dart`. Zero route change.

**Laptop keyboard shortcuts** (A/B/C/D/E select, M mark, N next, P prev, F flag, Enter submit): wire via `RawKeyboardListener` around the exam screen body on `>= 1024px`. Small chip row at bottom shows the shortcuts. Phone/tablet unaffected.

---

### 3.6 Custom Tests (10 screens)

| Screen | Polish deltas | Mockup input absorbed |
|---|---|---|
| `custom_test_lists.dart` | Saved-configs cards with last-used timestamp and a "Rerun" CTA. | Mockup 06 |
| `select_custom_test_category.dart` / `_chapter.dart` / `_topic.dart` / `_test.dart` | Add a persistent bottom bar showing "N chapters · M topics · ~Q questions" estimate that updates live. Multi-select tap targets to 44pt. | Mockup 11 builder |
| `custom_configuration.dart` | Stepper gets a visible progress bar + back/next at bottom. Draft auto-save to `CustomTestStore` — resumable. | Mockup 11 |
| `custom_preview.dart` | Summary AppCard with chips, edit button reopens stepper at correct step, primary Start CTA. | Mockup 11 |
| `custom_test_exam_screen.dart` | Same exam-engine tools as §3.5. | Mockup 11 |
| `custom_test_report_screen.dart` / `_details_screen.dart` | Report polish matches §3.5. | Mockup 12 |

---

### 3.7 Progress / Reports (11 screens + master/spr)

Mockup 12 (analytics+) lands **here** — not on a new screen — by extending the existing Progress tab and Reports stack.

| Screen | Polish deltas | Mockup input absorbed |
|---|---|---|
| `progress_screen.dart` | **Readiness gauge** (half-donut CustomPainter) at the top pulling a simple score already computed by `ReportStore`. **Percentile bar** (if backend sends it; else hidden). **Peer-comparison mini-card** (only if endpoint exists; feature-flagged). **Mock rank history** as a small SVG/CustomPainter line under "Trend". Keeps existing pie and bar charts but restyles with new tokens. Tabs on top: Overview / Topics / Trend / Calendar. | Mockup 12 readiness, percentile, peer, rank history |
| `report_main_screen.dart` | Tab bar stays, restyled. Date-range filter becomes a visible chip at top (no longer hidden). Export menu in overflow (PDF/CSV — stubbed if endpoint missing). | Mockup 12 |
| `report_category_list.dart`, `reports_subcategory_list.dart`, `reports_topic_list.dart` | Colour-coded per-topic bars (weak/ok/strong using `bad-soft` / `warn-soft` / `success-soft`). Tap a row → the existing details screen. | Mockup 12 topic map |
| `report_list.dart` / `select_exam_report_list.dart` | Attempts shown as cards with score ring, sort chips (Date / Score / Time), filter chip. | Mockup 12 |
| `solution_report.dart` | Tabular → per-question AppCard on phone, real table on tablet/laptop. | Mockup 12 |
| `report_sub_category.dart` | Breadcrumb + heatmap row for sub-topic mastery. | Mockup 12 concept-adjacent |
| `master reports/*.dart`, `spr reports/*.dart` | Same polish family so these don't visually drift from regular reports. | Mockup 12 |

**Time-per-question histogram + concept map + study-calendar + AI-plan** from Mockup 12: these ride on `progress_screen.dart` as optional sections behind feature flags. If the backend endpoints aren't yet ready, the sections simply don't render. No route change, no new screen — the plan pane lands under the existing "Overview" tab content.

---

### 3.8 Bookmarks (10 screens)

| Screen | Polish deltas | Mockup input absorbed |
|---|---|---|
| `bookmark_main_list.dart` / `select_bookmark_by_exam.dart` / `bookmark_category_list.dart` / `bookmark_subcategory_screen.dart` / `bookmark_topic_list.dart` / `bookmark_exam_attempt_list.dart` | **Collapse discovery flow**: top of the main list becomes a searchable flat list with "Exam", "Category", "Topic" chip filters — the 4-level deep nav still works but is no longer the default. Badge counts added to every category/topic row. | Mockup 10 shorter flow |
| `bookmark_question_list.dart` | Question cards with subject/topic chips, bookmark toggle inline, "Jump to question" CTA. | Mockup 10 |
| `bookmark_question_detail.dart` | Same layout as `test_report_details_screen.dart` for consistency, inline explanation with toggle. | Mockup 06 |
| `masterBookmarks/*.dart` | Same polish — don't drift from regular bookmarks. | Mockup 10 |
| `new-bookmark-flow/*.dart` | Either merge into the main flow or mark deprecated. Pick one visual contract. **Decision point.** | — |

---

### 3.9 Subscription / Store (20 screens)

Mockup 08 (unified store + flipbook + admin) absorbs here. **Core decision**: one of the two subscription flows (`subscriptionplans/` vs `new_subscription_plans/`) becomes the single surface. Based on files, `new_subscription_plans/` is the active path — we polish that and mark the older one deprecated.

| Screen | Polish deltas | Mockup input absorbed |
|---|---|---|
| `new_subscription.dart` | Plan cards side-by-side on tablet, vertically stacked on phone. "Most popular" ribbon on recommended plan. Features list uses iconified bullets, not dense paragraphs. | Mockup 08 plan hero |
| `new_select_subscription_plan.dart` | Filter chips (duration, type), sort chips (price asc/desc). | Mockup 08 |
| `new_custom_subscription_plan.dart` | Feature checkboxes grouped by category with live recalculated price panel pinned at bottom. | Mockup 08 |
| `new_checkout_plan.dart` | **Three-step tracker** (Address / Payment / Confirm). Coupon inline-validates on blur. Discount breakdown visible (subtotal / discount / tax / total). | Mockup 08 checkout |
| `new_payment_success_screen.dart` / `payment_successful_screen.dart` | One success screen, celebration animation (Lottie already available), order summary + activation status + "Download invoice" CTA. | Mockup 08 confirmation |
| `payment_failed_screen.dart` | Clear error, Retry CTA, contact support ghost CTA. | Mockup 08 |
| `new_add_address.dart` | Pincode autofills city/state (existing API reuses). Default-address toggle. | Mockup 08 |
| `select_delivery_type.dart` | Visual card options (Home / Pickup) with ETA chip. | Mockup 08 |
| `ordered_book_list.dart` / `track_order_screen.dart` | **Vertical timeline** (Ordered → Packed → Shipped → Out for delivery → Delivered) with live status chip. Tracking info card with courier + AWB + "Copy" button. "Read digital copy while you wait" CTA if user owns the e-book. | Mockup 08 tracking |
| `hardcopyNotes/book_list_screen.dart` / `hardcopy/*.dart` | Book covers get consistent aspect-ratio (0.72:1), gradient scrim on cover for price legibility, "Preview" CTA opens **flipbook**. **Flipbook viewer** lands as a new widget `modules/hardcopy/flipbook_viewer.dart` — no new route, opened via `showDialog` or `Navigator.push` with existing route if needed. Phone: single page + bottom scrubber. Tablet/iPad: two-page spread. End-of-preview paywall upsells the plan. | Mockup 08 flipbook |
| `subscription_*.dart` (old flow) | Mark `@Deprecated` with a comment pointing to `new_*` screens. Visual polish minimal — just keep them from looking broken until fully phased out. | — |

**Admin side** (Mockup 08 admin sections): belongs to the separate admin web (`admin/`) and not the Flutter app. Admin additions (SKU manager, flipbook range, orders queue) stay as the mockup for when we touch the admin codebase.

---

### 3.10 Live Classes (4 screens)

| Screen | Polish deltas | Mockup input absorbed |
|---|---|---|
| `live_class_main_screen.dart` | TabBar polish, countdown chip on upcoming rows. | Mockup 09 |
| `live_classes.dart` / `live_classes_upcoming.dart` / `live_classes_completed.dart` | Class cards: presenter avatar, subject chip, date/time with countdown, Join CTA with subscription-gate check (existing `SubscriptionStore`). "Add to calendar" secondary. Recording rows show duration + quality chip. | Mockup 09 |

---

### 3.11 Master Tests (10 screens)

All polish identical to §3.5, applied to: `allTest_category.dart`, `all_select_test_list.dart`, `choose_test_screen.dart`, `test_master_exam_screen.dart`, `practice__master_test_exam_screen.dart`, `sections_list_screen.dart`, `section_exam_screen.dart`, `start_section_instruction_screen.dart`.

**Leaderboard** (`leader_board_screen.dart`, `leaderboard_category_screen.dart`, `leaderboard_examlist_screen.dart`): user row sticky at bottom with "You: Rank #N · Top X%". Percentile chip. Date-range filter.

**Mockup 11 section-based mode** lands directly on `section_exam_screen.dart` — section pills, lock state after submit, per-section timer, palette scoped per section.

---

### 3.12 Profile / Settings (5 screens)

| Screen | Polish deltas | Mockup input absorbed |
|---|---|---|
| `profile_screen.dart` (tab) | See §3.2. | Mockup 03 |
| `edit_profile.dart` | Form groups, save disabled until dirty, autosave draft to MobX. | Mockup 03 |
| `active_subscription.dart` | Plan card with validity ring, renew CTA, "Manage plan" link, order-history link. | Mockup 03/08 |
| `verify_change_mobile_otp.dart` | Same OTP widget as auth. | Mockup 01 |
| `delete_history_screen.dart` | Confirm via secondary sheet with a count "Delete 124 items?", undo snackbar for 5s. | Mockup 03 |

---

### 3.13 Misc (6 screens)

| Screen | Polish deltas |
|---|---|
| `blog_screen.dart` / `blog_details_screen.dart` | Reader typography upgrade, related-posts row at bottom (if API gives; else hide). |
| `testimonial_screen.dart` | Carousel pauses on interaction, card typography polish. |
| `about_screen.dart` | Version badge, links to privacy/terms/website, open-source libs list. |
| `review_queue_screen.dart` | AppEmptyState when empty, queue rows use AppCard, existing SM-2 flow unchanged. |
| `new-bookmark-flow/*` | Decision: consolidate or deprecate (see §3.8). |

---

## 4. Feature flags (so nothing breaks if backend isn't ready)

A single helper `lib/helpers/feature_flags.dart` reads from `AppConfig`/`SharedPreferences`:

```dart
class FeatureFlags {
  static bool readiness = false;        // Mockup 12 readiness gauge
  static bool percentile = false;       // Mockup 12 percentile bar
  static bool peerCompare = false;      // Mockup 12 peer comparison
  static bool calendar = false;         // Mockup 12 study calendar
  static bool aiPlan = false;           // Mockup 12 AI study plan
  static bool flashcards = false;       // Mockup 12 flashcards (SM-2)
  static bool rankHistory = false;      // Mockup 12 rank trend
  static bool tpq = false;              // Mockup 12 time-per-question
  static bool conceptMap = false;       // Mockup 12 concept map
  static bool flipbook = true;          // Mockup 08 preview
  static bool transcripts = false;      // Mockup 04 transcript panel
  static bool labShortcuts = true;      // Mockup 11 keyboard shortcuts
}
```

Every "new" feature absorbed into existing screens reads a flag. If the backend endpoint is absent, the section simply doesn't render — existing UX preserved.

---

## 5. Responsive polish

- Current breakpoint `1300px`: keep.
- Add a soft breakpoint at `744px` (iPad mini) for tablet-specific grid densities.
- On `>= 1024px` (iPad Pro / laptop): video player gets right-side chapter panel; exam screen gets left-side palette + keyboard-shortcut chips; reports become 2-column dashboards.
- All lists use `LayoutBuilder` to switch column counts — no new widgets, just helpers in `app_theme.dart`.

---

## 6. Dark-mode audit (blocking issues)

- Home carousel text overlays: add 0→60% black gradient scrim.
- Report charts: ensure legend dots + labels pass AA on `#0B0C10`.
- Form focus ring: currently blue, fades on dark — switch to accent-soft.
- Bottom tab bar glass: on dark, use 40% opacity black with sigma 18 blur.

---

## 7. Migration order (low-risk first, high-impact last)

1. **Design-system tokens + shared widgets** (`colors.dart`, `dimensions.dart`, `app_theme.dart`, `CustomButton`, `SearchFiled`, `BookmarkWidget`, `ToastWidget`, new `AppCard`, `AppEmptyState`, `AppSkeleton`). No screen visually changes much yet, but everything gets the new primitives.
2. **Tab bar + AppBars** — instant "feels new" across the whole app.
3. **Home screen** — biggest perceived win, also most complex state.
4. **Exam engine + tools** (calculator, scratchpad, timer ring, palette polish, keyboard shortcuts). Ship once, benefits every exam route.
5. **Reports / Progress polish + Mockup 12 features behind flags.**
6. **Notes reader TOC + in-doc search.**
7. **Subscription checkout polish + flipbook viewer.**
8. **Bookmarks + search collapse** (Mockup 10 shorter flow).
9. **Auth flow polish, profile, misc screens.**
10. **Deprecation pass**: remove the old `subscriptionplans/` duplicate, decide on `new-bookmark-flow/`.

---

## 8. What stays untouched this pass

- Any `ApiService` method signature.
- Any MobX observable name currently read by widgets.
- All 150+ route names.
- Asset pipeline (same images/fonts).
- Firebase/Vimeo/PSPDFKit integrations.
- macOS in-app purchase flow (existing).
- Android/iOS build config.

---

## 9. Mockup → existing-code absorption table (quick reference)

| Mockup cluster | Lands on |
|---|---|
| 01 Auth | `modules/login/*`, `modules/signup/*`, `modules/verifyotp/*`, `modules/splash/*` |
| 02 Home | `modules/dashboard/home_screen.dart` + `dashboard_screen.dart` |
| 03 Profile | `modules/dashboard/profile_screen.dart`, `modules/signup/edit_profile.dart`, `modules/profile/active_subscription.dart` |
| 04 Video | `modules/videolectures/*` |
| 05 Notes | `modules/notes/*` |
| 06 Tests | `modules/test/*` + reports (polish-only delta) |
| 07 Progress | `modules/progress/progress_screen.dart` + `modules/reports/*` |
| 08 Plans / Store / Flipbook | `modules/new_subscription_plans/*`, `modules/hardcopy/*`, `modules/hardcopyNotes/*`, `modules/orders/*`; admin parts → `admin/` repo later |
| 09 Bonus | `modules/dashboard/notifications_screen.dart`, `modules/liveclass/*`, empty/error states everywhere |
| 10 Explorer | Bookmark nav collapse, offline-notes flat view, global search chip row |
| 11 Exam engine | `modules/test/*`, `modules/customtests/*`, `modules/quiztest/*`, `modules/masterTest/*` — new shared `exam_tools.dart` |
| 12 Analytics+ | `modules/progress/*`, `modules/reports/*` — behind feature flags |

---

## 10. What I need from you to start executing

1. **Sign-off on the migration order** in §7 (or tell me which phase to start first).
2. **Feature-flag defaults** — for the Mockup 12 items that need backend endpoints, which ones are ready today? I'll turn those flags on; the rest stay off until the API ships.
3. **Decision on the two duplicate flows**:
   - Keep only `new_subscription_plans/` and deprecate `subscriptionplans/`? (my recommendation)
   - Keep only the unified bookmark flow and deprecate `new-bookmark-flow/`? (or vice versa)
4. **Admin polish scope** — is Mockup 08's admin side (SKU manager, flipbook upload, orders queue) in scope for this cycle or queued for later?

Once you give me a green light on phase 1 (design-system tokens + shared widgets), I'll start editing the actual `colors.dart`, `dimensions.dart`, `custom_button.dart`, etc. — no new files except the three shared primitives (`AppCard`, `AppEmptyState`, `AppSkeleton`) and the new `exam_tools.dart` used by the test screens.
