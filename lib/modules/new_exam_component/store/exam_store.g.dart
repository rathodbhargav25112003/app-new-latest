// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ExamStore on _ExamStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_ExamStore.isLoading', context: context);

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

  late final _$isSubmittingAtom =
      Atom(name: '_ExamStore.isSubmitting', context: context);

  @override
  bool get isSubmitting {
    _$isSubmittingAtom.reportRead();
    return super.isSubmitting;
  }

  @override
  set isSubmitting(bool value) {
    _$isSubmittingAtom.reportWrite(value, super.isSubmitting, () {
      super.isSubmitting = value;
    });
  }

  late final _$answerCountSinceLastTriggerAtom =
      Atom(name: '_ExamStore.answerCountSinceLastTrigger', context: context);

  @override
  int get answerCountSinceLastTrigger {
    _$answerCountSinceLastTriggerAtom.reportRead();
    return super.answerCountSinceLastTrigger;
  }

  @override
  set answerCountSinceLastTrigger(int value) {
    _$answerCountSinceLastTriggerAtom
        .reportWrite(value, super.answerCountSinceLastTrigger, () {
      super.answerCountSinceLastTrigger = value;
    });
  }

  late final _$questionListAtom =
      Atom(name: '_ExamStore.questionList', context: context);

  @override
  Observable<List<TestData>> get questionList {
    _$questionListAtom.reportRead();
    return super.questionList;
  }

  @override
  set questionList(Observable<List<TestData>> value) {
    _$questionListAtom.reportWrite(value, super.questionList, () {
      super.questionList = value;
    });
  }

  late final _$ansListAtom = Atom(name: '_ExamStore.ansList', context: context);

  @override
  Observable<List<ExamAnsModel>> get ansList {
    _$ansListAtom.reportRead();
    return super.ansList;
  }

  @override
  set ansList(Observable<List<ExamAnsModel>> value) {
    _$ansListAtom.reportWrite(value, super.ansList, () {
      super.ansList = value;
    });
  }

  late final _$savedAnsListAtom =
      Atom(name: '_ExamStore.savedAnsList', context: context);

  @override
  Observable<List<ExamAnsModel>> get savedAnsList {
    _$savedAnsListAtom.reportRead();
    return super.savedAnsList;
  }

  @override
  set savedAnsList(Observable<List<ExamAnsModel>> value) {
    _$savedAnsListAtom.reportWrite(value, super.savedAnsList, () {
      super.savedAnsList = value;
    });
  }

  late final _$typeAtom = Atom(name: '_ExamStore.type', context: context);

  @override
  Observable<String> get type {
    _$typeAtom.reportRead();
    return super.type;
  }

  @override
  set type(Observable<String> value) {
    _$typeAtom.reportWrite(value, super.type, () {
      super.type = value;
    });
  }

  late final _$questionAtom =
      Atom(name: '_ExamStore.question', context: context);

  @override
  Observable<TestData?> get question {
    _$questionAtom.reportRead();
    return super.question;
  }

  @override
  set question(Observable<TestData?> value) {
    _$questionAtom.reportWrite(value, super.question, () {
      super.question = value;
    });
  }

  late final _$currentQuestionIndexAtom =
      Atom(name: '_ExamStore.currentQuestionIndex', context: context);

  @override
  Observable<int?> get currentQuestionIndex {
    _$currentQuestionIndexAtom.reportRead();
    return super.currentQuestionIndex;
  }

  @override
  set currentQuestionIndex(Observable<int?> value) {
    _$currentQuestionIndexAtom.reportWrite(value, super.currentQuestionIndex,
        () {
      super.currentQuestionIndex = value;
    });
  }

  late final _$selectedOptionIndexAtom =
      Atom(name: '_ExamStore.selectedOptionIndex', context: context);

  @override
  Observable<int> get selectedOptionIndex {
    _$selectedOptionIndexAtom.reportRead();
    return super.selectedOptionIndex;
  }

  @override
  set selectedOptionIndex(Observable<int> value) {
    _$selectedOptionIndexAtom.reportWrite(value, super.selectedOptionIndex, () {
      super.selectedOptionIndex = value;
    });
  }

  late final _$trackerAtom = Atom(name: '_ExamStore.tracker', context: context);

  @override
  Observable<TimeTracker> get tracker {
    _$trackerAtom.reportRead();
    return super.tracker;
  }

  @override
  set tracker(Observable<TimeTracker> value) {
    _$trackerAtom.reportWrite(value, super.tracker, () {
      super.tracker = value;
    });
  }

  late final _$reportsMasterExamAtom =
      Atom(name: '_ExamStore.reportsMasterExam', context: context);

  @override
  Observable<ReportByCategoryModel?> get reportsMasterExam {
    _$reportsMasterExamAtom.reportRead();
    return super.reportsMasterExam;
  }

  @override
  set reportsMasterExam(Observable<ReportByCategoryModel?> value) {
    _$reportsMasterExamAtom.reportWrite(value, super.reportsMasterExam, () {
      super.reportsMasterExam = value;
    });
  }

  late final _$isGuessAtom = Atom(name: '_ExamStore.isGuess', context: context);

  @override
  Observable<bool> get isGuess {
    _$isGuessAtom.reportRead();
    return super.isGuess;
  }

  @override
  set isGuess(Observable<bool> value) {
    _$isGuessAtom.reportWrite(value, super.isGuess, () {
      super.isGuess = value;
    });
  }

  late final _$isMarkedForReviewAtom =
      Atom(name: '_ExamStore.isMarkedForReview', context: context);

  @override
  Observable<bool> get isMarkedForReview {
    _$isMarkedForReviewAtom.reportRead();
    return super.isMarkedForReview;
  }

  @override
  set isMarkedForReview(Observable<bool> value) {
    _$isMarkedForReviewAtom.reportWrite(value, super.isMarkedForReview, () {
      super.isMarkedForReview = value;
    });
  }

  late final _$showSheetAtom =
      Atom(name: '_ExamStore.showSheet', context: context);

  @override
  Observable<bool> get showSheet {
    _$showSheetAtom.reportRead();
    return super.showSheet;
  }

  @override
  set showSheet(Observable<bool> value) {
    _$showSheetAtom.reportWrite(value, super.showSheet, () {
      super.showSheet = value;
    });
  }

  late final _$isSavingAtom =
      Atom(name: '_ExamStore.isSaving', context: context);

  @override
  Observable<bool> get isSaving {
    _$isSavingAtom.reportRead();
    return super.isSaving;
  }

  @override
  set isSaving(Observable<bool> value) {
    _$isSavingAtom.reportWrite(value, super.isSaving, () {
      super.isSaving = value;
    });
  }

  late final _$isSubmitAtom =
      Atom(name: '_ExamStore.isSubmit', context: context);

  @override
  Observable<bool> get isSubmit {
    _$isSubmitAtom.reportRead();
    return super.isSubmit;
  }

  @override
  set isSubmit(Observable<bool> value) {
    _$isSubmitAtom.reportWrite(value, super.isSubmit, () {
      super.isSubmit = value;
    });
  }

  late final _$reportsExamAtom =
      Atom(name: '_ExamStore.reportsExam', context: context);

  @override
  Observable<ReportByCategoryModel?> get reportsExam {
    _$reportsExamAtom.reportRead();
    return super.reportsExam;
  }

  @override
  set reportsExam(Observable<ReportByCategoryModel?> value) {
    _$reportsExamAtom.reportWrite(value, super.reportsExam, () {
      super.reportsExam = value;
    });
  }

  late final _$onAnsSaveAsyncAction =
      AsyncAction('_ExamStore.onAnsSave', context: context);

  @override
  Future<void> onAnsSave(BuildContext context, bool isShow) {
    return _$onAnsSaveAsyncAction.run(() => super.onAnsSave(context, isShow));
  }

  late final _$onChangeAsyncAction =
      AsyncAction('_ExamStore.onChange', context: context);

  @override
  Future<void> onChange(TestData q) {
    return _$onChangeAsyncAction.run(() => super.onChange(q));
  }

  late final _$onAnsAsyncAction =
      AsyncAction('_ExamStore.onAns', context: context);

  @override
  Future<void> onAns(ExamAnsModel ans, bool isAdd, String? prevous) {
    return _$onAnsAsyncAction.run(() => super.onAns(ans, isAdd, prevous));
  }

  late final _$onOptionSelectAsyncAction =
      AsyncAction('_ExamStore.onOptionSelect', context: context);

  @override
  Future<void> onOptionSelect(dynamic index) {
    return _$onOptionSelectAsyncAction.run(() => super.onOptionSelect(index));
  }

  late final _$changeIndexAsyncAction =
      AsyncAction('_ExamStore.changeIndex', context: context);

  @override
  Future<void> changeIndex(dynamic index) {
    return _$changeIndexAsyncAction.run(() => super.changeIndex(index));
  }

  late final _$changeMarkReviewAsyncAction =
      AsyncAction('_ExamStore.changeMarkReview', context: context);

  @override
  Future<void> changeMarkReview(bool value) {
    return _$changeMarkReviewAsyncAction
        .run(() => super.changeMarkReview(value));
  }

  late final _$changeGuessAsyncAction =
      AsyncAction('_ExamStore.changeGuess', context: context);

  @override
  Future<void> changeGuess(bool value) {
    return _$changeGuessAsyncAction.run(() => super.changeGuess(value));
  }

  late final _$changeTypeAsyncAction =
      AsyncAction('_ExamStore.changeType', context: context);

  @override
  Future<void> changeType(String value) {
    return _$changeTypeAsyncAction.run(() => super.changeType(value));
  }

  late final _$changeShowSheetAsyncAction =
      AsyncAction('_ExamStore.changeShowSheet', context: context);

  @override
  Future<void> changeShowSheet(bool value) {
    return _$changeShowSheetAsyncAction.run(() => super.changeShowSheet(value));
  }

  late final _$setDataAsyncAction =
      AsyncAction('_ExamStore.setData', context: context);

  @override
  Future<void> setData(List<TestData> questions, String ttype) {
    return _$setDataAsyncAction.run(() => super.setData(questions, ttype));
  }

  late final _$disposeStoreAsyncAction =
      AsyncAction('_ExamStore.disposeStore', context: context);

  @override
  Future<void> disposeStore() {
    return _$disposeStoreAsyncAction.run(() => super.disposeStore());
  }

  late final _$onReportMasterExamApiCallAsyncAction =
      AsyncAction('_ExamStore.onReportMasterExamApiCall', context: context);

  @override
  Future<void> onReportMasterExamApiCall(String id) {
    return _$onReportMasterExamApiCallAsyncAction
        .run(() => super.onReportMasterExamApiCall(id));
  }

  late final _$onMcqQuestionListCallAsyncAction =
      AsyncAction('_ExamStore.onMcqQuestionListCall', context: context);

  @override
  Future<void> onMcqQuestionListCall(String id, String type) {
    return _$onMcqQuestionListCallAsyncAction
        .run(() => super.onMcqQuestionListCall(id, type));
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
isSubmitting: ${isSubmitting},
answerCountSinceLastTrigger: ${answerCountSinceLastTrigger},
questionList: ${questionList},
ansList: ${ansList},
savedAnsList: ${savedAnsList},
type: ${type},
question: ${question},
currentQuestionIndex: ${currentQuestionIndex},
selectedOptionIndex: ${selectedOptionIndex},
tracker: ${tracker},
reportsMasterExam: ${reportsMasterExam},
isGuess: ${isGuess},
isMarkedForReview: ${isMarkedForReview},
showSheet: ${showSheet},
isSaving: ${isSaving},
isSubmit: ${isSubmit},
reportsExam: ${reportsExam}
    ''';
  }
}
