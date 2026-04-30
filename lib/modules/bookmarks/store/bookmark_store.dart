import 'package:mobx/mobx.dart';
import '../../../helpers/colors.dart';
import 'package:flutter/cupertino.dart';
import '../../widgets/bottom_toast.dart';
import '../../../api_service/api_service.dart';
import '../../../models/bookmark_topic_model.dart';
import '../../../models/solution_reports_model.dart';
import '../../../models/bookmark_category_model.dart';
import '../../../models/bookmark_mainlist_model.dart';
import '../../../models/bookmark_exam_list_model.dart';
import '../../../models/bookmark_by_examlist_model.dart';
import '../../../models/bookmark_subcategory_model.dart';
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';

part 'bookmark_store.g.dart';

class BookMarkStore = _BookMarkStore with _$BookMarkStore;

abstract class _BookMarkStore extends InternetStore with Store {
  final ApiService _apiService = ApiService();

  @observable
  bool isLoading = false;

  @observable
  ObservableList<BookMarkCategoryModel?> bookmarkCategory =
      ObservableList<BookMarkCategoryModel>();

  @observable
  ObservableList<BookMarkCategoryModel?> masterBookmarkCategory =
      ObservableList<BookMarkCategoryModel>();

  @observable
  ObservableList<BookMarkSubCategoryModel?> bookmarkSubCategory =
      ObservableList<BookMarkSubCategoryModel>();

  @observable
  ObservableList<BookMarkTopicModel?> bookmarkTopic =
      ObservableList<BookMarkTopicModel>();

  @observable
  ObservableList<BookMarkMainListModel?> bookmarkListAll =
      ObservableList<BookMarkMainListModel>();

  @observable
  ObservableList<BookMarkByExamListModel?> bookMarkByExam =
      ObservableList<BookMarkByExamListModel>();

  @observable
  ObservableList<BookMarkByExamListModel?> masterbookMarkByExam =
      ObservableList<BookMarkByExamListModel>();

  @observable
  ObservableList<BookMarkExamListModel?> bookMarkByExamType =
      ObservableList<BookMarkExamListModel>();

  @observable
  ObservableList<SolutionReportsModel?> bookMarkQuestionsList =
      ObservableList<SolutionReportsModel>();

  @observable
  ObservableList<SolutionReportsModel?> masterBookMarkQuestionsList =
      ObservableList<SolutionReportsModel>();

  Future<void> onBookMarkListAllApiCall(BuildContext context) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<BookMarkMainListModel> result =
          await _apiService.bookmarkListAll();
      bookmarkListAll.clear();
      bookmarkListAll.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      bookmarkListAll.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onBookMarkExamByCategoryApiCall(String id, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<BookMarkByExamListModel> result =
          await _apiService.bookMarkExamByCategoryList(id, type);
      bookMarkByExam.clear();
      bookMarkByExam.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      bookMarkByExam.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onMasterBookMarkExamListApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<BookMarkByExamListModel> result =
          await _apiService.masterBookMarkExamByList(id);
      masterbookMarkByExam.clear();
      masterbookMarkByExam.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      masterbookMarkByExam.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onMasterBookMarkExamListApiCallv2(
      List<String> ids, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<BookMarkByExamListModel> result =
          await _apiService.masterBookMarkExamByListv2(ids,type);
      masterbookMarkByExam.clear();
      masterbookMarkByExam.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      masterbookMarkByExam.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onBookMarkExamTypeApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<BookMarkExamListModel> result =
          await _apiService.bookMarkListByExam(id);
      bookMarkByExamType.clear();
      result.sort(
          (a, b) => b.isAttemptcount?.compareTo(a.isAttemptcount ?? 0) ?? 0);
      bookMarkByExamType.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      bookMarkByExamType.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onBookMarkQuestionListApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<SolutionReportsModel> result =
          await _apiService.bookMarkExamQuestionList(id);
      bookMarkQuestionsList.clear();
      bookMarkQuestionsList.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      bookMarkQuestionsList.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onMasterBookMarkQuestionListApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<SolutionReportsModel> result =
          await _apiService.masterBookMarkExamQuestionList(id);
      masterBookMarkQuestionsList.clear();
      masterBookMarkQuestionsList.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      masterBookMarkQuestionsList.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onBookMarkCategoryApiCall(BuildContext context) async {
    isLoading = true;

    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    try {
      final List<BookMarkCategoryModel> result =
          await _apiService.bookMarkCategoryList();
      bookmarkCategory.clear();
      bookmarkCategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching test: $e');
      bookmarkCategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onMasterBookMarkCategoryApiCall(BuildContext context) async {
    isLoading = true;

    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    try {
      final List<BookMarkCategoryModel> result =
          await _apiService.masterBookMarkCategoryList();
      masterBookmarkCategory.clear();
      masterBookmarkCategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching test: $e');
      masterBookmarkCategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onBookMarkSubCategoryApiCall(String catid) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<BookMarkSubCategoryModel> result =
          await _apiService.bookMarkSubCategoryList(catid);
      bookmarkSubCategory.clear();
      bookmarkSubCategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      bookmarkSubCategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onBookMarkSubCategoryApiCallv2(
      List<String> catid, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<BookMarkSubCategoryModel> result =
          await _apiService.bookMarkSubCategoryListv2(catid, type);
      bookmarkSubCategory.clear();
      bookmarkSubCategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      bookmarkSubCategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onBookMarkTopicApiCall(String subCatId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<BookMarkTopicModel> result =
          await _apiService.bookMarkTopicList(subCatId);
      bookmarkTopic.clear();
      bookmarkTopic.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      bookmarkTopic.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onBookMarkTopicApiCallv2(
      List<String> subCatId, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<BookMarkTopicModel> result =
          await _apiService.bookMarkTopicListv2(subCatId, type);
      bookmarkTopic.clear();
      bookmarkTopic.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      bookmarkTopic.clear();
    } finally {
      isLoading = false;
    }
  }
}
