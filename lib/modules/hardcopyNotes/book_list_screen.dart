// ignore_for_file: deprecated_member_use, unused_import, avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/models/subscription_model.dart';
import 'package:shusruta_lms/modules/subscriptionplans/razorpay_payment.dart';
import 'package:shusruta_lms/modules/subscriptionplans/select_bottom_hardcopy_bottom_sheet.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';
import 'package:http/http.dart' as http;
import 'package:shusruta_lms/modules/widgets/subscription_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../subscriptionplans/model/book_by_subscription_id_model.dart';
import '../widgets/custom_button.dart';
import 'package:shusruta_lms/modules/hardcopyNotes/model/get_all_book_model.dart';

/// Hardcopy book catalog + cart — redesigned with AppTokens. Constructor,
/// static route, MobX Observer, Provider wiring, all book math, Razorpay
/// disposal, and navigation targets preserved.
class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const BookListScreen(),
    );
  }
}

class _BookListScreenState extends State<BookListScreen> {
  Future<bool>? isLogged;
  bool loggedIn = false;
  num totalAmount = 0;
  List<Map<String, dynamic>> selectedBooks = [];
  List<int> bookQuantities = [];
  bool discountApplied = false;

  @override
  void initState() {
    super.initState();
    getAllBookList();
    getBookOffer();
    isLogged = _checkIsLoggedIn();
    isLogged!.then((value) {
      setState(() {
        loggedIn = value;
      });
    });
  }

  Future<void> getAllBookList() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetAllBookApiCall();
    setState(() {
      bookQuantities = List.filled(store.getAllhardCopy.length, 0);
    });
  }

  Future<void> getBookOffer() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetBookOffer(context);
  }

  void addBook(SubscriptionStore store, int index, GetAllBookModel book) async {
    setState(() {
      bookQuantities[index]++;
      selectedBooks.add({
        'bookId': book.sId ?? '',
        'bookName': book.bookName ?? '',
        'price': book.price ?? 0,
        'bookImg': book.bookImg,
        'bookType': book.bookType,
      });
      updateTotalAmount();
    });
  }

  void removeBook(SubscriptionStore store, int index, String? bookId) async {
    setState(() {
      if (bookQuantities[index] > 0) {
        bookQuantities[index]--;
        int bookIndex =
            selectedBooks.indexWhere((book) => book['bookId'] == bookId);
        if (bookIndex != -1) {
          selectedBooks.removeAt(bookIndex);
        }
        updateTotalAmount();
      }
    });
  }

  void updateTotalAmount() {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    double discountValue =
        double.tryParse(store.bookOffer.value?.discount ?? '') ?? 0;
    num totalBeforeDiscount =
        selectedBooks.fold(0, (sum, book) => sum + book['price']);

    num totalPriceAfterDiscount = totalBeforeDiscount;
    if (selectedBooks.length >= 2) {
      totalPriceAfterDiscount =
          totalBeforeDiscount * (1 - (discountValue / 100));
    }

    setState(() {
      totalAmount = totalPriceAfterDiscount;
    });
  }

  void updateBookPrize() {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    double discountValue =
        double.tryParse(store.bookOffer.value?.discount ?? '') ?? 0;

    if (selectedBooks.length >= 2) {
      for (var book in selectedBooks) {
        book['price'] = book['price'] * (1 - (discountValue / 100));
      }
    }
  }

  Future<bool> _checkIsLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? loggedInEmail = prefs.getBool('isloggedInEmail');
    bool? signInGoogle = prefs.getBool('isSignInGoogle');
    bool? loggedInWt = prefs.getBool('isLoggedInWt');
    if (loggedInEmail == true || signInGoogle == true || loggedInWt == true) {
      return loggedIn = true;
    } else {
      return loggedIn = false;
    }
  }

  void _onPurchase() {
    if (Platform.isMacOS || Platform.isWindows) {
      showDialog(
        context: context,
        builder: (context) {
          return SubscriptionDialog();
        },
      );
    } else {
      updateBookPrize();
      Navigator.of(context).pushNamed(
        Routes.hardCopyAddressScreen,
        arguments: {
          'totalAmount': totalAmount,
          'selectedBooks': selectedBooks,
        },
      );
    }
  }

  @override
  void dispose() {
    RazorpayPayment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SubscriptionStore>(context);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _Header(onBack: () => Navigator.pop(context)),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s16,
                      AppTokens.s16,
                      AppTokens.s16,
                      AppTokens.s8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BuySubscriptionCard(
                          onTap: () => Navigator.of(context).pushNamed(
                            Routes.hardCopySubscriptionListScreen,
                          ),
                        ),
                        const SizedBox(height: AppTokens.s20),
                        Text(
                          'Select Hardcopy Notes',
                          style: AppTokens.titleSm(context),
                        ),
                        const SizedBox(height: AppTokens.s12),
                        Expanded(
                          child: Observer(builder: (_) {
                            if (store.isLoading) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: AppTokens.accent(context),
                                ),
                              );
                            }
                            if (store.getAllhardCopy.isEmpty) {
                              return _EmptyState();
                            }
                            return ListView.separated(
                              itemCount: store.getAllhardCopy.length,
                              padding: EdgeInsets.zero,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppTokens.s12),
                              itemBuilder: (_, index) {
                                final GetAllBookModel? book =
                                    store.getAllhardCopy[index];
                                final qty = (index < bookQuantities.length)
                                    ? bookQuantities[index]
                                    : 0;
                                return _BookTile(
                                  name: book?.bookName ?? '',
                                  subtitle: book?.bookType ?? '',
                                  price: book?.price?.toInt() ?? 0,
                                  quantity: qty,
                                  onViewMore: () =>
                                      Navigator.of(context).pushNamed(
                                    Routes.viewHardCopyNoteDetails,
                                    arguments: {'bookDetails': book},
                                  ),
                                  onAdd: () {
                                    if (book != null) addBook(store, index, book);
                                  },
                                  onRemove: () =>
                                      removeBook(store, index, book?.sId),
                                );
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                if (totalAmount.toInt() > 0)
                  _CartTray(
                    totalAmount: totalAmount.toInt(),
                    showDiscountHint:
                        bookQuantities.any((qty) => qty > 0),
                    onPurchase: _onPurchase,
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
                      'Catalog',
                      style: AppTokens.overline(context).copyWith(
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Buy Hardcopy Notes',
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
// Buy subscription banner card
// ---------------------------------------------------------------------------

class _BuySubscriptionCard extends StatelessWidget {
  final VoidCallback onTap;
  const _BuySubscriptionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppTokens.radius20,
      child: InkWell(
        borderRadius: AppTokens.radius20,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B1F29), Color(0xFF2A2F3D)],
            ),
            borderRadius: AppTokens.radius20,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buy Subscription Plan',
                      style: AppTokens.titleSm(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Subscribe for full access to videos, notes, and exams.',
                      style: AppTokens.caption(context).copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Container(
                height: 36,
                width: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
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
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 44,
                color: AppTokens.accent(context),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'No hardcopy notes available',
              style: AppTokens.titleMd(context),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              'Check back later for new releases.',
              style: AppTokens.body(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Book tile
// ---------------------------------------------------------------------------

class _BookTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final int price;
  final int quantity;
  final VoidCallback onViewMore;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _BookTile({
    required this.name,
    required this.subtitle,
    required this.price,
    required this.quantity,
    required this.onViewMore,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppTokens.radius12,
            child: Container(
              width: 72,
              height: 96,
              color: AppTokens.surface2(context),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/image/bookCover.png',
                fit: BoxFit.cover,
                width: 72,
                height: 96,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.menu_book_rounded,
                  size: 28,
                  color: AppTokens.muted(context),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTokens.titleSm(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Text(
                      '₹$price',
                      style: AppTokens.titleSm(context).copyWith(
                        color: AppTokens.accent(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTokens.caption(context),
                  ),
                ],
                const SizedBox(height: AppTokens.s8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ViewMoreChip(onTap: onViewMore),
                    if (quantity == 0)
                      _AddBtn(onTap: onAdd)
                    else
                      _QtyStepper(
                        qty: quantity,
                        onAdd: onAdd,
                        onRemove: onRemove,
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

class _ViewMoreChip extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewMoreChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.accentSoft(context),
      borderRadius: AppTokens.radius8,
      child: InkWell(
        borderRadius: AppTokens.radius8,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s8,
            vertical: 4,
          ),
          child: Text(
            'View More',
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.accent(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppTokens.radius8,
      child: InkWell(
        borderRadius: AppTokens.radius8,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius8,
            border: Border.all(color: AppTokens.accent(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 14,
                color: AppTokens.accent(context),
              ),
              const SizedBox(width: 4),
              Text(
                'Add',
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.accent(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _QtyStepper({
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.accent(context),
        borderRadius: AppTokens.radius8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperBtn(icon: Icons.remove_rounded, onTap: onRemove),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTokens.s8),
            child: Text(
              '$qty',
              style: AppTokens.body(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _StepperBtn(icon: Icons.add_rounded, onTap: onAdd),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppTokens.radius8,
      child: InkWell(
        borderRadius: AppTokens.radius8,
        onTap: onTap,
        child: SizedBox(
          height: 32,
          width: 32,
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart tray
// ---------------------------------------------------------------------------

class _CartTray extends StatelessWidget {
  final int totalAmount;
  final bool showDiscountHint;
  final VoidCallback onPurchase;

  const _CartTray({
    required this.totalAmount,
    required this.showDiscountHint,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s16,
          AppTokens.s8,
          AppTokens.s16,
          AppTokens.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDiscountHint)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.s12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s12,
                    vertical: AppTokens.s8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.successSoft(context),
                    borderRadius: AppTokens.radius12,
                    border: Border.all(
                      color: AppTokens.success(context).withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 24,
                        width: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTokens.success(context),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.percent_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: AppTokens.s8),
                      Expanded(
                        child: Text(
                          'Add more to get a bigger discount',
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.success(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTokens.brand, AppTokens.brand2],
                ),
                borderRadius: AppTokens.radius16,
                boxShadow: [
                  BoxShadow(
                    color: AppTokens.brand.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Payable Amount',
                          style: AppTokens.caption(context).copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹$totalAmount',
                              style: AppTokens.displayMd(context).copyWith(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: AppTokens.s8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                'inclusive GST',
                                style: AppTokens.caption(context).copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Material(
                    color: Colors.white,
                    borderRadius: AppTokens.radius12,
                    child: InkWell(
                      borderRadius: AppTokens.radius12,
                      onTap: onPurchase,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s20,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Purchase Now',
                              style: AppTokens.titleSm(context).copyWith(
                                color: AppTokens.brand,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: AppTokens.brand,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
