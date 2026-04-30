import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../helpers/app_tokens.dart';
// ignore: unused_import
import 'package:shusruta_lms/helpers/colors.dart';
// ignore: unused_import
import 'package:shusruta_lms/helpers/styles.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';

/// CustomButton — app-wide primary button. Public surface preserved exactly:
///   • const constructor with named parameters:
///       onPressed, buttonText, transparent, isLoading, margin, width,
///       height, fontSize, radius, icon, textAlign, bgColor (required),
///       textColor, child, key
///   • `isLoading == true` renders a CupertinoActivityIndicator
///   • `child` takes priority over buttonText+icon when non-null
///   • `onPressed == null` disables (uses theme disabled colour)
class CustomButton extends StatelessWidget {
  final void Function()? onPressed;
  final String? buttonText;
  final bool? transparent;
  final bool? isLoading;
  final EdgeInsets? margin;
  final double? height;
  final double? width;
  final double? fontSize;
  final double? radius;
  final IconData? icon;
  final TextAlign? textAlign;
  final Color bgColor;
  final Color? textColor;
  final Widget? child;

  const CustomButton({
    super.key,
    required this.onPressed,
    this.buttonText,
    this.transparent = false,
    this.isLoading = false,
    this.margin,
    this.width,
    this.height,
    this.fontSize,
    this.radius,
    this.icon,
    this.textAlign,
    required this.bgColor,
    this.child,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;
    final double resolvedHeight = height ?? 52;
    final double resolvedRadius = radius ?? AppTokens.r12;
    final double resolvedWidth = width ?? double.infinity;
    final Color resolvedBg = disabled
        ? Theme.of(context).disabledColor
        : bgColor;
    final Color resolvedLabel = textColor ??
        (transparent ?? false
            ? AppTokens.ink(context)
            : Colors.white);

    final Widget content = child ??
        Row(
          mainAxisAlignment: icon != null
              ? MainAxisAlignment.center
              : MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: resolvedLabel, size: 18),
              const SizedBox(width: AppTokens.s8),
            ],
            Flexible(
              child: Text(
                buttonText ?? '',
                textAlign: textAlign ?? TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTokens.body(context).copyWith(
                  color: resolvedLabel,
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
                ),
              ),
            ),
          ],
        );

    final Widget body = isLoading == true
        ? Container(
            height: resolvedHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(resolvedRadius),
              color: resolvedBg,
            ),
            alignment: Alignment.center,
            child: const CupertinoActivityIndicator(color: Colors.white),
          )
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(resolvedRadius),
              child: Container(
                height: resolvedHeight,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  horizontal: icon != null
                      ? AppTokens.s16
                      : AppTokens.s20,
                ),
                decoration: BoxDecoration(
                  color: resolvedBg,
                  borderRadius: BorderRadius.circular(resolvedRadius),
                  border: (transparent ?? false)
                      ? Border.all(color: AppTokens.border(context))
                      : null,
                ),
                child: content,
              ),
            ),
          );

    return Center(
      child: SizedBox(
        width: resolvedWidth,
        child: Padding(
          padding: margin ?? EdgeInsets.zero,
          child: body,
        ),
      ),
    );
  }
}

/// LoginCustomButton — branded gradient CTA used in auth flows. Public
/// surface preserved exactly:
///   • const constructor with named parameters:
///       onPressed, buttonText, transparent, margin, width, height,
///       fontSize, radius, icon, textAlign, bgColor (required), child, key
///   • `child` takes priority over buttonText+icon when non-null
class LoginCustomButton extends StatelessWidget {
  final void Function()? onPressed;
  final String? buttonText;
  final bool? transparent;
  final EdgeInsets? margin;
  final double? height;
  final double? width;
  final double? fontSize;
  final double? radius;
  final IconData? icon;
  final TextAlign? textAlign;
  final Color bgColor;
  final Widget? child;

  const LoginCustomButton({
    super.key,
    required this.onPressed,
    this.buttonText,
    this.transparent = false,
    this.margin,
    this.width,
    this.height,
    this.fontSize,
    this.radius,
    this.icon,
    this.textAlign,
    required this.bgColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;
    final double resolvedHeight = height ?? 52;
    final double resolvedRadius = radius ?? AppTokens.r12;
    final double resolvedWidth = width ?? double.infinity;

    final Widget labelRow = child ??
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: AppTokens.s8),
            ],
            Flexible(
              child: Text(
                buttonText ?? '',
                textAlign: textAlign ?? TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTokens.body(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
                ),
              ),
            ),
          ],
        );

    final BoxDecoration decoration = disabled
        ? BoxDecoration(
            color: Theme.of(context).disabledColor,
            borderRadius: BorderRadius.circular(resolvedRadius),
          )
        : BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(resolvedRadius),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: AppTokens.brand.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          );

    return Center(
      child: SizedBox(
        width: resolvedWidth,
        child: Padding(
          padding: margin ?? EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(resolvedRadius),
              child: Container(
                height: resolvedHeight,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s20,
                ),
                decoration: decoration,
                child: labelRow,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
