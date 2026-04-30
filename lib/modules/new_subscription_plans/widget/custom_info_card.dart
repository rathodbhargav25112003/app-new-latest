// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../helpers/app_tokens.dart';
import '../../../helpers/colors.dart';
import '../../../helpers/dimensions.dart';
import '../../../helpers/styles.dart';

/// CustomInfoCard — small rectangular tap target with a leading icon, a
/// title, a subtitle, and a trailing arrow. Used across the
/// new_subscription_plans flows for selecting delivery type / address /
/// offers etc.
///
/// Public surface preserved exactly:
///   • class [CustomInfoCard] + const constructor with named params
///     `{key, required icon, required title, required subtitle, onTap,
///      backgroundColor = const Color(0xFFF3F9F4), iconBgColor = white,
///      arrowColor = black}`
class CustomInfoCard extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color iconBgColor;
  final Color arrowColor;

  const CustomInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.backgroundColor = const Color(0xFFF3F9F4),
    this.iconBgColor = Colors.white,
    this.arrowColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppTokens.r16),
            border: Border.all(color: AppTokens.border(context)),
          ),
          padding: const EdgeInsets.all(AppTokens.s16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
                child: icon,
              ),
              const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: arrowColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
