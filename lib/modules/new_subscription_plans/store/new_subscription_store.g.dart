// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_subscription_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$NewSubscriptionStore on _NewSubscriptionStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_NewSubscriptionStore.isLoading', context: context);

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

  late final _$isSubcategoryLoadingAtom = Atom(
      name: '_NewSubscriptionStore.isSubcategoryLoading', context: context);

  @override
  bool get isSubcategoryLoading {
    _$isSubcategoryLoadingAtom.reportRead();
    return super.isSubcategoryLoading;
  }

  @override
  set isSubcategoryLoading(bool value) {
    _$isSubcategoryLoadingAtom.reportWrite(value, super.isSubcategoryLoading,
        () {
      super.isSubcategoryLoading = value;
    });
  }

  late final _$planCategoriesAtom =
      Atom(name: '_NewSubscriptionStore.planCategories', context: context);

  @override
  ObservableList<PlanCategoryModel> get planCategories {
    _$planCategoriesAtom.reportRead();
    return super.planCategories;
  }

  @override
  set planCategories(ObservableList<PlanCategoryModel> value) {
    _$planCategoriesAtom.reportWrite(value, super.planCategories, () {
      super.planCategories = value;
    });
  }

  late final _$planSubcategoriesAtom =
      Atom(name: '_NewSubscriptionStore.planSubcategories', context: context);

  @override
  ObservableList<PlanSubcategoryModel> get planSubcategories {
    _$planSubcategoriesAtom.reportRead();
    return super.planSubcategories;
  }

  @override
  set planSubcategories(ObservableList<PlanSubcategoryModel> value) {
    _$planSubcategoriesAtom.reportWrite(value, super.planSubcategories, () {
      super.planSubcategories = value;
    });
  }

  late final _$selectedCategoryAtom =
      Atom(name: '_NewSubscriptionStore.selectedCategory', context: context);

  @override
  PlanCategoryModel? get selectedCategory {
    _$selectedCategoryAtom.reportRead();
    return super.selectedCategory;
  }

  @override
  set selectedCategory(PlanCategoryModel? value) {
    _$selectedCategoryAtom.reportWrite(value, super.selectedCategory, () {
      super.selectedCategory = value;
    });
  }

  late final _$errorAtom =
      Atom(name: '_NewSubscriptionStore.error', context: context);

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

  late final _$deliveryServicesAtom =
      Atom(name: '_NewSubscriptionStore.deliveryServices', context: context);

  @override
  ObservableList<DeliveryServiceModel> get deliveryServices {
    _$deliveryServicesAtom.reportRead();
    return super.deliveryServices;
  }

  @override
  set deliveryServices(ObservableList<DeliveryServiceModel> value) {
    _$deliveryServicesAtom.reportWrite(value, super.deliveryServices, () {
      super.deliveryServices = value;
    });
  }

  late final _$isServiceabilityLoadingAtom = Atom(
      name: '_NewSubscriptionStore.isServiceabilityLoading', context: context);

  @override
  bool get isServiceabilityLoading {
    _$isServiceabilityLoadingAtom.reportRead();
    return super.isServiceabilityLoading;
  }

  @override
  set isServiceabilityLoading(bool value) {
    _$isServiceabilityLoadingAtom
        .reportWrite(value, super.isServiceabilityLoading, () {
      super.isServiceabilityLoading = value;
    });
  }

  late final _$serviceabilityErrorAtom =
      Atom(name: '_NewSubscriptionStore.serviceabilityError', context: context);

  @override
  String? get serviceabilityError {
    _$serviceabilityErrorAtom.reportRead();
    return super.serviceabilityError;
  }

  @override
  set serviceabilityError(String? value) {
    _$serviceabilityErrorAtom.reportWrite(value, super.serviceabilityError, () {
      super.serviceabilityError = value;
    });
  }

  late final _$showServiceabilityMessageAtom = Atom(
      name: '_NewSubscriptionStore.showServiceabilityMessage',
      context: context);

  @override
  bool get showServiceabilityMessage {
    _$showServiceabilityMessageAtom.reportRead();
    return super.showServiceabilityMessage;
  }

  @override
  set showServiceabilityMessage(bool value) {
    _$showServiceabilityMessageAtom
        .reportWrite(value, super.showServiceabilityMessage, () {
      super.showServiceabilityMessage = value;
    });
  }

  late final _$pincodeAtom =
      Atom(name: '_NewSubscriptionStore.pincode', context: context);

  @override
  String get pincode {
    _$pincodeAtom.reportRead();
    return super.pincode;
  }

  @override
  set pincode(String value) {
    _$pincodeAtom.reportWrite(value, super.pincode, () {
      super.pincode = value;
    });
  }

  late final _$selectedAddressAtom =
      Atom(name: '_NewSubscriptionStore.selectedAddress', context: context);

  @override
  Map<String, dynamic>? get selectedAddress {
    _$selectedAddressAtom.reportRead();
    return super.selectedAddress;
  }

  @override
  set selectedAddress(Map<String, dynamic>? value) {
    _$selectedAddressAtom.reportWrite(value, super.selectedAddress, () {
      super.selectedAddress = value;
    });
  }

  late final _$selectedDeliveryServiceAtom = Atom(
      name: '_NewSubscriptionStore.selectedDeliveryService', context: context);

  @override
  DeliveryServiceModel? get selectedDeliveryService {
    _$selectedDeliveryServiceAtom.reportRead();
    return super.selectedDeliveryService;
  }

  @override
  set selectedDeliveryService(DeliveryServiceModel? value) {
    _$selectedDeliveryServiceAtom
        .reportWrite(value, super.selectedDeliveryService, () {
      super.selectedDeliveryService = value;
    });
  }

  late final _$isAddressLoadingAtom =
      Atom(name: '_NewSubscriptionStore.isAddressLoading', context: context);

  @override
  bool get isAddressLoading {
    _$isAddressLoadingAtom.reportRead();
    return super.isAddressLoading;
  }

  @override
  set isAddressLoading(bool value) {
    _$isAddressLoadingAtom.reportWrite(value, super.isAddressLoading, () {
      super.isAddressLoading = value;
    });
  }

  late final _$addressErrorAtom =
      Atom(name: '_NewSubscriptionStore.addressError', context: context);

  @override
  String? get addressError {
    _$addressErrorAtom.reportRead();
    return super.addressError;
  }

  @override
  set addressError(String? value) {
    _$addressErrorAtom.reportWrite(value, super.addressError, () {
      super.addressError = value;
    });
  }

  late final _$isCouponLoadingAtom =
      Atom(name: '_NewSubscriptionStore.isCouponLoading', context: context);

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
      Atom(name: '_NewSubscriptionStore.couponError', context: context);

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

  late final _$appliedCouponAtom =
      Atom(name: '_NewSubscriptionStore.appliedCoupon', context: context);

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

  late final _$isOfferLoadingAtom =
      Atom(name: '_NewSubscriptionStore.isOfferLoading', context: context);

  @override
  bool get isOfferLoading {
    _$isOfferLoadingAtom.reportRead();
    return super.isOfferLoading;
  }

  @override
  set isOfferLoading(bool value) {
    _$isOfferLoadingAtom.reportWrite(value, super.isOfferLoading, () {
      super.isOfferLoading = value;
    });
  }

  late final _$offerErrorAtom =
      Atom(name: '_NewSubscriptionStore.offerError', context: context);

  @override
  String? get offerError {
    _$offerErrorAtom.reportRead();
    return super.offerError;
  }

  @override
  set offerError(String? value) {
    _$offerErrorAtom.reportWrite(value, super.offerError, () {
      super.offerError = value;
    });
  }

  late final _$appliedOfferAtom =
      Atom(name: '_NewSubscriptionStore.appliedOffer', context: context);

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

  late final _$availableOffersAtom =
      Atom(name: '_NewSubscriptionStore.availableOffers', context: context);

  @override
  ObservableList<OfferModel> get availableOffers {
    _$availableOffersAtom.reportRead();
    return super.availableOffers;
  }

  @override
  set availableOffers(ObservableList<OfferModel> value) {
    _$availableOffersAtom.reportWrite(value, super.availableOffers, () {
      super.availableOffers = value;
    });
  }

  late final _$discountAmountAtom =
      Atom(name: '_NewSubscriptionStore.discountAmount', context: context);

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

  late final _$bookDimensionsAtom =
      Atom(name: '_NewSubscriptionStore.bookDimensions', context: context);

  @override
  ObservableMap<String, double> get bookDimensions {
    _$bookDimensionsAtom.reportRead();
    return super.bookDimensions;
  }

  @override
  set bookDimensions(ObservableMap<String, double> value) {
    _$bookDimensionsAtom.reportWrite(value, super.bookDimensions, () {
      super.bookDimensions = value;
    });
  }

  late final _$bookHeightAtom =
      Atom(name: '_NewSubscriptionStore.bookHeight', context: context);

  @override
  double? get bookHeight {
    _$bookHeightAtom.reportRead();
    return super.bookHeight;
  }

  @override
  set bookHeight(double? value) {
    _$bookHeightAtom.reportWrite(value, super.bookHeight, () {
      super.bookHeight = value;
    });
  }

  late final _$bookWidthAtom =
      Atom(name: '_NewSubscriptionStore.bookWidth', context: context);

  @override
  double? get bookWidth {
    _$bookWidthAtom.reportRead();
    return super.bookWidth;
  }

  @override
  set bookWidth(double? value) {
    _$bookWidthAtom.reportWrite(value, super.bookWidth, () {
      super.bookWidth = value;
    });
  }

  late final _$bookLengthAtom =
      Atom(name: '_NewSubscriptionStore.bookLength', context: context);

  @override
  double? get bookLength {
    _$bookLengthAtom.reportRead();
    return super.bookLength;
  }

  @override
  set bookLength(double? value) {
    _$bookLengthAtom.reportWrite(value, super.bookLength, () {
      super.bookLength = value;
    });
  }

  late final _$bookBreadthAtom =
      Atom(name: '_NewSubscriptionStore.bookBreadth', context: context);

  @override
  double? get bookBreadth {
    _$bookBreadthAtom.reportRead();
    return super.bookBreadth;
  }

  @override
  set bookBreadth(double? value) {
    _$bookBreadthAtom.reportWrite(value, super.bookBreadth, () {
      super.bookBreadth = value;
    });
  }

  late final _$pincodeAddressesAtom =
      Atom(name: '_NewSubscriptionStore.pincodeAddresses', context: context);

  @override
  ObservableList<PincodeAddressModel> get pincodeAddresses {
    _$pincodeAddressesAtom.reportRead();
    return super.pincodeAddresses;
  }

  @override
  set pincodeAddresses(ObservableList<PincodeAddressModel> value) {
    _$pincodeAddressesAtom.reportWrite(value, super.pincodeAddresses, () {
      super.pincodeAddresses = value;
    });
  }

  late final _$isPincodeAddressLoadingAtom = Atom(
      name: '_NewSubscriptionStore.isPincodeAddressLoading', context: context);

  @override
  bool get isPincodeAddressLoading {
    _$isPincodeAddressLoadingAtom.reportRead();
    return super.isPincodeAddressLoading;
  }

  @override
  set isPincodeAddressLoading(bool value) {
    _$isPincodeAddressLoadingAtom
        .reportWrite(value, super.isPincodeAddressLoading, () {
      super.isPincodeAddressLoading = value;
    });
  }

  late final _$pincodeAddressErrorAtom =
      Atom(name: '_NewSubscriptionStore.pincodeAddressError', context: context);

  @override
  String? get pincodeAddressError {
    _$pincodeAddressErrorAtom.reportRead();
    return super.pincodeAddressError;
  }

  @override
  set pincodeAddressError(String? value) {
    _$pincodeAddressErrorAtom.reportWrite(value, super.pincodeAddressError, () {
      super.pincodeAddressError = value;
    });
  }

  late final _$getPlanCategoriesAsyncAction =
      AsyncAction('_NewSubscriptionStore.getPlanCategories', context: context);

  @override
  Future<void> getPlanCategories() {
    return _$getPlanCategoriesAsyncAction.run(() => super.getPlanCategories());
  }

  late final _$getPlanSubcategoriesAsyncAction = AsyncAction(
      '_NewSubscriptionStore.getPlanSubcategories',
      context: context);

  @override
  Future<void> getPlanSubcategories(String categoryId) {
    return _$getPlanSubcategoriesAsyncAction
        .run(() => super.getPlanSubcategories(categoryId));
  }

  late final _$checkServiceabilityWithDimensionsAsyncAction = AsyncAction(
      '_NewSubscriptionStore.checkServiceabilityWithDimensions',
      context: context);

  @override
  Future<void> checkServiceabilityWithDimensions(String pincode, double weight,
      {double? height, double? width, double? length, double? breadth}) {
    return _$checkServiceabilityWithDimensionsAsyncAction.run(() => super
        .checkServiceabilityWithDimensions(pincode, weight,
            height: height, width: width, length: length, breadth: breadth));
  }

  late final _$createAddressAsyncAction =
      AsyncAction('_NewSubscriptionStore.createAddress', context: context);

  @override
  Future<bool> createAddress(Map<String, dynamic> addressData) {
    return _$createAddressAsyncAction
        .run(() => super.createAddress(addressData));
  }

  late final _$verifyCouponAsyncAction =
      AsyncAction('_NewSubscriptionStore.verifyCoupon', context: context);

  @override
  Future<bool> verifyCoupon(
      String couponCode, List<Map<String, dynamic>> selectedPlans) {
    return _$verifyCouponAsyncAction
        .run(() => super.verifyCoupon(couponCode, selectedPlans));
  }

  late final _$getAvailableOffersAsyncAction =
      AsyncAction('_NewSubscriptionStore.getAvailableOffers', context: context);

  @override
  Future<void> getAvailableOffers() {
    return _$getAvailableOffersAsyncAction
        .run(() => super.getAvailableOffers());
  }

  late final _$checkServiceabilityAsyncAction = AsyncAction(
      '_NewSubscriptionStore.checkServiceability',
      context: context);

  @override
  Future<void> checkServiceability(String pincode, double weight,
      {double? height, double? width, double? length, double? breadth}) {
    return _$checkServiceabilityAsyncAction.run(() => super.checkServiceability(
        pincode, weight,
        height: height, width: width, length: length, breadth: breadth));
  }

  late final _$getPincodeAddressesAsyncAction = AsyncAction(
      '_NewSubscriptionStore.getPincodeAddresses',
      context: context);

  @override
  Future<void> getPincodeAddresses(String pincode) {
    return _$getPincodeAddressesAsyncAction
        .run(() => super.getPincodeAddresses(pincode));
  }

  late final _$_NewSubscriptionStoreActionController =
      ActionController(name: '_NewSubscriptionStore', context: context);

  @override
  void setSelectedCategory(String categoryId) {
    final _$actionInfo = _$_NewSubscriptionStoreActionController.startAction(
        name: '_NewSubscriptionStore.setSelectedCategory');
    try {
      return super.setSelectedCategory(categoryId);
    } finally {
      _$_NewSubscriptionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPincode(String value) {
    final _$actionInfo = _$_NewSubscriptionStoreActionController.startAction(
        name: '_NewSubscriptionStore.setPincode');
    try {
      return super.setPincode(value);
    } finally {
      _$_NewSubscriptionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearDeliveryServices() {
    final _$actionInfo = _$_NewSubscriptionStoreActionController.startAction(
        name: '_NewSubscriptionStore.clearDeliveryServices');
    try {
      return super.clearDeliveryServices();
    } finally {
      _$_NewSubscriptionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSelectedDeliveryService(DeliveryServiceModel service) {
    final _$actionInfo = _$_NewSubscriptionStoreActionController.startAction(
        name: '_NewSubscriptionStore.setSelectedDeliveryService');
    try {
      return super.setSelectedDeliveryService(service);
    } finally {
      _$_NewSubscriptionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearCoupon() {
    final _$actionInfo = _$_NewSubscriptionStoreActionController.startAction(
        name: '_NewSubscriptionStore.clearCoupon');
    try {
      return super.clearCoupon();
    } finally {
      _$_NewSubscriptionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool applyOffer(OfferModel offer, List<Map<String, dynamic>> selectedPlans,
      {List<Map<String, dynamic>>? selectedBooks,
      Map<int, int>? bookQuantities}) {
    final _$actionInfo = _$_NewSubscriptionStoreActionController.startAction(
        name: '_NewSubscriptionStore.applyOffer');
    try {
      return super.applyOffer(offer, selectedPlans,
          selectedBooks: selectedBooks, bookQuantities: bookQuantities);
    } finally {
      _$_NewSubscriptionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearOffer() {
    final _$actionInfo = _$_NewSubscriptionStoreActionController.startAction(
        name: '_NewSubscriptionStore.clearOffer');
    try {
      return super.clearOffer();
    } finally {
      _$_NewSubscriptionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectAddress(Map<String, dynamic> address) {
    final _$actionInfo = _$_NewSubscriptionStoreActionController.startAction(
        name: '_NewSubscriptionStore.selectAddress');
    try {
      return super.selectAddress(address);
    } finally {
      _$_NewSubscriptionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
isSubcategoryLoading: ${isSubcategoryLoading},
planCategories: ${planCategories},
planSubcategories: ${planSubcategories},
selectedCategory: ${selectedCategory},
error: ${error},
deliveryServices: ${deliveryServices},
isServiceabilityLoading: ${isServiceabilityLoading},
serviceabilityError: ${serviceabilityError},
showServiceabilityMessage: ${showServiceabilityMessage},
pincode: ${pincode},
selectedAddress: ${selectedAddress},
selectedDeliveryService: ${selectedDeliveryService},
isAddressLoading: ${isAddressLoading},
addressError: ${addressError},
isCouponLoading: ${isCouponLoading},
couponError: ${couponError},
appliedCoupon: ${appliedCoupon},
isOfferLoading: ${isOfferLoading},
offerError: ${offerError},
appliedOffer: ${appliedOffer},
availableOffers: ${availableOffers},
discountAmount: ${discountAmount},
bookDimensions: ${bookDimensions},
bookHeight: ${bookHeight},
bookWidth: ${bookWidth},
bookLength: ${bookLength},
bookBreadth: ${bookBreadth},
pincodeAddresses: ${pincodeAddresses},
isPincodeAddressLoading: ${isPincodeAddressLoading},
pincodeAddressError: ${pincodeAddressError}
    ''';
  }
}
