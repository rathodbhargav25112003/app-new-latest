// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';

/// SPR (Student Performance Report) list screen — shows a list of past
/// tests with maximum marks + scored marks. Tapping an item routes to
/// `Routes.sprReportDetail`.
///
/// Preserved public contract:
///   • Constructor `SPRReportsListScreen({Key? key})`
///   • Static `route(RouteSettings)` returning a `CupertinoPageRoute`
///     that builds `const SPRReportsListScreen()`.
///   • Currently renders 6 placeholder items (itemCount: 6) — same as
///     the legacy view; wiring to a real list is out of scope for this
///     polish pass.
///   • Row tap → `Navigator.of(context).pushNamed(Routes.sprReportDetail)`.
class SPRReportsListScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const SPRReportsListScreen({Key? key}) : super(key: key);

  @override
  State<SPRReportsListScreen> createState() => _SPRReportsListScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const SPRReportsListScreen(),
    );
  }
}

class _SPRReportsListScreenState extends State<SPRReportsListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: AppTokens.scaffold(context),
        surfaceTintColor: Colors.transparent,
        titleSpacing: AppTokens.s8,
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(AppTokens.r8),
              child: Container(
                height: AppTokens.s32,
                width: AppTokens.s32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.surface2(context),
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppTokens.ink(context),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Text(
              "SPR Reports",
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppTokens.s20),
        physics: const BouncingScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppTokens.s12),
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            borderRadius: BorderRadius.circular(AppTokens.r16),
            onTap: () {
              Navigator.of(context).pushNamed(Routes.sprReportDetail);
            },
            child: Container(
              padding: const EdgeInsets.all(AppTokens.s16),
              decoration: BoxDecoration(
                color: AppTokens.surface(context),
                borderRadius: BorderRadius.circular(AppTokens.r16),
                border: Border.all(color: AppTokens.border(context)),
                boxShadow: AppTokens.shadow1(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Chemistry Chapter 01",
                          style: AppTokens.body(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTokens.accentSoft(context),
                          borderRadius:
                              BorderRadius.circular(AppTokens.r8),
                        ),
                        child: Text(
                          "17/July/2023",
                          style: AppTokens.caption(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppTokens.accent(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s16,
                      vertical: AppTokens.s12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.surface2(context),
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _SprStat(
                            value: "200",
                            label: "Maximum Marks",
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AppTokens.border(context),
                        ),
                        Expanded(
                          child: _SprStat(
                            value: "200",
                            label: "Scored Marks",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SprStat extends StatelessWidget {
  const _SprStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTokens.titleSm(context).copyWith(
            fontWeight: FontWeight.w800,
            color: AppTokens.accent(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.muted(context),
          ),
        ),
      ],
    );
  }
}
