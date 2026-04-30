// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_plan_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SubscriptionPlanStore on _SubscriptionPlanStore, Store {
  Computed<List<String>>? _$availableMonthsComputed;

  @override
  List<String> get availableMonths => (_$availableMonthsComputed ??=
          Computed<List<String>>(() => super.availableMonths,
              name: '_SubscriptionPlanStore.availableMonths'))
      .value;
  Computed<int>? _$totalPriceComputed;

  @override
  int get totalPrice =>
      (_$totalPriceComputed ??= Computed<int>(() => super.totalPrice,
              name: '_SubscriptionPlanStore.totalPrice'))
          .value;

  late final _$isLoadingAtom =
      Atom(name: '_SubscriptionPlanStore.isLoading', context: context);

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

  late final _$errorAtom =
      Atom(name: '_SubscriptionPlanStore.error', context: context);

  @override
  String? get error {
    _$errorAtom.reportRead();
    return super.error;
  }

  @override
  set error(String? value) {
    _$errorAtom.reportWrite(value, super.error, () {
      super.error = value;
    });
  }

  late final _$allPlansAtom =
      Atom(name: '_SubscriptionPlanStore.allPlans', context: context);

  @override
  ObservableList<AllPlansResponseModel> get allPlans {
    _$allPlansAtom.reportRead();
    return super.allPlans;
  }

  @override
  set allPlans(ObservableList<AllPlansResponseModel> value) {
    _$allPlansAtom.reportWrite(value, super.allPlans, () {
      super.allPlans = value;
    });
  }

  late final _$currentMonthIndexAtom =
      Atom(name: '_SubscriptionPlanStore.currentMonthIndex', context: context);

  @override
  int get currentMonthIndex {
    _$currentMonthIndexAtom.reportRead();
    return super.currentMonthIndex;
  }

  @override
  set currentMonthIndex(int value) {
    _$currentMonthIndexAtom.reportWrite(value, super.currentMonthIndex, () {
      super.currentMonthIndex = value;
    });
  }

  late final _$selectedPlansAtom =
      Atom(name: '_SubscriptionPlanStore.selectedPlans', context: context);

  @override
  ObservableList<Map<String, dynamic>> get selectedPlans {
    _$selectedPlansAtom.reportRead();
    return super.selectedPlans;
  }

  @override
  set selectedPlans(ObservableList<Map<String, dynamic>> value) {
    _$selectedPlansAtom.reportWrite(value, super.selectedPlans, () {
      super.selectedPlans = value;
    });
  }

  late final _$selectedBooksAtom =
      Atom(name: '_SubscriptionPlanStore.selectedBooks', context: context);

  @override
  ObservableList<Map<String, dynamic>> get selectedBooks {
    _$selectedBooksAtom.reportRead();
    return super.selectedBooks;
  }

  @override
  set selectedBooks(ObservableList<Map<String, dynamic>> value) {
    _$selectedBooksAtom.reportWrite(value, super.selectedBooks, () {
      super.selectedBooks = value;
    });
  }

  late final _$showAddedPlansContainerAtom = Atom(
      name: '_SubscriptionPlanStore.showAddedPlansContainer', context: context);

  @override
  bool get showAddedPlansContainer {
    _$showAddedPlansContainerAtom.reportRead();
    return super.showAddedPlansContainer;
  }

  @override
  set showAddedPlansContainer(bool value) {
    _$showAddedPlansContainerAtom
        .reportWrite(value, super.showAddedPlansContainer, () {
      super.showAddedPlansContainer = value;
    });
  }

  late final _$appliedCouponAtom =
      Atom(name: '_SubscriptionPlanStore.appliedCoupon', context: context);

  @override
  CouponModel? get appliedCoupon {
    _$appliedCouponAtom.reportRead();
    return super.appliedCoupon;
  }

  @override
  set appliedCoupon(CouponModel? value) {
    _$appliedCouponAtom.reportWrite(value, super.appliedCoupon, () {
      super.appliedCoupon = value;
    });
  }

  late final _$appliedOfferAtom =
      Atom(name: '_SubscriptionPlanStore.appliedOffer', context: context);

  @override
  OfferModel? get appliedOffer {
    _$appliedOfferAtom.reportRead();
    return super.appliedOffer;
  }

  @override
  set appliedOffer(OfferModel? value) {
    _$appliedOfferAtom.reportWrite(value, super.appliedOffer, () {
      super.appliedOffer = value;
    });
  }

  late final _$discountAmountAtom =
      Atom(name: '_SubscriptionPlanStore.discountAmount', context: context);

  @override
  double get discountAmount {
    _$discountAmountAtom.reportRead();
    return super.discountAmount;
  }

  @override
  set discountAmount(double value) {
    _$discountAmountAtom.reportWrite(value, super.discountAmount, () {
      super.discountAmount = value;
    });
  }

  late final _$isCouponLoadingAtom =
      Atom(name: '_SubscriptionPlanStore.isCouponLoading', context: context);

  @override
  bool get isCouponLoading {
    _$isCouponLoadingAtom.reportRead();
    return super.isCouponLoading;
  }

  @override
  set isCouponLoading(bool value) {
    _$isCouponLoadingAtom.reportWrite(value, super.isCouponLoading, () {
      super.isCouponLoading = value;
    });
  }

  late final _$couponErrorAtom =
      Atom(name: '_SubscriptionPlanStore.couponError', context: context);

  @override
  String? get couponError {
    _$couponErrorAtom.reportRead();
    return super.couponError;
  }

  @override
  set couponError(String? value) {
    _$couponErrorAtom.reportWrite(value, super.couponError, () {
      super.couponError = value;
    });
  }

  late final _$bookQuantitiesAtom =
      Atom(name: '_SubscriptionPlanStore.bookQuantities', context: context);

  @override
  ObservableMap<String, int> get bookQuantities {
    _$bookQuantitiesAtom.reportRead();
    return super.bookQuantities;
  }

  @override
  set bookQuantities(ObservableMap<String, int> value) {
    _$bookQuantitiesAtom.reportWrite(value, super.bookQuantities, () {
      super.bookQuantities = value;
    });
  }

  late final _$isIAPEnabledAtom =
      Atom(name: '_SubscriptionPlanStore.isIAPEnabled', context: context);

  @override
  bool get isIAPEnabled {
    _$isIAPEnabledAtom.reportRead();
    return super.isIAPEnabled;
  }

  @override
  set isIAPEnabled(bool value) {
    _$isIAPEnabledAtom.reportWrite(value, super.isIAPEnabled, () {
      super.isIAPEnabled = value;
    });
  }

  late final _$applyCouponAsyncAction =
      AsyncAction('_SubscriptionPlanStore.applyCoupon', context: context);

  @override
  Future<bool> applyCoupon(
      String code, List<Map<String, dynamic>> selectedPlans,
      {List<Map<String, dynamic>>? selectedBooks}) {
    return _$applyCouponAsyncAction.run(() =>
        super.applyCoupon(code, selectedPlans, selectedBooks: selectedBooks));
  }

  late final _$getAllPlansForUserAsyncAction = AsyncAction(
      '_SubscriptionPlanStore.getAllPlansForUser',
      context: context);

  @override
  Future<void> getAllPlansForUser(String categoryId, String subcategoryId) {
    return _$getAllPlansForUserAsyncAction
        .run(() => super.getAllPlansForUser(categoryId, subcategoryId));
  }

  late final _$_SubscriptionPlanStoreActionController =
      ActionController(name: '_SubscriptionPlanStore', context: context);

  @override
  void setCurrentMonthIndex(int index) {
    final _$actionInfo = _$_SubscriptionPlanStoreActionController.startAction(
        name: '_SubscriptionPlanStore.setCurrentMonthIndex');
    try {
      return super.setCurrentMonthIndex(index);
    } finally {
      _$_SubscriptionPlanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setIAPEnabled(bool enabled) {
    final _$actionInfo = _$_SubscriptionPlanStoreActionController.startAction(
        name: '_SubscriptionPlanStore.setIAPEnabled');
    try {
      return super.setIAPEnabled(enabled);
    } finally {
      _$_SubscriptionPlanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addPlan(Map<String, dynamic> plan) {
    final _$actionInfo = _$_SubscriptionPlanStoreActionController.startAction(
        name: '_SubscriptionPlanStore.addPlan');
    try {
      return super.addPlan(plan);
    } finally {
      _$_SubscriptionPlanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removePlan(String planId, String durationId) {
    final _$actionInfo = _$_SubscriptionPlanStoreActionController.startAction(
        name: '_SubscriptionPlanStore.removePlan');
    try {
      return super.removePlan(planId, durationId);
    } finally {
      _$_SubscriptionPlanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addBook(Map<String, dynamic> book) {
    final _$actionInfo = _$_SubscriptionPlanStoreActionController.startAction(
        name: '_SubscriptionPlanStore.addBook');
    try {
      return super.addBook(book);
    } finally {
      _$_SubscriptionPlanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeBook(String bookId) {
    final _$actionInfo = _$_SubscriptionPlanStoreActionController.startAction(
        name: '_SubscriptionPlanStore.removeBook');
    try {
      return super.removeBook(bookId);
    } finally {
      _$_SubscriptionPlanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _updateAddedPlansContainerVisibility() {
    final _$actionInfo = _$_SubscriptionPlanStoreActionController.startAction(
        name: '_SubscriptionPlanStore._updateAddedPlansContainerVisibility');
    try {
      return super._updateAddedPlansContainerVisibility();
    } finally {
      _$_SubscriptionPlanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearSelections() {
    final _$actionInfo = _$_SubscriptionPlanStoreActionController.startAction(
        name: '_SubscriptionPlanStore.clearSelections');
    try {
      return super.clearSelections();
    } finally {
      _$_SubscriptionPlanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateBookQuantity(String bookId, int quantity) {
    final _$actionInfo = _$_SubscriptionPlanStoreActionController.startAction(
        name: '_SubscriptionPlanStore.updateBookQuantity');
    try {
      return super.updateBookQuantity(bookId, quantity);
    } finally {
      _$_SubscriptionPlanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _recalculateDiscount() {
    final _$actionInfo = _$_SubscriptionPlanStoreActionController.startAction(
        name: '_SubscriptionPlanStore._recalculateDiscount');
    try {
      return super._recalculateDiscount();
    } finally {
      _$_SubscriptionPlanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool applyOffer(OfferModel offer, List<Map<String, dynamic>> selectedPlans,
      {List<Map<String, dynamic>>? selectedBooks}) {
    final _$actionInfo = _$_SubscriptionPlanStoreActionController.startAction(
        name: '_SubscriptionPlanStore.applyOffer');
    try {
      return super
          .applyOffer(offer, selectedPlans, selectedBooks: selectedBooks);
    } finally {
      _$_SubscriptionPlanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeAppliedCoupon() {
    final _$actionInfo = _$_SubscriptionPlanStoreActionController.startAction(
        name: '_SubscriptionPlanStore.removeAppliedCoupon');
    try {
      return super.removeAppliedCoupon();
    } finally {
      _$_SubscriptionPlanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeAppliedOffer() {
    final _$actionInfo = _$_SubscriptionPlanStoreActionController.startAction(
        name: '_SubscriptionPlanStore.removeAppliedOffer');
    try {
      return super.removeAppliedOffer();
    } finally {
      _$_SubscriptionPlanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
error: ${error},
allPlans: ${allPlans},
currentMonthIndex: ${currentMonthIndex},
selectedPlans: ${selectedPlans},
selectedBooks: ${selectedBooks},
showAddedPlansContainer: ${showAddedPlansContainer},
appliedCoupon: ${appliedCoupon},
appliedOffer: ${appliedOffer},
discountAmount: ${discountAmount},
isCouponLoading: ${isCouponLoading},
couponError: ${couponError},
bookQuantities: ${bookQuantities},
isIAPEnabled: ${isIAPEnabled},
availableMonths: ${availableMonths},
totalPrice: ${totalPrice}
    ''';
  }
}
