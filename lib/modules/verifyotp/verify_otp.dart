import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/modules/login/store/verify_otp_phone.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/registerationData.dart';
import '../login/store/login_store.dart';
import '../signup/store/signup_store.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';
import '../widgets/otp_autofill_field.dart';

class VerificationOtp extends StatefulWidget {
  final String email;
  final String email2;
  final RegistrationData registerData;
  final bool trial;
  final bool? isProfileUpdate;
  const VerificationOtp(
      {super.key,
      required this.email,
      required this.registerData,
      required this.trial,
      required this.email2,
      this.isProfileUpdate});

  @override
  State<VerificationOtp> createState() => _VerificationOtpState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => VerificationOtp(
        email: arguments['email'],
        email2: arguments['email2'],
        registerData: arguments['registrationObj'],
        trial: arguments['trial'],
        isProfileUpdate: arguments['isProfileUpdate'],
      ),
    );
  }
}

class _VerificationOtpState extends State<VerificationOtp> with WidgetsBindingObserver {
  bool isKeyboardOpen = false;
  bool isCompleted = false;
  String otp = '';
  String? _fcmToken;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerActive = false;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // OTP captured from the OtpAutofillField. Kept as a single string
  // since the new widget owns its own per-cell controllers + handles
  // SMS retrieval / iOS QuickType / paste-distribute internally.

  @override
  void initState() {
    super.initState();
    debugPrint('registerData${widget.registerData.fullName}');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom ?? 0;
    setState(() {
      isKeyboardOpen = bottomInset > 0;
    });
  }

  // Custom hand-rolled OTP cells + bottom-sheet number keyboard
  // were removed in wave 3.5 — replaced by OtpAutofillField which
  // uses the SYSTEM keyboard (iOS QuickType natively surfaces the
  // OTP from the SMS, Android pulls it via SMS Retriever API).

  // @override
  // Widget build(BuildContext context) {
  //   final store = Provider.of<SignupStore>(context, listen: false);
  //   final loginStore = Provider.of<LoginStore>(context, listen: false);
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
  //                               fontSize: Dimensions.fontSizeExtraSmall,
  //                               color: Theme.of(context).hintColor
  //                             ),
  //                           ),
  //                           Text(
  //                             "${widget.email} / ${widget.email2}"??"",
  //                             style: interSemiBold.copyWith(
  //                               fontSize: Dimensions.fontSizeExtraSmall,
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
  //                     style: const TextStyle(
  //                         fontSize: 17
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
  //                   const SizedBox(
  //                     height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
  //                   ),
  //                   Text(
  //                     "Please Check Your Email / WhatsApp for the Code",
  //                     style: interRegular.copyWith(
  //                         fontSize: Dimensions.fontSizeSmall,
  //                         color: Theme.of(context).hintColor
  //                     ),
  //                   ),
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
  //                             // _resendOtp(store, widget.email);
  //                             _resendOtpPhone(store, widget.email,widget.email2);
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
  //                   Expanded(
  //                     child: Column(
  //                       children: [
  //                         const Spacer(),
  //                         CustomButton(
  //                           onPressed: () {
  //                             otp!=""?
  //                             // _verifyOtpMail(store,loginStore,widget.email,otp):
  //                             _verifyOtpPhone(store,loginStore,widget.email,otp):
  //                             BottomToast.showBottomToastOverlay(context: context,
  //                                 errorMessage: "Enter OTP",
  //                                 backgroundColor: ThemeManager.redAlert);
  //                           },
  //                           buttonText: "Verify",
  //                           height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
  //                           bgColor: isCompleted?Theme.of(context).primaryColor:Theme.of(context).disabledColor,
  //                           radius: Dimensions.RADIUS_SMALL,
  //                           transparent: true,
  //                           fontSize: Dimensions.fontSizeDefault,
  //                           child: store.isLoading ? const CircularProgressIndicator(color: Colors.white,) : null,
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
    final store = Provider.of<SignupStore>(context, listen: false);
    final loginStore = Provider.of<LoginStore>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      // Soft transparent app bar — back button only, no title.
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
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              left: AppTokens.s24,
              top: AppTokens.s8,
              right: AppTokens.s24,
              bottom: isKeyboardOpen ? MediaQuery.of(context).viewInsets.bottom : AppTokens.s32,
            ),
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
                //           "${widget.email} / ${widget.email2}"??"",
                //           style: interSemiBold.copyWith(
                //               fontSize: Dimensions.fontSizeExtraSmall,
                //               color: Theme.of(context).hintColor
                //           ),
                //         ),
                //       ],
                //     ),
                //   ],
                // ),
                // Apple-style hero: lock badge + headline + body
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: AppTokens.radius16,
                  ),
                  child: Icon(Icons.lock_outline_rounded, size: 28, color: AppTokens.accent(context)),
                ),
                const SizedBox(height: AppTokens.s24),
                Text(
                  "Verify your phone",
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
                        text: widget.email,
                        style: TextStyle(
                          color: AppTokens.ink(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: "."),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.s32),
                // System keyboard + iOS QuickType + Android SMS
                // Retriever — fully replaces the legacy custom
                // bottom-sheet keyboard.
                OtpAutofillField(
                  length: 4,
                  autoStartListener: true,
                  onChanged: (code) {
                    otp = code;
                    setState(() {
                      isCompleted = code.length == 4;
                    });
                  },
                  onCompleted: (code) {
                    otp = code;
                    setState(() => isCompleted = true);
                    _verifyOtpPhone(store, loginStore, widget.email, otp);
                  },
                ),
                const SizedBox(height: AppTokens.s24),
                Observer(builder: (context) {
                  return CustomButton(
                    onPressed: () {
                      if (otp.length == 4) {
                        _verifyOtpPhone(store, loginStore, widget.email, otp);
                      } else {
                        BottomToast.showBottomToastOverlay(
                            context: context,
                            errorMessage: "Please enter the 4-digit code.",
                            backgroundColor: ThemeManager.redAlert);
                      }
                    },
                    buttonText: "Verify",
                    textColor: Colors.white,
                    height: 54,
                    bgColor:
                        isCompleted ? AppTokens.accent(context) : AppTokens.accent(context).withOpacity(0.4),
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
                  );
                }),
                const SizedBox(height: AppTokens.s20),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Text(
                //       "Didn't receive code? ",
                //       style: interRegular.copyWith(
                //           fontSize: Dimensions.fontSizeSmall,
                //           color: Theme.of(context).hintColor
                //       ),
                //     ),
                //     if (!_timerActive)
                //       InkWell(
                //         onTap: () {
                //           _startTimer();
                //           // _resendOtp(store, widget.email);
                //           _resendOtpPhone(store, widget.email,widget.email2);
                //         },
                //         child: Text(
                //           "Resend",
                //           style: interRegular.copyWith(
                //             fontSize: Dimensions.fontSizeSmall,
                //             color: Theme.of(context).primaryColor,
                //             decoration: TextDecoration.underline,
                //           ),
                //         ),
                //       ),
                //     if (_timerActive)
                //       Text(
                //         "Resend code in ${remainingTime()}s",
                //         style: interRegular.copyWith(
                //           fontSize: Dimensions.fontSizeSmall,
                //           color: Theme.of(context).hintColor,
                //         ),
                //       ),
                //   ],
                // ),
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
                            _resendOtpPhone(store, widget.email, widget.email2);
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
              ],
            ),
          ),
        ),
      ),
    );
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

  Future<void> _resendOtp(SignupStore store, String email) async {
    await store.onSendOtpToMail(email, widget.registerData.fullName).then((value) {
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

  Future<void> _resendOtpPhone(SignupStore store, String phone, String email) async {
    await store.onSendOtpToPhone(phone, email).then((value) {
      if (store.errorMessageOtp2.value?.message != null) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: "OTP Sent Successfully! both Email and WhatsApp",
          backgroundColor: Theme.of(context).primaryColor,
        );
      } else if (store.errorMessageOtp2.value?.error != null) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: store.errorMessageOtp2.value?.error ?? "Something went wrong!",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    });
  }

  Future<void> _verifyOtpMail(SignupStore store, LoginStore loginStore, String email, String otp) async {
    String fullName = widget.registerData.fullName;
    String dateOfBirth = widget.registerData.dateOfBirth;
    String preparingVal = widget.registerData.preparingValue;
    String stateVal = widget.registerData.stateValue;
    List<String> preparingFor = widget.registerData.preparingFor;
    String currentStatus = widget.registerData.currentStatus;
    String phoneNo = widget.registerData.phoneNumber;
    // String password = widget.registerData.password;
    // String confirmPass = widget.registerData.confirmPass;

    await store.onVerifyOtpToMail(otp, email).then((value) async {
      if (store.registerWithEmail.value?.message != null) {
        await store.onRegisterWithPhoneApiCall(fullName, dateOfBirth, preparingVal, stateVal, preparingFor,
            currentStatus, phoneNo, email, isTablet(context) ? "tab" : "",
            standardId: widget.registerData.standardId, preparingId: widget.registerData.preparingId);

        String errorMessage = store.errorMessage;
        debugPrint('created${store.signupWithPhone.value?.created}');
        if (store.signupWithPhone.value?.created == null) {
          BottomToast.showBottomToastOverlay(
            context: context,
            errorMessage: errorMessage,
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        } else if (store.signupWithPhone.value?.created == false) {
          debugPrint('created${store.signupWithPhone.value?.data?.token}');
          if (store.signupWithPhone.value?.data?.token != null) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setString('token', store.signupWithPhone.value?.data?.token ?? "");
            prefs.setBool('isloggedInEmail', true);
            String? fcmtoken = await _firebaseMessaging.getToken();
            setState(() {
              _fcmToken = fcmtoken;
            });
            prefs.setString('fcmtoken', _fcmToken ?? "");
            debugPrint('fcm $_fcmToken');
            await loginStore.onCreateNotificationToken(_fcmToken ?? "");
            BottomToast.showBottomToastOverlay(
              context: context,
              errorMessage: "User Registered Successfully",
              backgroundColor: Theme.of(context).primaryColor,
            );
            Navigator.of(context).pushNamed(Routes.home, arguments: {'trial': widget.trial});
          }
        }
      } else if (store.registerWithEmail.value?.error != null) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: store.registerWithEmail.value?.error ?? "Something went wrong!",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    });
  }

  Future<void> _verifyOtpPhone(SignupStore store, LoginStore loginStore, String phoneNo, String otp) async {
    String fullName = widget.registerData.fullName;
    String dateOfBirth = widget.registerData.dateOfBirth;
    String preparingVal = widget.registerData.preparingValue;
    String stateVal = widget.registerData.stateValue;
    List<String> preparingFor = widget.registerData.preparingFor;
    String currentStatus = widget.registerData.currentStatus;
    String email = widget.registerData.email;

    await store.onVerifyOtpToPhone(phoneNo, otp).then((value) async {
      if (store.registerWithEmail2.value?.message != null) {
        // Check if this is a profile update
        if (widget.isProfileUpdate == true) {
          // Return true to indicate successful verification
          Navigator.of(context).pop(true);
        } else {
          // Normal registration flow
          await store.onRegisterWithPhoneApiCall(fullName, dateOfBirth, preparingVal, stateVal, preparingFor,
              currentStatus, phoneNo, email, isTablet(context) ? "tab" : "",
              standardId: widget.registerData.standardId, preparingId: widget.registerData.preparingId);

          String errorMessage = store.errorMessage;
          debugPrint('created${store.signupWithPhone.value?.created}');
          if (store.signupWithPhone.value?.created == null) {
            BottomToast.showBottomToastOverlay(
              context: context,
              errorMessage: errorMessage,
              backgroundColor: Theme.of(context).colorScheme.error,
            );
          } else if (store.signupWithPhone.value?.created == false) {
            debugPrint('created${store.signupWithPhone.value?.data?.token}');
            if (store.signupWithPhone.value?.data?.token != null) {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setString('token', store.signupWithPhone.value?.data?.token ?? "");
              prefs.setBool('isloggedInEmail', true);
              if (Platform.isIOS || Platform.isAndroid) {
                String? fcmtoken = await _firebaseMessaging.getToken();
                setState(() {
                  _fcmToken = fcmtoken;
                });
                prefs.setString('fcmtoken', _fcmToken ?? "");
                await loginStore.onCreateNotificationToken(_fcmToken ?? "");
              }
              BottomToast.showBottomToastOverlay(
                context: context,
                errorMessage: "User Registered Successfully",
                backgroundColor: Theme.of(context).primaryColor,
              );
              Navigator.of(context).pushNamed(Routes.home, arguments: {'trial': widget.trial});
            }
          }
        }
      } else if (store.registerWithEmail2.value?.error != null) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: store.registerWithEmail2.value?.error ?? "Something went wrong!",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    });
  }

  // Future<void> _verifyOtp(LoginStore store, String phone, String otp) async{
  //   await store.onVerifyOtpApiCall(phone,otp).then((value) async {
  //     if (store.loginWithPhone.value?.token != null) {
  //       SharedPreferences prefs = await SharedPreferences.getInstance();
  //       prefs.setString('token', store.loginWithPhone.value?.token??"");
  //       prefs.setBool('isloggedInEmail', true);
  //       String? fcmtoken = await _firebaseMessaging.getToken();
  //       setState(() {
  //         _fcmToken = fcmtoken;
  //       });
  //       prefs.setString('fcmtoken',_fcmToken??"");
  //       debugPrint('fcm $_fcmToken');
  //       await store.onCreateNotificationToken(_fcmToken??"");
  //       BottomToast.showBottomToastOverlay(
  //         context: context,
  //         errorMessage: "Loggedin Successfully!",
  //         backgroundColor: Theme.of(context).primaryColor,
  //       );
  //       Navigator.of(context).pushNamed(Routes.home);
  //     } else {
  //       BottomToast.showBottomToastOverlay(
  //         context: context,
  //         errorMessage: store.loginWithPhone.value?.error ?? "",
  //         backgroundColor: Theme.of(context).colorScheme.error,
  //       );
  //     }
  //   });
  // }
}
