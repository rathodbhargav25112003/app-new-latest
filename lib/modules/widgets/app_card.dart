import 'package:flutter/material.dart';
import '../../helpers/app_tokens.dart';

/// AppCard — single shared card wrapper that reads from [AppTokens].
///
/// Replaces ad-hoc `Container(decoration: BoxDecoration(...))` chunks
/// scattered across the app. Use [AppCard] for the default elevation-1 card
/// (surface + border + soft shadow). Use [AppCard.soft] for a flat secondary
/// surface (no shadow). Use [AppCard.accent] for the brand-gradient hero
/// card. Use [AppCard.flat] when you want just a border and rounded corners
/// (no shadow, no fill).
///
/// A screen that opts into [AppCard] automatically tracks light/dark theme
/// changes through [AppTokens] — no local `isDark` branches needed.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.borderRadius,
    this.height,
    this.width,
    this.variant = _CardVariant.elevated,
  });

  /// Flat secondary surface card — for chip backgrounds, inline tiles.
  const AppCard.soft({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.onTap,
    this.borderRadius,
    this.height,
    this.width,
  }) : variant = _CardVariant.soft;

  /// Brand gradient hero card — for primary CTA blocks.
  const AppCard.accent({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.onTap,
    this.borderRadius,
    this.height,
    this.width,
  }) : variant = _CardVariant.accent;

  /// Border-only card — no shadow, no fill. For dividers / grouped sections.
  const AppCard.flat({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.onTap,
    this.borderRadius,
    this.height,
    this.width,
  }) : variant = _CardVariant.flat;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double? height;
  final double? width;
  final _CardVariant variant;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? _defaultRadius;
    final decoration = _buildDecoration(context, radius);

    final content = Container(
      height: height,
      width: width,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap == null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: content,
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      ),
    );
  }

  BorderRadius get _defaultRadius {
    switch (variant) {
      case _CardVariant.elevated:
      case _CardVariant.accent:
        return AppTokens.radius16;
      case _CardVariant.soft:
      case _CardVariant.flat:
        return AppTokens.radius12;
    }
  }

  BoxDecoration _buildDecoration(BuildContext context, BorderRadius radius) {
    switch (variant) {
      case _CardVariant.elevated:
        return BoxDecoration(
          color: AppTokens.surface(context),
          borderRadius: radius,
          border: Border.all(color: AppTokens.border(context), width: 1),
          boxShadow: AppTokens.shadow1(context),
        );
      case _CardVariant.soft:
        return BoxDecoration(
          color: AppTokens.surface2(context),
          borderRadius: radius,
          border: Border.all(color: AppTokens.border(context), width: 1),
        );
      case _CardVariant.accent:
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTokens.brand, AppTokens.brand2],
          ),
          borderRadius: radius,
          boxShadow: AppTokens.shadow2(context),
        );
      case _CardVariant.flat:
        return BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppTokens.border(context), width: 1),
        );
    }
  }
}

enum _CardVariant { elevated, soft, accent, flat }
