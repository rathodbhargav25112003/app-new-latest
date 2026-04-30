import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import '../../helpers/app_tokens.dart';
import '../widgets/smart_resume_banner.dart';
import 'ask_question.dart';
import '../../app/routes.dart';
import 'package:intl/intl.dart';
import '../../helpers/colors.dart';
import '../../helpers/styles.dart';
import '../../helpers/constants.dart';
import '../widgets/bottom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../login/verify_otp_mail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import 'package:flutter/foundation.dart';
import '../login/store/login_store.dart';
import '../widgets/review_bottom_sheet.dart';
import 'models/homepage_watching_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/no_internet_connection.dart';
import '../../models/zoom_meeting_live_model.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shusruta_lms/modules/formate_text.dart';
import 'package:shusruta_lms/api_service/api_service.dart';
import '../widgets/custom_featured_test_bottom_sheet.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../subscriptionplans/store/subscription_store.dart';
import '../liveclass/store/live_class_main_screen_store.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/reports/rank_list_screen.dart';
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
import 'package:shusruta_lms/modules/profile/active_subscription.dart';
import 'package:shusruta_lms/modules/login/store/verify_otp_phone.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import '../testimonial_and_blog/model/get_all_testimonial_list_model.dart';
import 'package:shusruta_lms/modules/subscriptionplans/subscription_screen.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/new_bookmark_screen1.dart';
import 'package:shusruta_lms/modules/masterTest/leaderboard_category_screen.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../widgets/preparing_for_bottom_sheet.dart';
import '../signup/store/signup_store.dart';
import '../../models/get_user_details_model.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key, required this.scaffoldKey});
  final GlobalKey<ScaffoldState> scaffoldKey;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CarouselSliderController _controller = CarouselSliderController();
  final TextEditingController _searchController = TextEditingController();
  // final CarouselController _controller2 = CarouselController();
  final PageController _controller2 = PageController();
  List<String> imgList = [];
  List<String> bottomImgList = [];
  bool isFeaturedContent = false;
  bool isFeaturedVideoExist = false;
  bool isFeaturedTestExist = false;
  bool isFeaturedPdfExist = false;
  int _current = 0;
  int _current2 = 0;
  List<Widget> imageSliders = [];
  List<Widget> bottomImageSliders = [];
  Uint8List? thumbnailImg;
  String loggedInPlatform = '';
  String selectedValue = 'All Category';
  List<String> drop = [
    "All Category",
    "Videos",
    "Notes",
    "Exams",
    "Mock Exams"
  ];
  var isEnabled = ThemeManager.currentTheme == AppTheme.Dark ? false : true;
  final animationDuration = const Duration(milliseconds: 500);
  Map<String, dynamic> packages = {};
  bool isResultVisible = true;
  List learnFrom = [
    {
      "name": "Videos",
      "path": "assets/image/video.png",
      "onTap": Routes.videoLectures
    },
    {
      "name": "Live Classes",
      "path": "assets/image/live.png",
      "onTap": Routes.liveClassMainScreen
    },
    {
      "name": "MCQ Bank",
      "path": "assets/image/mcq.png",
      "onTap": Routes.testCategory
    },
    {
      "name": "Notes",
      "path": "assets/image/note.png",
      "onTap": Routes.notesCategory
    },
    {
      "name": "Quiz of the Day",
      "path": "assets/image/quiz.png",
      "onTap": Routes.quizScreen
    },
    {
      "name": "Mock Exams",
      "path": "assets/image/mock.png",
      "onTap": Routes.allTestCategory
    },
    {
      "name": "Blogs",
      "path": "assets/image/blog.png",
      "onTap": Routes.blogScreen
    },
    {
      "name": "Testimonials",
      "path": "assets/image/testomonial.png",
      "onTap": Routes.testimonialScreen
    },
    {
      "name": "Study Planner",
      "path": "assets/image/planner.png",
      "onTap": Routes.liveClassMainScreen
    },
  ];

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    // SystemChrome.setSystemUIOverlayStyle( SystemUiOverlayStyle(
    //   statusBarColor: ThemeManager.white,
    //   statusBarIconBrightness: ThemeManager.currentTheme == AppTheme.Dark ? Brightness.light : Brightness.dark,
    //   statusBarBrightness: ThemeManager.currentTheme == AppTheme.Dark ? Brightness.dark : Brightness.light,
    // ));
    _getUserDetails();
    _getDeclaration();
    _getFeaturedContent();
    _getSubscribedPlan();
    _getOfferBanner();
    _settingsData();
    _getMockTestData();
    _getTestimonial();
    _upcomingmeetData();
    _setTheme();
    _getContinueWatchingData();
    checkDeviceExists();
    // getToken();
  }

  Future<void> _settingsData() async {
    final store = Provider.of<LoginStore>(context, listen: false);
    await store.onGetSettingsData();
  }

  Future<void> _setTheme() async {
    var brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    debugPrint("isDarkMode:$isDarkMode");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? settheme = prefs.getBool("first_Time");
    debugPrint("settheme:$settheme");
    if (isDarkMode == true) {
      if (settheme == null) {
        await prefs.setBool("first_Time", true);
        settheme == false ? null : openBottomSheet();
      }
    } else {
      await prefs.setBool("first_Time", false);
    }
  }

  Future<void> checkDeviceExists() async {
    try {
      Map<String, dynamic> platformInfo = await getDeviceInfo();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      final response =
      await ApiService().checkDeviceInfo(platformInfo["device_id"], token!);
      print(response);
      if (response["status"] == false) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.login,
              (route) => false,
        );
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  void openBottomSheet() {
    if (Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: ThemeManager.mainBackground,
            actionsPadding: EdgeInsets.zero,
            insetPadding: const EdgeInsets.symmetric(horizontal: 250),
            actions: const [
              ThemeComponent(),
            ],
          );
        },
      );
    } else {
      showModalBottomSheet<void>(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
        ),
        isDismissible: true,
        enableDrag: false,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return const ThemeComponent();
        },
      );
    }
  }

  void _showPreparingForBottomSheet() {
    final store = Provider.of<HomeStore>(context, listen: false);
    
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PreparingForBottomSheet(
        userDetails: store.userDetails.value,
        onUpdate: () {
          _getUserDetails();
        },
      ),
    );
  }

  Future<void> _getContinueWatchingData() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGetHomePageListApiCall();
  }

  Future<void> _upcomingmeetData() async {
    final meetingStore = Provider.of<MeetingStore>(context, listen: false);
    await meetingStore.fetchUpComingMeeting();
  }

  Future<void> _getUserDetails() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGetUserDetailsCall(context);
  }

  Future<void> _getDeclaration() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGetDeclarationCall();
  }

  Future<void> _initPackageInfo() async {
    // final info = await PackageInfo.fromPlatform();
    final data = await PackageManager.getPackageInfo();
    if (Platform.isIOS) {
      final iTunes = ITunesSearchAPI();
      final response =
      await (iTunes.lookupByBundleId(data.packageName, country: "IN"));
      if (response != null) {
        final version = iTunes.version(response);
        if (version != null) {}
        final view = iTunes.trackViewUrl(response);
        log(view.toString());
        log(version.toString());
        packages["store"] = version;
        packages["url"] = view;
      }
    } else if (Platform.isAndroid) {
      final playStore = PlayStoreSearchAPI();
      final response = await playStore.lookupById(data.packageName,
          country: "IN", language: "English");
      if (response != null) {
        final version = playStore.version(response);
        if (version != null) {
          final view = playStore.lookupURLById(data.packageName,
              country: "IN", language: "English");
          packages["store"] = version;
          packages["url"] = view;
        }
      }
    }
    packages["current"] = data.version;
    log(data.toJson().toString());
  }

  Future<void> _getFeaturedContent() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGetFeaturedListApiCall(context);
  }

  Future<void> _getOfferBanner() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGetOffersCall(context);
  }

  Future<void> _getSubscribedPlan() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetSubscribedUserPlan();
    if (store.subscribedPlan.isEmpty) {
      // Navigator.of(context).pushNamed(Routes.subscriptionList);
    }
  }

  Future<void> _getMockTestData() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGetMockTestDetailsCall(context);
  }

  Future<void> _getTestimonial() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGetTestimonialListApiCall();
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

  Widget _buildSuffixIcon(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          _navigate(context);
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  void _navigate(BuildContext context) {
    Navigator.of(context).pushNamed(
      Routes.searchScreen,
      arguments: {
        'selectedValue': selectedValue,
        'text': _searchController.text,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginStore = Provider.of<LoginStore>(context, listen: false);
    launchZoomMeeting(String zoomlink, String pdfUrl, String title) async {
      final url = zoomlink;

      if (await canLaunch(url)) {
        await launch(url);
      } else {
        const zoomAppStoreUrl =
            "https://play.google.com/store/apps/details?id=us.zoom.videomeetings";

        if (await canLaunch(zoomAppStoreUrl)) {
          await launch(zoomAppStoreUrl);
        } else {
          print("Could not open the app store link.");
        }
      }
    }

    final store = Provider.of<HomeStore>(context, listen: false);
    DateTime now = DateTime.now();
    int hours = now.hour;
    List<DropdownMenuItem<String>> dropdownItems = drop.map((item) {
      final preparingFor = item;
      return DropdownMenuItem<String>(
        value: preparingFor,
        child: Text(preparingFor),
      );
    }).toList();

    return UpgradeAlert(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppTokens.scaffold(context),
          body: Stack(
            children: [
              Observer(
                builder: (_) {
                  isFeaturedVideoExist =
                  (store.featuredContent.value?.video?.isNotEmpty ?? false);
                  isFeaturedTestExist =
                  (store.featuredContent.value?.test?.isNotEmpty ?? false);
                  isFeaturedPdfExist =
                  (store.featuredContent.value?.pdf?.isNotEmpty ?? false);
                  if ((store.featuredContent.value?.video?.isEmpty ?? false) &&
                      (store.featuredContent.value?.pdf?.isEmpty ?? false) &&
                      (store.featuredContent.value?.test?.isEmpty ?? false)) {
                    isFeaturedContent = true;
                  }

                  imgList = (store.offerBanners.value?.upperbanner ?? [])
                      .map((e) => e.upperbanner_img)
                      .whereType<String>()
                      .toList();
                  imageSliders = (store.offerBanners.value?.upperbanner ?? [])
                      .map((banner) {
                    String upperbanner =
                        "getImage${banner.upperbanner_img?.substring(banner.upperbanner_img?.lastIndexOf('/') ?? 0)}";
                    return GestureDetector(
                      onTap: () {
                        _launchURL(banner.upperbanner_url ?? "");
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                Dimensions.PADDING_SIZE_DEFAULT)),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              Dimensions.PADDING_SIZE_DEFAULT),
                          child: Image.network(
                            // "https://imgs.search.brave.com/Nhj77btyOFXdao7hozLzaaDYFIG9XIEZB-uR3vZsDMw/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly93YWxs/cGFwZXJhY2Nlc3Mu/Y29tL2Z1bGwvMTc3/MjI0MS5qcGc",
                            pdfBaseUrl + upperbanner,
                            fit: BoxFit.fill,
                            // width: 1100.0,
                          ),
                        ),
                      ),
                    );
                  }).toList();

                  bottomImgList = (store.offerBanners.value?.lowerbanner ?? [])
                      .map((e) => e.lowerbanner_img)
                      .whereType<String>()
                      .toList();
                  bottomImageSliders =
                      (store.offerBanners.value?.lowerbanner ?? [])
                          .map((banner) {
                        String lowerbanner =
                            "getImage${banner.lowerbanner_img?.substring(banner.lowerbanner_img?.lastIndexOf('/') ?? 0)}";
                        return GestureDetector(
                          onTap: () {
                            _launchURL(banner.lowerbanner_url ?? "");
                          },
                          child: Container(
                            margin: const EdgeInsets.all(1.0),
                            child: ClipRRect(
                              borderRadius:
                              const BorderRadius.all(Radius.circular(5.0)),
                              child: Stack(
                                children: <Widget>[
                                  Image.network(
                                    pdfBaseUrl + lowerbanner,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList();

                  return store.isConnected
                      ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal:
                                Dimensions.PADDING_SIZE_DEFAULT * 1.1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.start,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            CupertinoDialogRoute(
                                                builder: (context) =>
                                                    ActiveSubscriptionScreen(),
                                                context: context));
                                      },
                                      child: Padding(
                                        padding:
                                        const EdgeInsets.only(top: 15),
                                        child: SvgPicture.asset(ThemeManager
                                            .currentTheme ==
                                            AppTheme.Dark
                                            ? "assets/image/profileBgIcon.svg"
                                            : "assets/image/profileBgIcon.svg"),
                                      ),
                                    ),
                                    const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT),
                                    // Primary Group | Exam Button
                                    Observer(
                                      builder: (_) {
                                        final preparingFor = store.userDetails.value?.preparingFor ?? '';
                                        final standerdFor = store.userDetails.value?.standerdFor ?? '';
                                        final displayText = preparingFor.isNotEmpty && standerdFor.isNotEmpty
                                            ? '$preparingFor | $standerdFor'
                                            : preparingFor.isNotEmpty
                                                ? preparingFor
                                                : 'Select Group';
                                        
                                        return InkWell(
                                          onTap: () {
                                            _showPreparingForBottomSheet();
                                          },
                                          borderRadius: AppTokens.radius20,
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 15),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppTokens.s12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTokens.accentSoft(context),
                                                borderRadius: AppTokens.radius20,
                                                border: Border.all(
                                                  color: AppTokens.accent(context)
                                                      .withOpacity(0.25),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      displayText,
                                                      style: AppTokens
                                                              .titleSm(context)
                                                          .copyWith(
                                                        color: AppTokens.accent(
                                                            context),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Icon(
                                                    Icons.tune_rounded,
                                                    size: 14,
                                                    color: AppTokens.accent(
                                                        context),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                Spacer(),
                                // Reset progress action — Apple-style icon button.
                                InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(context, Routes.deleteHistoryScreen);
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 15, right: 12),
                                    child: Icon(
                                      Icons.restart_alt_rounded,
                                      color: AppTokens.ink(context),
                                      size: 22,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (context) =>
                                            const BookMarkScreen1()));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: SvgPicture.asset(ThemeManager
                                        .currentTheme ==
                                        AppTheme.Dark
                                        ? "assets/image/bookmarkBgIcon.svg"
                                        : "assets/image/bookmarkBgIcon.svg"),
                                  ),
                                ),
                                // // Test Crash Button (debug only)
                                // if (kDebugMode)
                                //   IconButton(
                                //     tooltip: 'Test Crash',
                                //     icon: const Icon(Icons.bug_report, color: Colors.red),
                                //     onPressed: () {
                                //       FirebaseCrashlytics.instance.crash();
                                //     },
                                // ),
                                const SizedBox(
                                  width: 13,
                                ),
                                InkWell(
                                  onTap: () {
                                    widget.scaffoldKey.currentState
                                        ?.openEndDrawer(); // Open the drawer
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: SvgPicture.asset(ThemeManager
                                        .currentTheme ==
                                        AppTheme.Dark
                                        ? "assets/image/darkMenuIcon.svg"
                                        : "assets/image/hamburgerBgIcon.svg"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // const SizedBox(
                          //   height: Dimensions.PADDING_SIZE_LARGE * 1.15,
                          // ),

                          // Padding(
                          //   padding: const EdgeInsets.symmetric(
                          //       horizontal:
                          //           Dimensions.PADDING_SIZE_DEFAULT * 1.1),
                          //   child: Container(
                          //     constraints: const BoxConstraints(
                          //       minHeight:
                          //           Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                          //     ),
                          //     decoration: BoxDecoration(
                          //         border: Border.all(
                          //             color: ThemeManager.mainBorder),
                          //         borderRadius: const BorderRadius.all(
                          //             Radius.circular(10)),
                          //         boxShadow: [
                          //           ThemeManager.currentTheme == AppTheme.Dark
                          //               ? const BoxShadow()
                          //               : BoxShadow(
                          //                   offset: const Offset(0, 2),
                          //                   blurRadius: 16,
                          //                   color: ThemeManager.black
                          //                       .withOpacity(0.1),
                          //                   spreadRadius: -5),
                          //         ]),
                          //     child: Row(
                          //       children: [
                          //         Container(
                          //           width: Dimensions.PADDING_SIZE_EXTRA_LARGE *
                          //               5.4,
                          //           constraints: const BoxConstraints(
                          //             minHeight:
                          //                 Dimensions.PADDING_SIZE_EXTRA_LARGE *
                          //                     2,
                          //           ),
                          //           decoration: BoxDecoration(
                          //             color: ThemeManager.blueFinal,
                          //             borderRadius:
                          //                 const BorderRadius.horizontal(
                          //                     left: Radius.circular(10)),
                          //           ),
                          //           child: ClipRRect(
                          //             borderRadius:
                          //                 const BorderRadius.horizontal(
                          //                     left: Radius.circular(10)),
                          //             child: DropdownButtonFormField<String>(
                          //               isExpanded: true,
                          //               dropdownColor: ThemeManager.blueFinal,
                          //               value: selectedValue.isNotEmpty
                          //                   ? selectedValue
                          //                   : null,
                          //               decoration: InputDecoration(
                          //                   filled: true,
                          //                   fillColor: ThemeManager.blueFinal,
                          //                   hintText: 'All Category',
                          //                   hintStyle: interRegular.copyWith(
                          //                     fontSize:
                          //                         Dimensions.fontSizeSmall,
                          //                     fontWeight: FontWeight.w400,
                          //                     color: ThemeManager.white,
                          //                   ),
                          //                   contentPadding:
                          //                       const EdgeInsets.symmetric(
                          //                           horizontal: 14,
                          //                           vertical: 14),
                          //                   focusedBorder:
                          //                       const OutlineInputBorder(
                          //                           borderSide:
                          //                               BorderSide.none),
                          //                   border: const OutlineInputBorder(
                          //                       borderSide: BorderSide.none)),
                          //               items: dropdownItems,
                          //               onChanged: (value) {
                          //                 setState(() {
                          //                   selectedValue = value ?? '';
                          //                 });
                          //               },
                          //               icon: Icon(
                          //                 Icons.keyboard_arrow_down,
                          //                 color: ThemeManager.white,
                          //               ),
                          //               iconSize: 24,
                          //               elevation: 16,
                          //               style: interRegular.copyWith(
                          //                 fontSize: Dimensions.fontSizeSmall,
                          //                 color: ThemeManager.white,
                          //               ),
                          //             ),
                          //           ),
                          //         ),
                          //         Flexible(
                          //           child: Container(
                          //             decoration: BoxDecoration(
                          //               color: ThemeManager.white,
                          //               borderRadius:
                          //                   const BorderRadius.horizontal(
                          //                       right: Radius.circular(10)),
                          //             ),
                          //             child: TextFormField(
                          //               readOnly: !(Platform.isWindows ||
                          //                   Platform.isMacOS),
                          //               onTap: () {
                          //                 if (!(Platform.isWindows ||
                          //                     Platform.isMacOS)) {
                          //                   _navigate(context);
                          //                 }
                          //               },
                          //               onFieldSubmitted: (value) {
                          //                 _navigate(context);
                          //               },
                          //               cursorColor: ThemeManager.textColor4,
                          //               style: interRegular.copyWith(
                          //                 fontSize: Dimensions.fontSizeDefault,
                          //                 color: ThemeManager.textColor4,
                          //               ),
                          //               keyboardType: TextInputType.name,
                          //               controller: _searchController,
                          //               decoration: InputDecoration(
                          //                 contentPadding:
                          //                     const EdgeInsets.fromLTRB(
                          //                         12, 12, 12, 12),
                          //                 fillColor:
                          //                     Theme.of(context).disabledColor,
                          //                 enabledBorder: InputBorder.none,
                          //                 hintText:
                          //                     'Search chapter name, topic...',
                          //                 hintStyle: interRegular.copyWith(
                          //                   fontSize: Dimensions.fontSizeSmall,
                          //                   color: ThemeManager.textColor4
                          //                       .withOpacity(0.5),
                          //                 ),
                          //                 counterText: '',
                          //                 focusedBorder: InputBorder.none,
                          //                 border: InputBorder.none,
                          //                 suffixIcon: _buildSuffixIcon(context),
                          //               ),
                          //             ),
                          //           ),
                          //         )
                          //       ],
                          //     ),
                          //   ),
                          // ),

                          const SizedBox(
                              height: Dimensions.PADDING_SIZE_LARGE),

                          ///Slider
                          imgList.isNotEmpty
                              ? Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal:
                                Dimensions.PADDING_SIZE_DEFAULT *
                                    1.1),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(10),
                                  child: CarouselSlider(
                                    items: imageSliders,
                                    carouselController: _controller,
                                    options: CarouselOptions(
                                        autoPlay: true,
                                        viewportFraction:
                                        (Platform.isWindows ||
                                            Platform.isMacOS)
                                            ? 0.5
                                            : 1,
                                        enlargeCenterPage:
                                        (Platform.isWindows ||
                                            Platform.isMacOS)
                                            ? false
                                            : true,
                                        height: (Platform.isWindows ||
                                            Platform.isMacOS)
                                            ? 310
                                            : 186,
                                        onPageChanged:
                                            (index, reason) {
                                          setState(() {
                                            _current = index;
                                          });
                                        }),
                                  ),
                                ),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: List.generate(
                                        imageSliders.length,
                                            (index) => Container(
                                          width: _current == index
                                              ? 24
                                              : 14,
                                          height: 2,
                                          margin: EdgeInsets.symmetric(
                                              horizontal: (Platform
                                                  .isWindows ||
                                                  Platform
                                                      .isMacOS)
                                                  ? 5
                                                  : Dimensions
                                                  .PADDING_SIZE_EXTRA_SMALL *
                                                  1.6,
                                              vertical: Dimensions
                                                  .PADDING_SIZE_EXTRA_SMALL *
                                                  1.6),
                                          decoration: BoxDecoration(
                                              borderRadius: (Platform
                                                  .isWindows ||
                                                  Platform
                                                      .isMacOS)
                                                  ? null
                                                  : BorderRadius
                                                  .circular(10),
                                              color: _current ==
                                                  index
                                                  ? ThemeManager
                                                  .primaryblue
                                                  : ThemeManager
                                                  .primaryblue
                                                  .withOpacity(
                                                  0.3)),
                                        )),
                                  ),
                                ),
                              ],
                            ),
                          )
                              : const SizedBox(),
                          // if (store.getDeclaration?.categoryId != null) ...[
                          //   Center(
                          //     child: GestureDetector(
                          //       onTap: () {
                          //         Navigator.push(
                          //             context,
                          //             CupertinoPageRoute(
                          //               builder: (context) =>
                          //                   RankListScreen(
                          //                 examId:
                          //                     store.getDeclaration!.examId!,
                          //               ),
                          //             ));
                          //       },
                          //       child: Container(
                          //         constraints:
                          //             const BoxConstraints(maxWidth: 600),
                          //         padding: const EdgeInsets.all(16),
                          //         margin: const EdgeInsets.only(
                          //             top: 20,
                          //             left: 16,
                          //             right: 15,
                          //             bottom: 5),
                          //         decoration: BoxDecoration(
                          //           color: ThemeManager.white,
                          //           borderRadius: BorderRadius.circular(12),
                          //           border: Border.all(
                          //             color: ThemeManager.border1,
                          //           ),
                          //         ),
                          //         child: Column(
                          //           crossAxisAlignment:
                          //               CrossAxisAlignment.start,
                          //           children: [
                          //             Text(
                          //               'Ranks & Merit List for ${store.getDeclaration?.examName ?? ""} in ${store.getDeclaration?.categoryName} are Now Available!',
                          //               style: interMedium.copyWith(
                          //                 fontSize: 14,
                          //                 fontWeight: FontWeight.bold,
                          //                 color: ThemeManager.black,
                          //               ),
                          //             ),
                          //             const SizedBox(height: 8),
                          //             Align(
                          //                 alignment: Alignment.center,
                          //                 child: Row(
                          //                   mainAxisAlignment:
                          //                       MainAxisAlignment.center,
                          //                   children: [
                          //                     Text(
                          //                       'Check Leaderboard',
                          //                       style: interMedium.copyWith(
                          //                         fontSize: 13,
                          //                         color: ThemeManager
                          //                             .continueIcon,
                          //                         fontWeight:
                          //                             FontWeight.w600,
                          //                       ),
                          //                     ),
                          //                     const SizedBox(
                          //                       width: 5,
                          //                     ),
                          //                     Icon(
                          //                       Icons.arrow_forward,
                          //                       color: ThemeManager
                          //                           .continueIcon,
                          //                     ),
                          //                   ],
                          //                 )),
                          //           ],
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // ],

                          Padding(
                            padding: const EdgeInsets.only(
                              left: Dimensions.PADDING_SIZE_LARGE,
                              top: Dimensions.PADDING_SIZE_LARGE,
                            ),
                            child: Text(
                              "Learn From",
                              style: interRegular.copyWith(
                                fontSize: Dimensions.fontSizeLarge,
                                fontWeight: FontWeight.w600,
                                color: ThemeManager.black,
                              ),
                            ),
                          ),
                          const SizedBox(
                              height: Dimensions.PADDING_SIZE_SMALL * 1.1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.PADDING_SIZE_LARGE),
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: ThemeManager.white,
                                  boxShadow: [
                                    BoxShadow(
                                        color: ThemeManager.grey1,
                                        spreadRadius: 1.0,
                                        blurRadius: 4.0,
                                        offset: const Offset(0, 3))
                                  ]),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: Dimensions
                                        .PADDING_SIZE_EXTRA_LARGE),
                                child: CustomDynamicHeightGridView(
                                  shrinkWrap: true,
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 22,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: learnFrom.length,
                                  builder:
                                      (BuildContext context, int index) {
                                    return GestureDetector(
                                      onTap: () async {
                                        if (index == 8) {
                                          await launchUrl(
                                              Uri.parse(
                                                  "https://www.sushrutalgs.in/studyplanner/"),
                                              mode:
                                              LaunchMode.inAppWebView);
                                        } else {
                                          Navigator.of(context).pushNamed(
                                              learnFrom[index]['onTap']);
                                        }
                                      },
                                      child: Column(
                                        children: [
                                          Image.asset(
                                            learnFrom[index]['path'],
                                            height: 25,
                                            width: 25,
                                          ),
                                          const SizedBox(
                                            height: 2.8,
                                          ),
                                          Text(
                                            learnFrom[index]['name'],
                                            style: interRegular.copyWith(
                                              fontSize:
                                              Dimensions.fontSizeSmall,
                                              fontWeight: FontWeight.w500,
                                              color: ThemeManager.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                              height: Dimensions.PADDING_SIZE_SMALL * 1.1),

                          // Smart Resume banner — surfaces the user's
                          // most-recent in-progress mock exam / custom
                          // test / video / note as a 1-tap "pick up
                          // where you left off" card. Hidden when the
                          // user has nothing in progress.
                          const SmartResumeBanner(),

                          Padding(
                            padding: const EdgeInsets.only(
                              left: Dimensions.PADDING_SIZE_LARGE,
                              top: Dimensions.PADDING_SIZE_LARGE,
                              right: Dimensions.PADDING_SIZE_LARGE,
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Continue learning",
                                  style: AppTokens.titleMd(context),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                        Routes.continueWatchingScreen);
                                  },
                                  borderRadius: AppTokens.radius12,
                                  child: Text(
                                    "View more",
                                    style: AppTokens.titleSm(context).copyWith(
                                      color: AppTokens.accent(context),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      height: 0,
                                      decorationColor:
                                      ThemeManager.primaryblue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                              height: Dimensions.PADDING_SIZE_SMALL),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal:
                                Dimensions.PADDING_SIZE_DEFAULT * 1.1),
                            child: Observer(builder: (context) {
                              if (store.isLoading) {
                                return Center(
                                    child: CircularProgressIndicator(
                                      color: ThemeManager.primaryColor,
                                    ));
                              }
                              return Column(
                                children: [
                                  SizedBox(
                                    height: Dimensions.PADDING_SIZE_LARGE *
                                        4.55,
                                    child: PageView(
                                      controller: _controller2,
                                      onPageChanged: (index) {
                                        setState(() {
                                          _current2 = index;
                                        });
                                      },
                                      children: store
                                          .getHomeListData.isNotEmpty
                                          ? List.generate(
                                          store.getHomeListData
                                              .length ??
                                              0, (index) {
                                        HomePageWatchingModel?
                                        homeWatchList =
                                        store.getHomeListData[
                                        index];
                                        String type =
                                            homeWatchList?.type ?? '';
                                        String? titleName =
                                        (homeWatchList?.type ==
                                            'exam'
                                            ? homeWatchList
                                            ?.examName
                                            : type == 'mockExam'
                                            ? homeWatchList
                                            ?.examName
                                            : homeWatchList
                                            ?.title);

                                        // debugPrint("titleName:${titleName}");
                                        return InkWell(
                                          onTap: () {
                                            if (type == 'video') {
                                              Navigator.of(context)
                                                  .pushNamed(
                                                  Routes
                                                      .videoPlayDetail,
                                                  arguments: {
                                                    "topicId":
                                                    homeWatchList
                                                        ?.topicId,
                                                    "isCompleted":
                                                    homeWatchList
                                                        ?.isCompleted,
                                                    "videoTopicId":
                                                    homeWatchList
                                                        ?.topicId,
                                                    // "topicId": videoSubcat?.topicId,
                                                    'title': homeWatchList
                                                        ?.title ??
                                                        '',
                                                    'isDownloaded':
                                                    false,
                                                    'titleId':
                                                    homeWatchList
                                                        ?.sId,
                                                    'contentId':
                                                    homeWatchList
                                                        ?.sId,
                                                    'pauseTime':
                                                    homeWatchList
                                                        ?.pausedTime,
                                                    'categoryId':
                                                    homeWatchList
                                                        ?.categoryId,
                                                    'subcategoryId':
                                                    homeWatchList
                                                        ?.subcategoryId,
                                                    'isBookmark':
                                                    homeWatchList
                                                        ?.isBookmark,
                                                    'pdfId':
                                                    homeWatchList
                                                        ?.pdfId,
                                                    'videoPlayUrl':
                                                    homeWatchList
                                                        ?.videoLink,
                                                    'videoQuality':
                                                    homeWatchList
                                                        ?.videoFiles,
                                                    'downloadVideoData':
                                                    homeWatchList
                                                        ?.downloadVideo,
                                                    'annotationData':
                                                    homeWatchList
                                                        ?.annotation,
                                                    'contentUrl':
                                                    homeWatchList
                                                        ?.pdfcontents,
                                                    'pageNo': 0,
                                                  });
                                            } else if (type ==
                                                'pdf') {
                                              Navigator.of(context)
                                                  .pushNamed(
                                                  Routes
                                                      .notesReadView,
                                                  arguments: {
                                                    'contentUrl':
                                                    homeWatchList
                                                        ?.contentUrl,
                                                    'title': homeWatchList
                                                        ?.title ??
                                                        '',
                                                    'topic_name':
                                                    homeWatchList
                                                        ?.topicName ??
                                                        '',
                                                    'category_name':
                                                    homeWatchList
                                                        ?.categoryName ??
                                                        '',
                                                    'subcategory_name':
                                                    homeWatchList
                                                        ?.subcategoryName ??
                                                        '',
                                                    'isDownloaded':
                                                    false,
                                                    "isCompleted":
                                                    homeWatchList
                                                        ?.isCompleted,
                                                    'topicId':
                                                    homeWatchList
                                                        ?.topicId,
                                                    'titleId':
                                                    homeWatchList
                                                        ?.sId,
                                                    'categoryId':
                                                    homeWatchList
                                                        ?.categoryId,
                                                    'subcategoryId':
                                                    homeWatchList
                                                        ?.subcategoryId,
                                                  });
                                            } else if (type ==
                                                'exam') {
                                              Navigator.of(context)
                                                  .pushNamed(
                                                  Routes
                                                      .selectTestList,
                                                  arguments: {
                                                    'id':
                                                    homeWatchList
                                                        ?.sId,
                                                    'type': "topic"
                                                  });
                                            } else if (type ==
                                                'mockExam') {
                                              Navigator.of(context)
                                                  .pushNamed(
                                                  Routes
                                                      .allSelectTestList,
                                                  arguments: {
                                                    'id':
                                                    homeWatchList
                                                        ?.sId,
                                                    'type': "topic",
                                                  });
                                            }
                                          },
                                          child: Container(
                                            // height: 72,
                                            width:
                                            MediaQuery.of(context)
                                                .size
                                                .width *
                                                0.9,
                                            padding: const EdgeInsets
                                                .fromLTRB(
                                                Dimensions
                                                    .PADDING_SIZE_SMALL *
                                                    1.7,
                                                Dimensions
                                                    .PADDING_SIZE_SMALL *
                                                    1.2,
                                                Dimensions
                                                    .PADDING_SIZE_SMALL *
                                                    1.5,
                                                Dimensions
                                                    .PADDING_SIZE_SMALL *
                                                    1.2),
                                            decoration: BoxDecoration(
                                              color:
                                              ThemeManager.white,
                                              borderRadius:
                                              BorderRadius
                                                  .circular(12),
                                              border: Border.all(
                                                color: ThemeManager
                                                    .border1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .center,
                                              children: [
                                                Container(
                                                  height: Dimensions
                                                      .PADDING_SIZE_LARGE *
                                                      2.4,
                                                  width: Dimensions
                                                      .PADDING_SIZE_LARGE *
                                                      2.4,
                                                  alignment: Alignment
                                                      .center,
                                                  decoration: BoxDecoration(
                                                      color: ThemeManager
                                                          .continueContainerOpacity,
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          Dimensions
                                                              .RADIUS_DEFAULT),
                                                      boxShadow: [
                                                        ThemeManager.currentTheme ==
                                                            AppTheme
                                                                .Dark
                                                            ? const BoxShadow()
                                                            : BoxShadow(
                                                            offset: const Offset(0,
                                                                2),
                                                            blurRadius:
                                                            11,
                                                            spreadRadius:
                                                            -2,
                                                            color: ThemeManager
                                                                .black
                                                                .withOpacity(0.13))
                                                      ]),
                                                  child: ThemeManager
                                                      .currentTheme ==
                                                      AppTheme
                                                          .Dark
                                                      ? SvgPicture.asset(type ==
                                                      'video'
                                                      ? "assets/image/darkContinueIcon.svg"
                                                      : type ==
                                                      'pdf'
                                                      ? "assets/image/darkContinueNote.svg"
                                                      : "assets/image/darkContinueExam.svg")
                                                      : SvgPicture.asset(type ==
                                                      'video'
                                                      ? "assets/image/continueIcon.svg"
                                                      : type ==
                                                      'pdf'
                                                      ? "assets/image/continueNote.svg"
                                                      : "assets/image/continueExam.svg"),
                                                ),
                                                const SizedBox(
                                                    width: Dimensions
                                                        .PADDING_SIZE_DEFAULT *
                                                        1.1),
                                                // const SizedBox(height: 7),
                                                Expanded(
                                                  child: Text(
                                                    titleName ?? '',
                                                    style:
                                                    interRegular
                                                        .copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeLarge,
                                                      fontWeight:
                                                      FontWeight
                                                          .w600,
                                                      color:
                                                      ThemeManager
                                                          .black,
                                                    ),
                                                    overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                                    maxLines: 2,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward,
                                                  color: ThemeManager
                                                      .continueIcon,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      })
                                          : [
                                        Center(
                                          child: Text(
                                            "Ready to Begin? Start Learning Now!",
                                            style:
                                            interRegular.copyWith(
                                              fontSize: Dimensions
                                                  .fontSizeSmall,
                                              fontWeight:
                                              FontWeight.w400,
                                              color:
                                              ThemeManager.black,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  (store.getHomeListData.isNotEmpty)
                                      ? Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: List.generate(
                                        store.getHomeListData.length,
                                            (index) {
                                          return Container(
                                            width: _current2 == index
                                                ? 24
                                                : 14,
                                            height: 2,
                                            margin: const EdgeInsets
                                                .symmetric(
                                                horizontal: Dimensions
                                                    .PADDING_SIZE_EXTRA_SMALL *
                                                    1.6,
                                                vertical: Dimensions
                                                    .PADDING_SIZE_EXTRA_SMALL *
                                                    1.6),
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    10),
                                                color: _current2 == index
                                                    ? ThemeManager
                                                    .primaryblue
                                                    : ThemeManager
                                                    .primaryblue
                                                    .withOpacity(
                                                    0.3)),
                                          );
                                        }),
                                  )
                                      : const SizedBox(),
                                ],
                              );
                            }),
                          ),
                          // isFeaturedVideoExist
                          //     ? Padding(
                          //   padding: const EdgeInsets.only(
                          //     left: Dimensions.PADDING_SIZE_LARGE,
                          //     top: Dimensions.PADDING_SIZE_LARGE,
                          //   ),
                          //   child: Column(
                          //     crossAxisAlignment:
                          //     CrossAxisAlignment.start,
                          //     children: [
                          //       Text(
                          //         "Featured Videos",
                          //         style: interRegular.copyWith(
                          //           fontSize:
                          //           Dimensions.fontSizeLarge,
                          //           fontWeight: FontWeight.w600,
                          //           color: ThemeManager.black,
                          //         ),
                          //       ),
                          //       const SizedBox(
                          //         height:
                          //         Dimensions.PADDING_SIZE_SMALL,
                          //       ),
                          //       SingleChildScrollView(
                          //         scrollDirection: Axis.horizontal,
                          //         child: Row(
                          //           crossAxisAlignment:
                          //           CrossAxisAlignment.start,
                          //           children: List.generate(
                          //               store.featuredContent.value
                          //                   ?.video?.length ??
                          //                   0, (index) {
                          //             String base64String = store
                          //                 .featuredContent
                          //                 .value
                          //                 ?.video?[index]
                          //                 .thumbImg ??
                          //                 "";
                          //             try {
                          //               thumbnailImg = base64Decode(
                          //                   base64String);
                          //             } catch (e) {
                          //               debugPrint(
                          //                   "Error decoding base64 string: $e");
                          //             }
                          //             return Padding(
                          //               padding: const EdgeInsets
                          //                   .only(
                          //                   right: Dimensions
                          //                       .PADDING_SIZE_SMALL),
                          //               child: Container(
                          //                 margin: const EdgeInsets
                          //                     .only(
                          //                     bottom: Dimensions
                          //                         .PADDING_SIZE_SMALL),
                          //                 height:
                          //                 MediaQuery.of(context)
                          //                     .size
                          //                     .height *
                          //                     0.22,
                          //                 width: (Platform
                          //                     .isWindows ||
                          //                     Platform.isMacOS)
                          //                     ? MediaQuery.of(context)
                          //                     .size
                          //                     .width *
                          //                     0.15
                          //                     : MediaQuery.of(context)
                          //                     .size
                          //                     .width *
                          //                     0.4,
                          //                 decoration: BoxDecoration(
                          //                     borderRadius:
                          //                     BorderRadius
                          //                         .circular(15),
                          //                     color:
                          //                     ThemeManager.white,
                          //                     border: Border.all(
                          //                         color: ThemeManager
                          //                             .mainBorder),
                          //                     boxShadow: [
                          //                       ThemeManager.currentTheme ==
                          //                           AppTheme.Dark
                          //                           ? const BoxShadow()
                          //                           : BoxShadow(
                          //                           offset:
                          //                           const Offset(
                          //                               0, 2),
                          //                           blurRadius:
                          //                           14,
                          //                           spreadRadius:
                          //                           -5,
                          //                           color: ThemeManager
                          //                               .black
                          //                               .withOpacity(
                          //                               0.14))
                          //                     ]),
                          //                 child: InkWell(
                          //                   onTap: () {
                          //                     store
                          //                         .featuredContent
                          //                         .value
                          //                         ?.video?[
                          //                     index]
                          //                         .videoUrl !=
                          //                         null &&
                          //                         store
                          //                             .featuredContent
                          //                             .value
                          //                             ?.video?[
                          //                         index]
                          //                             .videoUrl !=
                          //                             ""
                          //                         ? Navigator.of(
                          //                         context)
                          //                         .pushNamed(
                          //                         Routes
                          //                             .featuredVideos,
                          //                         arguments: {
                          //                           'featuredVideo': store
                          //                               .featuredContent
                          //                               .value
                          //                               ?.video?[index],
                          //                           'featuredVideoList': store
                          //                               .featuredContent
                          //                               .value
                          //                               ?.video
                          //                         })
                          //                         : BottomToast
                          //                         .showBottomToastOverlay(
                          //                       context:
                          //                       context,
                          //                       errorMessage:
                          //                       "No Video is Found!",
                          //                       backgroundColor:
                          //                       ThemeManager
                          //                           .redAlert,
                          //                     );
                          //                   },
                          //                   child: Column(
                          //                     crossAxisAlignment:
                          //                     CrossAxisAlignment
                          //                         .start,
                          //                     children: [
                          //                       Stack(
                          //                         alignment: Alignment
                          //                             .center,
                          //                         children: [
                          //                           ClipRRect(
                          //                               borderRadius:
                          //                               const BorderRadius
                          //                                   .only(
                          //                                 topLeft: Radius
                          //                                     .circular(
                          //                                     15),
                          //                                 topRight: Radius
                          //                                     .circular(
                          //                                     15),
                          //                               ),
                          //                               child: thumbnailImg !=
                          //                                   null
                          //                                   ? Image
                          //                                   .memory(
                          //                                 thumbnailImg!,
                          //                                 height: (Platform.isWindows || Platform.isMacOS)
                          //                                     ? MediaQuery.of(context).size.height * 0.134
                          //                                     : MediaQuery.of(context).size.height * 0.124,
                          //                                 width:
                          //                                 double.infinity,
                          //                                 fit: BoxFit
                          //                                     .fill,
                          //                               )
                          //                                   : Image
                          //                                   .asset(
                          //                                 "assets/image/cardimage.png",
                          //                                 height: (Platform.isWindows || Platform.isMacOS)
                          //                                     ? MediaQuery.of(context).size.height * 0.134
                          //                                     : MediaQuery.of(context).size.height * 0.124,
                          //                                 width:
                          //                                 double.infinity,
                          //                                 fit: BoxFit
                          //                                     .fill,
                          //                               )),
                          //                           Container(
                          //                             height: (Platform
                          //                                 .isWindows ||
                          //                                 Platform
                          //                                     .isMacOS)
                          //                                 ? MediaQuery.of(context)
                          //                                 .size
                          //                                 .height *
                          //                                 0.134
                          //                                 : MediaQuery.of(context)
                          //                                 .size
                          //                                 .height *
                          //                                 0.124,
                          //                             decoration:
                          //                             BoxDecoration(
                          //                                 borderRadius:
                          //                                 const BorderRadius
                          //                                     .only(
                          //                                   topLeft:
                          //                                   Radius.circular(15),
                          //                                   topRight:
                          //                                   Radius.circular(15),
                          //                                 ),
                          //                                 gradient: LinearGradient(
                          //                                     begin:
                          //                                     Alignment.topCenter,
                          //                                     end: Alignment.bottomCenter,
                          //                                     colors: [
                          //                                       const Color(0xFF0048D0).withOpacity(0),
                          //                                       const Color(0xFF0048D0),
                          //                                     ])),
                          //                           ),
                          //                           Container(
                          //                             height: 36,
                          //                             width: 36,
                          //                             alignment:
                          //                             Alignment
                          //                                 .center,
                          //                             decoration:
                          //                             BoxDecoration(
                          //                               color: AppColors
                          //                                   .white
                          //                                   .withOpacity(
                          //                                   0.8),
                          //                               shape: BoxShape
                          //                                   .circle,
                          //                             ),
                          //                             child: SvgPicture
                          //                                 .asset(
                          //                                 "assets/image/playIcon.svg"),
                          //                           ),
                          //                         ],
                          //                       ),
                          //                       Padding(
                          //                         padding: const EdgeInsets
                          //                             .fromLTRB(
                          //                             Dimensions
                          //                                 .PADDING_SIZE_EXTRA_SMALL *
                          //                                 1.6,
                          //                             Dimensions
                          //                                 .PADDING_SIZE_EXTRA_SMALL *
                          //                                 1.8,
                          //                             Dimensions
                          //                                 .PADDING_SIZE_EXTRA_SMALL *
                          //                                 1.6,
                          //                             0),
                          //                         child: FittedBox(
                          //                           child: Text(
                          //                             store
                          //                                 .featuredContent
                          //                                 .value
                          //                                 ?.video?[
                          //                             index]
                          //                                 .topicName ??
                          //                                 "",
                          //                             style: interBold.copyWith(
                          //                                 fontSize:
                          //                                 Dimensions
                          //                                     .fontSizeSmall,
                          //                                 fontWeight:
                          //                                 FontWeight
                          //                                     .w600,
                          //                                 color: ThemeManager
                          //                                     .black,
                          //                                 overflow:
                          //                                 TextOverflow
                          //                                     .ellipsis),
                          //                             maxLines: 2,
                          //                           ),
                          //                         ),
                          //                       ),
                          //                     ],
                          //                   ),
                          //                 ),
                          //               ),
                          //             );
                          //           }),
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // )
                          //     : const SizedBox(),

                          // isFeaturedTestExist
                          //     ? Padding(
                          //   padding: const EdgeInsets.only(
                          //     left: Dimensions.PADDING_SIZE_LARGE,
                          //   ),
                          //   child: Column(
                          //     crossAxisAlignment:
                          //     CrossAxisAlignment.start,
                          //     children: [
                          //       Text(
                          //         "Tests",
                          //         style: interRegular.copyWith(
                          //           fontSize:
                          //           Dimensions.fontSizeDefault,
                          //           fontWeight: FontWeight.w500,
                          //           color: ThemeManager.black,
                          //         ),
                          //       ),
                          //       const SizedBox(
                          //           height: Dimensions
                          //               .PADDING_SIZE_DEFAULT),
                          //       SizedBox(
                          //         width: MediaQuery.of(context)
                          //             .size
                          //             .width *
                          //             2,
                          //         height: 160,
                          //         child: ListView.builder(
                          //           scrollDirection: Axis.horizontal,
                          //           itemCount: store.featuredContent
                          //               .value?.test?.length,
                          //           itemBuilder: (context, index) {
                          //             return Padding(
                          //               padding: const EdgeInsets
                          //                   .only(
                          //                   right: Dimensions
                          //                       .PADDING_SIZE_SMALL),
                          //               child: SizedBox(
                          //                 width:
                          //                 MediaQuery.of(context)
                          //                     .size
                          //                     .width *
                          //                     0.42,
                          //                 height: 150,
                          //                 child: Card(
                          //                   clipBehavior: Clip
                          //                       .antiAliasWithSaveLayer,
                          //                   color: ThemeManager
                          //                       .reportContainer,
                          //                   shape:
                          //                   RoundedRectangleBorder(
                          //                     borderRadius:
                          //                     BorderRadius
                          //                         .circular(10.0),
                          //                   ),
                          //                   child: InkWell(
                          //                     onTap: () {
                          //                       store
                          //                           .featuredContent
                          //                           .value
                          //                           ?.test
                          //                           ?.isNotEmpty ??
                          //                           false
                          //                           ? showModalBottomSheet<
                          //                           void>(
                          //                         shape:
                          //                         const RoundedRectangleBorder(
                          //                           borderRadius:
                          //                           BorderRadius
                          //                               .vertical(
                          //                             top: Radius
                          //                                 .circular(
                          //                                 25),
                          //                           ),
                          //                         ),
                          //                         clipBehavior:
                          //                         Clip.antiAliasWithSaveLayer,
                          //                         context:
                          //                         context,
                          //                         builder:
                          //                             (BuildContext
                          //                         context) {
                          //                           return CustomFeaturedTestBottomSheet(
                          //                               context,
                          //                               store
                          //                                   .featuredContent
                          //                                   .value
                          //                                   ?.test?[index],
                          //                               false);
                          //                         },
                          //                       )
                          //                           : BottomToast
                          //                           .showBottomToastOverlay(
                          //                         context:
                          //                         context,
                          //                         errorMessage:
                          //                         "No Test is Found!",
                          //                         backgroundColor:
                          //                         ThemeManager
                          //                             .redAlert,
                          //                       );
                          //                     },
                          //                     child: Column(
                          //                       mainAxisAlignment:
                          //                       MainAxisAlignment
                          //                           .center,
                          //                       children: [
                          //                         SizedBox(
                          //                           height: Dimensions
                          //                               .PADDING_SIZE_EXTRA_LARGE *
                          //                               1.5,
                          //                           width: Dimensions
                          //                               .PADDING_SIZE_SMALL *
                          //                               10,
                          //                           child: Center(
                          //                               child:
                          //                               SvgPicture
                          //                                   .asset(
                          //                                 "assets/image/book_icon.svg",
                          //                               )),
                          //                         ),
                          //                         const SizedBox(
                          //                             height: Dimensions
                          //                                 .PADDING_SIZE_SMALL),
                          //                         Padding(
                          //                           padding:
                          //                           const EdgeInsets
                          //                               .only(
                          //                               left:
                          //                               10.0),
                          //                           child: Column(
                          //                               crossAxisAlignment:
                          //                               CrossAxisAlignment
                          //                                   .start,
                          //                               children: [
                          //                                 Align(
                          //                                   alignment:
                          //                                   Alignment
                          //                                       .topLeft,
                          //                                   child:
                          //                                   Text(
                          //                                     store.featuredContent.value?.test?[index].examName ??
                          //                                         "",
                          //                                     overflow:
                          //                                     TextOverflow.ellipsis,
                          //                                     style: interRegular
                          //                                         .copyWith(
                          //                                       fontSize:
                          //                                       Dimensions.fontSizeExtraSmall,
                          //                                       fontWeight:
                          //                                       FontWeight.w500,
                          //                                       color:
                          //                                       ThemeManager.black,
                          //                                     ),
                          //                                   ),
                          //                                 ),
                          //                                 const SizedBox(
                          //                                     height:
                          //                                     Dimensions.PADDING_SIZE_SMALL),
                          //                                 Text(
                          //                                   "Time Duration : ${store.featuredContent.value?.test?[index].timeDuration ?? ""}",
                          //                                   style: interRegular
                          //                                       .copyWith(
                          //                                     fontSize:
                          //                                     Dimensions.fontSizeExtraLarge /
                          //                                         2,
                          //                                     fontWeight:
                          //                                     FontWeight.w400,
                          //                                     color: Theme.of(context)
                          //                                         .hintColor,
                          //                                   ),
                          //                                 ),
                          //                                 const SizedBox(
                          //                                     height:
                          //                                     Dimensions.PADDING_SIZE_SMALL),
                          //                                 Row(
                          //                                   children: [
                          //                                     Text(
                          //                                       "Start a test",
                          //                                       style:
                          //                                       TextStyle(
                          //                                         fontSize:
                          //                                         Dimensions.fontSizeExtraLarge / 2,
                          //                                         fontWeight:
                          //                                         FontWeight.w400,
                          //                                         color:
                          //                                         Theme.of(context).primaryColor,
                          //                                       ),
                          //                                     ),
                          //                                     const SizedBox(
                          //                                         width:
                          //                                         Dimensions.PADDING_SIZE_SMALL),
                          //                                     SvgPicture
                          //                                         .asset(
                          //                                       "assets/image/forward_icon.svg",
                          //                                       color:
                          //                                       Theme.of(context).primaryColor,
                          //                                     )
                          //                                   ],
                          //                                 ),
                          //                               ]),
                          //                         )
                          //                       ],
                          //                     ),
                          //                   ),
                          //                 ),
                          //               ),
                          //             );
                          //           },
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // )
                          //     : const SizedBox(),
                          // isFeaturedPdfExist
                          //     ? Padding(
                          //   padding: const EdgeInsets.only(
                          //     top: Dimensions.PADDING_SIZE_SMALL,
                          //     left: Dimensions.PADDING_SIZE_LARGE,
                          //   ),
                          //   child: Column(
                          //     crossAxisAlignment:
                          //     CrossAxisAlignment.start,
                          //     children: [
                          //       Text(
                          //         "Featured Notes",
                          //         style: interRegular.copyWith(
                          //           fontSize:
                          //           Dimensions.fontSizeLarge,
                          //           fontWeight: FontWeight.w600,
                          //           color: ThemeManager.black,
                          //         ),
                          //       ),
                          //       const SizedBox(
                          //         height:
                          //         Dimensions.PADDING_SIZE_SMALL,
                          //       ),
                          //       SingleChildScrollView(
                          //         scrollDirection: Axis.horizontal,
                          //         child: Row(
                          //           crossAxisAlignment:
                          //           CrossAxisAlignment.start,
                          //           children: List.generate(
                          //               store.featuredContent.value
                          //                   ?.pdf?.length ??
                          //                   0, (index) {
                          //             return Padding(
                          //               padding: const EdgeInsets
                          //                   .only(
                          //                   right: Dimensions
                          //                       .PADDING_SIZE_SMALL),
                          //               child: Container(
                          //                 margin: const EdgeInsets
                          //                     .only(
                          //                     bottom: Dimensions
                          //                         .PADDING_SIZE_SMALL),
                          //                 height: (Platform
                          //                     .isWindows ||
                          //                     Platform.isMacOS)
                          //                     ? MediaQuery.of(context)
                          //                     .size
                          //                     .height *
                          //                     0.22
                          //                     : MediaQuery.of(context)
                          //                     .size
                          //                     .height *
                          //                     0.19,
                          //                 width: (Platform
                          //                     .isWindows ||
                          //                     Platform.isMacOS)
                          //                     ? MediaQuery.of(context)
                          //                     .size
                          //                     .width *
                          //                     0.15
                          //                     : MediaQuery.of(context)
                          //                     .size
                          //                     .width *
                          //                     0.4,
                          //                 decoration: BoxDecoration(
                          //                     borderRadius:
                          //                     BorderRadius
                          //                         .circular(15),
                          //                     border: Border.all(
                          //                         color: ThemeManager
                          //                             .mainBorder),
                          //                     color:
                          //                     ThemeManager.white,
                          //                     boxShadow: [
                          //                       ThemeManager.currentTheme ==
                          //                           AppTheme.Dark
                          //                           ? const BoxShadow()
                          //                           : BoxShadow(
                          //                           offset:
                          //                           const Offset(
                          //                               0, 2),
                          //                           blurRadius:
                          //                           14,
                          //                           spreadRadius:
                          //                           -5,
                          //                           color: ThemeManager
                          //                               .black
                          //                               .withOpacity(
                          //                               0.14))
                          //                     ]),
                          //                 child: InkWell(
                          //                   onTap: () {
                          //                     store
                          //                         .featuredContent
                          //                         .value
                          //                         ?.pdf?[
                          //                     index]
                          //                         .contentUrl !=
                          //                         null &&
                          //                         store
                          //                             .featuredContent
                          //                             .value
                          //                             ?.pdf?[
                          //                         index]
                          //                             .contentUrl !=
                          //                             ""
                          //                         ? Navigator.of(
                          //                         context)
                          //                         .pushNamed(
                          //                         Routes
                          //                             .featuredNotes,
                          //                         arguments: {
                          //                           'featuredNotes': store
                          //                               .featuredContent
                          //                               .value
                          //                               ?.pdf?[index]
                          //                         })
                          //                         : BottomToast
                          //                         .showBottomToastOverlay(
                          //                       context:
                          //                       context,
                          //                       errorMessage:
                          //                       "No File is Found!",
                          //                       backgroundColor:
                          //                       ThemeManager
                          //                           .redAlert,
                          //                     );
                          //                   },
                          //                   child: Column(
                          //                     crossAxisAlignment:
                          //                     CrossAxisAlignment
                          //                         .start,
                          //                     children: [
                          //                       Stack(
                          //                         alignment: Alignment
                          //                             .center,
                          //                         children: [
                          //                           ClipRRect(
                          //                               borderRadius:
                          //                               const BorderRadius
                          //                                   .only(
                          //                                 topLeft: Radius
                          //                                     .circular(
                          //                                     15),
                          //                                 topRight: Radius
                          //                                     .circular(
                          //                                     15),
                          //                               ),
                          //                               child: Image
                          //                                   .asset(
                          //                                 "assets/image/cardimage.png",
                          //                                 height: (Platform
                          //                                     .isWindows ||
                          //                                     Platform
                          //                                         .isMacOS)
                          //                                     ? MediaQuery.of(context).size.height *
                          //                                     0.134
                          //                                     : MediaQuery.of(context).size.height *
                          //                                     0.124,
                          //                                 width: double
                          //                                     .infinity,
                          //                                 fit: BoxFit
                          //                                     .fill,
                          //                               )),
                          //                           Container(
                          //                             height: (Platform
                          //                                 .isWindows ||
                          //                                 Platform
                          //                                     .isMacOS)
                          //                                 ? MediaQuery.of(context)
                          //                                 .size
                          //                                 .height *
                          //                                 0.134
                          //                                 : MediaQuery.of(context)
                          //                                 .size
                          //                                 .height *
                          //                                 0.124,
                          //                             decoration:
                          //                             BoxDecoration(
                          //                                 borderRadius:
                          //                                 const BorderRadius
                          //                                     .only(
                          //                                   topLeft:
                          //                                   Radius.circular(15),
                          //                                   topRight:
                          //                                   Radius.circular(15),
                          //                                 ),
                          //                                 gradient: LinearGradient(
                          //                                     begin:
                          //                                     Alignment.topCenter,
                          //                                     end: Alignment.bottomCenter,
                          //                                     colors: [
                          //                                       const Color(0xFF0085D0).withOpacity(0),
                          //                                       const Color(0xFF00D0AB),
                          //                                     ])),
                          //                           ),
                          //                           Container(
                          //                             height: Dimensions
                          //                                 .PADDING_SIZE_LARGE *
                          //                                 1.04,
                          //                             width: 78,
                          //                             alignment:
                          //                             Alignment
                          //                                 .center,
                          //                             decoration:
                          //                             BoxDecoration(
                          //                               borderRadius:
                          //                               BorderRadius
                          //                                   .circular(
                          //                                   56),
                          //                               color: AppColors
                          //                                   .white
                          //                                   .withOpacity(
                          //                                   0.8),
                          //                               // shape: BoxShape.circle,
                          //                             ),
                          //                             child: Text(
                          //                               "View Notes",
                          //                               style: interBold
                          //                                   .copyWith(
                          //                                 fontSize:
                          //                                 Dimensions
                          //                                     .fontSizeSmall,
                          //                                 fontWeight:
                          //                                 FontWeight
                          //                                     .w600,
                          //                                 color: AppColors
                          //                                     .black,
                          //                               ),
                          //                             ),
                          //                           ),
                          //                         ],
                          //                       ),
                          //                       Padding(
                          //                         padding: const EdgeInsets
                          //                             .fromLTRB(
                          //                             Dimensions
                          //                                 .PADDING_SIZE_EXTRA_SMALL *
                          //                                 1.6,
                          //                             Dimensions
                          //                                 .PADDING_SIZE_EXTRA_SMALL *
                          //                                 1.8,
                          //                             Dimensions
                          //                                 .PADDING_SIZE_EXTRA_SMALL *
                          //                                 1.6,
                          //                             0),
                          //                         child: Text(
                          //                           store
                          //                               .featuredContent
                          //                               .value
                          //                               ?.pdf?[
                          //                           index]
                          //                               .topicName ??
                          //                               "",
                          //                           style: interBold.copyWith(
                          //                               fontSize:
                          //                               Dimensions
                          //                                   .fontSizeSmall,
                          //                               fontWeight:
                          //                               FontWeight
                          //                                   .w600,
                          //                               color:
                          //                               ThemeManager
                          //                                   .black,
                          //                               overflow:
                          //                               TextOverflow
                          //                                   .ellipsis),
                          //                           maxLines: 2,
                          //                         ),
                          //                       ),
                          //                     ],
                          //                   ),
                          //                 ),
                          //               ),
                          //             );
                          //           }),
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // )
                          //     : const SizedBox(),

                          Padding(
                            padding: const EdgeInsets.only(
                                left: Dimensions.PADDING_SIZE_LARGE,
                                right: Dimensions.PADDING_SIZE_SMALL * 1.6,
                                top: Dimensions.PADDING_SIZE_SMALL),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Testimonial",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                    fontWeight: FontWeight.w600,
                                    color: ThemeManager.black,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    if (Platform.isWindows ||
                                        Platform.isMacOS) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor:
                                            ThemeManager.mainBackground,
                                            actionsPadding: EdgeInsets.zero,
                                            actions: [
                                              ReviewBottomSheet(
                                                store: store,
                                                userName: store.userDetails
                                                    .value?.fullname
                                                    ?.toString() ??
                                                    '',
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else {
                                      showModalBottomSheet<String>(
                                          shape:
                                          const RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.vertical(
                                              top: Radius.circular(25),
                                            ),
                                          ),
                                          clipBehavior:
                                          Clip.antiAliasWithSaveLayer,
                                          context: context,
                                          builder: (BuildContext context) {
                                            debugPrint(
                                                "usname${store.userDetails.value?.fullname?.toString() ?? ''}");
                                            return ReviewBottomSheet(
                                              store: store,
                                              userName: store.userDetails
                                                  .value?.fullname
                                                  ?.toString() ??
                                                  '',
                                            );
                                          });
                                    }
                                  },
                                  child: Container(
                                    height:
                                    Dimensions.PADDING_SIZE_SMALL * 2.7,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal:
                                        Dimensions.PADDING_SIZE_SMALL),
                                    decoration: BoxDecoration(
                                        color: ThemeManager.primaryColor,
                                        borderRadius:
                                        BorderRadius.circular(18.71)),
                                    child: Text(
                                      "+  Write review",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: Dimensions.PADDING_SIZE_LARGE,
                              top: Dimensions.PADDING_SIZE_SMALL,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: List.generate(
                                        store.getTestimonialData.length < 5
                                            ? store
                                            .getTestimonialData.length
                                            : 5, (index) {
                                      GetTestimonialListModel?
                                      getTestimonial =
                                      store.getTestimonialData[index];
                                      return Container(
                                        width: (Platform.isWindows ||
                                            Platform.isMacOS)
                                            ? MediaQuery.of(context)
                                            .size
                                            .width *
                                            0.22
                                            : MediaQuery.of(context)
                                            .size
                                            .width *
                                            0.5,
                                        margin: const EdgeInsets.only(
                                            right: Dimensions
                                                .PADDING_SIZE_SMALL),
                                        padding: const EdgeInsets.only(
                                          top: Dimensions
                                              .PADDING_SIZE_DEFAULT,
                                          left:
                                          Dimensions.PADDING_SIZE_SMALL,
                                          right:
                                          Dimensions.PADDING_SIZE_SMALL,
                                        ),
                                        decoration: BoxDecoration(
                                            color: ThemeManager.white,
                                            borderRadius:
                                            BorderRadius.circular(15),
                                            border: Border.all(
                                                color: ThemeManager
                                                    .mainBorder),
                                            boxShadow: [
                                              ThemeManager.currentTheme ==
                                                  AppTheme.Dark
                                                  ? const BoxShadow()
                                                  : BoxShadow(
                                                  offset: const Offset(
                                                      0, 2),
                                                  blurRadius: 14,
                                                  spreadRadius: -5,
                                                  color: ThemeManager
                                                      .black
                                                      .withOpacity(
                                                      0.14))
                                            ]),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              getTestimonial?.name ?? '',
                                              style: interRegular.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeSmall,
                                                  color: ThemeManager.black,
                                                  fontWeight:
                                                  FontWeight.w600),
                                            ),
                                            const SizedBox(
                                              height: Dimensions
                                                  .PADDING_SIZE_SMALL *
                                                  1.2,
                                            ),
                                            RatingBar.builder(
                                              initialRating: getTestimonial
                                                  ?.rating
                                                  ?.toDouble() ??
                                                  0,
                                              direction: Axis.horizontal,
                                              itemCount: 5,
                                              itemSize: 20,
                                              itemPadding:
                                              const EdgeInsets.only(
                                                  right: 4),
                                              itemBuilder: (context, _) =>
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                              ),
                                              ignoreGestures: true,
                                              unratedColor:
                                              ThemeManager.ratingColor,
                                              onRatingUpdate: (_) {},
                                            ),
                                            const SizedBox(
                                              height: Dimensions
                                                  .PADDING_SIZE_EXTRA_SMALL,
                                            ),
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                                  0.3,
                                              child: SingleChildScrollView(
                                                child: Text(
                                                  '"${getTestimonial?.description}"',
                                                  style: interRegular.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeExtraSmall,
                                                      color: ThemeManager
                                                          .black,
                                                      fontWeight:
                                                      FontWeight.w500),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: Dimensions
                                                  .PADDING_SIZE_SMALL,
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Observer(builder: (_) {
                            final meetingStore = Provider.of<MeetingStore>(
                                context,
                                listen: false);
                            if (meetingStore.meetingUpcoming.isEmpty) {
                              return const SizedBox();
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: Dimensions.PADDING_SIZE_LARGE,
                                  top: Dimensions.PADDING_SIZE_LARGE,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Scheduled Classes",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeLarge,
                                        fontWeight: FontWeight.w600,
                                        color: ThemeManager.black,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: Dimensions.PADDING_SIZE_SMALL,
                                    ),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            left: (Platform.isWindows ||
                                                Platform.isMacOS)
                                                ? 0
                                                : Dimensions
                                                .PADDING_SIZE_LARGE),
                                        child: Row(
                                          children: List.generate(
                                              meetingStore.meetingUpcoming
                                                  .length, (index) {
                                            ZoomLiveModel meeting =
                                            meetingStore
                                                .meetingUpcoming[index];
                                            String dateString =
                                                meeting.start_time ?? "";
                                            String formattedDate = "";
                                            String dateStringhours = "";

                                            // Try parsing the date
                                            try {
                                              DateTime dateTime =
                                              DateFormat(
                                                  "d MMM, h:mm a")
                                                  .parse(dateString);
                                              formattedDate = DateFormat(
                                                  "d MMM, h:mm a")
                                                  .format(dateTime);
                                              dateStringhours =
                                                  DateFormat('a')
                                                      .format(dateTime)
                                                      .toUpperCase();
                                            } catch (e) {
                                              print(
                                                  "Date parsing error: $e");
                                              formattedDate = dateString
                                                  .isNotEmpty
                                                  ? dateString
                                                  : "Date not available";
                                            }

                                            return Padding(
                                              padding:
                                              const EdgeInsets.only(
                                                  right: 10),
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.of(context)
                                                      .pushNamed(Routes
                                                      .liveClassMainScreen);
                                                },
                                                child: Container(
                                                  width: (Platform
                                                      .isWindows ||
                                                      Platform.isMacOS)
                                                      ? MediaQuery.of(
                                                      context)
                                                      .size
                                                      .width *
                                                      0.22
                                                      : MediaQuery.of(
                                                      context)
                                                      .size
                                                      .width *
                                                      0.4,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                      BorderRadius
                                                          .circular(15),
                                                      color: ThemeManager
                                                          .white,
                                                      boxShadow: [
                                                        BoxShadow(
                                                            offset:
                                                            const Offset(
                                                                0, 2),
                                                            blurRadius: 14,
                                                            spreadRadius:
                                                            -5,
                                                            color: ThemeManager
                                                                .black
                                                                .withOpacity(
                                                                0.14))
                                                      ]),
                                                  child: Column(
                                                    children: [
                                                      Stack(
                                                        alignment: Alignment
                                                            .center,
                                                        children: [
                                                          ClipRRect(
                                                              borderRadius:
                                                              const BorderRadius
                                                                  .only(
                                                                topLeft: Radius
                                                                    .circular(
                                                                    15),
                                                                topRight: Radius
                                                                    .circular(
                                                                    15),
                                                              ),
                                                              child: Image.asset(
                                                                  "assets/image/cardimage.png",
                                                                  height: (Platform.isWindows ||
                                                                      Platform
                                                                          .isMacOS)
                                                                      ? MediaQuery.of(context).size.height *
                                                                      0.150
                                                                      : MediaQuery.of(context).size.height *
                                                                      0.124,
                                                                  width: double
                                                                      .infinity,
                                                                  fit: BoxFit
                                                                      .fill)),
                                                          Container(
                                                            height: (Platform
                                                                .isWindows ||
                                                                Platform
                                                                    .isMacOS)
                                                                ? MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                                0.150
                                                                : MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                                0.124,
                                                            decoration:
                                                            BoxDecoration(
                                                                borderRadius:
                                                                const BorderRadius
                                                                    .only(
                                                                  topLeft:
                                                                  Radius.circular(15),
                                                                  topRight:
                                                                  Radius.circular(15),
                                                                ),
                                                                gradient: LinearGradient(
                                                                    begin:
                                                                    Alignment.topCenter,
                                                                    end: Alignment.bottomCenter,
                                                                    colors: [
                                                                      const Color(0xFFD01900).withOpacity(0),
                                                                      const Color(0xFFFF6B00),
                                                                    ])),
                                                          ),
                                                          Container(
                                                            height: 36,
                                                            width: 36,
                                                            alignment:
                                                            Alignment
                                                                .center,
                                                            decoration:
                                                            BoxDecoration(
                                                              color: ThemeManager
                                                                  .white
                                                                  .withOpacity(
                                                                  0.8),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: SvgPicture
                                                                .asset(
                                                                "assets/image/shedulecalendar.svg"),
                                                          ),
                                                        ],
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets
                                                            .fromLTRB(
                                                            Dimensions
                                                                .PADDING_SIZE_EXTRA_SMALL *
                                                                1.6,
                                                            Dimensions
                                                                .PADDING_SIZE_EXTRA_SMALL *
                                                                1.8,
                                                            Dimensions
                                                                .PADDING_SIZE_EXTRA_SMALL *
                                                                1.6,
                                                            Dimensions
                                                                .PADDING_SIZE_DEFAULT *
                                                                1.1),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                          children: [
                                                            Text(
                                                              meetingStore
                                                                  .meetingUpcoming[
                                                              index]
                                                                  .topic ??
                                                                  "",
                                                              style: interBold
                                                                  .copyWith(
                                                                fontSize:
                                                                Dimensions
                                                                    .fontSizeSmall,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                                color: ThemeManager
                                                                    .black,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 2),
                                                            Text(
                                                              meetingStore
                                                                  .meetingUpcoming[
                                                              index]
                                                                  .description ??
                                                                  "",
                                                              style: interBold
                                                                  .copyWith(
                                                                fontSize:
                                                                Dimensions
                                                                    .fontSizeExtraSmall,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w400,
                                                                color: ThemeManager
                                                                    .textColor6,
                                                              ),
                                                              overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                            ),
                                                            const SizedBox(
                                                                height: Dimensions
                                                                    .PADDING_SIZE_SMALL *
                                                                    1.1),
                                                            Row(
                                                              children: [
                                                                SvgPicture
                                                                    .asset(
                                                                    "assets/image/time.svg"),
                                                                const SizedBox(
                                                                    width: Dimensions
                                                                        .PADDING_SIZE_EXTRA_SMALL),
                                                                Text(
                                                                  "$formattedDate ${dateStringhours.toUpperCase()}",
                                                                  style: interBold
                                                                      .copyWith(
                                                                    fontSize:
                                                                    Dimensions.fontSizeExtraSmall,
                                                                    fontWeight:
                                                                    FontWeight.w500,
                                                                    color: ThemeManager
                                                                        .black,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }),
                          const SizedBox(
                              height: Dimensions.PADDING_SIZE_LARGE),
                          //Offer Bottom Banner
                          // bottomImgList.isNotEmpty?
                          // Padding(
                          //     padding: const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                          //     child: ClipRRect(
                          //         borderRadius: BorderRadius.circular(10),child:CarouselSlider(
                          //       items: bottomImageSliders,
                          //       carouselController: _bottomController,
                          //       options: CarouselOptions(
                          //           viewportFraction: 1,
                          //           enlargeCenterPage: true,
                          //           height: 165
                          //       ),
                          //     ) ) ):const SizedBox(),
                          // const SizedBox(height: 90,),

                          if (!Platform.isMacOS) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal:
                                  Dimensions.PADDING_SIZE_SMALL * 1.6),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                      CupertinoPageRoute(
                                          builder: (context) =>
                                          const AskQuestionScreen()));
                                },
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                      Dimensions.PADDING_SIZE_DEFAULT * 1.5,
                                      Dimensions.PADDING_SIZE_SMALL * 1.6,
                                      Dimensions.PADDING_SIZE_SMALL * 1.9,
                                      Dimensions.PADDING_SIZE_SMALL * 1.6),
                                  decoration: BoxDecoration(
                                    color: ThemeManager.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: ThemeManager.mainBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Image.asset("assets/image/ask.png"),
                                      const SizedBox(
                                          width: Dimensions
                                              .PADDING_SIZE_LARGE),
                                      Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Ask Cortex.ai",
                                              style: interRegular.copyWith(
                                                fontSize: Dimensions
                                                    .fontSizeExtraLarge,
                                                fontWeight: FontWeight.w600,
                                                color: ThemeManager.black,
                                              ),
                                            ),
                                            Text(
                                              "Start a conversation now",
                                              style: interRegular.copyWith(
                                                fontSize: Dimensions
                                                    .fontSizeSmall,
                                                fontWeight: FontWeight.w400,
                                                color: ThemeManager.black,
                                              ),
                                            ),
                                          ]),
                                      const Spacer(),
                                      SvgPicture.asset(
                                        "assets/image/arrow-right.svg",
                                        color: ThemeManager.black,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(
                              height: Dimensions.PADDING_SIZE_LARGE),
                        ],
                      ))
                      : const NoInternetScreen();
                },
              ),
              if (store.getDeclaration?.categoryId != null &&
                  isResultVisible) ...[
                Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.PADDING_SIZE_DEFAULT,
                      vertical: Dimensions.PADDING_SIZE_SMALL,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeManager.blueFinalDark,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      border: ThemeManager.currentTheme == AppTheme.Light
                          ? null
                          : Border(
                        top: BorderSide(
                          color: ThemeManager.black,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                isResultVisible = false;
                              });
                            },
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Image.asset(
                                            "assets/image/result.png",
                                            width: 28,
                                            height: 28,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Result Declared",
                                            style: interBold.copyWith(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Expanded(
                                        child: Text(
                                          "${store.getDeclaration!.categoryName} | ${store.getDeclaration!.examName}\nRanking & Leaderboard Now Available.",
                                          style: interRegular.copyWith(
                                            fontSize: 12,
                                            color:
                                            Colors.white.withOpacity(0.9),
                                            height: 1.2,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                      width: Dimensions.PADDING_SIZE_DEFAULT),
                                ],
                              ),
                            ),
                            Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(0xff648DDB),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) => RankListScreen(
                                            examId:
                                            store.getDeclaration!.examId!,
                                          ),
                                        ));
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 0,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Check Now",
                                          style: interRegular.copyWith(
                                            fontSize: 13,
                                            color: ThemeManager.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          size: 16,
                                          color: ThemeManager.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // final GoogleSignIn _googleSignIn = GoogleSignIn();
  void signOut(HomeStore store, String loggedInPlatform) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? loggedInEmail = prefs.getBool('isloggedInEmail');
    bool? loggedInWt = prefs.getBool('isLoggedInWt');
    // bool? signInGoogle = prefs.getBool('isSignInGoogle');
    String? fcmToken = prefs.getString('fcmtoken');
    
    // Try to call the API logout, but don't block local logout if it fails
    try {
      await store.onSignoutUser(loggedInPlatform);
    } catch (e) {
      print("API logout failed, proceeding with local logout: $e");
    }

    // Perform local logout operations regardless of API call success
    // If user reached this screen, they must be logged in, so always allow logout
    String? token = prefs.getString('token');
    bool shouldLogout = true; // Always allow logout if user clicked logout button
    
    print("Logout Debug - loggedInEmail: $loggedInEmail, loggedInWt: $loggedInWt, token: ${token?.substring(0, token != null && token.length > 10 ? 10 : token?.length ?? 0)}..., shouldLogout: $shouldLogout, platform: ${Platform.operatingSystem}");
    
    if (shouldLogout) {
      prefs.setString('token', '');
      prefs.setString('fcmtoken', '');
      prefs.setBool('isLoggedInWt', false);
      prefs.setBool('isloggedInEmail', false);
      prefs.setBool('isSignInGoogle', false);
      prefs.clear();
      ThemeManager.currentTheme == AppTheme.Dark
          ? Provider.of<ThemeNotifier>(context, listen: false).toggleTheme()
          : null;
      // Navigator.of(context).pushNamed(Routes.loginWithPass);
      Navigator.of(context).pushNamed(Routes.login);
      print("User Logged Out - Navigation to login screen executed");
    } else {
      print("Logout failed - shouldLogout condition not met");
    }
    // Only delete FCM token on mobile platforms where FCM is available
    if (fcmToken != null && !Platform.isWindows && !Platform.isMacOS) {
      try {
        await store.onDeleteNotificationToken(fcmToken);
      } catch (e) {
        print("FCM token deletion failed: $e");
      }
    }
  }

  void signOutAllDevice(HomeStore store) async {
    await store.onSignoutUserAllDevice();
  }

  Future<void> _deleteAccountUser(HomeStore store) async {
    await store.onDeleteUserAccountCall(store.userDetails.value?.sid ?? '');
    Navigator.of(context).pushNamed(Routes.login);
  }
}

class ThemeComponent extends StatelessWidget {
  const ThemeComponent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      width: MediaQuery.of(context).size.width,
      constraints: (Platform.isWindows || Platform.isMacOS)
          ? const BoxConstraints(maxWidth: Dimensions.WEB_MAX_WIDTH * 0.4)
          : null,
      decoration: BoxDecoration(
          color: ThemeManager.reportContainer,
          borderRadius: (Platform.isWindows || Platform.isMacOS)
              ? BorderRadius.circular(12)
              : null),
      child: Padding(
        padding: const EdgeInsets.only(
            top: Dimensions.PADDING_SIZE_EXTRA_LARGE,
            bottom: Dimensions.PADDING_SIZE_EXTRA_LARGE,
            left: Dimensions.PADDING_SIZE_EXTRA_LARGE,
            right: Dimensions.PADDING_SIZE_EXTRA_LARGE),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Choose Theme",
                style: interSemiBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  fontWeight: FontWeight.w600,
                  color: ThemeManager.black,
                ),
              ),
            ),
            const SizedBox(
              height: Dimensions.PADDING_SIZE_LARGE,
            ),
            Text(
              "Please Select Theme",
              style: interSemiBold.copyWith(
                fontSize: Dimensions.fontSizeExtraLarge,
                fontWeight: FontWeight.w600,
                color: ThemeManager.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Theme.of(context).primaryColor),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Light Theme",
                        style: TextStyle(
                          fontSize: Dimensions.fontSizeDefault,
                          fontWeight: FontWeight.w400,
                          color: ThemeManager.currentTheme == AppTheme.Dark
                              ? ThemeManager.white
                              : Colors.white,
                        ),
                      )),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Theme.of(context).primaryColor),
                      onPressed: () async {
                        Provider.of<ThemeNotifier>(context, listen: false)
                            .toggleTheme();
                        SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                        await prefs.setBool("first_Time", false);
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Dark Theme",
                        style: TextStyle(
                          fontSize: Dimensions.fontSizeDefault,
                          fontWeight: FontWeight.w400,
                          color: ThemeManager.currentTheme == AppTheme.Dark
                              ? ThemeManager.white
                              : Colors.white,
                        ),
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UpdateButton extends StatelessWidget {
  const UpdateButton({super.key, required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      width: double.infinity,
      decoration: BoxDecoration(
        color: ThemeManager.blueFinal,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/image/logo.png",
                  width: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  data['store'] != data['current']
                      ? 'Update available'
                      : 'App Version : ${data['current']}',
                  style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: ThemeManager.white,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
            if (data['store'] != data['current']) ...[
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  await launchUrl(Uri.parse(data['url']));
                },
                child: Container(
                  height: 23,
                  decoration: BoxDecoration(
                      color: ThemeManager.white,
                      borderRadius: BorderRadius.circular(5)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      child: Text(
                        'Update',
                        style: interMedium.copyWith(
                            fontSize: 10,
                            color: ThemeManager.blueFinal,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

Widget learnFromWidget(String name, String path, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Image.asset(
          path,
          height: 22,
          width: 22,
        ),
        Text(
          name,
          style: interRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            fontWeight: FontWeight.w500,
            color: ThemeManager.black,
          ),
        ),
      ],
    ),
  );
}