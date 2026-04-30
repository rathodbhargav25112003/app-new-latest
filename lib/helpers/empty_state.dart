import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// EmptyState — single home for "nothing here" surfaces.
///
/// Replaces the dozen ad-hoc `Center(child: Text('No data'))` snippets
/// scattered across the app. The default icon goes in a 64-px tinted
/// circle; title is `titleMd`; subtitle is `body`.
///
/// Optionally pass an [action] to render a CTA button.
///
/// Usage:
/// ```dart
/// const EmptyState(
///   icon: Icons.bookmark_outline_rounded,
///   title: 'No bookmarks yet',
///   subtitle: 'Tap the bookmark icon on any question to save it here.',
/// )
/// ```
class EmptyState extends StatelessWidget {
  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.iconColor,
    this.iconBackgroundColor,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? AppTokens.surface2(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: iconColor ?? AppTokens.muted(context),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTokens.titleMd(context),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTokens.body(context),
            ),
            if (action != null) ...[
              const SizedBox(height: AppTokens.s16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
