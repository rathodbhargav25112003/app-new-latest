// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_test_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CustomTestCategoryStore on _CustomTestCategoryStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_CustomTestCategoryStore.isLoading', context: context);

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

  late final _$createCustomTestsAtom = Atom(
      name: '_CustomTestCategoryStore.createCustomTests', context: context);

  @override
  Observable<CustomTestModel?> get createCustomTests {
    _$createCustomTestsAtom.reportRead();
    return super.createCustomTests;
  }

  @override
  set createCustomTests(Observable<CustomTestModel?> value) {
    _$createCustomTestsAtom.reportWrite(value, super.createCustomTests, () {
      super.createCustomTests = value;
    });
  }

  late final _$customtestlistAtom =
      Atom(name: '_CustomTestCategoryStore.customtestlist', context: context);

  @override
  Observable<MyCustomTestListModel?> get customtestlist {
    _$customtestlistAtom.reportRead();
    return super.customtestlist;
  }

  @override
  set customtestlist(Observable<MyCustomTestListModel?> value) {
    _$customtestlistAtom.reportWrite(value, super.customtestlist, () {
      super.customtestlist = value;
    });
  }

  late final _$customTestSubByCateListAtom = Atom(
      name: '_CustomTestCategoryStore.customTestSubByCateList',
      context: context);

  @override
  ObservableList<CustomTestSubByCategoryModel?> get customTestSubByCateList {
    _$customTestSubByCateListAtom.reportRead();
    return super.customTestSubByCateList;
  }

  @override
  set customTestSubByCateList(
      ObservableList<CustomTestSubByCategoryModel?> value) {
    _$customTestSubByCateListAtom
        .reportWrite(value, super.customTestSubByCateList, () {
      super.customTestSubByCateList = value;
    });
  }

  late final _$customTestTopicBySubCateListAtom = Atom(
      name: '_CustomTestCategoryStore.customTestTopicBySubCateList',
      context: context);

  @override
  ObservableList<CustomTestTopicBySubCategoryModel?>
      get customTestTopicBySubCateList {
    _$customTestTopicBySubCateListAtom.reportRead();
    return super.customTestTopicBySubCateList;
  }

  @override
  set customTestTopicBySubCateList(
      ObservableList<CustomTestTopicBySubCategoryModel?> value) {
    _$customTestTopicBySubCateListAtom
        .reportWrite(value, super.customTestTopicBySubCateList, () {
      super.customTestTopicBySubCateList = value;
    });
  }

  late final _$customTestExamByTopicsListAtom = Atom(
      name: '_CustomTestCategoryStore.customTestExamByTopicsList',
      context: context);

  @override
  ObservableList<CustomTestExamByTopicModel?> get customTestExamByTopicsList {
    _$customTestExamByTopicsListAtom.reportRead();
    return super.customTestExamByTopicsList;
  }

  @override
  set customTestExamByTopicsList(
      ObservableList<CustomTestExamByTopicModel?> value) {
    _$customTestExamByTopicsListAtom
        .reportWrite(value, super.customTestExamByTopicsList, () {
      super.customTestExamByTopicsList = value;
    });
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
createCustomTests: ${createCustomTests},
customtestlist: ${customtestlist},
customTestSubByCateList: ${customTestSubByCateList},
customTestTopicBySubCateList: ${customTestTopicBySubCateList},
customTestExamByTopicsList: ${customTestExamByTopicsList}
    ''';
  }
}
