import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:otp_text_field/style.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:otp_text_field/otp_field_style.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/api_service/api_service.dart';
import 'package:shusruta_lms/modules/widgets/bottom_toast.dart';
import 'package:shusruta_lms/modules/widgets/custom_button.dart';
import 'package:shusruta_lms/modules/login/store/login_store.dart';
import 'package:shusruta_lms/modules/login/store/verify_otp_phone.dart';
import 'package:shusruta_lms/modules/widgets/email_phone_change_success.dart';
import 'package:shusruta_lms/services/otp_autofill_service.dart';

class VerifyCodeBottomSheet extends StatefulWidget {
  final String contactInfo; // Phone or email
  final String info; // Phone or email
  final bool isPhone; // true for phone, false for email
  final VoidCallback onVerify;

  const VerifyCodeBottomSheet({
    super.key,
    required this.contactInfo,
    required this.isPhone,
    required this.info,
    required this.onVerify,
  });

  @override
  State<VerifyCodeBottomSheet> createState() => _VerifyCodeBottomSheetState();
}

class _VerifyCodeBottomSheetState extends State<VerifyCodeBottomSheet> {
  TextEditingController _controllers = TextEditingController();
  int _resendSeconds = 60;
  Timer? _timer;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  // Wave-3.2: Android SMS autofill stream → fills _controllers + auto
  // verifies. iOS gets the OTP via QuickType natively.
  final OtpAutofillService _autofill = OtpAutofillService();
  StreamSubscription<String>? _autofillSub;

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    _autofill.start();
    _autofillSub = _autofill.codes.listen((code) {
      if (!mounted) return;
      final digits = code.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 4) return;
      _controllers.text = digits.substring(0, 4);
      _verifyCode();
    });
  }

  // dispose() — see below; consolidated with the existing version
  // that handles _controllers.dispose() too. Keep this method body
  // empty so the duplicate doesn't shadow the canonical dispose.

  void _startResendTimer() {
    _timer?.cancel();
    _resendSeconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendSeconds--;
        });
      }
    });
  }

  void _resendCode() async {
    LoginStore store = Provider.of<LoginStore>(context, listen: false);
    if (_resendSeconds == 0) {
      showLoadingDialog(context);
      if (widget.isPhone) {
        await store.onLoginWithPhoneApiCall(widget.info).then((value) async {
          Navigator.pop(context);
          _startResendTimer();
          if (store.loginWithPhone.value?.message != null) {
            BottomToast.showBottomToastOverlay(
                context: context,
                errorMessage: store.loginWithPhone.value?.message ?? "",
                backgroundColor: AppColors.primaryColor);
          } else {
            BottomToast.showBottomToastOverlay(
                context: context,
                errorMessage: store.loginWithPhone.value?.error ??
                    "Something went wrong!",
                backgroundColor: AppColors.redAlert);
          }
        });
      } else {
        await store.onSendOtpForgotEmail(widget.info).then((value) {
          Navigator.pop(context);
          if (store.errorMessageOtp.value?.message != null) {
            BottomToast.showBottomToastOverlay(
              context: context,
              errorMessage: "OTP Sent Successfully!",
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
    }
  }

  Future<void> _verifyCode() async {
    if (_controllers.text.length != 4) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: 'Please enter all 4 digits',
        backgroundColor: AppColors.redAlert,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.verifyUpdateUser(
          widget.info, widget.isPhone ? 'phone' : 'email', _controllers.text);

      if (response['status'] == true) {
        final store = Provider.of<LoginStore>(context, listen: false);
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhoneEmailChangeSuccessScreen(
              text: widget.isPhone
                  ? 'Your mobile number\nchanged successfully'
                  : 'Your email\nchanged successfully',
            ),
          ),
        );
      } else {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage:
              response['error'] ?? response['message'] ?? 'Verification failed',
          backgroundColor: AppColors.redAlert,
        );
      }
    } catch (e) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: 'An error occurred during verification',
        backgroundColor: AppColors.redAlert,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autofillSub?.cancel();
    _autofill.stop();
    _controllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hintText = widget.isPhone
        ? "We have sent a code ${widget.contactInfo}"
        : "We have sent a code to ${widget.contactInfo}";

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: ThemeManager.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isPhone ? 'Verify your old no.' : 'Verify your email',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: ThemeManager.black),
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(color: Colors.grey),
                children: [
                  TextSpan(text: "We have sent a code "),
                  TextSpan(
                    text: widget.contactInfo,
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: ThemeManager.black),
                  ),
                ],
              ),
            ),
            const Text(
              "Enter the 4 Digit Code here",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 25),
            OTPTextField(
              length: 4,
              width: MediaQuery.of(context).size.width,
              fieldWidth: 56,
              style: TextStyle(fontSize: 19, color: ThemeManager.textColor3),
              otpFieldStyle: OtpFieldStyle(
                focusBorderColor: ThemeManager.primaryColor,
                enabledBorderColor: ThemeManager.grey2,
              ),
              keyboardType: TextInputType.number,
              textFieldAlignment: MainAxisAlignment.spaceAround,
              fieldStyle: FieldStyle.box,
              hasError: false,
              onCompleted: (pin) {
                _controllers.text = pin;
                if (pin.length == 4) {
                  _verifyCode();
                }
              },
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            Text.rich(
              TextSpan(
                text: "Haven't got the code yet? ",
                style: const TextStyle(color: Colors.grey),
                children: [
                  WidgetSpan(
                    child: InkWell(
                      onTap: _resendSeconds == 0 ? _resendCode : null,
                      child: Text(
                        _resendSeconds == 0
                            ? "Resend code"
                            : "Resend code in ${_resendSeconds}s",
                        style: TextStyle(
                          color: ThemeManager.blueFinal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            CustomButton(
              onPressed: _isLoading ? null : _verifyCode,
              buttonText: _isLoading ? "Verifying..." : "Verify",
              height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
              textAlign: TextAlign.center,
              radius: Dimensions.RADIUS_DEFAULT,
              transparent: true,
              bgColor: Theme.of(context).primaryColor,
              fontSize: Dimensions.fontSizeDefault,
            ),
          ],
        ),
      ),
    );
  }
}
