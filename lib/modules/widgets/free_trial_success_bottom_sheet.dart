import 'dart:io';
import 'package:flutter/material.dart';

import '../../helpers/app_tokens.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import 'custom_button.dart';

/// FreeTrialSuccessBottomSheet — celebration sheet shown after a user opts
/// into the free trial. Public surface preserved exactly:
///   • const constructor `{super.key, required String expirationDate}`
///   • "Got it" CTA pops the sheet
class FreeTrialSuccessBottomSheet extends StatelessWidget {
  final String expirationDate;

  const FreeTrialSuccessBottomSheet({
    super.key,
    required this.expirationDate,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Platform.isWindows || Platform.isMacOS;
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: isDesktop ? const BoxConstraints(maxWidth: 520) : null,
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: isDesktop
            ? BorderRadius.circular(AppTokens.r28)
            : const BorderRadius.vertical(
                top: Radius.circular(AppTokens.r28),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s24,
          AppTokens.s16,
          AppTokens.s24,
          AppTokens.s20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isDesktop)
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
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTokens.successSoft(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppTokens.success(context),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'Free Trial Activated!',
              style: AppTokens.titleLg(context)
                  .copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s4),
            Text(
              'You can now access all premium features',
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink2(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s20),
            Container(
              padding: const EdgeInsets.all(AppTokens.s16),
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                borderRadius: BorderRadius.circular(AppTokens.r16),
                border: Border.all(
                  // ignore: deprecated_member_use
                  color: AppTokens.accent(context).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available_rounded,
                          color: AppTokens.accent(context), size: 18),
                      const SizedBox(width: AppTokens.s8),
                      Text(
                        'Your free trial expires on',
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.ink2(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s4),
                  Text(
                    expirationDate,
                    style: AppTokens.titleMd(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTokens.accent(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s20),
            _GradientCta(
              label: 'Got it',
              icon: Icons.rocket_launch_rounded,
              onTap: () => Navigator.of(context).pop(),
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
