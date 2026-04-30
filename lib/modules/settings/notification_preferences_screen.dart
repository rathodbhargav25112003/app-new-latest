import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_feedback.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/haptics.dart';

/// NotificationPreferencesScreen — surfaces all the FCM notification
/// switches into one Apple-style settings sub-screen.
///
/// Persists prefs in [SharedPreferences] under stable keys; the FCM
/// dispatcher on the backend (or the app's local notification scheduler)
/// reads these to gate which channels fire.
///
/// Categories:
///  • Daily review reminder (with time picker)
///  • Streak risk alerts ("you'll lose your streak today")
///  • New content announcements (videos, MCQs, mocks)
///  • Subscription / billing alerts
///  • Doubt replies (existing doubt chat)
///
/// Default state: everything ON. User explicitly opts out.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const NotificationPreferencesScreen(),
    );
  }

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  // Storage keys.
  static const _kDailyReview = 'notif_daily_review_v1';
  static const _kDailyReviewHour = 'notif_daily_review_hour_v1';
  static const _kDailyReviewMinute = 'notif_daily_review_minute_v1';
  static const _kStreakRisk = 'notif_streak_risk_v1';
  static const _kNewContent = 'notif_new_content_v1';
  static const _kBilling = 'notif_billing_v1';
  static const _kDoubtReplies = 'notif_doubt_replies_v1';

  bool _loading = true;
  bool _dailyReview = true;
  TimeOfDay _dailyReviewTime = const TimeOfDay(hour: 20, minute: 0);
  bool _streakRisk = true;
  bool _newContent = true;
  bool _billing = true;
  bool _doubtReplies = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _dailyReview = prefs.getBool(_kDailyReview) ?? true;
      _dailyReviewTime = TimeOfDay(
        hour: prefs.getInt(_kDailyReviewHour) ?? 20,
        minute: prefs.getInt(_kDailyReviewMinute) ?? 0,
      );
      _streakRisk = prefs.getBool(_kStreakRisk) ?? true;
      _newContent = prefs.getBool(_kNewContent) ?? true;
      _billing = prefs.getBool(_kBilling) ?? true;
      _doubtReplies = prefs.getBool(_kDoubtReplies) ?? true;
      _loading = false;
    });
  }

  Future<void> _save<T>(String key, T value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dailyReviewTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTokens.accent(ctx),
            brightness: Theme.of(ctx).brightness,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dailyReviewTime = picked);
      await _save(_kDailyReviewHour, picked.hour);
      await _save(_kDailyReviewMinute, picked.minute);
      if (mounted) {
        AppFeedback.success(
          context,
          "Daily reminder set for ${picked.format(context)}",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTokens.scaffold(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTokens.ink(context), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text("Notifications", style: AppTokens.titleLg(context)),
        centerTitle: false,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTokens.accent(context),
              ),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(AppTokens.s24),
                children: [
                  Text(
                    "Pick what you want to hear about. Everything respects "
                    "your phone's Do Not Disturb.",
                    style: AppTokens.body(context),
                  ),
                  const SizedBox(height: AppTokens.s20),
                  _section('Daily review', [
                    _toggleRow(
                      icon: Icons.replay_circle_filled_rounded,
                      tint: const Color(0xFF1E88E5),
                      label: 'Daily review reminder',
                      subtitle:
                          'A nudge to keep your streak alive at your chosen time.',
                      value: _dailyReview,
                      onChanged: (v) {
                        Haptics.medium();
                        setState(() => _dailyReview = v);
                        _save(_kDailyReview, v);
                      },
                    ),
                    if (_dailyReview)
                      _actionRow(
                        icon: Icons.access_time_rounded,
                        tint: AppTokens.muted(context),
                        label: 'Reminder time',
                        trailing: _dailyReviewTime.format(context),
                        onTap: _pickTime,
                      ),
                    _toggleRow(
                      icon: Icons.local_fire_department_rounded,
                      tint: const Color(0xFFE89B20),
                      label: 'Streak risk alerts',
                      subtitle:
                          "Heads-up at 8 PM if you haven't reviewed today.",
                      value: _streakRisk,
                      onChanged: (v) {
                        Haptics.medium();
                        setState(() => _streakRisk = v);
                        _save(_kStreakRisk, v);
                      },
                    ),
                  ]),
                  _section('Content', [
                    _toggleRow(
                      icon: Icons.fiber_new_rounded,
                      tint: const Color(0xFF33AD48),
                      label: 'New content',
                      subtitle:
                          'Videos, notes, MCQs, and mocks added to your plan.',
                      value: _newContent,
                      onChanged: (v) {
                        Haptics.medium();
                        setState(() => _newContent = v);
                        _save(_kNewContent, v);
                      },
                    ),
                    _toggleRow(
                      icon: Icons.chat_bubble_outline_rounded,
                      tint: const Color(0xFF8E44AD),
                      label: 'Doubt replies',
                      subtitle:
                          'When mentors or AI reply to your raised doubts.',
                      value: _doubtReplies,
                      onChanged: (v) {
                        Haptics.medium();
                        setState(() => _doubtReplies = v);
                        _save(_kDoubtReplies, v);
                      },
                    ),
                  ]),
                  _section('Account', [
                    _toggleRow(
                      icon: Icons.receipt_long_rounded,
                      tint: const Color(0xFFE23B3B),
                      label: 'Subscription & billing',
                      subtitle:
                          'Trial reminders, plan renewals, payment failures.',
                      value: _billing,
                      onChanged: (v) {
                        Haptics.medium();
                        setState(() => _billing = v);
                        _save(_kBilling, v);
                      },
                    ),
                  ]),
                  const SizedBox(height: AppTokens.s24),
                  Center(
                    child: Text(
                      'You can also manage notifications from your '
                      'phone settings.',
                      textAlign: TextAlign.center,
                      style: AppTokens.caption(context),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(title.toUpperCase(),
                style: AppTokens.overline(context)),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              borderRadius: AppTokens.radius16,
              border:
                  Border.all(color: AppTokens.border(context), width: 0.5),
            ),
            child: Column(
              children: List.generate(rows.length, (i) {
                final isLast = i == rows.length - 1;
                return Container(
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: AppTokens.border(context),
                              width: 0.5,
                            ),
                          ),
                  ),
                  child: rows[i],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required Color tint,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16, vertical: AppTokens.s8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.14),
              borderRadius: AppTokens.radius8,
            ),
            child: Icon(icon, color: tint, size: 18),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTokens.titleSm(context)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTokens.caption(context)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTokens.accent(context),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required Color tint,
    required String label,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16, vertical: AppTokens.s12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withOpacity(0.14),
                  borderRadius: AppTokens.radius8,
                ),
                child: Icon(icon, color: tint, size: 18),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Text(label, style: AppTokens.titleSm(context)),
              ),
              Text(trailing, style: AppTokens.caption(context)),
              const SizedBox(width: AppTokens.s8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppTokens.muted(context)),
            ],
          ),
        ),
      ),
    );
  }
}
