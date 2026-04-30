// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, unused_local_variable, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';

/// Submission-acknowledgement screen shown after a master test is submitted
/// while results are scheduled for later release. Preserves:
///   • `const MasterTestNotificationsScreen({super.key})` constructor
///   • `static Route<dynamic> route(RouteSettings routeSettings)` factory
///     returning a `CupertinoPageRoute` wrapping this screen
///   • Back icon → `Navigator.of(context).pushNamed(Routes.dashboard)`
///   • `assets/image/declareImage.png` illustration
///   • Body copy verbatim
class MasterTestNotificationsScreen extends StatefulWidget {
  const MasterTestNotificationsScreen({super.key});

  @override
  State<MasterTestNotificationsScreen> createState() =>
      _MasterTestNotificationsScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => const MasterTestNotificationsScreen(),
    );
  }
}

class _MasterTestNotificationsScreenState
    extends State<MasterTestNotificationsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          // ---------------------------------------------------
          // Brand gradient header
          // ---------------------------------------------------
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppTokens.s12,
              left: AppTokens.s16,
              right: AppTokens.s16,
              bottom: AppTokens.s20,
            ),
            child: Row(
              children: [
                _CircleBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () =>
                      Navigator.of(context).pushNamed(Routes.dashboard),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Submission Confirmed",
                        style: AppTokens.overline(context)
                            .copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Notification",
                        style: AppTokens.titleMd(context)
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40), // symmetrical spacer
              ],
            ),
          ),
          // ---------------------------------------------------
          // Body
          // ---------------------------------------------------
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s24,
                  vertical: AppTokens.s32,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppTokens.s24),
                    Container(
                      padding: const EdgeInsets.all(AppTokens.s24),
                      decoration: BoxDecoration(
                        color: AppTokens.accentSoft(context),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        "assets/image/declareImage.png",
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: AppTokens.s24),
                    Text(
                      "Your Responses have been Submitted",
                      textAlign: TextAlign.center,
                      style: AppTokens.titleMd(context),
                    ),
                    const SizedBox(height: AppTokens.s12),
                    Container(
                      padding: const EdgeInsets.all(AppTokens.s16),
                      decoration: BoxDecoration(
                        color: AppTokens.surface(context),
                        borderRadius: AppTokens.radius16,
                        border: Border.all(color: AppTokens.border(context)),
                        boxShadow: AppTokens.shadow1(context),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: AppTokens.accent(context),
                            size: 22,
                          ),
                          const SizedBox(width: AppTokens.s12),
                          Expanded(
                            child: Text(
                              "Your Responses have been Submitted. Result And Solutions Shall be Available on {Date} at {Time}.",
                              style: AppTokens.body(context),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//                        Primitives
// ============================================================

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
