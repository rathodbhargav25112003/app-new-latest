import '../../app/routes.dart';
import '../../helpers/colors.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:shusruta_lms/helpers/styles.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/modules/widgets/custom_button.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const SplashScreen(),
    );
  }
}

class _SplashScreenState extends State<SplashScreen> {
  int _backButtonPressCount = 0;
  
  Future<bool> _handleBackPressed() async {
    if (_backButtonPressCount == 1) {
      SystemNavigator.pop();
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
        ),
      );
      _backButtonPressCount++;
      Future.delayed(const Duration(seconds: 2), () {
        _backButtonPressCount = 0;
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: Scaffold(
        body: OrientationBuilder(
          builder: (context, orientation) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: ThemeManager.primaryColor,
              child: Stack(
                children: [
                  if (orientation == Orientation.portrait)
                    _buildPortraitContent()
                  else
                    _buildLandscapeContent(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPortraitContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: SvgPicture.asset(
                    "assets/image/splash_bg.svg",
                    width: MediaQuery.of(context).size.width * 0.8,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: SvgPicture.asset(
                    "assets/image/child_study.svg",
                    height: MediaQuery.of(context).size.height * 0.38,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Soft hairline divider replaces the harsh 2pt black bar —
        // Apple style: barely-there separator that sets a copy block
        // apart from the illustration without screaming.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 0.5,
            margin: const EdgeInsets.only(bottom: 32),
            color: Colors.white.withOpacity(0.18),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Change the way you learn",
                style: AppTokens.displayMd(context).copyWith(
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Join the Sushruta LGS family — aim high, achieve higher.",
                style: AppTokens.bodyLg(context).copyWith(
                  color: Colors.white.withOpacity(0.78),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              CustomButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(Routes.loginWithPass);
                },
                buttonText: "Get started",
                height: 54,
                icon: Icons.arrow_forward_rounded,
                radius: AppTokens.r16,
                bgColor: Colors.white,
                fontSize: 16,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLandscapeContent() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: SvgPicture.asset(
              "assets/image/splash_bg.svg",
              width: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              left: Dimensions.PADDING_SIZE_LARGE,
              right: Dimensions.PADDING_SIZE_EXTRA_LARGE,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Change the way you learn",
                  style: AppTokens.displayMd(context).copyWith(
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Join the Sushruta LGS family — aim high, achieve higher.",
                  style: AppTokens.bodyLg(context).copyWith(
                    color: Colors.white.withOpacity(0.78),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                CustomButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(Routes.loginWithPass);
                  },
                  buttonText: "Get started",
                  height: 54,
                  icon: Icons.arrow_forward_rounded,
                  radius: AppTokens.r16,
                  bgColor: Colors.white,
                  fontSize: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
