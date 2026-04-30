// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upgrade_plan_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$UpgradePlanStore on _UpgradePlanStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_UpgradePlanStore.isLoading', context: context);

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
      Atom(name: '_UpgradePlanStore.error', context: context);

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

  late final _$plansListAtom =
      Atom(name: '_UpgradePlanStore.plansList', context: context);

  @override
  ObservableList<AllPlansResponseModel> get plansList {
    _$plansListAtom.reportRead();
    return super.plansList;
  }

  @override
  set plansList(ObservableList<AllPlansResponseModel> value) {
    _$plansListAtom.reportWrite(value, super.plansList, () {
      super.plansList = value;
    });
  }

  late final _$fetchUpgradePlansAsyncAction =
      AsyncAction('_UpgradePlanStore.fetchUpgradePlans', context: context);

  @override
  Future<void> fetchUpgradePlans(
      {required String subscriptionId,
      bool? sameValidity,
      bool? isDiffValidity}) {
    return _$fetchUpgradePlansAsyncAction.run(() => super.fetchUpgradePlans(
        subscriptionId: subscriptionId,
        sameValidity: sameValidity,
        isDiffValidity: isDiffValidity));
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
error: ${error},
plansList: ${plansList}
    ''';
  }
}
