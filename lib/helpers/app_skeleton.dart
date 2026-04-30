import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// AppSkeleton — minimal shimmer placeholder.
///
/// Replaces `CircularProgressIndicator` for surfaces where we know
/// the layout shape ahead of time. The animated highlight sweeps
/// every 1.6s — softer than `shimmer` package's 1s default.
///
/// Use [SkeletonLine] for one-line placeholder (e.g. titles), [SkeletonBlock]
/// for arbitrary shapes (cards, avatars), or [SkeletonList] for a stack
/// of N rows.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    Key? key,
    required this.child,
    this.borderRadius,
  }) : super(key: key);

  /// Wraps any widget with a shimmer overlay.
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppTokens.surface2(context);
    final highlight = AppTokens.surface3(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) {
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _ctrl.value * 2, 0),
              end: Alignment(1.0 + _ctrl.value * 2, 0),
            ).createShader(rect);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Single-line bone — height + width controllable.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    Key? key,
    this.height = 14,
    this.width,
    this.radius = 6,
  }) : super(key: key);

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Rectangular block — useful for thumbnails, avatars, charts.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    Key? key,
    this.height,
    this.width,
    this.radius = 12,
    this.shape = BoxShape.rectangle,
  }) : super(key: key);

  final double? height;
  final double? width;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.black,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(radius)
              : null,
        ),
      ),
    );
  }
}

/// Stack of [count] card-shaped placeholders, used as a list-loading state.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    Key? key,
    this.count = 5,
    this.itemHeight = 76,
    this.spacing = 12,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppTokens.s24,
      vertical: AppTokens.s16,
    ),
  }) : super(key: key);

  final int count;
  final double itemHeight;
  final double spacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: count,
      separatorBuilder: (_, __) => SizedBox(height: spacing),
      itemBuilder: (_, __) => Container(
        height: itemHeight,
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          borderRadius: AppTokens.radius16,
          border: Border.all(
            color: AppTokens.border(context),
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(AppTokens.s12),
        child: Row(
          children: [
            const SkeletonBlock(width: 44, height: 44, shape: BoxShape.circle),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SkeletonLine(width: 180, height: 12),
                  SizedBox(height: 8),
                  SkeletonLine(width: 120, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
