import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../helpers/app_tokens.dart';

/// CustomShowCaseWidget — thin wrapper around [Showcase] that the bottom-
/// nav tabs and a handful of first-run tips use to call out UI. Public
/// surface preserved exactly:
///   • const constructor `{super.key, required GlobalKey globalKey,
///     required String description, ShapeBorder? shapeBorder,
///     required Widget child}`
///
/// The surface-level polish here standardises the showcase palette
/// (ink text, surface background) so tips match the rest of the
/// AppTokens rhythm.
class CustomShowCaseWidget extends StatelessWidget {
  final GlobalKey globalKey;
  final ShapeBorder? shapeBorder;
  final String description;
  final Widget child;

  const CustomShowCaseWidget({
    super.key,
    required this.globalKey,
    required this.description,
    this.shapeBorder,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Showcase(
      key: globalKey,
      description: description,
      showArrow: false,
      textColor: AppTokens.ink(context),
      descTextStyle: AppTokens.body(context).copyWith(
        fontWeight: FontWeight.w600,
      ),
      tooltipBackgroundColor: AppTokens.surface(context),
      overlayColor: Colors.black,
      // ignore: deprecated_member_use
      overlayOpacity: 0.72,
      tooltipBorderRadius: BorderRadius.circular(AppTokens.r12),
      targetShapeBorder: shapeBorder ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
      targetPadding: const EdgeInsets.all(4),
      child: child,
    );
  }
}
