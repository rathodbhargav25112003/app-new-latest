// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ordered_book_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$OrderedBookStore on _OrderedBookStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_OrderedBookStore.isLoading', context: context);

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
      Atom(name: '_OrderedBookStore.error', context: context);

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

  late final _$orderedBooksAtom =
      Atom(name: '_OrderedBookStore.orderedBooks', context: context);

  @override
  ObservableList<OrderedBookModel> get orderedBooks {
    _$orderedBooksAtom.reportRead();
    return super.orderedBooks;
  }

  @override
  set orderedBooks(ObservableList<OrderedBookModel> value) {
    _$orderedBooksAtom.reportWrite(value, super.orderedBooks, () {
      super.orderedBooks = value;
    });
  }

  late final _$getAllUserBooksAsyncAction =
      AsyncAction('_OrderedBookStore.getAllUserBooks', context: context);

  @override
  Future<void> getAllUserBooks() {
    return _$getAllUserBooksAsyncAction.run(() => super.getAllUserBooks());
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
error: ${error},
orderedBooks: ${orderedBooks}
    ''';
  }
}
