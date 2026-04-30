// ════════════════════════════════════════════════════════════════════
// DeviceSessionsScreen — multi-device session manager UI
// ════════════════════════════════════════════════════════════════════
//
// Drop into the Profile → Security flow. Lists all currently active
// sessions for the signed-in account, grouped by device class
// (mobile / tablet / desktop). Each row carries:
//
//   • Class icon + raw platform label (e.g. "Android phone")
//   • Device name
//   • Relative last-active hint ("2h ago")
//   • Per-row swipe-to-revoke + per-row "Sign out" button
//
// Top of the list shows the policy: "1 device per class · max 3
// active". Bottom carries a "Sign out from all other devices"
// destructive action.
//
// Uses AppTokens throughout — light/dark agnostic.

import 'package:flutter/material.dart';
import '../../helpers/app_tokens.dart';
import '../../services/session_manager_service.dart';

class DeviceSessionsScreen extends StatefulWidget {
  const DeviceSessionsScreen({super.key});

  @override
  State<DeviceSessionsScreen> createState() => _DeviceSessionsScreenState();
}

class _DeviceSessionsScreenState extends State<DeviceSessionsScreen> {
  final SessionManagerService _service = SessionManagerService();
  late Future<List<DeviceSession>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.list();
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.list());
  }

  Future<void> _revoke(DeviceSession s) async {
    final ok = await _service.revoke(s.deviceId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Signed out from ${s.deviceName.isEmpty ? "device" : s.deviceName}' : 'Failed to revoke'),
    ));
    if (ok) _refresh();
  }

  Future<void> _logoutOthers() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out from all other devices?'),
        content: const Text(
          'You will stay signed in on this device. Other devices will need to sign in again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign out', style: TextStyle(color: AppTokens.danger(context))),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final n = await _service.logoutOthers();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(n == 0 ? 'No other sessions to sign out' : 'Signed out from $n device${n == 1 ? '' : 's'}'),
    ));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        title: const Text('Active devices'),
        backgroundColor: AppTokens.surface(context),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<DeviceSession>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snap.data ?? [];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PolicyCard(),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  _EmptyState()
                else
                  ...list.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SessionTile(
                          session: s,
                          onRevoke: () => _revoke(s),
                        ),
                      )),
                if (list.length > 1) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _logoutOthers,
                    icon: Icon(Icons.logout_rounded,
                        size: 18, color: AppTokens.danger(context)),
                    label: Text(
                      'Sign out from other devices',
                      style: TextStyle(color: AppTokens.danger(context)),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.accentSoft(context),
        borderRadius: AppTokens.radius12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.devices_other_rounded,
              size: 20, color: AppTokens.accent(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You can stay signed in on 1 phone, 1 tablet, and 1 laptop at a time. Signing in on a 4th device automatically signs out the oldest one in that class.',
              style: AppTokens.caption(context).copyWith(
                color: AppTokens.accent(context),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final DeviceSession session;
  final VoidCallback onRevoke;
  const _SessionTile({required this.session, required this.onRevoke});

  IconData get _icon {
    switch (session.deviceClass) {
      case 'tab':
      case 'tablet':
        return Icons.tablet_mac_rounded;
      case 'desktop':
        return Icons.laptop_mac_rounded;
      default:
        return Icons.smartphone_rounded;
    }
  }

  String get _classLabel {
    switch (session.deviceClass) {
      case 'tab':
      case 'tablet':
        return 'Tablet';
      case 'desktop':
        return 'Laptop / Desktop';
      default:
        return 'Phone';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.surface2(context),
              borderRadius: AppTokens.radius8,
            ),
            child: Icon(_icon, size: 20, color: AppTokens.ink(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.deviceName.isEmpty ? _classLabel : session.deviceName,
                  style: AppTokens.titleSm(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$_classLabel · ${session.lastActiveRelative}',
                  style: AppTokens.caption(context),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRevoke,
            style: TextButton.styleFrom(
              foregroundColor: AppTokens.danger(context),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Column(
        children: [
          Icon(Icons.devices_rounded, size: 32, color: AppTokens.muted(context)),
          const SizedBox(height: 8),
          Text('No active sessions', style: AppTokens.titleSm(context)),
          const SizedBox(height: 4),
          Text(
            'Sign in on another device to see it here.',
            style: AppTokens.caption(context),
          ),
        ],
      ),
    );
  }
}
