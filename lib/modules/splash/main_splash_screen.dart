import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/api_service/api_service.dart';
import 'package:shusruta_lms/services/app_lock_service.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../../app/routes.dart';
import '../../helpers/colors.dart';

class MainSplashScreen extends StatefulWidget {
  const MainSplashScreen({super.key});

  @override
  _MainSplashScreenState createState() => _MainSplashScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const MainSplashScreen(),
    );
  }
}

class _MainSplashScreenState extends State<MainSplashScreen>
    with SingleTickerProviderStateMixin {
  Socket? socket;
  // Apple-like fade-in for the logo: 700ms gentle ease, no scale —
  // matches iOS's Cold Boot launch image transition.
  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _fadeCtrl,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    // Light status-bar icons on the navy gradient — system icons appear
    // white instead of fighting the brand colour.
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF00309D),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    _fadeCtrl.forward();
    checkLoggedIn();
  }

  Future<void> checkLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? loggedInEmail = prefs.getBool('isloggedInEmail');
    bool? signInGoogle = prefs.getBool('isSignInGoogle');
    bool? loggedInWt = prefs.getBool('isLoggedInWt');
    String? token = prefs.getString("token");
    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      final isAuthenticated = (loggedInEmail ?? false || signInGoogle == true)
          || (loggedInWt ?? false || signInGoogle == true);
      if (isAuthenticated) {
        // Wave-3.2 boot-gate: when biometric / PIN is configured the
        // user must pass it before we push to dashboard. Falls
        // through silently when nothing is configured.
        final passed = await AppLockService().runBootGate(context);
        if (!mounted) return;
        if (!passed) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.login,
            (route) => false,
          );
          return;
        }
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.dashboard,
          (route) => false,
        );
        // await checkDeviceExists(token);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.login,
          (route) => false,
        );
        // Navigator.of(context).pushNamed(Routes.loginWithPass);
      }
    });
  }

  Future<Map<String, String>> getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId = '';
    String deviceName = '';
    String platform = '';

    if (Platform.isAndroid) {
      // Android specific device information
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
      deviceName = androidInfo.model ?? 'Unknown';
      platform = 'Android';
    } else if (Platform.isIOS) {
      // iOS specific device information
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? 'Unknown';
      deviceName = iosInfo.name ?? 'Unknown';
      platform = 'iOS';
    } else if (Platform.isMacOS) {
      // macOS specific device information
      final macInfo = await deviceInfo.macOsInfo;
      deviceId = macInfo.systemGUID ?? 'Unknown';
      deviceName = macInfo.model ?? 'Unknown';
      platform = 'macOS';
    } else if (Platform.isWindows) {
      // Windows specific device information
      final windowsInfo = await deviceInfo.windowsInfo;
      deviceId = windowsInfo.deviceId ?? 'Unknown';
      deviceName = windowsInfo.computerName ?? 'Unknown';
      platform = 'Windows';
    }
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
    };
  }

  Future<void> checkDeviceExists(token) async {
    try {
      Map<String, dynamic> platformInfo = await getDeviceInfo();

      final response =
          await ApiService().checkDeviceInfo(platformInfo["device_id"], token);
      print(response);
      if (response["status"] == true) {
        connectSocketIO();
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.dashboard,
          (route) => false,
        );
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.login,
          (route) => false,
        );
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  void connectSocketIO() {
    socket = io('http://api.sushrutalgs.in:5001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket?.on('connect', (_) {
      print('Connected to socket.io server');
    });

    socket?.on('disconnect', (_) {
      print('Disconnected from socket.io server');
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
    socket?.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            // Softer 2-stop gradient — replaces the previous 4-stop
            // saturated stack for an Apple-style calm hero. Keeps the
            // brand navy tone but reads as one surface, not bands.
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2366F4),
                  Color(0xFF00309D),
                ],
              ),
              color: AppColors.primaryColor,
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  if (orientation == Orientation.portrait)
                    _buildPortraitContent()
                  else
                    _buildLandscapeContent(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPortraitContent() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gentle fade-in — feels intentional rather than abrupt.
          FadeTransition(
            opacity: _fade,
            child: Image.asset(
              'assets/image/app_logo.png',
              width: 280,
            ),
          ),
          // Subtle 3-dot loader near the bottom — replaces a static
          // splash bg image with motion that signals progress without
          // shouting. Falls behind the wave bg so legacy assets still
          // work for users who expect them.
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 56),
              child: _BootingDots(controller: _fadeCtrl),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/image/splash_bg.png',
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.fitWidth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeContent() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: _fade,
            child: Image.asset(
              'assets/image/app_logo.png',
              width: 240,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/image/splash_bg.png',
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }
}

/// Three soft dots that pulse in sequence — visible signal that the
/// app is booting. Re-uses the splash fade controller to cycle so we
/// don't spawn a second AnimationController.
class _BootingDots extends StatelessWidget {
  final AnimationController controller;
  const _BootingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = ((t * 3) - i).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: 0.35 + 0.55 * phase,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
