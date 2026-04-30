import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/modules/bottom/moreMenuBottomSheetContainer.dart';

import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../cortex/cortex_home_screen.dart';
import '../dashboard/home_screen.dart';
import 'bottomNavigationItemContainer.dart';
import 'homeBottomSheetMenu.dart';

class HomeScreenSecond extends StatefulWidget {
  final bool trial;
  const HomeScreenSecond({super.key, required this.trial});

  @override
  State<HomeScreenSecond> createState() => HomeScreenSecondState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      return CupertinoPageRoute(builder: (_) => HomeScreenSecond(trial: arguments['trial']));
    } else {
      return CupertinoPageRoute(builder: (_) => const HomeScreenSecond(trial: false));
    }
  }
}

class HomeScreenSecondState extends State<HomeScreenSecond> with TickerProviderStateMixin {
  late AnimationController _animationController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 500),
  );
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Animation<double> _bottomNavAndTopProfileAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

  late AnimationController _moreMenuBottomsheetAnimationController = AnimationController(
    vsync: this,
    duration: homeMenuBottomSheetAnimationDuration,
  );

  Duration homeMenuBottomSheetAnimationDuration = const Duration(milliseconds: 300);

  late final List<AnimationController> _bottomNavItemTitlesAnimationController = [];

  late Animation<Offset> _moreMenuBottomsheetAnimation = Tween<Offset>(
    begin: Offset(0.0, 1.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _moreMenuBottomsheetAnimationController, curve: Curves.easeInOut));

  late Animation<double> _moreMenuBackgroundContainerColorAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _moreMenuBottomsheetAnimationController, curve: Curves.easeInOut));

  late int _currentSelectedBottomNavIndex = 0;
  late int _previousSelectedBottmNavIndex = -1;

  //index of opened homeBottomshet menu
  late int _currentlyOpenMenuIndex = -1;

  late bool _isMoreMenuOpen = false;

  List<BottomNavItem> _bottomNavItems = [
    BottomNavItem(
      activeImageUrl: "assets/image/home.svg",
      disableImageUrl: "assets/image/home1.svg",
      title: "Home",
    ),
    BottomNavItem(
      activeImageUrl: "assets/image/ask_cortex.svg",
      disableImageUrl: "assets/image/ask_cortex1.svg",
      title: "Ask Cortex.ai",
    ),
    BottomNavItem(
      activeImageUrl: "assets/image/menu.svg",
      disableImageUrl: "assets/image/menu1.svg",
      title: "Menu",
    ),
  ];

  late List<GlobalKey> _bottomNavItemShowCaseKey = [];
  bool isloading = false;
  String? child_name, child_profile_img, class_id;
  var getcall;
  DateTime? currentDateTime;
  DateTime? pastDateTime;
  @override
  void initState() {
    super.initState();
    // Commented out - free trial is no longer automatically activated during registration
    // widget.trial ? trialAlertBox(context) : null;
    debugPrint("widget.trial:${widget.trial}");
    initAnimations();
    initShowCaseKeys();
    _animationController.forward();

    isloading = true;

    // getparent = Get.put(parentProfileController().parentDetails().then((value) {
    //   _getParent = value;
    // }));
  }

  Future<void> trialAlertBox(BuildContext context) async {
    currentDateTime = DateTime.now();

    // Calculate 72 hours ago
    pastDateTime = currentDateTime?.add(Duration(hours: 72));
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
                      color: ThemeManager.primaryColor,
                    ),
                  ),
                  SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                  Text(
                    'Your Free Trial has been automatically activated! Enjoy access for 72 hours.',
                    textAlign: TextAlign.start,
                    style: interBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: ThemeManager.primaryColor,
                    ),
                  ),
                  SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                  Text(
                    'Your Free Trial will Expire on $formattedPastDateTime Explore all courses and features.',
                    textAlign: TextAlign.start,
                    style: interBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: ThemeManager.primaryColor,
                    ),
                  ),
                  SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Happy Learning!',
                      textAlign: TextAlign.center,
                      style: interBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: ThemeManager.primaryColor,
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
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primaryColor, // Set the background color
              ),
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

  void _updateState() {
    if (mounted) {
      setState(() {
        isloading = false;
      });
    }
  }

  void navigateToAssignmentContainer() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    _changeBottomNavItem(1);
  }

  void initAnimations() {
    for (var i = 0; i < _bottomNavItems.length; i++) {
      _bottomNavItemTitlesAnimationController.add(
        AnimationController(
          value: i == _currentSelectedBottomNavIndex ? 0.0 : 1.0,
          vsync: this,
          duration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  void initShowCaseKeys() {
    for (var i = 0; i < _bottomNavItems.length; i++) {
      _bottomNavItemShowCaseKey.add(GlobalKey());
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var animationController in _bottomNavItemTitlesAnimationController) {
      animationController.dispose();
    }
    _moreMenuBottomsheetAnimationController.dispose();
    super.dispose();
  }

  void _changeBottomNavItem(int index) async {
    if (_moreMenuBottomsheetAnimationController.isAnimating) {
      return;
    }
    _bottomNavItemTitlesAnimationController[_currentSelectedBottomNavIndex].forward();

    //need to assign previous selected bottom index only if menu is close
    if (!_isMoreMenuOpen && _currentlyOpenMenuIndex == -1) {
      _previousSelectedBottmNavIndex = _currentSelectedBottomNavIndex;
    }

    //change current selected bottom index
    setState(() {
      _currentSelectedBottomNavIndex = index;

      //if user taps on non-last bottom nav item then change _currentlyOpenMenuIndex
      if (_currentSelectedBottomNavIndex != _bottomNavItems.length - 1) {
        _currentlyOpenMenuIndex = -1;
      }
    });

    _bottomNavItemTitlesAnimationController[_currentSelectedBottomNavIndex].reverse();

    //if bottom index is last means open/close the bottom sheet
    if (index == _bottomNavItems.length - 1) {
      if (_moreMenuBottomsheetAnimationController.isCompleted) {
        //close the menu
        await _moreMenuBottomsheetAnimationController.reverse();

        setState(() {
          _isMoreMenuOpen = !_isMoreMenuOpen;
        });

        //change bottom nav to previous selected index
        //only if there is not any opened menu item container
        if (_currentlyOpenMenuIndex == -1) {
          _changeBottomNavItem(_previousSelectedBottmNavIndex);
        }
      } else {
        //open menu
        await _moreMenuBottomsheetAnimationController.forward();
        setState(() {
          _isMoreMenuOpen = !_isMoreMenuOpen;
        });
      }
    } else {
      //if current selected index is not last index(bottom nav item)
      //and menu is open then close the menu
      if (_moreMenuBottomsheetAnimationController.isCompleted) {
        await _moreMenuBottomsheetAnimationController.reverse();
        setState(() {
          _isMoreMenuOpen = !_isMoreMenuOpen;
        });
      }
    }
  }

  void _closeBottomMenu() async {
    if (_currentlyOpenMenuIndex == -1) {
      //close the menu and change bottom sheet
      _changeBottomNavItem(_previousSelectedBottmNavIndex);
    } else {
      await _moreMenuBottomsheetAnimationController.reverse();
      setState(() {
        _isMoreMenuOpen = !_isMoreMenuOpen;
      });
    }
  }

  void _onTapMoreMenuItemContainer(int index) async {
    await _moreMenuBottomsheetAnimationController.reverse();
    _currentlyOpenMenuIndex = index;
    _isMoreMenuOpen = !_isMoreMenuOpen;
    setState(() {});
  }

  Widget _buildBottomNavigationContainer() {
    return FadeTransition(
      opacity: _bottomNavAndTopProfileAnimation,
      child: SlideTransition(
        position: _bottomNavAndTopProfileAnimation.drive(
          Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero),
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(
                color: AppTokens.border(context).withOpacity(0.6),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          height: 72,
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, boxConstraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _bottomNavItems.map((bottomNavItem) {
                    int index = _bottomNavItems
                        .indexWhere((e) => e.title == bottomNavItem.title);
                    return BottomNavItemContainer(
                      showCaseKey: _bottomNavItemShowCaseKey[index],
                      showCaseDescription: bottomNavItem.title,
                      onTap: _changeBottomNavItem,
                      boxConstraints: boxConstraints,
                      currentIndex: _currentSelectedBottomNavIndex,
                      bottomNavItem: _bottomNavItems[index],
                      animationController:
                          _bottomNavItemTitlesAnimationController[index],
                      index: index,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreMenuBackgroundContainer() {
    return GestureDetector(
      onTap: () async {
        _closeBottomMenu();
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        // Apple-style scrim — slightly less opaque than 0.75 so the
        // content underneath stays subtly visible.
        color: Colors.black.withOpacity(0.55),
      ),
    );
  }

  Widget _buildMenuItemContainer() {
    print("menuitemtitle");
    print(homeBottomSheetMenu[_currentlyOpenMenuIndex].title);
    // if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == "Videos") {
    //   return Container();
    // }
    // if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == "Tests") {
    //   return Container();
    // }
    // if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == "Notes") {
    //   return Container();
    // }
    // if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == "Analysis & Solutions") {
    //   return Container();
    // }
    // if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == "Mock Exam Analysis") {
    //   return Container();
    // }
    // if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == "offline notes") {
    //   return Container();
    // }
    // if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == "My Plan") {
    //   return Container();
    // }
    // if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == "Subscription Plan") {
    //   return Container();
    // }
    // if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == "Notification") {
    //   return Container();
    // }
    // if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == "Bookmarks") {
    //   return Container();
    // }
    // if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == "Mock Exam Bookmarks") {
    //   return Container();
    // }
    // if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == "Privacy Policy") {
    //   return Container();
    // }
    // if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == "Refund Policy") {
    //   return Container();
    // }
    // if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == "Terms & Conditions") {
    //   return Container();
    // }
    return SizedBox();
  }

  int _backButtonPressCount = 0;

  Future<bool> _handleBackPressed() async {
    if (_isMoreMenuOpen) {
      _closeBottomMenu();
      return Future.value(false);
    }
    if (_currentSelectedBottomNavIndex != 0) {
      _changeBottomNavItem(0);
      return Future.value(false);
    }
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
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: [
            IndexedStack(
              index: _currentSelectedBottomNavIndex,
              children: [
                HomeScreen(scaffoldKey: _scaffoldKey),
                // AskQuestionScreen(),
                CortexHomeScreen(),
                _currentlyOpenMenuIndex != -1
                    ? _buildMenuItemContainer()
                    : _previousSelectedBottmNavIndex == 0
                    ? HomeScreen(scaffoldKey: _scaffoldKey)
                    : _previousSelectedBottmNavIndex == 1
                    // ? AskQuestionScreen()
                    ? CortexHomeScreen()
                    : SizedBox(),
              ],
            ),
            IgnorePointer(
              ignoring: !_isMoreMenuOpen,
              child: FadeTransition(
                opacity: _moreMenuBackgroundContainerColorAnimation,
                child: _buildMoreMenuBackgroundContainer(),
              ),
            ),

            // More menu bottom sheet
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: _moreMenuBottomsheetAnimation,
                child: MoreMenuBottomsheetContainer(
                  closeBottomMenu: _closeBottomMenu,
                  // onTapMoreMenuItemContainer:
                  // _onTapMoreMenuItemContainer,
                ),
              ),
            ),
            Align(alignment: Alignment.bottomCenter, child: _buildBottomNavigationContainer()),
          ],
        ),
      ),
    );
  }
}
