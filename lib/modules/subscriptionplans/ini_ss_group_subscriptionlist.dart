// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, unused_field, unused_local_variable, dead_null_aware_expression, prefer_interpolation_to_compose_strings, use_build_context_synchronously, avoid_unnecessary_containers, library_private_types_in_public_api, duplicate_ignore

import 'dart:io';
import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/styles.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import '../../helpers/dimensions.dart';
import '../widgets/custom_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../login/store/login_store.dart';
import '../widgets/custom_bottom_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/no_internet_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/models/subscription_model.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';

class IniGroupSubscriptionList extends StatefulWidget {
  const IniGroupSubscriptionList({super.key});

  @override
  State<IniGroupSubscriptionList> createState() =>
      _IniGroupSubscriptionListState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const IniGroupSubscriptionList(),
    );
  }
}

class _IniGroupSubscriptionListState extends State<IniGroupSubscriptionList>
    with SingleTickerProviderStateMixin {
  final int _selectedIndex = 0;
  TabController? _controller;
  int tabIndex = 0;
  bool loggedIn = false;
  bool isExpanded = false;
  Future<bool>? isLogged;
  List<SubscriptionModel?>? filteredSolutionReport;
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
    // store.onRegisterApiCall(context,'');
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

  List<bool?> isExpandedList = [];
  String filterValue = '';
  int currentIndex = 0;
  // List<String> filterValue = [];
  List<String> checkItems = [
    'All',
    'Live Classes',
    'Mock Exams',
    "Only MCQ's",
    'Only Videos',
    'Only Notes'
  ];
  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SubscriptionStore>(context);
    final loginStore = Provider.of<LoginStore>(context, listen: false);
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed(Routes.dashboard);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          children: [
            ThemeManager.currentTheme == AppTheme.Dark
                ? const SizedBox()
                : Container(
                    decoration: BoxDecoration(
                        gradient: RadialGradient(radius: 0.8, colors: [
                      AppTokens.brand.withOpacity(0.55),
                      AppTokens.brand2.withOpacity(0),
                    ])),
                  ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: Dimensions.PADDING_SIZE_LARGE * 1.2,
                    right: Dimensions.PADDING_SIZE_LARGE * 1.2,
                    bottom: Dimensions.PADDING_SIZE_SMALL * 1.4,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                          checkItems.length,
                          (index) => Padding(
                                padding: const EdgeInsets.only(
                                    right: Dimensions.PADDING_SIZE_SMALL - 2),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      currentIndex = index;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal:
                                            Dimensions.PADDING_SIZE_DEFAULT,
                                        vertical: Dimensions
                                                .PADDING_SIZE_EXTRA_SMALL *
                                            1.2),
                                    decoration: BoxDecoration(
                                      color: currentIndex == index
                                          ? AppColors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(
                                          Dimensions.PADDING_SIZE_EXTRA_LARGE *
                                              2),
                                      border: currentIndex == index
                                          ? Border.all(color: AppColors.white)
                                          : Border.all(
                                              color: AppColors.backContainer
                                                  .withOpacity(0.5)),
                                    ),
                                    child: Text(checkItems[index],
                                        style: interRegular.copyWith(
                                          fontSize:
                                              Dimensions.fontSizeExtraSmall,
                                          color: currentIndex == index
                                              ? AppColors.black
                                              : AppColors.backContainer
                                                  .withOpacity(0.5),
                                          fontWeight: FontWeight.w500,
                                        )),
                                  ),
                                ),
                              )),
                    ),
                  ),
                ),
                loggedIn != true
                    ? Align(
                        alignment: Alignment.topRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                // Navigator.of(context).pushNamed(Routes.loginWithPass);
                                Navigator.of(context).pushNamed(Routes.login);
                              },
                              label: Icon(
                                Icons.arrow_forward_outlined,
                                color: Theme.of(context).primaryColor,
                              ),
                              icon: Text('Login or Register',
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(),
                Flexible(
                  child: Observer(
                    builder: (_) {
                      if (store.subscription.isEmpty) {
                        return const Center(
                          child: Text(
                            'No Subscription Plans Found',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return store.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                              color: AppColors.white,
                            ))
                          : store.isConnected
                              ? (Platform.isWindows || Platform.isMacOS)
                                  ? CustomDynamicHeightGridView(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 12,
                                      shrinkWrap: true,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: currentIndex == 0
                                          ? store.subscription.length
                                          : store.subscription
                                              .where((element) =>
                                                  (currentIndex == 1 &&
                                                      element?.liveClass ==
                                                          true) ||
                                                  (currentIndex == 2 &&
                                                      element?.mockExam ==
                                                          true) ||
                                                  (currentIndex == 3 &&
                                                      element?.exam == true) ||
                                                  (currentIndex == 4 &&
                                                      element?.videos ==
                                                          true) ||
                                                  (currentIndex == 4 &&
                                                      element?.notes == true))
                                              .length,
                                      builder:
                                          (BuildContext context, int index) {
                                        return buildItem(
                                            context, store, index, loginStore);
                                      },
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.only(
                                          top: Dimensions.PADDING_SIZE_DEFAULT,
                                          bottom: Dimensions
                                              .PADDING_SIZE_EXTRA_LARGE),
                                      itemCount: currentIndex == 0
                                          ? store.subscription.length
                                          : store.subscription
                                              .where((element) =>
                                                  (currentIndex == 1 &&
                                                      element?.liveClass ==
                                                          true) ||
                                                  (currentIndex == 2 &&
                                                      element?.mockExam ==
                                                          true) ||
                                                  (currentIndex == 3 &&
                                                      element?.exam == true) ||
                                                  (currentIndex == 4 &&
                                                      element?.videos ==
                                                          true) ||
                                                  (currentIndex == 4 &&
                                                      element?.notes == true))
                                              .length,
                                      shrinkWrap: true,
                                      physics: const BouncingScrollPhysics(),
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return buildItem(
                                            context, store, index, loginStore);
                                      },
                                    )
                              : const NoInternetScreen();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, SubscriptionStore store, int index,
      LoginStore loginStore) {
    // List<SubscriptionModel?> subscriptionList = store.subscription;
    List<SubscriptionModel?> subscriptionList = currentIndex == 0
        ? store.subscription
        : store.subscription
            .where((element) =>
                (currentIndex == 1 && element?.liveClass == true) ||
                (currentIndex == 2 && element?.mockExam == true) ||
                (currentIndex == 3 && element?.exam == true) ||
                (currentIndex == 4 && element?.videos == true) ||
                (currentIndex == 4 && element?.notes == true))
            .toList();

    subscriptionList.sort((a, b) {
      final aOrder = a?.order ?? 0;
      final bOrder = b?.order ?? 0;
      return aOrder.compareTo(bOrder);
    });

    // Check if the current item should be shown
    bool shouldShowItem =
        !(subscriptionList[index]?.duration?.any((e) => e.price == 0) ?? false);

    // Return an empty widget if the item should not be shown
    if (!shouldShowItem) {
      return const SizedBox.shrink();
    }

    bool isSelected = index == _selectedIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_DEFAULT),
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.PADDING_SIZE_LARGE * 1.1),
        margin: EdgeInsets.symmetric(
            horizontal: (Platform.isMacOS || Platform.isWindows)
                ? 0
                : Dimensions.PADDING_SIZE_LARGE * 1.2),
        decoration: BoxDecoration(
          color: AppColors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(13.78),
          border:
              Border.all(color: AppColors.white.withOpacity(0.3), width: 0.86),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: Dimensions.PADDING_SIZE_SMALL * 2.1,
            ),
            Text("${subscriptionList[index]?.plan_name}",
                style: interRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefaultOverLarge,
                  color: AppColors.subPlanText,
                  fontWeight: FontWeight.w700,
                )),
            // const SizedBox(
            //   height: Dimensions.PADDING_SIZE_LARGE,
            // ),
            // Text("₹ ${subscriptionList[index]?.duration?[0].price}",
            //     style: interRegular.copyWith(
            //       fontSize: Dimensions.fontSizeOverLargeLarge,
            //       color: AppColors.white,
            //       fontWeight: FontWeight.w600,
            //     )),
            const SizedBox(
              height: Dimensions.PADDING_SIZE_LARGE,
            ),
            ListView.builder(
              itemCount: subscriptionList[index]?.benifit?.length,
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int bindex) {
                String? benefits = subscriptionList[index]?.benifit![bindex];
                return Padding(
                  padding: const EdgeInsets.only(
                      bottom: Dimensions.PADDING_SIZE_SMALL),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check,
                        color: AppColors.subPlanText,
                      ),
                      const SizedBox(
                        width: Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.6,
                      ),
                      Expanded(
                        child: Text("$benefits",
                            style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: AppColors.white,
                              fontWeight: FontWeight.w400,
                            )),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(
              height: Dimensions.PADDING_SIZE_LARGE,
            ),
            InkWell(
              onTap: () {
                if (Platform.isMacOS || Platform.isWindows) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        backgroundColor: Colors.transparent,
                        child: FittedBox(
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topCenter,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.PADDING_SIZE_LARGE),
                                constraints: const BoxConstraints(
                                    maxWidth: Dimensions.WEB_MAX_WIDTH * 0.4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: ThemeManager.white,
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height:
                                          Dimensions.PADDING_SIZE_LARGE * 1.7,
                                    ),
                                    Image.asset(
                                      'assets/image/app_icon.jpg',
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.fill,
                                    ),
                                    const SizedBox(
                                      height:
                                          Dimensions.PADDING_SIZE_LARGE * 1.7,
                                    ),
                                    Text(
                                      "Subscriptions are currently available on Our Mobile App",
                                      style: interMedium.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                          color: ThemeManager.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(
                                      height:
                                          Dimensions.PADDING_SIZE_SMALL * 1.3,
                                    ),
                                    Text(
                                      "To complete your purchase or subscription please access our mobile app on Playstore and App Store.",
                                      textAlign: TextAlign.center,
                                      style: interMedium.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                          color: ThemeManager.black,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(
                                      height:
                                          Dimensions.PADDING_SIZE_SMALL * 2.2,
                                    ),
                                    Container(
                                      // width: MediaQuery.of(context)
                                      //         .size
                                      //         .width *
                                      //     0.5,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: InkWell(
                                              onTap: () async {
                                                if (!await launchUrl(Uri.parse(
                                                    'https://play.google.com/store/apps/details?id=com.ginger.sushruta&pcampaignid=web_share'))) {
                                                  throw Exception(
                                                      'Could not launch Link');
                                                }
                                              },
                                              child: SvgPicture.asset(
                                                "assets/image/Google_Play_Store_badge_EN.svg",
                                                height: 50,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width:
                                                Dimensions.PADDING_SIZE_SMALL *
                                                    2.2,
                                          ),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () async {
                                                if (!await launchUrl(Uri.parse(
                                                    'https://apps.apple.com/in/app/sushruta-lgs/id6443898817'))) {
                                                  throw Exception(
                                                      'Could not launch Link');
                                                }
                                              },
                                              child: SvgPicture.asset(
                                                "assets/image/Download_on_the_App_Store_Badge.svg",
                                                height: 50,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height:
                                          Dimensions.PADDING_SIZE_SMALL * 2.2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  Navigator.of(context).pushNamed(Routes.subscriptionDetailPlan,
                      arguments: {
                        "subscription": store.subscription[index],
                        "store": store
                      });
                }

                isExpandedList = [];
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.PADDING_SIZE_DEFAULT),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(39.61),
                ),
                child: Text("Get Started",
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefaultLarge,
                      color: AppColors.black,
                      fontWeight: FontWeight.w500,
                    )),
              ),
            ),
            const SizedBox(
              height: Dimensions.PADDING_SIZE_SMALL,
            ),
            loginStore.settingsData.value?.showActiveUser == true
                ? Align(
                    alignment: Alignment.center,
                    child: Text(
                        "${subscriptionList[index]?.active_user} Active Students",
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: AppColors.white,
                          fontWeight: FontWeight.w400,
                        )),
                  )
                : const SizedBox(),
            const SizedBox(
              height: Dimensions.PADDING_SIZE_LARGE,
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
    // Disable external subscription URL for iOS/macOS to comply with App Store guidelines
    if (Platform.isIOS || Platform.isMacOS) {
      // Show message that subscription is only available through in-app purchase on iOS/macOS
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription is available through in-app purchase. Please use the subscription options within the app.'),
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
  List<String> checkItems = [
    'Live Classes',
    'Mock Exams',
    "Only MCQ's",
    'Only Videos',
    'Only Notes'
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
      padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Filter',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
          Expanded(
            child: ListView.builder(
              itemCount: widget.checkboxItems.length,
              itemBuilder: (context, index) {
                final item = widget.checkboxItems[index];
                return CheckboxListTile(
                  title: Text(checkItems[index]),
                  value: _selectedValues.contains(item),
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
          const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (_selectedValues.isNotEmpty) {
                    Navigator.pop(context, _selectedValues.join(','));
                  } else {
                    Navigator.pop(
                        context, ''); // or any other appropriate value
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
