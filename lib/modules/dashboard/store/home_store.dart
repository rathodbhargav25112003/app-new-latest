import 'dart:developer';
import 'package:mobx/mobx.dart';
import '../../../app/routes.dart';
import '../../../helpers/colors.dart';
import 'package:flutter/cupertino.dart';
import '../../widgets/bottom_toast.dart';
import '../models/global_search_model.dart';
import '../../../api_service/api_service.dart';
import '../../../models/get_offers_model.dart';
import '../models/progress_details_model.dart';
import '../models/continue_watching_model.dart';
import '../models/homepage_watching_model.dart';
import '../../../models/featured_list_model.dart';
import '../../../models/get_user_details_model.dart';
import '../../../models/notification_list_model.dart';
import '../../../models/zoom_meeting_live_model.dart';
import '../../../models/update_user_profile_model.dart';
import '../../../models/standard_model.dart';
import '../models/create_video_note_history_model.dart';
import 'package:shusruta_lms/models/get_declaration.dart';
import '../../../models/get_mock_test_details_model.dart';
import 'package:shusruta_lms/models/delete_account_model.dart';
import '../../testimonial_and_blog/model/get_all_blogs_model.dart';
import '../../testimonial_and_blog/model/get_blog_details_model.dart';
import '../../testimonial_and_blog/model/create_testimonial_model.dart';
import '../../testimonial_and_blog/model/get_all_testimonial_list_model.dart';
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';

part 'home_store.g.dart';

class HomeStore = _HomeStore with _$HomeStore;

abstract class _HomeStore extends InternetStore with Store {
  final ApiService _apiService = ApiService();

  @observable
  bool isLoading = false;

  @observable
  Observable<ZoomLiveModel?> zoomlivemodel = Observable<ZoomLiveModel?>(null);

  @observable
  Observable<FeaturedListModel?> featuredContent =
      Observable<FeaturedListModel?>(null);

  @observable
  Observable<GetBlogsListModel?> blogsContent =
      Observable<GetBlogsListModel?>(null);

  @observable
  Observable<GetTestimonialListModel?> testimonialContent =
      Observable<GetTestimonialListModel?>(null);

  @observable
  GetDeclaration? getDeclaration;

  @observable
  Observable<GetUserDetailsModel?> userDetails =
      Observable<GetUserDetailsModel?>(null);

  @observable
  Observable<ProgressDetailsModel?> progressDetails =
      Observable<ProgressDetailsModel?>(null);

  @observable
  Observable<GetMockTestDetailsModel?> mockTestDetails =
      Observable<GetMockTestDetailsModel?>(null);

  @observable
  Observable<UpdateUserProfileModel?> updateUserDetails =
      Observable<UpdateUserProfileModel?>(null);

  @observable
  Observable<CreateTestimonialModel?> createTestimonial =
      Observable<CreateTestimonialModel?>(null);

  @observable
  Observable<GetOffersModel?> offerBanners = Observable<GetOffersModel?>(null);

  @observable
  Observable<CreateVideoNoteHistoryModel?> createVideoNoteHistory =
      Observable<CreateVideoNoteHistoryModel?>(null);

  @observable
  Observable<DeleteAccountModel?> deleteData =
      Observable<DeleteAccountModel?>(null);

  @observable
  ObservableList<NotificationListModel?> getNotificationList =
      ObservableList<NotificationListModel?>();

  // Not annotated to avoid requiring codegen update
  ObservableList<StandardModel?> standardList = ObservableList<StandardModel?>();

  @observable
  ObservableList<GlobalSearchDataModel?> globalSearchList =
      ObservableList<GlobalSearchDataModel?>();

  @observable
  ObservableList<GetBlogsListModel?> getBlogsListData =
      ObservableList<GetBlogsListModel>();

  @observable
  ObservableList<ContinueWatchingModel?> getContinueListData =
      ObservableList<ContinueWatchingModel>();

  @observable
  ObservableList<HomePageWatchingModel?> getHomeListData =
      ObservableList<HomePageWatchingModel>();

  @observable
  Observable<GetBlogDetailsModel?> getBlogDetailsData =
      Observable<GetBlogDetailsModel?>(null);

  @observable
  ObservableList<GetTestimonialListModel?> getTestimonialData =
      ObservableList<GetTestimonialListModel>();

  // Future<void> ongetLiveZoomClass(BuildContext context) async {
  //   await checkConnectionStatus();
  //   if (!isConnected) {
  //     //Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
  //     return;
  //   }
  //
  //   isLoading = true;
  //   try {
  //     final ZoomLiveModel result = await _apiService.getZoomLive();
  //     await Future.delayed(const Duration(milliseconds: 1));
  //     _setLiveDetails(result);
  //   } catch (e) {
  //     debugPrint('Error fetching featured contents: $e');
  //   } finally {
  //     isLoading = false;
  //   }
  // }

  Future<void> onGetFeaturedListApiCall(BuildContext context) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }

    isLoading = true;
    try {
      final FeaturedListModel result = await _apiService.getFeaturedList();
      await Future.delayed(const Duration(milliseconds: 1));
      _setFeaturedContent(result);
    } catch (e) {
      debugPrint('Error fetching featured contents: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetStanderdList() async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<StandardModel> result = await _apiService.getStanderdList();
      standardList.clear();
      standardList.addAll(result);
    } catch (e) {
      debugPrint('Error fetching standerd list: $e');
      standardList.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetUserDetailsCall(BuildContext context) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final GetUserDetailsModel result =
          await _apiService.showUserDetails(context);
      await Future.delayed(const Duration(milliseconds: 1));
      _setUserDetails(result);
      // userDetails.value = result;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetProgressDetailsCall(BuildContext context) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final ProgressDetailsModel result =
          await _apiService.showProgressDetails(context);
      await Future.delayed(const Duration(milliseconds: 1));
      _setProgressDetails(result);
      // userDetails.value = result;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetDeclarationCall() async {
    await checkConnectionStatus();
    isLoading = true;
    try {
      final GetDeclaration result = await _apiService.getDeclaration();
      log(result.toString());
      getDeclaration = result;
      log(getDeclaration!.toJson().toString());
    } catch (e) {
      debugPrint('Error fetching getDeclaration: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onDeleteNotificationCall() async {
    await checkConnectionStatus();
    isLoading = true;
    try {
      final result = await _apiService.clearNotification();
      debugPrint('result');
    } catch (e) {
      debugPrint('Error clear notifications: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onDeleteUserAccountCall(String userId) async {
    await checkConnectionStatus();
    isLoading = true;
    try {
      final result = await _apiService.deteledAccount(userId);
      debugPrint('result');
    } catch (e) {
      debugPrint('Error deleting bookmark: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetMockTestDetailsCall(BuildContext context) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final GetMockTestDetailsModel result =
          await _apiService.getMockTestDetails();
      await Future.delayed(const Duration(milliseconds: 1));
      _setMockTestDetails(result);
      // userDetails.value = result;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onUpdateUserDetailsCall(
      String userId,
      String fullname,
      String dob,
      String preparingFor,
      stateValue,
      List<String> preparingExams,
      String currentData,
      String phone,
      String email,
      BuildContext context,
      {String? standerdId, String? preparingId}) async {
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
      final UpdateUserProfileModel result = await _apiService.updateUserProfile(
          userId,
          fullname,
          dob,
          preparingFor,
          stateValue,
          preparingExams,
          currentData,
          phone,
          email,
          standerdId: standerdId,
          preparingId: preparingId);
      await Future.delayed(const Duration(milliseconds: 1));
      updateUserDetails.value = result;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCreatetestimonialCall(
      String name, String description, int rating, BuildContext context) async {
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
      final CreateTestimonialModel result =
          await _apiService.createTestimonialReview(name, description, rating);
      await Future.delayed(const Duration(milliseconds: 1));
      createTestimonial.value = result;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetBlogsListApiCall() async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<GetBlogsListModel> result = await _apiService.getBlogsList();
      getBlogsListData.clear();
      getBlogsListData.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      getBlogsListData.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetContinueListApiCall() async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<ContinueWatchingModel> result =
          await _apiService.getContinueHistoryList();
      getContinueListData.clear();
      getContinueListData.addAll(result);
    } catch (e) {
      debugPrint('Error fetching continue watch history: $e');
      getContinueListData.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetHomePageListApiCall() async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<HomePageWatchingModel> result =
          await _apiService.getHomePageHistoryList();
      getHomeListData.clear();
      getHomeListData.addAll(result);
    } catch (e) {
      debugPrint('Error fetching homepage watch history: $e');
      getHomeListData.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetBlogDetailsApiCall(String blogId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final GetBlogDetailsModel result =
          await _apiService.getBlogsDetails(blogId);
      await Future.delayed(const Duration(milliseconds: 1));
      _setBlogDetails(result);
    } catch (e) {
      debugPrint('Error fetching offers: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetTestimonialListApiCall() async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<GetTestimonialListModel> result =
          await _apiService.getTestimonialList();
      getTestimonialData.clear();
      getTestimonialData.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      getTestimonialData.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetOffersCall(BuildContext context) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final GetOffersModel result = await _apiService.getAllOffer();
      await Future.delayed(const Duration(milliseconds: 1));
      _setOfferDetails(result);
    } catch (e) {
      debugPrint('Error fetching offers: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCreateVideoNoteHistoryCall(
      String contentId, String contentType) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    // isLoading = true;
    try {
      final CreateVideoNoteHistoryModel result = await _apiService
          .createContinueHistoryVideoNote(contentId, contentType);
      await Future.delayed(const Duration(milliseconds: 1));
      _setVideoNoteHistoryDetails(result);
    } catch (e) {
      debugPrint('Error fetching offers: $e');
    } finally {
      // isLoading = false;
    }
  }

  Future<void> onDeleteNotificationToken(String fcmToken) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final result = await _apiService.deleteNotificationToken(fcmToken);
      // debugPrint("fcm result");
    } catch (e) {
      debugPrint('Error deleting user notification: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onSignoutUser(String loggedInPlatform) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final result = await _apiService.signoutUser(loggedInPlatform);
      // debugPrint("fcm result");
    } catch (e) {
      debugPrint('Error signout user: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onSignoutUserAllDevice() async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final result = await _apiService.signoutUserAllDevice();
    } catch (e) {
      debugPrint('Error signout user all device: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetNotificationListApiCall() async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<NotificationListModel> result =
          await _apiService.getNotificationList();
      await Future.delayed(const Duration(milliseconds: 1));
      getNotificationList.clear();
      getNotificationList.addAll(result);
    } catch (e) {
      debugPrint('Error fetching notification list: $e');
      getNotificationList.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGlobalSearchApiCall(String type, String selectedVal) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<GlobalSearchDataModel> result =
          await _apiService.getGlobalSearchedListData(type, selectedVal);
      globalSearchList.clear();
      globalSearchList.addAll(result);
    } catch (e) {
      debugPrint('Error fetching globalSearchList: $e');
      globalSearchList.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onDeleteHistoryCall(String id, String type) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      await _apiService.deleteHistory(id, type);
      await onGetContinueListApiCall(); // Refresh the list after deletion
    } catch (e) {
      debugPrint('Error deleting history: $e');
    } finally {
      isLoading = false;
    }
  }

  @action
  void _setFeaturedContent(FeaturedListModel value) {
    featuredContent.value = value;
  }

  @action
  void _setUserDetails(GetUserDetailsModel value) {
    userDetails.value = value;
  }

  @action
  void _setProgressDetails(ProgressDetailsModel value) {
    progressDetails.value = value;
  }

  @action
  void _setMockTestDetails(GetMockTestDetailsModel value) {
    mockTestDetails.value = value;
  }

  @action
  void _setLiveDetails(ZoomLiveModel value) {
    zoomlivemodel.value = value;
  }

  @action
  void _setOfferDetails(GetOffersModel value) {
    offerBanners.value = value;
  }

  @action
  void _setVideoNoteHistoryDetails(CreateVideoNoteHistoryModel value) {
    createVideoNoteHistory.value = value;
  }

  @action
  void _setBlogDetails(GetBlogDetailsModel value) {
    getBlogDetailsData.value = value;
  }

  @action
  void _deteleAccountDetails(DeleteAccountModel value) {
    deleteData.value = value;
  }
}
