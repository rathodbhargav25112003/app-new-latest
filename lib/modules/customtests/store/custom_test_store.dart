import 'package:mobx/mobx.dart';
import '../../../app/routes.dart';
import 'package:flutter/cupertino.dart';
import '../../../api_service/api_service.dart';
import '../model/create_custom_test_model.dart';
import '../model/custom_test_exam_by_topic_model.dart';
import '../model/custom_test_sub_by_category_model.dart';
import '../../../models/get_all_my_custom_test_model.dart';
import '../model/custom_test_topic_by_subcategory_model.dart';
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';

part 'custom_test_store.g.dart';

class CustomTestCategoryStore = _CustomTestCategoryStore
    with _$CustomTestCategoryStore;

abstract class _CustomTestCategoryStore extends InternetStore with Store {
  final ApiService _apiService = ApiService();

  @observable
  bool isLoading = false;

  @observable
  Observable<CustomTestModel?> createCustomTests =
      Observable<CustomTestModel?>(null);

  @observable
  Observable<MyCustomTestListModel?> customtestlist =
      Observable<MyCustomTestListModel?>(null);

  @observable
  ObservableList<CustomTestSubByCategoryModel?> customTestSubByCateList =
      ObservableList<CustomTestSubByCategoryModel>();

  @observable
  ObservableList<CustomTestTopicBySubCategoryModel?>
      customTestTopicBySubCateList =
      ObservableList<CustomTestTopicBySubCategoryModel>();

  @observable
  ObservableList<CustomTestExamByTopicModel?> customTestExamByTopicsList =
      ObservableList<CustomTestExamByTopicModel>();

  Future<void> onCreateCustomTestApiCall(
      String testName,
      String description,
      int numberOfQuestion,
      String timeDuration,
      List<Map<String, dynamic>> category,
      List<Map<String, dynamic>> subCategory,
      List<Map<String, dynamic>> topic,
      List<Map<String, dynamic>> exam) async {
    isLoading = true;
    await checkConnectionStatus();

    try {
      final CustomTestModel result = await _apiService.createCustomTest(
          testName,
          description,
          numberOfQuestion,
          timeDuration,
          category,
          subCategory,
          topic,
          exam);
      await Future.delayed(const Duration(milliseconds: 1));
      createCustomTests.value = result;
    } catch (e) {
      debugPrint('Error fetching custom test: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onDeleteCustomTestCall(String customTestId) async {
    await checkConnectionStatus();

    isLoading = true;

    try {
      final result = await _apiService.deleteCustomTest(customTestId);
      debugPrint('result');
    } catch (e) {
      debugPrint('Error deleting custom test: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCustomTestListApiCall(BuildContext context) async {
    isLoading = true;

    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }
    try {
      final MyCustomTestListModel result = await _apiService.customTestList();
      await Future.delayed(const Duration(milliseconds: 1));
      customtestlist.value = result;
    } catch (e) {
      debugPrint('Error fetching custom test: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCustomSubCategoryApiCall(String cateIds) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<CustomTestSubByCategoryModel> result =
          await _apiService.customTestSubByCategoryList(cateIds);
      customTestSubByCateList.clear();
      customTestSubByCateList.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      customTestSubByCateList.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCustomTopicApiCall(String subIds) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<CustomTestTopicBySubCategoryModel> result =
          await _apiService.customTestTopicBySubCategoryList(subIds);
      customTestTopicBySubCateList.clear();
      customTestTopicBySubCateList.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      customTestTopicBySubCateList.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCustomExamApiCall(String topicIds) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<CustomTestExamByTopicModel> result =
          await _apiService.customTestExamByTopicList(topicIds);
      customTestExamByTopicsList.clear();
      customTestExamByTopicsList.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      customTestExamByTopicsList.clear();
    } finally {
      isLoading = false;
    }
  }
}
