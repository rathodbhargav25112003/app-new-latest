// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, prefer_final_fields, unnecessary_import

import 'dart:io';

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
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/helpers/styles.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';

/// Blog article detail — shows cover image, title and rich HTML content
/// for a single blog post identified by `blogId`.
///
/// Preserved public contract:
///   • `BlogDetailsScreen({super.key, required blogId})`.
///   • Static `route(RouteSettings)` reads `{blogId}`.
///   • initState calls `_getBlogDetails()` →
///     `store.onGetBlogDetailsApiCall(widget.blogId)` on `HomeStore`.
///   • Back button pops the current route.
///   • AppBar title "Blogs".
class BlogDetailsScreen extends StatefulWidget {
  final String blogId;
  const BlogDetailsScreen({
    super.key,
    required this.blogId,
  });

  @override
  State<BlogDetailsScreen> createState() => _BlogDetailsScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => BlogDetailsScreen(
        blogId: arguments['blogId'],
      ),
    );
  }
}

class _BlogDetailsScreenState extends State<BlogDetailsScreen> {
  @override
  void initState() {
    super.initState();
    _getBlogDetails();
  }

  Future<void> _getBlogDetails() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGetBlogDetailsApiCall(widget.blogId);
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<HomeStore>(context, listen: false);
    final bool isDesktop = Platform.isWindows || Platform.isMacOS;

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
      body: Observer(builder: (context) {
        if (store.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTokens.accent(context),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16, vertical: AppTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: isDesktop ? 350 : 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTokens.surface2(context),
                  borderRadius: BorderRadius.circular(AppTokens.r16),
                  border: Border.all(color: AppTokens.border(context)),
                ),
                clipBehavior: Clip.antiAlias,
                child: (store.getBlogDetailsData.value?.image ?? '') != ''
                    ? Image.network(
                        store.getBlogDetailsData.value?.image ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: AppTokens.muted(context),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.article_outlined,
                          size: 48,
                          color: AppTokens.muted(context),
                        ),
                      ),
              ),
              const SizedBox(height: AppTokens.s20),
              Text(
                store.getBlogDetailsData.value?.title ?? '',
                style: AppTokens.titleMd(context).copyWith(
                  color: AppTokens.ink(context),
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppTokens.s16),
              Html(
                data: '''
                  <div style="color: ${ThemeManager.currentTheme == AppTheme.Dark ? 'white' : 'black'};">
                  ${store.getBlogDetailsData.value?.content ?? ''}
                  </div>
                  ''',
              ),
              const SizedBox(height: AppTokens.s24),
            ],
          ),
        );
      }),
    );
  }
}
