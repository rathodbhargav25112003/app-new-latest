import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/login/store/login_store.dart';
import '../../app/routes.dart';
import '../../helpers/colors.dart';
import '../../helpers/app_tokens.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';

class ForgotEmailScreen extends StatefulWidget {
  const ForgotEmailScreen({Key? key}) : super(key: key);

  @override
  State<ForgotEmailScreen> createState() => _ForgotEmailScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const ForgotEmailScreen(),
    );
  }
}

class _ForgotEmailScreenState extends State<ForgotEmailScreen> with WidgetsBindingObserver {
  final TextEditingController emailController = TextEditingController();
  final _emailKey = GlobalKey<FormFieldState<String>>();
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  bool isKeyboardOpen = false;
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    emailController.dispose();
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
    final store = Provider.of<LoginStore>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      // Soft transparent app bar — Apple-style "back is enough"
      // chrome. No title; the headline below carries the page intent.
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
        child: Padding(
          padding: EdgeInsets.only(
            left: AppTokens.s24,
            top: AppTokens.s8,
            right: AppTokens.s24,
            bottom: isKeyboardOpen
                ? MediaQuery.of(context).viewInsets.bottom
                : AppTokens.s32,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTokens.s24),
                // Apple-style hero: short headline + supporting body.
                Text(
                  "Reset your password",
                  style: AppTokens.displayMd(context),
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  "Enter the email you signed up with. We'll send a verification code.",
                  style: AppTokens.bodyLg(context).copyWith(
                    color: AppTokens.muted(context),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppTokens.s32),
                // Polished input — soft fill, rounded 12r, accent
                // border on focus, hairline border at rest.
                TextFormField(
                  key: _emailKey,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  cursorColor: AppTokens.accent(context),
                  style: AppTokens.bodyLg(context),
                  onChanged: (value) {
                    setState(() {
                      _isEmailValid = _emailRegex.hasMatch(value);
                    });
                  },
                  onFieldSubmitted: (_) {
                    final ok = _emailKey.currentState?.validate() ?? false;
                    if (ok) _sentOtpToMail(store, emailController.text);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      setState(() => _isEmailValid = false);
                      return 'Please enter an email address.';
                    } else if (!_emailRegex.hasMatch(value)) {
                      setState(() => _isEmailValid = false);
                      return 'Please enter a valid email address.';
                    }
                    setState(() => _isEmailValid = true);
                    return null;
                  },
                  decoration: AppTokens.inputDecoration(
                    context,
                    hint: 'name@example.com',
                    label: 'Email address',
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 6),
                      child: Icon(Icons.alternate_email_rounded,
                          size: 18, color: AppTokens.muted(context)),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.s24),
                Observer(
                  builder: (_) {
                    return CustomButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        bool? validate = _emailKey.currentState?.validate();
                        if (validate ?? false) {
                          _sentOtpToMail(store, emailController.text);
                        }
                      },
                      buttonText: "Send code",
                      height: 54,
                      bgColor: _isEmailValid
                          ? AppTokens.accent(context)
                          : AppTokens.surface3(context),
                      radius: AppTokens.r16,
                      transparent: true,
                      fontSize: 16,
                      child: store.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white,
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
    );
  }

  Future<void> _sentOtpToMail(LoginStore store, String email) async{
    await store.onSendOtpForgotEmail(email).then((value) {

      if(store.errorMessageOtp.value?.message!=null){
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: "OTP Sent Successfully!",
          backgroundColor: Theme.of(context).primaryColor,
        );
        Navigator.of(context).pushNamed(Routes.verifyOtpMail,
            arguments: {'email': emailController.text});
      }
      else if(store.errorMessageOtp.value?.error!=null){
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: store.errorMessageOtp.value?.error??"Something went wrong!",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    });
  }
}
