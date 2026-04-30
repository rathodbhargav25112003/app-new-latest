import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../helpers/app_tokens.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import 'package:shusruta_lms/helpers/colors.dart';
// ignore: unused_import
import 'package:shusruta_lms/helpers/dimensions.dart';
// ignore: unused_import
import 'package:shusruta_lms/helpers/styles.dart';

/// SubscriptionDialog — web-only upsell dialog that nudges users to the
/// native apps for subscription purchases. Public surface preserved
/// exactly: no constructor params, still renders as a [Dialog]. External
/// callers (e.g. `showDialog(builder: (_) => SubscriptionDialog())`)
/// keep working unchanged.
///
/// Links are routed via `url_launcher`:
///   • Play Store — com.ginger.sushruta
///   • App Store — id6443898817
// ignore: use_key_in_widget_constructors, prefer_const_constructors_in_immutables
class SubscriptionDialog extends StatelessWidget {
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ginger.sushruta&pcampaignid=web_share';
  static const _appStoreUrl =
      'https://apps.apple.com/in/app/sushruta-lgs/id6443898817';

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTokens.surface(context),
      surfaceTintColor: AppTokens.surface(context),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s20,
        vertical: AppTokens.s24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r28),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s24,
            AppTokens.s24,
            AppTokens.s24,
            AppTokens.s20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.r20),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: AppTokens.brand.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.r20),
                  child: Image.asset(
                    'assets/image/app_icon.jpg',
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s20),
              Text(
                'Subscriptions are available on our mobile app',
                textAlign: TextAlign.center,
                style: AppTokens.titleMd(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                'To complete your purchase or manage a subscription, please open the Sushruta LGS app from Play Store or App Store.',
                textAlign: TextAlign.center,
                style: AppTokens.body(context).copyWith(
                  color: AppTokens.ink2(context),
                ),
              ),
              const SizedBox(height: AppTokens.s24),
              Row(
                children: [
                  Expanded(
                    child: _StoreBadge(
                      asset:
                          'assets/image/Google_Play_Store_badge_EN.svg',
                      onTap: () => _open(_playStoreUrl),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: _StoreBadge(
                      asset:
                          'assets/image/Download_on_the_App_Store_Badge.svg',
                      onTap: () => _open(_appStoreUrl),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink2(context),
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

class _StoreBadge extends StatelessWidget {
  const _StoreBadge({required this.asset, required this.onTap});

  final String asset;
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
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s8),
          decoration: BoxDecoration(
            color: AppTokens.surface2(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(color: AppTokens.border(context)),
          ),
          child: SvgPicture.asset(asset, height: 36),
        ),
      ),
    );
  }
}
