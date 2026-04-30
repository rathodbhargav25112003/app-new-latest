import 'package:mobx/mobx.dart';
import 'package:flutter/material.dart';
import '../../../api_service/api_service.dart';
import 'package:shusruta_lms/models/mcq_exam_data.dart';
import 'package:shusruta_lms/models/BookmarkTestModel.dart';
import 'package:shusruta_lms/models/bookmark_topic_model.dart';
import 'package:shusruta_lms/models/bookmark_category_model.dart';
import 'package:shusruta_lms/models/bookmark_by_examlist_model.dart';
import 'package:shusruta_lms/models/bookmark_subcategory_model.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart' as test;
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';
part 'new_bookmark_store.g.dart';

class BookmarkNewStore = _BookmarkNewStore with _$BookmarkNewStore;

abstract class _BookmarkNewStore extends InternetStore with Store {
  final ApiService _apiService = ApiService();

  @observable
  bool isLoading = false;

  @observable
  Observable<List<BookMarkCategoryModel>?> selectedBookmarkCategory =
      Observable<List<BookMarkCategoryModel>?>([]);

  @observable
  Observable<List<BookMarkSubCategoryModel>> selectedBookmarkSubCategory =
      Observable<List<BookMarkSubCategoryModel>>([]);

  @observable
  Observable<List<BookMarkTopicModel>> selectedBookmarkTopic =
      Observable<List<BookMarkTopicModel>>([]);

  @observable
  Observable<List<BookMarkByExamListModel>> selectedBookmarkTest =
      Observable<List<BookMarkByExamListModel>>([]);

  @observable
  Observable<BookmarkTestModel?> bookmarkTestModel =
      Observable<BookmarkTestModel?>(null);

  @observable
  Observable<String> name = Observable<String>("");

  @observable
  Observable<String> description = Observable<String>("");

  @observable
  Observable<int> min = Observable<int>(30);

  @observable
  Observable<int> question = Observable<int>(1);

  @observable
  Observable<McqExamData?> examsData = Observable<McqExamData?>(null);

  @action
  Future<void> ongetAllMyCustomTestApiCall(String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      BookmarkTestModel data =
          await _apiService.getAllMyCustomTestBookmark(type);
      bookmarkTestModel.value = data;
      selectedBookmarkCategory.value = [];
      selectedBookmarkSubCategory.value = [];
      selectedBookmarkTopic.value = [];
      selectedBookmarkTest.value = [];
    } catch (e) {
      debugPrint('Error fetching ongetAllMyCustomTestApiCall: $e');
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> ongetCustomAnalysisApiCall(
      String type, String id, bool isAll) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      McqExamData? data =
          await _apiService.getCustomAnalysisBookmark(type, id, isAll);

      if (data != null) {
        examsData.value = data;
      }
    } catch (e) {
      debugPrint('Error fetching ongetAllMyCustomTestApiCall: $e');
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> ongetCustomADeleteApiCall(String type, String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    isLoading = true;
    try {
      await _apiService.getCustomDeleteBookmark(type, id);
    } catch (e) {
      debugPrint('Error fetching onCreateCustomeExamApiCall: $e');
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<Map<String, dynamic>?> onCreateCustomeExamApiCall(
      String type, Map<String, dynamic> data) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return {};
    }

    isLoading = true;
    try {
      return await _apiService.onCreateCustomeExamCreate(type, data);
    } catch (e) {
      debugPrint('Error fetching onCreateCustomeExamApiCall: $e');
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<List<test.TestData>> ongetBookmarkMacqQuestionsListApiCall(
      String type, String id, bool isAll, bool isMock, bool isCustome) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return [];
    }

    isLoading = true;
    try {
      return isCustome
          ? await _apiService.getCustomMacqQuestionList(type, id, isCustome)
          : await _apiService.getBookmarkMacqQuestionList(
              type, id, isAll, isMock, isCustome);
    } catch (e) {
      debugPrint('Error fetching ongetAllMyCustomTestApiCall: $e');
      return [];
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<List<test.TestData>> ongetReBookmarkMacqQuestionsListApiCall(
      String type, String sectionType, String id, bool isAll, bool isCustom) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return [];
    }

    isLoading = true;
    try {
      return await _apiService.getReBookmarkMacqQuestionList(
          type, sectionType, id, isAll, isCustom);
    } catch (e) {
      debugPrint('Error fetching ongetAllMyCustomTestApiCall: $e');
      return [];
    } finally {
      isLoading = false;
    }
  }

  @action
  void deleteCategoryAndLinkedData(String categoryId) {
    // Step 1: Find all subcategories linked to this category
    final subcategoryIds = selectedBookmarkSubCategory.value!
        .where((sub) => sub.category_id == categoryId)
        .map((sub) => sub.subcategory_id)
        .toList();
    print(subcategoryIds);
    // Step 2: Find all topics linked to these subcategories
    final topicIds = selectedBookmarkTopic.value!
        .where((topic) => subcategoryIds.contains(topic.subcategory_id))
        .map((topic) => topic.topic_id)
        .toList();

    // Step 3: Delete all tests linked to those topics
    selectedBookmarkTest.value!.removeWhere(
      (test) => topicIds.contains(test.topic_id),
    );

    // Step 4: Delete all topics under those subcategories
    selectedBookmarkTopic.value!.removeWhere(
      (topic) => subcategoryIds.contains(topic.subcategory_id),
    );

    // Step 5: Delete all subcategories under this category
    selectedBookmarkSubCategory.value!.removeWhere(
      (sub) => sub.category_id == categoryId,
    );

    // Step 6: Delete the category itself
    selectedBookmarkCategory.value!.removeWhere(
      (cat) => cat.category_id == categoryId,
    );
  }

  @action
  void deleteSubcategoryAndLinkedData(
    String subcategoryId,
  ) {
    // Step 1: Find all topics linked to this subcategory
    final topicIds = selectedBookmarkTopic.value!
        .where((topic) => topic.subcategory_id == subcategoryId)
        .map((topic) => topic.topic_id)
        .toList();

    // Step 2: Delete all tests linked to these topics
    selectedBookmarkTest.value!.removeWhere(
      (test) => topicIds.contains(test.topic_id),
    );

    // Step 3: Delete all topics under this subcategory
    selectedBookmarkTopic.value!.removeWhere(
      (topic) => topic.subcategory_id == subcategoryId,
    );

    // Step 4: Delete the subcategory itself
    selectedBookmarkSubCategory.value!.removeWhere(
      (sub) => sub.subcategory_id == subcategoryId,
    );
  }

  @action
  void deleteTopicAndLinkedData(
    String topicId,
  ) {
    // Step 1: Delete all tests linked to this topic
    selectedBookmarkTest.value!.removeWhere(
      (test) => test.topic_id == topicId,
    );

    // Step 2: Delete the topic itself
    selectedBookmarkTopic.value!.removeWhere(
      (topic) => topic.topic_id == topicId,
    );
  }

  @action
  Future<void> createModule(Map<String, dynamic> data, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      await _apiService.createBookmarkExam(data, type);
    } catch (e) {
      debugPrint('Error createModule: $e');
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> selectBookmarkCategory(BookMarkCategoryModel category) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkCategory.value!.add(category);
  }

  @action
  Future<void> selectAllBookmarkCategories(
      List<BookMarkCategoryModel> categories) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkCategory.value!
        .clear(); // Clear existing selection if needed
    selectedBookmarkCategory.value!.addAll(categories);
  }

  @action
  Future<void> deselectAllBookmarkCategories() async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkCategory.value!.clear();
  }

  @action
  Future<void> removeBookmarkCategory(BookMarkCategoryModel category) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkCategory.value!.remove(category);
  }

  @action
  Future<void> selectBookmarkSubCategory(
      BookMarkSubCategoryModel subCategory) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkSubCategory.value.add(subCategory);
  }

  @action
  Future<void> selectAllBookmarkSubCategories(
      List<BookMarkSubCategoryModel> allSubCategories) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkSubCategory.value = List.from(allSubCategories);
  }

  @action
  Future<void> deselectAllBookmarkSubCategories() async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkSubCategory.value.clear();
  }

  @action
  Future<void> removeBookmarkSubCategory(
      BookMarkSubCategoryModel subCategory) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkSubCategory.value.remove(subCategory);
  }

  @action
  Future<void> selectBookmarkTopic(BookMarkTopicModel topic) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkTopic.value.add(topic);
  }

  @action
  Future<void> selectAllBookmarkTopics(
      List<BookMarkTopicModel> allTopics) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkTopic.value = List.from(allTopics);
  }

  @action
  Future<void> deselectAllBookmarkTopics() async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkTopic.value.clear();
  }

  @action
  Future<void> removeBookmarkTopic(BookMarkTopicModel topic) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkTopic.value.remove(topic);
  }

  @action
  Future<void> selectBookmarkTest(BookMarkByExamListModel test) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkTest.value.add(test);
  }

  @action
  Future<void> selectAllBookmarkTests(
      List<BookMarkByExamListModel> allTests) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkTest.value = List.from(allTests);
  }

  @action
  Future<void> deselectAllBookmarkTests() async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkTest.value.clear();
  }

  @action
  Future<void> removeBookmarkTest(BookMarkByExamListModel test) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    selectedBookmarkTest.value.remove(test);
  }

  @action
  Future<void> resetBookmark() async {
    selectedBookmarkCategory.value = null;
  }

  @action
  Future<void> setValue(String testName, String testdescription, int duration,
      int numberOfQuestions) async {
    name.value = testName;
    description.value = testdescription;
    min.value = duration;
    question.value = numberOfQuestions;
  }
}
