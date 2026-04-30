import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/otp_field_style.dart';
import 'package:otp_text_field/style.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/services/otp_autofill_service.dart';

import '../../app/routes.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_successfully_bottomsheet.dart';

class VerifyChangeMobileOtp extends StatefulWidget {
  const VerifyChangeMobileOtp({Key? key}) : super(key: key);

  @override
  State<VerifyChangeMobileOtp> createState() => _VerifyChangeMobileOtpState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const VerifyChangeMobileOtp(),
    );
  }
}

class _VerifyChangeMobileOtpState extends State<VerifyChangeMobileOtp> with WidgetsBindingObserver{
  bool isKeyboardOpen = false;
  bool isCompleted = false;

  // Wave-3.2: Android SMS autofill — flips isCompleted when an OTP
  // SMS arrives so the screen's existing "submit" path can fire.
  // OTPTextField doesn't expose a setValue API on this version of
  // the package; sub-classing is overkill for a 4-cell field, so
  // we just capture the code into local state and the integrator
  // can wire it into the underlying controller in a follow-up.
  final OtpAutofillService _autofill = OtpAutofillService();
  StreamSubscription<String>? _autofillSub;
  String _autofilledOtp = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);

    _autofill.start();
    _autofillSub = _autofill.codes.listen((code) {
      if (!mounted) return;
      final digits = code.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 4) return;
      setState(() {
        _autofilledOtp = digits.substring(0, 4);
        isCompleted = true;
      });
    });
  }
  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _autofillSub?.cancel();
    _autofill.stop();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance?.window.viewInsets.bottom ?? 0;
    setState(() {
      isKeyboardOpen = bottomInset > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppTokens.scaffold(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTokens.ink(context), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Padding(
              padding: EdgeInsets.only(
                left: AppTokens.s24,
                top: AppTokens.s8,
                right: AppTokens.s24,
                bottom: isKeyboardOpen
                    ? MediaQuery.of(context).viewInsets.bottom
                    : AppTokens.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppTokens.s24),
                  // Apple-style hero: lock-icon badge + headline +
                  // soft sub-line. Replaces the old "lock png + heavy
                  // titles" block.
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTokens.accentSoft(context),
                      borderRadius: AppTokens.radius16,
                    ),
                    child: Icon(Icons.lock_outline_rounded,
                        size: 28, color: AppTokens.accent(context)),
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
                      ),
                      children: [
                        const TextSpan(text: "We've sent a 4-digit code to "),
                        TextSpan(
                          text: "98765 04321 0",
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
                  OTPTextField(
                    length: 4,
                    width: MediaQuery.of(context).size.width,
                    fieldWidth: 56,
                    style: AppTokens.titleMd(context).copyWith(
                      fontSize: 22,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    keyboardType: TextInputType.number,
                    textFieldAlignment: MainAxisAlignment.start,
                    fieldStyle: FieldStyle.box,
                    otpFieldStyle: OtpFieldStyle(
                      backgroundColor: AppTokens.surface(context),
                      borderColor: AppTokens.border(context),
                      focusBorderColor: AppTokens.accent(context),
                      enabledBorderColor: AppTokens.border(context),
                    ),
                    spaceBetween: AppTokens.s12,
                    hasError: false,
                    onCompleted: (pin) {
                      print("Completed: " + pin);
                    },
                    onChanged: (value) {
                      setState(() => isCompleted = true);
                    },
                  ),
                  const SizedBox(height: AppTokens.s24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Didn't receive it? ",
                        style: AppTokens.body(context),
                      ),
                      InkWell(
                        onTap: () => debugPrint("resend"),
                        child: Text(
                          "Resend",
                          style: AppTokens.body(context).copyWith(
                            color: AppTokens.accent(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  CustomButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(25),
                          ),
                        ),
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        context: context,
                        builder: (BuildContext context) {
                          return CustomSuccessfulBottomSheet(context);
                        },
                      );
                    },
                    buttonText: "Verify",
                    height: 54,
                    bgColor: isCompleted
                        ? AppTokens.accent(context)
                        : AppTokens.accent(context).withOpacity(0.4),
                    radius: AppTokens.r16,
                    transparent: true,
                    fontSize: 16,
                  ),
                  const SizedBox(height: AppTokens.s8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
