// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, prefer_final_fields, unnecessary_import

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import '../new_subscription_plans/model/all_plans_model.dart';
import 'upgrade_plan_store.dart';
import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';

class SelectUpgradePlanScreen extends StatefulWidget {
  final String subscriptionId;
  final bool sameValidity;
  final bool isDiffValidity;
  // Add more params as needed

  const SelectUpgradePlanScreen({
    super.key,
    required this.subscriptionId,
    required this.sameValidity,
    required this.isDiffValidity,
  });

  @override
  State<SelectUpgradePlanScreen> createState() => _SelectUpgradePlanScreenState();
}

class _SelectUpgradePlanScreenState extends State<SelectUpgradePlanScreen> {
  late UpgradePlanStore _store;
  int currentMonthIndex = 0;
  List<Map<String, dynamic>> addedPlans = [];
  bool showAddedPlansContainer = false;
  List<Map<String, dynamic>> addedBooks = [];

  @override
  void initState() {
    super.initState();
    _store = UpgradePlanStore();
    _fetchUpgradePlans();
  }

  Future<void> _fetchUpgradePlans() async {
    // Only pass the selected flag as non-null
    if (widget.sameValidity) {
      await _store.fetchUpgradePlans(
        subscriptionId: widget.subscriptionId,
        sameValidity: true,
        isDiffValidity: null,
      );
    } else if (widget.isDiffValidity) {
      await _store.fetchUpgradePlans(
        subscriptionId: widget.subscriptionId,
        sameValidity: null,
        isDiffValidity: true,
      );
    } else {
      // Default fallback: fetch with no flags (should not happen in normal flow)
      await _store.fetchUpgradePlans(
        subscriptionId: widget.subscriptionId,
        sameValidity: null,
        isDiffValidity: null,
      );
    }
  }

  void _updateAddedPlansContainerVisibility() {
    setState(() {
      showAddedPlansContainer = addedPlans.isNotEmpty || addedBooks.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    final horizontalPadding = isDesktop || isTablet ? 32.0 : 16.0;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTokens.brand, AppTokens.brand2],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // HEADER BAR
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
                      IconButton(
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT),
                      Text(
                        "Select Upgrade Plan",
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // MAIN CONTENT
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.PADDING_SIZE_SMALL,
                      vertical: Dimensions.PADDING_SIZE_SMALL,
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
                    child: Observer(
                      builder: (_) {
                        if (_store.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (_store.error != null) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Error: \\${_store.error}',
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchUpgradePlans,
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          );
                        }
                        if (_store.plansList.isEmpty) {
                          return Center(
                            child: Text(
                              'No upgrade plans available',
                              style: interRegular.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                            ),
                          );
                        }
                        // Month/duration tabs
                        final availableMonths = _store.plansList.map((plan) => plan.month ?? '').toList();
                        // Current plans for selected month
                        final currentPlans = _store.plansList.isNotEmpty && currentMonthIndex < _store.plansList.length
                            ? _store.plansList[currentMonthIndex].subscription ?? []
                            : [];
                        return SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: horizontalPadding,
                            right: horizontalPadding,
                            top: 12,
                            bottom: showAddedPlansContainer ? 100 : 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Month selection tabs
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: List.generate(
                                      availableMonths.length,
                                      (index) => Padding(
                                        padding: const EdgeInsets.only(
                                            right: Dimensions.PADDING_SIZE_EXTRA_SMALL - 2),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              currentMonthIndex = index;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: Dimensions.PADDING_SIZE_DEFAULT,
                                              vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.2),
                                            decoration: BoxDecoration(
                                              color: currentMonthIndex == index
                                                  ? AppColors.blueFinal
                                                  : Colors.white.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(
                                                Dimensions.PADDING_SIZE_EXTRA_LARGE * 2),
                                            ),
                                            child: Text(
                                              availableMonths[index],
                                              style: interRegular.copyWith(
                                                fontSize: Dimensions.fontSizeExtraSmall,
                                                color: currentMonthIndex == index
                                                    ? ThemeManager.white
                                                    : ThemeManager.black.withOpacity(0.8),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Plan Cards
                              if (currentPlans.isNotEmpty)
                                Column(
                                  children: List.generate(
                                    currentPlans.length,
                                    (index) => _buildPlanCard(currentPlans[index]),
                                  ),
                                ),
                              // Hardcopy Books Horizontal List (Upgrade Flow)
                              Builder(
                                builder: (_) {
                                  List<HardCopyBookModel> books = [];
                                  // Only get books from the current selected month/duration
                                  for (final plan in currentPlans) {
                                    if (plan.hardCopyBooks != null && plan.hardCopyBooks!.isNotEmpty) {
                                      books.addAll(plan.hardCopyBooks!);
                                    }
                                  }
                                  if (books.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 16),
                                      Text(
                                        'Get discount on books',
                                        style: interBold.copyWith(
                                          fontSize: Dimensions.fontSizeExtraLarge,
                                          fontWeight: FontWeight.w600,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Purchase Hardcopy notes to get more off',
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.grey4,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: 210,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: books.length,
                                          itemBuilder: (context, index) {
                                            final isAdded = addedBooks.any((b) => b['id'] == books[index].id);
                                            return Padding(
                                              padding: EdgeInsets.only(right: index < books.length - 1 ? 16 : 0),
                                              child: _buildBookCard(books[index], isAdded),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              if (showAddedPlansContainer)
                                const SizedBox(height: 80),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            // Bottom container for added plans
            if (showAddedPlansContainer)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildAddedPlansContainer(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddedPlansContainer() {
    int totalPrice = 0;
    for (var plan in addedPlans) {
      totalPrice += plan['price'] as int;
    }
    for (var book in addedBooks) {
      totalPrice += book['price'] as int;
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: ThemeManager.blueFinal,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...addedPlans.map((plan) => _buildPlanItemRow(plan)),
                  
                  // Show added books
                  ...addedBooks.map((book) => _buildBookItemRow(book)),
                  
                  const SizedBox(height: 12),
                  Divider(
                    color: ThemeManager.white,
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Total',
                        style: interBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          fontWeight: FontWeight.w600,
                          color: ThemeManager.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹$totalPrice',
                        style: interBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          fontWeight: FontWeight.w600,
                          color: ThemeManager.white,
                        ),
                      ),
                      Text(
                        ' (GST Included)',
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          fontWeight: FontWeight.w400,
                          color: ThemeManager.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the same checkout page as subscription plan but with upgrade parameters
                  Navigator.of(context).pushNamed(
                    Routes.newCheckoutPlan,
                    arguments: {
                      'plans': List<Map<String, dynamic>>.from(addedPlans),
                      'books': List<Map<String, dynamic>>.from(addedBooks),
                      'totalPrice': totalPrice,
                      'isUpgrade': true, // Flag to indicate this is an upgrade flow
                      'subscriptionId': widget.subscriptionId, // Pass the subscription ID
                    }
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.summitBorder,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Continue',
                  style: interBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanItemRow(Map<String, dynamic> plan) {
    return GestureDetector(
      onTap: () {
        setState(() {
          addedPlans.removeWhere((addedPlan) =>
              addedPlan['id'] == plan['id'] &&
              addedPlan['durationId'] == plan['durationId']);
          _updateAddedPlansContainerVisibility();
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: ThemeManager.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: ThemeManager.white, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                plan['name'],
                style: interRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  fontWeight: FontWeight.w500,
                  color: ThemeManager.white,
                ),
              ),
            ),
            Text(
              '₹${plan['price']}',
              style: interRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                fontWeight: FontWeight.w500,
                color: ThemeManager.white,
              ),
            ),
            if (plan['originalPrice'] != null && plan['originalPrice'] != plan['price'])
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '₹${plan['originalPrice']}',
                  style: interRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    fontWeight: FontWeight.w400,
                    color: ThemeManager.white.withOpacity(0.7),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.remove_circle_outline,
              color: ThemeManager.white.withOpacity(0.7),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookItemRow(Map<String, dynamic> book) {
    return GestureDetector(
      onTap: () {
        setState(() {
          addedBooks.removeWhere((addedBook) => addedBook['id'] == book['id']);
          _updateAddedPlansContainerVisibility();
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: ThemeManager.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.menu_book, color: ThemeManager.white, size: 14),
            ),
            const SizedBox(width: 8),
            Text(
              book['name'],
              style: interRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                fontWeight: FontWeight.w500,
                color: ThemeManager.white,
              ),
            ),
            const Spacer(),
            Text(
              '₹${book['price']}',
              style: interRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                fontWeight: FontWeight.w500,
                color: ThemeManager.white,
              ),
            ),
            if (book['originalPrice'] != null && book['originalPrice'] != book['price'])
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '₹${book['originalPrice']}',
                  style: interRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    fontWeight: FontWeight.w400,
                    color: ThemeManager.white.withOpacity(0.7),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.remove_circle_outline,
              color: ThemeManager.white.withOpacity(0.7),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlanModel plan) {
    final durationInfo = plan.duration?.isNotEmpty == true ? plan.duration![0] : null;
    final originalPrice = durationInfo?.price ?? 0;
    final offer = durationInfo?.offer ?? '';
    int discountedPrice = originalPrice;
    int percent = 0;
    if (offer.isNotEmpty) {
      if (offer.contains('%')) {
        // Handle percentage offers (e.g., "20%")
        final percentStr = offer.replaceAll('%', '').trim();
        final percentDouble = double.tryParse(percentStr) ?? 0.0;
        percent = percentDouble.round();
      } else {
        // Handle integer offers (e.g., "20" - treat as percentage)
        final percentDouble = double.tryParse(offer.trim()) ?? 0.0;
        percent = percentDouble.round();
      }
      
      if (percent > 0) {
        discountedPrice = originalPrice - (originalPrice * percent ~/ 100);
      }
    }
    discountedPrice = discountedPrice < 0 ? 0 : discountedPrice;
    final isPlanAdded = addedPlans.any((addedPlan) =>
        addedPlan['id'] == plan.id && addedPlan['durationId'] == durationInfo?.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.white.withOpacity(0.3), width: 0.86),
        color: ThemeManager.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.planName ?? 'Upgrade Plan',
            style: interBold.copyWith(
              fontSize: Dimensions.fontSizeExtraLarge,
              fontWeight: FontWeight.w600,
              color: ThemeManager.black,
            ),
          ),
          const SizedBox(height: 8),
          if (plan.description != null && plan.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                plan.description!,
                style: interRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: AppColors.grey4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Text(
            'Inclusions',
            style: interSemiBold.copyWith(
              fontSize: Dimensions.fontSizeSmallLarge,
              fontWeight: FontWeight.w500,
              color: ThemeManager.black,
            ),
          ),
          const SizedBox(height: 8),
          ...(plan.benifit ?? []).map((text) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check, size: 18, color: ThemeManager.blueFinal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    text,
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grey4,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '₹$discountedPrice',
                        style: interBold.copyWith(
                          fontSize: Dimensions.fontSizeDefaultOverLarge,
                          fontWeight: FontWeight.w600,
                          color: ThemeManager.blueFinal,
                        ),
                      ),
                      if (offer.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          "/ ",
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            fontWeight: FontWeight.w400,
                            color: AppColors.grey4,
                          ),
                        ),
                        Text(
                          '₹$originalPrice',
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            fontWeight: FontWeight.w400,
                            color: AppColors.grey4,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (offer.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.grey1,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        offer,
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          fontWeight: FontWeight.w400,
                          color: AppColors.grey4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(
                width: 120,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    if (isPlanAdded) {
                      setState(() {
                        addedPlans.removeWhere((addedPlan) =>
                            addedPlan['id'] == plan.id &&
                            addedPlan['durationId'] == durationInfo?.id);
                        _updateAddedPlansContainerVisibility();
                      });
                    } else {
                      setState(() {
                        addedPlans.add({
                          'id': plan.id,
                          'durationId': durationInfo?.id,
                          'name': plan.planName ?? 'Upgrade Plan',
                          'price': discountedPrice,
                          'originalPrice': originalPrice != discountedPrice ? originalPrice : null,
                          'day': durationInfo?.day,
                          'benifit': plan.benifit ?? [],
                        });
                        _updateAddedPlansContainerVisibility();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPlanAdded ? AppColors.paymentSuccessColor : AppColors.blueFinal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    isPlanAdded ? 'Added' : 'Add',
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      fontWeight: FontWeight.w400,
                      color: ThemeManager.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(HardCopyBookModel? book, bool isAdded) {
    if (book == null) return const SizedBox.shrink();
    final bookName = book.bookName ?? 'Surgery notes Powerhouse';
    final bookType = book.bookType ?? 'Book Type 1';
    final price = book.price ?? 1200;
    int discountedPrice = price;
    // For now, no discount logic (can be added if needed)
    discountedPrice = discountedPrice < 0 ? 0 : discountedPrice;
    final imageUrl = book.bookImg != null && book.bookImg!.isNotEmpty
        ? book.bookImg!
        : 'https://via.placeholder.com/150x100';
    final isBookAdded = addedBooks.any((addedBook) => addedBook['id'] == book.id);
    return Container(
      width: 180,
      decoration: BoxDecoration(
         border: Border.all(color: AppColors.white.withOpacity(0.3), width: 0.86),
        color: ThemeManager.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.fitWidth,
                width: 180,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    'https://via.placeholder.com/150x100',
                    fit: BoxFit.cover,
                    width: 180,
                    height: 120,
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.25,
                          child: Text(bookName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: interSemiBold.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              fontWeight: FontWeight.w500,
                              color: ThemeManager.black,
                        ),
                          ),
                        ),
                        Text(bookType,
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            fontWeight: FontWeight.w400,
                            color: AppColors.grey4,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹$discountedPrice',
                          style: interBold.copyWith(
                            fontSize: Dimensions.fontSizeExtraLarge,
                            fontWeight: FontWeight.w600,
                            color: ThemeManager.blueFinal,
                          ),),
                        if (price != discountedPrice)
                          Text('₹$price',
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            fontWeight: FontWeight.w400,
                            color: AppColors.grey4,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 80,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle book add/remove logic
                          if (isBookAdded) {
                            setState(() {
                              addedBooks.removeWhere((addedBook) => addedBook['id'] == book.id);
                              _updateAddedPlansContainerVisibility();
                            });
                          } else {
                            setState(() {
                              addedBooks.add({
                                'id': book.id,
                                'name': book.bookName ?? 'Book Title',
                                'type': book.bookType ?? 'Book Type',
                                'price': discountedPrice,
                                'originalPrice': price != discountedPrice ? price : null,
                                'imageUrl': book.bookImg,
                                'height': book.height,
                                'width': book.breadth, // Using breadth as width
                                'length': book.length,
                                'weight': book.weight,
                              });
                              _updateAddedPlansContainerVisibility();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBookAdded ? AppColors.paymentSuccessColor : AppColors.blueFinal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        ),
                        child: Text(isBookAdded ? 'Added' : 'Add',
                          style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          fontWeight: FontWeight.w400,
                          color: ThemeManager.white,
                        ),),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Show book details (optional, can be implemented if needed)
                      },
                      child: Text('View more',
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        fontWeight: FontWeight.w400,
                        color: AppColors.blueFinal,
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
} 