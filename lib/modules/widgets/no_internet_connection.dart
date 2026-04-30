import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import '../../helpers/styles.dart';

/// NoInternetScreen — full-screen fallback shown when the device is
/// offline. Public surface preserved exactly:
///   • const constructor `{super.key}`
///   • Wraps the shared [NoInternetWidget] inside a [Scaffold]
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: const SafeArea(child: NoInternetWidget()),
    );
  }
}

/// NoInternetWidget — offline-state illustration + CTA used both inside
/// [NoInternetScreen] and inline elsewhere. Public surface preserved:
///   • const constructor `{super.key}`
///   • CTA pushes [Routes.downloadedNotesCategory]
class NoInternetWidget extends StatelessWidget {
  const NoInternetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.s20),
                decoration: BoxDecoration(
                  color: AppTokens.warningSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r28),
                ),
                child: SvgPicture.asset(
                  'assets/image/no_internet_connection.svg',
                  width: 160,
                  height: 160,
                ),
              ),
              const SizedBox(height: AppTokens.s24),
              Text(
                "Oops! You're offline",
                textAlign: TextAlign.center,
                style: AppTokens.displayMd(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: AppTokens.body(context).copyWith(
                  color: AppTokens.ink2(context),
                ),
              ),
              const SizedBox(height: AppTokens.s32),
              SizedBox(
                width: double.infinity,
                child: _GradientCta(
                  label: 'Go to Offline notes',
                  icon: Icons.offline_bolt_rounded,
                  onTap: () => Navigator.of(context)
                      .pushNamed(Routes.downloadedNotesCategory),
                ),
              ),
            ],
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
