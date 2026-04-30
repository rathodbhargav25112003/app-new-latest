// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, prefer_final_fields, use_build_context_synchronously, avoid_print, unused_element, unnecessary_string_interpolations, dead_null_aware_expression

import 'dart:io';
import '../../app/routes.dart';
import 'package:intl/intl.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/styles.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import '../../helpers/dimensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';
import '../../models/merit_list_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/models/report_by_category_model.dart';
import 'package:shusruta_lms/helpers/forked_packages/circular_chart_flutter/lib/circular_chart_flutter.dart';
import 'package:nuts_activity_indicator/nuts_activity_indicator.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';




class TestReportDetailsScreen extends StatefulWidget {
  final String title;
  final ReportByCategoryModel? reports;
  final String userexamId;
  final String examId;
  const TestReportDetailsScreen(
      {super.key,
      required this.title,
      this.reports,
      required this.userexamId,
      required this.examId});
  @override
  State<TestReportDetailsScreen> createState() =>
      _TestReportDetailsScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => TestReportDetailsScreen(
        title: arguments['title'],
        reports: arguments['report'],
        userexamId: arguments['userexamId'],
        examId: arguments['examId'],
      ),
    );
  }
}

class _TestReportDetailsScreenState extends State<TestReportDetailsScreen> {
  final GlobalKey<AnimatedCircularChartState> _chartKey =
      GlobalKey<AnimatedCircularChartState>();
  final GlobalKey<AnimatedCircularChartState> _guessedchartKey =
      GlobalKey<AnimatedCircularChartState>();

  @override
  void initState() {
    super.initState();
    getMeritList();
  }

  Future<void> _getSolutionReport(String examId, String filter) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onSolutionReportApiCall(examId,"").then((_) {
      Navigator.of(context).pushNamed(Routes.solutionReport, arguments: {
        'solutionReport': store.solutionReportCategory,
        'filterVal': filter,
        'userExamId': examId
      });
    });
  }

  String roundAndFormatDouble(String value) {
    double doubleValue = double.tryParse(value) ?? 0.0;
    int roundedValue = doubleValue.round();
    return roundedValue.toString();
  }

  Future<void> getMeritList() async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onMeritListApiCall(widget.examId ?? "");
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    List<CircularStackEntry> data = <CircularStackEntry>[
      CircularStackEntry(
        <CircularSegmentEntry>[
          CircularSegmentEntry(
              double.tryParse(
                      widget.reports?.incorrectAnswersPercentage ?? "0") ??
                  0,
              ThemeManager.incorrectChart,
              rankKey: 'Q1'),
          CircularSegmentEntry(
              double.tryParse(
                      widget.reports?.correctAnswersPercentage ?? "0") ??
                  0,
              ThemeManager.correctChart,
              rankKey: 'Q2'),
          CircularSegmentEntry(
              double.tryParse(
                      widget.reports?.skippedAnswersPercentage ?? "0") ??
                  0,
              ThemeManager.skipChart,
              rankKey: 'Q3'),
        ],
        rankKey: 'Quarterly Profits',
      ),
    ];

    double percentageValue =
        double.tryParse(widget.reports?.percentage ?? "") ?? 0;
    String percentage =
        (percentageValue >= 0) ? percentageValue.toString() : "0";
    String myMarks = (widget.reports?.myMark ?? 0) >= 0
        ? widget.reports?.myMark.toString() ?? ""
        : "0";
    String originalDate = widget.reports?.date ?? "";
    DateTime parsedDate = DateTime.parse(originalDate);
    final formatter = DateFormat('dd MMM, yyyy');
    String formattedDate = formatter.format(parsedDate);
    List<CircularStackEntry> datax = <CircularStackEntry>[
      CircularStackEntry(
        <CircularSegmentEntry>[
          CircularSegmentEntry(
              widget.reports?.correctGuessCount?.toDouble() ?? 0,
              ThemeManager.greenSuccess,
              rankKey: 'Q1'),
          CircularSegmentEntry(widget.reports?.wrongGuessCount?.toDouble() ?? 0,
              ThemeManager.redAlert,
              rankKey: 'Q2'),
        ],
        rankKey: 'Guessed_Questions_Stats',
      ),
    ];
    String correctAnsPercentage =
        roundAndFormatDouble(widget.reports?.correctAnswersPercentage ?? "0.0");
    String incorrectAnsPercentage = roundAndFormatDouble(
        widget.reports?.incorrectAnswersPercentage.toString() ?? "");
    String skippedAnsPercentage = roundAndFormatDouble(
        widget.reports?.skippedAnswersPercentage.toString() ?? "");
    String accuracyPercentage = roundAndFormatDouble(
        widget.reports?.accuracyPercentage.toString() ?? "");

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed(Routes.reportsCategoryList);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        // appBar: AppBar(
        //   elevation: 0,
        //   automaticallyImplyLeading: false,
        //   backgroundColor: ThemeManager.white,
        //   leading: Padding(
        //     padding: const EdgeInsets.only(left: Dimensions.PADDING_SIZE_SMALL),
        //     child:       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
        //       icon:  Icon(Icons.arrow_back_ios, color: ThemeManager.iconColor),
        //       onPressed: () {
        //         Navigator.of(context).pushNamed(Routes.reportsCategoryList,
        //         arguments: {
        //           'fromhome': true
        //         });
        //       },
        //     ),
        //   ),
        //   centerTitle: true,
        //   title: Text("Analysis & Solutions",
        //     style: interSemiBold.copyWith(
        //       fontSize: Dimensions.fontSizeLarge,
        //       fontWeight: FontWeight.w500,
        //       color: ThemeManager.black,
        //     ),
        //   )
        // ),
        body: Observer(
          builder: (BuildContext context) {
            List<MeritListModel?> meritList = store.meritList;
            if (store.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    NutsActivityIndicator(
                      activeColor: Theme.of(context).primaryColor,
                      animating: true,
                      radius: 20,
                    ),
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_DEFAULT,
                    ),
                    Text(
                      "Getting everything ready for you... Just a moment!",
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        fontWeight: FontWeight.w500,
                        color: ThemeManager.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTokens.brand, AppTokens.brand2],
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        top: Dimensions.PADDING_SIZE_LARGE * 2,
                        left: Dimensions.PADDING_SIZE_LARGE * 1.2,
                        right: Dimensions.PADDING_SIZE_LARGE * 1.2,
                        bottom: Dimensions.PADDING_SIZE_SMALL * 1.3),
                    child: Row(
                      children: [
                        IconButton(
                            highlightColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                          
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios_rounded,
                              color: AppColors.white,
                            )),
                        const SizedBox(
                          width: Dimensions.PADDING_SIZE_DEFAULT,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: Text(
                            "Detailed Analytics",
                            style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(
                          left: Dimensions.PADDING_SIZE_LARGE * 1.2,
                          right: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                          top: Dimensions.PADDING_SIZE_DEFAULT * 2),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExpansionTile(
                              initiallyExpanded: false,
                              backgroundColor: ThemeManager.bottomBackground,
                              collapsedIconColor: ThemeManager.black,
                              iconColor: ThemeManager.black,
                              tilePadding: const EdgeInsets.only(
                                  top: Dimensions.PADDING_SIZE_SMALL * 0.6,
                                  bottom: Dimensions.PADDING_SIZE_SMALL * 0.6,
                                  left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                  right: Dimensions.PADDING_SIZE_LARGE),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9.6),
                                  side: BorderSide(
                                      color: ThemeManager.mainBorder)),
                              collapsedBackgroundColor: ThemeManager.white,
                              collapsedShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9.6),
                                  side: BorderSide(
                                      color: ThemeManager.mainBorder)),
                              title: Row(
                                children: [
                                  Container(
                                    height:
                                        Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                                    width:
                                        Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: ThemeManager
                                            .continueContainerOpacity,
                                        borderRadius:
                                            BorderRadius.circular(10.32)),
                                    child: SvgPicture.asset(
                                      "assets/image/award.svg",
                                      color: ThemeManager.currentTheme ==
                                              AppTheme.Dark
                                          ? AppColors.white
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_LARGE,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.title,
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                          fontWeight: FontWeight.w600,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      Text(
                                        "Attempt ${widget.reports?.isAttemptcount.toString() ?? ""} | $formattedDate",
                                        style: interRegular.copyWith(
                                          fontSize:
                                              Dimensions.fontSizeExtraSmall,
                                          fontWeight: FontWeight.w400,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                          "assets/image/firstAttempt.png"),
                                      const SizedBox(
                                        width:
                                            Dimensions.PADDING_SIZE_SMALL * 1.7,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "1st Attempt",
                                            style: interRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeSmall,
                                              fontWeight: FontWeight.w400,
                                              color: ThemeManager.black,
                                            ),
                                          ),
                                          Text(
                                            "Rank #${widget.reports?.userFirstRank.toString()}",
                                            style: interRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeLarge,
                                              fontWeight: FontWeight.w700,
                                              color: ThemeManager.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                ),
                                Divider(
                                  color: ThemeManager.divider,
                                  height: 0,
                                ),
                                const SizedBox(
                                  height: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Image.asset("assets/image/myMark.png"),
                                      const SizedBox(
                                        width:
                                            Dimensions.PADDING_SIZE_SMALL * 1.7,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "My Marks",
                                            style: interRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeSmall,
                                              fontWeight: FontWeight.w400,
                                              color: ThemeManager.black,
                                            ),
                                          ),
                                          Text(
                                            "$myMarks/${widget.reports?.mark.toString()}",
                                            style: interRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeLarge,
                                              fontWeight: FontWeight.w700,
                                              color: ThemeManager.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                ),
                                Divider(
                                  color: ThemeManager.divider,
                                  height: 0,
                                ),
                                const SizedBox(
                                  height: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                          "assets/image/myPercantage.png"),
                                      const SizedBox(
                                        width:
                                            Dimensions.PADDING_SIZE_SMALL * 1.7,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "My Percentage",
                                            style: interRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeSmall,
                                              fontWeight: FontWeight.w400,
                                              color: ThemeManager.black,
                                            ),
                                          ),
                                          Text(
                                            "$percentage%",
                                            style: interRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeLarge,
                                              fontWeight: FontWeight.w700,
                                              color: ThemeManager.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                ),
                              ],
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_DEFAULT),

                            ExpansionTile(
                              initiallyExpanded: false,
                              backgroundColor: ThemeManager.white,
                              collapsedIconColor: ThemeManager.black,
                              iconColor: ThemeManager.black,
                              tilePadding: const EdgeInsets.only(
                                  top: Dimensions.PADDING_SIZE_SMALL * 0.6,
                                  bottom: Dimensions.PADDING_SIZE_SMALL * 0.6,
                                  left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                  right: Dimensions.PADDING_SIZE_DEFAULT * 1.2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9.6),
                                  side: BorderSide(
                                      color: ThemeManager.mainBorder)),
                              collapsedBackgroundColor: ThemeManager.white,
                              collapsedShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9.6),
                                  side: BorderSide(
                                      color: ThemeManager.mainBorder)),
                              title: Row(
                                children: [
                                  Container(
                                    height:
                                        Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                                    width:
                                        Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: ThemeManager
                                            .continueContainerOpacity,
                                        borderRadius:
                                            BorderRadius.circular(10.32)),
                                    child: SvgPicture.asset(
                                      "assets/image/award.svg",
                                      color: ThemeManager.currentTheme ==
                                              AppTheme.Dark
                                          ? AppColors.white
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_LARGE,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Summit Scholars",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                          fontWeight: FontWeight.w600,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      Text(
                                        "(Attempt 1)",
                                        style: interRegular.copyWith(
                                          fontSize:
                                              Dimensions.fontSizeExtraSmall,
                                          fontWeight: FontWeight.w400,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              childrenPadding: const EdgeInsets.only(
                                top: Dimensions.PADDING_SIZE_SMALL * 1.5,
                                left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                right: Dimensions.PADDING_SIZE_SMALL * 1.6,
                                bottom: Dimensions.PADDING_SIZE_SMALL * 2.1,
                              ),
                              children: [
                                DataTable(
                                  columnSpacing: Dimensions.PADDING_SIZE_SMALL,
                                  horizontalMargin:
                                      Dimensions.PADDING_SIZE_SMALL * 1.3,
                                  border: TableBorder.all(
                                      color: ThemeManager.summitBorder
                                          .withOpacity(0.2),
                                      width: 1.48),
                                  headingRowColor:
                                      MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) {
                                      if (states
                                          .contains(MaterialState.hovered)) {
                                        return Colors.grey.withOpacity(
                                            0.3); // Color when hovered
                                      }
                                      return ThemeManager
                                          .summitBorder; // Default color
                                    },
                                  ),
                                  columns: [
                                    DataColumn(
                                        label: Text(
                                      "Rank",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        fontWeight: FontWeight.w600,
                                        color: ThemeManager.white,
                                      ),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      "Marks",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        fontWeight: FontWeight.w600,
                                        color: ThemeManager.white,
                                      ),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      "Correct",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        fontWeight: FontWeight.w600,
                                        color: ThemeManager.white,
                                      ),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      "Incorrect",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        fontWeight: FontWeight.w600,
                                        color: ThemeManager.white,
                                      ),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      "Skipped",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        fontWeight: FontWeight.w600,
                                        color: ThemeManager.white,
                                      ),
                                    )),
                                  ],
                                  rows: meritList.map((student) {
                                    return DataRow(cells: [
                                      DataCell(Padding(
                                        padding: const EdgeInsets.only(
                                            right:
                                                Dimensions.PADDING_SIZE_LARGE),
                                        child: Row(
                                          children: [
                                            Text(
                                              "${student?.rank.toString()}",
                                              style: interRegular.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                                fontWeight: FontWeight.w400,
                                                color: ThemeManager.textColor3,
                                              ),
                                            ),
                                            student?.isMyRank == true
                                                ? Text(
                                                    " (You)",
                                                    style:
                                                        interRegular.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeSmall,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: ThemeManager
                                                          .blueFinal,
                                                    ),
                                                  )
                                                : const SizedBox()
                                          ],
                                        ),
                                      )),
                                      DataCell(Center(
                                        child: Text(
                                            student?.score.toString() ?? "",
                                            style: interRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeSmall,
                                              fontWeight: FontWeight.w400,
                                              color: ThemeManager.textColor3,
                                            )),
                                      )),
                                      DataCell(Center(
                                        child: Text(
                                          student?.correct.toString() ?? "",
                                          style: interRegular.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            fontWeight: FontWeight.w400,
                                            color: ThemeManager.textColor3,
                                          ),
                                        ),
                                      )),
                                      DataCell(Center(
                                        child: Text(
                                          student?.inCorrect.toString() ?? "",
                                          style: interRegular.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            fontWeight: FontWeight.w400,
                                            color: ThemeManager.textColor3,
                                          ),
                                        ),
                                      )),
                                      DataCell(Center(
                                        child: Text(
                                          student?.skipped.toString() ?? "",
                                          style: interRegular.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            fontWeight: FontWeight.w400,
                                            color: ThemeManager.textColor3,
                                          ),
                                        ),
                                      )),
                                    ]);
                                  }).toList(),
                                ),
                              ],
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_DEFAULT),

                            // LayoutBuilder(
                            //     builder: (context, constraints){
                            //       if (constraints.maxWidth > 600) {
                            //         return ExpansionTile(
                            //           initiallyExpanded: false,
                            //           backgroundColor: ThemeManager.white,
                            //           collapsedIconColor: ThemeManager.black,
                            //           iconColor: ThemeManager.black,
                            //           tilePadding: const EdgeInsets.only(
                            //               top: Dimensions.PADDING_SIZE_SMALL*0.6,
                            //               bottom: Dimensions.PADDING_SIZE_SMALL*0.6,
                            //               left: Dimensions.PADDING_SIZE_SMALL*1.4,
                            //               right: Dimensions.PADDING_SIZE_LARGE
                            //           ),
                            //           shape: RoundedRectangleBorder(
                            //             borderRadius: BorderRadius.circular(9.6),
                            //           ),
                            //           collapsedBackgroundColor: ThemeManager.white,
                            //           collapsedShape: RoundedRectangleBorder(
                            //             borderRadius: BorderRadius.circular(9.6),
                            //           ),
                            //           title: Row(
                            //             children: [
                            //               Container(
                            //                 height: Dimensions.PADDING_SIZE_EXTRA_LARGE*2,
                            //                 width: Dimensions.PADDING_SIZE_EXTRA_LARGE*2,
                            //                 alignment: Alignment.center,
                            //                 decoration: BoxDecoration(
                            //                     color: ThemeManager.continueContainer,
                            //                     borderRadius: BorderRadius.circular(10.32)
                            //                 ),
                            //                 child: SvgPicture.asset("assets/image/award.svg"),
                            //               ),
                            //               const SizedBox(width: Dimensions.PADDING_SIZE_LARGE,),
                            //               Text(
                            //                 "EduMetrics",
                            //                 style: interRegular.copyWith(
                            //                   fontSize: Dimensions.fontSizeDefault,
                            //                   fontWeight: FontWeight.w600,
                            //                   color: ThemeManager.black,
                            //                 ),
                            //               )
                            //             ],
                            //           ),
                            //           children: [
                            //             Stack(
                            //               alignment: AlignmentDirectional.center,
                            //               children: [
                            //                 Column(
                            //                   crossAxisAlignment: CrossAxisAlignment.center,
                            //                   children: [
                            //                     Text(
                            //                       "Total Questions",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeDefault,
                            //                         fontWeight: FontWeight.w600,
                            //                         color: ThemeManager.textChart,
                            //                       ),
                            //                     ),
                            //                     Text(
                            //                       widget.reports?.question.toString()??"",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: 32,
                            //                         fontWeight: FontWeight.w700,
                            //                         color: ThemeManager.black,
                            //                       ),
                            //                     ),
                            //                   ],
                            //                 ),
                            //                 AnimatedCircularChart(
                            //                   key: _chartKey,
                            //                   size: const Size(500.0, 300),
                            //                   initialChartData: data,
                            //                   holeRadius: 40,
                            //                   chartType: CircularChartType.Radial,
                            //                 ),
                            //               ],
                            //             ),
                            //             Padding(
                            //               padding: const EdgeInsets.only(
                            //                 left: Dimensions.PADDING_SIZE_SMALL*1.4,
                            //                 right: Dimensions.PADDING_SIZE_SMALL*1.2,
                            //               ),
                            //               child: Row(
                            //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //                 children: [
                            //                   Row(
                            //                     children: [
                            //                       Container(
                            //                         height: Dimensions.PADDING_SIZE_SMALL,
                            //                         width: Dimensions.PADDING_SIZE_SMALL,
                            //                         margin: const EdgeInsets.only(
                            //                             right: Dimensions.PADDING_SIZE_EXTRA_SMALL*1.1
                            //                         ),
                            //                         decoration: BoxDecoration(
                            //                             shape: BoxShape.circle,
                            //                             color: ThemeManager.correctChart
                            //                         ),
                            //                       ),
                            //                       Text(
                            //                         "Correct",
                            //                         style: interRegular.copyWith(
                            //                           fontSize: Dimensions.fontSizeSmall,
                            //                           fontWeight: FontWeight.w400,
                            //                           color: ThemeManager.black,
                            //                         ),
                            //                       ),
                            //                       const SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL*1.1,),
                            //                       Text(
                            //                         "($correctAnsPercentage%)",
                            //                         style: interRegular.copyWith(
                            //                           fontSize: Dimensions.fontSizeSmall,
                            //                           fontWeight: FontWeight.w600,
                            //                           color: ThemeManager.black,
                            //                         ),
                            //                       ),
                            //                     ],
                            //                   ),
                            //                   Row(
                            //                     children: [
                            //                       Container(
                            //                         height: Dimensions.PADDING_SIZE_SMALL,
                            //                         width: Dimensions.PADDING_SIZE_SMALL,
                            //                         margin: const EdgeInsets.only(
                            //                             right: Dimensions.PADDING_SIZE_EXTRA_SMALL*1.1
                            //                         ),
                            //                         decoration: BoxDecoration(
                            //                             shape: BoxShape.circle,
                            //                             color: ThemeManager.incorrectChart
                            //                         ),
                            //                       ),
                            //                       Text(
                            //                         "Incorrect",
                            //                         style: interRegular.copyWith(
                            //                           fontSize: Dimensions.fontSizeSmall,
                            //                           fontWeight: FontWeight.w400,
                            //                           color: ThemeManager.black,
                            //                         ),
                            //                       ),
                            //                       const SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL*1.1,),
                            //                       Text(
                            //                         "($incorrectAnsPercentage%)",
                            //                         style: interRegular.copyWith(
                            //                           fontSize: Dimensions.fontSizeSmall,
                            //                           fontWeight: FontWeight.w600,
                            //                           color: ThemeManager.black,
                            //                         ),
                            //                       ),
                            //                     ],
                            //                   ),
                            //                   Row(
                            //                     children: [
                            //                       Container(
                            //                         height: Dimensions.PADDING_SIZE_SMALL,
                            //                         width: Dimensions.PADDING_SIZE_SMALL,
                            //                         margin: const EdgeInsets.only(
                            //                             right: Dimensions.PADDING_SIZE_EXTRA_SMALL*1.1
                            //                         ),
                            //                         decoration: BoxDecoration(
                            //                             shape: BoxShape.circle,
                            //                             color: ThemeManager.skipChart
                            //                         ),
                            //                       ),
                            //                       Text(
                            //                         "Skipped",
                            //                         style: interRegular.copyWith(
                            //                           fontSize: Dimensions.fontSizeSmall,
                            //                           fontWeight: FontWeight.w400,
                            //                           color: ThemeManager.black,
                            //                         ),
                            //                       ),
                            //                       const SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL*1.1,),
                            //                       Text(
                            //                         "($skippedAnsPercentage%)",
                            //                         style: interRegular.copyWith(
                            //                           fontSize: Dimensions.fontSizeSmall,
                            //                           fontWeight: FontWeight.w600,
                            //                           color: ThemeManager.black,
                            //                         ),
                            //                       ),
                            //                     ],
                            //                   ),
                            //                 ],
                            //               ),
                            //             ),
                            //             const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                            //             Padding(
                            //               padding: const EdgeInsets.only(
                            //                 left: Dimensions.PADDING_SIZE_SMALL*1.4,
                            //                 right: Dimensions.PADDING_SIZE_SMALL*1.2,
                            //               ),
                            //               child: Row(
                            //                 children: [
                            //                   Expanded(
                            //                     child: Container(
                            //                       padding: const EdgeInsets.only(
                            //                         left: Dimensions.PADDING_SIZE_SMALL*1.3,
                            //                         right:  Dimensions.PADDING_SIZE_SMALL,
                            //                         top:  Dimensions.PADDING_SIZE_SMALL,
                            //                         bottom:  Dimensions.PADDING_SIZE_SMALL*1.1,
                            //                       ),
                            //                       decoration: BoxDecoration(
                            //                           color: ThemeManager.white,
                            //                           border: Border.all(
                            //                               color: ThemeManager.eduBorder,
                            //                               width: 0.61
                            //                           ),
                            //                           boxShadow: [
                            //                             BoxShadow(
                            //                               offset: const Offset(0, 1.84208),
                            //                               blurRadius: 18.2843,
                            //                               spreadRadius: 0,
                            //                               color: ThemeManager.black.withOpacity(0.06),
                            //                             ),
                            //                           ]
                            //                       ),
                            //                       child: Row(
                            //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //                         children: [
                            //                           Column(
                            //                             crossAxisAlignment: CrossAxisAlignment.start,
                            //                             children: [
                            //                               Text(
                            //                                 "Accuracy",
                            //                                 style: interRegular.copyWith(
                            //                                   fontSize: Dimensions.fontSizeExtraSmall,
                            //                                   fontWeight: FontWeight.w400,
                            //                                   color: ThemeManager.textChart,
                            //                                 ),
                            //                               ),
                            //                               Text(
                            //                                 "$accuracyPercentage%",
                            //                                 style: interRegular.copyWith(
                            //                                   fontSize: Dimensions.fontSizeLarge,
                            //                                   fontWeight: FontWeight.w600,
                            //                                   color: ThemeManager.black,
                            //                                 ),
                            //                               ),
                            //                             ],
                            //                           ),
                            //                           Container(
                            //                             height: Dimensions.PADDING_SIZE_EXTRA_LARGE*1.1,
                            //                             width: Dimensions.PADDING_SIZE_EXTRA_LARGE*1.1,
                            //                             alignment: Alignment.center,
                            //                             decoration: BoxDecoration(
                            //                                 borderRadius: BorderRadius.circular(7.37),
                            //                                 boxShadow: [
                            //                                   BoxShadow(
                            //                                       offset: const Offset(0, 2.149095),
                            //                                       blurRadius: 3.3771,
                            //                                       spreadRadius: 0,
                            //                                       color: ThemeManager.black.withOpacity(0.02)
                            //                                   ),
                            //                                 ],
                            //                                 gradient: LinearGradient(colors: [
                            //                                   ThemeManager.edugradiet.withOpacity(0),
                            //                                   ThemeManager.edugradiet,
                            //                                 ],begin: Alignment.topLeft,end: Alignment.bottomRight)
                            //                             ),
                            //                             child: SvgPicture.asset("assets/image/accuracy.svg"),
                            //                           ),
                            //                         ],
                            //                       ),
                            //                     ),
                            //                   ),
                            //                   const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
                            //                   Expanded(
                            //                     child: Container(
                            //                       padding: const EdgeInsets.only(
                            //                         left: Dimensions.PADDING_SIZE_SMALL*1.3,
                            //                         right:  Dimensions.PADDING_SIZE_SMALL,
                            //                         top:  Dimensions.PADDING_SIZE_SMALL,
                            //                         bottom:  Dimensions.PADDING_SIZE_SMALL*1.1,
                            //                       ),
                            //                       decoration: BoxDecoration(
                            //                           color: ThemeManager.white,
                            //                           border: Border.all(
                            //                               color: ThemeManager.eduBorder,
                            //                               width: 0.61
                            //                           ),
                            //                           boxShadow: [
                            //                             BoxShadow(
                            //                               offset: const Offset(0, 1.84208),
                            //                               blurRadius: 18.2843,
                            //                               spreadRadius: 0,
                            //                               color: ThemeManager.black.withOpacity(0.06),
                            //                             ),
                            //                           ]
                            //                       ),
                            //                       child: Row(
                            //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //                         children: [
                            //                           Column(
                            //                             crossAxisAlignment: CrossAxisAlignment.start,
                            //                             children: [
                            //                               Text(
                            //                                 "Time Taken",
                            //                                 style: interRegular.copyWith(
                            //                                   fontSize: Dimensions.fontSizeExtraSmall,
                            //                                   fontWeight: FontWeight.w400,
                            //                                   color: ThemeManager.textChart,
                            //                                 ),
                            //                               ),
                            //                               Text(
                            //                                 widget.reports?.Time??"",
                            //                                 style: interRegular.copyWith(
                            //                                   fontSize: Dimensions.fontSizeLarge,
                            //                                   fontWeight: FontWeight.w600,
                            //                                   color: ThemeManager.black,
                            //                                 ),
                            //                               ),
                            //                             ],
                            //                           ),
                            //                           Container(
                            //                             height: Dimensions.PADDING_SIZE_EXTRA_LARGE*1.1,
                            //                             width: Dimensions.PADDING_SIZE_EXTRA_LARGE*1.1,
                            //                             alignment: Alignment.center,
                            //                             decoration: BoxDecoration(
                            //                                 borderRadius: BorderRadius.circular(7.37),
                            //                                 boxShadow: [
                            //                                   BoxShadow(
                            //                                       offset: const Offset(0, 2.149095),
                            //                                       blurRadius: 3.3771,
                            //                                       spreadRadius: 0,
                            //                                       color: ThemeManager.black.withOpacity(0.02)
                            //                                   ),
                            //                                 ],
                            //                                 gradient: LinearGradient(colors: [
                            //                                   ThemeManager.edugradiet2.withOpacity(0),
                            //                                   ThemeManager.edugradiet2,
                            //                                 ],begin: Alignment.topLeft,end: Alignment.bottomRight)
                            //                             ),
                            //                             child: SvgPicture.asset("assets/image/timeTaken.svg"),
                            //                           ),
                            //                         ],
                            //                       ),
                            //                     ),
                            //                   ),
                            //                 ],
                            //               ),
                            //             ),
                            //             const SizedBox(height: Dimensions.PADDING_SIZE_LARGE,),
                            //           ],
                            //         );
                            //       }
                            //       return ExpansionTile(
                            //         initiallyExpanded: false,
                            //         backgroundColor: ThemeManager.white,
                            //         collapsedIconColor: ThemeManager.black,
                            //         iconColor: ThemeManager.black,
                            //         tilePadding: const EdgeInsets.only(
                            //             top: Dimensions.PADDING_SIZE_SMALL*0.6,
                            //             bottom: Dimensions.PADDING_SIZE_SMALL*0.6,
                            //             left: Dimensions.PADDING_SIZE_SMALL*1.4,
                            //             right: Dimensions.PADDING_SIZE_LARGE
                            //         ),
                            //         shape: RoundedRectangleBorder(
                            //           borderRadius: BorderRadius.circular(9.6),
                            //         ),
                            //         collapsedBackgroundColor: ThemeManager.white,
                            //         collapsedShape: RoundedRectangleBorder(
                            //           borderRadius: BorderRadius.circular(9.6),
                            //         ),
                            //         title: Row(
                            //           children: [
                            //             Container(
                            //               height: Dimensions.PADDING_SIZE_EXTRA_LARGE*2,
                            //               width: Dimensions.PADDING_SIZE_EXTRA_LARGE*2,
                            //               alignment: Alignment.center,
                            //               decoration: BoxDecoration(
                            //                   color: ThemeManager.continueContainer,
                            //                   borderRadius: BorderRadius.circular(10.32)
                            //               ),
                            //               child: SvgPicture.asset("assets/image/award.svg"),
                            //             ),
                            //             const SizedBox(width: Dimensions.PADDING_SIZE_LARGE,),
                            //             Text(
                            //               "EduMetrics",
                            //               style: interRegular.copyWith(
                            //                 fontSize: Dimensions.fontSizeDefault,
                            //                 fontWeight: FontWeight.w600,
                            //                 color: ThemeManager.black,
                            //               ),
                            //             )
                            //           ],
                            //         ),
                            //         children: [
                            //           Stack(
                            //             alignment: AlignmentDirectional.center,
                            //             children: [
                            //               Column(
                            //                 crossAxisAlignment: CrossAxisAlignment.center,
                            //                 children: [
                            //                   Text(
                            //                     "Total Questions",
                            //                     style: interRegular.copyWith(
                            //                       fontSize: Dimensions.fontSizeDefault,
                            //                       fontWeight: FontWeight.w600,
                            //                       color: ThemeManager.textChart,
                            //                     ),
                            //                   ),
                            //                   Text(
                            //                     widget.reports?.question.toString()??"",
                            //                     style: interRegular.copyWith(
                            //                       fontSize: 32,
                            //                       fontWeight: FontWeight.w700,
                            //                       color: ThemeManager.black,
                            //                     ),
                            //                   ),
                            //                 ],
                            //               ),
                            //               AnimatedCircularChart(
                            //                 key: _chartKey,
                            //                 size: const Size(500.0, 300),
                            //                 initialChartData: data,
                            //                 holeRadius: 40,
                            //                 chartType: CircularChartType.Radial,
                            //               ),
                            //             ],
                            //           ),
                            //           Padding(
                            //             padding: const EdgeInsets.only(
                            //               left: Dimensions.PADDING_SIZE_SMALL*1.4,
                            //               right: Dimensions.PADDING_SIZE_SMALL*1.2,
                            //             ),
                            //             child: Column(
                            //               children: [
                            //                 Row(
                            //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //                   children: [
                            //                     Row(
                            //                       children: [
                            //                         Container(
                            //                           height: Dimensions.PADDING_SIZE_SMALL,
                            //                           width: Dimensions.PADDING_SIZE_SMALL,
                            //                           margin: const EdgeInsets.only(
                            //                               right: Dimensions.PADDING_SIZE_EXTRA_SMALL*1.1
                            //                           ),
                            //                           decoration: BoxDecoration(
                            //                               shape: BoxShape.circle,
                            //                               color: ThemeManager.correctChart
                            //                           ),
                            //                         ),
                            //                         Text(
                            //                           "Correct",
                            //                           style: interRegular.copyWith(
                            //                             fontSize: Dimensions.fontSizeSmall,
                            //                             fontWeight: FontWeight.w400,
                            //                             color: ThemeManager.black,
                            //                           ),
                            //                         ),
                            //                         const SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL*1.1,),
                            //                         Text(
                            //                           "($correctAnsPercentage%)",
                            //                           style: interRegular.copyWith(
                            //                             fontSize: Dimensions.fontSizeSmall,
                            //                             fontWeight: FontWeight.w600,
                            //                             color: ThemeManager.black,
                            //                           ),
                            //                         ),
                            //                       ],
                            //                     ),
                            //                     Container(
                            //                       height: Dimensions.PADDING_SIZE_EXTRA_LARGE*1.1,
                            //                       width: Dimensions.PADDING_SIZE_EXTRA_LARGE*1.1,
                            //                       alignment: Alignment.center,
                            //                       decoration: BoxDecoration(
                            //                           borderRadius: BorderRadius.circular(7.37),
                            //                           boxShadow: [
                            //                             BoxShadow(
                            //                                 offset: const Offset(0, 2.149095),
                            //                               blurRadius: 3.3771,
                            //                               spreadRadius: 0,
                            //                                 color: ThemeManager.black.withOpacity(0.02)
                            //                             ),
                            //                           ],
                            //                           gradient: LinearGradient(colors: [
                            //                             ThemeManager.edugradiet.withOpacity(0),
                            //                             ThemeManager.edugradiet,
                            //                           ],begin: Alignment.topLeft,end: Alignment.bottomRight)
                            //                       ),
                            //                       child: SvgPicture.asset("assets/image/accuracy.svg",color: ThemeManager.currentTheme == AppTheme.Dark ? AppColors.black : null,),
                            //                     ),
                            //                   ],
                            //                 ),
                            //               ),
                            //             ),
                            //             const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
                            //             Expanded(
                            //               child: Container(
                            //                 padding: const EdgeInsets.only(
                            //                   left: Dimensions.PADDING_SIZE_SMALL*1.3,
                            //                   right:  Dimensions.PADDING_SIZE_SMALL,
                            //                   top:  Dimensions.PADDING_SIZE_SMALL,
                            //                   bottom:  Dimensions.PADDING_SIZE_SMALL*1.1,
                            //                 ),
                            //                 decoration: BoxDecoration(
                            //                     color: ThemeManager.white,
                            //                     border: Border.all(
                            //                         color: ThemeManager.eduBorder,
                            //                         width: 0.61
                            //                     ),
                            //                     boxShadow: [
                            //                       BoxShadow(
                            //                         offset: const Offset(0, 1.84208),
                            //                         blurRadius: 18.2843,
                            //                         spreadRadius: 0,
                            //                         color: ThemeManager.black.withOpacity(0.06),
                            //                       ),
                            //                     ]
                            //                 ),
                            //                 child: Row(
                            //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //                   children: [
                            //                     Column(
                            //                       crossAxisAlignment: CrossAxisAlignment.start,
                            //                       children: [
                            //                         Container(
                            //                           height: Dimensions.PADDING_SIZE_SMALL,
                            //                           width: Dimensions.PADDING_SIZE_SMALL,
                            //                           margin: const EdgeInsets.only(
                            //                               right: Dimensions.PADDING_SIZE_EXTRA_SMALL*1.1
                            //                           ),
                            //                           decoration: BoxDecoration(
                            //                               shape: BoxShape.circle,
                            //                               color: ThemeManager.incorrectChart
                            //                           ),
                            //                         ),
                            //                         Text(
                            //                           "Incorrect",
                            //                           style: interRegular.copyWith(
                            //                             fontSize: Dimensions.fontSizeSmall,
                            //                             fontWeight: FontWeight.w400,
                            //                             color: ThemeManager.black,
                            //                           ),
                            //                         ),
                            //                         const SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL*1.1,),
                            //                         Text(
                            //                           "($incorrectAnsPercentage%)",
                            //                           style: interRegular.copyWith(
                            //                             fontSize: Dimensions.fontSizeSmall,
                            //                             fontWeight: FontWeight.w600,
                            //                             color: ThemeManager.black,
                            //                           ),
                            //                         ),
                            //                       ],
                            //                     ),
                            //                   ],
                            //                 ),
                            //                 const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                            //                 Row(
                            //                   mainAxisAlignment: MainAxisAlignment.center,
                            //                   children: [
                            //                     Container(
                            //                       height: Dimensions.PADDING_SIZE_SMALL,
                            //                       width: Dimensions.PADDING_SIZE_SMALL,
                            //                       margin: const EdgeInsets.only(
                            //                           right: Dimensions.PADDING_SIZE_EXTRA_SMALL*1.1
                            //                       ),
                            //                       decoration: BoxDecoration(
                            //                           shape: BoxShape.circle,
                            //                           color: ThemeManager.skipChart
                            //                       ),
                            //                     ),
                            //                     Text(
                            //                       "Skipped",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color: ThemeManager.black,
                            //                       ),
                            //                     ),
                            //                     const SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL*1.1,),
                            //                     Text(
                            //                       "($skippedAnsPercentage%)",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w600,
                            //                         color: ThemeManager.black,
                            //                       ),
                            //                     ),
                            //                   ],
                            //                 ),
                            //               ],
                            //             ),
                            //           ),
                            //           const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                            //           Padding(
                            //             padding: const EdgeInsets.only(
                            //               left: Dimensions.PADDING_SIZE_SMALL*1.4,
                            //               right: Dimensions.PADDING_SIZE_SMALL*1.2,
                            //             ),
                            //             child: Row(
                            //               children: [
                            //                 Expanded(
                            //                   child: Container(
                            //                     padding: const EdgeInsets.only(
                            //                       left: Dimensions.PADDING_SIZE_SMALL*1.3,
                            //                       right:  Dimensions.PADDING_SIZE_SMALL,
                            //                       top:  Dimensions.PADDING_SIZE_SMALL,
                            //                       bottom:  Dimensions.PADDING_SIZE_SMALL*1.1,
                            //                     ),
                            //                     decoration: BoxDecoration(
                            //                         color: ThemeManager.white,
                            //                         border: Border.all(
                            //                             color: ThemeManager.eduBorder,
                            //                             width: 0.61
                            //                         ),
                            //                         boxShadow: [
                            //                           BoxShadow(
                            //                             offset: const Offset(0, 1.84208),
                            //                             blurRadius: 18.2843,
                            //                             spreadRadius: 0,
                            //                             color: ThemeManager.black.withOpacity(0.06),
                            //                           ),
                            //                         ]
                            //                     ),
                            //                     child: Row(
                            //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //                       children: [
                            //                         Column(
                            //                           crossAxisAlignment: CrossAxisAlignment.start,
                            //                           children: [
                            //                             Text(
                            //                               "Accuracy",
                            //                               style: interRegular.copyWith(
                            //                                 fontSize: Dimensions.fontSizeExtraSmall,
                            //                                 fontWeight: FontWeight.w400,
                            //                                 color: ThemeManager.textChart,
                            //                               ),
                            //                             ),
                            //                             Text(
                            //                               "$accuracyPercentage%",
                            //                               style: interRegular.copyWith(
                            //                                 fontSize: Dimensions.fontSizeLarge,
                            //                                 fontWeight: FontWeight.w600,
                            //                                 color: ThemeManager.black,
                            //                               ),
                            //                             ),
                            //                           ],
                            //                         ),
                            //                         Container(
                            //                           height: Dimensions.PADDING_SIZE_EXTRA_LARGE*1.1,
                            //                           width: Dimensions.PADDING_SIZE_EXTRA_LARGE*1.1,
                            //                           alignment: Alignment.center,
                            //                           decoration: BoxDecoration(
                            //                               borderRadius: BorderRadius.circular(7.37),
                            //                               boxShadow: [
                            //                                 BoxShadow(
                            //                                     offset: const Offset(0, 2.149095),
                            //                                     blurRadius: 3.3771,
                            //                                     spreadRadius: 0,
                            //                                     color: ThemeManager.black.withOpacity(0.02)
                            //                                 ),
                            //                               ],
                            //                               gradient: LinearGradient(colors: [
                            //                                 ThemeManager.edugradiet.withOpacity(0),
                            //                                 ThemeManager.edugradiet,
                            //                               ],begin: Alignment.topLeft,end: Alignment.bottomRight)
                            //                           ),
                            //                           child: SvgPicture.asset("assets/image/accuracy.svg"),
                            //                         ),
                            //                       ],
                            //                     ),
                            //                   ),
                            //                 ),
                            //                 const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
                            //                 Expanded(
                            //                   child: Container(
                            //                     padding: const EdgeInsets.only(
                            //                       left: Dimensions.PADDING_SIZE_SMALL*1.3,
                            //                       right:  Dimensions.PADDING_SIZE_SMALL,
                            //                       top:  Dimensions.PADDING_SIZE_SMALL,
                            //                       bottom:  Dimensions.PADDING_SIZE_SMALL*1.1,
                            //                     ),
                            //                     decoration: BoxDecoration(
                            //                         color: ThemeManager.white,
                            //                         border: Border.all(
                            //                             color: ThemeManager.eduBorder,
                            //                             width: 0.61
                            //                         ),
                            //                         boxShadow: [
                            //                           BoxShadow(
                            //                             offset: const Offset(0, 1.84208),
                            //                             blurRadius: 18.2843,
                            //                             spreadRadius: 0,
                            //                             color: ThemeManager.black.withOpacity(0.06),
                            //                           ),
                            //                         ]
                            //                     ),
                            //                     child: Row(
                            //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //                       children: [
                            //                         Column(
                            //                           crossAxisAlignment: CrossAxisAlignment.start,
                            //                           children: [
                            //                             Text(
                            //                               "Time Taken",
                            //                               style: interRegular.copyWith(
                            //                                 fontSize: Dimensions.fontSizeExtraSmall,
                            //                                 fontWeight: FontWeight.w400,
                            //                                 color: ThemeManager.textChart,
                            //                               ),
                            //                             ),
                            //                             Text(
                            //                               widget.reports?.Time??"",
                            //                               style: interRegular.copyWith(
                            //                                 fontSize: Dimensions.fontSizeLarge,
                            //                                 fontWeight: FontWeight.w600,
                            //                                 color: ThemeManager.black,
                            //                               ),
                            //                             ),
                            //                           ],
                            //                         ),
                            //                         Container(
                            //                           height: Dimensions.PADDING_SIZE_EXTRA_LARGE*1.1,
                            //                           width: Dimensions.PADDING_SIZE_EXTRA_LARGE*1.1,
                            //                           alignment: Alignment.center,
                            //                           decoration: BoxDecoration(
                            //                               borderRadius: BorderRadius.circular(7.37),
                            //                               boxShadow: [
                            //                                 BoxShadow(
                            //                                     offset: const Offset(0, 2.149095),
                            //                                     blurRadius: 3.3771,
                            //                                     spreadRadius: 0,
                            //                                     color: ThemeManager.black.withOpacity(0.02)
                            //                                 ),
                            //                               ],
                            //                               gradient: LinearGradient(colors: [
                            //                                 ThemeManager.edugradiet2.withOpacity(0),
                            //                                 ThemeManager.edugradiet2,
                            //                               ],begin: Alignment.topLeft,end: Alignment.bottomRight)
                            //                           ),
                            //                           child: SvgPicture.asset("assets/image/timeTaken.svg"),
                            //                         ),
                            //                       ],
                            //                     ),
                            //                   ),
                            //                 ),
                            //               ],
                            //             ),
                            //           ),
                            //           const SizedBox(height: Dimensions.PADDING_SIZE_LARGE,),
                            //         ],
                            //       );
                            //     }
                            //   ),
                            LayoutBuilder(builder: (context, constraints) {
                              if (constraints.maxWidth > 600) {
                                return ExpansionTile(
                                  initiallyExpanded: false,
                                  backgroundColor: ThemeManager.white,
                                  collapsedIconColor: ThemeManager.black,
                                  iconColor: ThemeManager.black,
                                  tilePadding: const EdgeInsets.only(
                                      top: Dimensions.PADDING_SIZE_SMALL * 0.6,
                                      bottom:
                                          Dimensions.PADDING_SIZE_SMALL * 0.6,
                                      left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                      right: Dimensions.PADDING_SIZE_LARGE),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9.6),
                                      side: BorderSide(
                                          color: ThemeManager.mainBorder)),
                                  collapsedBackgroundColor: ThemeManager.white,
                                  collapsedShape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9.6),
                                      side: BorderSide(
                                          color: ThemeManager.mainBorder)),
                                  title: Row(
                                    children: [
                                      Container(
                                        height: Dimensions
                                                .PADDING_SIZE_EXTRA_LARGE *
                                            2,
                                        width: Dimensions
                                                .PADDING_SIZE_EXTRA_LARGE *
                                            2,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            color: ThemeManager
                                                .continueContainerOpacity,
                                            borderRadius:
                                                BorderRadius.circular(10.32)),
                                        child: SvgPicture.asset(
                                          "assets/image/award.svg",
                                          color: ThemeManager.currentTheme ==
                                                  AppTheme.Dark
                                              ? AppColors.white
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: Dimensions.PADDING_SIZE_LARGE,
                                      ),
                                      Text(
                                        "EduMetrics",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                          fontWeight: FontWeight.w600,
                                          color: ThemeManager.black,
                                        ),
                                      )
                                    ],
                                  ),
                                  children: [
                                    Stack(
                                      alignment: AlignmentDirectional.center,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Total Questions",
                                              style: interRegular.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeDefault,
                                                fontWeight: FontWeight.w600,
                                                color: ThemeManager.textChart,
                                              ),
                                            ),
                                            Text(
                                              widget.reports?.question
                                                      .toString() ??
                                                  "",
                                              style: interRegular.copyWith(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w700,
                                                color: ThemeManager.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        AnimatedCircularChart(
                                          key: _chartKey,
                                          size: const Size(500.0, 300),
                                          initialChartData: data,
                                          holeRadius: 40,
                                          chartType: CircularChartType.Radial,
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left:
                                            Dimensions.PADDING_SIZE_SMALL * 1.4,
                                        right:
                                            Dimensions.PADDING_SIZE_SMALL * 1.2,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                height: Dimensions
                                                    .PADDING_SIZE_SMALL,
                                                width: Dimensions
                                                    .PADDING_SIZE_SMALL,
                                                margin: const EdgeInsets.only(
                                                    right: Dimensions
                                                            .PADDING_SIZE_EXTRA_SMALL *
                                                        1.1),
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: ThemeManager
                                                        .correctChart),
                                              ),
                                              Text(
                                                "Correct",
                                                style: interRegular.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                  fontWeight: FontWeight.w400,
                                                  color: ThemeManager.black,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: Dimensions
                                                        .PADDING_SIZE_EXTRA_SMALL *
                                                    1.1,
                                              ),
                                              Text(
                                                "($correctAnsPercentage%)",
                                                style: interRegular.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                  fontWeight: FontWeight.w600,
                                                  color: ThemeManager.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                height: Dimensions
                                                    .PADDING_SIZE_SMALL,
                                                width: Dimensions
                                                    .PADDING_SIZE_SMALL,
                                                margin: const EdgeInsets.only(
                                                    right: Dimensions
                                                            .PADDING_SIZE_EXTRA_SMALL *
                                                        1.1),
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: ThemeManager
                                                        .incorrectChart),
                                              ),
                                              Text(
                                                "Incorrect",
                                                style: interRegular.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                  fontWeight: FontWeight.w400,
                                                  color: ThemeManager.black,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: Dimensions
                                                        .PADDING_SIZE_EXTRA_SMALL *
                                                    1.1,
                                              ),
                                              Text(
                                                "($incorrectAnsPercentage%)",
                                                style: interRegular.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                  fontWeight: FontWeight.w600,
                                                  color: ThemeManager.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                height: Dimensions
                                                    .PADDING_SIZE_SMALL,
                                                width: Dimensions
                                                    .PADDING_SIZE_SMALL,
                                                margin: const EdgeInsets.only(
                                                    right: Dimensions
                                                            .PADDING_SIZE_EXTRA_SMALL *
                                                        1.1),
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color:
                                                        ThemeManager.skipChart),
                                              ),
                                              Text(
                                                "Skipped",
                                                style: interRegular.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                  fontWeight: FontWeight.w400,
                                                  color: ThemeManager.black,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: Dimensions
                                                        .PADDING_SIZE_EXTRA_SMALL *
                                                    1.1,
                                              ),
                                              Text(
                                                "($skippedAnsPercentage%)",
                                                style: interRegular.copyWith(
                                                  fontSize:
                                                      Dimensions.fontSizeSmall,
                                                  fontWeight: FontWeight.w600,
                                                  color: ThemeManager.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: Dimensions.PADDING_SIZE_DEFAULT,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left:
                                            Dimensions.PADDING_SIZE_SMALL * 1.4,
                                        right:
                                            Dimensions.PADDING_SIZE_SMALL * 1.2,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.only(
                                                left: Dimensions
                                                        .PADDING_SIZE_SMALL *
                                                    1.3,
                                                right: Dimensions
                                                    .PADDING_SIZE_SMALL,
                                                top: Dimensions
                                                    .PADDING_SIZE_SMALL,
                                                bottom: Dimensions
                                                        .PADDING_SIZE_SMALL *
                                                    1.1,
                                              ),
                                              decoration: BoxDecoration(
                                                  color: ThemeManager.white,
                                                  border: Border.all(
                                                      color: ThemeManager
                                                          .eduBorder,
                                                      width: 0.61),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      offset: const Offset(
                                                          0, 1.84208),
                                                      blurRadius: 18.2843,
                                                      spreadRadius: 0,
                                                      color: ThemeManager.black
                                                          .withOpacity(0.06),
                                                    ),
                                                  ]),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Accuracy",
                                                        style: interRegular
                                                            .copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeExtraSmall,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: ThemeManager
                                                              .textChart,
                                                        ),
                                                      ),
                                                      Text(
                                                        "$accuracyPercentage%",
                                                        style: interRegular
                                                            .copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeLarge,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: ThemeManager
                                                              .black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Container(
                                                    height: Dimensions
                                                            .PADDING_SIZE_EXTRA_LARGE *
                                                        1.1,
                                                    width: Dimensions
                                                            .PADDING_SIZE_EXTRA_LARGE *
                                                        1.1,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(7.37),
                                                        boxShadow: [
                                                          BoxShadow(
                                                              offset:
                                                                  const Offset(
                                                                      0,
                                                                      2.149095),
                                                              blurRadius:
                                                                  3.3771,
                                                              spreadRadius: 0,
                                                              color: ThemeManager
                                                                  .black
                                                                  .withOpacity(
                                                                      0.02)),
                                                        ],
                                                        gradient: LinearGradient(
                                                            colors: [
                                                              ThemeManager
                                                                  .edugradiet
                                                                  .withOpacity(
                                                                      0),
                                                              ThemeManager
                                                                  .edugradiet,
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight)),
                                                    child: SvgPicture.asset(
                                                      "assets/image/accuracy.svg",
                                                      color: ThemeManager
                                                                  .currentTheme ==
                                                              AppTheme.Dark
                                                          ? AppColors.white
                                                          : null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width:
                                                Dimensions.PADDING_SIZE_SMALL,
                                          ),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.only(
                                                left: Dimensions
                                                        .PADDING_SIZE_SMALL *
                                                    1.3,
                                                right: Dimensions
                                                    .PADDING_SIZE_SMALL,
                                                top: Dimensions
                                                    .PADDING_SIZE_SMALL,
                                                bottom: Dimensions
                                                        .PADDING_SIZE_SMALL *
                                                    1.1,
                                              ),
                                              decoration: BoxDecoration(
                                                  color: ThemeManager.white,
                                                  border: Border.all(
                                                      color: ThemeManager
                                                          .eduBorder,
                                                      width: 0.61),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      offset: const Offset(
                                                          0, 1.84208),
                                                      blurRadius: 18.2843,
                                                      spreadRadius: 0,
                                                      color: ThemeManager.black
                                                          .withOpacity(0.06),
                                                    ),
                                                  ]),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Time Taken",
                                                        style: interRegular
                                                            .copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeExtraSmall,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: ThemeManager
                                                              .textChart,
                                                        ),
                                                      ),
                                                      Text(
                                                        widget.reports?.Time ??
                                                            "",
                                                        style: interRegular
                                                            .copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeLarge,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: ThemeManager
                                                              .black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Container(
                                                    height: Dimensions
                                                            .PADDING_SIZE_EXTRA_LARGE *
                                                        1.1,
                                                    width: Dimensions
                                                            .PADDING_SIZE_EXTRA_LARGE *
                                                        1.1,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(7.37),
                                                        boxShadow: [
                                                          BoxShadow(
                                                              offset:
                                                                  const Offset(
                                                                      0,
                                                                      2.149095),
                                                              blurRadius:
                                                                  3.3771,
                                                              spreadRadius: 0,
                                                              color: ThemeManager
                                                                  .black
                                                                  .withOpacity(
                                                                      0.02)),
                                                        ],
                                                        gradient: LinearGradient(
                                                            colors: [
                                                              ThemeManager
                                                                  .edugradiet2
                                                                  .withOpacity(
                                                                      0),
                                                              ThemeManager
                                                                  .edugradiet2,
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight)),
                                                    child: SvgPicture.asset(
                                                        "assets/image/timeTaken.svg"),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: Dimensions.PADDING_SIZE_LARGE,
                                    ),
                                  ],
                                );
                              }
                              return ExpansionTile(
                                initiallyExpanded: false,
                                backgroundColor: ThemeManager.white,
                                collapsedIconColor: ThemeManager.black,
                                iconColor: ThemeManager.black,
                                tilePadding: const EdgeInsets.only(
                                    top: Dimensions.PADDING_SIZE_SMALL * 0.6,
                                    bottom: Dimensions.PADDING_SIZE_SMALL * 0.6,
                                    left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                    right: Dimensions.PADDING_SIZE_LARGE),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9.6),
                                    side: BorderSide(
                                        color: ThemeManager.mainBorder)),
                                collapsedBackgroundColor: ThemeManager.white,
                                collapsedShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9.6),
                                    side: BorderSide(
                                        color: ThemeManager.mainBorder)),
                                title: Row(
                                  children: [
                                    Container(
                                      height:
                                          Dimensions.PADDING_SIZE_EXTRA_LARGE *
                                              2,
                                      width:
                                          Dimensions.PADDING_SIZE_EXTRA_LARGE *
                                              2,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: ThemeManager
                                              .continueContainerOpacity,
                                          borderRadius:
                                              BorderRadius.circular(10.32)),
                                      child: SvgPicture.asset(
                                        "assets/image/award.svg",
                                        color: ThemeManager.currentTheme ==
                                                AppTheme.Dark
                                            ? AppColors.white
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: Dimensions.PADDING_SIZE_LARGE,
                                    ),
                                    Text(
                                      "EduMetrics",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        fontWeight: FontWeight.w600,
                                        color: ThemeManager.black,
                                      ),
                                    )
                                  ],
                                ),
                                children: [
                                  Stack(
                                    alignment: AlignmentDirectional.center,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Total Questions",
                                            style: interRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeDefault,
                                              fontWeight: FontWeight.w600,
                                              color: ThemeManager.textChart,
                                            ),
                                          ),
                                          Text(
                                            widget.reports?.question
                                                    .toString() ??
                                                "",
                                            style: interRegular.copyWith(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w700,
                                              color: ThemeManager.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      AnimatedCircularChart(
                                        key: _chartKey,
                                        size: const Size(500.0, 300),
                                        initialChartData: data,
                                        holeRadius: 40,
                                        chartType: CircularChartType.Radial,
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                      right:
                                          Dimensions.PADDING_SIZE_SMALL * 1.2,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  height: Dimensions
                                                      .PADDING_SIZE_SMALL,
                                                  width: Dimensions
                                                      .PADDING_SIZE_SMALL,
                                                  margin: const EdgeInsets.only(
                                                      right: Dimensions
                                                              .PADDING_SIZE_EXTRA_SMALL *
                                                          1.1),
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: ThemeManager
                                                          .correctChart),
                                                ),
                                                Text(
                                                  "Correct",
                                                  style: interRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeSmall,
                                                    fontWeight: FontWeight.w400,
                                                    color: ThemeManager.black,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: Dimensions
                                                          .PADDING_SIZE_EXTRA_SMALL *
                                                      1.1,
                                                ),
                                                Text(
                                                  "($correctAnsPercentage%)",
                                                  style: interRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeSmall,
                                                    fontWeight: FontWeight.w600,
                                                    color: ThemeManager.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  height: Dimensions
                                                      .PADDING_SIZE_SMALL,
                                                  width: Dimensions
                                                      .PADDING_SIZE_SMALL,
                                                  margin: const EdgeInsets.only(
                                                      right: Dimensions
                                                              .PADDING_SIZE_EXTRA_SMALL *
                                                          1.1),
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: ThemeManager
                                                          .incorrectChart),
                                                ),
                                                Text(
                                                  "Incorrect",
                                                  style: interRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeSmall,
                                                    fontWeight: FontWeight.w400,
                                                    color: ThemeManager.black,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: Dimensions
                                                          .PADDING_SIZE_EXTRA_SMALL *
                                                      1.1,
                                                ),
                                                Text(
                                                  "($incorrectAnsPercentage%)",
                                                  style: interRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeSmall,
                                                    fontWeight: FontWeight.w600,
                                                    color: ThemeManager.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                            height:
                                                Dimensions.PADDING_SIZE_SMALL),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              height:
                                                  Dimensions.PADDING_SIZE_SMALL,
                                              width:
                                                  Dimensions.PADDING_SIZE_SMALL,
                                              margin: const EdgeInsets.only(
                                                  right: Dimensions
                                                          .PADDING_SIZE_EXTRA_SMALL *
                                                      1.1),
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      ThemeManager.skipChart),
                                            ),
                                            Text(
                                              "Skipped",
                                              style: interRegular.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                                fontWeight: FontWeight.w400,
                                                color: ThemeManager.black,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: Dimensions
                                                      .PADDING_SIZE_EXTRA_SMALL *
                                                  1.1,
                                            ),
                                            Text(
                                              "($skippedAnsPercentage%)",
                                              style: interRegular.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                                fontWeight: FontWeight.w600,
                                                color: ThemeManager.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: Dimensions.PADDING_SIZE_DEFAULT,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                      right:
                                          Dimensions.PADDING_SIZE_SMALL * 1.2,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.only(
                                              left: Dimensions
                                                      .PADDING_SIZE_SMALL *
                                                  1.3,
                                              right:
                                                  Dimensions.PADDING_SIZE_SMALL,
                                              top:
                                                  Dimensions.PADDING_SIZE_SMALL,
                                              bottom: Dimensions
                                                      .PADDING_SIZE_SMALL *
                                                  1.1,
                                            ),
                                            decoration: BoxDecoration(
                                                color: ThemeManager.white,
                                                border: Border.all(
                                                    color:
                                                        ThemeManager.eduBorder,
                                                    width: 0.61),
                                                boxShadow: [
                                                  BoxShadow(
                                                    offset: const Offset(
                                                        0, 1.84208),
                                                    blurRadius: 18.2843,
                                                    spreadRadius: 0,
                                                    color: ThemeManager.black
                                                        .withOpacity(0.06),
                                                  ),
                                                ]),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Accuracy",
                                                      style:
                                                          interRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeExtraSmall,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: ThemeManager
                                                            .textChart,
                                                      ),
                                                    ),
                                                    Text(
                                                      "$accuracyPercentage%",
                                                      style:
                                                          interRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeLarge,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            ThemeManager.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  height: Dimensions
                                                          .PADDING_SIZE_EXTRA_LARGE *
                                                      1.1,
                                                  width: Dimensions
                                                          .PADDING_SIZE_EXTRA_LARGE *
                                                      1.1,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              7.37),
                                                      boxShadow: [
                                                        BoxShadow(
                                                            offset:
                                                                const Offset(0,
                                                                    2.149095),
                                                            blurRadius: 3.3771,
                                                            spreadRadius: 0,
                                                            color: ThemeManager
                                                                .black
                                                                .withOpacity(
                                                                    0.02)),
                                                      ],
                                                      gradient: LinearGradient(
                                                          colors: [
                                                            ThemeManager
                                                                .edugradiet
                                                                .withOpacity(0),
                                                            ThemeManager
                                                                .edugradiet,
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight)),
                                                  child: SvgPicture.asset(
                                                    "assets/image/accuracy.svg",
                                                    color: ThemeManager
                                                                .currentTheme ==
                                                            AppTheme.Dark
                                                        ? AppColors.white
                                                        : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: Dimensions.PADDING_SIZE_SMALL,
                                        ),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.only(
                                              left: Dimensions
                                                      .PADDING_SIZE_SMALL *
                                                  1.3,
                                              right:
                                                  Dimensions.PADDING_SIZE_SMALL,
                                              top:
                                                  Dimensions.PADDING_SIZE_SMALL,
                                              bottom: Dimensions
                                                      .PADDING_SIZE_SMALL *
                                                  1.1,
                                            ),
                                            decoration: BoxDecoration(
                                                color: ThemeManager.white,
                                                border: Border.all(
                                                    color:
                                                        ThemeManager.eduBorder,
                                                    width: 0.61),
                                                boxShadow: [
                                                  BoxShadow(
                                                    offset: const Offset(
                                                        0, 1.84208),
                                                    blurRadius: 18.2843,
                                                    spreadRadius: 0,
                                                    color: ThemeManager.black
                                                        .withOpacity(0.06),
                                                  ),
                                                ]),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Time Taken",
                                                      style:
                                                          interRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeExtraSmall,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: ThemeManager
                                                            .textChart,
                                                      ),
                                                    ),
                                                    Text(
                                                      widget.reports?.Time ??
                                                          "",
                                                      style:
                                                          interRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeLarge,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            ThemeManager.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  height: Dimensions
                                                          .PADDING_SIZE_EXTRA_LARGE *
                                                      1.1,
                                                  width: Dimensions
                                                          .PADDING_SIZE_EXTRA_LARGE *
                                                      1.1,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              7.37),
                                                      boxShadow: [
                                                        BoxShadow(
                                                            offset:
                                                                const Offset(0,
                                                                    2.149095),
                                                            blurRadius: 3.3771,
                                                            spreadRadius: 0,
                                                            color: ThemeManager
                                                                .black
                                                                .withOpacity(
                                                                    0.02)),
                                                      ],
                                                      gradient: LinearGradient(
                                                          colors: [
                                                            ThemeManager
                                                                .edugradiet2
                                                                .withOpacity(0),
                                                            ThemeManager
                                                                .edugradiet2,
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight)),
                                                  child: SvgPicture.asset(
                                                      "assets/image/timeTaken.svg"),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: Dimensions.PADDING_SIZE_LARGE,
                                  ),
                                ],
                              );
                            }),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_DEFAULT),

                            ExpansionTile(
                              initiallyExpanded: false,
                              backgroundColor: ThemeManager.white,
                              collapsedIconColor: ThemeManager.black,
                              iconColor: ThemeManager.black,
                              tilePadding: const EdgeInsets.only(
                                  top: Dimensions.PADDING_SIZE_SMALL * 0.6,
                                  bottom: Dimensions.PADDING_SIZE_SMALL * 0.6,
                                  left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                  right: Dimensions.PADDING_SIZE_LARGE),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9.6),
                                  side: BorderSide(
                                      color: ThemeManager.mainBorder)),
                              collapsedBackgroundColor: ThemeManager.white,
                              collapsedShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9.6),
                                  side: BorderSide(
                                      color: ThemeManager.mainBorder)),
                              title: Row(
                                children: [
                                  Container(
                                    height:
                                        Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                                    width:
                                        Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: ThemeManager
                                            .continueContainerOpacity,
                                        borderRadius:
                                            BorderRadius.circular(10.32)),
                                    child: SvgPicture.asset(
                                      "assets/image/award.svg",
                                      color: ThemeManager.currentTheme ==
                                              AppTheme.Dark
                                          ? AppColors.white
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_LARGE,
                                  ),
                                  Text(
                                    "Guess Analytics",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeManager.black,
                                    ),
                                  )
                                ],
                              ),
                              children: [
                                widget.reports?.wrongGuessCount == 0 &&
                                        widget.reports?.correctGuessCount == 0
                                    ? SizedBox(
                                        height: Dimensions
                                                .PADDING_SIZE_EXTRA_LARGE *
                                            6,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: Center(
                                          child: Text(
                                            "No Answer is Guessed ",
                                            style: interSemiBold.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeDefault,
                                              fontWeight: FontWeight.w400,
                                              color: ThemeManager.black,
                                            ),
                                          ),
                                        ))
                                    : Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Guessed Answers",
                                                style: interRegular.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeDefault,
                                                  fontWeight: FontWeight.w600,
                                                  color: ThemeManager.textChart,
                                                ),
                                              ),
                                              Text(
                                                widget.reports
                                                        ?.guessedAnswersCount
                                                        .toString() ??
                                                    "",
                                                style: interRegular.copyWith(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w700,
                                                  color: ThemeManager.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          AnimatedCircularChart(
                                            key: _guessedchartKey,
                                            size: const Size(500.0, 300),
                                            initialChartData: datax,
                                            holeRadius: 30,
                                            chartType: CircularChartType.Radial,
                                          ),
                                        ],
                                      ),
                                const SizedBox(
                                  height: Dimensions.PADDING_SIZE_DEFAULT,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                    right: Dimensions.PADDING_SIZE_SMALL * 1.2,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.only(
                                            left:
                                                Dimensions.PADDING_SIZE_SMALL *
                                                    1.3,
                                            right:
                                                Dimensions.PADDING_SIZE_SMALL,
                                            top: Dimensions.PADDING_SIZE_SMALL,
                                            bottom:
                                                Dimensions.PADDING_SIZE_SMALL *
                                                    1.1,
                                          ),
                                          decoration: BoxDecoration(
                                              color: ThemeManager.white,
                                              border: Border.all(
                                                  color: ThemeManager.eduBorder,
                                                  width: 0.61),
                                              boxShadow: [
                                                BoxShadow(
                                                  offset:
                                                      const Offset(0, 1.84208),
                                                  blurRadius: 18.2843,
                                                  spreadRadius: 0,
                                                  color: ThemeManager.black
                                                      .withOpacity(0.06),
                                                ),
                                              ]),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Correct Answer",
                                                    style:
                                                        interRegular.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeExtraSmall,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: ThemeManager
                                                          .textChart,
                                                    ),
                                                  ),
                                                  Text(
                                                    "${widget.reports?.correctGuessCount}",
                                                    style:
                                                        interRegular.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeLarge,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: ThemeManager.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                height: Dimensions
                                                        .PADDING_SIZE_EXTRA_LARGE *
                                                    1.1,
                                                width: Dimensions
                                                        .PADDING_SIZE_EXTRA_LARGE *
                                                    1.1,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.37),
                                                    boxShadow: [
                                                      BoxShadow(
                                                          offset: const Offset(
                                                              0, 2.149095),
                                                          blurRadius: 3.3771,
                                                          spreadRadius: 0,
                                                          color: ThemeManager
                                                              .black
                                                              .withOpacity(
                                                                  0.02)),
                                                    ],
                                                    gradient: LinearGradient(
                                                        colors: [
                                                          ThemeManager
                                                              .edugradiet2
                                                              .withOpacity(0),
                                                          ThemeManager
                                                              .edugradiet2,
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight)),
                                                child: SvgPicture.asset(
                                                  "assets/image/accuracy.svg",
                                                  color: ThemeManager
                                                              .currentTheme ==
                                                          AppTheme.Dark
                                                      ? AppColors.black
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: Dimensions.PADDING_SIZE_SMALL,
                                      ),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.only(
                                            left:
                                                Dimensions.PADDING_SIZE_SMALL *
                                                    1.3,
                                            right:
                                                Dimensions.PADDING_SIZE_SMALL,
                                            top: Dimensions.PADDING_SIZE_SMALL,
                                            bottom:
                                                Dimensions.PADDING_SIZE_SMALL *
                                                    1.1,
                                          ),
                                          decoration: BoxDecoration(
                                              color: ThemeManager.white,
                                              border: Border.all(
                                                  color: ThemeManager.eduBorder,
                                                  width: 0.61),
                                              boxShadow: [
                                                BoxShadow(
                                                  offset:
                                                      const Offset(0, 1.84208),
                                                  blurRadius: 18.2843,
                                                  spreadRadius: 0,
                                                  color: ThemeManager.black
                                                      .withOpacity(0.06),
                                                ),
                                              ]),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Incorrect Answer",
                                                    style:
                                                        interRegular.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeExtraSmall,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: ThemeManager
                                                          .textChart,
                                                    ),
                                                  ),
                                                  Text(
                                                    "${widget.reports?.wrongGuessCount}",
                                                    style:
                                                        interRegular.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeLarge,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: ThemeManager.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                height: Dimensions
                                                        .PADDING_SIZE_EXTRA_LARGE *
                                                    1.1,
                                                width: Dimensions
                                                        .PADDING_SIZE_EXTRA_LARGE *
                                                    1.1,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.37),
                                                    boxShadow: [
                                                      BoxShadow(
                                                          offset: const Offset(
                                                              0, 2.149095),
                                                          blurRadius: 3.3771,
                                                          spreadRadius: 0,
                                                          color: ThemeManager
                                                              .black
                                                              .withOpacity(
                                                                  0.02)),
                                                    ],
                                                    gradient: LinearGradient(
                                                        colors: [
                                                          ThemeManager
                                                              .edugradiet3
                                                              .withOpacity(0),
                                                          ThemeManager
                                                              .edugradiet3,
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight)),
                                                child: Transform.flip(
                                                    flipY: true,
                                                    child: SvgPicture.asset(
                                                      "assets/image/accuracy.svg",
                                                      color: ThemeManager
                                                                  .currentTheme ==
                                                              AppTheme.Dark
                                                          ? AppColors.black
                                                          : null,
                                                    )),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: Dimensions.PADDING_SIZE_LARGE,
                                ),
                              ],
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_DEFAULT),

                            ExpansionTile(
                              initiallyExpanded: false,
                              backgroundColor: ThemeManager.white,
                              collapsedIconColor: ThemeManager.black,
                              iconColor: ThemeManager.black,
                              tilePadding: const EdgeInsets.only(
                                  top: Dimensions.PADDING_SIZE_SMALL * 0.6,
                                  bottom: Dimensions.PADDING_SIZE_SMALL * 0.6,
                                  left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                  right: Dimensions.PADDING_SIZE_LARGE),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9.6),
                                  side: BorderSide(
                                      color: ThemeManager.mainBorder)),
                              collapsedBackgroundColor: ThemeManager.white,
                              collapsedShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9.6),
                                  side: BorderSide(
                                      color: ThemeManager.mainBorder)),
                              title: Row(
                                children: [
                                  Container(
                                    height:
                                        Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                                    width:
                                        Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: ThemeManager
                                            .continueContainerOpacity,
                                        borderRadius:
                                            BorderRadius.circular(10.32)),
                                    child: SvgPicture.asset(
                                      "assets/image/award.svg",
                                      color: ThemeManager.currentTheme ==
                                              AppTheme.Dark
                                          ? AppColors.white
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: Dimensions.PADDING_SIZE_LARGE,
                                  ),
                                  Text(
                                    "Answer Evolve",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeManager.black,
                                    ),
                                  )
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: Dimensions.PADDING_SIZE_SMALL * 1.3,
                                    right: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.only(
                                          left: Dimensions.PADDING_SIZE_SMALL *
                                              1.6,
                                          right: Dimensions.PADDING_SIZE_SMALL *
                                              1.2,
                                          top: Dimensions.PADDING_SIZE_SMALL *
                                              1.2,
                                          bottom:
                                              Dimensions.PADDING_SIZE_SMALL *
                                                  1.3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ThemeManager.white,
                                          boxShadow: [
                                            ThemeManager.currentTheme ==
                                                    AppTheme.Dark
                                                ? const BoxShadow()
                                                : BoxShadow(
                                                    offset:
                                                        const Offset(0, 2.3074),
                                                    blurRadius: 22.903,
                                                    spreadRadius: 0,
                                                    color: ThemeManager.black
                                                        .withOpacity(0.06)),
                                          ],
                                          border: GradientBoxBorder(
                                            gradient: LinearGradient(colors: [
                                              ThemeManager.evolveGreen,
                                              ThemeManager.evolveRed
                                            ]),
                                            width: 0.77,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Correct to Incorrect",
                                                  style: interRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeExtraSmall,
                                                    fontWeight: FontWeight.w400,
                                                    color:
                                                        ThemeManager.textChart,
                                                  ),
                                                ),
                                                Text(
                                                  "${widget.reports?.correct_incorrect}",
                                                  style: interRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeLarge,
                                                    fontWeight: FontWeight.w600,
                                                    color: ThemeManager.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              height: Dimensions
                                                      .PADDING_SIZE_EXTRA_LARGE *
                                                  1.1,
                                              width: Dimensions
                                                      .PADDING_SIZE_EXTRA_LARGE *
                                                  1.1,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.37),
                                                  boxShadow: [
                                                    BoxShadow(
                                                        offset: const Offset(
                                                            0, 2.149095),
                                                        blurRadius: 3.3771,
                                                        spreadRadius: 0,
                                                        color: ThemeManager
                                                            .black
                                                            .withOpacity(0.02)),
                                                  ],
                                                  gradient: LinearGradient(
                                                      colors: [
                                                        ThemeManager.edugradiet3
                                                            .withOpacity(0),
                                                        ThemeManager
                                                            .edugradiet3,
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment
                                                          .bottomRight)),
                                              child: Transform.flip(
                                                  flipY: true,
                                                  child: SvgPicture.asset(
                                                    "assets/image/accuracy.svg",
                                                    color: ThemeManager
                                                                .currentTheme ==
                                                            AppTheme.Dark
                                                        ? AppColors.black
                                                        : null,
                                                  )),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: Dimensions.PADDING_SIZE_SMALL,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: Dimensions.PADDING_SIZE_SMALL * 1.3,
                                    right: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.only(
                                          left: Dimensions.PADDING_SIZE_SMALL *
                                              1.6,
                                          right: Dimensions.PADDING_SIZE_SMALL *
                                              1.2,
                                          top: Dimensions.PADDING_SIZE_SMALL *
                                              1.2,
                                          bottom:
                                              Dimensions.PADDING_SIZE_SMALL *
                                                  1.3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ThemeManager.white,
                                          boxShadow: [
                                            ThemeManager.currentTheme ==
                                                    AppTheme.Dark
                                                ? const BoxShadow()
                                                : BoxShadow(
                                                    offset:
                                                        const Offset(0, 2.3074),
                                                    blurRadius: 22.903,
                                                    spreadRadius: 0,
                                                    color: ThemeManager.black
                                                        .withOpacity(0.06)),
                                          ],
                                          border: GradientBoxBorder(
                                            gradient: LinearGradient(colors: [
                                              ThemeManager.evolveRed,
                                              ThemeManager.evolveGreen
                                            ]),
                                            width: 0.77,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Incorrect to Correct",
                                                  style: interRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeExtraSmall,
                                                    fontWeight: FontWeight.w400,
                                                    color:
                                                        ThemeManager.textChart,
                                                  ),
                                                ),
                                                Text(
                                                  "${widget.reports?.incorrect_correct}",
                                                  style: interRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeLarge,
                                                    fontWeight: FontWeight.w600,
                                                    color: ThemeManager.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              height: Dimensions
                                                      .PADDING_SIZE_EXTRA_LARGE *
                                                  1.1,
                                              width: Dimensions
                                                      .PADDING_SIZE_EXTRA_LARGE *
                                                  1.1,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.37),
                                                  boxShadow: [
                                                    BoxShadow(
                                                        offset: const Offset(
                                                            0, 2.149095),
                                                        blurRadius: 3.3771,
                                                        spreadRadius: 0,
                                                        color: ThemeManager
                                                            .black
                                                            .withOpacity(0.02)),
                                                  ],
                                                  gradient: LinearGradient(
                                                      colors: [
                                                        ThemeManager.edugradiet2
                                                            .withOpacity(0),
                                                        ThemeManager
                                                            .edugradiet2,
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment
                                                          .bottomRight)),
                                              child: SvgPicture.asset(
                                                "assets/image/accuracy.svg",
                                                color:
                                                    ThemeManager.currentTheme ==
                                                            AppTheme.Dark
                                                        ? AppColors.black
                                                        : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: Dimensions.PADDING_SIZE_SMALL,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: Dimensions.PADDING_SIZE_SMALL * 1.3,
                                    right: Dimensions.PADDING_SIZE_SMALL * 1.4,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.only(
                                          left: Dimensions.PADDING_SIZE_SMALL *
                                              1.6,
                                          right: Dimensions.PADDING_SIZE_SMALL *
                                              1.2,
                                          top: Dimensions.PADDING_SIZE_SMALL *
                                              1.2,
                                          bottom:
                                              Dimensions.PADDING_SIZE_SMALL *
                                                  1.3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ThemeManager.white,
                                          boxShadow: [
                                            ThemeManager.currentTheme ==
                                                    AppTheme.Dark
                                                ? const BoxShadow()
                                                : BoxShadow(
                                                    offset:
                                                        const Offset(0, 2.3074),
                                                    blurRadius: 22.903,
                                                    spreadRadius: 0,
                                                    color: ThemeManager.black
                                                        .withOpacity(0.06)),
                                          ],
                                          border: Border.all(
                                            color: ThemeManager.evolveYellow,
                                            width: 0.77,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Incorrect to Incorrect",
                                                  style: interRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeExtraSmall,
                                                    fontWeight: FontWeight.w400,
                                                    color:
                                                        ThemeManager.textChart,
                                                  ),
                                                ),
                                                Text(
                                                  "${widget.reports?.incorrect_incorres}",
                                                  style: interRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeLarge,
                                                    fontWeight: FontWeight.w600,
                                                    color: ThemeManager.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              height: Dimensions
                                                      .PADDING_SIZE_EXTRA_LARGE *
                                                  1.1,
                                              width: Dimensions
                                                      .PADDING_SIZE_EXTRA_LARGE *
                                                  1.1,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.37),
                                                  boxShadow: [
                                                    BoxShadow(
                                                        offset: const Offset(
                                                            0, 2.149095),
                                                        blurRadius: 3.3771,
                                                        spreadRadius: 0,
                                                        color: ThemeManager
                                                            .black
                                                            .withOpacity(0.02)),
                                                  ],
                                                  gradient: LinearGradient(
                                                      colors: [
                                                        ThemeManager
                                                            .evolveYellow
                                                            .withOpacity(0.36),
                                                        ThemeManager
                                                            .evolveYellow,
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment
                                                          .bottomRight)),
                                              child: SvgPicture.asset(
                                                "assets/image/accuracy2.svg",
                                                color:
                                                    ThemeManager.currentTheme ==
                                                            AppTheme.Dark
                                                        ? AppColors.black
                                                        : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: Dimensions.PADDING_SIZE_DEFAULT * 2,
                                ),
                              ],
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_DEFAULT),
                            // ///Test information
                            // Text("Test information",
                            //   style: interSemiBold.copyWith(
                            //     fontSize: Dimensions.fontSizeDefault,
                            //     fontWeight: FontWeight.w400,
                            //     color: ThemeManager.black,
                            //   ),),
                            // const SizedBox(height: Dimensions.PADDING_SIZE_LARGE),
                            // Row(
                            //   children: [
                            //     //Candidates
                            //     Container(
                            //       height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.8,
                            //       width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 3.4,
                            //       color: ThemeManager.lightgrey,
                            //       child: Column(
                            //         mainAxisAlignment: MainAxisAlignment.center,
                            //         children: [
                            //           Text(widget.reports?.candidate.toString()??"",
                            //             style: interRegular.copyWith(
                            //               fontSize: Dimensions.fontSizeSmall,
                            //               fontWeight: FontWeight.w400,
                            //               color: Theme.of(context).primaryColor,
                            //             ),),
                            //           const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                            //           Text("Candidates",
                            //             style: interRegular.copyWith(
                            //               fontSize: Dimensions.fontSizeSmall,
                            //               fontWeight: FontWeight.w400,
                            //               color: Theme.of(context).hintColor,
                            //             ),),
                            //         ],
                            //       ),
                            //     ),
                            //     Container(
                            //       height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.8,
                            //       width: 1,
                            //       color: ThemeManager.lightBlue,
                            //     ),
                            //
                            //     //Questions
                            //     Container(
                            //       height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.8,
                            //       width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 3,
                            //       color: ThemeManager.lightgrey,
                            //       child: Column(
                            //         mainAxisAlignment: MainAxisAlignment.center,
                            //         children: [
                            //           Text(widget.reports?.question.toString()??"",
                            //             style: interRegular.copyWith(
                            //               fontSize: Dimensions.fontSizeSmall,
                            //               fontWeight: FontWeight.w400,
                            //               color: Theme.of(context).primaryColor,
                            //             ),),
                            //           const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                            //           Text("Questions",
                            //             style: interRegular.copyWith(
                            //               fontSize: Dimensions.fontSizeSmall,
                            //               fontWeight: FontWeight.w400,
                            //               color: Theme.of(context).hintColor,
                            //             ),),
                            //         ],
                            //       ),
                            //     ),
                            //     Container(
                            //       height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.8,
                            //       width: 1,
                            //       color: ThemeManager.lightBlue,
                            //     ),
                            //
                            //     //Marks
                            //     Container(
                            //       height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.8,
                            //       width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 3,
                            //       color: ThemeManager.lightgrey,
                            //       child: Column(
                            //         mainAxisAlignment: MainAxisAlignment.center,
                            //         children: [
                            //           Text(widget.reports?.mark.toString()??"",
                            //             style: interRegular.copyWith(
                            //               fontSize: Dimensions.fontSizeSmall,
                            //               fontWeight: FontWeight.w400,
                            //               color: Theme.of(context).primaryColor,
                            //             ),),
                            //           const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                            //           Text("Marks",
                            //             style: interRegular.copyWith(
                            //               fontSize: Dimensions.fontSizeSmall,
                            //               fontWeight: FontWeight.w400,
                            //               color: Theme.of(context).hintColor,
                            //             ),),
                            //         ],
                            //       ),
                            //     ),
                            //     Container(
                            //       height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.8,
                            //       width: 1,
                            //       color: ThemeManager.lightBlue,
                            //     ),
                            //
                            //     //Duration
                            //     Container(
                            //       height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.8,
                            //       width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 3.2,
                            //       color: ThemeManager.lightgrey,
                            //       child: Column(
                            //         mainAxisAlignment: MainAxisAlignment.center,
                            //         children: [
                            //           Text(widget.reports?.duration.toString()??"",
                            //             style: interRegular.copyWith(
                            //               fontSize: Dimensions.fontSizeSmall,
                            //               fontWeight: FontWeight.w400,
                            //               color: Theme.of(context).primaryColor,
                            //             ),),
                            //           const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                            //           Text("Duration",
                            //             style: interRegular.copyWith(
                            //               fontSize: Dimensions.fontSizeSmall,
                            //               fontWeight: FontWeight.w400,
                            //               color: Theme.of(context).hintColor,
                            //             ),),
                            //         ],
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            // const SizedBox(height: Dimensions.PADDING_SIZE_LARGE * 1.1),
                            //
                            // ///Candidates statics
                            // ExpansionTile(
                            //   initiallyExpanded: false,
                            //   collapsedIconColor: Theme.of(context).primaryColor,
                            //   title: Text(
                            //     "EduMetrics",
                            //     style: interSemiBold.copyWith(
                            //       fontSize: Dimensions.fontSizeDefault,
                            //       fontWeight: FontWeight.w400,
                            //       color: ThemeManager.black,
                            //     ),
                            //   ),
                            //   children: [
                            //     const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
                            //     Row(
                            //       mainAxisAlignment: MainAxisAlignment.center,
                            //       children: [
                            //         // Candidates
                            //         Container(
                            //           height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.8,
                            //           width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 4,
                            //           color: ThemeManager.lightgrey,
                            //           child: Column(
                            //             mainAxisAlignment: MainAxisAlignment.center,
                            //             children: [
                            //               Text(
                            //                 widget.reports?.question.toString() ?? "",
                            //                 style: interRegular.copyWith(
                            //                   fontSize: Dimensions.fontSizeSmall,
                            //                   fontWeight: FontWeight.w400,
                            //                   color: Theme.of(context).primaryColor,
                            //                 ),
                            //               ),
                            //               const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                            //               Text(
                            //                 "Question",
                            //                 style: interRegular.copyWith(
                            //                   fontSize: Dimensions.fontSizeSmall,
                            //                   fontWeight: FontWeight.w400,
                            //                   color: Theme.of(context).hintColor,
                            //                 ),
                            //               ),
                            //             ],
                            //           ),
                            //         ),
                            //         Container(
                            //           height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.8,
                            //           width: 1,
                            //           color: ThemeManager.lightBlue,
                            //         ),
                            //
                            //         // Time on questions
                            //         Container(
                            //           height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.8,
                            //           width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 6,
                            //           color: ThemeManager.lightgrey,
                            //           child: Column(
                            //             mainAxisAlignment: MainAxisAlignment.center,
                            //             children: [
                            //               Text(
                            //                 widget.reports?.Time.toString() ?? "",
                            //                 style: interRegular.copyWith(
                            //                   fontSize: Dimensions.fontSizeSmall,
                            //                   fontWeight: FontWeight.w400,
                            //                   color: Theme.of(context).primaryColor,
                            //                 ),
                            //               ),
                            //               const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                            //               Text(
                            //                 "Total Time",
                            //                 style: interRegular.copyWith(
                            //                   fontSize: Dimensions.fontSizeSmall,
                            //                   fontWeight: FontWeight.w400,
                            //                   color: Theme.of(context).hintColor,
                            //                 ),
                            //               ),
                            //             ],
                            //           ),
                            //         ),
                            //         Container(
                            //           height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.8,
                            //           width: 1,
                            //           color: ThemeManager.lightBlue,
                            //         ),
                            //       ],
                            //     ),
                            //     const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
                            //     ///Graph
                            //     Container(
                            //       height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 15.5,
                            //       width: MediaQuery.of(context).size.width,
                            //       color: ThemeManager.lightgrey,
                            //       child: Column(
                            //         children: [
                            //           //graph
                            //           Row(
                            //             children: [
                            //               AnimatedCircularChart(
                            //                 key: _chartKey,
                            //                 size: const Size(230.0, 240.0),
                            //                 initialChartData: data,
                            //                 chartType: CircularChartType.Pie,
                            //               ),
                            //               Column(
                            //                 crossAxisAlignment: CrossAxisAlignment.start,
                            //                 children: [
                            //                   Row(
                            //                     children: [
                            //                       Container(
                            //                         height: Dimensions.PADDING_SIZE_SMALL,
                            //                         width: Dimensions.PADDING_SIZE_SMALL,
                            //                         decoration: BoxDecoration(
                            //                             borderRadius: BorderRadius.circular(50),
                            //                             color: ThemeManager.greenSuccess
                            //                         ),
                            //                       ),
                            //                       const SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                            //                       Text("Correct",
                            //                         style: interSemiBold.copyWith(
                            //                           fontSize: Dimensions.fontSizeDefault,
                            //                           fontWeight: FontWeight.w400,
                            //                           color: ThemeManager.black,
                            //                         ),),
                            //                     ],
                            //                   ),
                            //                   const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                            //                   Row(
                            //                     children: [
                            //                       Container(
                            //                         height: Dimensions.PADDING_SIZE_SMALL,
                            //                         width: Dimensions.PADDING_SIZE_SMALL,
                            //                         decoration: BoxDecoration(
                            //                           borderRadius: BorderRadius.circular(50),
                            //                           color: ThemeManager.redAlert,
                            //                         ),
                            //                       ),
                            //                       const SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                            //                       Text("Incorrect",
                            //                         style: interSemiBold.copyWith(
                            //                           fontSize: Dimensions.fontSizeDefault,
                            //                           fontWeight: FontWeight.w400,
                            //                           color: ThemeManager.black,
                            //                         ),),
                            //                     ],
                            //                   ),
                            //                   const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                            //                   Row(
                            //                     children: [
                            //                       Container(
                            //                         height: Dimensions.PADDING_SIZE_SMALL,
                            //                         width: Dimensions.PADDING_SIZE_SMALL,
                            //                         decoration: BoxDecoration(
                            //                           borderRadius: BorderRadius.circular(50),
                            //                           color: const Color(0xFFFF9F59),
                            //                         ),
                            //                       ),
                            //                       const SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                            //                       Text("Skipped",
                            //                         style: interSemiBold.copyWith(
                            //                           fontSize: Dimensions.fontSizeDefault,
                            //                           fontWeight: FontWeight.w400,
                            //                           color: ThemeManager.black,
                            //                         ),),
                            //                     ],
                            //                   ),
                            //                   const SizedBox(height: Dimensions.PADDING_SIZE_SMALL)
                            //                 ],
                            //               ),
                            //             ],
                            //           ),
                            //
                            //           //Correct answer, Incorrect answer and Skipped answer
                            //           Row(
                            //             mainAxisAlignment: MainAxisAlignment.center,
                            //             children: [
                            //               //Correct answer
                            //               Container(
                            //                 height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.8,
                            //                 width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 4.2,
                            //                 color: ThemeManager.lightgrey,
                            //                 child: Column(
                            //                   mainAxisAlignment: MainAxisAlignment.center,
                            //                   children: [
                            //                     Text("$correctAnsPercentage%",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color: Theme.of(context).primaryColor,
                            //                       ),),
                            //                     const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                            //                     Text("Correct answer",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color: Theme.of(context).hintColor,
                            //                       ),
                            //                       textAlign: TextAlign.center,
                            //                     ),
                            //                   ],
                            //                 ),
                            //               ),
                            //               Container(
                            //                 height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 1.8,
                            //                 width: 1,
                            //                 color: ThemeManager.lightBlue,
                            //               ),
                            //
                            //               //Incorrect answer
                            //               Container(
                            //                 height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.8,
                            //                 width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 4.2,
                            //                 color: ThemeManager.lightgrey,
                            //                 child: Column(
                            //                   mainAxisAlignment: MainAxisAlignment.center,
                            //                   children: [
                            //                     Text("$incorrectAnsPercentage%",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color: Theme.of(context).primaryColor,
                            //                       ),),
                            //                     const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                            //                     Text("Incorrect answer",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color: Theme.of(context).hintColor,
                            //                       ),
                            //                       textAlign: TextAlign.center,
                            //                     ),
                            //                   ],
                            //                 ),
                            //               ),
                            //               Container(
                            //                 height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 1.8,
                            //                 width: 1,
                            //                 color: ThemeManager.lightBlue,
                            //               ),
                            //
                            //               //Skipped answer
                            //               Container(
                            //                 height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.8,
                            //                 width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 4.2,
                            //                 color: ThemeManager.lightgrey,
                            //                 child: Column(
                            //                   mainAxisAlignment: MainAxisAlignment.center,
                            //                   children: [
                            //                     Text("$skippedAnsPercentage%",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color: Theme.of(context).primaryColor,
                            //                       ),),
                            //                     const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                            //                     Text("Skipped answer",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color: Theme.of(context).hintColor,
                            //                       ),
                            //                       textAlign: TextAlign.center,
                            //                     ),
                            //                   ],
                            //                 ),
                            //               ),
                            //             ],
                            //           ),
                            //           const SizedBox(height: Dimensions.PADDING_SIZE_LARGE* 1.3),
                            //
                            //           //Accuracy,Correct,Incorrect and Skipped
                            //           Row(
                            //             mainAxisAlignment: MainAxisAlignment.center,
                            //             children: [
                            //               //Accuracy
                            //               Container(
                            //                 height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                            //                 width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 3.4,
                            //                 color: ThemeManager.lightgrey,
                            //                 child: Column(
                            //                   mainAxisAlignment: MainAxisAlignment.center,
                            //                   children: [
                            //                     Text("$accuracyPercentage%",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color: Theme.of(context).primaryColor,
                            //                       ),),
                            //                     const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                            //                     Text("Accuracy",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color: Theme.of(context).hintColor,
                            //                       ),),
                            //                   ],
                            //                 ),
                            //               ),
                            //               Container(
                            //                 height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 1.8,
                            //                 width: 1,
                            //                 color: ThemeManager.lightBlue,
                            //               ),
                            //
                            //               //Correct
                            //               InkWell(
                            //                 onTap:(){
                            //                   _getSolutionReport(widget.userexamId??"","View correct answer");
                            //                 },
                            //                 child: Container(
                            //                   height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                            //                   width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 3,
                            //                   color: ThemeManager.lightgrey,
                            //                   child: Column(
                            //                     mainAxisAlignment: MainAxisAlignment.center,
                            //                     children: [
                            //                       Text(widget.reports?.correctAnswers.toString()??"",
                            //                         style: interRegular.copyWith(
                            //                           fontSize: Dimensions.fontSizeSmall,
                            //                           fontWeight: FontWeight.w400,
                            //                           color: Theme.of(context).primaryColor,
                            //                         ),),
                            //                       const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                            //                       Text("Correct",
                            //                         style: interRegular.copyWith(
                            //                           fontSize: Dimensions.fontSizeSmall,
                            //                           fontWeight: FontWeight.w400,
                            //                           color: Theme.of(context).hintColor,
                            //                         ),),
                            //                     ],
                            //                   ),
                            //                 ),
                            //               ),
                            //               Container(
                            //                 height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 1.8,
                            //                 width: 1,
                            //                 color: ThemeManager.lightBlue,
                            //               ),
                            //
                            //               //Incorrect
                            //               InkWell(
                            //                 onTap:(){
                            //                   _getSolutionReport(widget.userexamId??"","View incorrect answer");
                            //                 },
                            //                 child: Container(
                            //                   height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                            //                   width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 3,
                            //                   color: ThemeManager.lightgrey,
                            //                   child: Column(
                            //                     mainAxisAlignment: MainAxisAlignment.center,
                            //                     children: [
                            //                       Text(widget.reports?.incorrectAnswers.toString()??"",
                            //                         style: interRegular.copyWith(
                            //                           fontSize: Dimensions.fontSizeSmall,
                            //                           fontWeight: FontWeight.w400,
                            //                           color: Theme.of(context).primaryColor,
                            //                         ),),
                            //                       const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                            //                       Text("Incorrect",
                            //                         style: interRegular.copyWith(
                            //                           fontSize: Dimensions.fontSizeSmall,
                            //                           fontWeight: FontWeight.w400,
                            //                           color: Theme.of(context).hintColor,
                            //                         ),),
                            //                     ],
                            //                   ),
                            //                 ),
                            //               ),
                            //               Container(
                            //                 height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 1.8,
                            //                 width: 1,
                            //                 color: ThemeManager.lightBlue,
                            //               ),
                            //
                            //               //Skipped
                            //               Container(
                            //                 height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                            //                 width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 3,
                            //                 color: ThemeManager.lightgrey,
                            //                 child: Column(
                            //                   mainAxisAlignment: MainAxisAlignment.center,
                            //                   children: [
                            //                     Text(widget.reports?.skippedAnswers.toString()??"",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color: Theme.of(context).primaryColor,
                            //                       ),),
                            //                     const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                            //                     Text("Skipped",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color: Theme.of(context).hintColor,
                            //                       ),),
                            //                   ],
                            //                 ),
                            //               ),
                            //             ],
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //     // const SizedBox(height: Dimensions.PADDING_SIZE_LARGE),
                            //   ],
                            // ),
                            // // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
                            // ExpansionTile(
                            //   initiallyExpanded: false,
                            //   collapsedIconColor: Theme.of(context).primaryColor,
                            //   title: Text(
                            //     "Guess Analytics",
                            //     style: interSemiBold.copyWith(
                            //       fontSize: Dimensions.fontSizeDefault,
                            //       fontWeight: FontWeight.w400,
                            //       color: ThemeManager.black,
                            //     ),
                            //   ),
                            //   children: [
                            //     const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
                            //     widget.reports?.wrongGuessCount == 0 &&
                            //         widget.reports?.correctGuessCount == 0
                            //         ?
                            //
                            //     ///Graph
                            //
                            //     Container(
                            //         height:
                            //         Dimensions.PADDING_SIZE_EXTRA_LARGE * 10.3,
                            //         width: MediaQuery.of(context).size.width,
                            //         child: Center(
                            //           child: Text(
                            //             "No Answer is Guessed ",
                            //             style: interSemiBold.copyWith(
                            //               fontSize: Dimensions.fontSizeDefault,
                            //               fontWeight: FontWeight.w400,
                            //               color: ThemeManager.primaryColor,
                            //             ),
                            //           ),
                            //         ))
                            //         : Container(
                            //       height:
                            //       Dimensions.PADDING_SIZE_EXTRA_LARGE * 14.3,
                            //       width: MediaQuery.of(context).size.width,
                            //       color: ThemeManager.lightgrey,
                            //       child: Column(
                            //         children: [
                            //           //graph
                            //           Row(
                            //             children: [
                            //               AnimatedCircularChart(
                            //                 key: _guessedchartKey,
                            //                 size: const Size(230.0, 240.0),
                            //                 initialChartData: datax,
                            //                 chartType: CircularChartType.Pie,
                            //               ),
                            //               Column(
                            //                 crossAxisAlignment:
                            //                 CrossAxisAlignment.start,
                            //                 children: [
                            //                   Row(
                            //                     children: [
                            //                       Container(
                            //                         height: Dimensions
                            //                             .PADDING_SIZE_SMALL,
                            //                         width: Dimensions
                            //                             .PADDING_SIZE_SMALL,
                            //                         decoration: BoxDecoration(
                            //                             borderRadius:
                            //                             BorderRadius.circular(
                            //                                 50),
                            //                             color: ThemeManager
                            //                                 .greenSuccess),
                            //                       ),
                            //                       const SizedBox(
                            //                           width: Dimensions
                            //                               .PADDING_SIZE_SMALL),
                            //                       Text(
                            //                         "Correct",
                            //                         style: interSemiBold.copyWith(
                            //                           fontSize: Dimensions
                            //                               .fontSizeDefault,
                            //                           fontWeight: FontWeight.w400,
                            //                           color: ThemeManager.black,
                            //                         ),
                            //                       ),
                            //                     ],
                            //                   ),
                            //                   const SizedBox(
                            //                       height: Dimensions
                            //                           .PADDING_SIZE_SMALL),
                            //                   Row(
                            //                     children: [
                            //                       Container(
                            //                         height: Dimensions
                            //                             .PADDING_SIZE_SMALL,
                            //                         width: Dimensions
                            //                             .PADDING_SIZE_SMALL,
                            //                         decoration: BoxDecoration(
                            //                           borderRadius:
                            //                           BorderRadius.circular(
                            //                               50),
                            //                           color: ThemeManager.redAlert,
                            //                         ),
                            //                       ),
                            //                       const SizedBox(
                            //                           width: Dimensions
                            //                               .PADDING_SIZE_SMALL),
                            //                       Text(
                            //                         "Incorrect",
                            //                         style: interSemiBold.copyWith(
                            //                           fontSize: Dimensions
                            //                               .fontSizeDefault,
                            //                           fontWeight: FontWeight.w400,
                            //                           color: ThemeManager.black,
                            //                         ),
                            //                       ),
                            //                     ],
                            //                   ),
                            //                   const SizedBox(
                            //                       height: Dimensions
                            //                           .PADDING_SIZE_SMALL),
                            //                 ],
                            //               ),
                            //             ],
                            //           ),
                            //
                            //           Row(
                            //             mainAxisAlignment: MainAxisAlignment.center,
                            //             children: [
                            //               // total
                            //               Container(
                            //                 height:
                            //                 Dimensions.PADDING_SIZE_EXTRA_LARGE *
                            //                     3,
                            //                 width: Dimensions.PADDING_SIZE_EXTRA_LARGE *
                            //                     3.4,
                            //                 color: ThemeManager.lightgrey,
                            //                 child: Column(
                            //                   mainAxisAlignment:
                            //                   MainAxisAlignment.center,
                            //                   children: [
                            //                     Text(
                            //                       "${widget.reports?.guessedAnswersCount}",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color:
                            //                         Theme
                            //                             .of(context)
                            //                             .primaryColor,
                            //                       ),
                            //                     ),
                            //                     const SizedBox(
                            //                       height: Dimensions.PADDING_SIZE_SMALL,
                            //                     ),
                            //                     Text(
                            //                       "Guessed answer",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color: Theme
                            //                             .of(context)
                            //                             .hintColor,
                            //                       ),
                            //                       textAlign: TextAlign.center,
                            //                     ),
                            //                   ],
                            //                 ),
                            //               ),
                            //
                            //               Container(
                            //                 height:
                            //                 Dimensions.PADDING_SIZE_EXTRA_LARGE *
                            //                     1.8,
                            //                 width: 1,
                            //                 color: ThemeManager.lightBlue,
                            //               ),
                            //               const SizedBox(
                            //                 width: Dimensions.PADDING_SIZE_SMALL,
                            //               ),
                            //
                            //               //Correct
                            //               Container(
                            //                 height:
                            //                 Dimensions.PADDING_SIZE_EXTRA_LARGE *
                            //                     3,
                            //                 width: Dimensions.PADDING_SIZE_EXTRA_LARGE *
                            //                     3.4,
                            //                 color: ThemeManager.lightgrey,
                            //                 child: Column(
                            //                   mainAxisAlignment:
                            //                   MainAxisAlignment.center,
                            //                   children: [
                            //                     Text(
                            //                       "${widget.reports?.correctGuessCount}",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color:
                            //                         Theme
                            //                             .of(context)
                            //                             .primaryColor,
                            //                       ),
                            //                     ),
                            //                     const SizedBox(
                            //                       height: Dimensions.PADDING_SIZE_SMALL,
                            //                     ),
                            //                     Text(
                            //                       "Correct answer",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color: Theme
                            //                             .of(context)
                            //                             .hintColor,
                            //                       ),
                            //                       textAlign: TextAlign.center,
                            //                     ),
                            //                   ],
                            //                 ),
                            //               ),
                            //
                            //               Container(
                            //                 height:
                            //                 Dimensions.PADDING_SIZE_EXTRA_LARGE *
                            //                     1.8,
                            //                 width: 1,
                            //                 color: ThemeManager.lightBlue,
                            //               ),
                            //               const SizedBox(
                            //                 width: Dimensions.PADDING_SIZE_SMALL,
                            //               ),
                            //               //Incorrect
                            //               Container(
                            //                 height:
                            //                 Dimensions.PADDING_SIZE_EXTRA_LARGE *
                            //                     3,
                            //                 width: Dimensions.PADDING_SIZE_EXTRA_LARGE *
                            //                     3.4,
                            //                 color: ThemeManager.lightgrey,
                            //                 child: Column(
                            //                   mainAxisAlignment:
                            //                   MainAxisAlignment.center,
                            //                   children: [
                            //                     Text(
                            //                       "${widget.reports?.wrongGuessCount}",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color:
                            //                         Theme
                            //                             .of(context)
                            //                             .primaryColor,
                            //                       ),
                            //                     ),
                            //                     const SizedBox(
                            //                       height: Dimensions.PADDING_SIZE_SMALL,
                            //                     ),
                            //                     Text(
                            //                       "Incorrect answer",
                            //                       style: interRegular.copyWith(
                            //                         fontSize: Dimensions.fontSizeSmall,
                            //                         fontWeight: FontWeight.w400,
                            //                         color: Theme
                            //                             .of(context)
                            //                             .hintColor,
                            //                       ),
                            //                       textAlign: TextAlign.center,
                            //                     ),
                            //                   ],
                            //                 ),
                            //               ),
                            //             ],
                            //           ),
                            //
                            //           //Correct answer, Incorrect answer and Skipped answer
                            //
                            //           //Accuracy,Correct,Incorrect and Skipped
                            //         ],
                            //       ),
                            //     )
                            //     // const SizedBox(height: Dimensions.PADDING_SIZE_LARGE),
                            //   ],
                            // ),
                            // ExpansionTile(
                            //   initiallyExpanded: false,
                            //   collapsedIconColor: Theme.of(context).primaryColor,
                            //   title: Text(
                            //     "Answer Evolve",
                            //     style: interSemiBold.copyWith(
                            //       fontSize: Dimensions.fontSizeDefault,
                            //       fontWeight: FontWeight.w400,
                            //       color: ThemeManager.black,
                            //     ),
                            //   ),
                            //   children: [
                            //     const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
                            //
                            //     /// Changed Answers Statistics
                            //     Container(
                            //       padding: EdgeInsets.all(16),
                            //       height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 5,
                            //       width: MediaQuery.of(context).size.width,
                            //       color: ThemeManager.lightgrey,
                            //       child: Row(
                            //         crossAxisAlignment: CrossAxisAlignment.start,
                            //         mainAxisAlignment: MainAxisAlignment.center,
                            //         children: [
                            //           Expanded(
                            //             child: Column(
                            //               children: [
                            //                 Text(
                            //                   "${widget.reports?.incorrect_correct}",
                            //                   style: interSemiBold.copyWith(
                            //                     fontSize: Dimensions.fontSizeDefault,
                            //                     fontWeight: FontWeight.w400,
                            //                     color: ThemeManager.black,
                            //                   ),
                            //                 ),
                            //                 Text(
                            //                   "Incorrect",
                            //                   style: interSemiBold.copyWith(
                            //                     fontSize: Dimensions.fontSizeDefault,
                            //                     fontWeight: FontWeight.w400,
                            //                     color: ThemeManager.redAlert,
                            //                   ),
                            //                 ),
                            //                 Text(
                            //                   "↓",
                            //                   style: interSemiBold.copyWith(
                            //                     fontSize: Dimensions.fontSizeDefault,
                            //                     fontWeight: FontWeight.w400,
                            //                     color: ThemeManager.black,
                            //                   ),
                            //                 ),
                            //                 Text(
                            //                   "Correct",
                            //                   style: interSemiBold.copyWith(
                            //                     fontSize: Dimensions.fontSizeDefault,
                            //                     fontWeight: FontWeight.w400,
                            //                     color: ThemeManager.greenSuccess,
                            //                   ),
                            //                 ),
                            //               ],
                            //             ),
                            //           ),
                            //           Container(
                            //               height: 40,
                            //               width: 1,
                            //               color: Color(0xffAFA8FD)),
                            //           Expanded(
                            //             child: Column(
                            //               children: [
                            //                 Text(
                            //                   "${widget.reports?.correct_incorrect}",
                            //                   style: interSemiBold.copyWith(
                            //                     fontSize: Dimensions.fontSizeDefault,
                            //                     fontWeight: FontWeight.w400,
                            //                     color: ThemeManager.black,
                            //                   ),
                            //                 ),
                            //                 Text(
                            //                   "Correct",
                            //                   style: interSemiBold.copyWith(
                            //                     fontSize: Dimensions.fontSizeDefault,
                            //                     fontWeight: FontWeight.w400,
                            //                     color: ThemeManager.greenSuccess,
                            //                   ),
                            //                 ),
                            //                 Text(
                            //                   "↓",
                            //                   style: interSemiBold.copyWith(
                            //                     fontSize: Dimensions.fontSizeDefault,
                            //                     fontWeight: FontWeight.w400,
                            //                     color: ThemeManager.black,
                            //                   ),
                            //                 ),
                            //                 Text(
                            //                   "Incorrect",
                            //                   style: interSemiBold.copyWith(
                            //                     fontSize: Dimensions.fontSizeDefault,
                            //                     fontWeight: FontWeight.w400,
                            //                     color: ThemeManager.redAlert,
                            //                   ),
                            //                 ),
                            //               ],
                            //             ),
                            //           ),
                            //           Container(
                            //               height: 40,
                            //               width: 1,
                            //               color: Color(0xffAFA8FD)),
                            //           Expanded(
                            //             child: Column(
                            //               children: [
                            //                 Text(
                            //                   "${widget.reports?.incorrect_incorres}",
                            //                   style: interSemiBold.copyWith(
                            //                     fontSize: Dimensions.fontSizeDefault,
                            //                     fontWeight: FontWeight.w400,
                            //                     color: ThemeManager.blackColor,
                            //                   ),
                            //                 ),
                            //                 Text(
                            //                   "Incorrect",
                            //                   style: interSemiBold.copyWith(
                            //                     fontSize: Dimensions.fontSizeDefault,
                            //                     fontWeight: FontWeight.w400,
                            //                     color: ThemeManager.redAlert,
                            //                   ),
                            //                 ),
                            //                 Text(
                            //                   "↓",
                            //                   style: interSemiBold.copyWith(
                            //                     fontSize: Dimensions.fontSizeDefault,
                            //                     fontWeight: FontWeight.w400,
                            //                     color: ThemeManager.black,
                            //                   ),
                            //                 ),
                            //                 Text(
                            //                   "Incorrect",
                            //                   style: interSemiBold.copyWith(
                            //                     fontSize: Dimensions.fontSizeDefault,
                            //                     fontWeight: FontWeight.w400,
                            //                     color: ThemeManager.redAlert,
                            //                   ),
                            //                 ),
                            //               ],
                            //             ),
                            //           )
                            //         ],
                            //       ),
                            //     )
                            //
                            //     // const SizedBox(height: Dimensions.PADDING_SIZE_LARGE),
                            //   ],
                            // ),
                            //
                            // ///Merit List
                            // meritList.isNotEmpty?
                            // ExpansionTile(
                            //   initiallyExpanded: false,
                            //   collapsedIconColor: Theme.of(context).primaryColor,
                            //   title: Text(
                            //     "Summit Scholars (Attempt 1)",
                            //     style: interSemiBold.copyWith(
                            //       fontSize: Dimensions.fontSizeDefault,
                            //       fontWeight: FontWeight.w400,
                            //       color: ThemeManager.black,
                            //     ),
                            //   ),
                            //   children: [
                            //     DataTable(
                            //       columns: [
                            //         DataColumn(label: Text("Rank",
                            //           style: interRegular.copyWith(
                            //             fontSize: Dimensions.fontSizeDefault,
                            //             fontWeight: FontWeight.w500,
                            //             color: ThemeManager.black,
                            //           ),)),
                            //         DataColumn(label: Text("Name",
                            //           style: interRegular.copyWith(
                            //             fontSize: Dimensions.fontSizeDefault,
                            //             fontWeight: FontWeight.w500,
                            //             color: ThemeManager.black,
                            //           ),)),
                            //         DataColumn(label: Text("Marks",
                            //           style: interRegular.copyWith(
                            //             fontSize: Dimensions.fontSizeDefault,
                            //             fontWeight: FontWeight.w500,
                            //             color: ThemeManager.black,
                            //           ),)),
                            //       ],
                            //       rows: meritList.map((student) {
                            //         return DataRow(cells: [
                            //           DataCell(Text(student?.rank.toString()??"",
                            //             style: interRegular.copyWith(
                            //               fontSize: Dimensions.fontSizeDefault,
                            //               fontWeight: FontWeight.w500,
                            //               color: ThemeManager.black,
                            //             ),)),
                            //           DataCell(Text(student?.fullName??"",
                            //               style: interRegular.copyWith(
                            //                 fontSize: Dimensions.fontSizeDefault,
                            //                 fontWeight: FontWeight.w500,
                            //                 color: ThemeManager.black,
                            //               ))),
                            //           DataCell(Text(student?.score.toString()??"",
                            //             style: interRegular.copyWith(
                            //               fontSize: Dimensions.fontSizeDefault,
                            //               fontWeight: FontWeight.w500,
                            //               color: ThemeManager.black,
                            //             ),)),
                            //         ]);
                            //       }).toList(),
                            //     ),
                            //   ],
                            // ):const SizedBox(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
