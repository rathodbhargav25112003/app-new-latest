// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/report_by_exam_list_model.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/widgets/no_access_alert_dialog.dart';
import 'package:shusruta_lms/modules/widgets/no_access_bottom_sheet.dart';
import 'package:shusruta_lms/modules/widgets/no_internet_connection.dart';

/// "Choose Test Report" — select which exam's solution report to view.
///
/// Preserved public contract:
///   • Constructor `SelectExamReportList({Key? key, required this.id,
///     required this.type})`
///   • Static `route(RouteSettings)` reads `id` and `type`.
///   • `store.onReportExamByCategoryApiCall(widget.id, widget.type)`
///     in initState.
///   • Lowercase-contains search on `examName`.
///   • Access-gated: `isAccess == true` pushes
///     `Routes.reportSubCategory` with `{id, title}`. Else:
///     `Platform.isWindows` → `AlertDialog(NoAccessAlertDialog)`, else
///     modal bottom sheet `NoAccessBottomSheet`.
///   • Lock badge displayed when `isAccess == false`.
///   • Empty state copy preserved verbatim.
///   • `!store.isConnected` → `NoInternetScreen`.
class SelectExamReportList extends StatefulWidget {
  final String id;
  final String type;
  const SelectExamReportList({Key? key, required this.id, required this.type})
      : super(key: key);

  @override
  State<SelectExamReportList> createState() => _SelectExamReportListState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => SelectExamReportList(
        id: arguments['id'],
        type: arguments['type'],
      ),
    );
  }
}

class _SelectExamReportListState extends State<SelectExamReportList> {
  final FocusNode _focusNode = FocusNode();
  String query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);

    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    store.onReportExamByCategoryApiCall(widget.id, widget.type);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  void _openGate(BuildContext context, ReportByExamListModel? reportByExam) {
    if (reportByExam?.isAccess == true) {
      Navigator.of(context).pushNamed(
        Routes.reportSubCategory,
        arguments: {
          'id': reportByExam?.examId,
          'title': reportByExam?.examName,
        },
      );
    } else {
      if (Platform.isWindows) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppTokens.scaffold(context),
              insetPadding: const EdgeInsets.symmetric(horizontal: 100),
              actionsPadding: EdgeInsets.zero,
              actions: const [NoAccessAlertDialog()],
            );
          },
        );
      } else {
        showModalBottomSheet<void>(
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppTokens.r20)),
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
    final store = Provider.of<ReportsCategoryStore>(context);
    return Scaffold(
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
              onTap: () => Navigator.pop(context),
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
                "Choose Test Report",
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
                if (store.reportByExam.isEmpty) {
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
                        ],
                      ),
                    ),
                  );
                }
                if (!store.isConnected) return const NoInternetScreen();

                return ListView.separated(
                  itemCount: store.reportByExam.length,
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
                    ReportByExamListModel? reportByExam =
                        store.reportByExam[index];
                    if (query.isNotEmpty &&
                        (!reportByExam!.examName!
                            .toLowerCase()
                            .contains(query.toLowerCase()))) {
                      return const SizedBox.shrink();
                    }
                    final isLocked = reportByExam?.isAccess == false;
                    return Stack(
                      children: [
                        Container(
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
                                height: 52,
                                width: 52,
                                padding:
                                    const EdgeInsets.all(AppTokens.s12),
                                decoration: BoxDecoration(
                                  color: AppTokens.accentSoft(context),
                                  borderRadius:
                                      BorderRadius.circular(AppTokens.r12),
                                ),
                                child: SvgPicture.asset(
                                  "assets/image/reportsubCate.svg",
                                  color: AppTokens.accent(context),
                                ),
                              ),
                              const SizedBox(width: AppTokens.s12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reportByExam?.examName ?? "",
                                      style: AppTokens.body(context).copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTokens.ink(context),
                                      ),
                                    ),
                                    const SizedBox(height: AppTokens.s8),
                                    InkWell(
                                      onTap: () =>
                                          _openGate(context, reportByExam),
                                      borderRadius: BorderRadius.circular(
                                          AppTokens.r20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTokens.s16,
                                          vertical: AppTokens.s8,
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
                                              BorderRadius.circular(
                                                  AppTokens.r20),
                                        ),
                                        child: Text(
                                          "View Analysis & Solution",
                                          style: AppTokens.caption(context)
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isLocked)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              height: AppTokens.s24,
                              width: AppTokens.s24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTokens.accent(context),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(AppTokens.r12),
                                  bottomLeft: Radius.circular(AppTokens.r12),
                                ),
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
