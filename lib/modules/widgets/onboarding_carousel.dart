// ════════════════════════════════════════════════════════════════════
// OnboardingCarousel — first-launch 3-card swipeable intro
// ════════════════════════════════════════════════════════════════════
//
// Shows once per install. Three cards:
//   1. "Adaptive practice"  — heatmap weakness + Sonnet why-wrong
//   2. "Doubt chat with seniors" — faculty doubt + Cortex AI
//   3. "Track your prep"    — daily streak + planner
//
// Persisted via SharedPreferences key `onboarded_v1`. Bumping to v2
// (or any new key) re-shows for everyone — useful for roll-outs that
// add a new feature card.
//
// Apple-style: sentence-case copy, hairline page indicator, generous
// 24pt padding, system-font typography via AppTokens.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/app_tokens.dart';
import '../../app/routes.dart';

class OnboardingCarousel extends StatefulWidget {
  const OnboardingCarousel({super.key});

  /// Shows the carousel only when SharedPreferences['onboarded_v1']
  /// is false / absent. Caller should invoke from splash AFTER the
  /// first-frame paint.
  static Future<void> showIfFirstRun(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('onboarded_v1') == true) return;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const OnboardingCarousel(),
      ),
    );
  }

  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  final PageController _ctrl = PageController();
  int _idx = 0;

  static const _slides = [
    _Slide(
      icon: Icons.insights_rounded,
      title: 'Adaptive practice',
      body: 'Topic weakness heatmap + Sonnet "why wrong?" so every wrong answer becomes a study session.',
    ),
    _Slide(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Doubt chat',
      body: 'Multi-turn AI doubt chat plus a direct line to senior faculty for the questions that actually need a human.',
    ),
    _Slide(
      icon: Icons.local_fire_department_rounded,
      title: 'Track your prep',
      body: 'Daily streaks, mock-rank trajectory, and a planner that adapts when you fall behind.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded_v1', true);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.login,
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _idx == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('Skip',
                    style: AppTokens.body(context).copyWith(
                      color: AppTokens.muted(context),
                    )),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _idx = i),
                itemBuilder: (_, i) => _slides[i].build(context),
              ),
            ),
            // Hairline pager indicator — Apple style.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: active ? 22 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: active
                          ? AppTokens.accent(context)
                          : AppTokens.border(context),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  if (_idx > 0)
                    TextButton(
                      onPressed: () => _ctrl.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTokens.accent(context),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppTokens.radius16,
                      ),
                    ),
                    onPressed: isLast
                        ? _finish
                        : () => _ctrl.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            ),
                    child: Text(isLast ? 'Get started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String body;
  const _Slide({required this.icon, required this.title, required this.body});

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              borderRadius: AppTokens.radius16,
            ),
            child: Icon(icon, size: 30, color: AppTokens.accent(context)),
          ),
          const SizedBox(height: 28),
          Text(title, style: AppTokens.displayMd(context)),
          const SizedBox(height: 12),
          Text(body,
              style: AppTokens.bodyLg(context).copyWith(
                color: AppTokens.ink2(context),
                height: 1.5,
              )),
        ],
      ),
    );
  }
}
