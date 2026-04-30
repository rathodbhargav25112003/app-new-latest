// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';

/// "Result pending" notification screen — shown after a student submits a
/// test whose results are embargoed until a future declarationTime.
///
/// Preserved public contract:
///   • `TestNotificationsScreen({super.key, required declarationTime})`
///   • Static `route(RouteSettings)` reads `{declarationTime}`.
///   • Back button pushes `Routes.dashboard`.
///   • Formatting: `dd-MMM-yyyy` + `hh:mm a`.
///   • Body copy verbatim: "Your Responses have been Submitted. Result
///     And Solutions Shall be Available on {date} at {time}."
class TestNotificationsScreen extends StatefulWidget {
  final String declarationTime;
  const TestNotificationsScreen({
    super.key,
    required this.declarationTime,
  });

  @override
  State<TestNotificationsScreen> createState() =>
      _TestNotificationsScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => TestNotificationsScreen(
        declarationTime: arguments['declarationTime'],
      ),
    );
  }
}

class _TestNotificationsScreenState extends State<TestNotificationsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final String originalDate = widget.declarationTime;
    final DateTime parsedDate = DateTime.parse(originalDate);
    final DateFormat formatter = DateFormat('dd-MMM-yyyy');
    final DateFormat formatter2 = DateFormat('hh:mm a');
    final String formattedDate = formatter.format(parsedDate);
    final String formattedTime = formatter2.format(parsedDate);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTokens.r28),
                  topRight: Radius.circular(AppTokens.r28),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
              child: Column(
                children: [
                  const Spacer(),
                  Image.asset(
                    "assets/image/declareImage.png",
                    height: 180,
                  ),
                  const SizedBox(height: AppTokens.s24),
                  Text(
                    "Your Responses have been Submitted. Result And Solutions Shall be Available on $formattedDate at $formattedTime.",
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTokens.ink(context),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTokens.s8,
        left: AppTokens.s8,
        right: AppTokens.s20,
        bottom: AppTokens.s20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pushNamed(Routes.dashboard),
            borderRadius: BorderRadius.circular(AppTokens.r8),
            child: Container(
              height: AppTokens.s32,
              width: AppTokens.s32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              "Notification",
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
