// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/bookmark_category_model.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';
import 'package:shusruta_lms/modules/widgets/no_internet_connection.dart';

/// Mock-exam "Analysis & Solutions" category list.
///
/// Preserved public contract:
///   • Constructor `MasterReportCategoryScreen({super.key, this.fromHome})`
///   • Static `route(RouteSettings)` reads `fromhome` (lowercase key).
///   • `WillPopScope` → `Routes.dashboard`.
///   • Back button always pushes `Routes.dashboard`.
///   • `store.onMasterReportCategoryApiCall(context)` fired in initState.
///   • `SubscriptionStore.onGetSubscribedUserPlan()` fetched in initState.
///   • Lowercase-contains search on `category_name`.
///   • Empty state: "No Analysis & Solutions Found!" + "Start a Test"
///     CTA pushes `Routes.allTestCategory`.
///   • Tap → `Routes.selectMasterExamReportList` with
///     `{id, title, type: 'topic', showPredictive: isNeetss ?? false}`.
///   • `!store.isConnected` → `NoInternetScreen`.
class MasterReportCategoryScreen extends StatefulWidget {
  final bool? fromHome;
  const MasterReportCategoryScreen({super.key, this.fromHome});

  @override
  State<MasterReportCategoryScreen> createState() =>
      _MasterReportCategoryScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) =>
          MasterReportCategoryScreen(fromHome: arguments['fromhome']),
    );
  }
}

class _MasterReportCategoryScreenState
    extends State<MasterReportCategoryScreen> {
  String filterValue = '';
  final FocusNode _focusNode = FocusNode();
  String query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _getSubscribedPlan();
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    store.onMasterReportCategoryApiCall(context);
  }

  Future<void> _getSubscribedPlan() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetSubscribedUserPlan();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed(Routes.dashboard);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: AppTokens.scaffold(context),
          surfaceTintColor: Colors.transparent,
          titleSpacing: AppTokens.s8,
          title: Row(
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).pushNamed(Routes.dashboard);
                },
                borderRadius: BorderRadius.circular(AppTokens.r8),
                child: Container(
                  height: AppTokens.s32,
                  width: AppTokens.s32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.surface2(context),
                    borderRadius: BorderRadius.circular(AppTokens.r8),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: AppTokens.ink(context),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Text(
                  "Mock Exam Analysis & Solutions",
                  style: AppTokens.titleSm(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s8,
                AppTokens.s20,
                AppTokens.s8,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  border: Border.all(color: AppTokens.border(context)),
                ),
                child: TextField(
                  focusNode: _focusNode,
                  cursorColor: AppTokens.accent(context),
                  onChanged: (value) {
                    setState(() {
                      query = value;
                    });
                  },
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink(context),
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppTokens.muted(context),
                    ),
                    hintStyle: AppTokens.body(context).copyWith(
                      color: AppTokens.muted(context),
                    ),
                    hintText: 'Search',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s12,
                      vertical: AppTokens.s12,
                    ),
                  ),
                ),
              ),
            ),
            if (query.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s20,
                  0,
                  AppTokens.s20,
                  AppTokens.s8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Results for \u201C$query\u201D",
                    style: AppTokens.caption(context).copyWith(
                      color: AppTokens.muted(context),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Observer(
                builder: (_) {
                  if (store.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTokens.accent(context),
                      ),
                    );
                  }
                  if (store.bookmarkMasterCategory.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.s24,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assessment_outlined,
                              size: 56,
                              color: AppTokens.muted(context),
                            ),
                            const SizedBox(height: AppTokens.s16),
                            Text(
                              "No Analysis & Solutions Found!",
                              style: AppTokens.body(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTokens.ink(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppTokens.s24),
                            InkWell(
                              onTap: () {
                                Navigator.of(context)
                                    .pushNamed(Routes.allTestCategory);
                              },
                              borderRadius:
                                  BorderRadius.circular(AppTokens.r12),
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTokens.s24,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTokens.brand,
                                      AppTokens.brand2,
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(AppTokens.r12),
                                ),
                                child: Text(
                                  "Start a Test",
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
                  if (!store.isConnected) return const NoInternetScreen();

                  return ListView.separated(
                    itemCount: store.bookmarkMasterCategory.length,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s20,
                      AppTokens.s4,
                      AppTokens.s20,
                      AppTokens.s20,
                    ),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTokens.s12),
                    itemBuilder: (BuildContext context, int index) {
                      BookMarkCategoryModel? bookMarkCat =
                          store.bookmarkMasterCategory[index];
                      if (query.isNotEmpty &&
                          (!bookMarkCat!.category_name!
                              .toLowerCase()
                              .contains(query.toLowerCase()))) {
                        return const SizedBox.shrink();
                      }
                      return InkWell(
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            Routes.selectMasterExamReportList,
                            arguments: {
                              'id': bookMarkCat?.category_id,
                              'title': bookMarkCat?.category_name,
                              'type': "topic",
                              'showPredictive':
                                  bookMarkCat?.isNeetss ?? false,
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppTokens.s16),
                          decoration: BoxDecoration(
                            color: AppTokens.surface(context),
                            borderRadius:
                                BorderRadius.circular(AppTokens.r12),
                            border: Border.all(
                              color: AppTokens.border(context),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 44,
                                width: 44,
                                padding:
                                    const EdgeInsets.all(AppTokens.s8),
                                decoration: BoxDecoration(
                                  color: AppTokens.accentSoft(context),
                                  borderRadius:
                                      BorderRadius.circular(AppTokens.r12),
                                ),
                                child: SvgPicture.asset(
                                  "assets/image/mockExamCategory.svg",
                                  color: AppTokens.accent(context),
                                ),
                              ),
                              const SizedBox(width: AppTokens.s12),
                              Expanded(
                                child: Text(
                                  bookMarkCat?.category_name ?? "",
                                  style: AppTokens.body(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTokens.ink(context),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppTokens.muted(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
