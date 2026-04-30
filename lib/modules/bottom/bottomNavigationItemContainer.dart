import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../../helpers/app_tokens.dart';
import 'customShowCaseWidget.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import 'package:shusruta_lms/helpers/colors.dart';
// ignore: unused_import
import 'package:shusruta_lms/helpers/dimensions.dart';

/// BottomNavItem — data object describing a single tab in the bottom
/// navigation bar. Public surface preserved exactly: const-compatible
/// positional named constructor with `activeImageUrl`, `disableImageUrl`,
/// `title`.
class BottomNavItem {
  final String title;
  final String activeImageUrl;
  final String disableImageUrl;

  BottomNavItem({
    required this.activeImageUrl,
    required this.disableImageUrl,
    required this.title,
  });
}

/// BottomNavItemContainer — single tab inside the bottom navigation bar.
/// Public surface preserved exactly:
///   • non-const constructor `(Key? key, {required boxConstraints,
///     required currentIndex, required showCaseDescription,
///     required showCaseKey, required bottomNavItem,
///     required animationController, required onTap, required index})`
///   • Tap invokes `widget.onTap(index)` then triggers
///     `HapticFeedback.heavyImpact()`
///   • SVG swaps between `activeImageUrl` and `disableImageUrl` based on
///     whether `index == currentIndex`
///   • Wrapped in a [CustomShowCaseWidget] with the supplied key +
///     description
class BottomNavItemContainer extends StatefulWidget {
  final BoxConstraints boxConstraints;
  final int index;
  final int currentIndex;
  final AnimationController animationController;
  final BottomNavItem bottomNavItem;
  final Function onTap;
  final GlobalKey showCaseKey;
  final String showCaseDescription;

  // ignore: use_super_parameters
  const BottomNavItemContainer({
    Key? key,
    required this.boxConstraints,
    required this.currentIndex,
    required this.showCaseDescription,
    required this.showCaseKey,
    required this.bottomNavItem,
    required this.animationController,
    required this.onTap,
    required this.index,
  }) : super(key: key);

  @override
  State<BottomNavItemContainer> createState() => _BottomNavItemContainerState();
}

class _BottomNavItemContainerState extends State<BottomNavItemContainer> {
  @override
  Widget build(BuildContext context) {
    final isSelected = widget.index == widget.currentIndex;
    return CustomShowCaseWidget(
      globalKey: widget.showCaseKey,
      description: widget.showCaseDescription,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            widget.onTap(widget.index);
            HapticFeedback.heavyImpact();
          },
          borderRadius: BorderRadius.circular(AppTokens.r16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppTokens.s8,
              horizontal: AppTokens.s4,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTokens.accentSoft(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                  ),
                  child: SvgPicture.asset(
                    isSelected
                        ? widget.bottomNavItem.activeImageUrl
                        : widget.bottomNavItem.disableImageUrl,
                    width: 22,
                    height: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.bottomNavItem.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTokens.caption(context).copyWith(
                    fontSize: 11.5,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppTokens.accent(context)
                        : AppTokens.ink2(context),
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
