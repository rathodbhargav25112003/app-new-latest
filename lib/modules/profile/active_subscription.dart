// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, avoid_print, use_build_context_synchronously, constant_identifier_names, non_constant_identifier_names, unnecessary_null_comparison, invalid_null_aware_operator, dead_code

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/models/subscribed_plan_model.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
import 'package:shusruta_lms/modules/login/store/login_store.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/model/ordered_book_model.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/store/ordered_book_store.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';
import 'package:shusruta_lms/modules/widgets/custom_button.dart';
import 'package:shusruta_lms/modules/widgets/no_internet_connection.dart';

import '../../helpers/styles.dart';

/// Local platform-shorthand used to toggle hero-header/border-radius
/// between desktop & mobile surfaces.
bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

/// The authenticated user's profile & subscription home screen.
///
/// Renders the logged-in header card, subscribed plan tiles, order history
/// (ordered hard-copy books), and a bottom bar with Delete Account / Log Out
/// actions.
///
/// Preserved public contract:
///   • `ActiveSubscriptionScreen({super.key, this.isHome = false})`
///     with final `isHome` field.
///   • Static `route(RouteSettings)` factory wrapping the widget in a
///     `MultiProvider` that creates fresh `SubscriptionStore`,
///     `OrderedBookStore`, and `LoginStore` instances and returns a
///     `CupertinoPageRoute`.
///   • `initState` sequence preserved byte-for-byte:
///     `_loginStore = Provider.of<LoginStore>(context, listen: false)`,
///     `_loadSettingsData()` → `_loginStore.onGetSettingsData()`,
///     `_getOrderHistory()` → `SubscriptionStore.onGetUserAllOrderHistory()`,
///     direct `_orderedBookStore = OrderedBookStore()` instantiation
///     (NOT via Provider — comment "avoid provider issues"),
///     `_getUserOrderedBooks()` → `_orderedBookStore.getAllUserBooks()`,
///     `SubscriptionStore.onRegisterApiCall(context, true, false)`,
///     `SubscriptionStore.onGetSubscribedUserPlan()`, and
///     `_checkIsLoggedIn()` reading SharedPreferences keys
///     `isloggedInEmail`, `isSignInGoogle`, `isLoggedInWt`.
///   • `_deleteAccountUser(HomeStore)` calls
///     `store.onDeleteUserAccountCall(store.userDetails.value?.sid ?? '')`
///     then pushes `Routes.login`.
///   • `_getPlatformString()` returns the literal strings
///     `"macOSDesktop"`, `"windowsDesktop"`, `"iOSMobile"`,
///     `"androidMobile"`, `"unknownDesktop"`.
///   • `signOut(HomeStore, String)` always performs local logout
///     regardless of API result, clears `token`/`fcmtoken`/all prefs,
///     toggles theme off Dark, navigates to `Routes.login`, and only
///     calls `onDeleteNotificationToken` on mobile platforms
///     (skipped on `Platform.isWindows || Platform.isMacOS`).
///   • `clearAppData()` clears `getTemporaryDirectory()`,
///     `getApplicationDocumentsDirectory()`, and all SharedPreferences.
///   • Delete-Account / Log-Out dialogs preserved: the literal
///     messages "Are you sure you want to Delete Account?" and
///     "Are you sure you want to log out?", plus the floating SVG
///     icons `assets/image/deleteAccount.svg` and `assets/image/log-out.svg`
///     positioned above the dialog body.
///   • The macOS IAP guard — `_loginStore.settingsData.value?.isInAPurchases == true && Platform.isMacOS`
///     hides the entire Order History section — preserved byte-for-byte.
///   • `Consumer<HomeStore>` profile header navigates to `Routes.editProfile`
///     with `arguments: {'userprofile': homeStore.userDetails.value}`.
///   • "No Subscribed Plans Found" empty state navigates to
///     `Routes.newSubscription` with `{'showBackButton': true}`.
///   • Public state helpers preserved: `formatTime(int)`,
///     `formatDate(String)`, `orderFormatDate(String)` with ordinal
///     day suffixes (st/nd/rd/th) — `buildSubscribedPlansView()`,
///     `_buildOrderedBookCard(BuildContext, OrderedBookModel)`,
///     `_buildInfoColumn(String, String)`.
///   • Top-level `buildSubscribedPlanItem(BuildContext, int)` and
///     `_buildFeatureRow(IconData, String)` preserved.
///   • Public class `UpgradePlanPopup` with required
///     `DateTime currentExpiryDate` and
///     `void Function(String selectedMode) onProceed`, plus
///     `_UpgradePlanPopupState` with its `'same-validity'` /
///     `'new-validity'` radio contract.
///   • `UpgradePlanPopup` decision feeds `Routes.selectUpgradePlan`
///     with `{subscriptionId, sameValidity, isDiffValidity, upgradeMode}`.
///   • Ordered-book card push to `Routes.trackOrder` with
///     `{orderId, productName, bookType, quantity}` preserved.
class ActiveSubscriptionScreen extends StatefulWidget {
  const ActiveSubscriptionScreen({super.key, this.isHome = false});
  final bool isHome;

  @override
  State<ActiveSubscriptionScreen> createState() => _ActiveSubscriptionScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => MultiProvider(
        providers: [
          Provider<SubscriptionStore>(create: (_) => SubscriptionStore()),
          Provider<OrderedBookStore>(create: (_) => OrderedBookStore()),
          Provider<LoginStore>(create: (_) => LoginStore()),
        ],
        child: const ActiveSubscriptionScreen(),
      ),
    );
  }
}

class _ActiveSubscriptionScreenState extends State<ActiveSubscriptionScreen> {
  // ignore: unused_field
  final int _selectedIndex = 0;
  bool loggedIn = false;
  String formattedDateTime = '';
  Future<bool>? isLogged;
  late OrderedBookStore _orderedBookStore;
  late LoginStore _loginStore;

  @override
  void initState() {
    super.initState();
    _loginStore = Provider.of<LoginStore>(context, listen: false);
    _loadSettingsData();
    _getOrderHistory();

    // Initialize the OrderedBookStore directly to avoid provider issues
    _orderedBookStore = OrderedBookStore();
    _getUserOrderedBooks();

    final store = Provider.of<SubscriptionStore>(context, listen: false);
    store.onRegisterApiCall(context, true, false);
    // store.onRegisterApiCall(context,'');
    store.onGetSubscribedUserPlan();
    isLogged = _checkIsLoggedIn();
    isLogged!.then((value) {
      if (!mounted) return;
      setState(() {
        loggedIn = value;
      });
    });
  }

  Future<void> _loadSettingsData() async {
    await _loginStore.onGetSettingsData();
  }

  Future<void> _deleteAccountUser(HomeStore store) async {
    await store.onDeleteUserAccountCall(store.userDetails.value?.sid ?? '');
    if (!mounted) return;
    Navigator.of(context).pushNamed(Routes.login);
  }

  /// Get platform-specific string for logout/delete account operations.
  String _getPlatformString() {
    if (Platform.isMacOS) {
      return "macOSDesktop";
    } else if (Platform.isWindows) {
      return "windowsDesktop";
    } else if (Platform.isIOS) {
      return "iOSMobile";
    } else if (Platform.isAndroid) {
      return "androidMobile";
    } else {
      return "unknownDesktop";
    }
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

  Future<void> _getOrderHistory() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetUserAllOrderHistory();
  }

  Future<void> _getUserOrderedBooks() async {
    // Use the instance variable directly instead of Provider
    await _orderedBookStore.getAllUserBooks();
  }

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

    print(
        "Logout Debug - loggedInEmail: $loggedInEmail, loggedInWt: $loggedInWt, token: ${token?.substring(0, token != null && token.length > 10 ? 10 : token?.length ?? 0)}..., shouldLogout: $shouldLogout, platform: ${Platform.operatingSystem}");

    if (shouldLogout) {
      prefs.setString('token', '');
      prefs.setString('fcmtoken', '');
      prefs.setBool('isLoggedInWt', false);
      prefs.setBool('isloggedInEmail', false);
      prefs.setBool('isSignInGoogle', false);
      prefs.clear();
      if (!mounted) return;
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

  Future<void> clearAppData() async {
    // Clear cache directory
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
      }
    } catch (e) {
      print("Error clearing cache: $e");
    }

    // Clear app documents directory
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      if (appDocDir.existsSync()) {
        appDocDir.deleteSync(recursive: true);
      }
    } catch (e) {
      print("Error clearing app documents: $e");
    }

    // Clear SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print("Error clearing SharedPreferences: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SubscriptionStore>(context);
    final homeStore = Provider.of<HomeStore>(context);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: ThemeManager.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
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
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_LARGE),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: ThemeManager.white,
                                    ),
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: Dimensions.PADDING_SIZE_LARGE * 1.7,
                                        ),
                                        Text(
                                          "Are you sure you want to Delete Account?",
                                          style: interMedium.copyWith(
                                              fontSize: Dimensions.fontSizeDefault,
                                              color: ThemeManager.black,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(
                                          height: Dimensions.PADDING_SIZE_SMALL * 1.3,
                                        ),
                                        Container(
                                          // width: MediaQuery.of(context)
                                          //         .size
                                          //         .width *
                                          //     0.5,
                                          child: Row(
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  _deleteAccountUser(homeStore);
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  alignment: Alignment.center,
                                                  constraints: const BoxConstraints(minWidth: 20),
                                                  decoration: BoxDecoration(
                                                    color: ThemeManager.logOutContainer.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    "Delete Account",
                                                    style: interBold.copyWith(
                                                        fontSize: Dimensions.fontSizeDefault,
                                                        fontWeight: FontWeight.w400,
                                                        color: ThemeManager.logOutContainer,
                                                        height: 0),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: Dimensions.PADDING_SIZE_SMALL * 2.2,
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  // signOut(store, loggedInPlatform);
                                                  Navigator.pop(context);
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  alignment: Alignment.center,
                                                  constraints: const BoxConstraints(minWidth: 20),
                                                  decoration: BoxDecoration(
                                                    color: ThemeManager.logOutContainer,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    "Cancel",
                                                    style: interBold.copyWith(
                                                        fontSize: Dimensions.fontSizeSmall,
                                                        fontWeight: FontWeight.w600,
                                                        color: ThemeManager.white,
                                                        height: 0),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: Dimensions.PADDING_SIZE_SMALL * 2.2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: -MediaQuery.of(context).size.height * 0.026,
                                    child: Container(
                                      height: 48,
                                      width: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: ThemeManager.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFE5E5E5)),
                                          boxShadow: [
                                            BoxShadow(
                                              offset: const Offset(0, 4),
                                              blurRadius: 14,
                                              spreadRadius: -2,
                                              color: ThemeManager.black.withOpacity(0.05),
                                            ),
                                          ]),
                                      child: SvgPicture.asset("assets/image/deleteAccount.svg"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Delete Account',
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: ThemeManager.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      await clearAppData();
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
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_LARGE),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: ThemeManager.white,
                                    ),
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: Dimensions.PADDING_SIZE_LARGE * 1.7,
                                        ),
                                        Text(
                                          "Are you sure you want to log out?",
                                          style: interMedium.copyWith(
                                              fontSize: Dimensions.fontSizeDefault,
                                              color: ThemeManager.black,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(
                                          height: Dimensions.PADDING_SIZE_SMALL * 1.3,
                                        ),
                                        Container(
                                          // width: MediaQuery.of(context)
                                          //         .size
                                          //         .width *
                                          //     0.5,
                                          child: Row(
                                            children: [
                                              InkWell(
                                                onTap: () async {
                                                  Navigator.pop(context); // Close dialog first
                                                  await clearAppData();
                                                  signOut(homeStore, _getPlatformString());
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  alignment: Alignment.center,
                                                  constraints: const BoxConstraints(minWidth: 20),
                                                  decoration: BoxDecoration(
                                                    color: ThemeManager.logOutContainer.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    "Log out",
                                                    style: interBold.copyWith(
                                                        fontSize: Dimensions.fontSizeDefault,
                                                        fontWeight: FontWeight.w400,
                                                        color: ThemeManager.logOutContainer,
                                                        height: 0),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: Dimensions.PADDING_SIZE_SMALL * 2.2,
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  // signOut(store, loggedInPlatform);
                                                  Navigator.pop(context);
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  alignment: Alignment.center,
                                                  constraints: const BoxConstraints(minWidth: 20),
                                                  decoration: BoxDecoration(
                                                    color: ThemeManager.logOutContainer,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    "Cancel",
                                                    style: interBold.copyWith(
                                                        fontSize: Dimensions.fontSizeSmall,
                                                        fontWeight: FontWeight.w600,
                                                        color: ThemeManager.white,
                                                        height: 0),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: Dimensions.PADDING_SIZE_SMALL * 2.2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: -MediaQuery.of(context).size.height * 0.026,
                                    child: Container(
                                      height: 48,
                                      width: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: ThemeManager.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFE5E5E5)),
                                          boxShadow: [
                                            BoxShadow(
                                              offset: const Offset(0, 4),
                                              blurRadius: 14,
                                              spreadRadius: -2,
                                              color: ThemeManager.black.withOpacity(0.05),
                                            ),
                                          ]),
                                      child: SvgPicture.asset("assets/image/log-out.svg"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Log Out',
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
        ],
      ),
      body: Column(
        children: [
          _HeroHeader(onBack: () => Navigator.pop(context)),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                left: AppTokens.s20,
                right: AppTokens.s20,
                top: AppTokens.s24,
              ),
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: _isDesktop
                    ? null
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.r28),
                        topRight: Radius.circular(AppTokens.r28),
                      ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<HomeStore>(
                      builder: (context, hs, child) {
                        return _ProfileCard(
                          fullName: hs.userDetails.value?.fullname ?? '',
                          phone: hs.userDetails.value?.phone ?? '',
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              Routes.editProfile,
                              arguments: {
                                'userprofile': hs.userDetails.value,
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppTokens.s20),
                    Observer(
                      builder: (_) {
                        return store.isConnected
                            ? store.subscribedPlan.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppTokens.s20,
                                    ),
                                    child: store.isLoading
                                        ? Center(
                                            child: CircularProgressIndicator(
                                              color: AppColors.primaryColor,
                                            ),
                                          )
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _SectionHeading(title: "My Subscription"),
                                              const SizedBox(height: AppTokens.s12),
                                              buildSubscribedPlansView(),
                                            ],
                                          ),
                                  )
                                : _EmptyPlansState(
                                    onSubscribe: () {
                                      Navigator.of(context).pushNamed(
                                        Routes.newSubscription,
                                        arguments: {'showBackButton': true},
                                      );
                                    },
                                  )
                            : const NoInternetWidget();
                      },
                    ),
                    if (_loginStore.settingsData.value?.isInAPurchases == true && Platform.isMacOS) ...[
                      const SizedBox.shrink(),
                    ] else ...[
                      _SectionHeading(title: 'Order History'),
                      const SizedBox(height: AppTokens.s12),
                      Observer(
                        builder: (_) {
                          return _orderedBookStore.isConnected
                              ? _orderedBookStore.orderedBooks.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppTokens.s20,
                                      ),
                                      child: _orderedBookStore.isLoading
                                          ? Center(
                                              child: CircularProgressIndicator(
                                                color: AppColors.primaryColor,
                                              ),
                                            )
                                          : ListView.builder(
                                              itemCount: _orderedBookStore.orderedBooks.length,
                                              shrinkWrap: true,
                                              padding: EdgeInsets.zero,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemBuilder: (BuildContext context, int index) {
                                                OrderedBookModel? bookOrder =
                                                    _orderedBookStore.orderedBooks[index];
                                                return _buildOrderedBookCard(context, bookOrder);
                                              },
                                            ),
                                    )
                                  : _EmptyBooksState()
                              : const NoInternetWidget();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(HomeStore homeStore) {
    showDialog(
      context: context,
      builder: (context) {
        return _ConfirmDialog(
          iconAsset: "assets/image/deleteAccount.svg",
          message: "Are you sure you want to Delete Account?",
          confirmLabel: "Delete Account",
          onConfirm: () {
            _deleteAccountUser(homeStore);
          },
          onCancel: () {
            // signOut(store, loggedInPlatform);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _showLogoutDialog(HomeStore homeStore) {
    showDialog(
      context: context,
      builder: (context) {
        return _ConfirmDialog(
          iconAsset: "assets/image/log-out.svg",
          message: "Are you sure you want to log out?",
          confirmLabel: "Log out",
          onConfirm: () async {
            Navigator.pop(context); // Close dialog first
            await clearAppData();
            if (!mounted) return;
            signOut(homeStore, _getPlatformString());
          },
          onCancel: () {
            // signOut(store, loggedInPlatform);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildOrderedBookCard(BuildContext context, OrderedBookModel book) {
    return InkWell(
      onTap: () {
        // Navigate to TrackOrderScreen with the book's order_id
        Navigator.of(context).pushNamed(
          Routes.trackOrder,
          arguments: {
            'orderId': book.orderId ?? '',
            'productName': book.bookName ?? '',
            'bookType': book.bookType ?? '',
            'quantity': book.quantity ?? 1,
          },
        );
      },
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTokens.s16),
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          border: Border.all(color: AppTokens.border(context)),
          borderRadius: BorderRadius.circular(AppTokens.r12),
          boxShadow: AppTokens.shadow1(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Type Banner
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s12,
                vertical: AppTokens.s12,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTokens.brand, AppTokens.brand2],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTokens.r12),
                  topRight: Radius.circular(AppTokens.r12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.book,
                    color: AppColors.white,
                    size: 18,
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Text(
                    book.bookType ?? 'Hardcopy Book',
                    style: AppTokens.caption(context).copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s8,
                      vertical: AppTokens.s4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppTokens.r20),
                    ),
                    child: Text(
                      'Order ID: ${book.orderId ?? 'N/A'}',
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.accent(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Book Details
            Padding(
              padding: const EdgeInsets.all(AppTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.bookName ?? 'Unknown Book',
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTokens.ink(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book.description != null && book.description!.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.s8),
                    Text(
                      book.description!,
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.muted(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppTokens.s12),

                  // Details
                  Row(
                    children: [
                      _buildInfoColumn('Price', '₹${book.price ?? 0}'),
                      const SizedBox(width: AppTokens.s16),
                      _buildInfoColumn('Quantity', '${book.quantity ?? 1}'),
                      const SizedBox(width: AppTokens.s16),
                      if (book.discountPrice != null && book.discountPrice! > 0)
                        _buildInfoColumn('Discount', '₹${book.discountPrice}'),
                    ],
                  ),

                  const SizedBox(height: AppTokens.s12),
                  if (book.deliveryCharge != null && book.deliveryCharge! > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery Charge:',
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                        ),
                        Text(
                          '₹${book.deliveryCharge}',
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.ink(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppTokens.s8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s12,
                      vertical: AppTokens.s8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.surface2(context),
                      borderRadius: BorderRadius.circular(AppTokens.r8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: AppTokens.body(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTokens.ink(context),
                          ),
                        ),
                        Text(
                          '₹${(book.price ?? 0) + (book.deliveryCharge ?? 0) - (book.discountPrice ?? 0)}',
                          style: AppTokens.body(context).copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTokens.accent(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.muted(context),
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        Text(
          value,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.ink(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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

  String formatDate(String isoString) {
    DateTime dateTime = DateTime.parse(isoString);
    String formattedDate = DateFormat('d MMMM yyyy').format(dateTime);

    int day = dateTime.day;
    String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }
    String dayWithSuffix = '$day$suffix';
    formattedDate = formattedDate.replaceFirst(RegExp(r'^\d+'), dayWithSuffix);

    return formattedDate;
  }

  String orderFormatDate(String isoString) {
    DateTime dateTime = DateTime.parse(isoString);
    String formattedDate = DateFormat('d MMMM').format(dateTime);

    int day = dateTime.day;
    String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }
    String dayWithSuffix = '$day$suffix';
    formattedDate = formattedDate.replaceFirst(RegExp(r'^\d+'), dayWithSuffix);

    return formattedDate;
  }

  Widget buildSubscribedPlansView() {
    final store = Provider.of<SubscriptionStore>(context);
    return (Platform.isWindows || Platform.isMacOS)
        ? CustomDynamicHeightGridView(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 10,
            itemCount: store.subscribedPlan.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            builder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.s20),
                child: buildSubscribedPlanItem(context, index),
              );
            },
          )
        : ListView.builder(
            itemCount: store.subscribedPlan.length,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.s12),
                child: buildSubscribedPlanItem(context, index),
              );
            },
          );
  }
}

// ═══════════════════════════════════════════════════════════════
// Private presentation widgets
// ═══════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      padding: _isDesktop
          ? const EdgeInsets.symmetric(
              vertical: AppTokens.s24,
              horizontal: AppTokens.s24,
            )
          : const EdgeInsets.only(
              top: AppTokens.s32 + AppTokens.s24,
              left: AppTokens.s20,
              right: AppTokens.s20,
              bottom: AppTokens.s20,
            ),
      child: Row(
        children: [
          IconButton(
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              "My Profile",
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.fullName,
    required this.phone,
    required this.onTap,
  });

  final String fullName;
  final String phone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s20,
            vertical: AppTokens.s16,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTokens.brand, AppTokens.brand2],
            ),
            borderRadius: BorderRadius.circular(AppTokens.r16),
            boxShadow: AppTokens.shadow2(context),
          ),
          child: Row(
            children: [
              Container(
                height: AppTokens.s32 + AppTokens.s20,
                width: AppTokens.s32 + AppTokens.s20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_2_outlined,
                  color: AppTokens.brand,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: AppTokens.titleSm(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: AppTokens.s4),
                    Text(
                      phone,
                      style: AppTokens.caption(context).copyWith(
                        color: AppColors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.edit_outlined,
                color: AppColors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTokens.body(context).copyWith(
        fontWeight: FontWeight.w700,
        color: AppTokens.ink(context),
      ),
    );
  }
}

class _EmptyPlansState extends StatelessWidget {
  const _EmptyPlansState({required this.onSubscribe});

  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.s24),
        child: Column(
          children: [
            Container(
              height: AppTokens.s32 + AppTokens.s32,
              width: AppTokens.s32 + AppTokens.s32,
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: AppTokens.accent(context),
                size: 32,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'No Subscribed Plans Found',
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            CustomButton(
              onPressed: onSubscribe,
              buttonText: "Subscribe now",
              height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
              width: Dimensions.PADDING_SIZE_DEFAULT * 10,
              textAlign: TextAlign.center,
              radius: Dimensions.RADIUS_DEFAULT,
              transparent: true,
              bgColor: AppColors.primaryColor,
              fontSize: Dimensions.fontSizeDefault,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBooksState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.s24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTokens.s20),
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.book_outlined,
                size: 56,
                color: AppTokens.accent(context),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'No books ordered yet',
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              'Your ordered books will appear here',
              style: AppTokens.body(context).copyWith(
                color: AppTokens.muted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onDeleteTap,
    required this.onLogoutTap,
  });

  final VoidCallback onDeleteTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s20,
          vertical: AppTokens.s16,
        ),
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          border: Border(
            top: BorderSide(color: AppTokens.border(context)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onDeleteTap,
                borderRadius: BorderRadius.circular(AppTokens.r12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTokens.border(context)),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                  ),
                  child: Center(
                    child: Text(
                      'Delete Account',
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTokens.ink(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: InkWell(
                onTap: onLogoutTap,
                borderRadius: BorderRadius.circular(AppTokens.r12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
                  decoration: BoxDecoration(
                    color: AppTokens.danger(context),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                  ),
                  child: Center(
                    child: Text(
                      'Log Out',
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.iconAsset,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  final String iconAsset;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FittedBox(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s24,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.r12),
                color: AppTokens.surface(context),
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppTokens.s32 + AppTokens.s12),
                  Text(
                    message,
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTokens.ink(context),
                    ),
                  ),
                  const SizedBox(height: AppTokens.s16),
                  Row(
                    children: [
                      InkWell(
                        onTap: onConfirm,
                        borderRadius: BorderRadius.circular(AppTokens.r8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s12,
                            vertical: AppTokens.s4,
                          ),
                          alignment: Alignment.center,
                          constraints: const BoxConstraints(minWidth: 20),
                          decoration: BoxDecoration(
                            color: AppTokens.dangerSoft(context),
                            borderRadius: BorderRadius.circular(AppTokens.r8),
                          ),
                          child: Text(
                            confirmLabel,
                            style: AppTokens.body(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTokens.danger(context),
                              height: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s16),
                      InkWell(
                        onTap: onCancel,
                        borderRadius: BorderRadius.circular(AppTokens.r8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s12,
                            vertical: AppTokens.s4,
                          ),
                          alignment: Alignment.center,
                          constraints: const BoxConstraints(minWidth: 20),
                          decoration: BoxDecoration(
                            color: AppTokens.danger(context),
                            borderRadius: BorderRadius.circular(AppTokens.r8),
                          ),
                          child: Text(
                            "Cancel",
                            style: AppTokens.caption(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                              height: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s20),
                ],
              ),
            ),
            Positioned(
              top: -MediaQuery.of(context).size.height * 0.026,
              child: Container(
                height: AppTokens.s32 + AppTokens.s16,
                width: AppTokens.s32 + AppTokens.s16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTokens.border(context)),
                  boxShadow: AppTokens.shadow2(context),
                ),
                child: SvgPicture.asset(iconAsset),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Top-level widget functions — preserved public contract
// ═══════════════════════════════════════════════════════════════

Widget buildSubscribedPlanItem(BuildContext context, int index) {
  final store = Provider.of<SubscriptionStore>(context);
  // Your existing item builder code
  SubscribedPlanModel? subscribedPlans = store.subscribedPlan[index];
  String? subPlanOffer = store.subscribedPlan[index]?.buyDuration?.offer?.toString().replaceAll("%", "");
  // ignore: unused_local_variable
  num offerPrice =
      (store.subscribedPlan[index]?.buyDuration?.price ?? store.subscribedPlan[index]?.amount ?? 0);
  if (subPlanOffer != null && subPlanOffer.isNotEmpty) {
    try {
      double discountPercentage = double.parse(subPlanOffer);
      offerPrice *= (1 - (discountPercentage / 100));
    } catch (e) {
      debugPrint("catch");
    }
  }
  DateTime expiryDate = DateFormat("MMM dd, yyyy, hh:mm a").parse(subscribedPlans?.expirationDate ?? '');
  DateTime startDate = DateFormat("yyyy-MM-ddTHH:mm:ss.SSSZ").parse(subscribedPlans?.created_at ?? '');
  // ignore: unused_local_variable
  String formattedExpiryDate = DateFormat("MMMM dd'TH' yyyy").format(expiryDate);
  // ignore: unused_local_variable
  String formattedStartDate = DateFormat("MMMM dd'TH' yyyy").format(startDate);

  // ignore: unused_local_variable
  int monthsDifference = (expiryDate.year - startDate.year) * 12 + expiryDate.month - startDate.month;
  // ignore: unused_local_variable
  int yearsDifference = expiryDate.year - startDate.year;
  // ignore: unused_local_variable
  int daysDifference = monthsDifference * 30;

  return Container(
    decoration: BoxDecoration(
      color: AppTokens.surface(context),
      borderRadius: BorderRadius.circular(AppTokens.r16),
      border: Border.all(color: AppTokens.border(context)),
      boxShadow: AppTokens.shadow1(context),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header strip with badge + upgrade pill
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s12,
          ),
          decoration: BoxDecoration(
            color: AppTokens.accentSoft(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppTokens.r16),
              topRight: Radius.circular(AppTokens.r16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 28,
                    width: 28,
                    padding: const EdgeInsets.all(AppTokens.s4),
                    decoration: BoxDecoration(
                      color: AppTokens.surface(context),
                      borderRadius: BorderRadius.circular(AppTokens.r8),
                    ),
                    child: Image.asset("assets/image/sub.png"),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Text(
                    "Subscription Plans",
                    style: AppTokens.caption(context).copyWith(
                      color: AppTokens.muted(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.successSoft(context),
                      borderRadius: BorderRadius.circular(AppTokens.r8),
                    ),
                    child: Text(
                      "Active",
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.success(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              subscribedPlans?.isPreviousPlan == true
                  ? const SizedBox()
                  : Observer(
                      builder: (context) {
                        // Show upgrade plan button only when isInAPurchases is true
                        final loginStore = Provider.of<LoginStore>(context, listen: false);
                        final bool isIAPEnabled = loginStore.settingsData.value?.isInAPurchases == true;

                        if (isIAPEnabled && (Platform.isMacOS || Platform.isIOS)) {
                          // When IAP is disabled, show blank container (no upgrade option)
                          return const SizedBox.shrink();
                        } else {
                          // When IAP is enabled, show the upgrade plan button
                          return InkWell(
                            onTap: () async {
                              // Show the UpgradePlanPopup dialog
                              final selectedMode = await showDialog<String>(
                                context: context,
                                barrierDismissible: true,
                                builder: (ctx) => UpgradePlanPopup(
                                  currentExpiryDate: expiryDate,
                                  onProceed: (mode) {
                                    Navigator.of(ctx).pop(mode); // Return selected mode
                                  },
                                ),
                              );
                              // After dialog closes, handle navigation here
                              if (selectedMode != null) {
                                // Determine flags for API based on selectedMode
                                final sameValidity = selectedMode == 'same-validity';
                                final isDiffValidity = selectedMode == 'new-validity';
                                // Get userId from the current plan/subscription
                                final subscriptionId = subscribedPlans?.order_id ?? '';
                                // Navigate to the new upgrade plan selection screen
                                if (!context.mounted) return;
                                Navigator.of(context).pushNamed(
                                  Routes.selectUpgradePlan,
                                  arguments: {
                                    'subscriptionId': subscriptionId,
                                    'sameValidity': sameValidity,
                                    'isDiffValidity': isDiffValidity,
                                    'upgradeMode': selectedMode,
                                  },
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(AppTokens.r20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.s12,
                                vertical: AppTokens.s4,
                              ),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTokens.brand,
                                    AppTokens.brand2,
                                  ],
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(AppTokens.r20)),
                              ),
                              child: Text(
                                "Upgrade plan",
                                style: AppTokens.caption(context).copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subscribedPlans?.plan_name ?? "",
                style: AppTokens.titleSm(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTokens.ink(context),
                ),
              ),
              const SizedBox(height: AppTokens.s4),
              Text(
                "${DateFormat('dd MMMM, yyyy').format(startDate)} to ${DateFormat('dd MMMM, yyyy').format(expiryDate)}",
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.muted(context),
                ),
              ),
              const SizedBox(height: AppTokens.s16),
              Column(
                children: subscribedPlans?.benifit?.map<Widget>((feature) {
                      return _buildFeatureRow(Icons.check_circle_outline, feature);
                    }).toList() ??
                    [],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildFeatureRow(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppTokens.s12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          "assets/image/arrow_sub.png",
          height: 20,
          width: 20,
        ),
        const SizedBox(width: AppTokens.s8),
        Expanded(
          child: Builder(
            builder: (context) => Text(
              text,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink(context),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// UpgradePlanPopup — preserved public class
// ═══════════════════════════════════════════════════════════════

/// UpgradePlanPopup: Modal dialog for upgrade plan selection.
///
/// Preserved public contract:
///   • Required `DateTime currentExpiryDate` and
///     `void Function(String selectedMode) onProceed` callback.
///   • `_UpgradePlanPopupState` exposes the `'same-validity'` /
///     `'new-validity'` mode identifiers via the Proceed button
///     (the dialog returns the selected mode string via `Navigator.pop`).
class UpgradePlanPopup extends StatefulWidget {
  final DateTime currentExpiryDate;
  final void Function(String selectedMode) onProceed;

  const UpgradePlanPopup({
    super.key,
    required this.currentExpiryDate,
    required this.onProceed,
  });

  @override
  State<UpgradePlanPopup> createState() => _UpgradePlanPopupState();
}

class _UpgradePlanPopupState extends State<UpgradePlanPopup> {
  String? _selectedMode;

  String get _sameValidityText {
    // Format: ends 30-Dec-2024
    final end = widget.currentExpiryDate;
    return 'Existing Plan Validity Till - ${_formatDate(end)}';
  }

  String get _newValidityText {
    // Format: valid till 30-Dec-2025 (add 12 months)
    final newEnd = DateTime(
      widget.currentExpiryDate.year + 1,
      widget.currentExpiryDate.month,
      widget.currentExpiryDate.day,
    );
    return 'Extended Plan Validity Till - ${_formatDate(newEnd)}';
  }

  String _formatDate(DateTime date) {
    // Format: dd-MMM-yyyy
    return '${date.day.toString().padLeft(2, '0')}-${_monthAbbr(date.month)}-${date.year}';
  }

  String _monthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s24,
            vertical: AppTokens.s24 + AppTokens.s4,
          ),
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: BorderRadius.circular(AppTokens.r20),
            boxShadow: AppTokens.shadow3(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                margin: const EdgeInsets.only(bottom: AppTokens.s12),
                padding: const EdgeInsets.all(AppTokens.s12),
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_upward,
                  size: 32,
                  color: AppTokens.accent(context),
                ),
              ),
              // Title
              Text(
                'Upgrade Your Plan',
                style: AppTokens.titleSm(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTokens.ink(context),
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              // Description
              Text(
                'Enjoy advanced features and extended access.',
                textAlign: TextAlign.center,
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.muted(context),
                ),
              ),
              const SizedBox(height: AppTokens.s24),
              // Radio options
              _buildRadioOption(
                value: 'same-validity',
                title: '🔒  Upgrade Tier – Keep Current Validity',
                subtitle: _sameValidityText,
                tagline: '🔹 Keep existing duration, switch to a better plan.',
              ),
              const SizedBox(height: AppTokens.s12),
              _buildRadioOption(
                value: 'new-validity',
                title: ' 🔓  Upgrade Tier – Extend / New Validity',
                subtitle: _newValidityText,
                tagline: '🔹 Upgrade and get Extra Validity added to your plan.',
              ),
              const SizedBox(height: AppTokens.s24 + AppTokens.s4),
              // Proceed button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMode != null
                      ? () {
                          Navigator.of(context).pop(_selectedMode);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    disabledBackgroundColor: AppTokens.muted(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.s12 + 2,
                    ),
                  ),
                  child: Text(
                    'Proceed',
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
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

  Widget _buildRadioOption({
    required String value,
    required String title,
    required String subtitle,
    required String tagline,
  }) {
    final bool selected = _selectedMode == value;
    return InkWell(
      onTap: () => setState(() => _selectedMode = value),
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12,
          vertical: AppTokens.s12,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppTokens.accent(context) : AppTokens.border(context),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTokens.r12),
          color: selected ? AppTokens.accentSoft(context) : AppTokens.surface(context),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedMode,
              onChanged: (val) => setState(() => _selectedMode = val),
              activeColor: AppTokens.accent(context),
            ),
            const SizedBox(width: AppTokens.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTokens.ink(context),
                    ),
                  ),
                  const SizedBox(height: AppTokens.s4),
                  Text(
                    subtitle,
                    style: AppTokens.caption(context).copyWith(
                      color: AppTokens.muted(context),
                    ),
                  ),
                  const SizedBox(height: AppTokens.s4),
                  Text(
                    tagline,
                    style: AppTokens.caption(context).copyWith(
                      color: AppTokens.muted(context),
                    ),
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
