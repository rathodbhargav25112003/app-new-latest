// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_bookmark_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$BookmarkNewStore on _BookmarkNewStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_BookmarkNewStore.isLoading', context: context);

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

  late final _$selectedBookmarkCategoryAtom = Atom(
      name: '_BookmarkNewStore.selectedBookmarkCategory', context: context);

  @override
  Observable<List<BookMarkCategoryModel>?> get selectedBookmarkCategory {
    _$selectedBookmarkCategoryAtom.reportRead();
    return super.selectedBookmarkCategory;
  }

  @override
  set selectedBookmarkCategory(Observable<List<BookMarkCategoryModel>?> value) {
    _$selectedBookmarkCategoryAtom
        .reportWrite(value, super.selectedBookmarkCategory, () {
      super.selectedBookmarkCategory = value;
    });
  }

  late final _$selectedBookmarkSubCategoryAtom = Atom(
      name: '_BookmarkNewStore.selectedBookmarkSubCategory', context: context);

  @override
  Observable<List<BookMarkSubCategoryModel>> get selectedBookmarkSubCategory {
    _$selectedBookmarkSubCategoryAtom.reportRead();
    return super.selectedBookmarkSubCategory;
  }

  @override
  set selectedBookmarkSubCategory(
      Observable<List<BookMarkSubCategoryModel>> value) {
    _$selectedBookmarkSubCategoryAtom
        .reportWrite(value, super.selectedBookmarkSubCategory, () {
      super.selectedBookmarkSubCategory = value;
    });
  }

  late final _$selectedBookmarkTopicAtom =
      Atom(name: '_BookmarkNewStore.selectedBookmarkTopic', context: context);

  @override
  Observable<List<BookMarkTopicModel>> get selectedBookmarkTopic {
    _$selectedBookmarkTopicAtom.reportRead();
    return super.selectedBookmarkTopic;
  }

  @override
  set selectedBookmarkTopic(Observable<List<BookMarkTopicModel>> value) {
    _$selectedBookmarkTopicAtom.reportWrite(value, super.selectedBookmarkTopic,
        () {
      super.selectedBookmarkTopic = value;
    });
  }

  late final _$selectedBookmarkTestAtom =
      Atom(name: '_BookmarkNewStore.selectedBookmarkTest', context: context);

  @override
  Observable<List<BookMarkByExamListModel>> get selectedBookmarkTest {
    _$selectedBookmarkTestAtom.reportRead();
    return super.selectedBookmarkTest;
  }

  @override
  set selectedBookmarkTest(Observable<List<BookMarkByExamListModel>> value) {
    _$selectedBookmarkTestAtom.reportWrite(value, super.selectedBookmarkTest,
        () {
      super.selectedBookmarkTest = value;
    });
  }

  late final _$bookmarkTestModelAtom =
      Atom(name: '_BookmarkNewStore.bookmarkTestModel', context: context);

  @override
  Observable<BookmarkTestModel?> get bookmarkTestModel {
    _$bookmarkTestModelAtom.reportRead();
    return super.bookmarkTestModel;
  }

  @override
  set bookmarkTestModel(Observable<BookmarkTestModel?> value) {
    _$bookmarkTestModelAtom.reportWrite(value, super.bookmarkTestModel, () {
      super.bookmarkTestModel = value;
    });
  }

  late final _$nameAtom =
      Atom(name: '_BookmarkNewStore.name', context: context);

  @override
  Observable<String> get name {
    _$nameAtom.reportRead();
    return super.name;
  }

  @override
  set name(Observable<String> value) {
    _$nameAtom.reportWrite(value, super.name, () {
      super.name = value;
    });
  }

  late final _$descriptionAtom =
      Atom(name: '_BookmarkNewStore.description', context: context);

  @override
  Observable<String> get description {
    _$descriptionAtom.reportRead();
    return super.description;
  }

  @override
  set description(Observable<String> value) {
    _$descriptionAtom.reportWrite(value, super.description, () {
      super.description = value;
    });
  }

  late final _$minAtom = Atom(name: '_BookmarkNewStore.min', context: context);

  @override
  Observable<int> get min {
    _$minAtom.reportRead();
    return super.min;
  }

  @override
  set min(Observable<int> value) {
    _$minAtom.reportWrite(value, super.min, () {
      super.min = value;
    });
  }

  late final _$questionAtom =
      Atom(name: '_BookmarkNewStore.question', context: context);

  @override
  Observable<int> get question {
    _$questionAtom.reportRead();
    return super.question;
  }

  @override
  set question(Observable<int> value) {
    _$questionAtom.reportWrite(value, super.question, () {
      super.question = value;
    });
  }

  late final _$examsDataAtom =
      Atom(name: '_BookmarkNewStore.examsData', context: context);

  @override
  Observable<McqExamData?> get examsData {
    _$examsDataAtom.reportRead();
    return super.examsData;
  }

  @override
  set examsData(Observable<McqExamData?> value) {
    _$examsDataAtom.reportWrite(value, super.examsData, () {
      super.examsData = value;
    });
  }

  late final _$ongetAllMyCustomTestApiCallAsyncAction = AsyncAction(
      '_BookmarkNewStore.ongetAllMyCustomTestApiCall',
      context: context);

  @override
  Future<void> ongetAllMyCustomTestApiCall(String type) {
    return _$ongetAllMyCustomTestApiCallAsyncAction
        .run(() => super.ongetAllMyCustomTestApiCall(type));
  }

  late final _$ongetCustomAnalysisApiCallAsyncAction = AsyncAction(
      '_BookmarkNewStore.ongetCustomAnalysisApiCall',
      context: context);

  @override
  Future<void> ongetCustomAnalysisApiCall(String type, String id, bool isAll) {
    return _$ongetCustomAnalysisApiCallAsyncAction
        .run(() => super.ongetCustomAnalysisApiCall(type, id, isAll));
  }

  late final _$ongetCustomADeleteApiCallAsyncAction = AsyncAction(
      '_BookmarkNewStore.ongetCustomADeleteApiCall',
      context: context);

  @override
  Future<void> ongetCustomADeleteApiCall(String type, String id) {
    return _$ongetCustomADeleteApiCallAsyncAction
        .run(() => super.ongetCustomADeleteApiCall(type, id));
  }

  late final _$onCreateCustomeExamApiCallAsyncAction = AsyncAction(
      '_BookmarkNewStore.onCreateCustomeExamApiCall',
      context: context);

  @override
  Future<Map<String, dynamic>?> onCreateCustomeExamApiCall(
      String type, Map<String, dynamic> data) {
    return _$onCreateCustomeExamApiCallAsyncAction
        .run(() => super.onCreateCustomeExamApiCall(type, data));
  }

  late final _$ongetBookmarkMacqQuestionsListApiCallAsyncAction = AsyncAction(
      '_BookmarkNewStore.ongetBookmarkMacqQuestionsListApiCall',
      context: context);

  @override
  Future<List<test.TestData>> ongetBookmarkMacqQuestionsListApiCall(
      String type, String id, bool isAll, bool isMock, bool isCustome) {
    return _$ongetBookmarkMacqQuestionsListApiCallAsyncAction.run(() => super
        .ongetBookmarkMacqQuestionsListApiCall(
            type, id, isAll, isMock, isCustome));
  }

  late final _$ongetReBookmarkMacqQuestionsListApiCallAsyncAction = AsyncAction(
      '_BookmarkNewStore.ongetReBookmarkMacqQuestionsListApiCall',
      context: context);

  @override
  Future<List<test.TestData>> ongetReBookmarkMacqQuestionsListApiCall(
      String type, String sectionType, String id, bool isAll, bool isCustom) {
    return _$ongetReBookmarkMacqQuestionsListApiCallAsyncAction.run(() => super
        .ongetReBookmarkMacqQuestionsListApiCall(
            type, sectionType, id, isAll, isCustom));
  }

  late final _$createModuleAsyncAction =
      AsyncAction('_BookmarkNewStore.createModule', context: context);

  @override
  Future<void> createModule(Map<String, dynamic> data, String type) {
    return _$createModuleAsyncAction.run(() => super.createModule(data, type));
  }

  late final _$selectBookmarkCategoryAsyncAction =
      AsyncAction('_BookmarkNewStore.selectBookmarkCategory', context: context);

  @override
  Future<void> selectBookmarkCategory(BookMarkCategoryModel category) {
    return _$selectBookmarkCategoryAsyncAction
        .run(() => super.selectBookmarkCategory(category));
  }

  late final _$selectAllBookmarkCategoriesAsyncAction = AsyncAction(
      '_BookmarkNewStore.selectAllBookmarkCategories',
      context: context);

  @override
  Future<void> selectAllBookmarkCategories(
      List<BookMarkCategoryModel> categories) {
    return _$selectAllBookmarkCategoriesAsyncAction
        .run(() => super.selectAllBookmarkCategories(categories));
  }

  late final _$deselectAllBookmarkCategoriesAsyncAction = AsyncAction(
      '_BookmarkNewStore.deselectAllBookmarkCategories',
      context: context);

  @override
  Future<void> deselectAllBookmarkCategories() {
    return _$deselectAllBookmarkCategoriesAsyncAction
        .run(() => super.deselectAllBookmarkCategories());
  }

  late final _$removeBookmarkCategoryAsyncAction =
      AsyncAction('_BookmarkNewStore.removeBookmarkCategory', context: context);

  @override
  Future<void> removeBookmarkCategory(BookMarkCategoryModel category) {
    return _$removeBookmarkCategoryAsyncAction
        .run(() => super.removeBookmarkCategory(category));
  }

  late final _$selectBookmarkSubCategoryAsyncAction = AsyncAction(
      '_BookmarkNewStore.selectBookmarkSubCategory',
      context: context);

  @override
  Future<void> selectBookmarkSubCategory(BookMarkSubCategoryModel subCategory) {
    return _$selectBookmarkSubCategoryAsyncAction
        .run(() => super.selectBookmarkSubCategory(subCategory));
  }

  late final _$selectAllBookmarkSubCategoriesAsyncAction = AsyncAction(
      '_BookmarkNewStore.selectAllBookmarkSubCategories',
      context: context);

  @override
  Future<void> selectAllBookmarkSubCategories(
      List<BookMarkSubCategoryModel> allSubCategories) {
    return _$selectAllBookmarkSubCategoriesAsyncAction
        .run(() => super.selectAllBookmarkSubCategories(allSubCategories));
  }

  late final _$deselectAllBookmarkSubCategoriesAsyncAction = AsyncAction(
      '_BookmarkNewStore.deselectAllBookmarkSubCategories',
      context: context);

  @override
  Future<void> deselectAllBookmarkSubCategories() {
    return _$deselectAllBookmarkSubCategoriesAsyncAction
        .run(() => super.deselectAllBookmarkSubCategories());
  }

  late final _$removeBookmarkSubCategoryAsyncAction = AsyncAction(
      '_BookmarkNewStore.removeBookmarkSubCategory',
      context: context);

  @override
  Future<void> removeBookmarkSubCategory(BookMarkSubCategoryModel subCategory) {
    return _$removeBookmarkSubCategoryAsyncAction
        .run(() => super.removeBookmarkSubCategory(subCategory));
  }

  late final _$selectBookmarkTopicAsyncAction =
      AsyncAction('_BookmarkNewStore.selectBookmarkTopic', context: context);

  @override
  Future<void> selectBookmarkTopic(BookMarkTopicModel topic) {
    return _$selectBookmarkTopicAsyncAction
        .run(() => super.selectBookmarkTopic(topic));
  }

  late final _$selectAllBookmarkTopicsAsyncAction = AsyncAction(
      '_BookmarkNewStore.selectAllBookmarkTopics',
      context: context);

  @override
  Future<void> selectAllBookmarkTopics(List<BookMarkTopicModel> allTopics) {
    return _$selectAllBookmarkTopicsAsyncAction
        .run(() => super.selectAllBookmarkTopics(allTopics));
  }

  late final _$deselectAllBookmarkTopicsAsyncAction = AsyncAction(
      '_BookmarkNewStore.deselectAllBookmarkTopics',
      context: context);

  @override
  Future<void> deselectAllBookmarkTopics() {
    return _$deselectAllBookmarkTopicsAsyncAction
        .run(() => super.deselectAllBookmarkTopics());
  }

  late final _$removeBookmarkTopicAsyncAction =
      AsyncAction('_BookmarkNewStore.removeBookmarkTopic', context: context);

  @override
  Future<void> removeBookmarkTopic(BookMarkTopicModel topic) {
    return _$removeBookmarkTopicAsyncAction
        .run(() => super.removeBookmarkTopic(topic));
  }

  late final _$selectBookmarkTestAsyncAction =
      AsyncAction('_BookmarkNewStore.selectBookmarkTest', context: context);

  @override
  Future<void> selectBookmarkTest(BookMarkByExamListModel test) {
    return _$selectBookmarkTestAsyncAction
        .run(() => super.selectBookmarkTest(test));
  }

  late final _$selectAllBookmarkTestsAsyncAction =
      AsyncAction('_BookmarkNewStore.selectAllBookmarkTests', context: context);

  @override
  Future<void> selectAllBookmarkTests(List<BookMarkByExamListModel> allTests) {
    return _$selectAllBookmarkTestsAsyncAction
        .run(() => super.selectAllBookmarkTests(allTests));
  }

  late final _$deselectAllBookmarkTestsAsyncAction = AsyncAction(
      '_BookmarkNewStore.deselectAllBookmarkTests',
      context: context);

  @override
  Future<void> deselectAllBookmarkTests() {
    return _$deselectAllBookmarkTestsAsyncAction
        .run(() => super.deselectAllBookmarkTests());
  }

  late final _$removeBookmarkTestAsyncAction =
      AsyncAction('_BookmarkNewStore.removeBookmarkTest', context: context);

  @override
  Future<void> removeBookmarkTest(BookMarkByExamListModel test) {
    return _$removeBookmarkTestAsyncAction
        .run(() => super.removeBookmarkTest(test));
  }

  late final _$resetBookmarkAsyncAction =
      AsyncAction('_BookmarkNewStore.resetBookmark', context: context);

  @override
  Future<void> resetBookmark() {
    return _$resetBookmarkAsyncAction.run(() => super.resetBookmark());
  }

  late final _$setValueAsyncAction =
      AsyncAction('_BookmarkNewStore.setValue', context: context);

  @override
  Future<void> setValue(String testName, String testdescription, int duration,
      int numberOfQuestions) {
    return _$setValueAsyncAction.run(() =>
        super.setValue(testName, testdescription, duration, numberOfQuestions));
  }

  late final _$_BookmarkNewStoreActionController =
      ActionController(name: '_BookmarkNewStore', context: context);

  @override
  void deleteCategoryAndLinkedData(String categoryId) {
    final _$actionInfo = _$_BookmarkNewStoreActionController.startAction(
        name: '_BookmarkNewStore.deleteCategoryAndLinkedData');
    try {
      return super.deleteCategoryAndLinkedData(categoryId);
    } finally {
      _$_BookmarkNewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deleteSubcategoryAndLinkedData(String subcategoryId) {
    final _$actionInfo = _$_BookmarkNewStoreActionController.startAction(
        name: '_BookmarkNewStore.deleteSubcategoryAndLinkedData');
    try {
      return super.deleteSubcategoryAndLinkedData(subcategoryId);
    } finally {
      _$_BookmarkNewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deleteTopicAndLinkedData(String topicId) {
    final _$actionInfo = _$_BookmarkNewStoreActionController.startAction(
        name: '_BookmarkNewStore.deleteTopicAndLinkedData');
    try {
      return super.deleteTopicAndLinkedData(topicId);
    } finally {
      _$_BookmarkNewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
selectedBookmarkCategory: ${selectedBookmarkCategory},
selectedBookmarkSubCategory: ${selectedBookmarkSubCategory},
selectedBookmarkTopic: ${selectedBookmarkTopic},
selectedBookmarkTest: ${selectedBookmarkTest},
bookmarkTestModel: ${bookmarkTestModel},
name: ${name},
description: ${description},
min: ${min},
question: ${question},
examsData: ${examsData}
    ''';
  }
}
