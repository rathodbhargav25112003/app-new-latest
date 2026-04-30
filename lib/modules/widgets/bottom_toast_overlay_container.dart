import 'package:flutter/material.dart';

import '../../helpers/app_tokens.dart';

/// BottomToastOverlayContainer — animated toast pill shown via
/// [BottomToast.showBottomToastOverlay]. Public surface preserved exactly:
///   • const constructor `({Key? key, required String errorMessage,
///     required Color backgroundColor})`
///   • `SingleTickerProviderStateMixin`-driven slideAnimation
///     (Tween -0.5→1.0 / 500ms / Curves.easeInOutCirc)
///   • 3000ms display duration + reverse schedule 500ms before dismissal
class BottomToastOverlayContainer extends StatefulWidget {
  final String errorMessage;
  final Color backgroundColor;
  // ignore: prefer_const_constructors_in_immutables
  BottomToastOverlayContainer({
    super.key,
    required this.errorMessage,
    required this.backgroundColor,
  });

  @override
  // ignore: library_private_types_in_public_api
  _BottomToastOverlayContainerState createState() =>
      _BottomToastOverlayContainerState();
}

class _BottomToastOverlayContainerState
    extends State<BottomToastOverlayContainer>
    with SingleTickerProviderStateMixin {
  final Duration errorMessageDisplayDuration =
      const Duration(milliseconds: 3000);

  late AnimationController animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  late Animation<double> slideAnimation = Tween<double>(begin: -0.5, end: 1.0)
      .animate(CurvedAnimation(
    parent: animationController,
    curve: Curves.easeInOutCirc,
  ));

  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(
        milliseconds: errorMessageDisplayDuration.inMilliseconds - 500,
      ),
      () {
        if (!mounted) return;
        animationController.reverse();
      },
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: slideAnimation,
      builder: (context, child) {
        final double t = slideAnimation.value;
        return PositionedDirectional(
          start: MediaQuery.of(context).size.width * 0.1,
          bottom: MediaQuery.of(context).size.height * 0.075 * t,
          child: Opacity(
            opacity: t < 0.0 ? 0.0 : t,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s16,
                  vertical: AppTokens.s12,
                ),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  widget.errorMessage,
                  textAlign: TextAlign.center,
                  style: AppTokens.caption(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
