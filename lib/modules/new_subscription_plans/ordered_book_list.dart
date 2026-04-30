// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/helpers/styles.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/model/ordered_book_model.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/store/ordered_book_store.dart';

/// OrderedBookListScreen — post-payment hardcopy orders list. Loads the
/// learner's orders via [OrderedBookStore.getAllUserBooks], renders a
/// responsive layout (3-column grid on desktop, 2-column on tablet,
/// single-column list on mobile), and opens `Routes.trackOrder` for each
/// card with `{orderId, productName, bookType, quantity}`.
///
/// Public surface preserved exactly:
///   • class [OrderedBookListScreen] + const constructor `{super.key}`
///   • static [routeName] = "/ordered-book-list"
///   • MobX: `_orderedBookStore.getAllUserBooks`, `orderedBooks`,
///     `isLoading`, `error`
///   • Navigation to `Routes.trackOrder` with the same arg shape
class OrderedBookListScreen extends StatefulWidget {
  static const String routeName = "/ordered-book-list";

  const OrderedBookListScreen({super.key});

  @override
  State<OrderedBookListScreen> createState() =>
      _OrderedBookListScreenState();
}

class _OrderedBookListScreenState extends State<OrderedBookListScreen> {
  late OrderedBookStore _orderedBookStore;

  @override
  void initState() {
    super.initState();
    _orderedBookStore =
        Provider.of<OrderedBookStore>(context, listen: false);
    _loadData();
  }

  Future<void> _loadData() async {
    await _orderedBookStore.getAllUserBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          // Brand gradient hero with rounded spacer
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
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
                                    color:
                                        Colors.white.withOpacity(0.18)),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          "My Ordered Books",
                          style: AppTokens.titleMd(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTokens.scaffold(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.r28),
                        topRight: Radius.circular(AppTokens.r28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppTokens.brand,
              child: Observer(
                builder: (_) {
                  if (_orderedBookStore.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTokens.brand,
                      ),
                    );
                  }

                  if (_orderedBookStore.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTokens.dangerSoft(context),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline_rounded,
                              size: 36,
                              color: AppTokens.danger(context),
                            ),
                          ),
                          const SizedBox(height: AppTokens.s16),
                          Text(
                            'Error loading books',
                            style: AppTokens.titleSm(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTokens.ink(context),
                            ),
                          ),
                          const SizedBox(height: AppTokens.s8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.s24),
                            child: Text(
                              _orderedBookStore.error!,
                              textAlign: TextAlign.center,
                              style: AppTokens.caption(context).copyWith(
                                color: AppTokens.muted(context),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTokens.s20),
                          _BrandCta(
                            label: 'Retry',
                            onTap: _loadData,
                          ),
                        ],
                      ),
                    );
                  }

                  if (_orderedBookStore.orderedBooks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppTokens.accentSoft(context),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.book_outlined,
                              size: 56,
                              color: AppTokens.brand,
                            ),
                          ),
                          const SizedBox(height: AppTokens.s20),
                          Text(
                            'No books ordered yet',
                            style: AppTokens.titleSm(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTokens.ink(context),
                            ),
                          ),
                          const SizedBox(height: AppTokens.s8),
                          Text(
                            'Your ordered books will appear here',
                            style: AppTokens.body(context).copyWith(
                              color: AppTokens.muted(context),
                            ),
                          ),
                          const SizedBox(height: AppTokens.s24),
                          _BrandCta(
                            label: 'Go Back',
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  }

                  // Use MediaQuery to determine the screen size and adapt layout
                  final screenWidth = MediaQuery.of(context).size.width;

                  if (screenWidth > 1200) {
                    // Desktop layout (3 columns)
                    return _buildGridLayout(3, 0.8);
                  } else if (screenWidth > 600) {
                    // Tablet layout (2 columns)
                    return _buildGridLayout(2, 1.0);
                  } else {
                    // Mobile layout (list view)
                    return _buildListLayout();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListLayout() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _orderedBookStore.orderedBooks.length,
      itemBuilder: (context, index) {
        final book = _orderedBookStore.orderedBooks[index];
        return _buildBookCard(book);
      },
    );
  }

  Widget _buildGridLayout(int crossAxisCount, double ratio) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: ratio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _orderedBookStore.orderedBooks.length,
      itemBuilder: (context, index) {
        final book = _orderedBookStore.orderedBooks[index];
        return _buildBookCard(book);
      },
    );
  }

  Widget _buildBookCard(OrderedBookModel book) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          onTap: () {
            // Navigate to TrackOrderScreen with the book's order_id
            Navigator.of(context).pushNamed(
              Routes.trackOrder,
              arguments: {
                'orderId': book.orderId ?? '',
                'productName': book.bookName,
                'bookType': book.bookType,
                'quantity': book.quantity,
              },
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              borderRadius: BorderRadius.circular(AppTokens.r16),
              border: Border.all(color: AppTokens.border(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand-gradient top banner with order chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTokens.brand, AppTokens.brand2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppTokens.r16),
                      topRight: Radius.circular(AppTokens.r16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.book_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          book.bookType ?? 'Hardcopy Book',
                          style: AppTokens.caption(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Order ID: ${book.orderId ?? 'N/A'}',
                          style: AppTokens.caption(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTokens.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Book Details
                Padding(
                  padding: const EdgeInsets.all(AppTokens.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.bookName ?? 'Unknown Book',
                        style: AppTokens.titleSm(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTokens.ink(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (book.description != null &&
                          book.description!.isNotEmpty)
                        Text(
                          book.description!,
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 12),

                      // Details
                      Row(
                        children: [
                          _buildInfoColumn('Price', '\u20B9${book.price ?? 0}'),
                          const SizedBox(width: 16),
                          _buildInfoColumn(
                              'Quantity', '${book.quantity ?? 1}'),
                          const SizedBox(width: 16),
                          if (book.discountPrice != null &&
                              book.discountPrice! > 0)
                            _buildInfoColumn(
                                'Discount', '\u20B9${book.discountPrice}'),
                        ],
                      ),

                      const SizedBox(height: 12),
                      if (book.deliveryCharge != null &&
                          book.deliveryCharge! > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Delivery Charge:',
                                style: AppTokens.caption(context).copyWith(
                                  color: AppTokens.muted(context),
                                ),
                              ),
                              Text(
                                '\u20B9${book.deliveryCharge}',
                                style: AppTokens.caption(context).copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.ink(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Divider(
                        height: 1,
                        color: AppTokens.border(context),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: AppTokens.body(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTokens.ink(context),
                            ),
                          ),
                          Text(
                            '\u20B9${(book.price ?? 0) + (book.deliveryCharge ?? 0) - (book.discountPrice ?? 0)}',
                            style: AppTokens.titleSm(context).copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTokens.brand,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.muted(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppTokens.ink(context),
          ),
        ),
      ],
    );
  }
}

/// Brand-gradient pill CTA used in empty / error states.
class _BrandCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BrandCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Text(
            label,
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
