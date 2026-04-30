// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$BookMarkStore on _BookMarkStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_BookMarkStore.isLoading', context: context);

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

  late final _$bookmarkCategoryAtom =
      Atom(name: '_BookMarkStore.bookmarkCategory', context: context);

  @override
  ObservableList<BookMarkCategoryModel?> get bookmarkCategory {
    _$bookmarkCategoryAtom.reportRead();
    return super.bookmarkCategory;
  }

  @override
  set bookmarkCategory(ObservableList<BookMarkCategoryModel?> value) {
    _$bookmarkCategoryAtom.reportWrite(value, super.bookmarkCategory, () {
      super.bookmarkCategory = value;
    });
  }

  late final _$masterBookmarkCategoryAtom =
      Atom(name: '_BookMarkStore.masterBookmarkCategory', context: context);

  @override
  ObservableList<BookMarkCategoryModel?> get masterBookmarkCategory {
    _$masterBookmarkCategoryAtom.reportRead();
    return super.masterBookmarkCategory;
  }

  @override
  set masterBookmarkCategory(ObservableList<BookMarkCategoryModel?> value) {
    _$masterBookmarkCategoryAtom
        .reportWrite(value, super.masterBookmarkCategory, () {
      super.masterBookmarkCategory = value;
    });
  }

  late final _$bookmarkSubCategoryAtom =
      Atom(name: '_BookMarkStore.bookmarkSubCategory', context: context);

  @override
  ObservableList<BookMarkSubCategoryModel?> get bookmarkSubCategory {
    _$bookmarkSubCategoryAtom.reportRead();
    return super.bookmarkSubCategory;
  }

  @override
  set bookmarkSubCategory(ObservableList<BookMarkSubCategoryModel?> value) {
    _$bookmarkSubCategoryAtom.reportWrite(value, super.bookmarkSubCategory, () {
      super.bookmarkSubCategory = value;
    });
  }

  late final _$bookmarkTopicAtom =
      Atom(name: '_BookMarkStore.bookmarkTopic', context: context);

  @override
  ObservableList<BookMarkTopicModel?> get bookmarkTopic {
    _$bookmarkTopicAtom.reportRead();
    return super.bookmarkTopic;
  }

  @override
  set bookmarkTopic(ObservableList<BookMarkTopicModel?> value) {
    _$bookmarkTopicAtom.reportWrite(value, super.bookmarkTopic, () {
      super.bookmarkTopic = value;
    });
  }

  late final _$bookmarkListAllAtom =
      Atom(name: '_BookMarkStore.bookmarkListAll', context: context);

  @override
  ObservableList<BookMarkMainListModel?> get bookmarkListAll {
    _$bookmarkListAllAtom.reportRead();
    return super.bookmarkListAll;
  }

  @override
  set bookmarkListAll(ObservableList<BookMarkMainListModel?> value) {
    _$bookmarkListAllAtom.reportWrite(value, super.bookmarkListAll, () {
      super.bookmarkListAll = value;
    });
  }

  late final _$bookMarkByExamAtom =
      Atom(name: '_BookMarkStore.bookMarkByExam', context: context);

  @override
  ObservableList<BookMarkByExamListModel?> get bookMarkByExam {
    _$bookMarkByExamAtom.reportRead();
    return super.bookMarkByExam;
  }

  @override
  set bookMarkByExam(ObservableList<BookMarkByExamListModel?> value) {
    _$bookMarkByExamAtom.reportWrite(value, super.bookMarkByExam, () {
      super.bookMarkByExam = value;
    });
  }

  late final _$masterbookMarkByExamAtom =
      Atom(name: '_BookMarkStore.masterbookMarkByExam', context: context);

  @override
  ObservableList<BookMarkByExamListModel?> get masterbookMarkByExam {
    _$masterbookMarkByExamAtom.reportRead();
    return super.masterbookMarkByExam;
  }

  @override
  set masterbookMarkByExam(ObservableList<BookMarkByExamListModel?> value) {
    _$masterbookMarkByExamAtom.reportWrite(value, super.masterbookMarkByExam,
        () {
      super.masterbookMarkByExam = value;
    });
  }

  late final _$bookMarkByExamTypeAtom =
      Atom(name: '_BookMarkStore.bookMarkByExamType', context: context);

  @override
  ObservableList<BookMarkExamListModel?> get bookMarkByExamType {
    _$bookMarkByExamTypeAtom.reportRead();
    return super.bookMarkByExamType;
  }

  @override
  set bookMarkByExamType(ObservableList<BookMarkExamListModel?> value) {
    _$bookMarkByExamTypeAtom.reportWrite(value, super.bookMarkByExamType, () {
      super.bookMarkByExamType = value;
    });
  }

  late final _$bookMarkQuestionsListAtom =
      Atom(name: '_BookMarkStore.bookMarkQuestionsList', context: context);

  @override
  ObservableList<SolutionReportsModel?> get bookMarkQuestionsList {
    _$bookMarkQuestionsListAtom.reportRead();
    return super.bookMarkQuestionsList;
  }

  @override
  set bookMarkQuestionsList(ObservableList<SolutionReportsModel?> value) {
    _$bookMarkQuestionsListAtom.reportWrite(value, super.bookMarkQuestionsList,
        () {
      super.bookMarkQuestionsList = value;
    });
  }

  late final _$masterBookMarkQuestionsListAtom = Atom(
      name: '_BookMarkStore.masterBookMarkQuestionsList', context: context);

  @override
  ObservableList<SolutionReportsModel?> get masterBookMarkQuestionsList {
    _$masterBookMarkQuestionsListAtom.reportRead();
    return super.masterBookMarkQuestionsList;
  }

  @override
  set masterBookMarkQuestionsList(ObservableList<SolutionReportsModel?> value) {
    _$masterBookMarkQuestionsListAtom
        .reportWrite(value, super.masterBookMarkQuestionsList, () {
      super.masterBookMarkQuestionsList = value;
    });
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
bookmarkCategory: ${bookmarkCategory},
masterBookmarkCategory: ${masterBookmarkCategory},
bookmarkSubCategory: ${bookmarkSubCategory},
bookmarkTopic: ${bookmarkTopic},
bookmarkListAll: ${bookmarkListAll},
bookMarkByExam: ${bookMarkByExam},
masterbookMarkByExam: ${masterbookMarkByExam},
bookMarkByExamType: ${bookMarkByExamType},
bookMarkQuestionsList: ${bookMarkQuestionsList},
masterBookMarkQuestionsList: ${masterBookMarkQuestionsList}
    ''';
  }
}
