import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import 'custom_delete_bottom_sheet.dart';
import '../widgets/no_access_bottom_sheet.dart';
import '../widgets/no_internet_connection.dart';
import '../../models/get_all_my_custom_test_model.dart';
import '../subscriptionplans/store/subscription_store.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/modules/widgets/no_access_alert_dialog.dart';
import 'package:shusruta_lms/modules/customtests/store/custom_test_store.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/bookmark_exam_screen.dart';

// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import, unnecessary_import
import 'dart:ui';
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/widgets.dart';
// ignore: unused_import
import 'package:flutter_svg/svg.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import 'custom_bottom_pratice_sheet.dart';
// ignore: unused_import
import 'custom_user_test_bottom_sheet.dart';
// ignore: unused_import
import '../widgets/bottom_practice_sheet.dart';

/// CustomTestLists — catalogue of every custom module the learner has
/// created. Public surface preserved exactly:
///   • const `CustomTestLists({super.key})`
///   • static `Route<dynamic> route(RouteSettings)` returning
///     [CupertinoPageRoute]
///   • `initState` still dispatches `_getSubscribedPlan()` +
///     `CustomTestCategoryStore.onCustomTestListApiCall(context)`
///   • Empty subscription path still surfaces [NoAccessAlertDialog] on
///     desktop / [NoAccessBottomSheet] on mobile
///   • Tap on a module pushes [BookmarkExamScreen] with
///     `isCustom: true, isAll: false, type: "Custom"`
///   • Trash tap still launches [CustomTestDeleteBottomSheet]
///   • "Create New Module" still routes to [Routes.customTestSelectCategory]
class CustomTestLists extends StatefulWidget {
  const CustomTestLists({super.key});

  @override
  State<CustomTestLists> createState() => _CustomTestListsState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    // final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => const CustomTestLists(),
    );
  }
}

class _CustomTestListsState extends State<CustomTestLists> {
  @override
  void initState() {
    super.initState();
    _getSubscribedPlan();
    final store =
        Provider.of<CustomTestCategoryStore>(context, listen: false);
    store.onCustomTestListApiCall(context);
  }

  Future<void> _getSubscribedPlan() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetSubscribedUserPlan();
    if (!mounted) return;
    if (store.subscribedPlan.isEmpty) {
      if (Platform.isWindows || Platform.isMacOS) {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              backgroundColor: AppTokens.surface(ctx),
              surfaceTintColor: AppTokens.surface(ctx),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppTokens.r28),
              ),
              actionsPadding: EdgeInsets.zero,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 100),
              actions: const [
                NoAccessAlertDialog(),
              ],
            );
          },
        );
      } else {
        // ignore: use_build_context_synchronously
        showModalBottomSheet<void>(
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTokens.r28),
            ),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          context: context,
          builder: (BuildContext context) {
            return const NoAccessBottomSheet();
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Platform.isWindows || Platform.isMacOS;
    final store = Provider.of<CustomTestCategoryStore>(context);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Observer(builder: (context) {
        if (store.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTokens.accent(context),
            ),
          );
        }
        if (store.customtestlist.value?.isSubscribe == false) {
          return _UpgradeRequiredView(
            onTap: () => Navigator.of(context).pushNamed(
              Routes.newSubscription,
              arguments: {'showBackButton': true},
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: Observer(
                builder: (_) {
                  if (store.customtestlist.value?.data?.isEmpty ?? false) {
                    return const _EmptyStateView();
                  }
                  return store.isConnected
                      ? isDesktop
                          ? CustomDynamicHeightGridView(
                              crossAxisCount: 3,
                              mainAxisSpacing: AppTokens.s12,
                              itemCount: store.customtestlist.value?.data
                                      ?.length ??
                                  0,
                              builder: (BuildContext context, int index) {
                                return _buildItem(
                                    context,
                                    store.customtestlist.value?.data?[
                                        index]);
                              },
                            )
                          : ListView.builder(
                              itemCount: store
                                  .customtestlist.value?.data?.length,
                              shrinkWrap: true,
                              padding: const EdgeInsets.only(
                                top: AppTokens.s12,
                                bottom: AppTokens.s8,
                              ),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder:
                                  (BuildContext context, int index) {
                                return _buildItem(
                                    context,
                                    store.customtestlist.value?.data?[
                                        index]);
                              },
                            )
                      : const NoInternetScreen();
                },
              ),
            ),
            _CreateModuleCta(
              onTap: () {
                Navigator.of(context)
                    .pushNamed(Routes.customTestSelectCategory);
              },
            ),
          ],
        );
      }),
    );
  }

  Widget _buildItem(BuildContext context, Data? customTestData) {
    final Data? customTest = customTestData;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s8,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          onTap: () {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => BookmarkExamScreen(
                    isCustom: true,
                    isAll: false,
                    id: customTest!.sId ?? "",
                    time: customTest.timeDuration ?? "",
                    name: customTest.testName ?? "",
                    question:
                        customTest.numberOfQuestions.toString().toString(),
                    type: "Custom",
                  ),
                ));
          },
          child: Container(
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              border: Border.all(color: AppTokens.border(context)),
              borderRadius: BorderRadius.circular(AppTokens.r16),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: AppTokens.accentSoft(context),
                          borderRadius:
                              BorderRadius.circular(AppTokens.r12),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: AppTokens.accent(context),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppTokens.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customTest?.testName?.trim() ?? "",
                              style: AppTokens.titleSm(context).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 13,
                                  color: AppTokens.accent(context),
                                ),
                                const SizedBox(width: AppTokens.s4),
                                Text(
                                  "${customTest?.numberOfQuestions ?? 0} Questions",
                                  style: AppTokens.caption(context)
                                      .copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTokens.accent(context),
                                  ),
                                ),
                              ],
                            ),
                            if ((customTest?.description?.trim() ?? '')
                                .isNotEmpty) ...[
                              const SizedBox(height: AppTokens.s4),
                              Text(
                                "${customTest?.description?.trim()}",
                                style: AppTokens.caption(context)
                                    .copyWith(
                                  color: AppTokens.ink2(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                Material(
                  color: AppTokens.dangerSoft(context),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      showModalBottomSheet<void>(
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppTokens.r28),
                          ),
                        ),
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        context: context,
                        builder: (BuildContext context) {
                          return CustomTestDeleteBottomSheet(context,
                              customTestId: customTest?.sId ?? '');
                        },
                      );
                    },
                    child: SizedBox(
                      height: 36,
                      width: 36,
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppTokens.danger(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                borderRadius: BorderRadius.circular(AppTokens.r28),
              ),
              child: Icon(
                Icons.auto_awesome_mosaic_rounded,
                color: AppTokens.accent(context),
                size: 40,
              ),
            ),
            const SizedBox(height: AppTokens.s20),
            Text(
              "Create Your Custom Module",
              textAlign: TextAlign.center,
              style: AppTokens.titleMd(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              "You haven't created any custom modules yet. Start by selecting and combining tests to build modules that match your study plan.",
              textAlign: TextAlign.center,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink2(context),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              "Get Started Now",
              textAlign: TextAlign.center,
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.accent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeRequiredView extends StatelessWidget {
  const _UpgradeRequiredView({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTokens.warningSoft(context),
                borderRadius: BorderRadius.circular(AppTokens.r28),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                color: AppTokens.warning(context),
                size: 36,
              ),
            ),
            const SizedBox(height: AppTokens.s20),
            Text(
              "Upgrade to unlock custom modules",
              textAlign: TextAlign.center,
              style: AppTokens.titleMd(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              "Custom modules let you mix and match any subject, chapter or topic. Upgrade your plan to get access.",
              textAlign: TextAlign.center,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink2(context),
              ),
            ),
            const SizedBox(height: AppTokens.s20),
            SizedBox(
              width: 240,
              height: 48,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppTokens.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTokens.r12),
                  ),
                ),
                child: Text(
                  "View Plans",
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

class _CreateModuleCta extends StatelessWidget {
  const _CreateModuleCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s16,
          AppTokens.s8,
          AppTokens.s16,
          AppTokens.s12,
        ),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r16),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: AppTokens.brand.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTokens.r16),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: AppTokens.s8),
                    Text(
                      'Create New Module',
                      style: AppTokens.body(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
