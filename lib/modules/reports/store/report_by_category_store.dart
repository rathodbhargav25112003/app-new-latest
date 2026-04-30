import 'dart:developer';
import 'package:mobx/mobx.dart';
import '../../../helpers/colors.dart';
import 'package:flutter/cupertino.dart';
import '../../widgets/bottom_toast.dart';
import '../../../models/strength_model.dart';
import '../../../api_service/api_service.dart';
import '../../../models/merit_list_model.dart';
import '../../../models/report_list_model.dart';
import '../../../models/ask_question_model.dart';
import '../../../models/bookmark_topic_model.dart';
import '../../../models/get_explanation_model.dart';
import 'package:shusruta_lms/models/user_score.dart';
import '../../../models/solution_reports_model.dart';
import 'package:shusruta_lms/models/exam_report.dart';
import '../../../models/bookmark_category_model.dart';
import '../../../models/create_query_mock_model.dart';
import '../../../models/get_notes_solution_model.dart';
import '../../../models/report_by_category_model.dart';
import '../../../models/report_by_exam_list_model.dart';
import '../../../models/bookmark_subcategory_model.dart';
import '../../quiztest/model/create_quiz_query_model.dart';
import '../../../models/master_solution_reports_model.dart';
import '../../../models/get_report_by_topic_name_model.dart';
import '../../../models/update_bookmark_question_model.dart';
import 'package:shusruta_lms/models/trend_analysis_model.dart';
import '../../quiztest/model/quiz_solution_reports_model.dart';
import '../../../models/create_query_solution_report_model.dart';
import '../../customtests/model/create_custom_test_query_model.dart';
import '../../customtests/model/custom_test_solution_reports_model.dart';
import '../../customtests/model/custom_test_report_by_category_model.dart';
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';
import 'package:shusruta_lms/modules/customtests/model/create_custom_test_model.dart';

part 'report_by_category_store.g.dart';

class ReportsCategoryStore = _ReportsCategoryStore with _$ReportsCategoryStore;

abstract class _ReportsCategoryStore extends InternetStore with Store {
  final ApiService _apiService = ApiService();

  @observable
  bool isLoading = false;

  @observable
  ObservableList<ReportByCategoryModel?> reportscategory =
      ObservableList<ReportByCategoryModel>();

  @observable
  ObservableList<CustomTestReportByCategoryModel?> customtestreportscategory =
      ObservableList<CustomTestReportByCategoryModel>();

  @observable
  ObservableList<ReportByTopicNameModel?> reportbytopicname =
      ObservableList<ReportByTopicNameModel>();
  @observable
  ObservableList<ReportSrengthModel?> reportbytopicstreght =
      ObservableList<ReportSrengthModel?>();

  @observable
  Observable<List<TrendAnalysisModel>?> trendList =
      Observable<List<TrendAnalysisModel>?>([]);

  @observable
  ObservableList<ReportByCategoryModel?> masterreportscategory =
      ObservableList<ReportByCategoryModel>();

  @observable
  Observable<ExamReport?> examReport = Observable<ExamReport?>(null);

  @observable
  ObservableList<SolutionReportsModel?> solutionReportCategory =
      ObservableList<SolutionReportsModel>();

  @observable
  ObservableList<QuizSolutionReportsModel?> quizSolutionReportCategory =
      ObservableList<QuizSolutionReportsModel>();

  @observable
  ObservableList<CustomTestSolutionReportsModel?>
      customTestSolutionReportCategory =
      ObservableList<CustomTestSolutionReportsModel>();

  @observable
  ObservableList<MasterSolutionReportsModel?> masterSolutionReportCategory =
      ObservableList<MasterSolutionReportsModel>();

  @observable
  ObservableList<MeritListModel?> meritList = ObservableList<MeritListModel>();

  @observable
  ObservableList<MeritListModel?> meritMasterList =
      ObservableList<MeritListModel>();

  @observable
  Observable<Map<String, dynamic>?> predictive =
      Observable<Map<String, dynamic>>({});

  @observable
  Observable<Map<String, dynamic>?> rankPredictive =
      Observable<Map<String, dynamic>>({});

  @observable
  ObservableList<ReportByExamListModel?> reportByExam =
      ObservableList<ReportByExamListModel>();

  @observable
  ObservableList<ReportByExamListModel?> masterReportByExam =
      ObservableList<ReportByExamListModel>();

  @observable
  ObservableList<ReportListModel?> reportsAll =
      ObservableList<ReportListModel>();

  @observable
  ObservableList<Map<String, dynamic>> score =
      ObservableList<Map<String, dynamic>>();

  @observable
  Observable<UpdateBookMarkModel?> updateBookMark =
      Observable<UpdateBookMarkModel?>(null);

  @observable
  Observable<CreateQuerySolutionReportModel?> addQuery =
      Observable<CreateQuerySolutionReportModel?>(null);

  @observable
  Observable<CreateQueryMockModel?> addMockQuery =
      Observable<CreateQueryMockModel?>(null);

  @observable
  Observable<CreateCustomTestQueryModel?> addCustomTestQuery =
      Observable<CreateCustomTestQueryModel?>(null);

  @observable
  Observable<CreateQuizQueryModel?> addQuizQuery =
      Observable<CreateQuizQueryModel?>(null);

  @observable
  ObservableList<BookMarkCategoryModel?> bookmarkCategory =
      ObservableList<BookMarkCategoryModel>();

  @observable
  Observable<GetExplanationModel?> getExplanationText =
      Observable<GetExplanationModel?>(null);

  @observable
  Observable<AskQuestionModel?> createAskQuestionData =
      Observable<AskQuestionModel?>(null);

  @observable
  Observable<List<UserScore>?> userScore = Observable<List<UserScore>?>([]);

  @observable
  ObservableList<AskQuestionModel?> getAllChatBotData =
      ObservableList<AskQuestionModel>();

  @observable
  ObservableList<BookMarkCategoryModel?> bookmarkMasterCategory =
      ObservableList<BookMarkCategoryModel>();

  @observable
  ObservableList<BookMarkSubCategoryModel?> bookmarkSubCategory =
      ObservableList<BookMarkSubCategoryModel>();

  @observable
  ObservableList<BookMarkTopicModel?> bookmarkTopic =
      ObservableList<BookMarkTopicModel>();

  @observable
  Observable<GetNotesSolutionModel?> notesData =
      Observable<GetNotesSolutionModel?>(null);

  @observable
  Observable<UserScore?> myRank = Observable<UserScore?>(null);

  //reports for all

  // Future<void> onReportByCategoryApiCall(String id, String? type) async {
  //   isLoading = true;
  //
  //   try {
  //     final List<ReportByCategoryModel> result = await _apiService.reportsListByType(id,type);
  //     reportscategory.clear();
  //     result.sort((a, b) => b.isAttemptcount?.compareTo(a.isAttemptcount??0)??0);
  //     reportscategory.addAll(result);
  //   } catch (e) {
  //     debugPrint('Error fetching subscription: $e');
  //     reportscategory.clear();
  //   } finally {
  //     isLoading = false;
  //   }
  // }

  //report list

  Future<void> onReportCategoryApiCall(BuildContext context) async {
    isLoading = true;

    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    try {
      final List<BookMarkCategoryModel> result =
          await _apiService.reportCategoryList();
      bookmarkCategory.clear();
      bookmarkCategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching test: $e');
      bookmarkCategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetExplanationCall(String prompt) async {
    await checkConnectionStatus();
    // isLoading = true;
    try {
      final GetExplanationModel result =
          await _apiService.getExplanation(prompt);
      await Future.delayed(const Duration(milliseconds: 1));
      _getExplanationDetails(result);
    } catch (e) {
      debugPrint('Error fetching videoctopic detail: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCreateAskQuestion(String question, String answer) async {
    await checkConnectionStatus();
    isLoading = true;
    try {
      final AskQuestionModel result =
          await _apiService.createChatBotQuestion(question, answer);
      await Future.delayed(const Duration(milliseconds: 1));
      _createAllAskQuestion(result);
    } catch (e) {
      debugPrint('Error creating askQuestion detail: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetAllAskQuestion(BuildContext context) async {
    isLoading = true;

    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    try {
      final List<AskQuestionModel> result =
          await _apiService.getAllAskQuestion();
      getAllChatBotData.clear();
      getAllChatBotData.addAll(result);
    } catch (e) {
      debugPrint('Error fetching test: $e');
      getAllChatBotData.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onDeleteAllAskQuestion(BuildContext context) async {
    await checkConnectionStatus();
    if (!isConnected) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "No Internet Connection!",
        backgroundColor: ThemeManager.redAlert,
      );
      return;
    }

    isLoading = true;

    try {
      final result = await _apiService.deleteAllAskQuestion();
      debugPrint('result');
    } catch (e) {
      debugPrint('Error deleting bookmark: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onMasterReportCategoryApiCall(BuildContext context) async {
    isLoading = true;

    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    try {
      final List<BookMarkCategoryModel> result =
          await _apiService.masterReportCategoryList();
      bookmarkMasterCategory.clear();
      bookmarkMasterCategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching test: $e');
      bookmarkMasterCategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onReportSubCategoryApiCall(String catid) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<BookMarkSubCategoryModel> result =
          await _apiService.reportSubCategoryList(catid);
      bookmarkSubCategory.clear();
      bookmarkSubCategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      bookmarkSubCategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onReportTopicApiCall(String subCatId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<BookMarkTopicModel> result =
          await _apiService.reportTopicList(subCatId);
      bookmarkTopic.clear();
      bookmarkTopic.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      bookmarkTopic.clear();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> onUserScoreApiCall(String examId) async {
    await checkConnectionStatus();
    myRank.value = null;
    isLoading = true;
    try {
      final List<UserScore> result = await _apiService.getUserScoreById(examId);

      final UserScore defaultRanker = UserScore(
        totalMarks: 0,
        score: 0,
        rank: 0,
        fullname: "No Rank",
        correct: 0,
        time: "00:00:00",
        inCorrect: 0,
        skipped: 0,
        isAttemptcount: 0,
        isMyRank: false,
      );

      List<UserScore> display = [];

      myRank.value = result.firstWhere(
        (ranker) => ranker.isMyRank,
        orElse: () => defaultRanker, // Return the default Ranker if not found
      );
      display.addAll(result);
      userScore.value = display;
    } catch (e) {
      debugPrint('Error fetching ranks: $e');
      bookmarkTopic.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onReportAllApiCall() async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<ReportListModel> result = await _apiService.reportsListAll();
      reportsAll.clear();
      reportsAll.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      reportsAll.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onReportByCategoryApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<ReportByCategoryModel> result =
          await _apiService.reportsListByType(id);
      reportscategory.clear();
      result.sort(
          (a, b) => b.isAttemptcount?.compareTo(a.isAttemptcount ?? 0) ?? 0);
      reportscategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      reportscategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCustomTestReportByCategoryApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<CustomTestReportByCategoryModel> result =
          await _apiService.customTestReportsByCategory(id);
      customtestreportscategory.clear();
      result.sort(
          (a, b) => b.isAttemptcount?.compareTo(a.isAttemptcount ?? 0) ?? 0);
      customtestreportscategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      customtestreportscategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onReportByTopicNameApiCall(String id, String mark) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<ReportByTopicNameModel> result =
          await _apiService.reportsListByTopicName(id);
      print(mark);
      final Map<String, dynamic> result1 =
          await _apiService.getNeetPrediction(mark);
      log(result1.toString());
      predictive.value = result1;
      reportbytopicname.clear();
      reportbytopicname.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      reportbytopicname.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onReportByTopicStengthApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final ReportSrengthModel result =
          await _apiService.reportsListByStregthTopicName(id);
      reportbytopicstreght.clear();
      reportbytopicstreght.add(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      reportbytopicstreght.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCallGetTrendAnalysis(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<TrendAnalysisModel> result =
          await _apiService.getTrendAnalysis(id);
      // await getScore(result);
      trendList.value!.clear();
      trendList.value!.addAll(result);
    } catch (e) {
      debugPrint('Error fetching onCallGetTrendAnalysis: $e');
      trendList.value!.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> getScore(List<TrendAnalysisModel> data) async {
    score.clear();
    final ApiService apiService = ApiService();
    for (var i = 0; i < data.length; i++) {
      final Map<String, dynamic> result =
          await apiService.getNeetPrediction(data[i].mymark.toString());
      score.add(result);
    }
    return;
  }

  // Future<void> onReportByTopicStengthApiCall(String id) async {
  //   await checkConnectionStatus();
  //   if (!isConnected) {
  //     return;
  //   }
  //
  //   isLoading = true;
  //   try {
  //     final List<ReportSrengthModel> result = await _apiService.reportsListByStregthTopicName(id);
  //     reportbytopicname.clear();
  //     reportbytopicname.addAll(result);
  //   } catch (e) {
  //     debugPrint('Error fetching subscription: $e');
  //     reportbytopicname.clear();
  //   } finally {
  //     isLoading = false;
  //   }
  // }
  Future<void> onMasterReportByCategoryApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<ReportByCategoryModel> result =
          await _apiService.masterReportsListByType(id);
      masterreportscategory.clear();
      result.sort(
          (a, b) => b.isAttemptcount?.compareTo(a.isAttemptcount ?? 0) ?? 0);
      masterreportscategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      masterreportscategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onReportExamByCategoryApiCall(String id, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<ReportByExamListModel> result =
          await _apiService.reportExamByCategoryList(id, type);
      reportByExam.clear();
      reportByExam.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      reportByExam.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onMasterReportExamByCategoryApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<ReportByExamListModel> result =
          await _apiService.masterReportExamByCategoryList(id);
      masterReportByExam.clear();
      masterReportByExam.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      masterReportByExam.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onSolutionReportApiCall(String id, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<SolutionReportsModel> result =
          await _apiService.solutionReportByExam(id, type);
      solutionReportCategory.clear();
      solutionReportCategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching solutionreport: $e');
      solutionReportCategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onQuizSolutionReportApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<QuizSolutionReportsModel> result =
          await _apiService.solutionReportByQuizExam(id);
      quizSolutionReportCategory.clear();
      quizSolutionReportCategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching solutionreport: $e');
      quizSolutionReportCategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCustomTestSolutionReportApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<CustomTestSolutionReportsModel> result =
          await _apiService.solutionReportByCustomTestExam(id);
      customTestSolutionReportCategory.clear();
      customTestSolutionReportCategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching solutionreport: $e');
      customTestSolutionReportCategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onMasterSolutionReportApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<MasterSolutionReportsModel> result =
          await _apiService.solutionReportByMasterExam(id);
      masterSolutionReportCategory.clear();
      masterSolutionReportCategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching solutionreport: $e');
      masterSolutionReportCategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onMeritListApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<MeritListModel> result = await _apiService.meritListByExam(id);
      meritList.clear();
      meritList.addAll(result);
    } catch (e) {
      debugPrint('Error fetching meritlist: $e');
      meritList.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onMasterMeritListApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<MeritListModel> result =
          await _apiService.meritListByMasterExam(id);
      meritMasterList.clear();
      meritMasterList.addAll(result);
    } catch (e) {
      debugPrint('Error fetching meritlist: $e');
      meritMasterList.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> compareWithRank1(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final result = await _apiService.compareWithRank1(id);
      rankPredictive.value =
          await _apiService.getNeetPrediction(result.mymark.toString());
      examReport.value = result;
    } catch (e) {
      debugPrint('Error fetching meritlist: $e');
      meritMasterList.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onBookMarkQuestion(BuildContext context, bool isBookMarked,
      String examId, String questionId, String? bookMarkNote) async {
    await checkConnectionStatus();
    if (!isConnected) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "No Internet Connection!",
        backgroundColor: ThemeManager.redAlert,
      );
      return;
    }

    try {
      final UpdateBookMarkModel result = await _apiService.bookMarkQuestion(
          isBookMarked, examId, questionId, bookMarkNote);
      updateBookMark.value = result;
    } catch (e) {
      debugPrint('Error updating bookmark: $e');
    } finally {}
  }

  Future<void> onDeleteBookMarkQuestion(
      BuildContext context, String bookMarkId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "No Internet Connection!",
        backgroundColor: ThemeManager.redAlert,
      );
      return;
    }

    isLoading = true;

    try {
      final result = await _apiService.deleteBookMarkQuestions(bookMarkId);
      debugPrint('result');
    } catch (e) {
      debugPrint('Error deleting bookmark: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCreateQuerySolutionReport(
    BuildContext context,
    String questionId,
    String queryTxt,
    bool incorrectQues,
    bool incorrectAns,
    bool explanationIssue,
    bool otherIssue,
    bool wrongImg,
    bool imgNotClear,
    bool spelingError,
    bool explainQueNotMatch,
    bool explainAnsNotMatch,
    bool queAnsOptionNotMatch,
  ) async {
    await checkConnectionStatus();
    if (!isConnected) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "No Internet Connection!",
        backgroundColor: ThemeManager.redAlert,
      );
      return;
    }

    isLoading = true;
    try {
      final CreateQuerySolutionReportModel result =
          await _apiService.createQuery(
        questionId,
        queryTxt,
        incorrectQues,
        incorrectAns,
        explanationIssue,
        otherIssue,
        wrongImg,
        imgNotClear,
        spelingError,
        explainQueNotMatch,
        explainAnsNotMatch,
        queAnsOptionNotMatch,
      );
      addQuery.value = result;
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCreateQueryMock(
      BuildContext context,
      String questionId,
      String queryTxt,
      bool incorrectQues,
      bool incorrectAns,
      bool explanationIssue,
      bool otherIssue) async {
    await checkConnectionStatus();
    if (!isConnected) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "No Internet Connection!",
        backgroundColor: ThemeManager.redAlert,
      );
      return;
    }

    isLoading = true;
    try {
      final CreateQueryMockModel result = await _apiService.createMockQuery(
          questionId,
          queryTxt,
          incorrectQues,
          incorrectAns,
          explanationIssue,
          otherIssue);
      addMockQuery.value = result;
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCreateQueryCustomTest(
      BuildContext context,
      String questionId,
      String queryTxt,
      bool incorrectQues,
      bool incorrectAns,
      bool explanationIssue,
      bool otherIssue) async {
    await checkConnectionStatus();
    if (!isConnected) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "No Internet Connection!",
        backgroundColor: ThemeManager.redAlert,
      );
      return;
    }

    isLoading = true;
    try {
      final CreateCustomTestQueryModel result =
          await _apiService.createQueryCustomTest(questionId, queryTxt,
              incorrectQues, incorrectAns, explanationIssue, otherIssue);
      addCustomTestQuery.value = result;
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCreateQueryQuiz(
      BuildContext context,
      String questionId,
      String queryTxt,
      bool incorrectQues,
      bool incorrectAns,
      bool explanationIssue,
      bool otherIssue) async {
    await checkConnectionStatus();
    if (!isConnected) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "No Internet Connection!",
        backgroundColor: ThemeManager.redAlert,
      );
      return;
    }

    isLoading = true;
    try {
      final CreateQuizQueryModel result = await _apiService.createQueryQuiz(
          questionId,
          queryTxt,
          incorrectQues,
          incorrectAns,
          explanationIssue,
          otherIssue);
      addQuizQuery.value = result;
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCreateNotes(
      BuildContext context, String queId, String notes) async {
    await checkConnectionStatus();
    if (!isConnected) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "No Internet Connection!",
        backgroundColor: ThemeManager.redAlert,
      );
      return;
    }

    isLoading = true;

    try {
      final result = await _apiService.onCreateNotes(queId, notes);
      debugPrint('result');
    } catch (e) {
      debugPrint('Error adding notes: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetNotesData(String queId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final GetNotesSolutionModel result =
          await _apiService.getNotesData(queId);
      await Future.delayed(const Duration(milliseconds: 1));
      _setNotesDetails(result);
    } catch (e) {
      debugPrint('Error getting notes: $e');
    } finally {
      isLoading = false;
    }
  }

  @action
  void _setNotesDetails(GetNotesSolutionModel value) {
    notesData.value = value;
  }

  @action
  void _getExplanationDetails(GetExplanationModel value) {
    getExplanationText.value = value;
  }

  @action
  void _createAllAskQuestion(AskQuestionModel value) {
    createAskQuestionData.value = value;
  }
}
