// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/modules/hardcopyNotes/model/get_all_book_model.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/subscription_model.dart';
import '../subscriptionplans/razorpay_payment.dart';

/// Screen shown after a subscription plan is picked — lets the user attach
/// hardcopy notes to the bundle, shows the selected plan card + scrollable
/// hardcopy list, and forwards to the address screen with the combined
/// arguments map. All MobX Provider wiring, SharedPreferences login check,
/// discount math (`>= 2 books` fires `(1 - discount/100)` on totals AND on
/// individual book prices before navigation via updateBookPrize), Razorpay
/// lifecycle, and navigation target preserved.
class SelectedSubscriptionPlanScreen extends StatefulWidget {
  final SubscriptionModel subscription;
  final SubscriptionStore store;
  final String selectedPlanMonth;
  final String durationId;
  final String? offerId;
  final String? couponId;
  final bool isSingleUse;
  final int subTotalAmount;

  const SelectedSubscriptionPlanScreen({
    super.key,
    required this.subscription,
    required this.store,
    required this.selectedPlanMonth,
    required this.durationId,
    required this.subTotalAmount,
    required this.offerId,
    required this.couponId,
    required this.isSingleUse,
  });

  @override
  State<SelectedSubscriptionPlanScreen> createState() =>
      _SelectedSubscriptionPlanScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => SelectedSubscriptionPlanScreen(
        subscription: arguments["subscription"],
        store: arguments["store"],
        selectedPlanMonth: arguments["selectedPlanMonth"],
        durationId: arguments["durationId"],
        subTotalAmount: arguments["subTotalAmount"],
        offerId: arguments["offerId"],
        couponId: arguments["couponId"],
        isSingleUse: arguments["isSingleUse"],
      ),
    );
  }
}

class _SelectedSubscriptionPlanScreenState
    extends State<SelectedSubscriptionPlanScreen> {
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

  @override
  void dispose() {
    RazorpayPayment.dispose();
    super.dispose();
  }

  String formatTime(int numberOfDays) {
    if (numberOfDays >= 365) {
      int years = numberOfDays ~/ 365;
      return years == 1 ? '1 Year' : '$years years';
    } else if (numberOfDays >= 30) {
      int months = numberOfDays ~/ 30;
      return months == 1 ? '1 month' : '$months months';
    } else {
      return '$numberOfDays days';
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SubscriptionStore>(context);
    final anySelected = bookQuantities.any((q) => q > 0);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _Header(
            title: "Buy Hardcopy Notes",
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppTokens.s16),
                  _SectionTitle(text: "Your Selected Subscription Plan"),
                  const SizedBox(height: AppTokens.s12),
                  _SelectedPlanCard(
                    planName: widget.subscription.plan_name ?? '',
                    amount: "₹ ${widget.subTotalAmount}",
                  ),
                  const SizedBox(height: AppTokens.s24),
                  _SectionTitle(text: "Select Hardcopy Notes"),
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
                      if (store.getAllhardCopy.isEmpty) {
                        return const _EmptyState();
                      }
                      return ListView.builder(
                        itemCount: store.getAllhardCopy.length,
                        padding: const EdgeInsets.only(
                          bottom: AppTokens.s16,
                        ),
                        itemBuilder: (context, index) {
                          final book = store.getAllhardCopy[index];
                          final qty = index < bookQuantities.length
                              ? bookQuantities[index]
                              : 0;
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppTokens.s12),
                            child: _BookTile(
                              book: book,
                              quantity: qty,
                              onViewMore: () {
                                Navigator.of(context).pushNamed(
                                  Routes.viewHardCopyNoteDetails,
                                  arguments: {'bookDetails': book},
                                );
                              },
                              onAdd: book == null
                                  ? null
                                  : () => addBook(store, index, book),
                              onRemove: book == null
                                  ? null
                                  : () => removeBook(store, index, book.sId),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          if (totalAmount.toInt() != 0)
            Column(
              children: [
                if (anySelected) const _DiscountHint(),
                _CheckoutBar(
                  total: widget.subTotalAmount + totalAmount.toInt(),
                  onContinue: () {
                    updateBookPrize();
                    Navigator.of(context).pushNamed(
                      Routes.hardCopyAndSubscriptionAddressScreen,
                      arguments: {
                        'totalAmount':
                            widget.subTotalAmount + totalAmount.toInt(),
                        'subTotalAmount': widget.subTotalAmount,
                        'selectedBooks': selectedBooks,
                        'store': widget.store,
                        'subscription': widget.subscription,
                        "selectedPlanMonth": widget.selectedPlanMonth,
                        "durationId": widget.durationId,
                        "offerId": widget.offerId,
                        "couponId": widget.couponId,
                        "isSingleUse": widget.isSingleUse,
                      },
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ============================================================
//                        Primitives
// ============================================================

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTokens.s8,
        MediaQuery.of(context).padding.top + AppTokens.s12,
        AppTokens.s16,
        AppTokens.s16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTokens.brand.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white.withOpacity(0.16),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: const SizedBox(
                width: 40,
                height: 40,
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
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.titleMd(context).copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTokens.accent(context),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Text(text, style: AppTokens.titleSm(context)),
      ],
    );
  }
}

class _SelectedPlanCard extends StatelessWidget {
  const _SelectedPlanCard({required this.planName, required this.amount});
  final String planName;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: AppTokens.accentSoft(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(
          color: AppTokens.accent(context).withOpacity(0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppTokens.accent(context),
            size: 22,
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              planName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.bodyLg(context).copyWith(
                color: AppTokens.ink(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            amount,
            style: AppTokens.titleSm(context).copyWith(
              color: AppTokens.ink(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.book,
    required this.quantity,
    required this.onViewMore,
    required this.onAdd,
    required this.onRemove,
  });
  final GetAllBookModel? book;
  final int quantity;
  final VoidCallback onViewMore;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppTokens.r16),
              bottomLeft: Radius.circular(AppTokens.r16),
            ),
            child: Image.asset(
              "assets/image/bookCover.png",
              width: 92,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s12,
                vertical: AppTokens.s8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          book?.bookName ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTokens.titleSm(context),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s8),
                      Text(
                        "₹ ${book?.price ?? 0}",
                        style: AppTokens.titleMd(context).copyWith(
                          color: AppTokens.ink(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s4),
                  if ((book?.bookType ?? '').isNotEmpty)
                    Text(
                      book!.bookType!,
                      style: AppTokens.caption(context),
                    ),
                  const SizedBox(height: AppTokens.s8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          ),
        ],
      ),
    );
  }
}

class _ViewMoreChip extends StatelessWidget {
  const _ViewMoreChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.accentSoft(context),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12,
            vertical: 6,
          ),
          child: Text(
            "View More",
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
  const _AddBtn({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surface(context),
      borderRadius: AppTokens.radius8,
      child: InkWell(
        borderRadius: AppTokens.radius8,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius8,
            border: Border.all(
              color: AppTokens.success(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 16,
                color: AppTokens.ink(context),
              ),
              const SizedBox(width: 4),
              Text(
                "Add",
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.ink(context),
                  fontWeight: FontWeight.w600,
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
  const _QtyStepper({
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });
  final int qty;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTokens.radius8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperBtn(
            icon: Icons.remove_rounded,
            onTap: onRemove,
          ),
          const SizedBox(width: AppTokens.s8),
          Text(
            "$qty",
            style: AppTokens.numeric(context, size: 14).copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          _StepperBtn(
            icon: Icons.add_rounded,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 64,
            color: AppTokens.muted(context),
          ),
          const SizedBox(height: AppTokens.s12),
          Text(
            "No hardcopy notes found",
            style: AppTokens.titleSm(context).copyWith(
              color: AppTokens.ink2(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountHint extends StatelessWidget {
  const _DiscountHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTokens.scaffold(context),
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s24,
        AppTokens.s8,
        AppTokens.s24,
        AppTokens.s4,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppTokens.success(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Text(
                "%",
                style: AppTokens.caption(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            Text(
              "Add More to Get More Discount",
              style: AppTokens.caption(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.total, required this.onContinue});
  final int total;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTokens.s16,
        AppTokens.s16,
        AppTokens.s16,
        MediaQuery.of(context).padding.bottom + AppTokens.s16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppTokens.shadow2(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Payable Amount",
                  style: AppTokens.caption(context).copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        "₹ $total",
                        style: AppTokens.displayMd(context).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        "inclusive GST",
                        style: AppTokens.caption(context).copyWith(
                          color: Colors.white.withOpacity(0.85),
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
              onTap: onContinue,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s20,
                  vertical: AppTokens.s12,
                ),
                child: Text(
                  "Continue",
                  style: AppTokens.titleSm(context).copyWith(
                    color: AppTokens.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
