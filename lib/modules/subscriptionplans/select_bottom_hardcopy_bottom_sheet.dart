// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';

import '../../app/routes.dart';
import '../../helpers/colors.dart';
import '../../helpers/styles.dart';
import '../../models/subscription_model.dart';
import 'model/book_by_subscription_id_model.dart';

class SelectHardCopyNotesBottomSheet extends StatefulWidget {
  final SubscriptionModel subscription;
  final SubscriptionStore store;
  const SelectHardCopyNotesBottomSheet(
      {super.key, required this.subscription, required this.store});

  @override
  State<SelectHardCopyNotesBottomSheet> createState() =>
      _SelectHardCopyNotesBottomSheetState();
}

class _SelectHardCopyNotesBottomSheetState
    extends State<SelectHardCopyNotesBottomSheet> {
  num totalAmount = 0;
  List<Map<String, dynamic>> selectedBooks = [];
  List<int> bookQuantities = [];
  bool discountApplied = false;

  @override
  void initState() {
    super.initState();
    getBookList();
    getBookOffer();
  }

  Future<void> getBookList() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store
        .onGetAllBookBySubscriptionApiCall(widget.subscription.sid ?? '');
    setState(() {
      bookQuantities = List.filled(store.getAllBookBySub.length, 0);
    });
  }

  Future<void> getBookOffer() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetBookOffer(context);
  }

  void addBook(SubscriptionStore store, int index,
      BookBySubscriptionIdModel book) async {
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

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SubscriptionStore>(context);
    return Container(
      constraints: BoxConstraints(
          maxWidth: 600, maxHeight: MediaQuery.of(context).size.height * .5),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
          color: AppTokens.surface(context),
          borderRadius: (Platform.isMacOS || Platform.isWindows)
              ? BorderRadius.circular(15)
              : null),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: Dimensions.PADDING_SIZE_DEFAULT * 2,
                left: Dimensions.PADDING_SIZE_DEFAULT,
                right: Dimensions.PADDING_SIZE_DEFAULT,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Select Hardcopy Notes",
                        style: AppTokens.titleMd(context).copyWith(
                          color: AppTokens.ink(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          borderRadius:
                              BorderRadius.circular(AppTokens.r8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              color: AppTokens.muted(context),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
                  Expanded(
                    child: Observer(builder: (context) {
                      if (store.isLoading) {
                        return Center(
                          child: CircularProgressIndicator(
                              color: AppTokens.accent(context)),
                        );
                      }
                      return ListView.builder(
                        itemCount: store.getAllBookBySub.length,
                        itemBuilder: (BuildContext context, int index) {
                          BookBySubscriptionIdModel? getBookSub =
                              store.getAllBookBySub[index];
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.only(
                                bottom: Dimensions.PADDING_SIZE_DEFAULT),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppTokens.border(context)),
                              color: AppTokens.surface2(context),
                              borderRadius:
                                  BorderRadius.circular(AppTokens.r12),
                            ),
                            child: Row(
                              children: [
                                Image.asset("assets/image/bookCover.png"),
                                const SizedBox(
                                    width: Dimensions.PADDING_SIZE_DEFAULT),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(
                                            width: (Platform.isMacOS ||
                                                    Platform.isWindows)
                                                ? 250
                                                : MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.4,
                                            child: Text(
                                              getBookSub?.bookName ?? '',
                                              style: AppTokens.body(context)
                                                  .copyWith(
                                                color: AppTokens.ink(context),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            "\u20B9 ${getBookSub?.price}",
                                            style: AppTokens.titleMd(context)
                                                .copyWith(
                                              color: AppTokens.ink(context),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        getBookSub?.bookType ?? '',
                                        style: AppTokens.caption(context)
                                            .copyWith(
                                          color: AppTokens.muted(context),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              Navigator.of(context).pushNamed(
                                                  Routes.viewNoteDetails,
                                                  arguments: {
                                                    'bookDetails': getBookSub,
                                                  });
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: Dimensions
                                                          .PADDING_SIZE_SMALL,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppTokens.r8),
                                                color: AppTokens.accentSoft(
                                                    context),
                                              ),
                                              child: Text(
                                                "View More",
                                                style: AppTokens.caption(
                                                        context)
                                                    .copyWith(
                                                  color: AppTokens.accent(
                                                      context),
                                                  fontWeight: FontWeight.w600,
                                                  height: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                          bookQuantities[index] == 0
                                              ? Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () {
                                                      addBook(store, index,
                                                          getBookSub!);
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppTokens.r8),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: Dimensions
                                                              .PADDING_SIZE_LARGE,
                                                          vertical: 6),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                AppTokens.r8),
                                                        border: Border.all(
                                                            color: AppTokens
                                                                .accent(
                                                                    context)),
                                                        color: AppTokens
                                                            .accentSoft(context),
                                                      ),
                                                      child: Text(
                                                        "Add +",
                                                        style:
                                                            AppTokens.caption(
                                                                    context)
                                                                .copyWith(
                                                          color: AppTokens
                                                              .accent(context),
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          height: 1,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: Dimensions
                                                          .PADDING_SIZE_LARGE,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppTokens.r8),
                                                    gradient:
                                                        const LinearGradient(
                                                      colors: [
                                                        AppTokens.brand,
                                                        AppTokens.brand2,
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment
                                                          .bottomRight,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      InkWell(
                                                        onTap: () {
                                                          addBook(store, index,
                                                              getBookSub!);
                                                        },
                                                        child: Text(
                                                          "+",
                                                          style: AppTokens
                                                                  .body(context)
                                                              .copyWith(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            height: 1,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        "${bookQuantities[index]}",
                                                        style:
                                                            AppTokens.body(
                                                                    context)
                                                                .copyWith(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          height: 1,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () {
                                                          removeBook(
                                                              store,
                                                              index,
                                                              getBookSub?.sId);
                                                        },
                                                        child: Text(
                                                          "-",
                                                          style: AppTokens
                                                                  .body(context)
                                                              .copyWith(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            height: 1,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                    width: Dimensions.PADDING_SIZE_DEFAULT),
                              ],
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
          totalAmount.toInt() == 0
              ? const SizedBox()
              : Column(
                  children: [
                    bookQuantities.any((quantity) => quantity > 0)
                        ? Container(
                            padding: const EdgeInsets.only(
                              left: Dimensions.PADDING_SIZE_LARGE * 1.7,
                              right: Dimensions.PADDING_SIZE_LARGE * 1.7,
                              top: Dimensions.PADDING_SIZE_DEFAULT,
                              bottom: Dimensions.PADDING_SIZE_DEFAULT,
                            ),
                            color: AppTokens.surface(context),
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(8, 6, 12, 6),
                              decoration: BoxDecoration(
                                color: AppTokens.success(context),
                                borderRadius:
                                    BorderRadius.circular(AppTokens.r16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height:
                                        Dimensions.PADDING_SIZE_LARGE * 1.2,
                                    width:
                                        Dimensions.PADDING_SIZE_LARGE * 1.2,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withOpacity(0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      "%",
                                      style:
                                          AppTokens.caption(context).copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                      width: Dimensions.PADDING_SIZE_SMALL),
                                  Text(
                                    "Add More to Get More Discount",
                                    style:
                                        AppTokens.body(context).copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.PADDING_SIZE_DEFAULT,
                          vertical: Dimensions.PADDING_SIZE_LARGE),
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTokens.brand, AppTokens.brand2],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              (Platform.isMacOS || Platform.isWindows)
                                  ? const BorderRadius.vertical(
                                      bottom: Radius.circular(15))
                                  : null),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Payable Amount ",
                                style: AppTokens.caption(context).copyWith(
                                  color: Colors.white.withOpacity(0.82),
                                ),
                              ),
                              const SizedBox(
                                  height:
                                      Dimensions.PADDING_SIZE_EXTRA_SMALL),
                              Text(
                                "\u20B9 ${totalAmount.toStringAsFixed(0)}",
                                style: AppTokens.titleLg(context).copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                              width: Dimensions.PADDING_SIZE_LARGE * 2.4),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  updateBookPrize();
                                  debugPrint(
                                      "selectedBooks:$selectedBooks");
                                  debugPrint("totalAmount:$totalAmount");
                                  Navigator.of(context).pushNamed(
                                      Routes.addressDetailScreen,
                                      arguments: {
                                        'subscription': widget.subscription,
                                        'store': widget.store,
                                        'totalAmount': totalAmount,
                                        'selectedBooks': selectedBooks,
                                      });
                                },
                                borderRadius:
                                    BorderRadius.circular(AppTokens.r12),
                                child: Ink(
                                  height:
                                      Dimensions.PADDING_SIZE_LARGE * 2.2,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        AppTokens.r12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Continue",
                                      style:
                                          AppTokens.body(context).copyWith(
                                        color: AppTokens.brand,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
