// ════════════════════════════════════════════════════════════════════
// MandatoryUpdateGate — full-screen blocker when current < min
// ════════════════════════════════════════════════════════════════════
//
// Drop into the app's root MaterialApp builder OR after splash. When
// `AppUpdateServiceV2().check()` returns mandatory == true, this
// widget paints a blocking screen with:
//
//   • Apple-style hero + system-update icon
//   • "v12.1.1 → v12.2.0" version label using tabular numerals
//   • Single primary "Update now" button — calls
//     AppUpdateServiceV2().startUpdate(immediate: true) which kicks
//     off Google Play in-app immediate update on Android, or opens
//     the App Store on iOS.
//   • Soft progress bar during flexible-update download (#22).
//
// No back button, no dismiss — student stays here until installed.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/app_tokens.dart';
import '../../services/app_update_service.dart' show AppUpdateStatus;
import '../../services/app_update_service_v2.dart';

/// Wraps any child screen + auto-shows the blocker when needed.
class MandatoryUpdateGate extends StatefulWidget {
  final Widget child;
  const MandatoryUpdateGate({super.key, required this.child});

  @override
  State<MandatoryUpdateGate> createState() => _MandatoryUpdateGateState();
}

class _MandatoryUpdateGateState extends State<MandatoryUpdateGate> {
  late Future<AppUpdateStatus> _future;

  @override
  void initState() {
    super.initState();
    _future = AppUpdateServiceV2().check();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUpdateStatus>(
      future: _future,
      builder: (ctx, snap) {
        final s = snap.data;
        if (s != null && s.mandatory) {
          return _BlockerScreen(status: s);
        }
        return widget.child;
      },
    );
  }
}

class _BlockerScreen extends StatefulWidget {
  final AppUpdateStatus status;
  const _BlockerScreen({required this.status});

  @override
  State<_BlockerScreen> createState() => _BlockerScreenState();
}

class _BlockerScreenState extends State<_BlockerScreen> {
  bool _starting = false;
  double? _progress;

  @override
  void initState() {
    super.initState();
    AppUpdateServiceV2().progress.listen((v) {
      if (!mounted) return;
      setState(() => _progress = v);
    });
  }

  Future<void> _update() async {
    setState(() => _starting = true);
    await AppUpdateServiceV2().startUpdate(immediate: true);
    if (!mounted) return;
    setState(() => _starting = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppTokens.scaffold(context),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTokens.accentSoft(context),
                      borderRadius: AppTokens.radius20,
                    ),
                    child: Icon(Icons.system_update_rounded,
                        size: 34, color: AppTokens.accent(context)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Update required',
                    style: AppTokens.displayMd(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.status.versionLabel,
                    style: AppTokens.numeric(context, size: 16).copyWith(
                      color: AppTokens.muted(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "This version is no longer supported. Please update to continue using Sushruta.",
                    style: AppTokens.bodyLg(context).copyWith(
                      color: AppTokens.ink2(context),
                      height: 1.5,
                    ),
                  ),
                  if (_progress != null) ...[
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: _progress,
                      minHeight: 4,
                      backgroundColor: AppTokens.surface3(context),
                      valueColor: AlwaysStoppedAnimation(
                        AppTokens.accent(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Downloading update… ${(_progress! * 100).toStringAsFixed(0)}%',
                      style: AppTokens.caption(context),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTokens.accent(context),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppTokens.radius16,
                        ),
                      ),
                      onPressed: _starting ? null : _update,
                      child: _starting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update now',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
