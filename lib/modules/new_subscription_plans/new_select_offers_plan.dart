// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, library_private_types_in_public_api, use_build_context_synchronously, unused_local_variable, use_super_parameters

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/model/offer_model.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/store/new_subscription_store.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/widget/custom_info_card.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/widget/exam_goal_dialog.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../widgets/bottom_toast.dart';

/// NewSelectOffersPlan — full-screen picker for coupons / flat-discount
/// offers. On Apply, records the selection in
/// [NewSubscriptionStore.applyOffer] and returns `{'applied': true}` /
/// `{'applied': false}` via `Navigator.pop`.
///
/// Public surface preserved exactly:
///   • class [NewSelectOffersPlan] + constructor
///     `{Key? key, required plans, books, bookQuantities}`
///   • static [route] factory reading `arguments['plans']`,
///     `arguments['books']`, `arguments['bookQuantities']` and wrapping
///     the page in a `Provider<NewSubscriptionStore>`
///   • Pop result shape `{'applied': bool}`
class NewSelectOffersPlan extends StatefulWidget {
  final List<Map<String, dynamic>> plans;
  final List<Map<String, dynamic>>? books;
  final Map<int, int>? bookQuantities;

  const NewSelectOffersPlan({
    Key? key,
    required this.plans,
    this.books,
    this.bookQuantities,
  }) : super(key: key);

  @override
  State<NewSelectOffersPlan> createState() => _NewSelectOffersPlanState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>?;
    return CupertinoPageRoute(
      builder: (_) => Provider<NewSubscriptionStore>(
        create: (_) => NewSubscriptionStore(),
        child: NewSelectOffersPlan(
          plans: List<Map<String, dynamic>>.from(args?['plans'] ?? []),
          books: args?['books'] as List<Map<String, dynamic>>?,
          bookQuantities: args?['bookQuantities'] as Map<int, int>?,
        ),
      ),
    );
  }
}

class _NewSelectOffersPlanState extends State<NewSelectOffersPlan> {
  int selectedIndex = -1;
  late NewSubscriptionStore _store;
  bool isLoading = true;
  String? error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _store = Provider.of<NewSubscriptionStore>(context);
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      await _store.getAvailableOffers();

      if (_store.appliedOffer != null) {
        final index = _store.availableOffers.indexWhere(
            (offer) => offer.id == _store.appliedOffer!.id);
        if (index != -1) {
          setState(() {
            selectedIndex = index;
          });
        }
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
                    "Select Offer",
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
                  vertical: Dimensions.PADDING_SIZE_LARGE,
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
                    Expanded(
                      child: Observer(
                        builder: (_) {
                          if (_store.isOfferLoading || isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTokens.brand,
                              ),
                            );
                          }

                          if (_store.offerError != null || error != null) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Error loading offers: ${_store.offerError ?? error}",
                                    style: AppTokens.body(context).copyWith(
                                      color: AppTokens.danger(context),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppTokens.s16),
                                  _FlatCta(
                                    label: "Retry",
                                    onTap: _fetchOffers,
                                  ),
                                ],
                              ),
                            );
                          }

                          if (_store.availableOffers.isEmpty) {
                            return Center(
                              child: Text(
                                "No offers available at the moment",
                                style: AppTokens.body(context).copyWith(
                                  color: AppTokens.muted(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          return (Platform.isMacOS || Platform.isWindows)
                              ? GridView.builder(
                                  itemCount: _store.availableOffers.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 3.8,
                                  ),
                                  itemBuilder: (context, index) {
                                    final offer =
                                        _store.availableOffers[index];
                                    return _buildOfferCard(offer, index);
                                  },
                                )
                              : ListView.separated(
                                  itemCount: _store.availableOffers.length,
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final offer =
                                        _store.availableOffers[index];
                                    return _buildOfferCard(offer, index);
                                  },
                                );
                        },
                      ),
                    ),
                    const SizedBox(height: AppTokens.s24),
                    Observer(builder: (_) {
                      final isApplied = _store.appliedOffer != null &&
                          selectedIndex != -1 &&
                          _store.availableOffers.isNotEmpty &&
                          _store.availableOffers[selectedIndex].id ==
                              _store.appliedOffer!.id;

                      return SizedBox(
                        width: double.infinity,
                        child: _OfferCta(
                          enabled: selectedIndex != -1,
                          danger: isApplied,
                          label: isApplied ? "Remove Offer" : "Apply Offer",
                          onTap: () {
                            if (isApplied) {
                              _store.clearOffer();
                              Navigator.pop(context, {'applied': false});
                            } else {
                              final selectedOffer =
                                  _store.availableOffers[selectedIndex];

                              debugPrint(
                                  'Selected offer: ${selectedOffer.title}');
                              debugPrint(
                                  'isPercentage: ${selectedOffer.isPercentage}');
                              debugPrint(
                                  'isFixPrice: ${selectedOffer.isFixPrice}');
                              debugPrint(
                                  'discountPercentage: ${selectedOffer.discountPercentage}');
                              debugPrint(
                                  'discountPrize: ${selectedOffer.discountPrize}');

                              final success = _store.applyOffer(
                                selectedOffer,
                                widget.plans,
                                selectedBooks: widget.books,
                                bookQuantities: widget.bookQuantities,
                              );

                              if (success) {
                                debugPrint(
                                    'Applied discount amount: ${_store.discountAmount}');
                                Navigator.pop(context, {'applied': true});
                              } else {
                                BottomToast.showBottomToastOverlay(
                                  context: context,
                                  errorMessage: _store.offerError ??
                                      "Could not apply offer",
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                );
                              }
                            }
                          },
                        ),
                      );
                    })
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(OfferModel offer, int index) {
    final isApplied = _store.appliedOffer != null &&
        offer.id == _store.appliedOffer!.id;
    final bool highlighted = selectedIndex == index || isApplied;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r16),
        onTap: () => setState(() => selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.only(left: 15, right: 10, top: 15, bottom: 10),
          decoration: BoxDecoration(
            color: highlighted
                ? AppTokens.accentSoft(context)
                : AppTokens.surface(context),
            borderRadius: BorderRadius.circular(AppTokens.r16),
            border: Border.all(
              color: highlighted
                  ? AppTokens.brand
                  : AppTokens.border(context),
              width: highlighted ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.title ?? "Offer",
                            style: AppTokens.body(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTokens.ink(context),
                            ),
                          ),
                        ),
                        if (isApplied)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTokens.successSoft(context),
                              borderRadius:
                                  BorderRadius.circular(AppTokens.r8),
                              border: Border.all(
                                  color: AppTokens.success(context)
                                      .withOpacity(0.35)),
                            ),
                            child: Text(
                              "Applied",
                              style: AppTokens.caption(context).copyWith(
                                color: AppTokens.success(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.description ?? "No description",
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.muted(context),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s8),
                    Text(
                      offer.isPercentage == true
                          ? "${offer.discountPercentage?.toStringAsFixed(0) ?? '0'}% OFF"
                          : "\u20B9${offer.discountPrize?.toStringAsFixed(0) ?? '0'} OFF",
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.success(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<int>(
                value: index,
                groupValue: selectedIndex,
                activeColor: AppTokens.brand,
                onChanged: (val) => setState(() => selectedIndex = val!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary CTA for the offers screen — brand gradient when applying,
/// danger solid when removing, gray when disabled.
class _OfferCta extends StatelessWidget {
  final bool enabled;
  final bool danger;
  final String label;
  final VoidCallback onTap;
  const _OfferCta({
    required this.enabled,
    required this.danger,
    required this.label,
    required this.onTap,
  });

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
              gradient: danger
                  ? null
                  : const LinearGradient(
                      colors: [AppTokens.brand, AppTokens.brand2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: danger ? AppTokens.danger(context) : null,
              borderRadius: BorderRadius.circular(AppTokens.r12),
            ),
            child: Center(
              child: Text(
                label,
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

/// Small flat rounded CTA used for the Retry button in the error state.
class _FlatCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FlatCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r8),
        onTap: onTap,
        child: Ink(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: AppTokens.brand,
            borderRadius: BorderRadius.circular(AppTokens.r8),
          ),
          child: Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
