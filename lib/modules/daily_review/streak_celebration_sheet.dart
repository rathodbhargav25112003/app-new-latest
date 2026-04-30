import 'dart:math';

import 'package:flutter/material.dart';

import '../../helpers/app_tokens.dart';
import '../../helpers/haptics.dart';
import '../../helpers/share_helpers.dart';

/// StreakCelebrationSheet — modal that fires when the user crosses a
/// streak milestone (3, 7, 14, 30, 60, 100, 200, 365).
///
/// Pure-Flutter confetti animation — no external package needed.
/// Tied to streak counter from [DailyReviewService].
///
/// Usage from the daily-review session screen:
///
/// ```dart
/// final r = await DailyReviewService.instance.recordSessionCompleted();
/// if (r.hitMilestone) {
///   await StreakCelebrationSheet.show(context, streak: r.streak);
/// }
/// ```
class StreakCelebrationSheet {
  StreakCelebrationSheet._();

  static Future<void> show(BuildContext context, {required int streak}) {
    Haptics.heavy();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (_) => _CelebrationContent(streak: streak),
    );
  }
}

class _CelebrationContent extends StatefulWidget {
  const _CelebrationContent({required this.streak});
  final int streak;

  @override
  State<_CelebrationContent> createState() => _CelebrationContentState();
}

class _CelebrationContentState extends State<_CelebrationContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();
    _particles = List.generate(60, (_) => _Particle.random());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.streak) {
      case 3:
        return '3-day streak!';
      case 7:
        return '1-week streak!';
      case 14:
        return '2-week streak!';
      case 30:
        return '30 days strong!';
      case 60:
        return '60 days!';
      case 100:
        return '100 days!';
      case 200:
        return '200 days!';
      case 365:
        return 'A full year!';
      default:
        return '${widget.streak}-day streak!';
    }
  }

  String get _subtitle {
    if (widget.streak < 7) {
      return "You're building the habit. Keep showing up.";
    } else if (widget.streak < 30) {
      return "Consistency is your edge. Don't break the chain.";
    } else if (widget.streak < 100) {
      return "Most aspirants quit by now. You're already in the top 5%.";
    } else {
      return "You're playing on a different level. Almost no one makes it here.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti layer — sits behind the sheet card.
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _ctrl.value,
            ),
          ),
        ),

        // Sheet card.
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTokens.r28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTokens.s24, AppTokens.s12, AppTokens.s24, AppTokens.s24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTokens.border(context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s24),
                    Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFB347), Color(0xFFFF7A00)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF7A00).withOpacity(0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: AppTokens.s20),
                    Text(_title,
                        style: AppTokens.displayMd(context),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppTokens.s8),
                    Text(
                      _subtitle,
                      textAlign: TextAlign.center,
                      style: AppTokens.body(context),
                    ),
                    const SizedBox(height: AppTokens.s24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ShareHelpers.shareStreak(context,
                                  streak: widget.streak);
                            },
                            icon: Icon(Icons.ios_share_rounded,
                                size: 16, color: AppTokens.accent(context)),
                            label: Text(
                              'Share',
                              style: AppTokens.titleSm(context).copyWith(
                                color: AppTokens.accent(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                  color: AppTokens.accent(context),
                                  width: 0.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppTokens.radius16),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTokens.accent(context),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppTokens.radius16),
                            ),
                            child: Text(
                              "Keep going",
                              style: AppTokens.titleSm(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Particle {
  _Particle({
    required this.start,
    required this.end,
    required this.color,
    required this.size,
    required this.rotation,
  });

  factory _Particle.random() {
    final r = Random();
    final w = r.nextDouble();
    return _Particle(
      start: Offset(w, -0.05),
      end: Offset(w + (r.nextDouble() - 0.5) * 0.4, 1.1),
      color: _palette[r.nextInt(_palette.length)],
      size: 6.0 + r.nextDouble() * 8,
      rotation: r.nextDouble() * 2 * pi,
    );
  }

  final Offset start;
  final Offset end;
  final Color color;
  final double size;
  final double rotation;

  static const _palette = [
    Color(0xFFFFB347), // amber
    Color(0xFFFF7A00), // orange
    Color(0xFF1E88E5), // blue
    Color(0xFF33AD48), // green
    Color(0xFFE23B3B), // red
    Color(0xFF8E44AD), // purple
  ];
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});
  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Animate position from start → end over progress with a slight
      // sine wobble for natural fall.
      final dx = lerpDouble(p.start.dx, p.end.dx, progress)! * size.width +
          sin(progress * 2 * pi + p.rotation) * 12;
      final dy = lerpDouble(p.start.dy, p.end.dy, progress)! * size.height;

      final paint = Paint()
        ..color = p.color.withOpacity(1.0 - (progress * 0.4));

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotation + progress * 4 * pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

double? lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0;
  b ??= 0.0;
  return a.toDouble() * (1.0 - t) + b.toDouble() * t;
}
