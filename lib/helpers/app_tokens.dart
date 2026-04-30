import 'package:flutter/material.dart';
import 'colors.dart';

/// AppTokens — upgraded design-system tokens that live alongside [AppColors]
/// and [AppColorsDark]. They DO NOT replace the legacy color system: existing
/// screens continue to read from `AppColors.xxx` / `ThemeManager.xxx`. As
/// screens are upgraded one-by-one, they switch over to `AppTokens.xxx`.
///
/// This avoids a big-bang migration. A screen only moves once it's been
/// manually touched and verified.
///
/// Usage:
///   Container(color: AppTokens.surface(context))
///   Text(..., style: AppTokens.titleLg(context))
///
/// All functions take `BuildContext` so they respond to theme changes
/// emitted by the existing [ThemeNotifier].
class AppTokens {
  AppTokens._();

  static bool _isDark(BuildContext ctx) =>
      ThemeManager.currentTheme == AppTheme.Dark;

  // ------------------------------------------------------------------
  // Brand colours — unchanged anchors
  // ------------------------------------------------------------------
  static const Color brand = Color(0xFF0048D0); // primary
  static const Color brand2 = Color(0xFF497BDC); // secondary blue

  // ------------------------------------------------------------------
  // Semantic colours
  // ------------------------------------------------------------------
  static Color accent(BuildContext ctx) =>
      _isDark(ctx) ? const Color(0xFF6FA4FF) : brand;
  static Color accentSoft(BuildContext ctx) => _isDark(ctx)
      ? const Color(0xFF0D1B3D)
      : const Color(0xFFE6EEFF);

  static Color success(BuildContext ctx) =>
      _isDark(ctx) ? const Color(0xFF5FD476) : const Color(0xFF33AD48);
  static Color successSoft(BuildContext ctx) => _isDark(ctx)
      ? const Color(0xFF0F2E17)
      : const Color(0xFFE8F7EB);

  static Color warning(BuildContext ctx) =>
      _isDark(ctx) ? const Color(0xFFF4B954) : const Color(0xFFE89B20);
  static Color warningSoft(BuildContext ctx) => _isDark(ctx)
      ? const Color(0xFF33260A)
      : const Color(0xFFFDF3E0);

  static Color danger(BuildContext ctx) =>
      _isDark(ctx) ? const Color(0xFFFF6E6E) : const Color(0xFFE23B3B);
  static Color dangerSoft(BuildContext ctx) => _isDark(ctx)
      ? const Color(0xFF36141B)
      : const Color(0xFFFDECEC);

  // ------------------------------------------------------------------
  // Surfaces (three tiers)
  // ------------------------------------------------------------------
  /// Main background / cards.
  static Color surface(BuildContext ctx) =>
      _isDark(ctx) ? const Color(0xFF12141A) : const Color(0xFFFFFFFF);

  /// Secondary surface — subtle elevations, chip backgrounds.
  static Color surface2(BuildContext ctx) =>
      _isDark(ctx) ? const Color(0xFF1A1D25) : const Color(0xFFF6F7FA);

  /// Tertiary surface — filled fields, dividers that need a touch more depth.
  static Color surface3(BuildContext ctx) =>
      _isDark(ctx) ? const Color(0xFF24283A) : const Color(0xFFEDEFF4);

  /// Scaffold background — the outermost colour.
  static Color scaffold(BuildContext ctx) =>
      _isDark(ctx) ? const Color(0xFF0B0C10) : const Color(0xFFF8F9FC);

  // ------------------------------------------------------------------
  // Borders & hairlines
  // ------------------------------------------------------------------
  static Color border(BuildContext ctx) =>
      _isDark(ctx) ? const Color(0xFF1F232D) : const Color(0xFFE6E8EE);
  static Color borderStrong(BuildContext ctx) =>
      _isDark(ctx) ? const Color(0xFF2F3444) : const Color(0xFFD2D6E0);

  // ------------------------------------------------------------------
  // Ink (text)
  // ------------------------------------------------------------------
  static Color ink(BuildContext ctx) =>
      _isDark(ctx) ? const Color(0xFFF5F6FA) : const Color(0xFF0A0D14);
  static Color ink2(BuildContext ctx) =>
      _isDark(ctx) ? const Color(0xFFB9BDCC) : const Color(0xFF3C4257);
  static Color muted(BuildContext ctx) =>
      _isDark(ctx) ? const Color(0xFF757A90) : const Color(0xFF7D8398);

  // ------------------------------------------------------------------
  // Radii
  // ------------------------------------------------------------------
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r28 = 28;

  static const BorderRadius radius8 = BorderRadius.all(Radius.circular(r8));
  static const BorderRadius radius12 = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius radius16 = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius radius20 = BorderRadius.all(Radius.circular(r20));
  static const BorderRadius radius28 = BorderRadius.all(Radius.circular(r28));

  // ------------------------------------------------------------------
  // Spacing scale
  // ------------------------------------------------------------------
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  // ------------------------------------------------------------------
  // Shadows — three tiers
  // ------------------------------------------------------------------
  static List<BoxShadow> shadow1(BuildContext ctx) {
    final base = _isDark(ctx) ? 0.55 : 0.05;
    return [
      BoxShadow(
        color: Colors.black.withOpacity(base),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> shadow2(BuildContext ctx) {
    final a = _isDark(ctx) ? 0.6 : 0.07;
    final b = _isDark(ctx) ? 0.35 : 0.04;
    return [
      BoxShadow(
        color: Colors.black.withOpacity(a),
        blurRadius: 28,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(b),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> shadow3(BuildContext ctx) {
    final a = _isDark(ctx) ? 0.7 : 0.12;
    final b = _isDark(ctx) ? 0.45 : 0.06;
    return [
      BoxShadow(
        color: Colors.black.withOpacity(a),
        blurRadius: 60,
        offset: const Offset(0, 24),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(b),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // ------------------------------------------------------------------
  // Typography
  // ------------------------------------------------------------------
  static const String _fontFamily = 'Jost';
  static const List<String> _fallback = ['DM Sans'];

  static TextStyle _base(
    BuildContext ctx, {
    required double size,
    required FontWeight weight,
    double letter = 0,
    double height = 1.3,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fallback,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letter,
        height: height,
        color: color ?? ink(ctx),
      );

  static TextStyle displayLg(BuildContext ctx) => _base(
        ctx,
        size: 34,
        weight: FontWeight.w800,
        letter: -0.5,
        height: 1.15,
      );
  static TextStyle displayMd(BuildContext ctx) => _base(
        ctx,
        size: 28,
        weight: FontWeight.w700,
        letter: -0.4,
        height: 1.18,
      );
  static TextStyle titleLg(BuildContext ctx) => _base(
        ctx,
        size: 22,
        weight: FontWeight.w700,
        letter: -0.3,
      );
  static TextStyle titleMd(BuildContext ctx) => _base(
        ctx,
        size: 18,
        weight: FontWeight.w700,
        letter: -0.2,
      );
  static TextStyle titleSm(BuildContext ctx) => _base(
        ctx,
        size: 15,
        weight: FontWeight.w600,
        letter: -0.1,
      );
  static TextStyle bodyLg(BuildContext ctx) => _base(
        ctx,
        size: 16,
        weight: FontWeight.w500,
        height: 1.45,
      );
  static TextStyle body(BuildContext ctx) => _base(
        ctx,
        size: 14,
        weight: FontWeight.w500,
        height: 1.45,
        color: ink2(ctx),
      );
  static TextStyle caption(BuildContext ctx) => _base(
        ctx,
        size: 12,
        weight: FontWeight.w500,
        height: 1.4,
        color: muted(ctx),
      );
  static TextStyle overline(BuildContext ctx) => _base(
        ctx,
        size: 11,
        weight: FontWeight.w700,
        letter: 0.8,
        height: 1.3,
        color: muted(ctx),
      ).copyWith(fontFeatures: const [FontFeature.enable('ss01')]);

  /// Mono / tabular numerals — for timers, prices, counters.
  static TextStyle numeric(BuildContext ctx, {double size = 16}) =>
      _base(ctx, size: size, weight: FontWeight.w700).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ------------------------------------------------------------------
  // Common decorations
  // ------------------------------------------------------------------
  static BoxDecoration cardDecoration(BuildContext ctx) => BoxDecoration(
        color: surface(ctx),
        borderRadius: radius16,
        border: Border.all(color: border(ctx), width: 1),
        boxShadow: shadow1(ctx),
      );

  static BoxDecoration softCard(BuildContext ctx) => BoxDecoration(
        color: surface2(ctx),
        borderRadius: radius12,
        border: Border.all(color: border(ctx), width: 1),
      );

  static BoxDecoration accentCard(BuildContext ctx) => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brand, brand2],
        ),
        borderRadius: radius16,
        boxShadow: shadow2(ctx),
      );

  /// Input decoration matching the upgrade spec — used by new fields.
  /// Kept as a method so callers can pass a [hint].
  static InputDecoration inputDecoration(
    BuildContext ctx, {
    String? hint,
    Widget? prefix,
    Widget? suffix,
    String? label,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: body(ctx).copyWith(color: muted(ctx)),
        labelText: label,
        labelStyle: overline(ctx),
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: surface(ctx),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: border(ctx), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: accent(ctx), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: danger(ctx), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: danger(ctx), width: 2),
        ),
      );
}
