// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'internet_check_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$InternetStore on _InternetStore, Store {
  late final _$isConnectedAtom =
      Atom(name: '_InternetStore.isConnected', context: context);

  @override
  bool get isConnected {
    _$isConnectedAtom.reportRead();
    return super.isConnected;
  }

  @override
  set isConnected(bool value) {
    _$isConnectedAtom.reportWrite(value, super.isConnected, () {
      super.isConnected = value;
    });
  }

  late final _$checkConnectionStatusAsyncAction =
      AsyncAction('_InternetStore.checkConnectionStatus', context: context);

  @override
  Future<void> checkConnectionStatus() {
    return _$checkConnectionStatusAsyncAction
        .run(() => super.checkConnectionStatus());
  }

  late final _$_InternetStoreActionController =
      ActionController(name: '_InternetStore', context: context);

  @override
  void setConnectionStatus(bool status) {
    final _$actionInfo = _$_InternetStoreActionController.startAction(
        name: '_InternetStore.setConnectionStatus');
    try {
      return super.setConnectionStatus(status);
    } finally {
      _$_InternetStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isConnected: ${isConnected}
    ''';
  }
}
