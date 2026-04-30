import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/models/login_with_phone_model.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../../../app/routes.dart';
import '../../../helpers/app_tokens.dart';
import '../../widgets/bottom_toast.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/otp_field.dart';
import 'login_store.dart';

// ---------------------------------------------------------------------
// Public top-level helpers (19+ files import these — signatures preserved)
// ---------------------------------------------------------------------

enum DeviceType { Mobile, Tablet }

bool isTablet(BuildContext context) {
  final double screenWidth = MediaQuery.of(context).size.width;
  final double screenHeight = MediaQuery.of(context).size.height;
  final double aspectRatio = screenWidth / screenHeight;
  return aspectRatio > 0.7 && aspectRatio < 1.3;
}

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

Future<Map<String, String>> getDeviceInfo() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String deviceId = '';
  String deviceName = '';
  String platform = '';

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    deviceId = androidInfo.id;
    deviceName = androidInfo.model ?? 'Unknown';
    platform = 'Android';
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    deviceId = iosInfo.identifierForVendor ?? 'Unknown';
    deviceName = iosInfo.name ?? 'Unknown';
    platform = 'iOS';
  } else if (Platform.isMacOS) {
    final macInfo = await deviceInfo.macOsInfo;
    deviceId = macInfo.systemGUID ?? 'Unknown';
    deviceName = macInfo.model ?? 'Unknown';
    platform = 'macOS';
  } else if (Platform.isWindows) {
    final windowsInfo = await deviceInfo.windowsInfo;
    deviceId = windowsInfo.deviceId ?? 'Unknown';
    deviceName = windowsInfo.computerName ?? 'Unknown';
    platform = 'Windows';
  }
  return {
    'device_id': deviceId,
    'device_name': deviceName,
    'platform': platform,
  };
}

/// Centered Lottie loader — imported by 19 files across the app.
/// Now uses AppTokens.surface so it respects dark-mode.
void showLoadingDialog(BuildContext context) {
  if (!context.mounted) return;
  showDialog(
    barrierColor: Colors.black.withOpacity(0.1),
    context: context,
    barrierDismissible: false,
    builder: (ctx) => WillPopScope(
      onWillPop: () async => false,
      child: Center(
        child: Container(
          clipBehavior: Clip.hardEdge,
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppTokens.surface(ctx),
            borderRadius: AppTokens.radius12,
            boxShadow: AppTokens.shadow2(ctx),
          ),
          padding: const EdgeInsets.all(8),
          child: Lottie.asset('assets/image/loading.json'),
        ),
      ),
    ),
  );
}

/// Session-overflow device picker — shown by both VerifyOtpPhone and
/// VerificationOtpMail when the server reports multiple active sessions.
/// Upgraded to AppTokens but signature + behaviour preserved.
void showDevicePopup(
    BuildContext context, List<LastLoginDeviceModel> devices, String token) {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  showDialog(
    context: context,
    builder: (BuildContext dialogCtx) {
      final loginStore = Provider.of<LoginStore>(dialogCtx, listen: false);
      return AlertDialog(
        backgroundColor: AppTokens.surface(dialogCtx),
        surfaceTintColor: AppTokens.surface(dialogCtx),
        shape: const RoundedRectangleBorder(
          borderRadius: AppTokens.radius16,
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s20,
          AppTokens.s20,
          AppTokens.s16,
        ),
        actionsPadding: const EdgeInsets.only(bottom: AppTokens.s8),
        title: Center(
          child: Text(
            'Logged-in devices',
            style: AppTokens.titleMd(dialogCtx),
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: devices.length,
              separatorBuilder: (_, __) => Divider(
                color: AppTokens.border(dialogCtx),
                thickness: 1,
                height: AppTokens.s20,
              ),
              itemBuilder: (BuildContext itemCtx, int index) {
                final device = devices[index];
                final formattedDate =
                    DateFormat('dd-MM-yyyy HH:mm').format(device.lastLogin!);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.deviceName ?? "Unknown",
                            style: AppTokens.titleSm(itemCtx),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last login: $formattedDate',
                            style: AppTokens.caption(itemCtx).copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    ElevatedButton(
                      onPressed: loginStore.isRemoveLoading
                          ? null
                          : () async {
                              final platformInfo = await getDeviceInfo();
                              showLoadingDialog(itemCtx);
                              await loginStore
                                  .deleteDeviceApiCall(
                                device.deviceId!,
                                token,
                                platformInfo['device_id']!,
                                platformInfo['device_name']!,
                                platformInfo['platform']!,
                              )
                                  .then((value) async {
                                if (loginStore.deleteDevice.value["status"] ==
                                    true) {
                                  Navigator.pop(itemCtx);
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  prefs.setString('token', token);
                                  prefs.setBool('isloggedInEmail', true);

                                  if (!Platform.isWindows &&
                                      !Platform.isMacOS) {
                                    final fcmtoken =
                                        await firebaseMessaging.getToken();
                                    prefs.setString(
                                        'fcmtoken', fcmtoken ?? "");
                                    await loginStore.onCreateNotificationToken(
                                        fcmtoken ?? "");
                                  }

                                  Socket? socket;
                                  socket = io('http://api.sushrutalgs.in:5001',
                                      <String, dynamic>{
                                        'transports': ['websocket'],
                                        'autoConnect': true,
                                      });
                                  socket.on('connect', (_) {});
                                  socket.on('disconnect', (_) {});

                                  // ignore: use_build_context_synchronously
                                  BottomToast.showBottomToastOverlay(
                                    context: itemCtx,
                                    errorMessage: "Logged in successfully!",
                                    backgroundColor:
                                        Theme.of(itemCtx).primaryColor,
                                  );

                                  Navigator.of(itemCtx).pushNamed(
                                    Routes.home,
                                    arguments: {'trial': false},
                                  );
                                } else {
                                  BottomToast.showBottomToastOverlay(
                                    context: itemCtx,
                                    errorMessage: loginStore
                                            .deleteDevice.value["message"] ??
                                        "",
                                    backgroundColor:
                                        Theme.of(itemCtx).colorScheme.error,
                                  );
                                }
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.danger(itemCtx),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppTokens.radius8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        actions: <Widget>[
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Close',
                style: AppTokens.titleSm(dialogCtx).copyWith(
                  color: AppTokens.muted(dialogCtx),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

// ---------------------------------------------------------------------
// VerificationOtpPhone — phone-number OTP verify screen
// ---------------------------------------------------------------------

/// VerificationOtpPhone — phone-number OTP step in the phone-login flow.
///
/// UPGRADE NOTES (ruchir-new-app-upgrade-ui, screen 07):
/// - Same route, same MobX store, same onVerifyOtpPhoneApiCall +
///   showDevicePopup path + Routes.home navigation.
/// - Same FCM permission + onMessage / onMessageOpenedApp plumbing.
/// - Same 60s resend timer via onLoginWithPhoneApiCall.
/// - Same device-info collection (getDeviceInfo) passed to verify.
/// - Drops otp_text_field package dependency in favour of shared
///   [OtpField]; drops ad-hoc TextField+FocusNode plumbing that lived
///   inside _buildCustomOTPInput.
/// - FCM in-app dialog rebuilt on AppTokens.
/// - Top-level helpers (isTablet / getDeviceInfo / getDeviceType /
///   showLoadingDialog / showDevicePopup) preserve their signatures
///   since 30+ other files import them.
class VerificationOtpPhone extends StatefulWidget {
  final String email;
  const VerificationOtpPhone({super.key, required this.email});

  @override
  State<VerificationOtpPhone> createState() => _VerificationOtpPhoneState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => VerificationOtpPhone(
        email: arguments['email'],
      ),
    );
  }
}

class _VerificationOtpPhoneState extends State<VerificationOtpPhone>
    with WidgetsBindingObserver {
  // ------------------------------------------------------------------
  // State (preserved)
  // ------------------------------------------------------------------
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _firebaseMessaging
        .requestPermission(
      alert: true,
      sound: true,
      provisional: false,
      badge: true,
    )
        .then((settings) {
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (!mounted) return;
          setState(() {});
          _handleMessage(message);
        });
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleMessage(message);
        });
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
      }
    });
  }

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

  // ------------------------------------------------------------------
  // FCM in-app dialog (AppTokens rewrite)
  // ------------------------------------------------------------------
  Future<void> _handleMessage(RemoteMessage message) async {
    final notification = message.notification;
    final imageUrl = notification?.android?.imageUrl ??
        notification?.apple?.imageUrl ??
        notification?.web?.image;
    if (notification == null) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.surface(ctx),
        surfaceTintColor: AppTokens.surface(ctx),
        shape: const RoundedRectangleBorder(
          borderRadius: AppTokens.radius20,
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s24,
          AppTokens.s20,
          AppTokens.s20,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              notification.title?.toUpperCase() ?? '',
              style: AppTokens.overline(ctx).copyWith(
                color: AppTokens.accent(ctx),
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.s16),
                child: ClipRRect(
                  borderRadius: AppTokens.radius12,
                  child: SizedBox(
                    height: 143,
                    width: double.infinity,
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  ),
                ),
              ),
            Text(
              notification.body ?? '',
              style: AppTokens.body(ctx),
            ),
            const SizedBox(height: AppTokens.s20),
            CustomButton(
              onPressed: () => Navigator.of(ctx).pop(),
              buttonText: "Ok",
              height: 46,
              bgColor: AppTokens.accent(ctx),
              textColor: Colors.white,
              radius: AppTokens.r12,
              transparent: true,
              fontSize: 15,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // no-op
  }

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final loginStore = Provider.of<LoginStore>(context, listen: false);

    final deviceType = getDeviceType(context);
    final typeStr = deviceType == DeviceType.Tablet ? 'Tablet' : 'Mobile';
    if (Platform.isIOS) {
      loggedInPlatform = "ios$typeStr";
    } else if (Platform.isAndroid) {
      loggedInPlatform = "android$typeStr";
    }

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppTokens.s24,
                AppTokens.s16,
                AppTokens.s24,
                isKeyboardOpen
                    ? MediaQuery.of(context).viewInsets.bottom
                    : AppTokens.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackBubble(onTap: () => Navigator.pop(context)),
                  const SizedBox(height: AppTokens.s24),
                  _buildHeader(context),
                  const SizedBox(height: AppTokens.s32),
                  Center(
                    child: OtpField(
                      length: 4,
                      cellWidth: 62,
                      cellHeight: 70,
                      onChanged: (value) {
                        setState(() {
                          otp = value;
                          isCompleted = value.length == 4;
                        });
                      },
                      onCompleted: (value) {
                        setState(() {
                          otp = value;
                          isCompleted = true;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: AppTokens.s24),
                  _ResendRow(
                    timerActive: _timerActive,
                    remainingSeconds: _remainingSeconds,
                    onResend: () {
                      _startTimer();
                      _resendWithWtOtp(loginStore, widget.email);
                    },
                  ),
                  const Spacer(),
                  Observer(
                    builder: (_) {
                      return CustomButton(
                        onPressed: isCompleted
                            ? () async {
                                final platformInfo = await getDeviceInfo();
                                if (!mounted) return;
                                if (otp.isEmpty) {
                                  BottomToast.showBottomToastOverlay(
                                    context: context,
                                    errorMessage: "Enter OTP",
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                  );
                                  return;
                                }
                                _verifyOtpPhone(loginStore, widget.email,
                                    otp, platformInfo);
                              }
                            : null,
                        buttonText: "Verify Code",
                        height: 54,
                        bgColor: isCompleted
                            ? AppTokens.accent(context)
                            : AppTokens.surface3(context),
                        textColor: isCompleted
                            ? Colors.white
                            : AppTokens.muted(context),
                        radius: AppTokens.r12,
                        transparent: true,
                        fontSize: 16,
                        child: loginStore.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final phone = widget.email;
    // Show last 3 digits of phone — legacy behaviour preserved.
    String tail = phone;
    if (phone.length >= 3) {
      tail = phone.substring(phone.length - 3);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTokens.accentSoft(context),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.sms_outlined,
            color: AppTokens.accent(context),
            size: 24,
          ),
        ),
        const SizedBox(width: AppTokens.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Check your SMS",
                style: AppTokens.titleLg(context),
              ),
              const SizedBox(height: 4),
              Text(
                "We sent a 4-digit code to",
                style: AppTokens.body(context),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "+91 ***** **$tail",
                    style: AppTokens.titleSm(context).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: AppTokens.accent(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Timer (preserved)
  // ------------------------------------------------------------------
  void _startTimer() {
    setState(() {
      _timerActive = true;
      _remainingSeconds = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
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
    final seconds = _remainingSeconds % 60;
    return seconds.toString().padLeft(2, '0');
  }

  // ------------------------------------------------------------------
  // Resend (preserved — re-triggers onLoginWithPhoneApiCall)
  // ------------------------------------------------------------------
  Future<void> _resendWithWtOtp(LoginStore store, String email) async {
    await store.onLoginWithPhoneApiCall(email).then((value) {
      if (!mounted) return;
      if (store.errorMessageOtp.value?.message != null) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: "OTP sent successfully.",
          backgroundColor: Theme.of(context).primaryColor,
        );
      } else if (store.errorMessageOtp.value?.error != null) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage:
              store.errorMessageOtp.value?.error ?? "Something went wrong!",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    });
  }

  // ------------------------------------------------------------------
  // Verify (preserved — device-info + token + FCM + socket + home)
  // ------------------------------------------------------------------
  Future<void> _verifyOtpPhone(LoginStore store, String email, String otp,
      Map<String, dynamic> loggedInPlatform) async {
    await store
        .onVerifyOtpPhoneApiCall(
      email,
      otp,
      loggedInPlatform['device_id'],
      loggedInPlatform['device_name'],
      isTablet(context) ? "tab" : loggedInPlatform['platform'],
    )
        .then((value) async {
      if (!mounted) return;

      if (store.loginWithPhone2.value?.token != null &&
          store.loginWithPhone2.value!.lastLoginDevices.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', store.loginWithPhone2.value?.token ?? "");
        prefs.setBool('isloggedInEmail', true);
        if (!Platform.isWindows && !Platform.isMacOS) {
          final fcmtoken = await _firebaseMessaging.getToken();
          if (mounted) {
            setState(() {
              _fcmToken = fcmtoken;
            });
          }
          prefs.setString('fcmtoken', _fcmToken ?? "");
          await store.onCreateNotificationToken(_fcmToken ?? "");
        }
        connectSocketIO();
        if (!mounted) return;
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: "Logged in successfully!",
          backgroundColor: Theme.of(context).primaryColor,
        );
        Navigator.of(context)
            .pushNamed(Routes.home, arguments: {'trial': false});
      } else if (store.loginWithPhone2.value?.message != null) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: store.loginWithPhone2.value?.message ?? "",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      } else if (store.loginWithPhone2.value?.token != null &&
          store.loginWithPhone2.value!.lastLoginDevices.isNotEmpty &&
          store.loginWithPhone2.value?.message == null) {
        showDevicePopup(
          context,
          store.loginWithPhone2.value!.lastLoginDevices,
          store.loginWithPhone2.value!.token!,
        );
      }
    });
  }

  void connectSocketIO() {
    socket = io('http://api.sushrutalgs.in:5001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket?.on('connect', (_) {
      // connected
    });

    socket?.on('disconnect', (_) {
      // disconnected
    });
  }
}

// ---------------------------------------------------------------------
// Local widgets (same pattern as screens 04 / 05 / 06)
// ---------------------------------------------------------------------

class _BackBubble extends StatelessWidget {
  const _BackBubble({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTokens.surface2(context),
          shape: BoxShape.circle,
          border: Border.all(color: AppTokens.border(context)),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: AppTokens.ink(context),
        ),
      ),
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.timerActive,
    required this.remainingSeconds,
    required this.onResend,
  });

  final bool timerActive;
  final int remainingSeconds;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Haven't got the code? ",
          style: AppTokens.body(context),
        ),
        if (!timerActive)
          InkWell(
            onTap: onResend,
            child: Text(
              "Resend code",
              style: AppTokens.titleSm(context).copyWith(
                color: AppTokens.accent(context),
                decoration: TextDecoration.underline,
                decorationColor: AppTokens.accent(context),
              ),
            ),
          )
        else
          Text(
            "Resend in ${remainingSeconds.toString().padLeft(2, '0')}s",
            style: AppTokens.titleSm(context).copyWith(
              color: AppTokens.muted(context),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }
}
