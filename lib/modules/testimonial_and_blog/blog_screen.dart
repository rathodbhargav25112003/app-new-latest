// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, prefer_final_fields, unnecessary_import

import 'dart:io';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/helpers/styles.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
import 'package:shusruta_lms/modules/testimonial_and_blog/model/get_all_blogs_model.dart';

/// Blog index — scrollable list / grid of blog article cards, each linking
/// to the blog details screen via `Routes.blogDetailsScreen`.
///
/// Preserved public contract:
///   • `BlogScreen({super.key})` (no arguments).
///   • Static `route(RouteSettings)` returns `CupertinoPageRoute`.
///   • initState calls `_getBlogList()` →
///     `store.onGetBlogsListApiCall()` on `HomeStore`.
///   • Back button pops the current route.
///   • AppBar title "Blogs".
///   • Windows uses `CustomDynamicHeightGridView` (3 cols);
///     other platforms use `ListView.builder`.
///   • Top-level `buildGridItem(BuildContext, GetBlogsListModel?)` helper.
///   • `ReadMoreHtml` widget preserved with same constructor contract.
///   • Tap on card navigates to `Routes.blogDetailsScreen` with `{blogId}`.
class BlogScreen extends StatefulWidget {
  const BlogScreen({
    super.key,
  });

  @override
  State<BlogScreen> createState() => _BlogScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    // final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => const BlogScreen(),
    );
  }
}

class _BlogScreenState extends State<BlogScreen> {
  @override
  void initState() {
    super.initState();
    _getBlogList();
  }

  Future<void> _getBlogList() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGetBlogsListApiCall();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<HomeStore>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppTokens.surface(context),
        surfaceTintColor: AppTokens.surface(context),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: AppTokens.s8,
        title: Row(
          children: [
            Material(
              color: AppTokens.surface2(context),
              borderRadius: BorderRadius.circular(AppTokens.r8),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(AppTokens.r8),
                child: SizedBox(
                  height: AppTokens.s32,
                  width: AppTokens.s32,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: AppTokens.ink(context),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Text(
              "Blogs",
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s16,
          AppTokens.s12,
          AppTokens.s16,
          0,
        ),
        child: Column(
          children: [
            _SearchField(),
            const SizedBox(height: AppTokens.s12),
            Expanded(
              child: Observer(builder: (context) {
                if (store.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTokens.accent(context),
                    ),
                  );
                }
                if (store.getBlogsListData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 56,
                          color: AppTokens.muted(context),
                        ),
                        const SizedBox(height: AppTokens.s12),
                        Text(
                          "No articles yet",
                          style: AppTokens.body(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Platform.isWindows
                    ? CustomDynamicHeightGridView(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        itemCount: store.getBlogsListData.length,
                        builder: (BuildContext context, int index) {
                          GetBlogsListModel? blogData =
                              store.getBlogsListData[index];
                          return buildGridItem(context, blogData);
                        },
                      )
                    : ListView.builder(
                        itemCount: store.getBlogsListData.length,
                        padding: const EdgeInsets.only(bottom: AppTokens.s16),
                        itemBuilder: (BuildContext context, int index) {
                          GetBlogsListModel? blogData =
                              store.getBlogsListData[index];
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppTokens.s12),
                            child: _BlogListCard(blogData: blogData),
                          );
                        },
                      );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: TextField(
        style: AppTokens.body(context).copyWith(
          color: AppTokens.ink(context),
          fontWeight: FontWeight.w500,
        ),
        cursorColor: AppTokens.accent(context),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s12,
          ),
          suffixIcon: Icon(
            CupertinoIcons.search,
            color: AppTokens.muted(context),
          ),
          hintStyle: AppTokens.body(context).copyWith(
            color: AppTokens.muted(context),
            fontWeight: FontWeight.w500,
          ),
          hintText: 'Search',
          filled: false,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _BlogListCard extends StatelessWidget {
  const _BlogListCard({required this.blogData});

  final GetBlogsListModel? blogData;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surface(context),
      borderRadius: BorderRadius.circular(AppTokens.r16),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r16),
        onTap: () {
          Navigator.of(context).pushNamed(
            Routes.blogDetailsScreen,
            arguments: {
              'blogId': blogData?.sId,
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s12),
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            border: Border.all(color: AppTokens.border(context)),
            borderRadius: BorderRadius.circular(AppTokens.r16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 132,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTokens.surface2(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
                clipBehavior: Clip.antiAlias,
                child: (blogData?.image ?? '') != ''
                    ? Image.network(
                        blogData?.image ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 36,
                            color: AppTokens.muted(context),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.article_outlined,
                          size: 36,
                          color: AppTokens.muted(context),
                        ),
                      ),
              ),
              const SizedBox(height: AppTokens.s12),
              Text(
                blogData?.title ?? '',
                style: AppTokens.titleSm(context).copyWith(
                  color: AppTokens.ink(context),
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              ReadMoreHtml(htmlContent: blogData?.content ?? ''),
              const SizedBox(height: AppTokens.s8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Read more..",
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.accent(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top-level grid-card builder preserved for Windows grid callers.
Widget buildGridItem(BuildContext context, GetBlogsListModel? blogData) {
  return Material(
    color: AppTokens.surface(context),
    borderRadius: BorderRadius.circular(AppTokens.r16),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r16),
      onTap: () {
        Navigator.of(context).pushNamed(Routes.blogDetailsScreen, arguments: {
          'blogId': blogData?.sId,
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          border: Border.all(color: AppTokens.border(context)),
          borderRadius: BorderRadius.circular(AppTokens.r16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTokens.r16),
                  topRight: Radius.circular(AppTokens.r16),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: (blogData?.image ?? '') != ''
                  ? Image.network(
                      blogData?.image ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 36,
                          color: AppTokens.muted(context),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.article_outlined,
                        size: 36,
                        color: AppTokens.muted(context),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s12,
                AppTokens.s12,
                AppTokens.s12,
                AppTokens.s12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blogData?.title ?? '',
                    style: AppTokens.titleSm(context).copyWith(
                      color: AppTokens.ink(context),
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppTokens.s8),
                  ReadMoreHtml(htmlContent: blogData?.content ?? ''),
                  const SizedBox(height: AppTokens.s8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Read more..",
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.accent(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ReadMoreHtml extends StatelessWidget {
  final String htmlContent;
  final int truncateLength;

  const ReadMoreHtml(
      {super.key, required this.htmlContent, this.truncateLength = 200});

  @override
  Widget build(BuildContext context) {
    String displayContent = htmlContent;
    bool isTruncated = false;

    if (htmlContent.length > truncateLength) {
      displayContent = '${htmlContent.substring(0, truncateLength)}...';
      isTruncated = true;
    }

    // return Html(data: displayContent);
    return Html(
      data: '''
            <div style="color: ${ThemeManager.currentTheme == AppTheme.Dark ? 'white' : 'black'};">
                $displayContent
                </div>
                ''',
    );
  }
}
