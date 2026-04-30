import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/login/store/login_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';
// Custom keyboard import - commented out as we're using system default keyboard
// Uncomment this if you want to re-enable the custom keyboard
// import 'keyboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const LoginScreen(),
    );
  }
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final _emailKey = GlobalKey<FormFieldState<String>>();
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  bool isKeyboardOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    settingsData();
  }

  Future<void> settingsData() async {
    final store = Provider.of<LoginStore>(context, listen: false);
    await store.onGetSettingsData();
  }

  // void _handleMessage(RemoteMessage message) {
  //   final notification = message.notification;
  //   if (notification != null) {
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: Text(notification.title ?? ''),
  //         content: Text(notification.body ?? ''),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('OK'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }

  // Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  //   // print('Firebase Messaging onBackgroundMessage: $message');
  // }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    emailController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom ?? 0;
    setState(() {
      isKeyboardOpen = bottomInset > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<LoginStore>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: KeyboardActions(
          config: KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
            actions: [
              KeyboardActionsItem(
                focusNode: FocusNode(),
                displayArrows: false,
                displayDoneButton: true,
                onTapAction: () => FocusScope.of(context).unfocus(),
              ),
            ],
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
            child: Observer(
              builder: (_) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTokens.s32),
                    Text(
                      "Welcome back",
                      style: AppTokens.displayMd(context),
                    ),
                    const SizedBox(height: AppTokens.s8),
                    Text(
                      "Sign in with your email — we'll send a verification code.",
                      style: AppTokens.bodyLg(context).copyWith(
                        color: AppTokens.muted(context),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppTokens.s32),
                    TextFormField(
                      key: _emailKey,
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      cursorColor: AppTokens.accent(context),
                      style: AppTokens.bodyLg(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email address.';
                        } else if (!_emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        final ok = _emailKey.currentState?.validate() ?? false;
                        if (ok) _login(store, emailController.text);
                      },
                      decoration: AppTokens.inputDecoration(
                        context,
                        hint: 'name@example.com',
                        label: 'Email address',
                        prefix: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 6),
                          child:
                              Icon(Icons.alternate_email_rounded, size: 18, color: AppTokens.muted(context)),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s24),
                    CustomButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        final ok = _emailKey.currentState?.validate() ?? false;
                        if (ok) _login(store, emailController.text);
                      },
                      buttonText: "Continue",
                      height: 54,
                      bgColor: AppTokens.accent(context),
                      radius: AppTokens.r16,
                      transparent: true,
                      fontSize: 16,
                      child: store.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: AppTokens.s24),
                    if (Platform.isAndroid || Platform.isIOS)
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          children: [
                            Text(
                              "New here?",
                              style: AppTokens.body(context),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(context).pushNamed(Routes.register),
                              child: Text(
                                "Create an account",
                                style: AppTokens.body(context).copyWith(
                                  color: AppTokens.accent(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    if (!store.isLoadingSettings)
                      _SupportFooter(
                        email: store.settingsData.value?.email ?? '',
                        phone: store.settingsData.value?.phone ?? '',
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login(LoginStore store, String email) async {
    await store.onSendOtpForgotEmail(email).then((value) {
      // Check for ERROR_REGISTER_User case
      if (store.errorMessageOtp.value?.error == 'ERROR_REGISTER_User') {
        // Show restore user dialog
        _showRestoreUserDialog(store, email);
      } else if (store.errorMessageOtp.value?.message != null) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: "OTP Sent Successfully!",
          backgroundColor: Theme.of(context).primaryColor,
        );

        Navigator.of(context).pushNamed(Routes.verifyOtpMail, arguments: {'email': emailController.text});
      } else if (store.errorMessageOtp.value?.error != null) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: store.errorMessageOtp.value?.error ?? "Something went wrong!",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    });

    // store.isConnected?
    // await store.onRegisterApiCall(email, password).then((value) async {
    //   if (store.login.value?.token != null) {
    //     SharedPreferences prefs = await SharedPreferences.getInstance();
    //     prefs.setString('token', store.login.value?.token??"");
    //     prefs.setBool('isloggedInEmail', true);
    //     String? fcmtoken = await _firebaseMessaging.getToken();
    //     setState(() {
    //       _fcmToken = fcmtoken;
    //     });
    //     prefs.setString('fcmtoken',_fcmToken??"");
    //     debugPrint('fcm $_fcmToken');
    //     await store.onCreateNotificationToken(_fcmToken??"");
    //
    //     BottomToast.showBottomToastOverlay(
    //       context: context,
    //       errorMessage: "Loggedin Successfully!",
    //       backgroundColor: Theme.of(context).primaryColor,
    //     );
    //     Navigator.of(context).pushNamed(Routes.home);
    //   } else {
    //     debugPrint("tokenerr");
    //     BottomToast.showBottomToastOverlay(
    //       context: context,
    //       errorMessage: store.login.value?.err?.message ?? "",
    //       backgroundColor: Theme.of(context).colorScheme.error,
    //     );
    //   }
    // });
  }

  // Future<void> _loginWithGoogle(BuildContext context, LoginStore store) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final GoogleSignIn googleSignIn = GoogleSignIn();
  //   final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
  //   if (googleSignInAccount != null) {
  //     final GoogleSignInAuthentication googleSignInAuthentication =
  //     await googleSignInAccount.authentication;
  //     final AuthCredential authCredential = GoogleAuthProvider.credential(
  //         idToken: googleSignInAuthentication.idToken,
  //         accessToken: googleSignInAuthentication.accessToken);
  //
  //     UserCredential result = await auth.signInWithCredential(authCredential);
  //     User? user = result.user;
  //     String? email = user?.email;
  //     if (result.additionalUserInfo?.isNewUser ?? false) {
  //       String? fcmtoken = await _firebaseMessaging.getToken();
  //       setState(() {
  //         _fcmToken = fcmtoken;
  //       });
  //       prefs.setString('fcmtoken',_fcmToken??"");
  //       debugPrint('fcm $_fcmToken');
  //       await store.onCreateNotificationToken(_fcmToken??"");
  //
  //       Navigator.of(context).pushNamed(Routes.googleSignUpForm,
  //         arguments: {"username":user?.displayName,"email":user?.email},);
  //     } else {
  //       await store.onLoginApiCall(email!);
  //       if (store.login.value?.token != null) {
  //         prefs.setString('token', store.login.value?.token??"");
  //         prefs.setBool('isSignInGoogle', true);
  //         String? fcmtoken = await _firebaseMessaging.getToken();
  //         setState(() {
  //           _fcmToken = fcmtoken;
  //         });
  //         prefs.setString('fcmtoken',_fcmToken??"");
  //         debugPrint('fcm $_fcmToken');
  //         await store.onCreateNotificationToken(_fcmToken??"");
  //
  //         BottomToast.showBottomToastOverlay(
  //           context: context,
  //           errorMessage: "Loggedin Successfully!",
  //           backgroundColor: Theme.of(context).primaryColor,
  //         );
  //         Navigator.of(context).pushNamed(Routes.home);
  //       } else {
  //         debugPrint("tokenerr");
  //         BottomToast.showBottomToastOverlay(
  //           context: context,
  //           errorMessage: store.login.value?.err?.message ?? "",
  //           backgroundColor: Theme.of(context).colorScheme.error,
  //         );
  //       }
  //     }
  //   }
  // }

  void _showRestoreUserDialog(LoginStore store, String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Account Previously Deleted",
            style: interBold.copyWith(
              fontSize: Dimensions.fontSizeDefaultLarge,
              color: ThemeManager.black,
            ),
          ),
          content: Text(
            "This account was previously deleted. You can restore it to continue.",
            style: TextStyle(
              fontSize: Dimensions.fontSizeDefault,
              color: ThemeManager.grey4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  fontSize: Dimensions.fontSizeDefault,
                  color: ThemeManager.grey4,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Call restore user API
                await _handleRestoreUser(store, email);
              },
              child: Text(
                "Restore Account",
                style: interBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleRestoreUser(LoginStore store, String email) async {
    try {
      // Get phone from the restore user info if available, otherwise use empty string
      String phone = '';
      if (store.restoreUserInfo != null && store.restoreUserInfo!['phone'] != null) {
        phone = store.restoreUserInfo!['phone'].toString();
      }

      if (mounted) {
        final result = await store.onRestoreUser(email, phone);

        if (result != null && result['success'] == true && result['message'] != null) {
          // Show success message
          BottomToast.showBottomToastOverlay(
            context: context,
            errorMessage: result['message'] ?? "User restored successfully",
            backgroundColor: AppColors.primaryColor,
          );

          // Navigate to login screen after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pushNamed(Routes.login);
            }
          });
        } else {
          // Show error message
          BottomToast.showBottomToastOverlay(
            context: context,
            errorMessage:
                store.errorMessage.isNotEmpty ? store.errorMessage : "Failed to restore user account",
            backgroundColor: AppColors.redAlert,
          );
        }
      }
    } catch (e) {
      // Show error message for any exception
      if (mounted) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: "An error occurred while restoring your account",
          backgroundColor: AppColors.redAlert,
        );
      }
    }
  }
}

/// Soft bottom-of-screen "Need help?" block that pulls support email +
/// phone from the existing Settings store. Apple-style: subtle, single
/// line per contact, tappable but not loud.
class _SupportFooter extends StatelessWidget {
  final String email;
  final String phone;
  const _SupportFooter({required this.email, required this.phone});

  @override
  Widget build(BuildContext context) {
    if (email.isEmpty && phone.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Need help signing in?",
            style: AppTokens.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink2(context),
            ),
          ),
          const SizedBox(height: 4),
          if (email.isNotEmpty)
            Text(email, style: AppTokens.caption(context), overflow: TextOverflow.ellipsis),
          if (phone.isNotEmpty) Text("+91 $phone", style: AppTokens.caption(context)),
        ],
      ),
    );
  }
}
