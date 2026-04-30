import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:mobx/mobx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/api_service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/modules/masterTest/time_traker.dart';
import 'package:shusruta_lms/models/report_by_category_model.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';
import 'package:shusruta_lms/modules/new_exam_component/model/exam_ans_model.dart';
import 'package:shusruta_lms/modules/masterTest/sectionwisemasterTest/model/get_section_list_model.dart';

part 'section_exam_store.g.dart';

class SectionExamStore = _SectionExamStore with _$SectionExamStore;

abstract class _SectionExamStore extends InternetStore with Store {
  final ApiService _apiService = ApiService();
  static const String _ansListKey = 'section_ans_list';
  static const String _questionListKey = 'section_question_list';

  @observable
  bool isLoading = false;

  @observable
  bool isSubmitting = false;

  Timer? _timer; // Timer for the 2-minute interval
  static const int triggerInterval = 2 * 60; // 2 minutes in seconds

  @observable
  int answerCountSinceLastTrigger = 0; // Count of answers since last trigger

  @observable
  String timeDuration = "00:00:59"; // Count of answers since last trigger

  @observable
  Observable<List<TestData>> questionList = Observable<List<TestData>>([]);

  @observable
  Observable<TestExamPaperListModel?> testExamPaperListModel =
      Observable<TestExamPaperListModel?>(null);

  @observable
  Observable<List<GetSectionListModel>> getSectionListModel =
      Observable<List<GetSectionListModel>>([]);

  @observable
  Observable<List<ExamAnsModel>> ansList = Observable<List<ExamAnsModel>>([]);

  @observable
  Observable<List<ExamAnsModel>> savedAnsList =
      Observable<List<ExamAnsModel>>([]);

  @observable
  Observable<List<List<ExamAnsModel>>> sectionAnsList =
      Observable<List<List<ExamAnsModel>>>([]);

  @observable
  Observable<List<List<TestData>>> sectionQuestionList =
      Observable<List<List<TestData>>>([]);

  @observable
  Observable<String> type = Observable<String>("MockExam");

  @observable
  Observable<TestData?> question = Observable<TestData?>(null);

  @observable
  Observable<int?> currentQuestionIndex = Observable<int?>(0);

  @observable
  Observable<int> selectedOptionIndex = Observable<int>(-1);

  @observable
  Observable<TimeTracker> tracker =
      Observable<TimeTracker>(TimeTracker(previousTime: '00:00:00'));

  @observable
  Observable<ReportByCategoryModel?> reportsMasterExam =
      Observable<ReportByCategoryModel?>(null);

  @observable
  Observable<bool> isGuess = Observable<bool>(false);

  @observable
  Observable<bool> isMarkedForReview = Observable<bool>(false);

  @observable
  Observable<bool> showSheet = Observable<bool>(false);

  @observable
  Observable<bool> isSaving = Observable<bool>(false);

  @observable
  Observable<bool> isSubmit = Observable<bool>(false);

  @observable
  Observable<ReportByCategoryModel?> reportsExam =
      Observable<ReportByCategoryModel?>(null);

  void startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(Duration(seconds: triggerInterval), (timer) async {
      await _triggerAction();
    });
  }

  Future<void> onTestApiCall(
      BuildContext context, String type, String id) async {
    isLoading = true;

    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }
    try {
      final List<TestData> result =
          await _apiService.getExamQuestionsList(type, id);
      questionList.value.clear();
      questionList.value.addAll(result);
      if (questionList.value.isNotEmpty) {
        question.value = questionList.value[0];
      }
    } catch (e) {
      questionList.value.clear();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> onAnsSave(BuildContext context, bool isShow) async {
    isSaving.value = true;
    await checkConnectionStatus();
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please check the internet connection'),
      ));
      return;
    }
    try {
      List<ExamAnsModel> saveList =
          ansList.value.where((ans) => !ans.isSaved).toList();
      log("${DateTime.now()}===>${saveList.length}");
      if (saveList.isNotEmpty) {
        final bool result =
            await _apiService.saveExamQuestionsList(saveList, type.value);
        if (result) {
          // Update isSaved flag for all saved answers
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
          showSheet.value = isShow;
          isSubmit.value = isShow;
          isSaving.value = false;
        } else {
          isSaving.value = false;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Facing error while saving answer"),
          ));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Facing error while saving answer"),
      ));
    } finally {
      isSaving.value = false;
    }
  }

  @action
  Future<void> onChange(TestData q) async {
    tracker.value.dispose();
    question.value = q;
    selectedOptionIndex.value = -1;
    isMarkedForReview.value = false;
    isGuess.value = false;
    for (var question in questionList.value) {
      print('Question Number: ${question.questionNumber}');
    }

    int matchingIndex = questionList.value
        .indexWhere((e) => e.questionNumber == question.value!.questionNumber);
    final index = ansList.value.indexWhere(
        (item) => item.questionId == questionList.value[matchingIndex].sId);
    if (index != -1) {
      selectedOptionIndex.value = questionList.value[matchingIndex].optionsData
              ?.indexWhere(
                  (e) => e.value == ansList.value[index].selectedOption) ??
          -1;
      isMarkedForReview.value = ansList.value[index].markedForReview;
      isGuess.value = ansList.value[index].guess.isNotEmpty;
      tracker.value =
          TimeTracker(previousTime: ansList.value[index].timePerQuestion);
      tracker.value.start();
    } else {
      tracker.value.start();
    }
    currentQuestionIndex.value = matchingIndex;
  }

  @action
  Future<void> onAns(ExamAnsModel ans, bool isAdd, String? prevous) async {
    final index =
        ansList.value.indexWhere((item) => item.questionId == ans.questionId);
    if (index != -1) {
      log(prevous.toString());
      // Create new model with isSaved set if answers match
      ExamAnsModel saveModel = ExamAnsModel(
          previousSelected: prevous,
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

    // answerCountSinceLastTrigger++;

    // if (answerCountSinceLastTrigger >= 5) {
    //   await _triggerAction();
    // }
  }

  @action
  Future<void> onOptionSelect(index) async {
    selectedOptionIndex.value = index;
  }

  @action
  Future<void> changeIndex(index) async {
    await onChange(questionList.value[index]);
    currentQuestionIndex.value = index;
  }

  @action
  Future<void> changeMarkReview(bool value) async {
    isMarkedForReview.value = value;
  }

  @action
  Future<void> changeGuess(bool value) async {
    isGuess.value = value;
  }

  @action
  Future<void> changeType(String value) async {
    type.value = value;
  }

  @action
  Future<void> changeShowSheet(bool value) async {
    showSheet.value = value;
  }

  @action
  Future<void> setData(List<TestData> questions, String ttype) async {
    questionList.value = questions;
    question.value = questions[0];
    type.value = ttype;
  }

  @action
  Future<void> setSectionData(List<TestData> questions,
      TestExamPaperListModel model, String? time) async {
    questionList.value = questions;
    question.value = questions[0];
    testExamPaperListModel.value = model;
    if (time != null) {
      print(time);
      timeDuration = time;
    }
  }

  @action
  Future<void> disposeStore() async {
    print("Disposing store...");
    question.value = null;
    currentQuestionIndex.value = 0;
    print("Question reset: ${question.value}");
    selectedOptionIndex.value = -1;
    print("Selected option reset: ${selectedOptionIndex.value}");
    questionList.value.clear();
    print("Question list cleared: ${questionList.value}");
    ansList.value.clear();
    print("Answer list cleared: ${ansList.value}");
    savedAnsList.value.clear();
    print("Saved answers cleared: ${savedAnsList.value}");
    tracker.value.stop();
    print("Tracker stopped");
    tracker.value = TimeTracker(previousTime: '00:00:00');
    print("Tracker reset: ${tracker.value}");
    isMarkedForReview.value = false;
    isGuess.value = false;
    print("Flags reset");
    isSaving.value = false;
    print("Flags reset");
    isSubmit.value = false;
    print("Flags reset");
    _timer?.cancel();
  }

  @action
  Future<void> disposeSectiomStore(String timeDurationData) async {
    timeDuration = timeDurationData;
    print(ansList.value.length);
    print(questionList.value.length);
    sectionAnsList.value = [...sectionAnsList.value, ansList.value];
    sectionQuestionList.value = [
      ...sectionQuestionList.value,
      questionList.value
    ];
    print(sectionAnsList.value[0].length);
    print(sectionQuestionList.value[0].length);
    print("Disposing store...");
    question.value = null;
    currentQuestionIndex.value = 0;
    print("Question reset: ${question.value}");
    selectedOptionIndex.value = -1;
    print("Selected option reset: ${selectedOptionIndex.value}");
    questionList.value.clear();
    print("Question list cleared: ${questionList.value}");
    ansList.value.clear();
    print("Answer list cleared: ${ansList.value}");
    savedAnsList.value.clear();
    print("Saved answers cleared: ${savedAnsList.value}");
    tracker.value.stop();
    print("Tracker stopped");
    tracker.value = TimeTracker(previousTime: '00:00:00');
    print("Tracker reset: ${tracker.value}");
    isMarkedForReview.value = false;
    isGuess.value = false;
    print("Flags reset");
    isSaving.value = false;
    print("Flags reset");
    isSubmit.value = false;
    print("Flags reset");
    _timer?.cancel();
  }

  @action
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

  @action
  Future<void> onMcqQuestionListCall(String id, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<TestData> result =
          await _apiService.getMcqExamQuestionList(id, type);
      questionList.value.clear();
      questionList.value.addAll(result);
      if (questionList.value.isNotEmpty) {
        question.value = questionList.value[0];
      }
    } catch (e) {
      debugPrint('Error fetching onMcqQuestionListCall: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> _triggerAction() async {
    answerCountSinceLastTrigger = 0;

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
}
