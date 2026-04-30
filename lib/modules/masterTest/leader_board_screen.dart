// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names

import 'package:flutter/material.dart';

import '../../helpers/app_tokens.dart';

/// Demo leaderboard screen — redesigned with AppTokens. Preserves the
/// stateless class surface (no const ctor — matches original), the
/// public `myRank` int field, the `leaderboard` list shape, and the
/// two public helpers `buildRankCard(rankInfo, {isWinner})` and
/// `buildRankTile(rankInfo, isMyRank)` with identical signatures.
class LeaderboardScreen extends StatelessWidget {
  LeaderboardScreen({super.key});

  final int myRank = 16;

  final List<Map<String, dynamic>> leaderboard = [
    {"name": "Anurag Kushwaha", "score": 59.05, "rank": 1},
    {"name": "Druj", "score": 53.73, "rank": 2},
    {"name": "SAK", "score": 51.05, "rank": 3},
    {"name": "User A", "score": 50.0, "rank": 4},
    {"name": "User B", "score": 48.5, "rank": 5},
    {"name": "User C", "score": 47.0, "rank": 6},
    {"name": "You", "score": 45.5, "rank": 16},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: AppTokens.titleMd(context).copyWith(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                buildRankCard(leaderboard[1], isWinner: false),
                buildRankCard(leaderboard[0], isWinner: true),
                buildRankCard(leaderboard[2], isWinner: false),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: AppTokens.s24),
              itemCount: leaderboard.length - 3,
              itemBuilder: (context, index) {
                final rankInfo = leaderboard[index + 3];
                final isMyRank = rankInfo['rank'] == myRank;
                return buildRankTile(rankInfo, isMyRank);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRankCard(Map<String, dynamic> rankInfo,
      {bool isWinner = false}) {
    return Builder(
      builder: (context) {
        final double radius = isWinner ? 38 : 28;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (isWinner)
                  const Positioned(
                    top: -22,
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: 34,
                    ),
                  ),
                Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    gradient: isWinner
                        ? const LinearGradient(
                            colors: [AppTokens.brand, AppTokens.brand2],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isWinner
                        ? null
                        : AppTokens.surface2(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isWinner
                          ? Colors.transparent
                          : AppTokens.border(context),
                    ),
                    boxShadow: isWinner
                        ? [
                            BoxShadow(
                              color: AppTokens.brand.withOpacity(0.3),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : AppTokens.shadow1(context),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    rankInfo['rank'].toString(),
                    style: AppTokens.titleMd(context).copyWith(
                      color: isWinner ? Colors.white : AppTokens.ink(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              rankInfo['name'],
              style: isWinner
                  ? AppTokens.titleSm(context)
                  : AppTokens.body(context).copyWith(
                      color: AppTokens.ink(context),
                      fontWeight: FontWeight.w600,
                    ),
            ),
            const SizedBox(height: 2),
            Text(
              "${rankInfo['score'].toStringAsFixed(2)}/80",
              style: AppTokens.caption(context),
            ),
          ],
        );
      },
    );
  }

  Widget buildRankTile(Map<String, dynamic> rankInfo, bool isMyRank) {
    return Builder(
      builder: (context) {
        return Container(
          margin: const EdgeInsets.symmetric(
            vertical: AppTokens.s4,
            horizontal: AppTokens.s16,
          ),
          padding: const EdgeInsets.all(AppTokens.s12),
          decoration: BoxDecoration(
            color: isMyRank
                ? AppTokens.accentSoft(context)
                : AppTokens.surface(context),
            borderRadius: AppTokens.radius12,
            border: Border.all(
              color: isMyRank
                  ? AppTokens.accent(context).withOpacity(0.35)
                  : AppTokens.border(context),
            ),
            boxShadow: AppTokens.shadow1(context),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isMyRank
                      ? AppTokens.accent(context)
                      : AppTokens.surface2(context),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  rankInfo['rank'].toString(),
                  style: AppTokens.titleSm(context).copyWith(
                    color: isMyRank ? Colors.white : AppTokens.ink(context),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rankInfo['name'],
                      style: AppTokens.body(context).copyWith(
                        color: AppTokens.ink(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${rankInfo['score'].toStringAsFixed(2)}/80",
                      style: AppTokens.caption(context),
                    ),
                  ],
                ),
              ),
              if (isMyRank)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s8,
                    vertical: AppTokens.s4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.accent(context),
                    borderRadius: BorderRadius.circular(64),
                  ),
                  child: Text(
                    "You",
                    style: AppTokens.caption(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
