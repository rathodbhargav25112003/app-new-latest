// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, library_private_types_in_public_api, use_build_context_synchronously, avoid_print

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/store/new_subscription_store.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/widget/custom_info_card.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/widget/exam_goal_dialog.dart';
import 'package:shusruta_lms/modules/login/store/login_store.dart';
import 'package:shusruta_lms/modules/widgets/subscription_dialog.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';

/// NewSubscription — landing screen of the revamped subscription flow.
/// Presents two primary actions: "Subscribe to App Plans" (opens the
/// [ExamGoalDialog] first) and, platform/IAP permitting, "Purchase
/// Hardcopy Notes".
///
/// Public surface preserved exactly:
///   • class [NewSubscription] + const constructor `{super.key, showBackButton = true}`
///   • static [route] factory that reads `arguments['showBackButton']`
///     and wraps the page in a [MultiProvider] providing [LoginStore]
///   • [_showGoalDialog] behavior + downstream `Routes.newCustomSubscription`
///     arguments `{'categoryId', 'categoryName'}`
///   • Platform-gated block via [SubscriptionDialog] when `isInAPurchases == false`
class NewSubscription extends StatefulWidget {
  final bool showBackButton;

  const NewSubscription({super.key, this.showBackButton = true});

  @override
  State<NewSubscription> createState() => _NewSubscriptionState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>?;
    final bool showBackButton = arguments?['showBackButton'] ?? true;

    return CupertinoPageRoute(
      builder: (_) => MultiProvider(
        providers: [
          Provider<LoginStore>(
            create: (_) => LoginStore(),
          ),
        ],
        child: NewSubscription(showBackButton: showBackButton),
      ),
    );
  }
}

class _NewSubscriptionState extends State<NewSubscription> {
  late LoginStore _loginStore;
  bool _shouldBlock = false;

  @override
  void initState() {
    super.initState();
    _loginStore = Provider.of<LoginStore>(context, listen: false);
    _loadSettingsData();
    Future.microtask(() {
      final settings = _loginStore.settingsData.value;
      if (settings != null &&
          settings.isInAPurchases == false &&
          (Platform.isWindows || Platform.isMacOS)) {
        setState(() => _shouldBlock = true);
        showDialog(
          context: context,
          // barrierDismissible: false,
          builder: (_) => SubscriptionDialog(),
        ).then((_) {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
    });
  }

  Future<void> _loadSettingsData() async {
    await _loginStore.onGetSettingsData();
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldBlock) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTokens.brand, AppTokens.brand2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: (Platform.isWindows || Platform.isMacOS)
                  ? const EdgeInsets.symmetric(
                      vertical: Dimensions.PADDING_SIZE_LARGE * 1.2,
                      horizontal: Dimensions.PADDING_SIZE_LARGE * 1.2)
                  : const EdgeInsets.only(
                      top: Dimensions.PADDING_SIZE_LARGE * 3.5,
                      left: Dimensions.PADDING_SIZE_LARGE * 1,
                      right: Dimensions.PADDING_SIZE_LARGE * 1.2,
                      bottom: Dimensions.PADDING_SIZE_SMALL * 1.3),
              child: Row(
                children: [
                  if (widget.showBackButton) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.18)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                  ],
                  Expanded(
                    child: Center(
                      child: Text(
                        "Subscription",
                        style: AppTokens.titleMd(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (widget.showBackButton) ...[
                    const SizedBox(width: 40 + 12),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(
                    left: Dimensions.PADDING_SIZE_LARGE,
                    right: Dimensions.PADDING_SIZE_LARGE,
                    top: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                decoration: BoxDecoration(
                  color: AppTokens.scaffold(context),
                  borderRadius: (Platform.isWindows || Platform.isMacOS)
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r28),
                          topRight: Radius.circular(AppTokens.r28),
                        ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Your Personalized",
                        style: AppTokens.titleLg(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTokens.ink(context),
                        ),
                      ),
                      Text(
                        "learning journey awaits.",
                        style: AppTokens.titleLg(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTokens.ink(context),
                        ),
                      ),
                      const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
                      Text(
                        "Unlock exclusive benefits and tailored \nsupport to help you reach your full potential.",
                        textAlign: TextAlign.center,
                        style: AppTokens.body(context).copyWith(
                          color: AppTokens.muted(context),
                        ),
                      ),
                      const SizedBox(
                          height: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                      SvgPicture.asset("assets/image/newsubscription.svg"),
                      const SizedBox(
                          height: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                      CustomInfoCard(
                        onTap: () {
                          _showGoalDialog(context);
                        },
                        icon: SvgPicture.asset(
                            "assets/image/premium_subscription_plan.svg",
                            fit: BoxFit.scaleDown),
                        title: "Subscribe to App Plans",
                        subtitle:
                            "Get access to premium app \nfeature.",
                        backgroundColor: AppTokens.successSoft(context),
                        arrowColor: AppTokens.ink(context),
                      ),
                      const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
                      Observer(
                        builder: (context) {
                          final bool isIAPEnabled =
                              _loginStore.settingsData.value?.isInAPurchases ==
                                  true;

                          if (isIAPEnabled &&
                              (Platform.isMacOS || Platform.isIOS)) {
                            return const SizedBox.shrink();
                          } else {
                            return CustomInfoCard(
                              onTap: () {
                                Navigator.of(context)
                                    .pushNamed(Routes.purchaseHardcopy);
                              },
                              icon: SvgPicture.asset(
                                  "assets/image/hardcopy_notes.svg",
                                  fit: BoxFit.scaleDown),
                              title: "Purchase Hardcopy Notes",
                              subtitle:
                                  "Order the hardcopy notes without subscribing to app plans.",
                              backgroundColor:
                                  AppTokens.accentSoft(context),
                              arrowColor: AppTokens.ink(context),
                            );
                          }
                        },
                      ),
                      const SizedBox(
                          height: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showGoalDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => Provider<NewSubscriptionStore>(
        create: (_) => NewSubscriptionStore(),
        child: const ExamGoalDialog(),
      ),
    );

    if (result != null) {
      print(
          "User selected category ID: ${result['id']}, name: ${result['name']}");
      Navigator.of(context).pushNamed(
        Routes.newCustomSubscription,
        arguments: {
          'categoryId': result['id'],
          'categoryName': result['name']
        },
      );
    }
  }
}
