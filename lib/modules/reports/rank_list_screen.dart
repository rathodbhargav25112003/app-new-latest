// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_element, unnecessary_import, unnecessary_string_interpolations

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/models/user_score.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';

/// Leaderboard / rank list screen for a mock exam.
///
/// Preserved public contract:
///   • `Ranker` value class — all fields retained.
///   • `RankListScreen({super.key, required this.examId})`
///   • `store.onUserScoreApiCall(widget.examId)` fired in initState.
///   • Podium art (3 top places) + "Your Rank" + leaderboard list/grid.
///   • `RankerCard({super.key, required this.ranker})` — public card
///     widget used from this screen and potentially elsewhere.
///   • Private helpers `_buildStatItem`, `_getOrdinalSuffix`,
///     `_formatTime` preserved.
///   • On desktop (mac/windows) uses `CustomDynamicHeightGridView`; on
///     mobile uses `ListView.builder`.
class Ranker {
  final int score;
  final int rank;
  final String fullname;
  final String time;
  final int correct;
  final int inCorrect;
  final int isAttemptcount;
  final int skipped;
  final bool isMyRank;

  Ranker({
    required this.score,
    required this.rank,
    required this.fullname,
    required this.correct,
    required this.time,
    required this.inCorrect,
    required this.isAttemptcount,
    required this.skipped,
    required this.isMyRank,
  });
}

class RankListScreen extends StatefulWidget {
  const RankListScreen({super.key, required this.examId});
  final String examId;

  @override
  State<RankListScreen> createState() => _RankListScreenState();
}

class _RankListScreenState extends State<RankListScreen> {
  Future<void> _getUserRank() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onUserScoreApiCall(widget.examId);
  }

  @override
  void initState() {
    _getUserRank();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Observer(
        builder: (context) {
          return Column(
            children: [
              // Gradient podium header
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + AppTokens.s12,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTokens.brand, AppTokens.brand2],
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.s20,
                        0,
                        AppTokens.s20,
                        AppTokens.s12,
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(AppTokens.r8),
                            child: Container(
                              height: AppTokens.s32,
                              width: AppTokens.s32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius:
                                    BorderRadius.circular(AppTokens.r8),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTokens.s12),
                          Text(
                            "Leaderboard",
                            style: AppTokens.titleSm(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!store.isLoading) ...[
                      SizedBox(
                        height: 365,
                        child: Stack(
                          children: [
                            Positioned(
                              top: 80,
                              left: 0,
                              right: 0,
                              child: Image.asset("assets/image/rank_bg.png"),
                            ),
                            Positioned(
                              top: 200,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    "assets/image/rank.png",
                                    width: 350,
                                  ),
                                ],
                              ),
                            ),
                            // 2nd place — left
                            Positioned(
                              bottom: 175,
                              left: 55,
                              child: _PodiumEntry(
                                avatar: "assets/image/rank_profile.png",
                                avatarWidth: 65,
                                score:
                                    "${store.userScore.value![1].score}/${store.userScore.value![1].totalMarks}",
                                fullname:
                                    "${store.userScore.value![1].fullname}",
                              ),
                            ),
                            // 1st place — center, with crown
                            Positioned(
                              left: 0,
                              right: 0,
                              child: Column(
                                children: [
                                  Image.asset(
                                    "assets/image/king.png",
                                    width: 55,
                                  ),
                                  const SizedBox(height: 5),
                                  _PodiumEntry(
                                    avatar: "assets/image/rank_profile.png",
                                    avatarWidth: 82,
                                    score:
                                        "${store.userScore.value![0].score}/${store.userScore.value![0].totalMarks}",
                                    fullname:
                                        "${store.userScore.value![0].fullname}",
                                    nameWidth: 89,
                                  ),
                                ],
                              ),
                            ),
                            // 3rd place — right
                            Positioned(
                              right: 55,
                              bottom: 175,
                              child: _PodiumEntry(
                                avatar: "assets/image/rank_profile.png",
                                avatarWidth: 60,
                                score:
                                    "${store.userScore.value![2].score}/${store.userScore.value![2].totalMarks}",
                                fullname:
                                    "${store.userScore.value![2].fullname}",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(
                    left: AppTokens.s12,
                    right: AppTokens.s12,
                    top: AppTokens.s16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.scaffold(context),
                    borderRadius: (Platform.isMacOS || Platform.isWindows)
                        ? null
                        : const BorderRadius.only(
                            topLeft: Radius.circular(AppTokens.r28),
                            topRight: Radius.circular(AppTokens.r28),
                          ),
                  ),
                  child: store.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppTokens.accent(context),
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTokens.s8,
                                ),
                                child: Text(
                                  "Your Rank",
                                  style: AppTokens.titleSm(context).copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTokens.ink(context),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTokens.s4),
                              Padding(
                                padding:
                                    const EdgeInsets.all(AppTokens.s8),
                                child:
                                    RankerCard(ranker: store.myRank.value!),
                              ),
                              const SizedBox(height: AppTokens.s4),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTokens.s8,
                                  vertical: AppTokens.s8,
                                ),
                                child: Text(
                                  "Ranking and Leaderboard",
                                  style: AppTokens.titleSm(context).copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTokens.ink(context),
                                  ),
                                ),
                              ),
                              (Platform.isMacOS || Platform.isWindows)
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTokens.s4,
                                      ),
                                      child: CustomDynamicHeightGridView(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 10,
                                        shrinkWrap: true,
                                        physics:
                                            const BouncingScrollPhysics(),
                                        itemCount:
                                            store.userScore.value!.length,
                                        builder: (context, index) {
                                          final ranker =
                                              store.userScore.value![index];
                                          return ranker ==
                                                  store.myRank.value
                                              ? const SizedBox.shrink()
                                              : RankerCard(ranker: ranker);
                                        },
                                      ),
                                    )
                                  : ListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      padding:
                                          const EdgeInsets.all(AppTokens.s8),
                                      itemCount:
                                          store.userScore.value!.length,
                                      itemBuilder: (context, index) {
                                        final ranker =
                                            store.userScore.value![index];
                                        return ranker == store.myRank.value
                                            ? const SizedBox.shrink()
                                            : RankerCard(ranker: ranker);
                                      },
                                    ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PodiumEntry extends StatelessWidget {
  const _PodiumEntry({
    required this.avatar,
    required this.avatarWidth,
    required this.score,
    required this.fullname,
    this.nameWidth = 90,
  });

  final String avatar;
  final double avatarWidth;
  final String score;
  final String fullname;
  final double nameWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(avatar, width: avatarWidth),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: Colors.white.withOpacity(0.3),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
            child: Text(
              score,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: nameWidth,
          child: Text(
            fullname,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class RankerCard extends StatelessWidget {
  final UserScore ranker;

  const RankerCard({super.key, required this.ranker});

  @override
  Widget build(BuildContext context) {
    final bool isMine = ranker.isMyRank;
    final Color primaryText =
        isMine ? Colors.white : AppTokens.ink(context);
    final Color secondaryText = isMine
        ? Colors.white.withOpacity(0.85)
        : AppTokens.muted(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        gradient: isMine
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTokens.brand, AppTokens.brand2],
              )
            : null,
        color: isMine ? null : AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border:
            isMine ? null : Border.all(color: AppTokens.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: Image.asset(
                      "assets/image/rank_bg1.png",
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.transparent,
                    child: Text(
                      "${ranker.rank}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xffFFEB8A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ranker.fullname,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                    ),
                    if (ranker.time != '') ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(ranker.time),
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryText,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s12,
                  vertical: AppTokens.s4,
                ),
                decoration: BoxDecoration(
                  color: isMine
                      ? Colors.white.withOpacity(0.22)
                      : AppTokens.surface2(context),
                  borderRadius: BorderRadius.circular(AppTokens.r16),
                ),
                child: Text(
                  ranker.score.toString(),
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Divider(
            color: isMine
                ? Colors.white.withOpacity(0.3)
                : AppTokens.border(context),
            thickness: 1.2,
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem("assets/image/rank_correct.svg",
                  ranker.correct.toString(), 'Correct', context),
              _buildStatItem("assets/image/rank_incorrect.svg",
                  ranker.inCorrect.toString(), 'Incorrect', context),
              _buildStatItem("assets/image/rank_skip.svg",
                  ranker.skipped.toString(), 'Skipped', context),
              _buildStatItem("assets/image/rank_attemp.svg",
                  ranker.isAttemptcount.toString(), 'Attempt', context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String icon, String count, String label, BuildContext context) {
    final bool isMine = ranker.isMyRank;
    final Color textColor =
        isMine ? Colors.white : AppTokens.ink(context);
    return Row(
      children: [
        SvgPicture.asset(
          icon,
          width: 22,
          color: isMine ? Colors.white : AppTokens.accent(context),
        ),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textColor,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getOrdinalSuffix(int rank) {
    if (rank % 10 == 1 && rank % 100 != 11) {
      return 'st';
    } else if (rank % 10 == 2 && rank % 100 != 12) {
      return 'nd';
    } else if (rank % 10 == 3 && rank % 100 != 13) {
      return 'rd';
    }
    return 'th';
  }

  String _formatTime(String time) {
    List<String> parts = time.split(":");

    if (parts.length < 2) {
      return "Invalid time format";
    }

    int hours = int.tryParse(parts[0]) ?? 0;
    int minutes = int.tryParse(parts[1]) ?? 0;

    if (hours > 0 && minutes > 0) {
      return "$hours hour${hours > 1 ? 's' : ''} $minutes min";
    } else if (hours > 0) {
      return "$hours hour${hours > 1 ? 's' : ''}";
    } else if (minutes > 0) {
      return "$minutes min";
    } else {
      return "0 min";
    }
  }
}
