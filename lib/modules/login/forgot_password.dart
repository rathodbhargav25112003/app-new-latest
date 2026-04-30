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

class ForgotPasswordScreen extends StatefulWidget {
  final String email;
  const ForgotPasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => ForgotPasswordScreen(
        email: arguments['email'],
      ),
    );
  }
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with WidgetsBindingObserver {
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  final _passKey = GlobalKey<FormFieldState<String>>();
  final _confirmPassKey = GlobalKey<FormFieldState<String>>();
  bool isKeyboardOpen = false;
  bool _isPasswordValid = false;
  bool _showPass = false;
  bool _showConfirmPass = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    passController.dispose();
    confirmPassController.dispose();
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
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: AppTokens.radius16,
                  ),
                  child: Icon(Icons.lock_reset_rounded,
                      size: 28, color: AppTokens.accent(context)),
                ),
                const SizedBox(height: AppTokens.s24),
                Text(
                  "Create a new password",
                  style: AppTokens.displayMd(context),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  "Use 6+ characters with a mix of letters, numbers, and a symbol.",
                  style: AppTokens.bodyLg(context).copyWith(
                    color: AppTokens.muted(context),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppTokens.s32),
                TextFormField(
                  key: _passKey,
                  obscureText: !_showPass,
                  controller: passController,
                  keyboardType: TextInputType.visiblePassword,
                  cursorColor: AppTokens.accent(context),
                  style: AppTokens.bodyLg(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      setState(() => _isPasswordValid = false);
                      return 'Please enter a password.';
                    } else if (value.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    setState(() => _isPasswordValid = true);
                    return null;
                  },
                  decoration: AppTokens.inputDecoration(
                    context,
                    hint: 'New password',
                    label: 'New password',
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 6),
                      child: Icon(Icons.lock_outline_rounded,
                          size: 18, color: AppTokens.muted(context)),
                    ),
                    suffix: IconButton(
                      icon: Icon(
                        _showPass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppTokens.muted(context),
                      ),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                TextFormField(
                  key: _confirmPassKey,
                  obscureText: !_showConfirmPass,
                  controller: confirmPassController,
                  keyboardType: TextInputType.visiblePassword,
                  cursorColor: AppTokens.accent(context),
                  style: AppTokens.bodyLg(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      setState(() => _isPasswordValid = false);
                      return 'Please confirm your password.';
                    } else if (value.length < 6) {
                      return 'Password must be at least 6 characters.';
                    } else if (value != passController.text) {
                      return "Passwords don't match.";
                    }
                    setState(() => _isPasswordValid = true);
                    return null;
                  },
                  decoration: AppTokens.inputDecoration(
                    context,
                    hint: 'Confirm new password',
                    label: 'Confirm password',
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 6),
                      child: Icon(Icons.lock_outline_rounded,
                          size: 18, color: AppTokens.muted(context)),
                    ),
                    suffix: IconButton(
                      icon: Icon(
                        _showConfirmPass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppTokens.muted(context),
                      ),
                      onPressed: () => setState(
                          () => _showConfirmPass = !_showConfirmPass),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.s24),
                Observer(
                  builder: (_) {
                    return CustomButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        final pOk = _passKey.currentState?.validate() ?? false;
                        final cOk = _confirmPassKey.currentState?.validate() ?? false;
                        if (pOk && cOk) {
                          _createPassword(store, passController.text,
                              confirmPassController.text, widget.email);
                        }
                      },
                      buttonText: "Save password",
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

  Future<void> _createPassword(LoginStore store, String password, String confirmPass, String email) async{
      await store.onMailForgotPasswod(password,confirmPass,email).then((value) {

        if(store.forgotPassWithMail.value?.message!=null){
          BottomToast.showBottomToastOverlay(
            context: context,
            errorMessage: store.forgotPassWithMail.value?.message??"Something went wrong!",
            backgroundColor: Theme.of(context).primaryColor,
          );
          // Navigator.of(context).pushNamed(Routes.loginWithPass);
          Navigator.of(context).pushNamed(Routes.login);
        }else if(store.forgotPassWithMail.value?.err!=null){
          BottomToast.showBottomToastOverlay(
            context: context,
            errorMessage: store.forgotPassWithMail.value?.err?.message??"Something went wrong!",
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      });
  }
}
