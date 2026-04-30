// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../widgets/custom_button.dart';

/// Completed live classes placeholder — redesigned with AppTokens. Preserves
/// the constructor, static route factory, and the CustomButton → Routes
/// .videoLectures navigation target so the "View Recorded Lectures" CTA still
/// works end-to-end.
class LiveClassesCompleted extends StatefulWidget {
  const LiveClassesCompleted({super.key});

  @override
  State<LiveClassesCompleted> createState() => _LiveClassesCompletedState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const LiveClassesCompleted(),
    );
  }
}

class _LiveClassesCompletedState extends State<LiveClassesCompleted> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTokens.s24),
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "assets/image/video_files.png",
                width: 140,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppTokens.s24),
            Text(
              "Missed a live session?",
              textAlign: TextAlign.center,
              style: AppTokens.titleMd(context),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              "Catch up anytime from the recorded lectures library.",
              textAlign: TextAlign.center,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink2(context),
              ),
            ),
            const SizedBox(height: AppTokens.s24),
            _GradientCta(
              label: "View Recorded Lectures",
              icon: Icons.play_circle_fill_rounded,
              onTap: () =>
                  Navigator.of(context).pushNamed(Routes.videoLectures),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//                        Primitives
// ============================================================

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: AppTokens.radius12,
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppTokens.radius12,
            boxShadow: [
              BoxShadow(
                color: AppTokens.brand.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s24,
              vertical: AppTokens.s16,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: AppTokens.s8),
                Text(
                  label,
                  style: AppTokens.titleSm(context).copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
