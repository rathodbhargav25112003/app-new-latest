// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/models/bookmark_subcategory_model.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/widgets/no_internet_connection.dart';

/// Reports — subcategory list under a category. Tapping an entry pushes
/// `Routes.reportsTopicList` with `{subCateName, subcatId}`.
///
/// Preserved public contract:
///   • Constructor `ReportsSubcategoryScreen({Key? key,
///     required this.categoryName, this.categoryId})`
///   • Static `route(RouteSettings)` reads `categoryName` / `categoryId`.
///   • `store.onReportSubCategoryApiCall(widget.categoryId!)` in initState.
///   • AppBar title shows `widget.categoryName`.
///   • Search filter is lowercase-contains on `subcategory_name`.
///   • Empty state copy preserved verbatim: "We're sorry, there's no
///     content available right now. Please check back later or explore
///     other sections for more educational resources."
///   • `!store.isConnected` → `NoInternetScreen`.
class ReportsSubcategoryScreen extends StatefulWidget {
  final String categoryName;
  final String? categoryId;
  const ReportsSubcategoryScreen(
      {Key? key, required this.categoryName, this.categoryId})
      : super(key: key);

  @override
  State<ReportsSubcategoryScreen> createState() =>
      _ReportsSubcategoryScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => ReportsSubcategoryScreen(
        categoryName: arguments['categoryName'],
        categoryId: arguments['categoryId'],
      ),
    );
  }
}

class _ReportsSubcategoryScreenState extends State<ReportsSubcategoryScreen> {
  String query = '';

  @override
  void initState() {
    super.initState();
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    store.onReportSubCategoryApiCall(widget.categoryId!);
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
                widget.categoryName,
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
          // Results header
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
                if (store.bookmarkSubCategory.isEmpty) {
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
                  itemCount: store.bookmarkSubCategory.length,
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
                    BookMarkSubCategoryModel? reportSubCat =
                        store.bookmarkSubCategory[index];
                    if (query.isNotEmpty &&
                        (!reportSubCat!.subcategory_name!
                            .toLowerCase()
                            .contains(query.toLowerCase()))) {
                      return const SizedBox.shrink();
                    }
                    return InkWell(
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          Routes.reportsTopicList,
                          arguments: {
                            "subCateName": reportSubCat?.subcategory_name,
                            "subcatId": reportSubCat?.subcategory_id,
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
                                "assets/image/reportsubCate.svg",
                                color: AppTokens.accent(context),
                              ),
                            ),
                            const SizedBox(width: AppTokens.s12),
                            Expanded(
                              child: Text(
                                reportSubCat?.subcategory_name ?? "",
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
