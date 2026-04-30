// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_local_variable, use_super_parameters

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import 'model/book_model.dart';
import 'store/hardcopy_store.dart';

/// Purchase hardcopy — grid of books + subscription promo + floating
/// "added to cart" tray. Redesigned with AppTokens. Provider wiring,
/// static route, and navigation targets (hardcopyDetails, newCheckoutPlan,
/// newSubscription) preserved.
class PurchaseHardcopyScreen extends StatefulWidget {
  const PurchaseHardcopyScreen({Key? key}) : super(key: key);

  static Route<dynamic> route(RouteSettings routeSettings) {
    return MaterialPageRoute(
      builder: (_) => Provider<HardcopyStore>(
        create: (_) => HardcopyStore(),
        child: const PurchaseHardcopyScreen(),
      ),
    );
  }

  @override
  State<PurchaseHardcopyScreen> createState() => _PurchaseHardcopyScreenState();
}

class _PurchaseHardcopyScreenState extends State<PurchaseHardcopyScreen> {
  late HardcopyStore _store;
  List<BookModel> addedBooks = [];
  bool showAddedBooksContainer = false;

  @override
  void initState() {
    super.initState();
    _store = Provider.of<HardcopyStore>(context, listen: false);
    _loadData();
  }

  Future<void> _loadData() async {
    await _store.fetchAllBooks();
  }

  void _updateAddedBooksContainerVisibility() {
    setState(() {
      showAddedBooksContainer = addedBooks.isNotEmpty;
    });
  }

  String _formatPrice(int price) => price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Stack(
        children: [
          Column(
            children: [
              _Header(onBack: () => Navigator.pop(context)),
              Expanded(
                child: Observer(builder: (_) {
                  if (_store.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTokens.accent(context),
                      ),
                    );
                  }
                  if (_store.error != null) {
                    return _ErrorState(
                      message: '${_store.error}',
                      onRetry: _loadData,
                    );
                  }
                  if (_store.books.isEmpty) {
                    return _EmptyState();
                  }
                  final crossAxis =
                      isDesktop ? 4 : (isTablet ? 3 : 2);
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppTokens.s16,
                      AppTokens.s16,
                      AppTokens.s16,
                      showAddedBooksContainer ? 160 : AppTokens.s24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxis,
                            crossAxisSpacing: AppTokens.s12,
                            mainAxisSpacing: AppTokens.s16,
                            childAspectRatio: 0.60,
                          ),
                          itemCount: _store.books.length,
                          itemBuilder: (context, index) {
                            final book = _store.books[index];
                            final isBookAdded = addedBooks.contains(book);
                            return _BookCard(
                              book: book,
                              priceLabel: '₹${_formatPrice(book.price)}',
                              isAdded: isBookAdded,
                              onAddToggle: () {
                                setState(() {
                                  if (isBookAdded) {
                                    addedBooks.remove(book);
                                  } else {
                                    addedBooks.add(book);
                                  }
                                  _updateAddedBooksContainerVisibility();
                                });
                              },
                              onViewMore: () {
                                Navigator.of(context).pushNamed(
                                  Routes.hardcopyDetails,
                                  arguments: book,
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: AppTokens.s8),
                        Center(
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: AppTokens.accent(context),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.s16,
                                vertical: AppTokens.s8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View More Books',
                                  style: AppTokens.body(context).copyWith(
                                    color: AppTokens.accent(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: AppTokens.accent(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTokens.s16),
                        _SubscriptionCard(
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              Routes.newSubscription,
                              arguments: {'showBackButton': true},
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
          if (showAddedBooksContainer)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _CartTray(
                books: addedBooks,
                onRemove: (b) {
                  setState(() {
                    addedBooks.remove(b);
                    _updateAddedBooksContainerVisibility();
                  });
                },
                onContinue: () {
                  final total =
                      addedBooks.fold<int>(0, (sum, b) => sum + b.price);
                  Navigator.of(context).pushNamed(
                    Routes.newCheckoutPlan,
                    arguments: {
                      'plans': [],
                      'books': addedBooks
                          .map((book) => {
                                'id': book.id,
                                'name': book.bookName,
                                'type': book.bookType,
                                'price': book.price,
                                'imageUrl': book.bookImg,
                                'height': book.height,
                                'width': book.breadth,
                                'length': book.length,
                                'weight': book.weight,
                              })
                          .toList(),
                      'totalPrice': total,
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

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTokens.brand.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s12,
            AppTokens.s8,
            AppTokens.s16,
            AppTokens.s16,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.18),
                borderRadius: AppTokens.radius12,
                child: InkWell(
                  borderRadius: AppTokens.radius12,
                  onTap: onBack,
                  child: const SizedBox(
                    height: 40,
                    width: 40,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Store',
                      style: AppTokens.overline(context).copyWith(
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Purchase Hardcopy',
                      style: AppTokens.titleLg(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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
}

// ---------------------------------------------------------------------------
// Error / empty
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppTokens.danger(context),
              size: 40,
            ),
            const SizedBox(height: AppTokens.s12),
            Text(
              'Error',
              style: AppTokens.titleSm(context),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: AppTokens.body(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.accent(context),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppTokens.radius12,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              color: AppTokens.muted(context),
              size: 48,
            ),
            const SizedBox(height: AppTokens.s12),
            Text('No books available', style: AppTokens.titleSm(context)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Book card
// ---------------------------------------------------------------------------

class _BookCard extends StatelessWidget {
  final BookModel book;
  final String priceLabel;
  final bool isAdded;
  final VoidCallback onAddToggle;
  final VoidCallback onViewMore;

  const _BookCard({
    required this.book,
    required this.priceLabel,
    required this.isAdded,
    required this.onAddToggle,
    required this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: Image.asset(
              'assets/image/bookCover.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppTokens.surface2(context),
                alignment: Alignment.center,
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 40,
                  color: AppTokens.muted(context),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTokens.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.bookName,
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  book.bookType,
                  style: AppTokens.caption(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  priceLabel,
                  style: AppTokens.titleSm(context).copyWith(
                    color: AppTokens.accent(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAddToggle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAdded
                              ? AppTokens.success(context)
                              : AppTokens.accent(context),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTokens.radius8,
                          ),
                        ),
                        child: Text(
                          isAdded ? 'Added' : 'Add',
                          style: AppTokens.body(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: onViewMore,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Details',
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.accent(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subscription card
// ---------------------------------------------------------------------------

class _SubscriptionCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SubscriptionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppTokens.radius16,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppTokens.successSoft(context),
            borderRadius: AppTokens.radius16,
            border: Border.all(
              color: AppTokens.success(context).withOpacity(0.35),
            ),
          ),
          padding: const EdgeInsets.all(AppTokens.s16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: AppTokens.success(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Subscribe to App Plans',
                      style: AppTokens.titleSm(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Get access to premium app features and study materials',
                      style: AppTokens.caption(context),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTokens.ink(context),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart tray
// ---------------------------------------------------------------------------

class _CartTray extends StatelessWidget {
  final List<BookModel> books;
  final void Function(BookModel) onRemove;
  final VoidCallback onContinue;
  const _CartTray({
    required this.books,
    required this.onRemove,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final total = books.fold<int>(0, (s, b) => s + b.price);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppTokens.radius20,
            boxShadow: [
              BoxShadow(
                color: AppTokens.brand.withOpacity(0.28),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTokens.s16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...books.map((b) => _TrayRow(
                          book: b,
                          onRemove: () => onRemove(b),
                        )),
                    const SizedBox(height: AppTokens.s8),
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.25),
                    ),
                    const SizedBox(height: AppTokens.s8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'Total',
                          style: AppTokens.titleSm(context).copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹$total',
                          style: AppTokens.titleMd(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(GST Included)',
                          style: AppTokens.caption(context).copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withOpacity(0.16),
                child: InkWell(
                  onTap: onContinue,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.s12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: AppTokens.titleSm(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
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

class _TrayRow extends StatelessWidget {
  final BookModel book;
  final VoidCallback onRemove;
  const _TrayRow({required this.book, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              book.bookName,
              style: AppTokens.body(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '₹${book.price}',
            style: AppTokens.body(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.remove_circle_outline,
                color: Colors.white.withOpacity(0.85),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
