import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../helpers/app_tokens.dart';
import '../login/keyboard.dart';
import 'bottom_toast.dart';
import 'custom_verification_bottomsheet.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/modules/login/store/login_store.dart';
import 'package:shusruta_lms/modules/new_exam_component/widget/loading_box.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
// ignore: unused_import
import 'package:shusruta_lms/modules/videolectures/store/video_category_store.dart';
// ignore: unused_import
import 'custom_button.dart';
// ignore: unused_import
import '../../app/routes.dart';

/// CustomChangeMobileBottomSheet — contact-change bottom sheet used from the
/// profile flow. Public surface preserved exactly:
///   • non-const constructor `(BuildContext context, this.title, {super.key})`
///     with `bool title` as positional arg (true ⇒ phone, false ⇒ email)
///   • internal state fields `_mobileKey`, `_emailKey`, `phoneController`,
///     `emailController`, `_isMobileValid`, `_isEmailValid` retained
///   • Submit action chain: showLoadingDialog → LoginStore API → 2× pop →
///     BottomToast + VerifyCodeBottomSheet
// ignore: must_be_immutable
class CustomChangeMobileBottomSheet extends StatefulWidget {
  bool title;
  CustomChangeMobileBottomSheet(BuildContext context, this.title, {super.key});

  @override
  State<CustomChangeMobileBottomSheet> createState() =>
      _CustomChangeMobileBottomSheetState();
}

class _CustomChangeMobileBottomSheetState
    extends State<CustomChangeMobileBottomSheet> {
  // ignore: unused_field
  String? selectedValue;

  // ignore: unused_field
  final _mobileKey = GlobalKey<FormFieldState<String>>();
  // ignore: unused_field
  final _emailKey = GlobalKey<FormFieldState<String>>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  // ignore: unused_field
  bool _isMobileValid = false;
  // ignore: unused_field
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
  }

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    final LoginStore store = Provider.of<LoginStore>(context, listen: false);

    if (widget.title == true) {
      final String phone = phoneController.text.trim();
      if (phone.isEmpty) {
        _isMobileValid = false;
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: 'Please enter mobile number.',
          backgroundColor: AppColors.redAlert,
        );
        return;
      }
      _isMobileValid = true;
      showLoadingDialog(context);
      await store.onLoginWithPhoneApiCall(phone).then((value) async {
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pop(context);
        if (store.loginWithPhone.value?.message != null) {
          BottomToast.showBottomToastOverlay(
            // ignore: use_build_context_synchronously
            context: context,
            errorMessage: store.loginWithPhone.value?.message ?? '',
            backgroundColor: AppColors.primaryColor,
          );
          showModalBottomSheet(
            // ignore: use_build_context_synchronously
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => VerifyCodeBottomSheet(
              info: phone,
              contactInfo:
                  '+91 ******${phone.substring(phone.length - 4)}',
              isPhone: true,
              onVerify: () {},
            ),
          );
        } else {
          BottomToast.showBottomToastOverlay(
            // ignore: use_build_context_synchronously
            context: context,
            errorMessage:
                store.loginWithPhone.value?.error ?? 'Something went wrong!',
            backgroundColor: AppColors.redAlert,
          );
        }
      });
    } else {
      final String email = emailController.text.trim();
      if (email.isEmpty) {
        _isEmailValid = false;
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: 'Please enter email address',
          backgroundColor: AppColors.redAlert,
        );
        return;
      }
      _isEmailValid = true;
      showLoadingDialog(context);
      await store.onSendOtpForgotEmail(email).then((value) {
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pop(context);
        if (store.errorMessageOtp.value?.message != null) {
          BottomToast.showBottomToastOverlay(
            // ignore: use_build_context_synchronously
            context: context,
            errorMessage: 'OTP Sent Successfully!',
            // ignore: use_build_context_synchronously
            backgroundColor: Theme.of(context).primaryColor,
          );
          showModalBottomSheet(
            // ignore: use_build_context_synchronously
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => VerifyCodeBottomSheet(
              info: email,
              contactInfo:
                  '${email.substring(0, 3)}*****${email.substring(email.length - 3)}',
              isPhone: false,
              onVerify: () {},
            ),
          );
        } else if (store.errorMessageOtp.value?.error != null) {
          BottomToast.showBottomToastOverlay(
            // ignore: use_build_context_synchronously
            context: context,
            errorMessage:
                store.errorMessageOtp.value?.error ?? 'Something went wrong!',
            // ignore: use_build_context_synchronously
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPhone = widget.title == true;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        constraints: _isDesktop
            ? const BoxConstraints(maxWidth: 520)
            : null,
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          borderRadius: _isDesktop
              ? BorderRadius.circular(AppTokens.r20)
              : const BorderRadius.vertical(
                  top: Radius.circular(AppTokens.r20),
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s16,
            AppTokens.s20,
            AppTokens.s20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!_isDesktop) _SheetGrabber(),
                const SizedBox(height: AppTokens.s12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: BorderRadius.circular(AppTokens.r16),
                  ),
                  child: Icon(
                    isPhone
                        ? Icons.phone_iphone_rounded
                        : Icons.alternate_email_rounded,
                    color: AppTokens.accent(context),
                    size: 24,
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                Text(
                  isPhone ? 'Enter Mobile no.' : 'Enter Email Id',
                  style: AppTokens.titleLg(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTokens.s4),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s16),
                  child: Text(
                    isPhone
                        ? 'We will send you an OTP on your entered mobile number.'
                        : 'We will send you an OTP on your entered email Id.',
                    textAlign: TextAlign.center,
                    style: AppTokens.body(context).copyWith(
                      color: AppTokens.ink2(context),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.s20),
                if (isPhone)
                  TextFormField(
                    key: _mobileKey,
                    cursorColor: AppTokens.accent(context),
                    style: AppTokens.body(context),
                    controller: phoneController,
                    readOnly: true,
                    enableInteractiveSelection: false,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      showCustomKeyboardSheet(
                        context,
                        KeyboardType.number,
                        phoneController,
                      );
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() => _isMobileValid = false);
                        return 'Please enter mobile number.';
                      }
                      setState(() => _isMobileValid = true);
                      return null;
                    },
                    decoration: AppTokens.inputDecoration(
                      context,
                      hint: 'Mobile number',
                    ).copyWith(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+91',
                              style: AppTokens.body(context)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: AppTokens.s8),
                            Container(
                              width: 1,
                              height: 20,
                              color: AppTokens.border(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  TextFormField(
                    key: _emailKey,
                    cursorColor: AppTokens.accent(context),
                    style: AppTokens.body(context),
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() => _isEmailValid = false);
                        return 'Please enter email address';
                      }
                      setState(() => _isEmailValid = true);
                      return null;
                    },
                    decoration: AppTokens.inputDecoration(
                      context,
                      hint: 'Email Id',
                    ),
                  ),
                const SizedBox(height: AppTokens.s20),
                _GradientCta(
                  label: 'Submit',
                  icon: Icons.arrow_forward_rounded,
                  onTap: _onSubmit,
                ),
                const SizedBox(height: AppTokens.s12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetGrabber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: AppTokens.border(context),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: AppTokens.brand.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTokens.body(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Icon(icon, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
