// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/models/report_list_model.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/widgets/no_internet_connection.dart';

/// Report list — flat list of "Solution" entries across category /
/// subcategory / topic dimensions. Tapping an entry pushes
/// `Routes.selectExamReportList` with `{id, title, type}` where `type`
/// is one of 'topic' / 'subcategory' / 'category' chosen by the first
/// non-null id on the model (topicId > subcategoryId > categoryId).
///
/// Preserved public contract:
///   • Constructor `ReportListScreen({Key? key, this.fromHome})`
///   • Static `route(RouteSettings)` reads `fromhome` (lowercase).
///   • `store.onReportAllApiCall()` fired in initState.
///   • WillPopScope → `Routes.dashboard`
///   • When `fromHome == true`, leading back arrow also pushes
///     `Routes.dashboard`; otherwise leading is hidden.
///   • Search by lowercase contains across composed
///     "category[ | subcategory][ | topic]" label.
///   • Empty state copy: "We're sorry, there's no content available
///     right now. Please check back later or explore other sections for
///     more educational resources." + "Start a Test" CTA pushing
///     `Routes.testCategory`.
///   • `store.isConnected == false` → `NoInternetScreen`.
class ReportListScreen extends StatefulWidget {
  final bool? fromHome;
  const ReportListScreen({Key? key, this.fromHome}) : super(key: key);

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => ReportListScreen(fromHome: arguments['fromhome']),
    );
  }
}

class _ReportListScreenState extends State<ReportListScreen> {
  String query = '';

  @override
  void initState() {
    super.initState();
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    store.onReportAllApiCall();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
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
              if (widget.fromHome == true)
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
              if (widget.fromHome == true)
                const SizedBox(width: AppTokens.s12),
              Text(
                "Solutions",
                style: AppTokens.titleSm(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink(context),
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
                AppTokens.s16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  border: Border.all(color: AppTokens.border(context)),
                ),
                child: TextField(
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
                  if (store.reportsAll.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.s24,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 56,
                              color: AppTokens.muted(context),
                            ),
                            const SizedBox(height: AppTokens.s16),
                            Text(
                              "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
                              style: AppTokens.body(context).copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppTokens.ink(context),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppTokens.s24),
                            InkWell(
                              onTap: () {
                                Navigator.of(context)
                                    .pushNamed(Routes.testCategory);
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
                                      AppTokens.brand2
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
                    itemCount: store.reportsAll.length,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s20,
                      0,
                      AppTokens.s20,
                      AppTokens.s20,
                    ),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTokens.s12),
                    itemBuilder: (BuildContext context, int index) {
                      ReportListModel? reportList = store.reportsAll[index];
                      String originalDate = reportList?.createdAt ?? "";
                      DateTime parsedDate = DateTime.parse(originalDate);
                      final formatter = DateFormat('dd/MMMM/yyyy');
                      String formattedDate = formatter.format(parsedDate);

                      final categoryName = reportList?.categoryName ?? "";
                      final subcategoryName =
                          reportList?.subcategoryName ?? "";
                      final topicName = reportList?.topicName ?? "";

                      String displayText = categoryName;
                      if (subcategoryName.isNotEmpty &&
                          topicName.isNotEmpty) {
                        displayText +=
                            " | $subcategoryName | $topicName";
                      } else if (subcategoryName.isNotEmpty) {
                        displayText += " | $subcategoryName";
                      } else if (topicName.isNotEmpty) {
                        displayText += " | $topicName";
                      }
                      if (query.isNotEmpty &&
                          (!displayText
                              .toLowerCase()
                              .contains(query.toLowerCase()))) {
                        return const SizedBox.shrink();
                      }
                      return InkWell(
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                        onTap: () {
                          final id = reportList?.topicId != null
                              ? reportList?.topicId ?? ""
                              : reportList?.subcategoryId != null
                                  ? reportList?.subcategoryId ?? ""
                                  : reportList?.categoryId ?? "";
                          final type = reportList?.topicId != null
                              ? "topic"
                              : reportList?.subcategoryId != null
                                  ? "subcategory"
                                  : "category";
                          final title = reportList?.topicId != null
                              ? reportList?.topicName ?? ""
                              : reportList?.subcategoryId != null
                                  ? reportList?.subcategoryName ?? ""
                                  : reportList?.categoryName ?? "";
                          Navigator.of(context).pushNamed(
                            Routes.selectExamReportList,
                            arguments: {
                              'id': id,
                              'title': title,
                              'type': type
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayText,
                                style: AppTokens.body(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTokens.ink(context),
                                ),
                              ),
                              const SizedBox(height: AppTokens.s8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: AppTokens.muted(context),
                                  ),
                                  const SizedBox(width: AppTokens.s4),
                                  Text(
                                    formattedDate,
                                    style:
                                        AppTokens.caption(context).copyWith(
                                      color: AppTokens.muted(context),
                                    ),
                                  ),
                                ],
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
