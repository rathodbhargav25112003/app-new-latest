import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/modules/dashboard/home_screen.dart';
import 'package:shusruta_lms/modules/login/store/login_store.dart';
import 'package:shusruta_lms/modules/masterTest/leaderboard_category_screen.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/new_subscription.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/select_subscription_plan.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/store/subscription_plan_store.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/haptics.dart';
import '../../helpers/styles.dart';
import '../../helpers/app_tokens.dart';
import '../cortex/cortex_home_screen.dart';
import '../cortex/store/cortex_store.dart';
import '../progress/progress_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool trial;
  const DashboardScreen({super.key, required this.trial});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments;

    if (arguments != null && arguments is Map<String, dynamic>) {
      return CupertinoPageRoute(builder: (_) => DashboardScreen(trial: arguments['trial']));
    } else {
      return CupertinoPageRoute(builder: (_) => const DashboardScreen(trial: false));
    }
  }
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  int _backButtonPressCount = 0;
  DateTime? currentDateTime;
  DateTime? pastDateTime;

  final List _bottomText = [
    'Home',
    'Subscribe',
    'Progress',
    'Leaderboard',
    'Cortex.ai',
    // 'Menu',
  ];

  final List _bottomImage = [
    SvgPicture.asset("assets/image/home.svg", height: 20),
    SvgPicture.asset("assets/image/subscribe1Icon.svg", height: 20),
    SvgPicture.asset("assets/image/progress1Icon.svg", height: 20),
    SvgPicture.asset("assets/image/leaderboardIcon.svg", height: 20, color: const Color(0xFF0048D0)),
    if (!Platform.isMacOS) ...[
      Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFF0048D0)),
        ),
        child: Text(
          "AI",
          style: interBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: const Color(0xFF0048D0)),
        ),
      ),
    ],
    // SvgPicture.asset("assets/image/menu.svg"),
  ];

  final List _bottomImageDisable = [
    SvgPicture.asset("assets/image/home1.svg", height: 20),
    SvgPicture.asset("assets/image/subscribeIcon.svg", height: 20),
    SvgPicture.asset("assets/image/progressBTIcon.svg", height: 20),
    SvgPicture.asset("assets/image/leaderboardIcon.svg", height: 20),
    if (!Platform.isMacOS) ...[
      Container(
        width: 20,
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFF000000)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "AI",
              style: interBold.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: const Color(0xFF000000),
              ),
            ),
          ],
        ),
      ),
    ],
    // SvgPicture.asset("assets/image/menu1.svg"),
  ];

  Future<bool> _handleBackPressed() async {
    if (_backButtonPressCount == 1) {
      SystemNavigator.pop();
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Press back again to exit')));
      _backButtonPressCount++;
      Future.delayed(const Duration(seconds: 2), () {
        _backButtonPressCount = 0;
      });
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    // Commented out - free trial is no longer automatically activated during registration
    // widget.trial ? trialAlertBox(context) : null;
    debugPrint("widget.trial:${widget.trial}");
  }

  Future<void> trialAlertBox(BuildContext context) async {
    currentDateTime = DateTime.now();

    // Calculate 72 hours ago
    pastDateTime = currentDateTime?.add(const Duration(hours: 72));
    String formattedPastDateTime = DateFormat('dd-MM-yyyy hh:mm a').format(pastDateTime ?? DateTime.now());
    await Future.delayed(const Duration(milliseconds: 50));
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: Dimensions.PADDING_SIZE_DEFAULT),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Sushruta LGS! 🌟',
                    textAlign: TextAlign.start,
                    style: interBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                  Text(
                    'Your Free Trial has been automatically activated! Enjoy access for 72 hours.',
                    textAlign: TextAlign.start,
                    style: interBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                  Text(
                    'Your Free Trial will Expire on $formattedPastDateTime Explore all courses and features.',
                    textAlign: TextAlign.start,
                    style: interBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Happy Learning!',
                      textAlign: TextAlign.center,
                      style: interBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          content: Image.asset("assets/image/celebrate.png"),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: AppColors.primaryColor),
              child: Center(
                child: Text(
                  'Ok',
                  style: interRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginStore = Provider.of<LoginStore>(context, listen: false);
    // Build current tab screens reactively based on isInAPurchases & platform
    // When IAP is enabled on macOS, show plan selection screen directly on 2nd tab
    final List _screens = [
      HomeScreen(scaffoldKey: _scaffoldKey),
      Observer(
        builder: (_) {
          final bool isIAPEnabled = loginStore.settingsData.value?.isInAPurchases == true;
          if (isIAPEnabled && (Platform.isMacOS || Platform.isIOS)) {
            return MultiProvider(
              providers: [
                Provider<SubscriptionPlanStore>(create: (_) => SubscriptionPlanStore()),
                Provider<LoginStore>.value(value: loginStore),
              ],
              child: const SelectSubscriptionPlan(categoryId: '', subcategoryId: ''),
            );
          }
          return NewSubscription(showBackButton: false);
        },
      ),
      const ProgressScreen(),
      LeaderBoardCategoryScreen(isHome: true),
      if (!Platform.isMacOS) ...[
        Provider<CortexStore>(create: (_) => CortexStore(), child: const CortexHomeScreen()),
      ],
    ];
    return WillPopScope(
      onWillPop: _handleBackPressed,
      // child: Scaffold(
      //   key: _scaffoldKey,
      //   backgroundColor: AppColors.white,
      //   body: _screens[_currentIndex],
      //   bottomNavigationBar: BottomNavigationBar(
      //     elevation: 10,
      //     selectedFontSize: 14,
      //     unselectedFontSize: 14,
      //     selectedItemColor: Theme.of(context).primaryColor,
      //     unselectedItemColor: Theme.of(context).disabledColor,
      //     selectedLabelStyle: interRegular.copyWith(
      //       fontSize: Dimensions.fontSizeExtraSmall,
      //       color: Theme.of(context).primaryColor
      //     ),
      //     unselectedLabelStyle: interRegular.copyWith(
      //         fontSize: Dimensions.fontSizeExtraSmall,
      //         color: Theme.of(context).disabledColor
      //     ),
      //     type: BottomNavigationBarType.fixed,
      //     iconSize: 28,
      //     backgroundColor: AppColors.white,
      //     currentIndex: _currentIndex,
      //     onTap: (int index) {
      //       setState(() {
      //         _currentIndex = index;
      //       });
      //     },
      //     items: const [
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.home),
      //         label: 'Home',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.insert_chart_sharp),
      //         label: 'Solutions',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.bookmarks),
      //         label: 'Bookmarks',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.chat),
      //         label: 'Ask Question',
      //       ),
      //     ],
      //   )
      // ),
      child: Scaffold(
        endDrawer: Drawer(
          backgroundColor: ThemeManager.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Observer(
            builder: (_) {
              return Container(
                color: ThemeManager.white,
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    // Light/Dark Mode Toggle
                    Container(
                      margin: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xffE4E9F2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (ThemeManager.currentTheme != AppTheme.Light) {
                                  Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
                                }
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: ThemeManager.currentTheme == AppTheme.Light
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Image.asset("assets/image/light_d.png", width: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'Light Mode',
                                        style: interRegular.copyWith(
                                          fontSize: 12,
                                          color: ThemeManager.currentTheme == AppTheme.Light
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (ThemeManager.currentTheme != AppTheme.Dark) {
                                  Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
                                }
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: ThemeManager.currentTheme == AppTheme.Dark
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Image.asset("assets/image/dark_d.png", width: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'Dark Mode',
                                        style: interRegular.copyWith(
                                          fontSize: 12,
                                          color: ThemeManager.currentTheme == AppTheme.Dark
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Color(0xffE4E9F2), thickness: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Column(
                            children: [
                              SizedBox(height: 20),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, Routes.reviewQueueV3);
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.repeat),
                                    SizedBox(width: 16),
                                    Text(
                                      "Review Queue",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: ThemeManager.black.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 25),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, Routes.studyPlan);
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_month),
                                    SizedBox(width: 16),
                                    Text(
                                      "Study Plan",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: ThemeManager.black.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 25),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, Routes.scheduledSessions);
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule),
                                    SizedBox(width: 16),
                                    Text(
                                      "Scheduled Sessions",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: ThemeManager.black.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 25),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, Routes.performanceTrends);
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.trending_up),
                                    SizedBox(width: 16),
                                    Text(
                                      "Performance Trends",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: ThemeManager.black.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 25),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, Routes.readingSettings);
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.tune),
                                    SizedBox(width: 16),
                                    Text(
                                      "Reading Preferences",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: ThemeManager.black.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 25),
                              Divider(color: Color(0xffE4E9F2), thickness: 1),
                              SizedBox(height: 25),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, Routes.blogScreen);
                                },
                                child: Row(
                                  children: [
                                    Image.asset("assets/image/blog_d.png", width: 18),
                                    SizedBox(width: 16),
                                    Text(
                                      "Blogs & Testimonials",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: ThemeManager.black.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 25),
                              GestureDetector(
                                onTap: () {
                                  _launchURL("https://sushrutalgs.in/privacy-policy");
                                },
                                child: Row(
                                  children: [
                                    Image.asset("assets/image/privacy_d.png", width: 18),
                                    SizedBox(width: 16),
                                    Text(
                                      "Privacy Policy",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: ThemeManager.black.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 25),
                              // InkWell(
                              //   onTap: () {
                              //     Navigator.of(context).pushNamed(Routes.newSubscription);
                              //   },
                              //   child: Row(
                              //     children: [
                              //       // const SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                              //       SizedBox(
                              //           height: 21,
                              //           width: 22,
                              //           child: SvgPicture.asset("assets/image/preparefrom.svg")),
                              //       const SizedBox(
                              //         width: 15,
                              //       ),
                              //       Text(
                              //         "Subscription Plans",
                              //         style: interRegular.copyWith(
                              //             fontSize: Dimensions.fontSizeDefault,
                              //             color: ThemeManager.black.withOpacity(0.6),
                              //             fontWeight: FontWeight.w400),
                              //       )
                              //     ],
                              //   ),
                              // ),
                              // const SizedBox(
                              //   height: Dimensions.PADDING_SIZE_LARGE,
                              // ),
                              GestureDetector(
                                onTap: () {
                                  _launchURL("https://sushrutalgs.in/refund-policy");
                                },
                                child: Row(
                                  children: [
                                    Image.asset("assets/image/refund_d.png", width: 18),
                                    SizedBox(width: 16),
                                    Text(
                                      "Refund Policy",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: ThemeManager.black.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 25),
                              // Terms and Conditions
                              GestureDetector(
                                onTap: () {
                                  _launchURL("https://sushrutalgs.in/terms-%26-conditions");
                                },
                                child: Row(
                                  children: [
                                    Image.asset("assets/image/terms_d.png", width: 18),
                                    SizedBox(width: 16),
                                    Text(
                                      "Terms and Conditions",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: ThemeManager.black.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 25),

                              // Contact Information
                              GestureDetector(
                                onTap: () => _launchWhatsApp("${loginStore.settingsData.value?.phone}"),
                                child: Row(
                                  children: [
                                    Image.asset("assets/image/wp_d.png", height: 24),
                                    SizedBox(width: 16),
                                    Text(
                                      "${loginStore.settingsData.value?.phone}",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: ThemeManager.black.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 25),
                              GestureDetector(
                                onTap: () => _launchEmail("${loginStore.settingsData.value?.email}"),
                                child: Row(
                                  children: [
                                    Image.asset("assets/image/email_d.png", height: 24),
                                    SizedBox(width: 16),
                                    Text(
                                      "${loginStore.settingsData.value?.email}",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: ThemeManager.black.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // const SizedBox(
                              //   height: 25,
                              // ),
                              // GestureDetector(
                              //   onTap: () {
                              //     Navigator.pushNamed(context, Routes.deleteHistoryScreen);
                              //   },
                              //   child: Row(
                              //     children: [
                              //       Icon(Icons.delete_outline, color: ThemeManager.black.withOpacity(0.6), size: 22),
                              //       SizedBox(width: 16),
                              //       Text(
                              //         "Delete History",
                              //         style: interRegular.copyWith(
                              //           fontSize: Dimensions.fontSizeDefault,
                              //           color: ThemeManager.black.withOpacity(0.6),
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        key: _scaffoldKey,
        backgroundColor: ThemeManager.homeBackground,
        body: _screens[_currentIndex],
        // Apple-style tab bar — soft hairline divider on top, active
        // tab pill with light accent background, larger labels,
        // generous tap targets. Mobile keeps the legacy rounded
        // top corners; desktop sits flush.
        bottomNavigationBar: Container(
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsets.only(
            top: 6,
            bottom: MediaQuery.of(context).padding.bottom > 0 ? 4 : 8,
            left: 6,
            right: 6,
          ),
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular((Platform.isMacOS || Platform.isWindows) ? 0 : 24),
              topRight: Radius.circular((Platform.isMacOS || Platform.isWindows) ? 0 : 24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: AppTokens.border(context).withOpacity(0.6),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(
                !Platform.isMacOS ? 5 : 2,
                (index) {
                  final isActive = _currentIndex == index;
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        if (_currentIndex != index) Haptics.selection();
                        setState(() => _currentIndex = index);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTokens.accentSoft(context)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            isActive ? _bottomImage[index] : _bottomImageDisable[index],
                            const SizedBox(height: 4),
                            Text(
                              _bottomText[index],
                              style: AppTokens.caption(context).copyWith(
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isActive
                                    ? AppTokens.accent(context)
                                    : AppTokens.muted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunch(emailLaunchUri.toString())) {
      await launch(emailLaunchUri.toString());
    } else {
      throw 'Could not launch email';
    }
  }

  _launchWhatsApp(String phone) async {
    final Uri whatsAppLaunchUri = Uri(scheme: 'https', host: 'wa.me', path: "91$phone");
    if (await canLaunch(whatsAppLaunchUri.toString())) {
      await launch(whatsAppLaunchUri.toString());
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  Future<void> _launchURL(String url) async {
    debugPrint('usel$url');
    // ignore: deprecated_member_use
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class MoreMenuBottomsheetContainer extends StatelessWidget {
  const MoreMenuBottomsheetContainer({super.key});

  Widget _buildMoreMenuContainer({
    required BuildContext context,
    required BoxConstraints boxConstraints,
    required Icon iconUrl,
    required String title,
  }) {
    return title != ""
        ? Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: GestureDetector(
              onTap: () {},
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: boxConstraints.maxWidth * (0.065)),
                    width: boxConstraints.maxWidth * (0.2),
                    height: boxConstraints.maxWidth * (0.2),
                    padding: const EdgeInsets.all(12.5),
                    child: iconUrl,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: boxConstraints.maxWidth * (0.3),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14.0),
                    ),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 25.0, right: 25.0, left: 25.0),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(color: Theme.of(context).colorScheme.onSurface, height: 50),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: SingleChildScrollView(
                    child: Wrap(
                      children: List.generate(3, (index) {
                        return _buildMoreMenuContainer(
                          context: context,
                          boxConstraints: boxConstraints,
                          iconUrl: const Icon(Icons.home),
                          title: "titleToSend",
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
