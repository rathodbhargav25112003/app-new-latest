// ════════════════════════════════════════════════════════════════════
// auth_widgets.dart — Apple-style auth flow UI primitives
// ════════════════════════════════════════════════════════════════════
//
// Bundles the small reusable widgets the OTP / login / signup screens
// need. Kept in one file because each is < 100 lines and they're
// always imported together.
//
// Exports:
//   • OtpResendCountdown    — "Resend in 28s" → "Resend OTP" button
//   • InlineFieldError      — red helper text + soft horizontal shake
//   • AuthSkeleton          — shimmering placeholder rows during async
//
// All read theme colours via `AppTokens.*` so they obey the existing
// light/dark switch.

import 'dart:async';
import 'package:flutter/material.dart';
import '../../helpers/app_tokens.dart';

// ────────────────────────────────────────────────────────────────────
// OtpResendCountdown
// ────────────────────────────────────────────────────────────────────

/// Apple-style "Resend in 28s … Resend OTP" affordance. Starts a
/// countdown immediately on mount; flips to a tappable "Resend OTP"
/// link once it hits zero.
class OtpResendCountdown extends StatefulWidget {
  /// Seconds to wait before allowing resend. Default 30 — same as
  /// Razorpay / PhonePe / Swiggy.
  final int seconds;
  final VoidCallback onResend;
  const OtpResendCountdown({
    super.key,
    this.seconds = 30,
    required this.onResend,
  });

  @override
  State<OtpResendCountdown> createState() => _OtpResendCountdownState();
}

class _OtpResendCountdownState extends State<OtpResendCountdown> {
  late int _left;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _t?.cancel();
    setState(() => _left = widget.seconds);
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_left <= 1) {
        t.cancel();
        setState(() => _left = 0);
      } else {
        setState(() => _left--);
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _left == 0;
    return GestureDetector(
      onTap: ready
          ? () {
              widget.onResend();
              _start();
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              ready ? "Didn't receive it?  " : "Resend in ",
              style: AppTokens.body(context),
            ),
            Text(
              ready ? 'Resend OTP' : '${_left}s',
              style: AppTokens.body(context).copyWith(
                color: ready
                    ? AppTokens.accent(context)
                    : AppTokens.muted(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// InlineFieldError — red helper + horizontal shake
// ────────────────────────────────────────────────────────────────────

/// Wrap a TextFormField (or any child) and pass a non-null `error`
/// to render the message below it AND trigger a tiny horizontal
/// shake on the child. Set `error` to null to clear.
class InlineFieldError extends StatefulWidget {
  final Widget child;
  final String? error;
  const InlineFieldError({super.key, required this.child, this.error});

  @override
  State<InlineFieldError> createState() => _InlineFieldErrorState();
}

class _InlineFieldErrorState extends State<InlineFieldError>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void didUpdateWidget(covariant InlineFieldError oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.error != widget.error
        && (widget.error ?? '').isNotEmpty) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            // 4 oscillations, decaying amplitude — feels like Apple's
            // "wrong password" wiggle.
            final t = _ctrl.value;
            final dx = (t == 0)
                ? 0.0
                : (1 - t) * 8 *
                    (t < .25 ? 1 : (t < .5 ? -1 : (t < .75 ? 1 : -1)));
            return Transform.translate(
              offset: Offset(dx, 0),
              child: child,
            );
          },
          child: widget.child,
        ),
        if ((widget.error ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 14, color: AppTokens.danger(context)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.error!,
                    style: AppTokens.caption(context).copyWith(
                      color: AppTokens.danger(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// AuthSkeleton — shimmer rows while async
// ────────────────────────────────────────────────────────────────────

/// Renders 3 shimmering placeholder bars sized to match an OTP cell
/// row. Used in place of a CircularProgressIndicator on the "verify"
/// button so the layout doesn't jump.
class AuthSkeleton extends StatefulWidget {
  final int rows;
  final double height;
  const AuthSkeleton({super.key, this.rows = 3, this.height = 18});

  @override
  State<AuthSkeleton> createState() => _AuthSkeletonState();
}

class _AuthSkeletonState extends State<AuthSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.rows, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = _ctrl.value;
              final base = AppTokens.surface3(context);
              return Container(
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: AppTokens.radius8,
                  gradient: LinearGradient(
                    colors: [
                      base,
                      AppTokens.border(context),
                      base,
                    ],
                    stops: [
                      (t - 0.3).clamp(0.0, 1.0),
                      t,
                      (t + 0.3).clamp(0.0, 1.0),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
