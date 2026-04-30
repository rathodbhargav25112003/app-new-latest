// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, library_private_types_in_public_api, use_build_context_synchronously, unused_local_variable

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/model/plan_subcategory_model.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/store/new_subscription_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';

/// NewCustomSubscriptionPlan — second step of the revamped subscription
/// flow. Given the chosen exam [categoryId] / [categoryName] from the
/// previous dialog, lists the available plan subcategories and lets the
/// learner pick one before advancing to the plan selector.
///
/// Public surface preserved exactly:
///   • class [NewCustomSubscriptionPlan] + const constructor
///     `{super.key, required categoryId, required categoryName}`
///   • static [route] factory reading `arguments['categoryId']`,
///     `arguments['categoryName']` and wrapping the page in a
///     `Provider<NewSubscriptionStore>`
///   • Navigation target: `Routes.newSelectSubscriptionPlan` with
///     `{'categoryId', 'subcategoryId'}` arguments
class NewCustomSubscriptionPlan extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const NewCustomSubscriptionPlan({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<NewCustomSubscriptionPlan> createState() =>
      _NewCustomSubscriptionPlanState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => Provider<NewSubscriptionStore>(
        create: (_) => NewSubscriptionStore(),
        child: NewCustomSubscriptionPlan(
          categoryId: args['categoryId'],
          categoryName: args['categoryName'],
        ),
      ),
    );
  }
}

class _NewCustomSubscriptionPlanState extends State<NewCustomSubscriptionPlan> {
  int selectedIndex = -1;
  late NewSubscriptionStore _store;

  @override
  void initState() {
    super.initState();
    _store = Provider.of<NewSubscriptionStore>(context, listen: false);
    _loadSubcategories();
  }

  Future<void> _loadSubcategories() async {
    await _store.getPlanSubcategories(widget.categoryId);
  }

  PlanSubcategoryModel? get selectedSubcategory {
    if (selectedIndex >= 0 && selectedIndex < _store.planSubcategories.length) {
      return _store.planSubcategories[selectedIndex];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrDesktop = screenWidth > 600;
    final maxWidth = isTabletOrDesktop ? 600.0 : screenWidth * 0.95;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTokens.brand, AppTokens.brand2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: (Platform.isWindows || Platform.isMacOS)
                  ? const EdgeInsets.symmetric(
                      vertical: Dimensions.PADDING_SIZE_LARGE * 1.2,
                      horizontal: Dimensions.PADDING_SIZE_LARGE * 1.2)
                  : const EdgeInsets.only(
                      top: Dimensions.PADDING_SIZE_LARGE * 2,
                      left: Dimensions.PADDING_SIZE_LARGE * 1,
                      right: Dimensions.PADDING_SIZE_LARGE * 1.2,
                      bottom: Dimensions.PADDING_SIZE_SMALL * 1.3),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.18)),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT),
                  Text(
                    "Customize Subscription",
                    style: AppTokens.titleMd(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.PADDING_SIZE_LARGE,
                  vertical: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.scaffold(context),
                  borderRadius: (Platform.isWindows || Platform.isMacOS)
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r28),
                          topRight: Radius.circular(AppTokens.r28),
                        ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: AppTokens.s16),
                      decoration: BoxDecoration(
                        color: AppTokens.accentSoft(context),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: AppTokens.border(context)),
                      ),
                      child: Text(
                        "Preparing for: ${widget.categoryName}",
                        textAlign: TextAlign.center,
                        style: AppTokens.caption(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTokens.accent(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s16),
                    Text(
                      "Customize Your Subscription",
                      style: AppTokens.titleLg(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTokens.s8),
                    Text(
                      "What content are you looking for? Select an \noption to explore tailored plans",
                      textAlign: TextAlign.center,
                      style: AppTokens.body(context).copyWith(
                        color: AppTokens.muted(context),
                      ),
                    ),
                    Expanded(
                      child: Observer(
                        builder: (_) {
                          if (_store.isSubcategoryLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTokens.brand,
                              ),
                            );
                          }

                          if (_store.planSubcategories.isEmpty) {
                            return Center(
                              child: Text(
                                "No subscription options available",
                                style: AppTokens.body(context).copyWith(
                                  color: AppTokens.muted(context),
                                ),
                              ),
                            );
                          }

                          return (Platform.isMacOS || Platform.isWindows)
                              ? GridView.builder(
                                  itemCount: _store.planSubcategories.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 4.8,
                                  ),
                                  itemBuilder: (context, index) {
                                    final option =
                                        _store.planSubcategories[index];
                                    return _buildOptionCard(option, index);
                                  },
                                )
                              : ListView.separated(
                                  itemCount: _store.planSubcategories.length,
                                  physics: const BouncingScrollPhysics(),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final option =
                                        _store.planSubcategories[index];
                                    return _buildOptionCard(option, index);
                                  },
                                );
                        },
                      ),
                    ),
                    const SizedBox(height: AppTokens.s24),
                    SizedBox(
                      width: double.infinity,
                      child: _ProceedCta(
                        enabled: selectedIndex >= 0,
                        onTap: () {
                          final subcategory = selectedSubcategory;
                          if (subcategory != null && subcategory.sid != null) {
                            Navigator.of(context).pushNamed(
                              Routes.newSelectSubscriptionPlan,
                              arguments: {
                                'categoryId': widget.categoryId,
                                'subcategoryId': subcategory.sid,
                              },
                            );
                          }
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(PlanSubcategoryModel option, int index) {
    final bool selected = selectedIndex == index;
    List<Widget> icons = [];

    if (option.isMcq == true) {
      icons.add(
          Image.asset("assets/image/mcq.png", height: 24, width: 24));
    }
    if (option.isNote == true) {
      icons.add(
          Image.asset("assets/image/note.png", height: 24, width: 24));
    }
    if (option.isVideo == true) {
      icons.add(
          Image.asset("assets/image/video.png", height: 24, width: 24));
    }
    if (option.isMock == true) {
      icons.add(
          Image.asset("assets/image/mock.png", height: 24, width: 24));
    }
    if (option.isLive == true) {
      icons.add(
          Image.asset("assets/image/live.png", height: 24, width: 24));
    }

    if (icons.isEmpty) {
      icons.add(
          Image.asset("assets/image/mcq.png", height: 24, width: 24));
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r16),
        onTap: () => setState(() => selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.only(
              left: 20, right: 10, top: 15, bottom: 15),
          decoration: BoxDecoration(
            color: selected
                ? AppTokens.accentSoft(context)
                : AppTokens.surface(context),
            borderRadius: BorderRadius.circular(AppTokens.r16),
            border: Border.all(
              color: selected
                  ? AppTokens.brand
                  : AppTokens.border(context),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTokens.brand.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.subcategory_name ?? "Unknown Plan",
                          style: AppTokens.body(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.description ?? "",
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Radio<int>(
                    value: index,
                    groupValue: selectedIndex,
                    onChanged: (val) =>
                        setState(() => selectedIndex = val ?? -1),
                    activeColor: AppTokens.brand,
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s8),
              Row(
                children: icons
                    .map((icon) => Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: icon,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand-gradient "Proceed" CTA used to advance the subscription flow.
class _ProceedCta extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _ProceedCta({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          onTap: enabled ? onTap : null,
          child: Ink(
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppTokens.brand.withOpacity(0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                "Proceed",
                style: AppTokens.titleSm(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
