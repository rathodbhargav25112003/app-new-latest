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
import 'package:shusruta_lms/modules/widgets/subscription_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../login/store/login_store.dart';
import '../widgets/custom_bottom_sheet.dart';
import '../widgets/custom_button.dart';
import '../widgets/no_internet_connection.dart';

/// INI SS subscription group list for hardcopy bundle flow — redesigned with
/// AppTokens. Mirrors the NEET SS variant but calls
/// `store.onRegisterApiCall(context, false, true)` and shows the first
/// duration's price on the card. Constructor, static route, TabController +
/// SingleTickerProviderStateMixin, Provider wiring, and all navigation
/// targets preserved.
class IniGroupSubscriptionListWithHardCopy extends StatefulWidget {
  const IniGroupSubscriptionListWithHardCopy({super.key});

  @override
  State<IniGroupSubscriptionListWithHardCopy> createState() =>
      _IniGroupSubscriptionListWithHardCopyState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const IniGroupSubscriptionListWithHardCopy(),
    );
  }
}

class _IniGroupSubscriptionListWithHardCopyState
    extends State<IniGroupSubscriptionListWithHardCopy>
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
  int currentIndex = 0;

  final List<String> checkItems = [
    'All',
    'Live Classes',
    'Mock Exams',
    "Only MCQ's",
    'Only Videos',
    'Only Notes',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this, initialIndex: tabIndex);
    _controller?.addListener(() {
      setState(() {
        tabIndex = _controller?.index ?? 0;
      });
    });
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    store.onRegisterApiCall(context, false, true);
    isLogged = _checkIsLoggedIn();
    isLogged!.then((value) {
      setState(() {
        loggedIn = value;
      });
    });
    _settingsData();
  }

  Future<bool> _checkIsLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? loggedInEmail = prefs.getBool('isloggedInEmail');
    bool? signInGoogle = prefs.getBool('isSignInGoogle');
    bool? loggedInWt = prefs.getBool('isLoggedInWt');
    if (loggedInEmail == true || signInGoogle == true || loggedInWt == true) {
      return loggedIn = true;
    } else {
      return loggedIn = false;
    }
  }

  Future<void> _settingsData() async {
    final store = Provider.of<LoginStore>(context, listen: false);
    await store.onGetSettingsData();
  }

  List<SubscriptionModel?> _applyFilter(List<SubscriptionModel?> list) {
    if (currentIndex == 0) return list;
    return list.where((element) {
      return (currentIndex == 1 && element?.liveClass == true) ||
          (currentIndex == 2 && element?.mockExam == true) ||
          (currentIndex == 3 && element?.exam == true) ||
          (currentIndex == 4 && element?.videos == true) ||
          (currentIndex == 4 && element?.notes == true);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SubscriptionStore>(context);
    // ignore: unused_local_variable
    final loginStore = Provider.of<LoginStore>(context, listen: false);
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed(Routes.dashboard);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        body: Column(
          children: [
            _Header(
              loggedIn: loggedIn,
              onBack: () => Navigator.of(context).pushNamed(Routes.dashboard),
              onLogin: () => Navigator.of(context).pushNamed(Routes.login),
            ),
            _FilterPills(
              items: checkItems,
              currentIndex: currentIndex,
              onChanged: (i) => setState(() => currentIndex = i),
            ),
            Expanded(
              child: Observer(
                builder: (_) {
                  if (store.subscription.isEmpty) {
                    return _EmptyState();
                  }
                  if (store.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTokens.accent(context),
                      ),
                    );
                  }
                  if (!store.isConnected) {
                    return const NoInternetScreen();
                  }
                  final filtered = _applyFilter(store.subscription)
                    ..sort((a, b) {
                      final aOrder = a?.order ?? 0;
                      final bOrder = b?.order ?? 0;
                      return aOrder.compareTo(bOrder);
                    });
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s16,
                      AppTokens.s8,
                      AppTokens.s16,
                      AppTokens.s24,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (BuildContext context, int index) {
                      final sub = filtered[index];
                      if (sub?.duration?.any((e) => e.price == 0) ?? false) {
                        return const SizedBox.shrink();
                      }
                      final firstPrice =
                          sub?.duration != null && sub!.duration!.isNotEmpty
                              ? sub.duration![0].price
                              : null;
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTokens.s12,
                        ),
                        child: _SubscriptionCard(
                          planName: sub?.plan_name ?? '',
                          firstDurationPrice: firstPrice,
                          benefits: sub?.benifit ?? [],
                          activeUsers: sub?.active_user?.toString() ?? '0',
                          onGetStarted: () {
                            if (Platform.isMacOS || Platform.isWindows) {
                              showDialog(
                                context: context,
                                builder: (_) => SubscriptionDialog(),
                              );
                            } else {
                              Navigator.of(context).pushNamed(
                                Routes.hardCopySubscriptionDetailPlan,
                                arguments: {
                                  'subscription': store.subscription[index],
                                  'store': store,
                                },
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
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
    String? token = prefs.getString('token');

    final url = 'https://app.sushrutalgs.in/subscription?token=$token';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final bool loggedIn;
  final VoidCallback onBack;
  final VoidCallback onLogin;
  const _Header({
    required this.loggedIn,
    required this.onBack,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTokens.brand.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s12,
            AppTokens.s8,
            AppTokens.s12,
            AppTokens.s16,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.18),
                borderRadius: AppTokens.radius12,
                child: InkWell(
                  borderRadius: AppTokens.radius12,
                  onTap: onBack,
                  child: const SizedBox(
                    height: 40,
                    width: 40,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'INI SS',
                      style: AppTokens.overline(context).copyWith(
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Subscription Plans',
                      style: AppTokens.titleLg(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!loggedIn)
                Material(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: AppTokens.radius12,
                  child: InkWell(
                    borderRadius: AppTokens.radius12,
                    onTap: onLogin,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.s12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Login',
                            style: AppTokens.caption(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
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

// ---------------------------------------------------------------------------
// Filter pills
// ---------------------------------------------------------------------------

class _FilterPills extends StatelessWidget {
  final List<String> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;
  const _FilterPills({
    required this.items,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16,
          vertical: AppTokens.s8,
        ),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.s8),
        itemBuilder: (_, index) {
          final selected = index == currentIndex;
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTokens.accent(context)
                      : AppTokens.surface(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected
                        ? AppTokens.accent(context)
                        : AppTokens.border(context),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  items[index],
                  style: AppTokens.caption(context).copyWith(
                    color: selected ? Colors.white : AppTokens.ink(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subscription card
// ---------------------------------------------------------------------------

class _SubscriptionCard extends StatelessWidget {
  final String planName;
  final num? firstDurationPrice;
  final List<String> benefits;
  final String activeUsers;
  final VoidCallback onGetStarted;

  const _SubscriptionCard({
    required this.planName,
    required this.firstDurationPrice,
    required this.benefits,
    required this.activeUsers,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1F29), Color(0xFF2A2F3D)],
        ),
        borderRadius: AppTokens.radius20,
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Text(
                  planName,
                  style: AppTokens.titleMd(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (firstDurationPrice != null) ...[
            const SizedBox(height: AppTokens.s12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹$firstDurationPrice',
                  style: AppTokens.displayLg(context).copyWith(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    'onwards',
                    style: AppTokens.caption(context).copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppTokens.s12),
          ...benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: AppTokens.accent(context),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: Text(
                        b,
                        style: AppTokens.body(context).copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: AppTokens.s12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: onGetStarted,
                child: Container(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: AppTokens.titleSm(context).copyWith(
                          color: AppTokens.brand,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppTokens.brand,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          Align(
            alignment: Alignment.center,
            child: Text(
              '$activeUsers Active Students',
              style: AppTokens.caption(context).copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 44,
                color: AppTokens.accent(context),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'No Subscription Plans Found',
              style: AppTokens.titleMd(context),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              'Please check back soon for new offers.',
              style: AppTokens.body(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomBottomSheet — preserved for external references
// ---------------------------------------------------------------------------

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
  final List<String> checkItems = [
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
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTokens.r28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Filter',
            style: AppTokens.titleMd(context),
          ),
          const SizedBox(height: AppTokens.s12),
          Expanded(
            child: ListView.builder(
              itemCount: widget.checkboxItems.length,
              itemBuilder: (context, index) {
                final item = widget.checkboxItems[index];
                final label =
                    index < checkItems.length ? checkItems[index] : item;
                return CheckboxListTile(
                  title: Text(label, style: AppTokens.body(context)),
                  value: _selectedValues.contains(item),
                  activeColor: AppTokens.accent(context),
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
              ElevatedButton(
                onPressed: () {
                  if (_selectedValues.isNotEmpty) {
                    Navigator.pop(context, _selectedValues.join(','));
                  } else {
                    Navigator.pop(context, '');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.accent(context),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTokens.radius12,
                  ),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
