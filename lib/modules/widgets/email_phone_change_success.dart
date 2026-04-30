import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../helpers/app_tokens.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import 'package:shusruta_lms/helpers/colors.dart';
// ignore: unused_import
import 'package:shusruta_lms/helpers/dimensions.dart';
// ignore: unused_import
import 'custom_button.dart';

/// PhoneEmailChangeSuccessScreen — success page shown after verifying a new
/// phone or email. Public surface preserved exactly:
///   • const constructor `{super.key, required String text}`
///   • "Ok" CTA triggers `HomeStore.onGetUserDetailsCall(context)` then
///     `Navigator.pop(context)`
class PhoneEmailChangeSuccessScreen extends StatelessWidget {
  const PhoneEmailChangeSuccessScreen({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppTokens.successSoft(context),
                      borderRadius: BorderRadius.circular(AppTokens.r28),
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppTokens.success(context),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: AppTokens.s24),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: AppTokens.displayMd(context)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppTokens.s8),
                  Text(
                    'You can use the new contact for sign-in from now on.',
                    textAlign: TextAlign.center,
                    style: AppTokens.body(context).copyWith(
                      color: AppTokens.ink2(context),
                    ),
                  ),
                  const SizedBox(height: AppTokens.s32),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: _GradientCta(
                      label: 'Ok',
                      icon: Icons.arrow_forward_rounded,
                      onTap: () {
                        final homeStore =
                            Provider.of<HomeStore>(context, listen: false);
                        homeStore.onGetUserDetailsCall(context);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
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
              Text(
                label,
                style: AppTokens.body(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Icon(icon, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
