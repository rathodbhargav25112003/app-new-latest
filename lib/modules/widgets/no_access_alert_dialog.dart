import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import 'free_trial_success_bottom_sheet.dart';
import 'package:shusruta_lms/modules/login/store/login_store.dart';
import 'package:shusruta_lms/modules/login/store/verify_otp_phone.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/widgets.dart';
// ignore: unused_import
import 'package:flutter_svg/flutter_svg.dart';

/// NoAccessAlertDialog — paywall / free-trial prompt dialog. Public surface
/// preserved exactly:
///   • const constructor `{super.key, this.isFree = false, this.planId = "",
///     this.day = 0, this.onTap}`
///   • Branches on `isFree` between the "Start Your Free Trial Today!" and
///     "Continue Your Learning Journey" flows
///   • On CTA tap: free-trial branch calls
///     `TestCategoryStore.onFreePlanApiCall(planId, day)` then opens
///     [FreeTrialSuccessBottomSheet]; upgrade branch pushes either
///     [Routes.newSelectSubscriptionPlan] (IAP on Apple platforms) or
///     [Routes.newSubscription]
class NoAccessAlertDialog extends StatefulWidget {
  final bool isFree;
  final String planId;
  final int day;
  final Function()? onTap;

  const NoAccessAlertDialog({
    super.key,
    this.isFree = false,
    this.planId = "",
    this.day = 0,
    this.onTap,
  });

  @override
  State<NoAccessAlertDialog> createState() => _NoAccessAlertDialogState();
}

class _NoAccessAlertDialogState extends State<NoAccessAlertDialog> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleCta() async {
    if (!widget.isFree) {
      final store = Provider.of<TestCategoryStore>(context, listen: false);
      showLoadingDialog(context);
      final bool result =
          await store.onFreePlanApiCall(widget.planId, widget.day);
      if (!mounted) return;
      Navigator.of(context).pop();

      if (result) {
        widget.onTap?.call();
        Navigator.of(context).pop();

        final DateTime currentDate = DateTime.now();
        final DateTime expirationDate =
            currentDate.add(Duration(days: widget.day));
        final String formattedDate =
            DateFormat('MMM dd, yyyy').format(expirationDate);

        showModalBottomSheet(
          // ignore: use_build_context_synchronously
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => FreeTrialSuccessBottomSheet(
            expirationDate: formattedDate,
          ),
        );
      } else {
        widget.onTap?.call();
        Navigator.of(context).pop();
      }
    } else {
      final loginStore = Provider.of<LoginStore>(context, listen: false);
      final bool isIAPEnabled =
          loginStore.settingsData.value?.isInAPurchases == true;
      Navigator.of(context).pop();
      if (isIAPEnabled && (Platform.isMacOS || Platform.isIOS)) {
        Navigator.of(context).pushNamed(
          Routes.newSelectSubscriptionPlan,
          arguments: {
            'categoryId': '',
            'subcategoryId': '',
          },
        );
      } else {
        Navigator.of(context).pushNamed(
          Routes.newSubscription,
          arguments: {'showBackButton': true},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> bullets = widget.isFree
        ? const [
            '8400+ MCQs from Bailey, Sabiston & Schwartz',
            'eNotes & Hardcopy Notes — crisp & exam-ready',
            'Powerhouse Videos — high-yield topics explained',
            'Masterclass Tests & Discussions — 32 tests with reasoning-based MCQs',
            'Image / Table-Based eNotes & Videos',
            'Complete Schwartz Module',
            'Superspecialty MCQs, AI Study Planner, Note Annotations',
          ]
        : const [
            'MCQ Bank — detailed explanations & justifications, updated to the latest editions',
            'eNotes — annotation & highlighting features for active learning',
            'Video Lectures — timestamped notes & chapter-wise navigation',
            'Mock Exams — realistic exam simulation with performance insights',
          ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s20,
        vertical: AppTokens.s24,
      ),
      backgroundColor: AppTokens.surface(context),
      surfaceTintColor: AppTokens.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r28),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s24,
            AppTokens.s24,
            AppTokens.s24,
            AppTokens.s20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTokens.brand, AppTokens.brand2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Text(
                      !widget.isFree
                          ? 'Start Your Free Trial Today!'
                          : 'Continue Your Learning Journey — unlock premium content!',
                      style: AppTokens.titleMd(context)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              Text(
                !widget.isFree
                    ? 'Get started with Sushruta LGS and explore all premium features:'
                    : "You've experienced the power of Sushruta LGS. Now, unlock full access by subscribing to our premium plan:",
                textAlign: TextAlign.center,
                style: AppTokens.body(context).copyWith(
                  color: AppTokens.ink2(context),
                ),
              ),
              const SizedBox(height: AppTokens.s20),
              ...bullets.map((b) => _FeatureItem(text: b)),
              const SizedBox(height: AppTokens.s16),
              Center(
                child: Text(
                  !widget.isFree
                      ? '🎉 Start your FREE trial now and experience it all!'
                      : '🎯 Continue your focused, structured prep with full access today!',
                  textAlign: TextAlign.center,
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s20),
              _GradientCta(
                label: !widget.isFree ? 'Activate Free Trial' : 'Subscribe Now',
                icon: !widget.isFree
                    ? Icons.rocket_launch_rounded
                    : Icons.workspace_premium_rounded,
                onTap: _handleCta,
              ),
              const SizedBox(height: AppTokens.s12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Maybe later',
                    style: AppTokens.body(context).copyWith(
                      color: AppTokens.ink2(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.successSoft(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: AppTokens.success(context),
              size: 14,
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              text,
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
