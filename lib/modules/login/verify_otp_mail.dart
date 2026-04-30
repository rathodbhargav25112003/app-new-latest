import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/modules/login/store/verify_otp_phone.dart';
import 'package:shusruta_lms/modules/widgets/otp_autofill_field.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../../app/routes.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../login/store/login_store.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';

enum DeviceType { Mobile, Tablet }

DeviceType getDeviceType(BuildContext context) {
  final double screenWidth = MediaQuery.of(context).size.width;
  final double screenHeight = MediaQuery.of(context).size.height;
  final double aspectRatio = screenWidth / screenHeight;

  if (aspectRatio > 0.7 && aspectRatio < 1.3) {
    return DeviceType.Tablet;
  } else {
    return DeviceType.Mobile;
  }
}

class VerificationOtpMail extends StatefulWidget {
  final String email;
  const VerificationOtpMail({super.key, required this.email});

  @override
  State<VerificationOtpMail> createState() => _VerificationOtpMailState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => VerificationOtpMail(
        email: arguments['email'],
      ),
    );
  }
}

class _VerificationOtpMailState extends State<VerificationOtpMail> with WidgetsBindingObserver {
  Socket? socket;
  bool isKeyboardOpen = false;
  bool isCompleted = false;
  String otp = '';
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerActive = false;
  String loggedInPlatform = '';
  // OtpAutofillField owns its own per-cell controllers + SMS retrieval.
  // We just track the captured OTP string here.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _firebaseMessaging
        .requestPermission(alert: true, sound: true, provisional: false, badge: true)
        .then((settings) {
      // print('Firebase Messaging Authorization Status: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          // print('Firebase Messaging onMessage: ${message.notification?.body}');
          setState(() {});
          _handleMessage(message);
        });
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          // print('Firebase Messaging onMessageOpenedApp: $message');
          // setState(() {
          //   _message = message.notification?.body ?? '';
          // });
          _handleMessage(message);
        });
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }
    });
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    final notification = message.notification;
    final imageUrl = message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl ??
        message.notification?.web?.image;
    if (notification != null) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.white,
          surfaceTintColor: AppColors.white,
          contentPadding: const EdgeInsets.only(
            left: Dimensions.PADDING_SIZE_LARGE,
            right: Dimensions.PADDING_SIZE_LARGE,
            top: Dimensions.PADDING_SIZE_DEFAULT * 2,
            bottom: Dimensions.PADDING_SIZE_DEFAULT * 2,
          ),
          shape: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: Text(
                  notification.title?.toUpperCase() ?? '',
                  style: interRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmallOverLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ),
              if (imageUrl != null && imageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Dimensions.PADDING_SIZE_LARGE),
                  child: SizedBox(
                      height: 143,
                      width: double.infinity,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.fitWidth,
                      )),
                ),
              const SizedBox(
                height: Dimensions.PADDING_SIZE_LARGE,
              ),
              Text(
                notification.body ?? '',
                style: interRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(
                height: Dimensions.PADDING_SIZE_LARGE,
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  height: Dimensions.PADDING_SIZE_LARGE * 2.7,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: ThemeManager.blueFinal,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: ThemeManager.buttonBorder, width: 0.89),
                      boxShadow: [
                        BoxShadow(
                            offset: const Offset(0, 1.7733),
                            blurRadius: 3.5467,
                            spreadRadius: 0,
                            color: ThemeManager.dropShadow.withOpacity(0.16)),
                        BoxShadow(
                            offset: const Offset(0, 0),
                            blurRadius: 0.8866,
                            spreadRadius: 0,
                            color: ThemeManager.dropShadow2.withOpacity(0.04)),
                      ]),
                  child: Text(
                    "Ok",
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      fontWeight: FontWeight.w700,
                      color: ThemeManager.white,
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

  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // print('Firebase Messaging onBackgroundMessage: $message');
  }

  // Wave-3.5: legacy hand-rolled OTP cells + custom-keyboard
  // bottom-sheet replaced by OtpAutofillField (system keyboard +
  // iOS QuickType + Android SMS Retriever).

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    socket?.disconnect();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    setState(() {
      isKeyboardOpen = bottomInset > 0;
    });
  }

  // @override
  // Widget build(BuildContext context) {
  //   final loginStore = Provider.of<LoginStore>(context, listen: false);
  //
  //   final deviceType = getDeviceType(context);
  //   String type = deviceType == DeviceType.Tablet?'Tablet':'Mobile';
  //   if(Platform.isIOS){
  //       loggedInPlatform = "ios$type";
  //   }else if(Platform.isAndroid){
  //     loggedInPlatform =  "android$type";
  //   }
  //
  //   return Scaffold(
  //     backgroundColor: ThemeManager.white,
  //     resizeToAvoidBottomInset: false,
  //     body: SingleChildScrollView(
  //         physics: const NeverScrollableScrollPhysics(),
  //         child: SizedBox(
  //             height: MediaQuery.of(context).size.height,
  //             child: Padding(
  //               padding: EdgeInsets.only(
  //                 left: Dimensions.PADDING_SIZE_LARGE + Dimensions.PADDING_SIZE_SMALL,
  //                 top: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.5,
  //                 right: Dimensions.PADDING_SIZE_LARGE + Dimensions.PADDING_SIZE_SMALL,
  //                 bottom: isKeyboardOpen
  //                     ? MediaQuery.of(context).viewInsets.bottom
  //                     : Dimensions.PADDING_SIZE_LARGE,
  //               ),
  //               child: Column(
  //                 children: [
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.start,
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Image.asset("assets/image/verify_lock.png"),
  //                       const SizedBox(
  //                         width: Dimensions.PADDING_SIZE_LARGE,
  //                       ),
  //                       Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Text(
  //                             "Enter 4 digit OTP",
  //                             style: interSemiBold.copyWith(
  //                               fontSize: Dimensions.fontSizeExtraLarge,
  //                             ),
  //                           ),
  //                           Text(
  //                             "We have sent you OTP on",
  //                             style: interSemiBold.copyWith(
  //                                 fontSize: Dimensions.fontSizeExtraSmall,
  //                                 color: Theme.of(context).hintColor
  //                             ),
  //                           ),
  //                           Text(
  //                             widget.email,
  //                             style: interSemiBold.copyWith(
  //                                 fontSize: Dimensions.fontSizeExtraSmall,
  //                                 color: Theme.of(context).hintColor
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(
  //                     height: Dimensions.PADDING_SIZE_LARGE * 2,
  //                   ),
  //                   OTPTextField(
  //                     length: 4,
  //                     width: MediaQuery.of(context).size.width,
  //                     fieldWidth: 40,
  //                     style:  TextStyle(
  //                         fontSize: 17,
  //                         color: ThemeManager.black
  //                     ),
  //                     keyboardType: TextInputType.number,
  //                     textFieldAlignment: MainAxisAlignment.spaceAround,
  //                     fieldStyle: FieldStyle.underline,
  //                     spaceBetween: Dimensions.PADDING_SIZE_DEFAULT,
  //                     hasError: false,
  //                     onCompleted: (pin) {
  //                       otp = pin;
  //                     },
  //                     onChanged: (value) {
  //                       setState(() {
  //                         isCompleted = true;
  //                       });
  //                     },
  //                   ),
  //
  //                   const SizedBox(
  //                     height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
  //                   ),
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: [
  //                       Text(
  //                         "Didn't receive code? ",
  //                         style: interRegular.copyWith(
  //                             fontSize: Dimensions.fontSizeSmall,
  //                             color: Theme.of(context).hintColor
  //                         ),
  //                       ),
  //                       if (!_timerActive)
  //                         InkWell(
  //                           onTap: () {
  //                             _startTimer();
  //                             _resendOtp(loginStore, widget.email);
  //                           },
  //                           child: Text(
  //                             "Resend",
  //                             style: interRegular.copyWith(
  //                               fontSize: Dimensions.fontSizeSmall,
  //                               color: Theme.of(context).primaryColor,
  //                               decoration: TextDecoration.underline,
  //                             ),
  //                           ),
  //                         ),
  //                       if (_timerActive)
  //                         Text(
  //                           remainingTime(),
  //                           style: interRegular.copyWith(
  //                             fontSize: Dimensions.fontSizeSmall,
  //                             color: Theme.of(context).hintColor,
  //                           ),
  //                         ),
  //                     ],
  //                   ),
  //                   const SizedBox(
  //                     height: Dimensions.PADDING_SIZE_DEFAULT,
  //                   ),
  //                   Text(
  //                     "If Not Received in Inbox Check Spam Folder",
  //                     style: interRegular.copyWith(
  //                         fontSize: Dimensions.fontSizeSmall,
  //                         color: Theme.of(context).hintColor
  //                     ),
  //                   ),
  //                   Expanded(
  //                     child: Column(
  //                       children: [
  //                         const Spacer(),
  //                         Observer(
  //                         builder: (_) {
  //                            return CustomButton(
  //                              onPressed: () {
  //                                otp!=""?
  //                                _verifyOtpMail(loginStore,widget.email,otp,loggedInPlatform):
  //                                BottomToast.showBottomToastOverlay(context: context,
  //                                    errorMessage: "Enter OTP",
  //                                    backgroundColor: ThemeManager.redAlert);
  //                              },
  //                              buttonText: "Verify",
  //                              height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
  //                              bgColor: isCompleted?Theme.of(context).primaryColor:Theme.of(context).disabledColor,
  //                              radius: Dimensions.RADIUS_SMALL,
  //                              transparent: true,
  //                              fontSize: Dimensions.fontSizeDefault,
  //                              child: loginStore.isLoading ? const CircularProgressIndicator(color: Colors.white,) : null,
  //                            );
  //                           }
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             )
  //         )
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    final loginStore = Provider.of<LoginStore>(context, listen: false);

    final deviceType = getDeviceType(context);
    String type = deviceType == DeviceType.Tablet ? 'Tablet' : 'Mobile';
    if (Platform.isIOS) {
      loggedInPlatform = "ios$type";
    } else if (Platform.isAndroid) {
      loggedInPlatform = "android$type";
    }

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppTokens.scaffold(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTokens.ink(context), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppTokens.s24),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.start,
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: [
                  //     Image.asset("assets/image/verify_lock.png"),
                  //     const SizedBox(
                  //       width: Dimensions.PADDING_SIZE_LARGE,
                  //     ),
                  //     Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text(
                  //           "Enter 4 digit OTP",
                  //           style: interSemiBold.copyWith(
                  //             fontSize: Dimensions.fontSizeExtraLarge,
                  //           ),
                  //         ),
                  //         Text(
                  //           "We have sent you OTP on",
                  //           style: interSemiBold.copyWith(
                  //               fontSize: Dimensions.fontSizeExtraSmall,
                  //               color: Theme.of(context).hintColor
                  //           ),
                  //         ),
                  //         Text(
                  //           widget.email,
                  //           style: interSemiBold.copyWith(
                  //               fontSize: Dimensions.fontSizeExtraSmall,
                  //               color: Theme.of(context).hintColor
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ],
                  // ),
                  // Apple-style hero
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTokens.accentSoft(context),
                      borderRadius: AppTokens.radius16,
                    ),
                    child: Icon(Icons.mark_email_read_outlined, size: 28, color: AppTokens.accent(context)),
                  ),
                  const SizedBox(height: AppTokens.s24),
                  Text(
                    "Check your email",
                    style: AppTokens.displayMd(context),
                  ),
                  const SizedBox(height: AppTokens.s8),
                  RichText(
                    text: TextSpan(
                      style: AppTokens.bodyLg(context).copyWith(
                        color: AppTokens.muted(context),
                        height: 1.45,
                      ),
                      children: [
                        const TextSpan(text: "We've sent a 4-digit code to "),
                        TextSpan(
                          text: _maskEmail(widget.email),
                          style: TextStyle(
                            color: AppTokens.ink(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ". "),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Text(
                              "Edit",
                              style: AppTokens.body(context).copyWith(
                                color: AppTokens.accent(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.s32),
                  // System keyboard + iOS QuickType + Android SMS retrieval
                  OtpAutofillField(
                    length: 4,
                    autoStartListener: true,
                    onChanged: (code) {
                      otp = code;
                      setState(() => isCompleted = code.length == 4);
                    },
                    onCompleted: (code) {
                      otp = code;
                      setState(() => isCompleted = true);
                      _verifyOtpMail(loginStore, widget.email, otp, loggedInPlatform);
                    },
                  ),
                  const SizedBox(height: AppTokens.s24),
                  Observer(builder: (_) {
                    return CustomButton(
                      onPressed: () {
                        if (otp.length == 4) {
                          _verifyOtpMail(loginStore, widget.email, otp, loggedInPlatform);
                        } else {
                          BottomToast.showBottomToastOverlay(
                              context: context,
                              errorMessage: "Please enter the 4-digit code.",
                              backgroundColor: ThemeManager.redAlert);
                        }
                      },
                      buttonText: "Verify",
                      height: 54,
                      bgColor: isCompleted
                          ? AppTokens.accent(context)
                          : AppTokens.accent(context).withOpacity(0.4),
                      radius: AppTokens.r16,
                      transparent: true,
                      fontSize: 16,
                      child: loginStore.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    );
                  }),
                  const SizedBox(height: AppTokens.s20),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          !_timerActive ? "Didn't receive it?  " : "Resend in ",
                          style: AppTokens.body(context),
                        ),
                        if (!_timerActive)
                          InkWell(
                            onTap: () {
                              _startTimer();
                              _resendOtp(loginStore, widget.email);
                            },
                            child: Text(
                              "Resend OTP",
                              style: AppTokens.body(context).copyWith(
                                color: AppTokens.accent(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (_timerActive)
                          Text(
                            "${remainingTime()}s",
                            style: AppTokens.body(context).copyWith(
                              color: AppTokens.muted(context),
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.s24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Soft email mask used in the subtitle. "abc123@gmail.com" →
  /// "abc•••••@gmail.com". Keeps the first 3 chars + domain visible.
  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final local = parts[0];
    if (local.length <= 3) return email;
    return '${local.substring(0, 3)}•••••@${parts[1]}';
  }

  void _startTimer() {
    setState(() {
      _timerActive = true;
      _remainingSeconds = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _timerActive = false;
        }
      });
    });
  }

  String remainingTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return seconds.toString().padLeft(2, '0');
  }

  Future<void> _resendOtp(LoginStore store, String email) async {
    await store.onSendOtpForgotEmail(email).then((value) {
      if (store.errorMessageOtp.value?.message != null) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: "OTP Sent Successfully!",
          backgroundColor: Theme.of(context).primaryColor,
        );
      } else if (store.errorMessageOtp.value?.error != null) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: store.errorMessageOtp.value?.error ?? "Something went wrong!",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    });
  }

  Future<void> _verifyOtpMail(LoginStore store, String email, String otp, String loggedInPlatform) async {
    await store.onVerifyOtpApiCall(email, otp, isTablet(context) ? "tab" : "").then((value) async {
      if (store.loginWithPhone.value?.token != null && store.loginWithPhone.value!.lastLoginDevices.isEmpty) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (!Platform.isWindows && !Platform.isMacOS) {
          prefs.setString('token', store.loginWithPhone.value?.token ?? "");
          prefs.setBool('isloggedInEmail', true);
          String? fcmtoken = await _firebaseMessaging.getToken();
          setState(() {
            _fcmToken = fcmtoken;
          });
          prefs.setString('fcmtoken', _fcmToken ?? "");
          await store.onCreateNotificationToken(_fcmToken ?? "");
        }
        connectSocketIO();
        prefs.setString('token', store.loginWithPhone.value?.token ?? "");
        // ignore: use_build_context_synchronously
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: "Logged in Successfully!",
          backgroundColor: Theme.of(context).primaryColor,
        );
        Navigator.of(context).pushNamed(Routes.home, arguments: {'trial': false});
      } else if (store.loginWithPhone.value?.message != null) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: store.loginWithPhone.value?.message ?? "",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      } else if (store.loginWithPhone.value?.token != null &&
          store.loginWithPhone.value!.lastLoginDevices.isNotEmpty &&
          store.loginWithPhone.value?.message == null) {
        showDevicePopup(
            context, store.loginWithPhone.value!.lastLoginDevices, store.loginWithPhone.value!.token!);
      }

      //  else if(store.loginWithPhone.value?.error != null){
      //      BottomToast.showBottomToastOverlay(
      //        context: context,
      //        errorMessage: store.loginWithPhone.value?.error ?? "",
      //        backgroundColor: Theme.of(context).colorScheme.error,
      //      );
      //  }else if(store.loginWithPhone.value?.err !=null){
      //    BottomToast.showBottomToastOverlay(
      //      context: context,
      //      errorMessage: store.loginWithPhone.value?.err?.message ?? "",
      //      backgroundColor: Theme.of(context).colorScheme.error,
      //    );
      // }
    });
  }

  void connectSocketIO() {
    socket = io('http://api.sushrutalgs.in:5001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket?.on('connect', (_) {
      print('Connected to socket.io server');
    });

    socket?.on('disconnect', (_) {
      print('Disconnected from socket.io server');
    });
  }
}
