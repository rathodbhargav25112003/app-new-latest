// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';

/// Post-submission waiting screen — shown after a scheduled/mock test is
/// submitted before results are declared.
///
/// Preserved public contract:
///   • Constructor `SolutionTestNotificationsScreen({super.key,
///     required this.declarationTime})`
///   • Static `route(RouteSettings)` reads `declarationTime`.
///   • Displays declaration date (`dd-MMM-yyyy`) and time (`hh:mm a`)
///     parsed from `widget.declarationTime` via `DateTime.parse`.
///   • Copy preserved verbatim: "Your Responses have been Submitted.
///     Result And Solutions Shall be Available on {date} at {time}."
///   • Top bar back chevron pops route.
class SolutionTestNotificationsScreen extends StatefulWidget {
  final String declarationTime;
  const SolutionTestNotificationsScreen({
    super.key,
    required this.declarationTime,
  });

  @override
  State<SolutionTestNotificationsScreen> createState() =>
      _SolutionTestNotificationsScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => SolutionTestNotificationsScreen(
        declarationTime: arguments['declarationTime'],
      ),
    );
  }
}

class _SolutionTestNotificationsScreenState
    extends State<SolutionTestNotificationsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.parse(widget.declarationTime);
    final formattedDate = DateFormat('dd-MMM-yyyy').format(parsedDate);
    final formattedTime = DateFormat('hh:mm a').format(parsedDate);
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTokens.brand, AppTokens.brand2],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: AppTokens.s32),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTokens.scaffold(context),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTokens.r28),
                      topRight: Radius.circular(AppTokens.r28),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppTokens.s20),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s20,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius:
                                    BorderRadius.circular(AppTokens.r8),
                                child: Container(
                                  height: AppTokens.s32,
                                  width: AppTokens.s32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppTokens.surface2(context),
                                    borderRadius:
                                        BorderRadius.circular(AppTokens.r8),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 16,
                                    color: AppTokens.ink(context),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              "Notification",
                              style: AppTokens.titleSm(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTokens.ink(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: mq.height * 0.15),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s20,
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/image/declareImage.png",
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: AppTokens.s24),
                            Container(
                              padding: const EdgeInsets.all(AppTokens.s20),
                              decoration: BoxDecoration(
                                color: AppTokens.surface(context),
                                borderRadius:
                                    BorderRadius.circular(AppTokens.r16),
                                border: Border.all(
                                  color: AppTokens.border(context),
                                ),
                              ),
                              child: Text(
                                "Your Responses have been Submitted. Result And Solutions Shall be Available on $formattedDate at $formattedTime.",
                                style: AppTokens.body(context).copyWith(
                                  color: AppTokens.ink(context),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
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
