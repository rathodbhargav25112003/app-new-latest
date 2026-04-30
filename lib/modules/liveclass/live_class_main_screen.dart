// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:overlay_pop_up/overlay_pop_up.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/liveclass/live_classes.dart';
import 'package:shusruta_lms/modules/liveclass/live_classes_upcoming.dart';
import 'package:shusruta_lms/modules/liveclass/store/live_class_main_screen_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';

/// Live classes main screen — redesigned with AppTokens. A tabbed shell that
/// swaps between the live and upcoming lists while keeping the legacy
/// MeetingStore fetches, OverlayPopUp.isActive status check, and Routes
/// .dashboard back-button behaviour fully intact.
class LiveClassMainScreen extends StatefulWidget {
  const LiveClassMainScreen({super.key});

  @override
  State<LiveClassMainScreen> createState() => _LiveClassMainScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const LiveClassMainScreen(),
    );
  }
}

class _LiveClassMainScreenState extends State<LiveClassMainScreen> {
  bool isActivex = false;
  int _selectedIndex = 0;

  late MeetingStore meetingStore;

  @override
  void initState() {
    super.initState();
    overlayStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    meetingStore = Provider.of<MeetingStore>(context);
    meetingStore.fetchMeetings();
    meetingStore.fetchUpComingMeeting();
  }

  Future<void> overlayStatus() async {
    isActivex = await OverlayPopUp.isActive();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isWindows || Platform.isMacOS;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        body: Column(
          children: [
            _Header(
              title: _selectedIndex == 0 ? "Live Classes" : "Upcoming Classes",
              onBack: () => Navigator.of(context).pushNamed(Routes.dashboard),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTokens.scaffold(context),
                  borderRadius: isDesktop
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r28),
                          topRight: Radius.circular(AppTokens.r28),
                        ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppTokens.s12),
                    _SegmentedTabs(
                      labels: const ["Live", "Upcoming"],
                      selectedIndex: _selectedIndex,
                      onChanged: (i) {
                        setState(() {
                          _selectedIndex = i;
                        });
                      },
                    ),
                    const SizedBox(height: AppTokens.s4),
                    const Expanded(
                      child: TabBarView(
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          LiveClass(),
                          LiveClassesUpcoming(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//                        Primitives
// ============================================================

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTokens.s8,
        MediaQuery.of(context).padding.top + AppTokens.s12,
        AppTokens.s16,
        AppTokens.s20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTokens.brand.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white.withOpacity(0.16),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.titleMd(context).copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
      child: Container(
        padding: const EdgeInsets.all(AppTokens.s4),
        decoration: BoxDecoration(
          color: AppTokens.surface2(context),
          borderRadius: AppTokens.radius12,
          border: Border.all(color: AppTokens.border(context)),
        ),
        child: TabBar(
          onTap: onChanged,
          dividerColor: Colors.transparent,
          labelPadding: EdgeInsets.zero,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppTokens.radius8,
            boxShadow: AppTokens.shadow1(context),
          ),
          indicatorPadding: EdgeInsets.zero,
          labelColor: Colors.white,
          unselectedLabelColor: AppTokens.ink2(context),
          labelStyle: AppTokens.titleSm(context),
          unselectedLabelStyle: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
          splashBorderRadius: AppTokens.radius8,
          overlayColor:
              MaterialStateProperty.all(AppTokens.accentSoft(context)),
          tabs: [
            for (final l in labels)
              Tab(
                height: 36,
                child: Text(l),
              ),
          ],
        ),
      ),
    );
  }
}
