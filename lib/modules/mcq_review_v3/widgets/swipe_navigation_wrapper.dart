// SwipeNavigationWrapper — wraps the per-question page body with swipe
// gesture detection for prev/next navigation. Detects horizontal drags
// past a threshold and fires the callback. Combines with the existing
// Previous/Next buttons — this is purely additive UX.
//
// Also handles the auto-advance from ReadingPrefs: when answer is
// revealed and auto-advance is enabled, fires onNext after the
// configured delay. Cancellable by tapping or starting another swipe.

import 'dart:async';

import 'package:flutter/material.dart';

import '../reading_prefs.dart';

class SwipeNavigationWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  /// True when the answer is revealed — used by auto-advance timer
  final bool answerRevealed;
  /// Set false on first / last question
  final bool canGoPrevious;
  final bool canGoNext;

  const SwipeNavigationWrapper({
    super.key,
    required this.child,
    required this.onPrevious,
    required this.onNext,
    required this.answerRevealed,
    this.canGoPrevious = true,
    this.canGoNext = true,
  });

  @override
  State<SwipeNavigationWrapper> createState() => _SwipeNavigationWrapperState();
}

class _SwipeNavigationWrapperState extends State<SwipeNavigationWrapper> {
  Timer? _autoAdvanceTimer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    ReadingPrefs.I.addListener(_evaluate);
    _evaluate();
  }

  @override
  void didUpdateWidget(covariant SwipeNavigationWrapper old) {
    super.didUpdateWidget(old);
    if (old.answerRevealed != widget.answerRevealed) _evaluate();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    ReadingPrefs.I.removeListener(_evaluate);
    super.dispose();
  }

  void _evaluate() {
    _autoAdvanceTimer?.cancel();
    if (!widget.answerRevealed) {
      setState(() => _remaining = null);
      return;
    }
    if (!ReadingPrefs.I.autoAdvance) {
      setState(() => _remaining = null);
      return;
    }
    if (!widget.canGoNext) return;
    final secs = ReadingPrefs.I.autoAdvanceSeconds;
    setState(() => _remaining = Duration(seconds: secs));
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final r = (_remaining ?? Duration.zero) - const Duration(seconds: 1);
      if (r.inSeconds <= 0) {
        t.cancel();
        widget.onNext();
      } else {
        setState(() => _remaining = r);
      }
    });
  }

  void _cancelAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    setState(() => _remaining = null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            _cancelAutoAdvance();
            final v = details.primaryVelocity ?? 0;
            if (v < -300 && widget.canGoNext) widget.onNext();
            else if (v > 300 && widget.canGoPrevious) widget.onPrevious();
          },
          onTap: _cancelAutoAdvance,
          child: widget.child,
        ),
        // Auto-advance progress strip at the bottom
        if (_remaining != null)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _AutoAdvanceBar(
              remaining: _remaining!,
              total: Duration(seconds: ReadingPrefs.I.autoAdvanceSeconds),
              onCancel: _cancelAutoAdvance,
            ),
          ),
      ],
    );
  }
}

class _AutoAdvanceBar extends StatelessWidget {
  final Duration remaining;
  final Duration total;
  final VoidCallback onCancel;
  const _AutoAdvanceBar({required this.remaining, required this.total, required this.onCancel});
  @override
  Widget build(BuildContext context) {
    final pct = total.inSeconds == 0 ? 0.0 : remaining.inSeconds / total.inSeconds;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onCancel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: scheme.primary.withOpacity(0.95),
        child: Row(children: [
          const Icon(Icons.timer, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            'Auto-advance in ${remaining.inSeconds}s · tap to cancel',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                minHeight: 4,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
