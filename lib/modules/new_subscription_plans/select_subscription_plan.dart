// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, library_private_types_in_public_api, use_build_context_synchronously, avoid_print

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/model/all_plans_model.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/store/subscription_plan_store.dart';
import 'package:shusruta_lms/modules/login/store/login_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';

class SelectSubscriptionPlan extends StatefulWidget {
  final String categoryId;
  final String subcategoryId;
  
  const SelectSubscriptionPlan({
    super.key,
    required this.categoryId,
    required this.subcategoryId,
  });

  @override
  State<SelectSubscriptionPlan> createState() => _SelectSubscriptionPlanState();
  
  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => MultiProvider(
        providers: [
          Provider<SubscriptionPlanStore>(
            create: (_) => SubscriptionPlanStore(),
          ),
          Provider<LoginStore>(
            create: (_) => LoginStore(),
          ),
        ],
        child: SelectSubscriptionPlan(
        categoryId: args['categoryId'] ?? '',
        subcategoryId: args['subcategoryId'] ?? '',
        ),
      ),
    );
  }
}

class _SelectSubscriptionPlanState extends State<SelectSubscriptionPlan> {
  late SubscriptionPlanStore _store;
  late LoginStore _loginStore;
  
  // Track added plans
  List<Map<String, dynamic>> addedPlans = [];
  
  // Track added books
  List<Map<String, dynamic>> addedBooks = [];
  
  bool showAddedPlansContainer = false;
  
  @override
  void initState() {
    super.initState();
    _store = Provider.of<SubscriptionPlanStore>(context, listen: false);
    _loginStore = Provider.of<LoginStore>(context, listen: false);
    _loadSettingsDataAndPlans();
  }
  
  Future<void> _loadSettingsDataAndPlans() async {
    // First load settings data
    await _loadSettingsData();
    // Then load plans with the settings data available
    await _loadData();
  }
  
  Future<void> _loadData() async {
    // Set IAP flag based on settings before loading plans
    final bool isIAPEnabled = _loginStore.settingsData.value?.isInAPurchases == true;
    debugPrint("isIAPEnabled: $isIAPEnabled");
    debugPrint("login isIAPEnabled: ${_loginStore.settingsData.value?.isInAPurchases}");
    _store.setIAPEnabled(isIAPEnabled);
    
    await _store.getAllPlansForUser(widget.categoryId, widget.subcategoryId);
  }
  
  Future<void> _loadSettingsData() async {
    await _loginStore.onGetSettingsData();
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
            colors: [AppTokens.brand, AppTokens.brand2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                  if (Navigator.of(context).canPop()) ...[
                    IconButton(
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                  const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT),
                  Text(
                    "Select Subscription Plan",
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
                                  'Error: ${_store.error}',
                              style: interRegular.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    if (_store.allPlans.isEmpty) {
                      return Center(
                        child: Text(
                          'No subscription plans available',
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                        ),
                      );
                    }
                    
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
                              // color: AppColors.grey1.withOpacity(0.3),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(
                                      _store.availableMonths.length,
                                  (index) => Padding(
                                    padding: const EdgeInsets.only(
                                      right: Dimensions.PADDING_SIZE_EXTRA_SMALL - 2),
                                    child: GestureDetector(
                                      onTap: () {
                                            _store.setCurrentMonthIndex(index);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: Dimensions.PADDING_SIZE_DEFAULT,
                                          vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.2),
                                        decoration: BoxDecoration(
                                              color: _store.currentMonthIndex == index
                                            ? AppColors.blueFinal
                                            : Colors.white.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(
                                            Dimensions.PADDING_SIZE_EXTRA_LARGE * 2),
                                        ),
                                        child: Text(
                                              _store.availableMonths[index],
                                          style: interRegular.copyWith(
                                            fontSize: Dimensions.fontSizeExtraSmall,
                                                color: _store.currentMonthIndex == index
                                              ? ThemeManager.white
                                              : ThemeManager.black.withOpacity(0.8),
                                            fontWeight: FontWeight.w500,
                                          )
                                        ),
                                      ),
                                    ),
                                  )
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Plan Cards
                              if (_store.currentMonthIndex < _store.allPlans.length && 
                                  _store.allPlans[_store.currentMonthIndex].subscription != null) ...[
                            (Platform.isMacOS || Platform.isWindows)
                              ? SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.6,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Calculate appropriate aspect ratio based on available width
                                      final crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
                                      // Fixed height cards require specific aspect ratio calculation
                                      final cardWidth = (constraints.maxWidth - 16) / crossAxisCount; // Account for spacing
                                      final cardHeight = 280.0; // Fixed height from plan card
                                      final childAspectRatio = cardWidth / cardHeight;
                                      
                                      return GridView.builder(
                                        shrinkWrap: false,
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        itemCount: _store.allPlans[_store.currentMonthIndex].subscription?.length ?? 0,
                                        padding: EdgeInsets.zero,
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          childAspectRatio: childAspectRatio,
                                        ),
                                        itemBuilder: (_, index) => _buildPlanCard(_store.allPlans[_store.currentMonthIndex].subscription![index]),
                                      );
                                    },
                                  ),
                                )
                              : Column(
                                  children: List.generate(
                                        _store.allPlans[_store.currentMonthIndex].subscription?.length ?? 0,
                                        (index) => _buildPlanCard(_store.allPlans[_store.currentMonthIndex].subscription![index])
                                  ),
                                ),
                          ],

                              // Books Horizontal List
                              Observer(
                                builder: (_) {
                                  // Show books section only if there are books available
                                  List<HardCopyBookModel> books = [];
                                  
                                  // Only get books from the current selected month/duration
                                  if (_store.currentMonthIndex < _store.allPlans.length && 
                                      _store.allPlans[_store.currentMonthIndex].subscription != null) {
                                    
                                    for (final plan in _store.allPlans[_store.currentMonthIndex].subscription ?? []) {
                                      if (plan.hardCopyBooks != null && plan.hardCopyBooks!.isNotEmpty) {
                                        books.addAll(plan.hardCopyBooks!);
                                      }
                                    }
                                  }
                                  
                                  // Only show the books section if there are books available
                                  if (books.isEmpty) {
                                    return const SizedBox.shrink(); // Hide the section completely if no books
                                  }
                                  
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                          const SizedBox(height: 16),
                          Text(
                            _loginStore.settingsData.value?.hardCopyOff != null && _loginStore.settingsData.value!.hardCopyOff!.isNotEmpty
                                ? 'Get ${_loginStore.settingsData.value!.hardCopyOff}% off'
                                : 'Get discount on books',
                            style: interBold.copyWith(
                              fontSize: Dimensions.fontSizeExtraLarge,
                              fontWeight: FontWeight.w600,
                              color: ThemeManager.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _loginStore.settingsData.value?.hardCopydes != null && _loginStore.settingsData.value!.hardCopydes!.isNotEmpty
                                ? _loginStore.settingsData.value!.hardCopydes!
                                : 'Purchase Hardcopy notes to get more off',
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
                                            // Check if book already added
                                            final isAdded = false; // Implement your logic to check if book is added
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
                              
                              // Add space at bottom if added plans container is shown
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
    // Calculate total price
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
                  
                  const SizedBox(height: 12,),
                  Divider(
                    color: ThemeManager.white,
                    height: 1,
                  ),
                  const SizedBox(height: 12,),
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
                  // Handle continue button press
                  Navigator.of(context).pushNamed(
                    Routes.newCheckoutPlan,
                    arguments: {
                      'plans': List<Map<String, dynamic>>.from(addedPlans),
                      'books': List<Map<String, dynamic>>.from(addedBooks),
                      'totalPrice': totalPrice
                    }
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.summitBorder,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8)
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
          
          // Hide container if no plans are added
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
    
    // Calculate discounted price if there's an offer
    int discountedPrice = originalPrice;
    int percent = 0;
    if (offer.isNotEmpty) {
      if (offer.contains('%')) {
        // Handle percentage offers (e.g., "20%")
        final percentStr = offer.replaceAll('%', '').trim();
        // Try parsing as double, then round
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
    // Clamp discountedPrice to a minimum of 0
    discountedPrice = discountedPrice < 0 ? 0 : discountedPrice;
    // Debug prints
    print('Plan Debug => originalPrice: '
        '\u001b[33m$originalPrice\u001b[0m, offer: '
        '\u001b[36m$offer\u001b[0m, percent: '
        '\u001b[35m$percent\u001b[0m, discountedPrice: '
        '\u001b[32m$discountedPrice\u001b[0m');
    
    // Check if this plan is already added
    final isPlanAdded = addedPlans.any((addedPlan) => 
      addedPlan['id'] == plan.id && addedPlan['durationId'] == durationInfo?.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.white.withOpacity(0.3), width: 0.86),
        color: ThemeManager.white,
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: ThemeManager.grey.withOpacity(0.1),
        //     spreadRadius: 1,
        //     blurRadius: 5,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate available height for benefits section
          final isDesktop = Platform.isMacOS || Platform.isWindows;
          final baseCardHeight = isDesktop ? 280.0 : 350.0;
          
          return IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section - Fixed height
                Text(
                  plan.planName ?? 'Subscription Plan',
                  style: interBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager.black,
                  ),
                ),
                const SizedBox(height: 8),
                if (plan.description != null && plan.description!.isNotEmpty)
                  Html(
                    data: '''
                              <div style="color: ${ThemeManager.currentTheme == AppTheme.Dark ? 'white' : 'black'};">
                              ${plan.description!}
                              </div>
                              ''',
                    style: {
                      "div": Style(
                        fontSize: FontSize(Dimensions.fontSizeSmall),
                        color: ThemeManager.black,
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      "p": Style(
                        fontSize: FontSize(Dimensions.fontSizeSmall),
                        color: ThemeManager.black,
                        margin: Margins.only(bottom: 4),
                        padding: HtmlPaddings.zero,
                      ),
                      "strong": Style(
                        fontSize: FontSize(Dimensions.fontSizeSmall),
                        fontWeight: FontWeight.bold,
                        color: ThemeManager.black,
                      ),
                      "b": Style(
                        fontSize: FontSize(Dimensions.fontSizeSmall),
                        fontWeight: FontWeight.bold,
                        color: ThemeManager.black,
                      ),
                      "em": Style(
                        fontSize: FontSize(Dimensions.fontSizeSmall),
                        fontStyle: FontStyle.italic,
                        color: ThemeManager.black,
                      ),
                      "i": Style(
                        fontSize: FontSize(Dimensions.fontSizeSmall),
                        fontStyle: FontStyle.italic,
                        color: ThemeManager.black,
                      ),
                      "ul": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      "li": Style(
                        fontSize: FontSize(Dimensions.fontSizeSmall),
                        color: ThemeManager.black,
                        margin: Margins.only(bottom: 2),
                      ),
                    },
                  ),
                const SizedBox(height: 8),
                
                // Benefits Section - Scrollable
                Text(
                  'Inclusions',
                  style: interSemiBold.copyWith(
                    fontSize: Dimensions.fontSizeSmallLarge,
                    fontWeight: FontWeight.w500,
                    color: ThemeManager.black,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Scrollable Benefits Container
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: baseCardHeight * 0.4, // 40% of base card height for benefits
                      minHeight: 80, // Minimum height for benefits section
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Bottom Section - Fixed height
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
                                Flexible(
                                  child: Text(
                                    '₹$originalPrice',
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.grey4,
                                      decoration: TextDecoration.lineThrough,
                                    ),
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
                                "$offer% off",
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
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isPlanAdded) {
                            // Remove the plan if already added
                            setState(() {
                              addedPlans.removeWhere((addedPlan) => 
                                addedPlan['id'] == plan.id && 
                                addedPlan['durationId'] == durationInfo?.id);
                              
                              // Hide container if no plans are added
                              _updateAddedPlansContainerVisibility();
                            });
                          } else {
                            // Add the plan
                            setState(() {
                              addedPlans.add({
                                'id': plan.id,
                              'durationId': durationInfo?.id,
                                'name': plan.planName ?? 'First Plan',
                              'price': discountedPrice,
                                'originalPrice': originalPrice != discountedPrice ? originalPrice : null,
                              'day': durationInfo?.day,
                                'benifit': plan.benifit ?? [],
                              });
                              
                              // Show container when plans are added
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
        },
      ),
    );
  }

  Widget _buildBookCard(HardCopyBookModel? book, bool isAdded) {
    if (book == null) return const SizedBox.shrink();
    
    final bookName = book.bookName ?? 'Surgery notes Powerhouse';
    final bookType = book.bookType ?? 'Book Type 1';
    final price = book.price ?? 1200;
    
    // Calculate discounted price based on settings data instead of using comboPrice
    int discountedPrice = price;
    int discount = 0;
    if (_loginStore.settingsData.value?.hardCopyOff != null && 
        _loginStore.settingsData.value!.hardCopyOff!.isNotEmpty) {
      final discountStr = _loginStore.settingsData.value!.hardCopyOff!;
      discount = int.tryParse(discountStr) ?? 0;
      if (discount > 0) {
        discountedPrice = price - (price * discount ~/ 100);
      }
    }
    // Clamp discountedPrice to a minimum of 0
    discountedPrice = discountedPrice < 0 ? 0 : discountedPrice;
    // Debug prints
    print('Book Debug => price: '
        '[33m$price[0m, discount: '
        '[35m$discount[0m, discountedPrice: '
        '[32m$discountedPrice[0m');
    
    // Note: Using static asset instead of network image

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
              child:
              // Image.network(
              //   imageUrl,
              //   fit: BoxFit.cover,
              //   width: double.infinity,
              //   errorBuilder: (context, error, stackTrace) {
              //     return Image.network(
              //   'https://via.placeholder.com/150x100',
              //   fit: BoxFit.cover,
              //   width: double.infinity,
              //     );
              //   },
              // ),
              Image.asset("assets/image/bookCover.png",
                fit: BoxFit.fitWidth,
                width: 180,
                height: 120,),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bookName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: interSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        fontWeight: FontWeight.w500,
                        color: ThemeManager.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(bookType,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grey4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            // Remove the book
                            setState(() {
                              addedBooks.removeWhere((addedBook) => addedBook['id'] == book.id);
                              _updateAddedPlansContainerVisibility();
                            });
                          } else {
                            // Add the book
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
                        // Show book details
                        _showBookDetails(book);
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
  
  void _updateAddedPlansContainerVisibility() {
    showAddedPlansContainer = addedPlans.isNotEmpty || addedBooks.isNotEmpty;
  }
  
  void _showBookDetails(HardCopyBookModel book) {
    // Calculate discounted price based on settings data
    final price = book.price ?? 0;
    int discountedPrice = price;
    
    if (_loginStore.settingsData.value?.hardCopyOff != null && 
        _loginStore.settingsData.value!.hardCopyOff!.isNotEmpty) {
      final discountStr = _loginStore.settingsData.value!.hardCopyOff!;
      final discount = int.tryParse(discountStr) ?? 0;
      if (discount > 0) {
        discountedPrice = price - (price * discount ~/ 100);
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book.bookImg ?? 'https://via.placeholder.com/150x100',
                      width: 100,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          'https://via.placeholder.com/150x100',
                          width: 100,
                          height: 140,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.bookName ?? 'Book Title',
                          style: interBold.copyWith(
                            fontSize: Dimensions.fontSizeExtraLarge,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.bookType ?? 'Book Type',
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '₹$discountedPrice',
                              style: interBold.copyWith(
                                fontSize: Dimensions.fontSizeExtraLarge,
                                color: ThemeManager.blueFinal,
                              ),
                            ),
                            if (price != discountedPrice) ...[
                              const SizedBox(width: 8),
                              Text(
                                '₹$price',
                                style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Colors.grey[600],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              Text(
                'Description',
                style: interBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book.description ?? 'No description available',
                style: interRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Colors.grey[700],
                ),
              ),
              
              const SizedBox(height: 24),
              if (book.notesOverview != null && book.notesOverview!.isNotEmpty) ...[
                Text(
                  'Contents',
                  style: interBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: book.notesOverview!.length,
                    itemBuilder: (context, index) {
                      final chapter = book.notesOverview![index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ThemeManager.blueFinal,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${chapter.chapter ?? index + 1}',
                            style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        title: Text(
                          chapter.chapterName ?? 'Chapter ${index + 1}',
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Colors.black,
                          ),
                        ),
                        trailing: Text(
                          'Page ${chapter.pageNumber ?? '-'}',
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeManager.blueFinal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Check if this book is already added
                    final isBookAdded = addedBooks.any((addedBook) => addedBook['id'] == book.id);
                    
                    if (isBookAdded) {
                      // Remove the book if already added
                      setState(() {
                        addedBooks.removeWhere((addedBook) => addedBook['id'] == book.id);
                        _updateAddedPlansContainerVisibility();
                      });
                    } else {
                      // Add the book with the correct discounted price
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
                    
                    Navigator.pop(context);
                  },
                  child: Text(
                    addedBooks.any((addedBook) => addedBook['id'] == book.id)
                        ? 'Remove from Cart' : 'Add to Cart',
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 