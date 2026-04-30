import 'dart:async';
import 'dart:developer';
import 'package:mobx/mobx.dart';
import '../../../app/routes.dart';
import 'package:flutter/cupertino.dart';
import '../../quiztest/model/quiz_model.dart';
import '../../../api_service/api_service.dart';
import '../../../models/test_topic_model.dart';
import '../../../models/create_exam_model.dart';
import '../../../models/searched_data_model.dart';
import '../../../models/test_category_model.dart';
import '../../../models/practice_count_model.dart';
import '../../../models/exam_paper_data_model.dart';
import '../../../models/question_pallete_model.dart';
import '../../../models/test_subcategory_model.dart';
import '../../../models/user_exam_answer_model.dart';
import 'package:shusruta_lms/models/exam_report.dart';
import '../../../models/report_by_category_model.dart';
import '../../../models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/models/mock_analysis.dart';
import 'package:shusruta_lms/models/mcq_exam_data.dart';
import '../../../models/report_practice_count_model.dart';
import '../../quiztest/model/create_quiz_exam_model.dart';
import '../../quiztest/model/quiz_exam_answer_model.dart';
import 'package:shusruta_lms/models/exam_attempts_model.dart';
import '../../quiztest/model/quiz_exam_paper_data_model.dart';
import 'package:shusruta_lms/modules/test/test_mode_card.dart';
import '../../customtests/model/create_custom_exam_model.dart';
import '../../quiztest/model/quiz_question_pallete_model.dart';
import '../../quiztest/model/quiz_report_by_category_model.dart';
import '../../customtests/model/custom_exam_paper_data_model.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import '../../customtests/model/custom_question_pallete_model.dart';
import '../../customtests/model/user_custom_exam_answer_model.dart';
import '../../quiztest/model/quiz_question_pallete_count_model.dart';
import 'package:shusruta_lms/models/question_pallete_count_model.dart';
import '../../customtests/model/custom_test_report_by_category_model.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart' as test;
import '../../customtests/model/custom_test_question_pallete_count_model.dart';
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';
import '../../masterTest/sectionwisemasterTest/model/get_section_list_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/model/exam_ans_model.dart';
import '../../masterTest/sectionwisemasterTest/model/create_section_exam_model.dart';
import '../../masterTest/sectionwisemasterTest/model/section_exam_paper_data_model.dart';
import '../../masterTest/sectionwisemasterTest/model/section_question_pallete_model.dart';
import '../../masterTest/sectionwisemasterTest/model/all_section_pallete_count_model.dart';
import '../../masterTest/sectionwisemasterTest/model/section_question_pallete_count_model.dart';
//import 'dart:ffi';

// except all q and book mark share main user exma id

part 'test_category_store.g.dart';

class TestCategoryStore = _TestCategoryStore with _$TestCategoryStore;

abstract class _TestCategoryStore extends InternetStore with Store {
  final ApiService _apiService = ApiService();

  @observable
  bool isLoading = false;

  @observable
  bool isSheet = false;

  @observable
  bool isLoadingCountLoading = false;
  @observable
  String? userExamId;

  @observable
  List<TestCategoryModel> testcategory = [];

  @observable
  List<TestCategoryModel> filtterTestcategory = [];

  @observable
  List<TestSubCategoryModel> filtterTestSubcategory = [];

  @observable
  ObservableList<TestCategoryModel?> customtestcategory =
      ObservableList<TestCategoryModel>();

  @observable
  ObservableList<TestCategoryModel?> alltestcategory =
      ObservableList<TestCategoryModel>();

  @observable
  ObservableList<TestCategoryModel?> alltestcategoryLeaderBoard =
      ObservableList<TestCategoryModel>();

  @observable
  List<TestSubCategoryModel> testsubcategory = [];

  @observable
  ObservableList<TestTopicModel?> testtopic = ObservableList<TestTopicModel>();

  @observable
  ObservableList<TestTopicModel?> filtterTestTopic =
      ObservableList<TestTopicModel>();

  @observable
  ObservableList<TestExamPaperListModel?> testexam =
      ObservableList<TestExamPaperListModel>();

  @observable
  ObservableList<TestExamPaperListModel?> filtterTestExam =
      ObservableList<TestExamPaperListModel>();

  @observable
  ObservableList<TestExamPaperListModel?> alltestexam =
      ObservableList<TestExamPaperListModel>();

  @observable
  ObservableList<ExamPaperDataModel?> examPaperData =
      ObservableList<ExamPaperDataModel>();

  @observable
  ObservableList<ExamPaperDataModel?> examPracticePaperData =
      ObservableList<ExamPaperDataModel>();

  @observable
  ObservableList<ExamPaperDataModel?> mockExamPracticePaperData =
      ObservableList<ExamPaperDataModel>();

  @observable
  ObservableList<ExamPaperDataModel?> customExamPracticePaperData =
      ObservableList<ExamPaperDataModel>();

  @observable
  ObservableList<CustomExamPaperDataModel?> customExamPaperData =
      ObservableList<CustomExamPaperDataModel>();

  @observable
  ObservableList<QuizExamPaperDataModel?> quizExamPaperData =
      ObservableList<QuizExamPaperDataModel>();

  @observable
  Observable<QuizModel?> getTodayQuizData = Observable<QuizModel?>(null);

  @observable
  Observable<PracticeCountModel?> getPracticeCountData =
      Observable<PracticeCountModel?>(null);

  @observable
  Observable<PracticeCountModel?> getMockPracticeCountData =
      Observable<PracticeCountModel?>(null);

  @observable
  Observable<PracticeCountModel?> getCustomPracticeCountData =
      Observable<PracticeCountModel?>(null);

  @observable
  Observable<ReportPracticeCountModel?> getReportPracticeCountData =
      Observable<ReportPracticeCountModel?>(null);

  @observable
  Observable<ReportPracticeCountModel?> getMockReportPracticeCountData =
      Observable<ReportPracticeCountModel?>(null);

  @observable
  Observable<ReportPracticeCountModel?> getCustomReportPracticeCountData =
      Observable<ReportPracticeCountModel?>(null);

  @observable
  ObservableList<ExamPaperDataModel?> materExamPaperData =
      ObservableList<ExamPaperDataModel>();

  @observable
  ObservableList<SectionExamPaperDataModel?> sectionExamPaperData =
      ObservableList<SectionExamPaperDataModel>();

  @observable
  ObservableList<GetSectionListModel?> getSectionList =
      ObservableList<GetSectionListModel>();

  @observable
  Observable<CreateExamModel?> startExam = Observable<CreateExamModel?>(null);

  @observable
  Observable<CreateQuizExamModel?> startQuizExam =
      Observable<CreateQuizExamModel?>(null);

  @observable
  Observable<CreateCustomExamModel?> startCustomExam =
      Observable<CreateCustomExamModel?>(null);

  @observable
  Observable<CreateExamModel?> startMasterExam =
      Observable<CreateExamModel?>(null);

  @observable
  Observable<CreateSectionExamModel?> startSectionMasterExam =
      Observable<CreateSectionExamModel?>(null);

  @observable
  Observable<UserExamAnswer?> userAnswerExam =
      Observable<UserExamAnswer?>(null);

  @observable
  Observable<ExamAttemptsModel?> examAttemptsModel =
      Observable<ExamAttemptsModel?>(null);

  @observable
  Observable<McqExamData?> mcqExamData = Observable<McqExamData?>(null);

  @observable
  Observable<QuizExamAnswer?> quizAnswerExam =
      Observable<QuizExamAnswer?>(null);

  @observable
  Observable<UserCustomExamAnswer?> userCustomAnswerExam =
      Observable<UserCustomExamAnswer?>(null);

  @observable
  Observable<UserExamAnswer?> userAnswerMasterExam =
      Observable<UserExamAnswer?>(null);

  @observable
  ObservableList<QuestionPalleteModel?> testQuePallete =
      ObservableList<QuestionPalleteModel>();

  @observable
  ObservableList<QuizQuestionPalleteModel?> quizQuePallete =
      ObservableList<QuizQuestionPalleteModel>();

  @observable
  ObservableList<CustomTestQuestionPalleteModel?> customTestQuePallete =
      ObservableList<CustomTestQuestionPalleteModel>();

  @observable
  ObservableList<QuestionPalleteModel?> masterTestQuePallete =
      ObservableList<QuestionPalleteModel>();

  @observable
  ObservableList<SectionQuestionPalleteModel?> sectionTestQuePallete =
      ObservableList<SectionQuestionPalleteModel>();

  @observable
  Observable<QuestionPalleteCountModel?> testQuePalleteCount =
      Observable<QuestionPalleteCountModel?>(null);

  @observable
  Observable<QuizQuestionPalleteCountModel?> quizTestQuePalleteCount =
      Observable<QuizQuestionPalleteCountModel?>(null);

  @observable
  Observable<CustomTestQuestionPalleteCountModel?> customTestQuePalleteCount =
      Observable<CustomTestQuestionPalleteCountModel?>(null);

  @observable
  Observable<QuestionPalleteCountModel?> testQueMasterPalleteCount =
      Observable<QuestionPalleteCountModel?>(null);

  @observable
  Observable<SectionQuestionPalleteCountModel?> sectionQueMasterPalleteCount =
      Observable<SectionQuestionPalleteCountModel?>(null);
  @observable
  ObservableList<AllSectionQuestionPalleteCountModel?>
      allSectionQueMasterPalleteCount =
      ObservableList<AllSectionQuestionPalleteCountModel>();

  @observable
  Observable<ReportByCategoryModel?> reportsExam =
      Observable<ReportByCategoryModel?>(null);

  @observable
  Observable<QuizReportByCategoryModel?> reportsQuizExam =
      Observable<QuizReportByCategoryModel?>(null);

  @observable
  Observable<CustomTestReportByCategoryModel?> reportsCustomTestExam =
      Observable<CustomTestReportByCategoryModel?>(null);

  @observable
  Observable<ReportByCategoryModel?> reportsMasterExam =
      Observable<ReportByCategoryModel?>(null);

  @observable
  ObservableList<SearchedDataModel?> searchList =
      ObservableList<SearchedDataModel>();

  @observable
  Observable<ExamReport?> examReport = Observable<ExamReport?>(null);

  @observable
  Observable<McqAnalysis?> mcqExamReport = Observable<McqAnalysis?>(null);

  @observable
  Observable<ExamReport?> examReport2 = Observable<ExamReport?>(null);

  @observable
  Observable<String> type = Observable<String>('McqExam');

  @observable
  bool isSubmitting = false;

  Timer? _timer; // Timer for the 2-minute interval
  static const int triggerInterval = 2 * 60; // 2 minutes in seconds

  @observable
  Observable<List<test.TestData>> qutestionList =
      Observable<List<test.TestData>>([]);

  @observable
  Observable<Map<String, dynamic>?> mcqExamCount =
      Observable<Map<String, dynamic>?>(null);

  @observable
  Observable<List<ExamAnsModel>> ansList = Observable<List<ExamAnsModel>>([]);

  void startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(Duration(seconds: triggerInterval), (timer) async {
      await triggerAction();
    });
  }

  Future<void> onTestApiCall(BuildContext context) async {
    isLoading = true;

    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }

    try {
      final List<TestCategoryModel> result =
          await _apiService.testCategoryList();
      testcategory.clear();
      filtterTestcategory.clear();
      testcategory.addAll(result);
      filtterTestcategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching test: $e');
      testcategory.clear();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> statusCategoryFilter(BuildContext context, String status) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }
    try {
      log(testcategory.length.toString());
      if (status == "All") {
        filtterTestcategory = ObservableList.of(testcategory);
      } else if (status == "Completed") {
        filtterTestcategory = ObservableList.of(
            testcategory.where((e) => e.isAttempt! && e.isCompleted!).toList());
      } else if (status == "Not Started") {
        filtterTestcategory = ObservableList.of(
            testcategory.where((e) => !e.isAttempt!).toList());
      } else if (status == "In Progress") {
        filtterTestcategory = ObservableList.of(testcategory
            .where((e) => e.isAttempt! && !e.isCompleted!)
            .toList());
      }

      log(filtterTestcategory.length.toString());
    } catch (e) {
      debugPrint('Error fetching test: $e');
    }
  }

  @action
  Future<void> statusTopicFilter(BuildContext context, String status) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }
    try {
      if (status == "All") {
        filtterTestTopic = ObservableList.of(testtopic);
      } else if (status == "Completed") {
        filtterTestTopic = ObservableList.of(
            testtopic.where((e) => e!.isAttempt! && e.isCompleted).toList());
      } else if (status == "Not Started") {
        filtterTestTopic =
            ObservableList.of(testtopic.where((e) => !e!.isAttempt!).toList());
      } else if (status == "In Progress") {
        filtterTestTopic = ObservableList.of(
            testtopic.where((e) => e!.isAttempt! && !e.isCompleted).toList());
      }
    } catch (e) {
      debugPrint('Error fetching test: $e');
    }
  }

  @action
  Future<void> statusTestExamFilter(BuildContext context, String status) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }
    try {
      if (status == "All") {
        filtterTestExam = ObservableList.of(testexam);
      } else if (status == "Completed") {
        filtterTestExam = ObservableList.of(
            testexam.where((e) => e!.isAttempt! && e.isCompleted!).toList());
      } else if (status == "Not Started") {
        filtterTestExam =
            ObservableList.of(testexam.where((e) => !e!.isAttempt!).toList());
      } else if (status == "In Progress") {
        filtterTestExam = ObservableList.of(
            testexam.where((e) => e!.isAttempt! && !e.isCompleted!).toList());
      }
    } catch (e) {
      debugPrint('Error fetching test: $e');
    }
  }

  @action
  Future<void> statusSubCategoryFilter(
      BuildContext context, String status) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }
    try {
      if (status == "All") {
        filtterTestSubcategory = ObservableList.of(testsubcategory);
      } else if (status == "Completed") {
        filtterTestSubcategory = ObservableList.of(testsubcategory
            .where((e) => e.isAttempt! && e.isCompleted)
            .toList());
      } else if (status == "Not Started") {
        filtterTestSubcategory = ObservableList.of(
            testsubcategory.where((e) => !e.isAttempt!).toList());
      } else if (status == "In Progress") {
        filtterTestSubcategory = ObservableList.of(testsubcategory
            .where((e) => e.isAttempt! && !e.isCompleted)
            .toList());
      }
    } catch (e) {
      debugPrint('Error fetching test: $e');
    }
  }

  Future<void> onCustomTestApiCall(BuildContext context) async {
    isLoading = true;

    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }

    try {
      final List<TestCategoryModel> result =
          await _apiService.customTestCategoryList();
      customtestcategory.clear();
      customtestcategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching test: $e');
      customtestcategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onAllTestApiCall(BuildContext context) async {
    isLoading = true;

    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }

    try {
      final List<TestCategoryModel> result =
          await _apiService.allTestCategoryList();
      alltestcategory.clear();
      alltestcategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching test: $e');
      alltestcategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCategoryMockExams(
      BuildContext context, bool neetSS, bool iniss) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }
    isLoading = true;
    try {
      final List<TestCategoryModel> result =
          await _apiService.cateWiseTestCategoryList(neetSS, iniss);
      alltestcategory.clear();
      alltestcategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching test: $e');
      alltestcategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> getLeaderBoardCategoryList(BuildContext context) async {
    isLoading = true;
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }
    try {
      final List<TestCategoryModel> result =
          await _apiService.getLeaderBoardCategoryList();
      alltestcategoryLeaderBoard.clear();
      alltestcategoryLeaderBoard.addAll(result);
    } catch (e) {
      debugPrint('Error fetching test: $e');
      alltestcategoryLeaderBoard.clear();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> saveChangeExaplanation(
      BuildContext context, Map<String, dynamic> data) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }
    try {
      final result = await _apiService.saveExplAnnotation(data);
      log("saveExplAnnotation:-${result.toString()}");
    } catch (e) {
      debugPrint('Error fetching test: $e');
      alltestcategoryLeaderBoard.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onSubCategoryApiCall(String testid) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<TestSubCategoryModel> result =
          await _apiService.testSubCategoryList(testid);
      testsubcategory.clear();
      filtterTestSubcategory.clear();
      testsubcategory.addAll(result);
      filtterTestSubcategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      testsubcategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<bool> onFreePlanApiCall(String planId, int day) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return false;
    }

    isLoading = true;
    try {
      final bool result = await _apiService.freePlanApiCall(planId, day);
      if (result) {
        log("onFreePlanApiCall:-Success");
      }
      return result;
    } catch (e) {
      debugPrint('Error onFreePlanApiCall: $e');
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<void> onTopicApiCall(String subCatId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<TestTopicModel> result =
          await _apiService.testTopicList(subCatId);
      testtopic.clear();
      filtterTestTopic.clear();
      testtopic.addAll(result);
      filtterTestTopic.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      testtopic.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onTestExamByCategoryApiCall(String id, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<TestExamPaperListModel> result =
          await _apiService.testExamByCategoryList(id, type);
      testexam.clear();
      testexam.addAll(result);
      filtterTestExam.clear();
      filtterTestExam.addAll(result);
    } catch (e) {
      debugPrint('Error fetching testlist: $e');
      testexam.clear();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> onAns(ExamAnsModel ans) async {
    final index =
        ansList.value.indexWhere((item) => item.questionId == ans.questionId);
    if (index != -1) {
      ExamAnsModel saveModel = ExamAnsModel(
          userExamId: ans.userExamId,
          questionId: ans.questionId,
          selectedOption: ans.selectedOption,
          attempted: ans.attempted,
          attemptedMarkedForReview: ans.attemptedMarkedForReview,
          skipped: ans.skipped,
          guess: ans.guess,
          markedForReview: ans.markedForReview,
          time: ans.time,
          timePerQuestion: ans.timePerQuestion,
          isSaved: ans.toJson() == ansList.value[index].toJson());
      ansList.value[index] = saveModel;
    } else {
      ansList.value.add(ans);
    }
  }

  Future<void> onAllTestExamByCategoryApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<TestExamPaperListModel> result =
          await _apiService.allTestExamByCategoryList(id);
      alltestexam.clear();
      alltestexam.addAll(result);
    } catch (e) {
      debugPrint('Error fetching testlist: $e');
      alltestexam.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onAllExamAttemptList(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    isLoading = true;
    try {
      final ExamAttemptsModel result = await _apiService.allExamAttemptList(id);
      examAttemptsModel.value = null;
      examAttemptsModel.value = result;
    } catch (e) {
      debugPrint('Error fetching onAllExamAttemptList: $e');
      examAttemptsModel.value = null;
    } finally {
      isLoading = false;
    }
  }

  Future<void> onExamAttemptList(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    isLoading = true;
    try {
      final McqExamData result = await _apiService.allMcqExamAttemptList(id);
      mcqExamData.value = null;
      mcqExamData.value = result;
    } catch (e) {
      debugPrint('Error fetching onAllExamAttemptList: $e');
      mcqExamData.value = null;
    } finally {
      isLoading = false;
    }
  }

  Future<void> triggerAction() async {
    try {
      List<ExamAnsModel> saveList =
          ansList.value.where((ans) => !ans.isSaved).toList();
      log("${DateTime.now()}===>${saveList.length}");
      print("Triggering action: saving answers...");
      if (saveList.isNotEmpty) {
        bool result =
            await _apiService.saveExamQuestionsList(saveList, type.value);
        if (result) {
          print("Successfully triggered action.");
          for (var ans in saveList) {
            final index = ansList.value
                .indexWhere((item) => item.questionId == ans.questionId);
            if (index != -1) {
              ansList.value[index] = ExamAnsModel(
                  userExamId: ans.userExamId,
                  questionId: ans.questionId,
                  selectedOption: ans.selectedOption,
                  attempted: ans.attempted,
                  attemptedMarkedForReview: ans.attemptedMarkedForReview,
                  skipped: ans.skipped,
                  guess: ans.guess,
                  markedForReview: ans.markedForReview,
                  time: ans.time,
                  timePerQuestion: ans.timePerQuestion,
                  isSaved: true);
            }
          }
        } else {
          print("Error while triggering action.");
        }
      }
    } catch (e) {
      print("Exception occurred during action trigger: $e");
    }
  }

  Future<void> onAllLeaderboardTestExamByCategoryApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<TestExamPaperListModel> result =
          await _apiService.allLeaderboardTestExamByCategoryList(id);
      alltestexam.clear();
      alltestexam.addAll(result);
    } catch (e) {
      debugPrint('Error fetching testlist: $e');
      alltestexam.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetExamPaperDataApiCall(String examId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      debugPrint('storeexam');
      final List<ExamPaperDataModel> result =
          await _apiService.examQuestionPaperData(examId);
      examPaperData.clear();
      examPaperData.addAll(result);
    } catch (e) {
      debugPrint('Error fetching testlist: $e');
      examPaperData.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onPracticeExamPaperDataApiCall(String examId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      debugPrint('practicestoreexam');
      final List<ExamPaperDataModel> result =
          await _apiService.practiceExamQuestionPaperData(examId);
      examPaperData.clear();
      examPaperData.addAll(result);
    } catch (e) {
      debugPrint('Error fetching testlist: $e');
      examPaperData.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCreateTestHistoryCall(String examId, String testType) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final result =
          await _apiService.createContinueHistoryTest(examId, testType);
      await Future.delayed(const Duration(milliseconds: 1));
    } catch (e) {
      debugPrint('Error fetching offers: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetPracticeExamPaperDataApiCall(
      String examId, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      debugPrint('storeexam');
      final List<ExamPaperDataModel> result =
          await _apiService.examPracticeQuestionPaperData(examId, type);
      examPracticePaperData.clear();
      examPracticePaperData.addAll(result);
    } catch (e) {
      debugPrint('Error fetching testlist: $e');
      examPracticePaperData.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetPracticeMockExamPaperDataApiCall(
      String examId, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      debugPrint('storeexam');
      final List<ExamPaperDataModel> result =
          await _apiService.mockExamPracticeQuestionPaperData(examId, type);
      mockExamPracticePaperData.clear();
      mockExamPracticePaperData.addAll(result);
    } catch (e) {
      debugPrint('Error fetching testlist: $e');
      mockExamPracticePaperData.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetPracticeCustomExamPaperDataApiCall(
      String examId, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      debugPrint('storeexam');
      final List<ExamPaperDataModel> result =
          await _apiService.customExamPracticeQuestionPaperData(examId, type);
      customExamPracticePaperData.clear();
      customExamPracticePaperData.addAll(result);
    } catch (e) {
      debugPrint('Error fetching testlist: $e');
      customExamPracticePaperData.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetCustomExamPaperDataApiCall(String examId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      debugPrint('storeexam');
      final List<CustomExamPaperDataModel> result =
          await _apiService.customExamQuestionPaperData(examId);
      customExamPaperData.clear();
      customExamPaperData.addAll(result);
    } catch (e) {
      debugPrint('Error fetching testlist: $e');
      customExamPaperData.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetQuizExamPaperDataApiCall(String examId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      debugPrint('storeexam');
      final List<QuizExamPaperDataModel> result =
          await _apiService.quizExamQuestionPaperData(examId);
      quizExamPaperData.clear();
      quizExamPaperData.addAll(result);
    } catch (e) {
      debugPrint('Error fetching testlist: $e');
      quizExamPaperData.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetTodayQuizDataApiCall() async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final QuizModel result = await _apiService.getTodayQuizDetails();
      await Future.delayed(const Duration(milliseconds: 1));
      getTodayQuizData.value = result;
    } catch (e) {
      debugPrint('Error fetching today quiz: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetPracticeCountApiCall(
      String id, String type, bool isCustom) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final PracticeCountModel result =
          await _apiService.getQuestionCountForPractice(id, type, isCustom);
      await Future.delayed(const Duration(milliseconds: 1));
      _setCountPraticeDetails(result);
    } catch (e) {
      debugPrint('Error fetching today quiz: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetMockPracticeCountApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final PracticeCountModel result =
          await _apiService.getMockQuestionCountForPractice(id);
      await Future.delayed(const Duration(milliseconds: 1));
      _setCountMockPraticeDetails(result);
    } catch (e) {
      debugPrint('Error fetching today quiz: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetCustomPracticeCountApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final PracticeCountModel result =
          await _apiService.getCustomQuestionCountForPractice(id);
      await Future.delayed(const Duration(milliseconds: 1));
      _setCountCustomPraticeDetails(result);
    } catch (e) {
      debugPrint('Error fetching today quiz: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetReportPracticeCountApiCall(
      String id, String type, bool isCustom) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final ReportPracticeCountModel result =
          await _apiService.getReportCountForPractice(id, type, isCustom);
      await Future.delayed(const Duration(milliseconds: 1));
      _setCountReportPraticeDetails(result);
    } catch (e) {
      debugPrint('Error fetching today quiz: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetMockReportPracticeCountApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final ReportPracticeCountModel result =
          await _apiService.getMockReportCountForPractice(id);
      await Future.delayed(const Duration(milliseconds: 1));
      _setCountMockReportPraticeDetails(result);
    } catch (e) {
      debugPrint('Error fetching today quiz: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetCustomReportPracticeCountApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final ReportPracticeCountModel result =
          await _apiService.getCustomReportCountForPractice(id);
      await Future.delayed(const Duration(milliseconds: 1));
      _setCountCustomReportPraticeDetails(result);
    } catch (e) {
      debugPrint('Error fetching today quiz: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetMaterExamPaperDataApiCall(String examId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      debugPrint('storeexam');
      final List<ExamPaperDataModel> result =
          await _apiService.materExamQuestionPaperData(examId);
      materExamPaperData.clear();
      materExamPaperData.addAll(result);
    } catch (e) {
      debugPrint('Error fetching testlist: $e');
      materExamPaperData.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetPracticeMasterExamPaperDataApiCall(String examId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      debugPrint('storeexam');
      final List<ExamPaperDataModel> result =
          await _apiService.masterPracticeExamQuestionPaperData(examId);
      materExamPaperData.clear();
      materExamPaperData.addAll(result);
    } catch (e) {
      debugPrint('Error fetching testlist: $e');
      materExamPaperData.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetSectionExamPaperDataApiCall(
      String examId, String sectionId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      debugPrint('storeexam');
      final List<SectionExamPaperDataModel> result =
          await _apiService.sectionExamQuestionPaperData(examId, sectionId);
      sectionExamPaperData.clear();
      sectionExamPaperData.addAll(result);
    } catch (e) {
      debugPrint('Error fetching testlist: $e');
      sectionExamPaperData.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetSectionListApiCall(String examId, String userExamId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<GetSectionListModel> result =
          await _apiService.getSectionLists(examId, userExamId);
      getSectionList.clear();
      getSectionList.addAll(result);
    } catch (e) {
      debugPrint('Error fetching testlist: $e');
      getSectionList.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> startCreateCustomExam(
      String examId, String startTime, String endTime, bool? isPractice) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final CreateCustomExamModel result = await _apiService
          .startCustomExamTest(examId, startTime, endTime, isPractice);
      startCustomExam.value = result;
    } catch (e) {
      debugPrint('Error fetching exam2: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<String> startCreateExam(
      String examId,
      String startTime,
      String endTime,
      bool? isPractice,
      String? type,
      String? userExamId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return "";
    }

    isLoading = true;
    try {
      final CreateExamModel result = await _apiService.startExamTest(
          examId, startTime, endTime, isPractice, type ?? "", userExamId);
      log(result.toJson().toString());
      startExam.value = result;
      return result.id!;
    } catch (e) {
      debugPrint('Error fetching exam2: $e');
      return "";
    } finally {
      isLoading = false;
    }
  }

  Future<void> startCreateQuizExam(
      String examId, String startTime, String endTime) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final CreateQuizExamModel result =
          await _apiService.startQuizExamTest(examId, startTime, endTime);
      startQuizExam.value = result;
    } catch (e) {
      debugPrint('Error fetching exam2: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> startCreateMaterExam(
      String examId, String startTime, String endTime, bool? isPractice) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      log(examId.toString());
      log(startTime.toString());
      log(endTime.toString());
      final CreateExamModel result = await _apiService.startMasterExamTest(
          examId, startTime, endTime, isPractice);
      log(result.toString());
      startMasterExam.value = result;
    } catch (e) {
      debugPrint('Error fetching exam2: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> startCreateSectionMaterExam(
      String userExamId, String sectionId, String status) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final CreateSectionExamModel result = await _apiService
          .startSectionMasterExamTest(userExamId, sectionId, status);
      startSectionMasterExam.value = result;
    } catch (e) {
      debugPrint('Error fetching section exam: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> userAnswerTest(
      BuildContext context,
      String userExamId,
      String questionId,
      String selectedOption,
      bool isAttempted,
      bool isAttemptedAndMarkedForReview,
      bool isSkipped,
      bool isMarkedForReview,
      String guess,
      String time) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }

    isLoading = true;
    try {
      final UserExamAnswer result = await _apiService.userAnswerExamTest(
          userExamId,
          questionId,
          selectedOption,
          isAttempted,
          isAttemptedAndMarkedForReview,
          isSkipped,
          isMarkedForReview,
          guess,
          time);
      userAnswerExam.value = result;
    } catch (e) {
      debugPrint('Error fetching exam: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> quizAnswerTest(
      BuildContext context,
      String userExamId,
      String questionId,
      String selectedOption,
      bool isAttempted,
      bool isAttemptedAndMarkedForReview,
      bool isSkipped,
      bool isMarkedForReview,
      String guess,
      String time) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }

    isLoading = true;
    try {
      final QuizExamAnswer result = await _apiService.userAnswerQuizExamTest(
          userExamId,
          questionId,
          selectedOption,
          isAttempted,
          isAttemptedAndMarkedForReview,
          isSkipped,
          isMarkedForReview,
          guess,
          time);
      quizAnswerExam.value = result;
    } catch (e) {
      debugPrint('Error fetching exam: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> userAnswerCustomTest(
      BuildContext context,
      String userExamId,
      String questionId,
      String selectedOption,
      bool isAttempted,
      bool isAttemptedAndMarkedForReview,
      bool isSkipped,
      bool isMarkedForReview,
      String guess,
      String time) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }

    isLoading = true;
    try {
      final UserCustomExamAnswer result =
          await _apiService.userAnswerExamCustomTest(
              userExamId,
              questionId,
              selectedOption,
              isAttempted,
              isAttemptedAndMarkedForReview,
              isSkipped,
              isMarkedForReview,
              guess,
              time);
      userCustomAnswerExam.value = result;
    } catch (e) {
      debugPrint('Error fetching exam: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> userAnswerMasterTest(
      BuildContext context,
      String userExamId,
      String questionId,
      String selectedOption,
      bool isAttempted,
      bool isAttemptedAndMarkedForReview,
      bool isSkipped,
      bool isMarkedForReview,
      String guess,
      String time,
      String? questionTime) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }

    isLoading = true;
    try {
      final UserExamAnswer result = await _apiService.userAnswerMasterExamTest(
          userExamId,
          questionId,
          selectedOption,
          isAttempted,
          isAttemptedAndMarkedForReview,
          isSkipped,
          isMarkedForReview,
          guess,
          time,
          questionTime);
      userAnswerMasterExam.value = result;
    } catch (e) {
      debugPrint('Error fetching exam: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> questionAnswerById(String userExamId, String questionId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final UserExamAnswer result =
          await _apiService.getAnsByQuestion(userExamId, questionId);
      userAnswerExam.value = result;
    } catch (e) {
      debugPrint('Error fetching exam: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> questionAnswerByIdQuiz(
      String userExamId, String questionId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final QuizExamAnswer result =
          await _apiService.getAnsByQuizQuestion(userExamId, questionId);
      quizAnswerExam.value = result;
    } catch (e) {
      debugPrint('Error fetching exam: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> questionAnswerByIdCustomTest(
      String userExamId, String questionId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final UserCustomExamAnswer result =
          await _apiService.getAnsByCustomTestQuestion(userExamId, questionId);
      userCustomAnswerExam.value = result;
    } catch (e) {
      debugPrint('Error fetching exam: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> getQuestionPallete(String userExamId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<QuestionPalleteModel> result =
          await _apiService.questionPallete(userExamId);
      testQuePallete.clear();
      testQuePallete.addAll(result);
    } catch (e) {
      debugPrint('Error fetching exam: $e');
      testQuePallete.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> getQuizQuestionPallete(String userExamId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<QuizQuestionPalleteModel> result =
          await _apiService.quizQuestionPalletes(userExamId);
      quizQuePallete.clear();
      quizQuePallete.addAll(result);
    } catch (e) {
      debugPrint('Error fetching exam: $e');
      quizQuePallete.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> getCustomTestQuestionPallete(String userExamId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<CustomTestQuestionPalleteModel> result =
          await _apiService.customTestQuestionPallete(userExamId);
      customTestQuePallete.clear();
      customTestQuePallete.addAll(result);
    } catch (e) {
      debugPrint('Error fetching exam: $e');
      customTestQuePallete.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> getMasterQuestionPallete(String userExamId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<QuestionPalleteModel> result =
          await _apiService.masterQuestionPallete(userExamId);
      masterTestQuePallete.clear();
      masterTestQuePallete.addAll(result);
    } catch (e) {
      debugPrint('Error fetching exam: $e');
      masterTestQuePallete.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> getSectionQuestionPallete(String userExamId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<SectionQuestionPalleteModel> result =
          await _apiService.sectionQuestionPallete(userExamId);
      sectionTestQuePallete.clear();
      sectionTestQuePallete.addAll(result);
    } catch (e) {
      debugPrint('Error fetching section exam: $e');
      sectionTestQuePallete.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> getQuestionPalleteCount(String userExamId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final QuestionPalleteCountModel result =
          await _apiService.quesPalleteCount(userExamId);
      testQuePalleteCount.value = result;
    } catch (e) {
      debugPrint('Error fetching exam: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> getQuizQuestionPalleteCount(String userExamId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final QuizQuestionPalleteCountModel result =
          await _apiService.quesPalleteCountQuiz(userExamId);
      quizTestQuePalleteCount.value = result;
    } catch (e) {
      debugPrint('Error fetching exam: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> getCustomTestQuestionPalleteCount(String userExamId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final CustomTestQuestionPalleteCountModel result =
          await _apiService.quesPalleteCountCustomTest(userExamId);
      customTestQuePalleteCount.value = result;
    } catch (e) {
      debugPrint('Error fetching exam: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> getQuestionMasterPalleteCount(String userExamId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final QuestionPalleteCountModel result =
          await _apiService.quesMasterPalleteCount(userExamId);
      testQueMasterPalleteCount.value = result;
    } catch (e) {
      debugPrint('Error fetching exam: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> getQuestionSectionPalleteCount(
      String userExamId, String sectionId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final SectionQuestionPalleteCountModel result =
          await _apiService.quesSectionWisePalleteCount(userExamId, sectionId);
      sectionQueMasterPalleteCount.value = result;
    } catch (e) {
      debugPrint('Error fetching exam: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> getQuestionAllSectionPalleteCount(String userExamId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<AllSectionQuestionPalleteCountModel> result =
          await _apiService.quesAllSectionWisePalleteCount(userExamId);
      allSectionQueMasterPalleteCount.clear();
      allSectionQueMasterPalleteCount.addAll(result);
    } catch (e) {
      debugPrint('Error fetching all section wise pallete count: $e');
      allSectionQueMasterPalleteCount.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onReportExamApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final ReportByCategoryModel result = await _apiService.reportsByExam(id);
      reportsExam.value = result;
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onReportQuizExamApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final QuizReportByCategoryModel result =
          await _apiService.reportsByQuizExam(id);
      reportsQuizExam.value = result;
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onReportCustomTestExamApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final CustomTestReportByCategoryModel result =
          await _apiService.reportsByCustomTestExam(id);
      reportsCustomTestExam.value = result;
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onReportMasterExamApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final ReportByCategoryModel result =
          await _apiService.reportsByMasterExam(id);
      reportsMasterExam.value = result;
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onSearchApiCall(String keyword, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<SearchedDataModel> result =
          await _apiService.getSearchedListData(keyword, type);
      searchList.clear();
      searchList.addAll(result);
    } catch (e) {
      debugPrint('Error fetching videoctopic: $e');
      searchList.clear();
    } finally {
      isLoading = false;
    }
  }

  @action
  void _setQuizDetails(QuizModel value) {
    getTodayQuizData.value = value;
  }

  @action
  void _setCountPraticeDetails(PracticeCountModel value) {
    getPracticeCountData.value = value;
  }

  @action
  void _setCountMockPraticeDetails(PracticeCountModel value) {
    getMockPracticeCountData.value = value;
  }

  @action
  void _setCountCustomPraticeDetails(PracticeCountModel value) {
    getCustomPracticeCountData.value = value;
  }

  @action
  void _setCountReportPraticeDetails(ReportPracticeCountModel value) {
    getReportPracticeCountData.value = value;
  }

  @action
  void _setCountMockReportPraticeDetails(ReportPracticeCountModel value) {
    getMockReportPracticeCountData.value = value;
  }

  @action
  void _setCountCustomReportPraticeDetails(ReportPracticeCountModel value) {
    getCustomReportPracticeCountData.value = value;
  }

  @action
  Future<void> analysis(String id, String examId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    isLoading = true;
    try {
      final ExamReport result = await _apiService.examReport(id);
      final ExamReport result2 = await _apiService.examReportRank1(examId);
      examReport.value = result;
      examReport2.value = result2;
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> mcqAnalysis(String examId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    isLoading = true;
    try {
      final McqAnalysis result = await _apiService.mcqExamReport(examId);
      mcqExamReport.value = result;
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> bookmarkAnalysis(String examId, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    isLoading = true;
    try {
      final McqAnalysis result =
          await _apiService.bookmarkExamReport(examId, type);
      mcqExamReport.value = result;
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> mcqExamCounts(String examId, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    isLoadingCountLoading = true;
    try {
      print(examId);
      print(type);
      final result = await _apiService.getCountTestMcqMode(examId, type);
      mcqExamCount.value = result;
    } catch (e) {
      debugPrint('Error fetching mcqExamCounts: $e');
    } finally {
      isLoadingCountLoading = false;
    }
  }

  @action
  Future<void> disposeStore() async {
    print("Disposing store...");
    _timer?.cancel();
    ansList.value = [];
    qutestionList.value = [];
  }
}
