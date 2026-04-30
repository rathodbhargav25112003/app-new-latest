// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SubscriptionStore on _SubscriptionStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_SubscriptionStore.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$subscriptionAtom =
      Atom(name: '_SubscriptionStore.subscription', context: context);

  @override
  ObservableList<SubscriptionModel?> get subscription {
    _$subscriptionAtom.reportRead();
    return super.subscription;
  }

  @override
  set subscription(ObservableList<SubscriptionModel?> value) {
    _$subscriptionAtom.reportWrite(value, super.subscription, () {
      super.subscription = value;
    });
  }

  late final _$purchaseSubscriptionAtom =
      Atom(name: '_SubscriptionStore.purchaseSubscription', context: context);

  @override
  Observable<CreateSubscriptionOrderModel?> get purchaseSubscription {
    _$purchaseSubscriptionAtom.reportRead();
    return super.purchaseSubscription;
  }

  @override
  set purchaseSubscription(Observable<CreateSubscriptionOrderModel?> value) {
    _$purchaseSubscriptionAtom.reportWrite(value, super.purchaseSubscription,
        () {
      super.purchaseSubscription = value;
    });
  }

  late final _$purchaseFixedSubscriptionAtom = Atom(
      name: '_SubscriptionStore.purchaseFixedSubscription', context: context);

  @override
  Observable<CreateSubscriptionOrderModel?> get purchaseFixedSubscription {
    _$purchaseFixedSubscriptionAtom.reportRead();
    return super.purchaseFixedSubscription;
  }

  @override
  set purchaseFixedSubscription(
      Observable<CreateSubscriptionOrderModel?> value) {
    _$purchaseFixedSubscriptionAtom
        .reportWrite(value, super.purchaseFixedSubscription, () {
      super.purchaseFixedSubscription = value;
    });
  }

  late final _$purchaseUserOfferAtom =
      Atom(name: '_SubscriptionStore.purchaseUserOffer', context: context);

  @override
  Observable<CreateUserOfferModel?> get purchaseUserOffer {
    _$purchaseUserOfferAtom.reportRead();
    return super.purchaseUserOffer;
  }

  @override
  set purchaseUserOffer(Observable<CreateUserOfferModel?> value) {
    _$purchaseUserOfferAtom.reportWrite(value, super.purchaseUserOffer, () {
      super.purchaseUserOffer = value;
    });
  }

  late final _$subscribedPlanAtom =
      Atom(name: '_SubscriptionStore.subscribedPlan', context: context);

  @override
  ObservableList<SubscribedPlanModel?> get subscribedPlan {
    _$subscribedPlanAtom.reportRead();
    return super.subscribedPlan;
  }

  @override
  set subscribedPlan(ObservableList<SubscribedPlanModel?> value) {
    _$subscribedPlanAtom.reportWrite(value, super.subscribedPlan, () {
      super.subscribedPlan = value;
    });
  }

  late final _$orderUserHistoryAtom =
      Atom(name: '_SubscriptionStore.orderUserHistory', context: context);

  @override
  ObservableList<GetAllUserOrderModel?> get orderUserHistory {
    _$orderUserHistoryAtom.reportRead();
    return super.orderUserHistory;
  }

  @override
  set orderUserHistory(ObservableList<GetAllUserOrderModel?> value) {
    _$orderUserHistoryAtom.reportWrite(value, super.orderUserHistory, () {
      super.orderUserHistory = value;
    });
  }

  late final _$purchaseBooksAtom =
      Atom(name: '_SubscriptionStore.purchaseBooks', context: context);

  @override
  ObservableList<CreateBookOrderModel?> get purchaseBooks {
    _$purchaseBooksAtom.reportRead();
    return super.purchaseBooks;
  }

  @override
  set purchaseBooks(ObservableList<CreateBookOrderModel?> value) {
    _$purchaseBooksAtom.reportWrite(value, super.purchaseBooks, () {
      super.purchaseBooks = value;
    });
  }

  late final _$getAllCouponUserAtom =
      Atom(name: '_SubscriptionStore.getAllCouponUser', context: context);

  @override
  ObservableList<GetAllCouponUserModel?> get getAllCouponUser {
    _$getAllCouponUserAtom.reportRead();
    return super.getAllCouponUser;
  }

  @override
  set getAllCouponUser(ObservableList<GetAllCouponUserModel?> value) {
    _$getAllCouponUserAtom.reportWrite(value, super.getAllCouponUser, () {
      super.getAllCouponUser = value;
    });
  }

  late final _$getAllOfferUserAtom =
      Atom(name: '_SubscriptionStore.getAllOfferUser', context: context);

  @override
  ObservableList<GetAllOfferUserModel?> get getAllOfferUser {
    _$getAllOfferUserAtom.reportRead();
    return super.getAllOfferUser;
  }

  @override
  set getAllOfferUser(ObservableList<GetAllOfferUserModel?> value) {
    _$getAllOfferUserAtom.reportWrite(value, super.getAllOfferUser, () {
      super.getAllOfferUser = value;
    });
  }

  late final _$getAllBookBySubAtom =
      Atom(name: '_SubscriptionStore.getAllBookBySub', context: context);

  @override
  ObservableList<BookBySubscriptionIdModel?> get getAllBookBySub {
    _$getAllBookBySubAtom.reportRead();
    return super.getAllBookBySub;
  }

  @override
  set getAllBookBySub(ObservableList<BookBySubscriptionIdModel?> value) {
    _$getAllBookBySubAtom.reportWrite(value, super.getAllBookBySub, () {
      super.getAllBookBySub = value;
    });
  }

  late final _$getAllhardCopyAtom =
      Atom(name: '_SubscriptionStore.getAllhardCopy', context: context);

  @override
  ObservableList<GetAllBookModel?> get getAllhardCopy {
    _$getAllhardCopyAtom.reportRead();
    return super.getAllhardCopy;
  }

  @override
  set getAllhardCopy(ObservableList<GetAllBookModel?> value) {
    _$getAllhardCopyAtom.reportWrite(value, super.getAllhardCopy, () {
      super.getAllhardCopy = value;
    });
  }

  late final _$getAllUserAddressAtom =
      Atom(name: '_SubscriptionStore.getAllUserAddress', context: context);

  @override
  ObservableList<GetAddressModel?> get getAllUserAddress {
    _$getAllUserAddressAtom.reportRead();
    return super.getAllUserAddress;
  }

  @override
  set getAllUserAddress(ObservableList<GetAddressModel?> value) {
    _$getAllUserAddressAtom.reportWrite(value, super.getAllUserAddress, () {
      super.getAllUserAddress = value;
    });
  }

  late final _$paymentDetailsAtom =
      Atom(name: '_SubscriptionStore.paymentDetails', context: context);

  @override
  Observable<PaymentMethodDetailsModel?> get paymentDetails {
    _$paymentDetailsAtom.reportRead();
    return super.paymentDetails;
  }

  @override
  set paymentDetails(Observable<PaymentMethodDetailsModel?> value) {
    _$paymentDetailsAtom.reportWrite(value, super.paymentDetails, () {
      super.paymentDetails = value;
    });
  }

  late final _$bookOfferAtom =
      Atom(name: '_SubscriptionStore.bookOffer', context: context);

  @override
  Observable<BookOfferModel?> get bookOffer {
    _$bookOfferAtom.reportRead();
    return super.bookOffer;
  }

  @override
  set bookOffer(Observable<BookOfferModel?> value) {
    _$bookOfferAtom.reportWrite(value, super.bookOffer, () {
      super.bookOffer = value;
    });
  }

  late final _$addAddressAtom =
      Atom(name: '_SubscriptionStore.addAddress', context: context);

  @override
  Observable<CreateAddressModel?> get addAddress {
    _$addAddressAtom.reportRead();
    return super.addAddress;
  }

  @override
  set addAddress(Observable<CreateAddressModel?> value) {
    _$addAddressAtom.reportWrite(value, super.addAddress, () {
      super.addAddress = value;
    });
  }

  late final _$updateAddressAtom =
      Atom(name: '_SubscriptionStore.updateAddress', context: context);

  @override
  Observable<CreateAddressModel?> get updateAddress {
    _$updateAddressAtom.reportRead();
    return super.updateAddress;
  }

  @override
  set updateAddress(Observable<CreateAddressModel?> value) {
    _$updateAddressAtom.reportWrite(value, super.updateAddress, () {
      super.updateAddress = value;
    });
  }

  late final _$_SubscriptionStoreActionController =
      ActionController(name: '_SubscriptionStore', context: context);

  @override
  void _setPaymentDetails(PaymentMethodDetailsModel value) {
    final _$actionInfo = _$_SubscriptionStoreActionController.startAction(
        name: '_SubscriptionStore._setPaymentDetails');
    try {
      return super._setPaymentDetails(value);
    } finally {
      _$_SubscriptionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setBookOffer(BookOfferModel value) {
    final _$actionInfo = _$_SubscriptionStoreActionController.startAction(
        name: '_SubscriptionStore._setBookOffer');
    try {
      return super._setBookOffer(value);
    } finally {
      _$_SubscriptionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setAddress(CreateAddressModel value) {
    final _$actionInfo = _$_SubscriptionStoreActionController.startAction(
        name: '_SubscriptionStore._setAddress');
    try {
      return super._setAddress(value);
    } finally {
      _$_SubscriptionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setUpdateAddress(CreateAddressModel value) {
    final _$actionInfo = _$_SubscriptionStoreActionController.startAction(
        name: '_SubscriptionStore._setUpdateAddress');
    try {
      return super._setUpdateAddress(value);
    } finally {
      _$_SubscriptionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
subscription: ${subscription},
purchaseSubscription: ${purchaseSubscription},
purchaseFixedSubscription: ${purchaseFixedSubscription},
purchaseUserOffer: ${purchaseUserOffer},
subscribedPlan: ${subscribedPlan},
orderUserHistory: ${orderUserHistory},
purchaseBooks: ${purchaseBooks},
getAllCouponUser: ${getAllCouponUser},
getAllOfferUser: ${getAllOfferUser},
getAllBookBySub: ${getAllBookBySub},
getAllhardCopy: ${getAllhardCopy},
getAllUserAddress: ${getAllUserAddress},
paymentDetails: ${paymentDetails},
bookOffer: ${bookOffer},
addAddress: ${addAddress},
updateAddress: ${updateAddress}
    ''';
  }
}
