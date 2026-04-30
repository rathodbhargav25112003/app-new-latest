// import 'dart:io';
// import 'dart:math';
// import '../../app/routes.dart';
// import 'homeBottomSheetMenu.dart';
// import '../../helpers/colors.dart';
// import '../../helpers/styles.dart';
// import '../widgets/bottom_toast.dart';
// import 'package:flutter/material.dart';
// import '../../helpers/dimensions.dart';
// import '../login/verify_otp_mail.dart';
// import 'package:provider/provider.dart';
// import '../login/store/login_store.dart';
// import '../dashboard/store/home_store.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import '../videolectures/video_category.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../widgets/my_doubts_screen.dart';
//
// class MoreMenuBottomsheetContainer extends StatefulWidget {
//   // final Function onTapMoreMenuItemContainer;
//   final Function closeBottomMenu;
//   const MoreMenuBottomsheetContainer(
//       {Key? key,
//       // required this.onTapMoreMenuItemContainer,
//       required this.closeBottomMenu})
//       : super(key: key);
//
//   @override
//   State<MoreMenuBottomsheetContainer> createState() =>
//       _MoreMenuBottomsheetContainerState();
// }
//
// class _MoreMenuBottomsheetContainerState
//     extends State<MoreMenuBottomsheetContainer> {
//   Future<void> _launchURL(String url) async {
//     debugPrint('usel$url');
//     // ignore: deprecated_member_use
//     if (await canLaunch(url)) {
//       await launch(url);
//     } else {
//       throw 'Could not launch $url';
//     }
//   }
//
//   _launchEmail(String email) async {
//     final Uri _emailLaunchUri = Uri(
//       scheme: 'mailto',
//       path: email,
//     );
//     if (await canLaunch(_emailLaunchUri.toString())) {
//       await launch(_emailLaunchUri.toString());
//     } else {
//       throw 'Could not launch email';
//     }
//   }
//
//   _launchWhatsApp(String phone) async {
//     final Uri whatsAppLaunchUri =
//         Uri(scheme: 'https', host: 'wa.me', path: "91$phone");
//     if (await canLaunch(whatsAppLaunchUri.toString())) {
//       await launch(whatsAppLaunchUri.toString());
//     } else {
//       throw 'Could not launch WhatsApp';
//     }
//   }
//
//   String loggedInPlatform = '';
//   void signOut(HomeStore store, String loggedInPlatform) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     bool? loggedInEmail = prefs.getBool('isloggedInEmail');
//     bool? loggedInWt = prefs.getBool('isLoggedInWt');
//     // bool? signInGoogle = prefs.getBool('isSignInGoogle');
//     String? fcmToken = prefs.getString('fcmtoken');
//
//     // Try to call the API logout, but don't block local logout if it fails
//     try {
//       await store.onSignoutUser(loggedInPlatform);
//     } catch (e) {
//       print("API logout failed, proceeding with local logout: $e");
//     }
//
//     // Perform local logout operations regardless of API call success
//     // If user reached this screen, they must be logged in, so always allow logout
//     String? token = prefs.getString('token');
//     bool shouldLogout = true; // Always allow logout if user clicked logout button
//
//     print("Logout Debug - loggedInEmail: $loggedInEmail, loggedInWt: $loggedInWt, token: ${token?.substring(0, token != null && token.length > 10 ? 10 : token?.length ?? 0)}..., shouldLogout: $shouldLogout, platform: ${Platform.operatingSystem}");
//
//     if (shouldLogout) {
//       prefs.setString('token', '');
//       prefs.setString('fcmtoken', '');
//       prefs.setBool('isLoggedInWt', false);
//       prefs.setBool('isloggedInEmail', false);
//       prefs.setBool('isSignInGoogle', false);
//       prefs.clear();
//       ThemeManager.currentTheme == AppTheme.Dark
//           ? Provider.of<ThemeNotifier>(context, listen: false).toggleTheme()
//           : null;
//       // Navigator.of(context).pushNamed(Routes.loginWithPass);
//       Navigator.of(context)
//           .pushNamedAndRemoveUntil(Routes.login, (context) => false);
//       print("User Logged Out - Navigation to login screen executed");
//     } else {
//       print("Logout failed - shouldLogout condition not met");
//     }
//     // else if(signInGoogle==true){
//     //   await _googleSignIn.signOut();
//     //   prefs.setString('fcmtoken','');
//     //   prefs.setString('token','');
//     //   prefs.setBool('isSignInGoogle',false);
//     //   prefs.clear();
//     //   Navigator.of(context).pushNamed(Routes.splash);
//     //   print("User Sign Out");
//     // }
//
//     // Only delete FCM token on mobile platforms where FCM is available
//     if (fcmToken != null && !Platform.isWindows && !Platform.isMacOS) {
//       try {
//         await store.onDeleteNotificationToken(fcmToken);
//       } catch (e) {
//         print("FCM token deletion failed: $e");
//       }
//     }
//   }
//
//   Future<void> _deleteAccountUser() async {
//     final store = Provider.of<HomeStore>(context, listen: false);
//     await store.onDeleteUserAccountCall(store.userDetails.value?.id ?? '');
//   }
//
//   void _navigateToScreen(int currentlyOpenMenuIndex) {
//     final loginStore = Provider.of<LoginStore>(context, listen: false);
//     final store = Provider.of<HomeStore>(context, listen: false);
//     final deviceType = getDeviceType(context);
//     String type = deviceType == DeviceType.Tablet ? 'Tablet' : 'Mobile';
//
//     // Enhanced platform detection for desktop platforms
//     if (Platform.isIOS) {
//       loggedInPlatform = "ios$type";
//     } else if (Platform.isAndroid) {
//       loggedInPlatform = "android$type";
//     } else if (Platform.isMacOS) {
//       loggedInPlatform = "macOSDesktop";
//     } else if (Platform.isWindows) {
//       loggedInPlatform = "windowsDesktop";
//     } else {
//       loggedInPlatform = "unknownDesktop";
//     }
//     String title = homeBottomSheetMenu[currentlyOpenMenuIndex].title;
//
//     if (title == "Videos") {
//       Navigator.pushNamed(context, Routes.videoLectures);
//     }
//     if (title == "Tests") {
//       Navigator.pushNamed(context, Routes.testCategory);
//     }
//     if (title == "Notes") {
//       Navigator.pushNamed(context, Routes.notesCategory);
//     }
//     if (title == "Analysis & Solutions") {
//       Navigator.pushNamed(context, Routes.reportsCategoryList,
//           arguments: {'fromhome': true});
//     }
//     if (title == "Mock Exam Analysis") {
//       Navigator.pushNamed(context, Routes.masterReportsCategoryList,
//           arguments: {'fromhome': true});
//     }
//     if (title == "Offline Notes") {
//       Navigator.pushNamed(context, Routes.downloadedNotesCategory);
//     }
//     if (title == "My Plan") {
//       Navigator.pushNamed(context, Routes.subscriptionPlan);
//     }
//     if (title == "Subscription Plan") {
//       Navigator.pushNamed(context, Routes.newSubscription, arguments: {'showBackButton': true});
//     }
//     if (title == "Notification") {
//       Navigator.pushNamed(context, Routes.notificationScreen,
//           arguments: {'fromhome': true});
//     }
//     if (title == "Bookmarks") {
//       Navigator.pushNamed(context, Routes.bookMarkCategoryList,
//           arguments: {'fromhome': true});
//     }
//     if (title == "Mock Exam Bookmarks") {
//       Navigator.pushNamed(context, Routes.masterBookMarkCategoryList,
//           arguments: {'fromhome': true});
//     }
//     if (title == "My Doubts") {
//       Navigator.of(context).push(
//         MaterialPageRoute(builder: (context) => const MyDoubtsScreen()),
//       );
//     }
//     if (title == "Privacy Policy") {
//       _launchURL("https://sushrutalgs.in/privacy-policy");
//     }
//     if (title == "Refund Policy") {
//       _launchURL("https://sushrutalgs.in/refund-policy");
//     }
//     if (title == "Terms & Conditions") {
//       _launchURL("https://sushrutalgs.in/terms-%26-conditions");
//     }
//     if (title == "Contact Us") {
//       debugPrint("Phone:${loginStore.settingsData.value?.phone}");
//       _launchWhatsApp(loginStore.settingsData.value?.phone ?? "");
//     }
//     if (title == "Email") {
//       debugPrint("email:${loginStore.settingsData.value?.email}");
//       _launchEmail(loginStore.settingsData.value?.email ?? "");
//     }
//     if (title == "Logout") {
//       // Set platform detection for logout
//       final deviceType = getDeviceType(context);
//       String type = deviceType == DeviceType.Tablet ? 'Tablet' : 'Mobile';
//
//       // Enhanced platform detection for desktop platforms
//       if (Platform.isIOS) {
//         loggedInPlatform = "ios$type";
//       } else if (Platform.isAndroid) {
//         loggedInPlatform = "android$type";
//       } else if (Platform.isMacOS) {
//         loggedInPlatform = "macOSDesktop";
//       } else if (Platform.isWindows) {
//         loggedInPlatform = "windowsDesktop";
//       } else {
//         loggedInPlatform = "unknownDesktop";
//       }
//
//       showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//                 backgroundColor: ThemeManager.white,
//                 content: Text(
//                   'Do you want to logout this Account? ',
//                   style: interRegular.copyWith(
//                     fontSize: Dimensions.fontSizeLarge,
//                     fontWeight: FontWeight.w500,
//                     color: ThemeManager.black,
//                   ),
//                 ),
//                 actions: [
//                   TextButton(
//                     style: TextButton.styleFrom(
//                         foregroundColor: Colors.white,
//                         elevation: 2,
//                         backgroundColor: Theme.of(context).hintColor),
//                     onPressed: () => Navigator.pop(context, false),
//                     child: Text('No',
//                         style: interRegular.copyWith(
//                           fontSize: Dimensions.fontSizeDefault,
//                           fontWeight: FontWeight.w500,
//                           color: ThemeManager.white,
//                         )),
//                   ),
//                   TextButton(
//                     style: TextButton.styleFrom(
//                         foregroundColor: Colors.white,
//                         elevation: 2,
//                         backgroundColor: Theme.of(context).primaryColor),
//                     onPressed: () {
//                       Navigator.pop(context); // Close dialog first
//                       signOut(store, loggedInPlatform);
//                     },
//                     child: Text('Yes',
//                         style: interRegular.copyWith(
//                           fontSize: Dimensions.fontSizeDefault,
//                           fontWeight: FontWeight.w500,
//                           color: ThemeManager.white,
//                         )),
//                   ),
//                 ],
//               ));
//     }
//     if (title == "Delete Account") {
//       showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//                 backgroundColor: ThemeManager.white,
//                 content: Text(
//                   'Do you want to Delete this Account? ',
//                   style: interRegular.copyWith(
//                     fontSize: Dimensions.fontSizeLarge,
//                     fontWeight: FontWeight.w500,
//                     color: ThemeManager.black,
//                   ),
//                 ),
//                 actions: [
//                   TextButton(
//                     style: TextButton.styleFrom(
//                         foregroundColor: Colors.white,
//                         elevation: 2,
//                         backgroundColor: Theme.of(context).hintColor),
//                     onPressed: () => Navigator.pop(context, false),
//                     child: Text('No',
//                         style: interRegular.copyWith(
//                           fontSize: Dimensions.fontSizeDefault,
//                           fontWeight: FontWeight.w500,
//                           color: ThemeManager.white,
//                         )),
//                   ),
//                   TextButton(
//                     style: TextButton.styleFrom(
//                         foregroundColor: Colors.white,
//                         elevation: 2,
//                         backgroundColor: Theme.of(context).primaryColor),
//                     onPressed: () {
//                       _deleteAccountUser();
//                       // Navigator.of(context).pushNamed(Routes.loginWithPass);
//                       Navigator.of(context).pushNamed(Routes.login);
//                     },
//                     child: Text('Yes',
//                         style: interRegular.copyWith(
//                           fontSize: Dimensions.fontSizeDefault,
//                           fontWeight: FontWeight.w500,
//                           color: ThemeManager.white,
//                         )),
//                   ),
//                 ],
//               ));
//     }
//   }
//
//   final ScrollController scrollController = ScrollController();
//   Widget _buildMoreMenuContainer(
//       {required BuildContext context,
//       required BoxConstraints boxConstraints,
//       required String iconUrl,
//       required String title}) {
//     return title != ""
//         ? Padding(
//             padding: EdgeInsets.only(bottom: 20),
//             child: GestureDetector(
//               onTap: () {
//                 // widget.onTapMoreMenuItemContainer(homeBottomSheetMenu
//                 //     .indexWhere((element) => element.title == title));
//                 int currentlyOpenMenuIndex = homeBottomSheetMenu
//                     .indexWhere((element) => element.title == title);
//                 // widget.onTapMoreMenuItemContainer(currentlyOpenMenuIndex);
//                 _navigateToScreen(currentlyOpenMenuIndex);
//               },
//               child: Column(
//                 children: [
//                   // homeBottomSheetMenu.indexWhere((element) => element.title == title ?
//                   // student?.hostelId.toString() != "0" ?
//                   Container(
//                     margin: EdgeInsets.symmetric(
//                       horizontal: boxConstraints.maxWidth * (0.1),
//                     ),
//                     width: boxConstraints.maxWidth * (0.18),
//                     height: boxConstraints.maxWidth * (0.18),
//                     padding: EdgeInsets.only(
//                       left: 12.5,
//                       right: 12.5,
//                       top: 12.5,
//                       bottom: 6,
//                     ),
//                     child: SvgPicture.asset(iconUrl),
//                   ),
//                   // :SizedBox(),
//                   // SizedBox(height: 5),
//                   SizedBox(
//                     width: boxConstraints.maxWidth * (0.23),
//                     child: Text(
//                       title,
//                       textAlign: TextAlign.center,
//                       style:
//                           TextStyle(color: ThemeManager.black, fontSize: 14.0),
//                     ),
//                   )
//                 ],
//               ),
//             ),
//           )
//         : SizedBox.shrink();
//   }
//
//   Future<void> _getUserDetails() async {
//     final store = Provider.of<HomeStore>(context, listen: false);
//     await store.onGetUserDetailsCall(context);
//   }
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     _getUserDetails();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final store = Provider.of<HomeStore>(context, listen: false);
//     return Container(
//       // padding: EdgeInsets.only(top: 25.0, right: 25.0, left: 25.0),
//       child: LayoutBuilder(builder: (context, boxConstraints) {
//         return SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               InkWell(
//                 onTap: () {
//                   store.userDetails.value != null
//                       ? Navigator.of(context).pushNamed(Routes.editProfile,
//                           arguments: {'userprofile': store.userDetails.value})
//                       : BottomToast.showBottomToastOverlay(
//                           context: context,
//                           errorMessage: "Something went wrong!",
//                           backgroundColor: ThemeManager.redAlert,
//                         );
//                 },
//                 child: Padding(
//                   padding: EdgeInsets.only(top: 25.0, right: 25.0),
//                   child: Row(
//                     children: [
//                       SizedBox(
//                         width: boxConstraints.maxWidth * (0.075),
//                       ),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             store.userDetails.value?.fullname ?? "",
//                             style: interRegular.copyWith(
//                               fontSize: Dimensions.fontSizeOverLarge,
//                               fontWeight: FontWeight.bold,
//                               color: ThemeManager.black,
//                             ),
//                           ),
//                           Text(
//                             store.userDetails.value?.username ?? "",
//                             style: interRegular.copyWith(
//                               fontSize: Dimensions.fontSizeLarge,
//                               fontWeight: FontWeight.w500,
//                               color: ThemeManager.profileName,
//                             ),
//                           ),
//                         ],
//                       ),
//                       Spacer(),
//                       SizedBox(
//                           height: 21,
//                           width: 22,
//                           child: Icon(
//                             ThemeManager.currentTheme == AppTheme.Dark
//                                 ? Icons.nightlight
//                                 : Icons.sunny,
//                             color: ThemeManager.black,
//                           )),
//                       const SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
//                       Switch(
//                         inactiveThumbColor: Colors.white,
//                         inactiveTrackColor: Colors.blue,
//                         activeColor: Colors.white,
//                         activeTrackColor: Colors.green,
//                         value: ThemeManager.currentTheme == AppTheme.Dark,
//                         onChanged: (value) {
//                           setState(() {
//                             Provider.of<ThemeNotifier>(context, listen: false)
//                                 .toggleTheme();
//                             value = !value;
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: EdgeInsets.only(right: 25.0, left: 25.0),
//                 child: Divider(
//                   color: ThemeManager.black,
//                   height: 50,
//                 ),
//               ),
//               // Container(
//               //   height: MediaQuery.of(context).size.height * 0.5,
//               //   child: SingleChildScrollView(
//               //     child: Wrap(
//               //       children: homeBottomSheetMenu
//               //           .map((e) => _buildMoreMenuContainer(
//               //               context: context,
//               //               boxConstraints: boxConstraints,
//               //               iconUrl: e.iconUrl,
//               //               title: e.title))
//               //           .toList(),
//               //     ),
//               //   ),
//               // ),
//               Container(
//                 height: MediaQuery.of(context).size.height * 0.5,
//                 padding: EdgeInsets.only(right: 25.0, left: 25.0),
//                 child: Scrollbar(
//                   controller: scrollController,
//                   thumbVisibility: true,
//                   child: SingleChildScrollView(
//                     controller: scrollController,
//                     child: Wrap(
//                       spacing: MediaQuery.of(context).size.width * 0.09,
//                       children:
//                           List.generate(homeBottomSheetMenu.length, (index) {
//                         String titleToSend = homeBottomSheetMenu[index].title;
//
//                         return _buildMoreMenuContainer(
//                             context: context,
//                             boxConstraints: boxConstraints,
//                             iconUrl: homeBottomSheetMenu[index].iconUrl,
//                             title: titleToSend);
//                       }),
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(
//                 height: MediaQuery.of(context).size.height * 0.1,
//               ),
//             ],
//           ),
//         );
//       }),
//       width: MediaQuery.of(context).size.width,
//       decoration: BoxDecoration(
//           color: ThemeManager.white,
//           borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(25), topRight: Radius.circular(25))),
//     );
//   }
// }

import 'dart:io';
// ignore: unused_import
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
import '../dashboard/store/home_store.dart';
import '../login/store/login_store.dart';
// ignore: unused_import
import '../login/verify_otp_mail.dart';
// ignore: unused_import
import '../videolectures/video_category.dart';
import '../widgets/bottom_toast.dart';
import 'homeBottomSheetMenu.dart';

/// MoreMenuBottomsheetContainer — the "More" sheet shown from the bottom
/// nav. Public surface preserved exactly:
///   • non-const constructor `(Key? key, {required Function
///     closeBottomMenu})`
///   • `_navigateToScreen(index)` dispatches based on the title of the
///     tapped menu entry (Videos / Notes / Tests / My Plan /
///     Subscription Plan / Analysis & Solutions / Mock Exam Analysis /
///     Offline Notes / Notification / Bookmarks / Mock Exam Bookmarks /
///     Contact Us / Email / Privacy Policy / Refund Policy / Terms &
///     Conditions / Logout / Delete Account)
///   • `signOut` still clears SharedPreferences, tries
///     `HomeStore.onSignoutUser`, then
///     `Navigator.pushNamedAndRemoveUntil(Routes.login, …)`
///   • Theme toggle still calls
///     `Provider.of<ThemeNotifier>(context, listen: false).toggleTheme()`
class MoreMenuBottomsheetContainer extends StatefulWidget {
  final Function closeBottomMenu;

  // ignore: use_super_parameters
  const MoreMenuBottomsheetContainer({
    Key? key,
    required this.closeBottomMenu,
  }) : super(key: key);

  @override
  State<MoreMenuBottomsheetContainer> createState() => _MoreMenuBottomsheetContainerState();
}

class _MoreMenuBottomsheetContainerState extends State<MoreMenuBottomsheetContainer> {
  String loggedInPlatform = '';
  final ScrollController scrollController = ScrollController();

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  // ---------------------------------------------------------------------------
  // External launchers
  // ---------------------------------------------------------------------------
  Future<void> _launchURL(String url) async {
    debugPrint('usel$url');
    // ignore: deprecated_member_use
    if (await canLaunch(url)) {
      // ignore: deprecated_member_use
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: email);
    // ignore: deprecated_member_use
    if (await canLaunch(emailLaunchUri.toString())) {
      // ignore: deprecated_member_use
      await launch(emailLaunchUri.toString());
    } else {
      throw 'Could not launch email';
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final Uri whatsAppLaunchUri = Uri(scheme: 'https', host: 'wa.me', path: '91$phone');
    // ignore: deprecated_member_use
    if (await canLaunch(whatsAppLaunchUri.toString())) {
      // ignore: deprecated_member_use
      await launch(whatsAppLaunchUri.toString());
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  // ---------------------------------------------------------------------------
  // Sign-out + delete
  // ---------------------------------------------------------------------------
  Future<void> signOut(HomeStore store, String loggedInPlatform) async {
    final prefs = await SharedPreferences.getInstance();
    final loggedInEmail = prefs.getBool('isloggedInEmail');
    final loggedInWt = prefs.getBool('isLoggedInWt');
    final fcmToken = prefs.getString('fcmtoken');

    try {
      await store.onSignoutUser(loggedInPlatform);
    } catch (e) {
      debugPrint('API logout failed, proceeding with local logout: $e');
    }

    final token = prefs.getString('token');
    final tokenPreview = token == null ? 'null' : token.substring(0, token.length > 10 ? 10 : token.length);
    debugPrint('Logout Debug - loggedInEmail: $loggedInEmail, loggedInWt: $loggedInWt, '
        'token: $tokenPreview…, platform: ${Platform.operatingSystem}');

    if (!mounted) return;
    prefs.setString('token', '');
    prefs.setString('fcmtoken', '');
    prefs.setBool('isLoggedInWt', false);
    prefs.setBool('isloggedInEmail', false);
    prefs.setBool('isSignInGoogle', false);
    prefs.clear();
    if (ThemeManager.currentTheme == AppTheme.Dark) {
      Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
    }
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (context) => false);
    debugPrint('User Logged Out - Navigation to login screen executed');

    if (fcmToken != null && !Platform.isWindows && !Platform.isMacOS) {
      try {
        await store.onDeleteNotificationToken(fcmToken);
      } catch (e) {
        debugPrint('FCM token deletion failed: $e');
      }
    }
  }

  Future<void> _deleteAccountUser() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onDeleteUserAccountCall(store.userDetails.value?.id ?? '');
  }

  // ---------------------------------------------------------------------------
  // Navigation switchboard
  // ---------------------------------------------------------------------------
  void _resolveLoggedInPlatform() {
    final deviceType = getDeviceType(context);
    final type = deviceType == DeviceType.Tablet ? 'Tablet' : 'Mobile';
    if (Platform.isIOS) {
      loggedInPlatform = 'ios$type';
    } else if (Platform.isAndroid) {
      loggedInPlatform = 'android$type';
    } else if (Platform.isMacOS) {
      loggedInPlatform = 'macOSDesktop';
    } else if (Platform.isWindows) {
      loggedInPlatform = 'windowsDesktop';
    } else {
      loggedInPlatform = 'unknownDesktop';
    }
  }

  void _navigateToScreen(int currentlyOpenMenuIndex) {
    final loginStore = Provider.of<LoginStore>(context, listen: false);
    final store = Provider.of<HomeStore>(context, listen: false);
    _resolveLoggedInPlatform();
    final title = homeBottomSheetMenu[currentlyOpenMenuIndex].title;

    switch (title) {
      case 'Daily Review':
        Navigator.pushNamed(context, Routes.dailyReview);
        break;
      case 'Settings':
        Navigator.pushNamed(context, Routes.settings);
        break;
      case 'Videos':
        Navigator.pushNamed(context, Routes.videoLectures);
        break;
      case 'Tests':
        Navigator.pushNamed(context, Routes.testCategory);
        break;
      case 'Notes':
        Navigator.pushNamed(context, Routes.notesCategory);
        break;
      case 'Analysis & Solutions':
        Navigator.pushNamed(context, Routes.reportsCategoryList, arguments: {'fromhome': true});
        break;
      case 'Mock Exam Analysis':
        Navigator.pushNamed(context, Routes.masterReportsCategoryList, arguments: {'fromhome': true});
        break;
      case 'Offline Notes':
        Navigator.pushNamed(context, Routes.downloadedNotesCategory);
        break;
      case 'My Plan':
        Navigator.pushNamed(context, Routes.subscriptionPlan);
        break;
      case 'Subscription Plan':
        Navigator.pushNamed(context, Routes.newSubscription, arguments: {'showBackButton': true});
        break;
      case 'Notification':
        Navigator.pushNamed(context, Routes.notificationScreen, arguments: {'fromhome': true});
        break;
      case 'Bookmarks':
        Navigator.pushNamed(context, Routes.bookMarkCategoryList, arguments: {'fromhome': true});
        break;
      case 'Mock Exam Bookmarks':
        Navigator.pushNamed(context, Routes.masterBookMarkCategoryList, arguments: {'fromhome': true});
        break;

      // ── MCQ Review v3 — spaced repetition + planning + reading prefs ──
      case 'Review Queue':
        Navigator.pushNamed(context, Routes.reviewQueueV3);
        break;
      case 'Study Plan':
        Navigator.pushNamed(context, Routes.studyPlan);
        break;
      case 'Scheduled Sessions':
        Navigator.pushNamed(context, Routes.scheduledSessions);
        break;
      case 'Performance Trends':
        Navigator.pushNamed(context, Routes.performanceTrends);
        break;
      case 'Reading Preferences':
        Navigator.pushNamed(context, Routes.readingSettings);
        break;
      case 'Privacy Policy':
        _launchURL('https://sushrutalgs.in/privacy-policy');
        break;
      case 'Refund Policy':
        _launchURL('https://sushrutalgs.in/refund-policy');
        break;
      case 'Terms & Conditions':
        _launchURL('https://sushrutalgs.in/terms-%26-conditions');
        break;
      case 'Contact Us':
        debugPrint('Phone:${loginStore.settingsData.value?.phone}');
        _launchWhatsApp(loginStore.settingsData.value?.phone ?? '');
        break;
      case 'Email':
        debugPrint('email:${loginStore.settingsData.value?.email}');
        _launchEmail(loginStore.settingsData.value?.email ?? '');
        break;
      case 'Logout':
        _showConfirmDialog(
          title: 'Log out of this account?',
          message: 'You will need to sign in again to access your plan and progress.',
          confirmLabel: 'Log out',
          confirmColor: AppTokens.danger(context),
          icon: Icons.logout_rounded,
          onConfirm: () {
            Navigator.pop(context);
            signOut(store, loggedInPlatform);
          },
        );
        break;
      case 'Delete Account':
        _showConfirmDialog(
          title: 'Delete this account?',
          message: 'This is permanent. Your progress, notes and subscription data will be removed.',
          confirmLabel: 'Delete',
          confirmColor: AppTokens.danger(context),
          icon: Icons.delete_forever_rounded,
          onConfirm: () {
            _deleteAccountUser();
            Navigator.of(context).pushNamed(Routes.login);
          },
        );
        break;
    }
  }

  void _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required IconData icon,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.surface(ctx),
        surfaceTintColor: AppTokens.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTokens.dangerSoft(ctx),
                borderRadius: BorderRadius.circular(AppTokens.r12),
              ),
              child: Icon(icon, color: AppTokens.danger(ctx), size: 20),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Text(
                title,
                style: AppTokens.titleMd(ctx).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTokens.body(ctx).copyWith(
            color: AppTokens.ink2(ctx),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppTokens.s16,
          0,
          AppTokens.s16,
          AppTokens.s16,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTokens.body(ctx).copyWith(
                color: AppTokens.ink2(ctx),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s20,
                vertical: AppTokens.s12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.r12),
              ),
            ),
            onPressed: onConfirm,
            child: Text(
              confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Menu tile
  // ---------------------------------------------------------------------------
  Widget _buildMoreMenuContainer({
    required BuildContext context,
    required BoxConstraints boxConstraints,
    required String iconUrl,
    IconData? materialIcon,
    required String title,
  }) {
    if (title.isEmpty) return const SizedBox.shrink();
    final crossSize = (boxConstraints.maxWidth / 4).clamp(84.0, 140.0).toDouble();
    final isDestructive = title == 'Logout' || title == 'Delete Account';
    final iconColor = isDestructive ? AppTokens.danger(context) : AppTokens.accent(context);
    final iconBgColor = isDestructive ? AppTokens.dangerSoft(context) : AppTokens.accentSoft(context);
    return SizedBox(
      width: crossSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final int currentlyOpenMenuIndex =
                homeBottomSheetMenu.indexWhere((element) => element.title == title);
            _navigateToScreen(currentlyOpenMenuIndex);
          },
          borderRadius: BorderRadius.circular(AppTokens.r16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppTokens.s12,
              horizontal: AppTokens.s8,
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(AppTokens.r16),
                  ),
                  // Render the SVG asset when one is provided; fall back
                  // to the Material icon for V3 entries that don't have
                  // a matching SVG (review queue, study plan, etc.).
                  child: iconUrl.isNotEmpty
                      ? SvgPicture.asset(
                          iconUrl,
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                        )
                      : Icon(
                          materialIcon ?? Icons.circle_outlined,
                          size: 24,
                          color: iconColor,
                        ),
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTokens.caption(context).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.ink(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _getUserDetails() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGetUserDetailsCall(context);
  }

  @override
  void initState() {
    super.initState();
    _getUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<HomeStore>(context, listen: false);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = ThemeManager.currentTheme == AppTheme.Dark;

    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: _isDesktop ? const BoxConstraints(maxWidth: 720) : null,
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: _isDesktop
            ? BorderRadius.circular(AppTokens.r28)
            : const BorderRadius.vertical(
                top: Radius.circular(AppTokens.r28),
              ),
      ),
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isDesktop)
                  Container(
                    margin: const EdgeInsets.only(
                      top: AppTokens.s12,
                      bottom: AppTokens.s8,
                    ),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTokens.border(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                InkWell(
                  onTap: () {
                    if (store.userDetails.value != null) {
                      Navigator.of(context).pushNamed(
                        Routes.editProfile,
                        arguments: {
                          'userprofile': store.userDetails.value,
                        },
                      );
                    } else {
                      BottomToast.showBottomToastOverlay(
                        context: context,
                        errorMessage: 'Something went wrong!',
                        backgroundColor: AppTokens.danger(context),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s20,
                      AppTokens.s12,
                      AppTokens.s20,
                      AppTokens.s12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTokens.brand, AppTokens.brand2],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppTokens.r16),
                          ),
                          child: Text(
                            (store.userDetails.value?.fullname ?? 'U').trim().isEmpty
                                ? 'U'
                                : (store.userDetails.value!.fullname![0]).toUpperCase(),
                            style: AppTokens.titleLg(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.userDetails.value?.fullname ?? '',
                                style: AppTokens.titleMd(context).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                store.userDetails.value?.username ?? '',
                                style: AppTokens.caption(context).copyWith(
                                  color: AppTokens.ink2(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Icon(
                          isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                          color: AppTokens.ink2(context),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Switch(
                          value: isDark,
                          // ignore: deprecated_member_use
                          activeColor: Colors.white,
                          activeTrackColor: AppTokens.accent(context),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: AppTokens.border(context),
                          onChanged: (value) {
                            setState(() {
                              themeNotifier.toggleTheme();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s20,
                  ),
                  child: Divider(
                    color: AppTokens.border(context),
                    height: AppTokens.s24,
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s12,
                  ),
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        children: List.generate(
                          homeBottomSheetMenu.length,
                          (index) {
                            return _buildMoreMenuContainer(
                              context: context,
                              boxConstraints: boxConstraints,
                              iconUrl: homeBottomSheetMenu[index].iconUrl,
                              materialIcon: homeBottomSheetMenu[index].materialIcon,
                              title: homeBottomSheetMenu[index].title,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.s24),
              ],
            ),
          );
        },
      ),
    );
  }
}
