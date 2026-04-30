// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$OrderStore on _OrderStore, Store {
  Computed<List<TrackOrderActivity>>? _$shipmentActivitiesComputed;

  @override
  List<TrackOrderActivity> get shipmentActivities =>
      (_$shipmentActivitiesComputed ??= Computed<List<TrackOrderActivity>>(
              () => super.shipmentActivities,
              name: '_OrderStore.shipmentActivities'))
          .value;
  Computed<bool>? _$hasShipmentDetailsComputed;

  @override
  bool get hasShipmentDetails => (_$hasShipmentDetailsComputed ??=
          Computed<bool>(() => super.hasShipmentDetails,
              name: '_OrderStore.hasShipmentDetails'))
      .value;
  Computed<String>? _$currentStatusComputed;

  @override
  String get currentStatus =>
      (_$currentStatusComputed ??= Computed<String>(() => super.currentStatus,
              name: '_OrderStore.currentStatus'))
          .value;
  Computed<String>? _$estimatedDeliveryDateComputed;

  @override
  String get estimatedDeliveryDate => (_$estimatedDeliveryDateComputed ??=
          Computed<String>(() => super.estimatedDeliveryDate,
              name: '_OrderStore.estimatedDeliveryDate'))
      .value;

  late final _$isLoadingAtom =
      Atom(name: '_OrderStore.isLoading', context: context);

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

  late final _$errorAtom = Atom(name: '_OrderStore.error', context: context);

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

  late final _$activitiesAtom =
      Atom(name: '_OrderStore.activities', context: context);

  @override
  ObservableList<TrackOrderActivity> get activities {
    _$activitiesAtom.reportRead();
    return super.activities;
  }

  @override
  set activities(ObservableList<TrackOrderActivity> value) {
    _$activitiesAtom.reportWrite(value, super.activities, () {
      super.activities = value;
    });
  }

  late final _$trackOrderAsyncAction =
      AsyncAction('_OrderStore.trackOrder', context: context);

  @override
  Future<void> trackOrder(String orderId, String token, BuildContext context) {
    return _$trackOrderAsyncAction
        .run(() => super.trackOrder(orderId, token, context));
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
error: ${error},
activities: ${activities},
shipmentActivities: ${shipmentActivities},
hasShipmentDetails: ${hasShipmentDetails},
currentStatus: ${currentStatus},
estimatedDeliveryDate: ${estimatedDeliveryDate}
    ''';
  }
}
