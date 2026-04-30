// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_by_category_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ReportsCategoryStore on _ReportsCategoryStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_ReportsCategoryStore.isLoading', context: context);

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

  late final _$reportscategoryAtom =
      Atom(name: '_ReportsCategoryStore.reportscategory', context: context);

  @override
  ObservableList<ReportByCategoryModel?> get reportscategory {
    _$reportscategoryAtom.reportRead();
    return super.reportscategory;
  }

  @override
  set reportscategory(ObservableList<ReportByCategoryModel?> value) {
    _$reportscategoryAtom.reportWrite(value, super.reportscategory, () {
      super.reportscategory = value;
    });
  }

  late final _$customtestreportscategoryAtom = Atom(
      name: '_ReportsCategoryStore.customtestreportscategory',
      context: context);

  @override
  ObservableList<CustomTestReportByCategoryModel?>
      get customtestreportscategory {
    _$customtestreportscategoryAtom.reportRead();
    return super.customtestreportscategory;
  }

  @override
  set customtestreportscategory(
      ObservableList<CustomTestReportByCategoryModel?> value) {
    _$customtestreportscategoryAtom
        .reportWrite(value, super.customtestreportscategory, () {
      super.customtestreportscategory = value;
    });
  }

  late final _$reportbytopicnameAtom =
      Atom(name: '_ReportsCategoryStore.reportbytopicname', context: context);

  @override
  ObservableList<ReportByTopicNameModel?> get reportbytopicname {
    _$reportbytopicnameAtom.reportRead();
    return super.reportbytopicname;
  }

  @override
  set reportbytopicname(ObservableList<ReportByTopicNameModel?> value) {
    _$reportbytopicnameAtom.reportWrite(value, super.reportbytopicname, () {
      super.reportbytopicname = value;
    });
  }

  late final _$reportbytopicstreghtAtom = Atom(
      name: '_ReportsCategoryStore.reportbytopicstreght', context: context);

  @override
  ObservableList<ReportSrengthModel?> get reportbytopicstreght {
    _$reportbytopicstreghtAtom.reportRead();
    return super.reportbytopicstreght;
  }

  @override
  set reportbytopicstreght(ObservableList<ReportSrengthModel?> value) {
    _$reportbytopicstreghtAtom.reportWrite(value, super.reportbytopicstreght,
        () {
      super.reportbytopicstreght = value;
    });
  }

  late final _$trendListAtom =
      Atom(name: '_ReportsCategoryStore.trendList', context: context);

  @override
  Observable<List<TrendAnalysisModel>?> get trendList {
    _$trendListAtom.reportRead();
    return super.trendList;
  }

  @override
  set trendList(Observable<List<TrendAnalysisModel>?> value) {
    _$trendListAtom.reportWrite(value, super.trendList, () {
      super.trendList = value;
    });
  }

  late final _$masterreportscategoryAtom = Atom(
      name: '_ReportsCategoryStore.masterreportscategory', context: context);

  @override
  ObservableList<ReportByCategoryModel?> get masterreportscategory {
    _$masterreportscategoryAtom.reportRead();
    return super.masterreportscategory;
  }

  @override
  set masterreportscategory(ObservableList<ReportByCategoryModel?> value) {
    _$masterreportscategoryAtom.reportWrite(value, super.masterreportscategory,
        () {
      super.masterreportscategory = value;
    });
  }

  late final _$examReportAtom =
      Atom(name: '_ReportsCategoryStore.examReport', context: context);

  @override
  Observable<ExamReport?> get examReport {
    _$examReportAtom.reportRead();
    return super.examReport;
  }

  @override
  set examReport(Observable<ExamReport?> value) {
    _$examReportAtom.reportWrite(value, super.examReport, () {
      super.examReport = value;
    });
  }

  late final _$solutionReportCategoryAtom = Atom(
      name: '_ReportsCategoryStore.solutionReportCategory', context: context);

  @override
  ObservableList<SolutionReportsModel?> get solutionReportCategory {
    _$solutionReportCategoryAtom.reportRead();
    return super.solutionReportCategory;
  }

  @override
  set solutionReportCategory(ObservableList<SolutionReportsModel?> value) {
    _$solutionReportCategoryAtom
        .reportWrite(value, super.solutionReportCategory, () {
      super.solutionReportCategory = value;
    });
  }

  late final _$quizSolutionReportCategoryAtom = Atom(
      name: '_ReportsCategoryStore.quizSolutionReportCategory',
      context: context);

  @override
  ObservableList<QuizSolutionReportsModel?> get quizSolutionReportCategory {
    _$quizSolutionReportCategoryAtom.reportRead();
    return super.quizSolutionReportCategory;
  }

  @override
  set quizSolutionReportCategory(
      ObservableList<QuizSolutionReportsModel?> value) {
    _$quizSolutionReportCategoryAtom
        .reportWrite(value, super.quizSolutionReportCategory, () {
      super.quizSolutionReportCategory = value;
    });
  }

  late final _$customTestSolutionReportCategoryAtom = Atom(
      name: '_ReportsCategoryStore.customTestSolutionReportCategory',
      context: context);

  @override
  ObservableList<CustomTestSolutionReportsModel?>
      get customTestSolutionReportCategory {
    _$customTestSolutionReportCategoryAtom.reportRead();
    return super.customTestSolutionReportCategory;
  }

  @override
  set customTestSolutionReportCategory(
      ObservableList<CustomTestSolutionReportsModel?> value) {
    _$customTestSolutionReportCategoryAtom
        .reportWrite(value, super.customTestSolutionReportCategory, () {
      super.customTestSolutionReportCategory = value;
    });
  }

  late final _$masterSolutionReportCategoryAtom = Atom(
      name: '_ReportsCategoryStore.masterSolutionReportCategory',
      context: context);

  @override
  ObservableList<MasterSolutionReportsModel?> get masterSolutionReportCategory {
    _$masterSolutionReportCategoryAtom.reportRead();
    return super.masterSolutionReportCategory;
  }

  @override
  set masterSolutionReportCategory(
      ObservableList<MasterSolutionReportsModel?> value) {
    _$masterSolutionReportCategoryAtom
        .reportWrite(value, super.masterSolutionReportCategory, () {
      super.masterSolutionReportCategory = value;
    });
  }

  late final _$meritListAtom =
      Atom(name: '_ReportsCategoryStore.meritList', context: context);

  @override
  ObservableList<MeritListModel?> get meritList {
    _$meritListAtom.reportRead();
    return super.meritList;
  }

  @override
  set meritList(ObservableList<MeritListModel?> value) {
    _$meritListAtom.reportWrite(value, super.meritList, () {
      super.meritList = value;
    });
  }

  late final _$meritMasterListAtom =
      Atom(name: '_ReportsCategoryStore.meritMasterList', context: context);

  @override
  ObservableList<MeritListModel?> get meritMasterList {
    _$meritMasterListAtom.reportRead();
    return super.meritMasterList;
  }

  @override
  set meritMasterList(ObservableList<MeritListModel?> value) {
    _$meritMasterListAtom.reportWrite(value, super.meritMasterList, () {
      super.meritMasterList = value;
    });
  }

  late final _$predictiveAtom =
      Atom(name: '_ReportsCategoryStore.predictive', context: context);

  @override
  Observable<Map<String, dynamic>?> get predictive {
    _$predictiveAtom.reportRead();
    return super.predictive;
  }

  @override
  set predictive(Observable<Map<String, dynamic>?> value) {
    _$predictiveAtom.reportWrite(value, super.predictive, () {
      super.predictive = value;
    });
  }

  late final _$rankPredictiveAtom =
      Atom(name: '_ReportsCategoryStore.rankPredictive', context: context);

  @override
  Observable<Map<String, dynamic>?> get rankPredictive {
    _$rankPredictiveAtom.reportRead();
    return super.rankPredictive;
  }

  @override
  set rankPredictive(Observable<Map<String, dynamic>?> value) {
    _$rankPredictiveAtom.reportWrite(value, super.rankPredictive, () {
      super.rankPredictive = value;
    });
  }

  late final _$reportByExamAtom =
      Atom(name: '_ReportsCategoryStore.reportByExam', context: context);

  @override
  ObservableList<ReportByExamListModel?> get reportByExam {
    _$reportByExamAtom.reportRead();
    return super.reportByExam;
  }

  @override
  set reportByExam(ObservableList<ReportByExamListModel?> value) {
    _$reportByExamAtom.reportWrite(value, super.reportByExam, () {
      super.reportByExam = value;
    });
  }

  late final _$masterReportByExamAtom =
      Atom(name: '_ReportsCategoryStore.masterReportByExam', context: context);

  @override
  ObservableList<ReportByExamListModel?> get masterReportByExam {
    _$masterReportByExamAtom.reportRead();
    return super.masterReportByExam;
  }

  @override
  set masterReportByExam(ObservableList<ReportByExamListModel?> value) {
    _$masterReportByExamAtom.reportWrite(value, super.masterReportByExam, () {
      super.masterReportByExam = value;
    });
  }

  late final _$reportsAllAtom =
      Atom(name: '_ReportsCategoryStore.reportsAll', context: context);

  @override
  ObservableList<ReportListModel?> get reportsAll {
    _$reportsAllAtom.reportRead();
    return super.reportsAll;
  }

  @override
  set reportsAll(ObservableList<ReportListModel?> value) {
    _$reportsAllAtom.reportWrite(value, super.reportsAll, () {
      super.reportsAll = value;
    });
  }

  late final _$scoreAtom =
      Atom(name: '_ReportsCategoryStore.score', context: context);

  @override
  ObservableList<Map<String, dynamic>> get score {
    _$scoreAtom.reportRead();
    return super.score;
  }

  @override
  set score(ObservableList<Map<String, dynamic>> value) {
    _$scoreAtom.reportWrite(value, super.score, () {
      super.score = value;
    });
  }

  late final _$updateBookMarkAtom =
      Atom(name: '_ReportsCategoryStore.updateBookMark', context: context);

  @override
  Observable<UpdateBookMarkModel?> get updateBookMark {
    _$updateBookMarkAtom.reportRead();
    return super.updateBookMark;
  }

  @override
  set updateBookMark(Observable<UpdateBookMarkModel?> value) {
    _$updateBookMarkAtom.reportWrite(value, super.updateBookMark, () {
      super.updateBookMark = value;
    });
  }

  late final _$addQueryAtom =
      Atom(name: '_ReportsCategoryStore.addQuery', context: context);

  @override
  Observable<CreateQuerySolutionReportModel?> get addQuery {
    _$addQueryAtom.reportRead();
    return super.addQuery;
  }

  @override
  set addQuery(Observable<CreateQuerySolutionReportModel?> value) {
    _$addQueryAtom.reportWrite(value, super.addQuery, () {
      super.addQuery = value;
    });
  }

  late final _$addMockQueryAtom =
      Atom(name: '_ReportsCategoryStore.addMockQuery', context: context);

  @override
  Observable<CreateQueryMockModel?> get addMockQuery {
    _$addMockQueryAtom.reportRead();
    return super.addMockQuery;
  }

  @override
  set addMockQuery(Observable<CreateQueryMockModel?> value) {
    _$addMockQueryAtom.reportWrite(value, super.addMockQuery, () {
      super.addMockQuery = value;
    });
  }

  late final _$addCustomTestQueryAtom =
      Atom(name: '_ReportsCategoryStore.addCustomTestQuery', context: context);

  @override
  Observable<CreateCustomTestQueryModel?> get addCustomTestQuery {
    _$addCustomTestQueryAtom.reportRead();
    return super.addCustomTestQuery;
  }

  @override
  set addCustomTestQuery(Observable<CreateCustomTestQueryModel?> value) {
    _$addCustomTestQueryAtom.reportWrite(value, super.addCustomTestQuery, () {
      super.addCustomTestQuery = value;
    });
  }

  late final _$addQuizQueryAtom =
      Atom(name: '_ReportsCategoryStore.addQuizQuery', context: context);

  @override
  Observable<CreateQuizQueryModel?> get addQuizQuery {
    _$addQuizQueryAtom.reportRead();
    return super.addQuizQuery;
  }

  @override
  set addQuizQuery(Observable<CreateQuizQueryModel?> value) {
    _$addQuizQueryAtom.reportWrite(value, super.addQuizQuery, () {
      super.addQuizQuery = value;
    });
  }

  late final _$bookmarkCategoryAtom =
      Atom(name: '_ReportsCategoryStore.bookmarkCategory', context: context);

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

  late final _$getExplanationTextAtom =
      Atom(name: '_ReportsCategoryStore.getExplanationText', context: context);

  @override
  Observable<GetExplanationModel?> get getExplanationText {
    _$getExplanationTextAtom.reportRead();
    return super.getExplanationText;
  }

  @override
  set getExplanationText(Observable<GetExplanationModel?> value) {
    _$getExplanationTextAtom.reportWrite(value, super.getExplanationText, () {
      super.getExplanationText = value;
    });
  }

  late final _$createAskQuestionDataAtom = Atom(
      name: '_ReportsCategoryStore.createAskQuestionData', context: context);

  @override
  Observable<AskQuestionModel?> get createAskQuestionData {
    _$createAskQuestionDataAtom.reportRead();
    return super.createAskQuestionData;
  }

  @override
  set createAskQuestionData(Observable<AskQuestionModel?> value) {
    _$createAskQuestionDataAtom.reportWrite(value, super.createAskQuestionData,
        () {
      super.createAskQuestionData = value;
    });
  }

  late final _$userScoreAtom =
      Atom(name: '_ReportsCategoryStore.userScore', context: context);

  @override
  Observable<List<UserScore>?> get userScore {
    _$userScoreAtom.reportRead();
    return super.userScore;
  }

  @override
  set userScore(Observable<List<UserScore>?> value) {
    _$userScoreAtom.reportWrite(value, super.userScore, () {
      super.userScore = value;
    });
  }

  late final _$getAllChatBotDataAtom =
      Atom(name: '_ReportsCategoryStore.getAllChatBotData', context: context);

  @override
  ObservableList<AskQuestionModel?> get getAllChatBotData {
    _$getAllChatBotDataAtom.reportRead();
    return super.getAllChatBotData;
  }

  @override
  set getAllChatBotData(ObservableList<AskQuestionModel?> value) {
    _$getAllChatBotDataAtom.reportWrite(value, super.getAllChatBotData, () {
      super.getAllChatBotData = value;
    });
  }

  late final _$bookmarkMasterCategoryAtom = Atom(
      name: '_ReportsCategoryStore.bookmarkMasterCategory', context: context);

  @override
  ObservableList<BookMarkCategoryModel?> get bookmarkMasterCategory {
    _$bookmarkMasterCategoryAtom.reportRead();
    return super.bookmarkMasterCategory;
  }

  @override
  set bookmarkMasterCategory(ObservableList<BookMarkCategoryModel?> value) {
    _$bookmarkMasterCategoryAtom
        .reportWrite(value, super.bookmarkMasterCategory, () {
      super.bookmarkMasterCategory = value;
    });
  }

  late final _$bookmarkSubCategoryAtom =
      Atom(name: '_ReportsCategoryStore.bookmarkSubCategory', context: context);

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
      Atom(name: '_ReportsCategoryStore.bookmarkTopic', context: context);

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

  late final _$notesDataAtom =
      Atom(name: '_ReportsCategoryStore.notesData', context: context);

  @override
  Observable<GetNotesSolutionModel?> get notesData {
    _$notesDataAtom.reportRead();
    return super.notesData;
  }

  @override
  set notesData(Observable<GetNotesSolutionModel?> value) {
    _$notesDataAtom.reportWrite(value, super.notesData, () {
      super.notesData = value;
    });
  }

  late final _$myRankAtom =
      Atom(name: '_ReportsCategoryStore.myRank', context: context);

  @override
  Observable<UserScore?> get myRank {
    _$myRankAtom.reportRead();
    return super.myRank;
  }

  @override
  set myRank(Observable<UserScore?> value) {
    _$myRankAtom.reportWrite(value, super.myRank, () {
      super.myRank = value;
    });
  }

  late final _$onUserScoreApiCallAsyncAction =
      AsyncAction('_ReportsCategoryStore.onUserScoreApiCall', context: context);

  @override
  Future<void> onUserScoreApiCall(String examId) {
    return _$onUserScoreApiCallAsyncAction
        .run(() => super.onUserScoreApiCall(examId));
  }

  late final _$_ReportsCategoryStoreActionController =
      ActionController(name: '_ReportsCategoryStore', context: context);

  @override
  void _setNotesDetails(GetNotesSolutionModel value) {
    final _$actionInfo = _$_ReportsCategoryStoreActionController.startAction(
        name: '_ReportsCategoryStore._setNotesDetails');
    try {
      return super._setNotesDetails(value);
    } finally {
      _$_ReportsCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _getExplanationDetails(GetExplanationModel value) {
    final _$actionInfo = _$_ReportsCategoryStoreActionController.startAction(
        name: '_ReportsCategoryStore._getExplanationDetails');
    try {
      return super._getExplanationDetails(value);
    } finally {
      _$_ReportsCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _createAllAskQuestion(AskQuestionModel value) {
    final _$actionInfo = _$_ReportsCategoryStoreActionController.startAction(
        name: '_ReportsCategoryStore._createAllAskQuestion');
    try {
      return super._createAllAskQuestion(value);
    } finally {
      _$_ReportsCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
reportscategory: ${reportscategory},
customtestreportscategory: ${customtestreportscategory},
reportbytopicname: ${reportbytopicname},
reportbytopicstreght: ${reportbytopicstreght},
trendList: ${trendList},
masterreportscategory: ${masterreportscategory},
examReport: ${examReport},
solutionReportCategory: ${solutionReportCategory},
quizSolutionReportCategory: ${quizSolutionReportCategory},
customTestSolutionReportCategory: ${customTestSolutionReportCategory},
masterSolutionReportCategory: ${masterSolutionReportCategory},
meritList: ${meritList},
meritMasterList: ${meritMasterList},
predictive: ${predictive},
rankPredictive: ${rankPredictive},
reportByExam: ${reportByExam},
masterReportByExam: ${masterReportByExam},
reportsAll: ${reportsAll},
score: ${score},
updateBookMark: ${updateBookMark},
addQuery: ${addQuery},
addMockQuery: ${addMockQuery},
addCustomTestQuery: ${addCustomTestQuery},
addQuizQuery: ${addQuizQuery},
bookmarkCategory: ${bookmarkCategory},
getExplanationText: ${getExplanationText},
createAskQuestionData: ${createAskQuestionData},
userScore: ${userScore},
getAllChatBotData: ${getAllChatBotData},
bookmarkMasterCategory: ${bookmarkMasterCategory},
bookmarkSubCategory: ${bookmarkSubCategory},
bookmarkTopic: ${bookmarkTopic},
notesData: ${notesData},
myRank: ${myRank}
    ''';
  }
}
