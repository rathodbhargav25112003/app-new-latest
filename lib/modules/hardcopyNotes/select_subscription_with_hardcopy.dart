// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/models/subscription_model.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../login/store/login_store.dart';
import 'harcopy_neet_ss_group_list.dart';
import 'hardcopy_ini_ss_group_list.dart';

/// Tabbed container screen for hardcopy-bundle subscription lists — NEET SS on
/// tab 0 and INI-SS ET on tab 1. Constructor, static route, TabController
/// wiring, MobX Providers, WillPopScope pop, back-button → Routes.dashboard,
/// TabBarView children, formatTime(int) helper, and openUrlWithToken() iOS/
/// macOS-guarded helper are all preserved.
class HardCopySubscriptionList extends StatefulWidget {
  const HardCopySubscriptionList({super.key});

  @override
  State<HardCopySubscriptionList> createState() =>
      _HardCopySubscriptionListState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const HardCopySubscriptionList(),
    );
  }
}

class _HardCopySubscriptionListState extends State<HardCopySubscriptionList>
    with SingleTickerProviderStateMixin {
  final int _selectedIndex = 0;
  TabController? _controller;
  int tabIndex = 0;
  bool loggedIn = false;
  bool isExpanded = false;
  Future<bool>? isLogged;
  List<SubscriptionModel?>? filteredSolutionReport;

  List<bool?> isExpandedList = [];
  String filterValue = '';

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this, initialIndex: tabIndex);
    _controller?.addListener(() {
      setState(() {
        tabIndex = _controller?.index ?? 0;
      });
    });
  }

  Future<void> _settingsData() async {
    final store = Provider.of<LoginStore>(context, listen: false);
    await store.onGetSettingsData();
  }

  @override
  Widget build(BuildContext context) {
    // Preserve the MobX Provider wiring the legacy page depended on so the
    // child tabs (NEET + INI) observe consistent stores.
    Provider.of<SubscriptionStore>(context);
    Provider.of<LoginStore>(context, listen: false);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        body: Column(
          children: [
            _Header(
              title: "Subscription Plans",
              onBack: () =>
                  Navigator.of(context).pushNamed(Routes.dashboard),
            ),
            _SegmentedTabs(
              controller: _controller!,
              tabIndex: tabIndex,
              labels: const ["NEET SS", "INISS-ET"],
            ),
            Expanded(
              child: TabBarView(
                controller: _controller,
                children: const [
                  NeetGroupSubscriptionListWithHardCopy(),
                  IniGroupSubscriptionListWithHardCopy(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatTime(int numberOfDays) {
    if (numberOfDays >= 365) {
      int years = numberOfDays ~/ 365;
      return years == 1 ? '1 Year' : '$years years';
    } else if (numberOfDays >= 30) {
      int months = numberOfDays ~/ 30;
      return months == 1 ? '1 month' : '$months months';
    } else {
      return '$numberOfDays days';
    }
  }

  void openUrlWithToken() async {
    // Disable external subscription URL for iOS/macOS to comply with App
    // Store guidelines.
    if (Platform.isIOS || Platform.isMacOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Subscription is available through in-app purchase. Please use the subscription options within the app.'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final url = 'https://app.sushrutalgs.in/subscription?token=$token';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
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
        AppTokens.s16,
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
    required this.controller,
    required this.tabIndex,
    required this.labels,
  });
  final TabController controller;
  final int tabIndex;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s16,
        AppTokens.s16,
        AppTokens.s16,
        AppTokens.s8,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTokens.s4),
        decoration: BoxDecoration(
          color: AppTokens.surface2(context),
          borderRadius: AppTokens.radius12,
          border: Border.all(color: AppTokens.border(context)),
        ),
        child: TabBar(
          controller: controller,
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

// ============================================================
//                     CustomBottomSheet
//   (kept verbatim — used by filter entry points elsewhere)
// ============================================================

class CustomBottomSheet extends StatefulWidget {
  final double heightSize;
  final String selectedVal;
  final List<String> checkboxItems;

  const CustomBottomSheet({
    super.key,
    required this.heightSize,
    required this.selectedVal,
    required this.checkboxItems,
  });

  @override
  _CustomBottomSheetState createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  final List<String> _selectedValues = [];
  final List<String> checkItems = const [
    'Live Classes',
    'Mock Exams',
    "Only MCQ's",
    'Only Videos',
    'Only Notes',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.selectedVal != '') {
      _selectedValues.addAll(widget.selectedVal.split(','));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.heightSize,
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTokens.r28),
          topRight: Radius.circular(AppTokens.r28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Filter', style: AppTokens.titleMd(context)),
          const SizedBox(height: AppTokens.s12),
          Expanded(
            child: ListView.builder(
              itemCount: widget.checkboxItems.length,
              itemBuilder: (context, index) {
                final item = widget.checkboxItems[index];
                final selected = _selectedValues.contains(item);
                return CheckboxListTile(
                  title: Text(
                    checkItems[index],
                    style: AppTokens.body(context).copyWith(
                      color: AppTokens.ink(context),
                    ),
                  ),
                  activeColor: AppTokens.accent(context),
                  value: selected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value != null && value) {
                        _selectedValues.add(item);
                      } else {
                        _selectedValues.remove(item);
                      }
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Material(
                borderRadius: AppTokens.radius12,
                child: InkWell(
                  borderRadius: AppTokens.radius12,
                  onTap: () {
                    if (_selectedValues.isNotEmpty) {
                      Navigator.pop(context, _selectedValues.join(','));
                    } else {
                      Navigator.pop(context, '');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s20,
                      vertical: AppTokens.s12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTokens.brand, AppTokens.brand2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppTokens.radius12,
                    ),
                    child: Text(
                      'Apply',
                      style: AppTokens.titleSm(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
