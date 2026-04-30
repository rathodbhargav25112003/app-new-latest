// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/bookmark_topic_model.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/widgets/no_internet_connection.dart';

/// Reports — topic list under a subcategory. Tapping an entry pushes
/// `Routes.selectExamReportList` with `{id: topic_id, title: topic_name,
/// type: "topic"}`.
///
/// Preserved public contract:
///   • Constructor `ReportTopicScreen({Key? key, required this.chapter,
///     required this.subcatId})`
///   • Static `route(RouteSettings)` maps `subCateName` → `chapter`,
///     reads `subcatId`.
///   • `store.onReportTopicApiCall(widget.subcatId)` in initState.
///   • AppBar title shows `widget.chapter`.
///   • Search filter is lowercase-contains on `topic_name`.
///   • Empty state copy preserved verbatim.
///   • `!store.isConnected` → `NoInternetScreen`.
class ReportTopicScreen extends StatefulWidget {
  final String chapter;
  final String subcatId;
  const ReportTopicScreen(
      {Key? key, required this.chapter, required this.subcatId})
      : super(key: key);

  @override
  State<ReportTopicScreen> createState() => _ReportTopicScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => ReportTopicScreen(
        chapter: arguments['subCateName'],
        subcatId: arguments['subcatId'],
      ),
    );
  }
}

class _ReportTopicScreenState extends State<ReportTopicScreen> {
  String query = '';

  @override
  void initState() {
    super.initState();
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    store.onReportTopicApiCall(widget.subcatId);
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
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
                widget.chapter,
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
          // Search
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
                enableInteractiveSelection: false,
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
                  "Results for \"$query\"",
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
                if (store.bookmarkTopic.isEmpty) {
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
                  itemCount: store.bookmarkTopic.length,
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
                    BookMarkTopicModel? bookmarkTopic =
                        store.bookmarkTopic[index];
                    if (query.isNotEmpty &&
                        (!bookmarkTopic!.topic_name!
                            .toLowerCase()
                            .contains(query.toLowerCase()))) {
                      return const SizedBox.shrink();
                    }
                    return InkWell(
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          Routes.selectExamReportList,
                          arguments: {
                            'id': bookmarkTopic?.topic_id,
                            'title': bookmarkTopic?.topic_name,
                            'type': "topic",
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppTokens.s16),
                        decoration: BoxDecoration(
                          color: AppTokens.surface(context),
                          borderRadius: BorderRadius.circular(AppTokens.r12),
                          border: Border.all(color: AppTokens.border(context)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 44,
                              width: 44,
                              padding: const EdgeInsets.all(AppTokens.s8),
                              decoration: BoxDecoration(
                                color: AppTokens.accentSoft(context),
                                borderRadius:
                                    BorderRadius.circular(AppTokens.r12),
                              ),
                              child: SvgPicture.asset(
                                "assets/image/reportTopic.svg",
                                color: AppTokens.accent(context),
                              ),
                            ),
                            const SizedBox(width: AppTokens.s12),
                            Expanded(
                              child: Text(
                                bookmarkTopic?.topic_name ?? "",
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
    );
  }
}
