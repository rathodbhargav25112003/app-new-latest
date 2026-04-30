import 'dart:io';
import 'package:flutter/material.dart';

import '../../helpers/app_tokens.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
// ignore: unused_import
import 'package:flutter_svg/svg.dart';
// ignore: unused_import
import 'package:shusruta_lms/helpers/colors.dart';
// ignore: unused_import
import 'package:shusruta_lms/modules/videolectures/store/video_category_store.dart';
// ignore: unused_import
import '../../app/routes.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import
import 'custom_button.dart';

/// CustomSuccessfulBottomSheet — generic success bottom sheet used by the
/// mobile-change flow. Public surface preserved exactly:
///   • const constructor `(BuildContext context, {super.key})`
///   • "Okay" CTA is a no-op (the original body was commented out)
class CustomSuccessfulBottomSheet extends StatefulWidget {
  const CustomSuccessfulBottomSheet(BuildContext context, {super.key});

  @override
  State<CustomSuccessfulBottomSheet> createState() =>
      _CustomSuccessfulBottomSheetState();
}

class _CustomSuccessfulBottomSheetState
    extends State<CustomSuccessfulBottomSheet> {
  @override
  void initState() {
    super.initState();
  }

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: _isDesktop
          ? const BoxConstraints(maxWidth: 480)
          : null,
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: _isDesktop
            ? BorderRadius.circular(AppTokens.r20)
            : const BorderRadius.vertical(
                top: Radius.circular(AppTokens.r20),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s16,
          AppTokens.s20,
          AppTokens.s20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isDesktop)
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppTokens.s16),
                  decoration: BoxDecoration(
                    color: AppTokens.border(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTokens.successSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r20),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppTokens.success(context),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'Mobile number\nupdated successfully',
              textAlign: TextAlign.center,
              style: AppTokens.titleLg(context)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              'Your contact details have been saved.',
              textAlign: TextAlign.center,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink2(context),
              ),
            ),
            const SizedBox(height: AppTokens.s20),
            _GradientCta(
              label: 'Okay',
              icon: Icons.check_rounded,
              onTap: () {
                // Preserved: original button was a no-op.
              },
            ),
          ],
        ),
      ),
    );
  }
}

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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: AppTokens.brand.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: AppTokens.s8),
              Text(
                label,
                style: AppTokens.body(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
