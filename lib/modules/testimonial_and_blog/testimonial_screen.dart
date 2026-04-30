// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, prefer_final_fields, unnecessary_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/helpers/styles.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
import 'package:shusruta_lms/modules/testimonial_and_blog/custom_testimonial_description_widget.dart';
import 'package:shusruta_lms/modules/testimonial_and_blog/model/get_all_testimonial_list_model.dart';

/// Testimonial gallery — grid of student testimonials with ratings and
/// names, loaded through `HomeStore.onGetTestimonialListApiCall()`.
///
/// Preserved public contract:
///   • `TestimonialScreen({Key? key})` (no arguments).
///   • Static `route(RouteSettings)` returns `CupertinoPageRoute`.
///   • initState calls `_getTestimonial()` →
///     `store.onGetTestimonialListApiCall()` on `HomeStore`.
///   • Back button pops the current route.
///   • AppBar title "Testimonial".
///   • Section heading "Trending".
///   • Grid uses 2 columns on narrow screens, 4 on `maxWidth > 600`.
///   • Each card composes `RatingBar.builder` + `CustomTestimonialDescriptionWidget`
///     + testimonial name.
class TestimonialScreen extends StatefulWidget {
  const TestimonialScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<TestimonialScreen> createState() => _TestimonialScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    // final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => const TestimonialScreen(),
    );
  }
}

class _TestimonialScreenState extends State<TestimonialScreen> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _getTestimonial();
  }

  Future<void> _getTestimonial() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGetTestimonialListApiCall();
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
              "Testimonial",
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
          AppTokens.s8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Trending",
              style: AppTokens.titleMd(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            Expanded(
              child: Observer(builder: (context) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 2;
                    double childAspectRatio = 0.95;

                    if (constraints.maxWidth > 600) {
                      crossAxisCount = 4;
                      childAspectRatio = 0.9;
                    }
                    return GridView.count(
                      childAspectRatio: childAspectRatio,
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppTokens.s12,
                      mainAxisSpacing: AppTokens.s16,
                      children:
                          List.generate(store.getTestimonialData.length, (index) {
                        GetTestimonialListModel? getTestimonial =
                            store.getTestimonialData[index];
                        return _TestimonialCard(
                          testimonial: getTestimonial,
                        );
                      }),
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

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({
    required this.testimonial,
  });

  final GetTestimonialListModel? testimonial;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s12,
        AppTokens.s16,
        AppTokens.s12,
        AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 14,
            spreadRadius: -5,
            color: ThemeManager.black.withOpacity(0.10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RatingBar.builder(
            initialRating: testimonial?.rating?.toDouble() ?? 0,
            direction: Axis.horizontal,
            itemCount: 5,
            itemSize: 18,
            itemPadding: const EdgeInsets.only(right: 4),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            ignoreGestures: true,
            onRatingUpdate: (_) {},
          ),
          const SizedBox(height: AppTokens.s8),
          CustomTestimonialDescriptionWidget(
            name: testimonial?.name ?? "",
            rating: testimonial?.rating ?? 0,
            description: '"${testimonial?.description}"',
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            testimonial?.name ?? '',
            style: AppTokens.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink(context),
            ),
          ),
          const SizedBox(height: AppTokens.s8),
        ],
      ),
    );
  }
}
