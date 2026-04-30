// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hardcopy_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$HardcopyStore on _HardcopyStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_HardcopyStore.isLoading', context: context);

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

  late final _$booksAtom = Atom(name: '_HardcopyStore.books', context: context);

  @override
  ObservableList<BookModel> get books {
    _$booksAtom.reportRead();
    return super.books;
  }

  @override
  set books(ObservableList<BookModel> value) {
    _$booksAtom.reportWrite(value, super.books, () {
      super.books = value;
    });
  }

  late final _$errorAtom = Atom(name: '_HardcopyStore.error', context: context);

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

  late final _$fetchAllBooksAsyncAction =
      AsyncAction('_HardcopyStore.fetchAllBooks', context: context);

  @override
  Future<void> fetchAllBooks() {
    return _$fetchAllBooksAsyncAction.run(() => super.fetchAllBooks());
  }

  late final _$_HardcopyStoreActionController =
      ActionController(name: '_HardcopyStore', context: context);

  @override
  void clearBooks() {
    final _$actionInfo = _$_HardcopyStoreActionController.startAction(
        name: '_HardcopyStore.clearBooks');
    try {
      return super.clearBooks();
    } finally {
      _$_HardcopyStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
books: ${books},
error: ${error}
    ''';
  }
}
