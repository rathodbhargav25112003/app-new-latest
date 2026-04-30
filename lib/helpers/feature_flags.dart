/// Feature flags for the in-place UI upgrade.
///
/// Many mockup-driven polish items depend on API endpoints that may not yet
/// exist on every backend (staging vs prod vs legacy devices). Gating them
/// behind flags means the new UI ships safely — new widgets render only when
/// the backend is known to be able to feed them.
///
/// At runtime these are read from SharedPreferences (key: `ff.<name>`) so the
/// value can be flipped without a rebuild once we add a hidden debug screen.
/// For now they default to `false` for anything backend-dependent, `true` for
/// pure-client polish items that can't fail.
///
/// Usage:
///   if (FeatureFlags.readiness) { ...render readiness gauge... }
///
/// NOTE: This is a compile-time static getter today — wire to SharedPreferences
/// in Phase 2 once the admin/debug screen to toggle them exists. Until then,
/// flip defaults here.
library;

class FeatureFlags {
  FeatureFlags._();

  // ------------------------------------------------------------------
  // Pure-client polish — always on, no backend dependency.
  // ------------------------------------------------------------------
  /// Glass-blur tab bar on the dashboard.
  static const bool glassTabBar = true;

  /// Unified OTP cell widget across phone-login, email-verify, edit-profile.
  static const bool unifiedOtp = true;

  /// Searchable state dropdown in the signup flow.
  static const bool searchableState = true;

  /// Chip-grid exam picker in the signup flow.
  static const bool chipExamPicker = true;

  /// "Pick up where you left off" resume banner on Home.
  static const bool resumeBanner = true;

  /// Skeleton placeholders wherever lists load (replaces blank screens).
  static const bool skeletons = true;

  /// Timer ring + <5-min warning on in-exam screens.
  static const bool timerRing = true;

  /// Calculator + scratchpad overlay inside exams.
  static const bool examTools = true;

  /// Save-on-exit dialog for in-progress exams.
  static const bool saveOnExit = true;

  /// Collapsible report sections (saves scroll on long reports).
  static const bool collapsibleReport = true;

  /// Draft autosave for custom-test builder.
  static const bool builderAutosave = true;

  /// Reader TOC drawer (notes PDF).
  static const bool readerToc = true;

  /// Last-read persistence on notes.
  static const bool lastRead = true;

  /// Flat offline-files view (replaces 4-level tree).
  static const bool flatOffline = true;

  /// Flat bookmarks list with chip filters (replaces 4-level tree).
  static const bool flatBookmarks = true;

  /// Unified three-step checkout.
  static const bool unifiedCheckout = true;

  /// Vertical order-timeline on order detail.
  static const bool orderTimeline = true;

  /// Step progress on multi-step flows (builder, checkout, forgot-password).
  static const bool stepProgress = true;

  // ------------------------------------------------------------------
  // Backend-dependent — default OFF until API ships.
  // ------------------------------------------------------------------
  /// Readiness gauge on Progress dashboard — needs GET /api/progress/readiness
  static const bool readiness = false;

  /// Percentile bar on Report — needs report.percentile field
  static const bool percentile = false;

  /// Peer comparison panel — needs GET /api/progress/peer-compare
  static const bool peerCompare = false;

  /// Calendar "Add to calendar" for live classes — needs ICS endpoint
  static const bool calendar = false;

  /// AI study-plan surface — needs /api/planner/daily
  static const bool aiPlan = false;

  /// Flashcards — needs /api/flashcards
  static const bool flashcards = false;

  /// Rank-history sparkline on SPR — needs rank_history array
  static const bool rankHistory = false;

  /// TPQ (time-per-question) histogram — needs tpq array on report
  static const bool tpq = false;

  /// Concept-mastery heatmap — needs concept_mastery matrix
  static const bool conceptMap = false;

  /// CSS flipbook preview for hardcopy — purely client but needs high-res
  /// page images in the catalog JSON. Default off until backend exposes them.
  static const bool flipbook = false;

  /// Video transcripts — needs GET /api/videos/:id/transcript
  static const bool transcripts = false;

  /// Notes/Lab shortcuts grid on Home — needs lab_shortcuts config
  static const bool labShortcuts = false;

  // ------------------------------------------------------------------
  // Responsive — default on; can be disabled per-device if layout breaks.
  // ------------------------------------------------------------------
  /// Use new 744px breakpoint (iPad mini) for tablet layout.
  static const bool bp744 = true;

  /// Use new 1024px breakpoint (iPad Pro / laptop) for wide layout.
  static const bool bp1024 = true;
}
