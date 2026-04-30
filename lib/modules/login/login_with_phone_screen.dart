import 'dart:io';
import 'login_screen.dart';
import '../../app/routes.dart';
import '../../helpers/colors.dart';
import '../../helpers/styles.dart';
import '../../helpers/app_tokens.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_svg/svg.dart';
import '../widgets/bottom_toast.dart';
import 'package:flutter/material.dart';
import '../../helpers/dimensions.dart';
import '../widgets/custom_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shusruta_lms/modules/login/verify_otp_mail.dart';
import 'package:shusruta_lms/modules/login/store/login_store.dart';
import 'package:shusruta_lms/modules/signup/store/signup_store.dart';
// Custom keyboard import - commented out as we're using system default keyboard
// Uncomment this if you want to re-enable the custom keyboard
// import 'keyboard.dart';

class LoginWithPhoneScreen extends StatefulWidget {
  const LoginWithPhoneScreen({super.key});

  @override
  State<LoginWithPhoneScreen> createState() => _LoginWithPhoneScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const LoginWithPhoneScreen(),
    );
  }
}

class _LoginWithPhoneScreenState extends State<LoginWithPhoneScreen>
    with WidgetsBindingObserver {
  final TextEditingController phoneController = TextEditingController();
  final _phoneKey = GlobalKey<FormFieldState<String>>();
  final _phoneRegex = RegExp(r'^(\+[0-9])?[-\s\./0-9]*$');
  bool isKeyboardOpen = false;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  Socket? socket;
  String loggedInPlatform = '';
  final pageController = PageController(
    initialPage: 0,
  );
  int currentPage = 0;
  final List<String> pageLabels = ["Phone No.", "Email"];
  @override
  void initState() {
    super.initState();
    testApi();
    settingsData();
    WidgetsBinding.instance.addObserver(this);
    _firebaseMessaging
        .requestPermission(alert: true, sound: true, badge: true)
        .then((settings) {
      print(
          'Firebase Messaging Authorization Status: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('Firebase Messaging onMessage: ${message.notification?.body}');
          _handleMessage(message);
        });
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print('Firebase Messaging onMessageOpenedApp: $message');
          // setState(() {
          //   _message = message.notification?.body ?? '';
          // });
          _handleMessage(message);
        });
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
      }
    });
  }

  Future<void> settingsData() async {
    final store = Provider.of<LoginStore>(context, listen: false);
    await store.onGetSettingsData();
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
          shape: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none),
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
                  padding:
                      const EdgeInsets.only(top: Dimensions.PADDING_SIZE_LARGE),
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
                      border: Border.all(
                          color: ThemeManager.buttonBorder, width: 0.89),
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

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Firebase Messaging onBackgroundMessage: $message');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    phoneController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom ?? 0;
    setState(() {
      isKeyboardOpen = bottomInset > 0;
    });
  }

  var extra = {
    "method": "get",
    "params": {"cid": "MDOZRHRAXLODQ5I9TIF540PNM3MBQQSB"}
  };
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

  // @override
  // Widget build(BuildContext context) {
  //   final store = Provider.of<LoginStore>(context, listen: false);
  //   final deviceType = getDeviceType(context);
  //   String type = deviceType == DeviceType.Tablet?'Tablet':'Mobile';
  //   if(Platform.isIOS){
  //     loggedInPlatform = "ios$type";
  //   }else if(Platform.isAndroid){
  //     loggedInPlatform =  "android$type";
  //   }
  //   return Scaffold(
  //     backgroundColor: ThemeManager.white,
  //     resizeToAvoidBottomInset: false,
  //
  //     body: SizedBox(
  //       child: Padding(
  //         padding: EdgeInsets.only(
  //           left: Dimensions.PADDING_SIZE_LARGE,
  //           top: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
  //           right: Dimensions.PADDING_SIZE_LARGE,
  //           bottom: isKeyboardOpen
  //               ? MediaQuery.of(context).viewInsets.bottom
  //               : Dimensions.PADDING_SIZE_LARGE * 2,
  //         ),
  //         child: SizedBox(
  //           height: MediaQuery.of(context).size.height,
  //           width: MediaQuery.of(context).size.width,
  //           child: Column(
  //
  //             // crossAxisAlignment: CrossAxisAlignment.end,
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.start,
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   // Image.asset("assets/image/hand_alert.png"),
  //                   // const SizedBox(
  //                   //   width: Dimensions.PADDING_SIZE_LARGE,
  //                   // ),
  //                   Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         "Hello!!",
  //                         style: interSemiBold.copyWith(
  //                           fontSize: Dimensions.fontSizeExtraLarge,
  //                           color: ThemeManager.black
  //                         ),
  //                       ),
  //                       Text(
  //                         "Welcome back!",
  //                         style: interSemiBold.copyWith(
  //                           fontSize: Dimensions.fontSizeExtraLarge,
  //                           color: ThemeManager.black
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(
  //                 height: Dimensions.PADDING_SIZE_LARGE * 2,
  //               ),
  //               Container(
  //                 constraints: const BoxConstraints(
  //                   minHeight: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
  //                 ),
  //                 child: TextFormField(
  //                   key: _phoneKey,
  //                   onChanged: (value) {
  //                     setState(() {
  //                       _isPhoneValid = _phoneRegex.hasMatch(value);
  //                     });
  //                   },
  //                   validator: (value) {
  //                     if (value == null || value.isEmpty) {
  //                       setState(() {
  //                         _isPhoneValid = false;
  //                       });
  //                       return 'Please enter an mobile number.';
  //                     } else if (!_phoneRegex.hasMatch(value)) {
  //                       setState(() {
  //                         _isPhoneValid = false;
  //                       });
  //                       return 'Please enter a valid mobile number';
  //                     }
  //
  //                     setState(() {
  //                       _isPhoneValid = true;
  //                     });
  //                     return null;
  //                   },
  //                   cursorColor: Theme.of(context).disabledColor,
  //                   style: interRegular.copyWith(
  //                     fontSize: Dimensions.fontSizeDefault,
  //                   ),
  //                   controller: phoneController,
  //                   keyboardType: TextInputType.phone,
  //                   decoration: InputDecoration(
  //                     fillColor: Theme.of(context).disabledColor,
  //                     enabledBorder: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(
  //                         Dimensions.RADIUS_SMALL,
  //                       ),
  //                       borderSide: BorderSide(
  //                         color: Theme.of(context).disabledColor,
  //                       ),
  //                     ),
  //                     labelText: 'Enter Whatsapp mobile no.',
  //                     hintText: 'Enter Whatsapp mobile no.',
  //                     hintStyle: interRegular.copyWith(
  //                       fontSize: Dimensions.fontSizeSmall,
  //                       color: Colors.black,
  //                     ),
  //                     labelStyle: interRegular.copyWith(
  //                       fontSize: Dimensions.fontSizeSmall,
  //                       color: Colors.black,
  //                     ),
  //                     counterText: '',
  //                     focusedBorder: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(
  //                         Dimensions.RADIUS_SMALL,
  //                       ),
  //                       borderSide: BorderSide(
  //                         color: Theme.of(context).disabledColor,
  //                       ),
  //                     ),
  //                     border: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(
  //                         Dimensions.RADIUS_SMALL,
  //                       ),
  //                       borderSide: BorderSide(
  //                         color: Theme.of(context).disabledColor,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //               // SizedBox(
  //               //   height: MediaQuery.of(context).size.height*0.49,
  //               //   width:  MediaQuery.of(context).size.width,
  //               //   child: Center(child: SvgPicture.asset("assets/image/loginPerson.svg",fit: BoxFit.cover,)),
  //               // ),
  //
  //               const SizedBox(
  //                 height: Dimensions.PADDING_SIZE_LARGE,
  //               ),
  //               // const Spacer(),
  //
  //               CustomButton(
  //                 onPressed: () {
  //                   FocusScope.of(context).unfocus();
  //                   bool? validate = _phoneKey.currentState?.validate();
  //                   if(validate!) {
  //                     _login(store, phoneController.text);
  //                   }
  //                 },
  //                 buttonText: "Send OTP",
  //                 height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
  //                 bgColor: _isPhoneValid
  //                     ? Theme.of(context).primaryColor
  //                     : Theme.of(context).disabledColor,
  //                 radius: Dimensions.RADIUS_SMALL,
  //                 transparent: true,
  //                 fontSize: Dimensions.fontSizeDefault,
  //                 child: store.isLoading ? const CircularProgressIndicator(color: Colors.white,) : null,
  //               ),
  //               // Observer(
  //               //   builder: (_) {
  //               //     return LoginCustomButton(
  //               //       onPressed: () {
  //               //         FocusScope.of(context).unfocus();
  //               //         bool? validate = _phoneKey.currentState?.validate();
  //               //         if(validate!) {
  //               //           _login(store, phoneController.text);
  //               //         }
  //               //         },
  //               //       buttonText: "Send OTP",
  //               //       height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
  //               //
  //               //       bgColor: AppColors.primaryColor,
  //               //       radius: Dimensions.PADDING_SIZE_LARGE,
  //               //       transparent: true,
  //               //       fontSize: Dimensions.fontSizeDefault,
  //               //       child: store.isLoading ? const CircularProgressIndicator(color: Colors.white,) : null,
  //               //     );
  //               //   },
  //               // ),
  //
  //               /// Divider
  //               // Row(
  //               //   children: <Widget>[
  //               //     Expanded(
  //               //       child: Container(
  //               //         margin: const EdgeInsets.only(right: 20.0),
  //               //         child: Divider(
  //               //           color: Theme.of(context).disabledColor,
  //               //           height: 25,
  //               //           thickness: 1,
  //               //         ),
  //               //       ),
  //               //     ),
  //               //     const Text("OR"),
  //               //     Expanded(
  //               //       child: Container(
  //               //         margin: const EdgeInsets.only(left: 20.0),
  //               //         child: Divider(
  //               //           color: Theme.of(context).disabledColor,
  //               //           height: 25,
  //               //           thickness: 1,
  //               //         ),
  //               //       ),
  //               //     ),
  //               //   ],
  //               // ),
  //               const SizedBox(
  //                 height: Dimensions.PADDING_SIZE_LARGE,
  //               ),
  //               // SizedBox(
  //               //   width: MediaQuery.of(context).size.height,
  //               //   height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
  //               //   child: ElevatedButton(
  //               //     onPressed: () {
  //               //       // _loginWithGoogle(context,store);
  //               //       FocusScope.of(context).unfocus();
  //               //       Navigator.of(context).pushNamed(Routes.loginWithPass);
  //               //     },
  //               //     style: ElevatedButton.styleFrom(
  //               //       backgroundColor: Theme.of(context).cardColor,
  //               //       elevation: 0,
  //               //       side: BorderSide(
  //               //         color: Theme.of(context).disabledColor,
  //               //       ),
  //               //     ),
  //               //     child: Row(
  //               //       mainAxisAlignment: MainAxisAlignment.center,
  //               //       children: [
  //               //         Icon(Icons.password,color: Theme.of(context).primaryColor),
  //               //         const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT,),
  //               //         Text(
  //               //           "Login with Email",
  //               //           style: interBold.copyWith(
  //               //             color: Colors.black,
  //               //           ),
  //               //         ),
  //               //       ],
  //               //     ),
  //               //   ),
  //               // ),
  //               // const SizedBox(
  //               //   height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
  //               // ),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Text(
  //                     "Don't have an account? ",
  //                     style: interRegular.copyWith(
  //                       fontSize: Dimensions.fontSizeSmall,
  //                        color: Theme.of(context).hintColor
  //                     ),
  //                   ),
  //                   InkWell(
  //                     onTap: () {
  //                       Navigator.of(context).pushNamed(Routes.register);
  //                     },
  //                     child: Text(
  //                       "Register",
  //                       style: interRegular.copyWith(
  //                         fontSize: Dimensions.fontSizeSmall,
  //                         color: Theme.of(context).primaryColor,
  //                         decoration: TextDecoration.underline,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(
  //                 height: Dimensions.PADDING_SIZE_LARGE,
  //               ),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Text(
  //                     "Login to get OTP via ",
  //                     style: interRegular.copyWith(
  //                         fontSize: Dimensions.fontSizeSmall,
  //                         color: Theme.of(context).hintColor
  //                     ),
  //                   ),
  //                   InkWell(
  //                     onTap: () {
  //                       Navigator.of(context).pushNamed(Routes.loginWithPass);
  //                     },
  //                     child: Text(
  //                       "Email",
  //                       style: interRegular.copyWith(
  //                         fontSize: Dimensions.fontSizeSmall,
  //                         color: Theme.of(context).primaryColor,
  //                         decoration: TextDecoration.underline,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(
  //                 height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
  //               ),
  //
  //               store.isLoadingSettings?
  //               const Center(child: SizedBox()):
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Column(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text("Contact Us / Support",
  //                         style: interBold.copyWith(
  //                           fontSize: Dimensions.fontSizeDefault,
  //                           color: Theme.of(context).primaryColor,
  //                         ),
  //                       ),
  //                       const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.start,
  //                         crossAxisAlignment: CrossAxisAlignment.center,
  //                         children: [
  //                           Icon(Icons.email, color: Theme.of(context).primaryColor),
  //                           const SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
  //                           Text(
  //                             "${store.settingsData.value?.email} ",
  //                             style: interRegular.copyWith(
  //                               fontSize: Dimensions.fontSizeSmall,
  //                               color: ThemeManager.black,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.start,
  //                         crossAxisAlignment: CrossAxisAlignment.center,
  //                         children: [
  //                           Icon(Icons.phone, color: Theme.of(context).primaryColor),
  //                           const SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
  //                           Text(
  //                             "+91${store.settingsData.value?.phone} ",
  //                             style: interRegular.copyWith(
  //                               fontSize: Dimensions.fontSizeSmall,
  //                               color: ThemeManager.black,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               )
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    final store = Provider.of<LoginStore>(context, listen: false);
    final deviceType = getDeviceType(context);
    String type = deviceType == DeviceType.Tablet ? 'Tablet' : 'Mobile';
    if (Platform.isIOS) {
      loggedInPlatform = "ios$type";
    } else if (Platform.isAndroid) {
      loggedInPlatform = "android$type";
    }
    return Scaffold(
      backgroundColor: ThemeManager.white,
      resizeToAvoidBottomInset: false,
      body: KeyboardActions(
        config: KeyboardActionsConfig(
          keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
          actions: [
            KeyboardActionsItem(
              focusNode: FocusNode(),
              displayArrows: false,
              displayDoneButton: true,
              onTapAction: () {
                FocusScope.of(context).unfocus();
              },
            ),
          ],
        ),
        child: Center(
        child: Container(
          constraints: BoxConstraints(
              maxWidth: 600, maxHeight: MediaQuery.of(context).size.height * 1),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: Dimensions.PADDING_SIZE_LARGE * 1.2,
                top: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.4,
                right: Dimensions.PADDING_SIZE_LARGE * 1.2,
                bottom: isKeyboardOpen
                    ? MediaQuery.of(context).viewInsets.bottom * 0.2
                    : Dimensions.PADDING_SIZE_LARGE * 2,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    Image.asset("assets/image/app_logo2.png"),
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_LARGE * 2.4,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome back",
                            style: AppTokens.displayMd(context).copyWith(
                              color: AppTokens.ink(context),
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Sign in to continue your prep.",
                            style: AppTokens.body(context).copyWith(
                              color: AppTokens.muted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_LARGE,
                    ),
                    // Apple-style segmented control — soft surface
                    // background, single rounded inner pill that slides
                    // between Phone / Email. Primary affordance reads
                    // as a tab control, not a pair of buttons.
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTokens.surface2(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(2, (index) {
                          final isCurrentPage = currentPage == index;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  currentPage = index;
                                  pageController.animateToPage(index,
                                      duration: const Duration(milliseconds: 280),
                                      curve: Curves.easeOutCubic);
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                alignment: Alignment.center,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isCurrentPage
                                      ? AppTokens.surface(context)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: isCurrentPage
                                      ? AppTokens.shadow1(context)
                                      : null,
                                ),
                                child: Text(
                                  pageLabels[index],
                                  style: AppTokens.titleSm(context).copyWith(
                                    color: isCurrentPage
                                        ? AppTokens.ink(context)
                                        : AppTokens.muted(context),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_LARGE,
                    ),
                    Flexible(
                      child: PageView(
                        physics: const NeverScrollableScrollPhysics(),
                        controller: pageController,
                        onPageChanged: (index) {
                          setState(() {
                            currentPage = index;
                          });
                        },
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Phone number",
                                style: AppTokens.titleSm(context),
                              ),
                              const SizedBox(height: AppTokens.s8),
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12)),
                                    border: Border(
                                      top: BorderSide(
                                          color: ThemeManager.grey1,
                                          width: 0.85),
                                      left: BorderSide(
                                          color: ThemeManager.grey1,
                                          width: 0.85),
                                      right: BorderSide(
                                          color: ThemeManager.grey1,
                                          width: 0.85),
                                    )),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              Dimensions.PADDING_SIZE_SMALL *
                                                  1.2,
                                          vertical:
                                              Dimensions.PADDING_SIZE_SMALL *
                                                  1.4),
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                              "assets/image/india.svg"),
                                          const SizedBox(
                                            width:
                                                Dimensions.PADDING_SIZE_SMALL *
                                                    1.1,
                                          ),
                                          Text(
                                            "India",
                                            style: interMedium.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                                color: ThemeManager.textColor4),
                                          ),
                                          const Spacer(),
                                          SvgPicture.asset(
                                              "assets/image/arrow_icon.svg"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                constraints: const BoxConstraints(
                                  minHeight:
                                      Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                                ),
                                child: TextFormField(
                                  key: _phoneKey,
                                  controller: phoneController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a mobile number.';
                                    } else if (!_phoneRegex.hasMatch(value)) {
                                      return 'Please enter a valid mobile number';
                                    }
                                    return null;
                                  },
                                  // Custom keyboard code - commented out to use system default keyboard
                                  // To re-enable custom keyboard, also uncomment the import 'keyboard.dart' above
                                  // readOnly: true,
                                  // enableInteractiveSelection: false,
                                  // onTap: () {
                                  //   FocusScope.of(context).unfocus();
                                  //   showCustomKeyboardSheet(context, KeyboardType.number, phoneController);
                                  // },
                                  keyboardType: TextInputType.phone,
                                  cursorColor: Theme.of(context).disabledColor,
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    prefixIcon: IntrinsicHeight(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: Dimensions
                                                    .PADDING_SIZE_SMALL),
                                            child: Text(
                                              "+91",
                                              style: interMedium.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeDefault,
                                                  color: ThemeManager.black),
                                            ),
                                          ),
                                          VerticalDivider(
                                            color: ThemeManager.grey1,
                                          )
                                        ],
                                      ),
                                    ),
                                    fillColor: Theme.of(context).disabledColor,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      borderSide:
                                          BorderSide(color: ThemeManager.grey1),
                                    ),
                                    hintText: 'Enter Mobile no.',
                                    hintStyle: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: ThemeManager.black,
                                    ),
                                    counterText: '',
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      borderSide:
                                          BorderSide(color: ThemeManager.grey1),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      borderSide:
                                          BorderSide(color: ThemeManager.grey1),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: Dimensions.PADDING_SIZE_SMALL,
                              ),
                              Text(
                                "We shall be sending you a Code by SMS for verification",
                                style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: ThemeManager.black),
                              ),
                              const SizedBox(
                                height: Dimensions.PADDING_SIZE_DEFAULT * 2.4,
                              ),

                              // SizedBox(
                              //   height: MediaQuery.of(context).size.height*0.49,
                              //   width:  MediaQuery.of(context).size.width,
                              //   child: Center(child: SvgPicture.asset("assets/image/loginPerson.svg",fit: BoxFit.cover,)),
                              // ),
                              // const SizedBox(
                              //   height: Dimensions.PADDING_SIZE_LARGE,
                              // ),

                              CustomButton(
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  bool? validate =
                                      _phoneKey.currentState?.validate();
                                  if (validate!) {
                                    _login(store, phoneController.text);
                                  }
                                },
                                buttonText: "Continue",
                                height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                                bgColor: ThemeManager.primaryColor,
                                radius: Dimensions.RADIUS_DEFAULT,
                                transparent: true,
                                fontSize: Dimensions.fontSizeDefault,
                                child: store.isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              // Observer(
                              //   builder: (_) {
                              //     return LoginCustomButton(
                              //       onPressed: () {
                              //         FocusScope.of(context).unfocus();
                              //         bool? validate = _phoneKey.currentState?.validate();
                              //         if(validate!) {
                              //           _login(store, phoneController.text);
                              //         }
                              //         },
                              //       buttonText: "Send OTP",
                              //       height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                              //
                              //       bgColor: AppColors.primaryColor,
                              //       radius: Dimensions.PADDING_SIZE_LARGE,
                              //       transparent: true,
                              //       fontSize: Dimensions.fontSizeDefault,
                              //       child: store.isLoading ? const CircularProgressIndicator(color: Colors.white,) : null,
                              //     );
                              //   },
                              // ),
                              /// Divider
                              // Row(
                              //   children: <Widget>[
                              //     Expanded(
                              //       child: Container(
                              //         margin: const EdgeInsets.only(right: 20.0),
                              //         child: Divider(
                              //           color: Theme.of(context).disabledColor,
                              //           height: 25,
                              //           thickness: 1,
                              //         ),
                              //       ),
                              //     ),
                              //     const Text("OR"),
                              //     Expanded(
                              //       child: Container(
                              //         margin: const EdgeInsets.only(left: 20.0),
                              //         child: Divider(
                              //           color: Theme.of(context).disabledColor,
                              //           height: 25,
                              //           thickness: 1,
                              //         ),
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              const SizedBox(
                                height: Dimensions.PADDING_SIZE_DEFAULT * 2,
                              ),
                              // SizedBox(
                              //   width: MediaQuery.of(context).size.height,
                              //   height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                              //   child: ElevatedButton(
                              //     onPressed: () {
                              //       // _loginWithGoogle(context,store);
                              //       FocusScope.of(context).unfocus();
                              //       Navigator.of(context).pushNamed(Routes.loginWithPass);
                              //     },
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: Theme.of(context).cardColor,
                              //       elevation: 0,
                              //       side: BorderSide(
                              //         color: Theme.of(context).disabledColor,
                              //       ),
                              //     ),
                              //     child: Row(
                              //       mainAxisAlignment: MainAxisAlignment.center,
                              //       children: [
                              //         Icon(Icons.password,color: Theme.of(context).primaryColor),
                              //         const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT,),
                              //         Text(
                              //           "Login with Email",
                              //           style: interBold.copyWith(
                              //             color: Colors.black,
                              //           ),
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),
                              // const SizedBox(
                              //   height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                              // ),
                              // Show register option only on mobile devices (Android and iOS)
                              if (Platform.isAndroid || Platform.isIOS) ...[
                              Align(
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account?",
                                      style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: ThemeManager.black),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context)
                                            .pushNamed(Routes.register);
                                      },
                                      child: Text(
                                        "Register",
                                        style: interBold.copyWith(
                                          fontSize:
                                              Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w600,
                                          color: ThemeManager.textColor2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ],
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.center,
                              //   children: [
                              //     Text(
                              //       "Login to get OTP via ",
                              //       style: interRegular.copyWith(
                              //           fontSize: Dimensions.fontSizeSmall,
                              //           color: Theme.of(context).hintColor
                              //       ),
                              //     ),
                              //     InkWell(
                              //       onTap: () {
                              //         Navigator.of(context).pushNamed(Routes.loginWithPass);
                              //       },
                              //       child: Text(
                              //         "Email",
                              //         style: interRegular.copyWith(
                              //           fontSize: Dimensions.fontSizeSmall,
                              //           color: Theme.of(context).primaryColor,
                              //           decoration: TextDecoration.underline,
                              //         ),
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              // const SizedBox(
                              //   height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                              // ),
                              // if (!Platform.isWindows && !Platform.isMacOS) ...[
                              //   const Spacer(),
                              // ],
                              if (Platform.isWindows || Platform.isMacOS) ...[
                                const SizedBox(
                                  height: 15,
                                ),
                              ],
                              if (Platform.isAndroid || Platform.isIOS) ...[
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.09,
                                ),
                              ],
                              store.isLoadingSettings
                                  ? const Center(child: SizedBox())
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Observer(builder: (context) {
                                          return Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Contact Us / Support",
                                                style: interBold.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeDefault,
                                                  color:
                                                      ThemeManager.textColor2,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor:
                                                      ThemeManager.textColor2,
                                                ),
                                              ),
                                              const SizedBox(
                                                  height: Dimensions
                                                      .PADDING_SIZE_DEFAULT),
                                              Text(
                                                "${store.settingsData.value?.email} ",
                                                style: interRegular.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                  color: ThemeManager.black,
                                                ),
                                              ),
                                              const SizedBox(
                                                  height: Dimensions
                                                      .PADDING_SIZE_EXTRA_SMALL),
                                              Text(
                                                "+91${store.settingsData.value?.phone} ",
                                                style: interRegular.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                  color: ThemeManager.black,
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                      ],
                                    )
                            ],
                          ),
                          const LoginScreen(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }


  Future<void> _login(LoginStore store, String phone) async {
    try {
      await store.onLoginWithPhoneApiCall(phone).then((value) async {
        // Check for ERROR_REGISTER_User case
        if (store.loginWithPhone.value?.err?.code == 'ERROR_REGISTER_User') {
          _showRestoreUserDialog(phone);
        } else if (store.loginWithPhone.value?.message != null) {
          BottomToast.showBottomToastOverlay(
              context: context,
              errorMessage: store.loginWithPhone.value?.message ?? "",
              backgroundColor: AppColors.primaryColor);
          Navigator.of(context)
              .pushNamed(Routes.verifyOtpPhone, arguments: {'email': phone});
        } else {
          // Surface API error to the user + tag it for Crashlytics
          // so we can see operator-specific OTP delivery failures
          // in the Firebase dashboard.
          final apiErr = store.loginWithPhone.value?.error
              ?? "Something went wrong!";
          BottomToast.showBottomToastOverlay(
              context: context,
              errorMessage: apiErr,
              backgroundColor: AppColors.redAlert);
          // Wave-3.2 #14: tag with the failing step so Crashlytics
          // surfaces a histogram of WHERE login fails (per operator,
          // per phone-prefix, etc.) rather than just lumping
          // everything under the same exception type.
          try {
            FirebaseCrashlytics.instance.setCustomKey('login_step', 'send_otp');
            FirebaseCrashlytics.instance.setCustomKey('login_phone_prefix',
                phone.length >= 4 ? phone.substring(0, 4) : phone);
            await FirebaseCrashlytics.instance.recordError(
              apiErr,
              StackTrace.current,
              reason: 'Login OTP send failed (non-throw error path)',
              fatal: false,
            );
          } catch (_) { /* never let telemetry break the UX */ }
        }
      });
    } catch (e, st) {
      // Network / hard exception — record + show a generic error.
      try {
        FirebaseCrashlytics.instance.setCustomKey('login_step', 'send_otp_throw');
        await FirebaseCrashlytics.instance.recordError(
          e, st,
          reason: 'Login OTP send threw',
          fatal: false,
        );
      } catch (_) {}
      if (mounted) {
        BottomToast.showBottomToastOverlay(
            context: context,
            errorMessage: 'Could not send OTP. Please retry.',
            backgroundColor: AppColors.redAlert);
      }
    }
  }

  void _showRestoreUserDialog(String phone) {
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
                await _handleRestoreUser(phone);
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

  Future<void> _handleRestoreUser(String phone) async {
    try {
      final signupStore = SignupStore();
      
      // Try to get email from the error response params - but for login flow we may not have it
      // The API requires email parameter, so we'll pass empty string for now
      String email = '';
      
      if (mounted) {
        final result = await signupStore.onRestoreUser(email, phone);
        
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
            errorMessage: signupStore.errorMessage.isNotEmpty ? signupStore.errorMessage : "Failed to restore user account",
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

Future<void> testApi() async {
  try {
    final response = await http
        .get(Uri.parse('https://jsonplaceholder.typicode.com/todos/1'));

    if (response.statusCode == 200) {
      print('Response data: ${response.body}');
    } else {
      print('Error: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
