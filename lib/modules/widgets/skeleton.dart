import 'package:flutter/material.dart';

import '../../helpers/app_tokens.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import '../../helpers/colors.dart';

/// Lightweight shimmer skeleton. No external package dependency — uses a
/// ShaderMask + AnimationController to sweep a linear gradient across a
/// placeholder shape.
///
/// Usage:
///   Skeleton(width: 120, height: 16)                   // text line
///   Skeleton.circle(size: 48)                          // avatar
///   Skeleton(width: double.infinity, height: 140,      // banner
///            borderRadius: 12)
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final BoxShape shape;

  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 6,
    this.margin,
    this.shape = BoxShape.rectangle,
  });

  factory Skeleton.circle({
    Key? key,
    double size = 48,
    EdgeInsetsGeometry? margin,
  }) =>
      Skeleton(
        key: key,
        width: size,
        height: size,
        shape: BoxShape.circle,
        margin: margin,
      );

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppTokens.surface2(context);
    final highlight = AppTokens.surface3(context);

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: base,
        shape: widget.shape,
        borderRadius: widget.shape == BoxShape.rectangle
            ? BorderRadius.circular(widget.borderRadius)
            : null,
      ),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return ClipRRect(
            borderRadius: widget.shape == BoxShape.rectangle
                ? BorderRadius.circular(widget.borderRadius)
                : BorderRadius.circular(999),
            child: ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                final dx = _ctrl.value * 2 - 1; // -1..1
                return LinearGradient(
                  begin: Alignment(dx - 0.3, 0),
                  end: Alignment(dx + 0.3, 0),
                  colors: [base, highlight, base],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds);
              },
              child: Container(color: base),
            ),
          );
        },
      ),
    );
  }
}

/// A tile-style skeleton: thumbnail square + two text lines. Drop-in
/// replacement for a loading row in any list.
class SkeletonListTile extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final double thumbnailSize;

  const SkeletonListTile({
    super.key,
    this.padding,
    this.thumbnailSize = 56,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            vertical: AppTokens.s8,
            horizontal: AppTokens.s12,
          ),
      child: Row(
        children: [
          Skeleton(
            width: thumbnailSize,
            height: thumbnailSize,
            borderRadius: AppTokens.r12,
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(width: double.infinity, height: 14),
                const SizedBox(height: AppTokens.s8),
                Skeleton(width: width * 0.4, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal row of card skeletons (e.g. "Featured Videos" carousel).
class SkeletonCardRow extends StatelessWidget {
  final int count;
  final double height;
  final double width;
  const SkeletonCardRow({
    super.key,
    this.count = 4,
    this.height = 160,
    this.width = 240,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s12),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.s12),
        itemBuilder: (_, __) => Skeleton(
          width: width,
          height: height,
          borderRadius: AppTokens.r16,
        ),
      ),
    );
  }
}

/// Vertical list of [SkeletonListTile]s.
class SkeletonTileList extends StatelessWidget {
  final int count;
  const SkeletonTileList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const SkeletonListTile()),
    );
  }
}
