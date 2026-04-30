// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';

/// SPR report detail screen — placeholder detail showing scored marks,
/// rank, student count, percentage, percentile and a subject-wise
/// breakdown. Currently uses mock data (like the legacy view).
///
/// Preserved public contract:
///   • Constructor `SPRReportDetailScreen({Key? key})`
///   • Static `route(RouteSettings)` returning a `CupertinoPageRoute`.
class SPRReportDetailScreen extends StatefulWidget {
  const SPRReportDetailScreen({Key? key}) : super(key: key);

  @override
  State<SPRReportDetailScreen> createState() => _SPRReportDetailScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const SPRReportDetailScreen(),
    );
  }
}

class _SPRReportDetailScreenState extends State<SPRReportDetailScreen> {
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
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.s20),
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(AppTokens.s20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTokens.brand, AppTokens.brand2],
              ),
              borderRadius: BorderRadius.circular(AppTokens.r20),
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
                        style: AppTokens.titleSm(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      "17/July/2023",
                      style: AppTokens.caption(context).copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s24),
                Center(
                  child: Text(
                    "75/200",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "Scored marks",
                    style: AppTokens.caption(context).copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s20),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  asset: "assets/image/trophy_icon.svg",
                  label: "My rank",
                  value: "23",
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: _StatCard(
                  asset: "assets/image/person_icon.svg",
                  label: "Student appeared",
                  value: "125",
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  asset: "assets/image/percentage_icon.svg",
                  label: "Percentage",
                  value: "75%",
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: _StatCard(
                  asset: "assets/image/percentage_icon.svg",
                  label: "Percentile",
                  value: "80.05%",
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s20),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Subject",
                  style: AppTokens.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                ),
                Text(
                  "Scored Marks",
                  style: AppTokens.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                ),
                Text(
                  "Subject Rank",
                  style: AppTokens.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          ListView.separated(
            itemCount: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            separatorBuilder: (_, __) => Divider(
              color: AppTokens.border(context),
              height: AppTokens.s24,
            ),
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s4,
                  vertical: AppTokens.s8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Subject ${index.toString()}",
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTokens.ink(context),
                      ),
                    ),
                    Text(
                      "50/200",
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTokens.ink(context),
                      ),
                    ),
                    Text(
                      "-",
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTokens.muted(context),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppTokens.s20),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.asset,
    required this.label,
    required this.value,
  });

  final String asset;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              borderRadius: BorderRadius.circular(AppTokens.r8),
            ),
            child: SvgPicture.asset(asset, height: 20, width: 20),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.muted(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTokens.titleSm(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTokens.accent(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
