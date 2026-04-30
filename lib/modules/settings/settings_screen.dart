import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/routes.dart';
import '../../helpers/app_feedback.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/haptics.dart';
import '../dashboard/about_screen.dart';
import '../dashboard/store/home_store.dart';
import '../history/delete_history_screen.dart';
import '../login/pin_entry_screen.dart';
import '../profile/active_subscription.dart';
import '../profile/device_sessions_screen.dart';

/// SettingsScreen — single, Apple HIG-style settings home.
///
/// Replaces the scattered "Edit profile" / "Contact support" / "Reset
/// progress" / "Devices" entries that used to live across the
/// hamburger menu. Sections are grouped semantically:
///
///   • Account     — name, sign-in info
///   • Subscription — plan, billing
///   • Privacy & security — devices, biometric, PIN
///   • Data        — reset progress, downloaded notes
///   • Help        — contact support, FAQ
///   • Preferences — haptics, theme
///   • Legal       — terms, privacy policy, version
///
/// Each row is a [_SettingsRow] (icon → label → trailing chevron/value
/// → tap target). Sections are wrapped in a single soft-surface card
/// per the iOS Settings convention.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const SettingsScreen());
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hapticsEnabled = Haptics.enabled;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      // Lightweight: read from shared prefs the cached version, falls
      // back to "—" if not yet set.
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString('app_cached_version');
      if (v != null && mounted) setState(() => _appVersion = v);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<HomeStore>(context, listen: false);

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
        title: Text("Settings", style: AppTokens.titleLg(context)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s24),
          children: [
            _accountHero(store),
            const SizedBox(height: AppTokens.s20),
            _section('Account', [
              _SettingsRow(
                icon: Icons.person_outline_rounded,
                tint: const Color(0xFF1E88E5),
                label: 'Edit profile',
                onTap: () {
                  Haptics.selection();
                  Navigator.of(context).pushNamed(
                    Routes.editProfile,
                    arguments: {'userprofile': store.userDetails.value},
                  );
                },
              ),
              _SettingsRow(
                icon: Icons.devices_other_rounded,
                tint: const Color(0xFF8E44AD),
                label: 'Active devices',
                trailing: 'Manage',
                onTap: () {
                  Haptics.selection();
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const DeviceSessionsScreen(),
                    ),
                  );
                },
              ),
            ]),
            _section('Subscription', [
              _SettingsRow(
                icon: Icons.workspace_premium_rounded,
                tint: const Color(0xFFE89B20),
                label: 'My plan',
                onTap: () {
                  Haptics.selection();
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => ActiveSubscriptionScreen(),
                    ),
                  );
                },
              ),
              _SettingsRow(
                icon: Icons.shopping_bag_outlined,
                tint: const Color(0xFFE89B20),
                label: 'Browse plans',
                onTap: () {
                  Haptics.selection();
                  Navigator.of(context).pushNamed(Routes.subscriptionList);
                },
              ),
            ]),
            _section('Notifications', [
              _SettingsRow(
                icon: Icons.notifications_outlined,
                tint: const Color(0xFF1E88E5),
                label: 'Notification preferences',
                onTap: () {
                  Haptics.selection();
                  Navigator.of(context)
                      .pushNamed(Routes.notificationPreferences);
                },
              ),
            ]),
            _section('Privacy & security', [
              _SettingsRow(
                icon: Icons.fingerprint_rounded,
                tint: const Color(0xFF14A38B),
                label: 'Biometric unlock',
                trailing: 'On device',
                onTap: () {
                  Haptics.selection();
                  AppFeedback.info(context,
                      "Manage from your device's Privacy & Security settings.");
                },
              ),
              _SettingsRow(
                icon: Icons.lock_outline_rounded,
                tint: const Color(0xFF14A38B),
                label: 'App lock PIN',
                onTap: () {
                  Haptics.selection();
                  Navigator.of(context).push(PinEntryScreen.route());
                },
              ),
            ]),
            _section('Data', [
              _SettingsRow(
                icon: Icons.restart_alt_rounded,
                tint: const Color(0xFFE23B3B),
                label: 'Reset progress',
                onTap: () {
                  Haptics.selection();
                  Navigator.of(context)
                      .push(DeleteHistoryScreen.route(const RouteSettings()));
                },
              ),
              _SettingsRow(
                icon: Icons.download_done_rounded,
                tint: const Color(0xFF1E88E5),
                label: 'Downloaded notes',
                onTap: () {
                  Haptics.selection();
                  Navigator.of(context).pushNamed(Routes.downloadedNotes);
                },
              ),
            ]),
            _section('Help', [
              _SettingsRow(
                icon: Icons.headset_mic_outlined,
                tint: const Color(0xFF497BDC),
                label: 'Contact support',
                onTap: () {
                  Haptics.selection();
                  Navigator.of(context)
                      .push(AboutScreen.route(const RouteSettings()));
                },
              ),
            ]),
            _section('Preferences', [
              _SettingsToggleRow(
                icon: Icons.vibration_rounded,
                tint: const Color(0xFF8E44AD),
                label: 'Haptic feedback',
                value: _hapticsEnabled,
                onChanged: (v) {
                  setState(() {
                    _hapticsEnabled = v;
                    Haptics.enabled = v;
                  });
                  if (v) Haptics.medium();
                },
              ),
            ]),
            _section('About', [
              _SettingsRow(
                icon: Icons.info_outline_rounded,
                tint: AppTokens.muted(context),
                label: 'App version',
                trailing: _appVersion.isEmpty ? '—' : 'v$_appVersion',
                onTap: null,
              ),
            ]),
            const SizedBox(height: AppTokens.s32),
            Center(
              child: Text(
                'Sushruta LGS · Made for NEET SS aspirants',
                style: AppTokens.caption(context),
              ),
            ),
            const SizedBox(height: AppTokens.s32),
          ],
        ),
      ),
    );
  }

  Widget _accountHero(HomeStore store) {
    final name = store.userDetails.value?.fullname ?? '';
    final email = store.userDetails.value?.username ?? '';
    final initial = name.trim().isEmpty ? 'U' : name[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTokens.brand, AppTokens.brand2],
              ),
              borderRadius: AppTokens.radius16,
            ),
            child: Text(
              initial,
              style: AppTokens.titleLg(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Welcome' : name,
                  style: AppTokens.titleMd(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: AppTokens.caption(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
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
            child: Text(
              title.toUpperCase(),
              style: AppTokens.overline(context),
            ),
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
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    Key? key,
    required this.icon,
    required this.tint,
    required this.label,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  final IconData icon;
  final Color tint;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
              if (trailing != null) ...[
                Text(
                  trailing!,
                  style: AppTokens.caption(context),
                ),
                const SizedBox(width: AppTokens.s8),
              ],
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTokens.muted(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    Key? key,
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final IconData icon;
  final Color tint;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16, vertical: 6),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTokens.accent(context),
          ),
        ],
      ),
    );
  }
}
