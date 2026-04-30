import 'package:flutter/material.dart';
import '../../helpers/app_tokens.dart';

/// AppEmptyState — single shared widget for empty / no-data surfaces.
///
/// Replaces the blank-white-screen pattern in the legacy UI (lists that
/// quietly render nothing when empty, leaving the user wondering if it's
/// broken). Use wherever a list, search result, or filtered view can be
/// empty.
///
/// Three flavours:
///  * Default — icon bubble + title + subtitle + optional CTA
///  * [AppEmptyState.error] — same layout, danger-tinted icon, "Retry" CTA
///  * [AppEmptyState.search] — search-themed illustration for empty queries
///
/// Example:
///   AppEmptyState(
///     icon: Icons.bookmark_outline,
///     title: 'No bookmarks yet',
///     subtitle: 'Tap the bookmark icon on any question to save it here.',
///     ctaLabel: 'Browse questions',
///     onCta: () => Navigator.pushNamed(context, Routes.questionBank),
///   )
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
    this.iconColor,
    this.iconBgColor,
    this.compact = false,
  });

  /// Error variant — danger-tinted icon, optional retry button.
  factory AppEmptyState.error({
    Key? key,
    String title = "Something went wrong",
    String? subtitle = "Check your connection and try again.",
    String ctaLabel = "Retry",
    VoidCallback? onCta,
    IconData icon = Icons.wifi_off_rounded,
    bool compact = false,
  }) =>
      _ErrorEmptyState(
        key: key,
        icon: icon,
        title: title,
        subtitle: subtitle,
        ctaLabel: ctaLabel,
        onCta: onCta,
        compact: compact,
      );

  /// Search-no-results variant.
  factory AppEmptyState.search({
    Key? key,
    String title = "No results",
    String? subtitle = "Try different keywords or clear filters.",
    String? ctaLabel,
    VoidCallback? onCta,
    bool compact = false,
  }) =>
      AppEmptyState(
        key: key,
        icon: Icons.search_off_rounded,
        title: title,
        subtitle: subtitle,
        ctaLabel: ctaLabel,
        onCta: onCta,
        compact: compact,
      );

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final Color? iconColor;
  final Color? iconBgColor;

  /// When true, uses smaller icon+paddings. Good for inline empty
  /// surfaces (inside a card) rather than full-screen states.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 28.0 : 40.0;
    final bubbleSize = compact ? 64.0 : 96.0;
    final vSpace = compact ? 12.0 : 18.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTokens.s24,
          vertical: compact ? AppTokens.s16 : AppTokens.s32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: bubbleSize,
              height: bubbleSize,
              decoration: BoxDecoration(
                color: iconBgColor ?? AppTokens.accentSoft(context),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? AppTokens.accent(context),
              ),
            ),
            SizedBox(height: vSpace),
            Text(
              title,
              textAlign: TextAlign.center,
              style: compact
                  ? AppTokens.titleSm(context)
                  : AppTokens.titleMd(context),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTokens.body(context),
              ),
            ],
            if (ctaLabel != null && onCta != null) ...[
              SizedBox(height: vSpace),
              _EmptyStateButton(label: ctaLabel!, onPressed: onCta!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Internal: danger-tinted empty state for the error factory.
class _ErrorEmptyState extends AppEmptyState {
  const _ErrorEmptyState({
    super.key,
    required super.icon,
    required super.title,
    super.subtitle,
    super.ctaLabel,
    super.onCta,
    super.compact,
  });

  @override
  Widget build(BuildContext context) {
    // Recreate the AppEmptyState UI with danger tints by delegating to a
    // fresh AppEmptyState carrying the custom colours.
    return AppEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      ctaLabel: ctaLabel,
      onCta: onCta,
      compact: compact,
      iconBgColor: AppTokens.dangerSoft(context),
      iconColor: AppTokens.danger(context),
    );
  }
}

/// Internal: compact CTA button used inside empty states.
/// We avoid depending on the legacy CustomButton so AppEmptyState stays a
/// leaf widget and can be used in any module.
class _EmptyStateButton extends StatelessWidget {
  const _EmptyStateButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.accent(context),
      borderRadius: AppTokens.radius12,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppTokens.radius12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            label,
            style: AppTokens.titleSm(context).copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
