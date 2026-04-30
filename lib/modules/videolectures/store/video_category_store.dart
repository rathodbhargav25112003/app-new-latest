import 'dart:async';
import 'dart:io';
import 'package:mobx/mobx.dart';
import '../../../app/routes.dart';
import 'package:flutter/cupertino.dart';
import '../../../api_service/api_service.dart';
import '../../../helpers/dbhelper.dart';
import '../../../models/video_topic_model.dart';
import '../../../models/subscription_model.dart';
import '../../../models/searched_data_model.dart';
import '../../../models/video_category_model.dart';
import '../model/get_video_quality_data_model.dart';
import '../../../models/video_subcategory_model.dart';
import '../../../models/video_topic_detail_model.dart';
import '../model/get_all_video_topic_detail_model.dart';
import '../../../models/video_topic_category_model.dart';
import '../../../models/video_chapterization_list_model.dart';
import 'package:shusruta_lms/models/create_video_history_model.dart';
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';
import 'package:shusruta_lms/services/download_service.dart';


part 'video_category_store.g.dart';

class VideoCategoryStore =  _VideoCategoryStore with _$VideoCategoryStore;

abstract class _VideoCategoryStore extends InternetStore with Store {
  final ApiService _apiService = ApiService();

  @observable
  bool isLoading = false;

  @observable
  bool isLoadingChapter = false;

  @observable
  String filterValue = 'View all';

  @observable
  num downloadProgress = 0;

  @observable
  bool isVideoDownloading = false;

  @observable
  ObservableMap<String, int> downloadProgressMap = ObservableMap<String, int>();

  @observable
  ObservableSet<String> downloadingVideos = ObservableSet<String>();

  /// Cached set of titleIds whose files are confirmed on disk.
  /// Populated once per screen via loadDownloadedIds(), updated on
  /// download-complete / delete. Replaces per-item FutureBuilder DB queries.
  @observable
  ObservableSet<String> downloadedVideoIds = ObservableSet<String>();

  final Map<String, int> notificationIds = {};
  int _nextNotificationId = 1;

  /// Throttle: last time we pushed a progress update to observers
  final Map<String, int> _lastProgressUpdateMs = {};

  // ── DownloadService bridge ───────────────────────────────────────────────
  // The store subscribes to the global DownloadService streams so that any
  // download (triggered from any screen) keeps this store's observables in
  // sync — progress, in-progress set, and downloaded set. Using broadcast
  // streams here means the download_manager_sheet's single-callback fields
  // can still be used separately without clobbering the store's listeners.
  StreamSubscription<DownloadTask>? _dlUpdSub;
  StreamSubscription<DownloadTask>? _dlCompSub;
  StreamSubscription<DownloadTask>? _dlFailSub;
  bool _dlWired = false;

  /// Call once at app boot (main.dart, after DownloadService.init()).
  /// Idempotent — repeated calls are no-ops.
  void wireDownloadService() {
    if (_dlWired) return;
    _dlWired = true;
    final svc = DownloadService.instance;
    _dlUpdSub = svc.updates.listen(_onDlEvent);
    _dlCompSub = svc.completed.listen(_onDlCompleted);
    _dlFailSub = svc.failed.listen(_onDlFailed);
  }

  void disposeDownloadService() {
    _dlUpdSub?.cancel();
    _dlCompSub?.cancel();
    _dlFailSub?.cancel();
    _dlUpdSub = null;
    _dlCompSub = null;
    _dlFailSub = null;
    _dlWired = false;
  }

  @action
  void _onDlEvent(DownloadTask t) {
    if (!_isValidTitleId(t.titleId)) return;
    switch (t.status) {
      case DownloadStatus.queued:
      case DownloadStatus.downloading:
      case DownloadStatus.encrypting:
        downloadingVideos.add(t.titleId);
        // Throttle progress into the observable map — we only care about
        // transitions in integer percent; don't thrash the map on every byte.
        final pct = t.progressPercent;
        final prev = downloadProgressMap[t.titleId];
        if (prev != pct) {
          downloadProgressMap[t.titleId] = pct;
        }
        isVideoDownloading = true;
        break;
      case DownloadStatus.completed:
        downloadingVideos.remove(t.titleId);
        downloadProgressMap.remove(t.titleId);
        downloadedVideoIds.add(t.titleId);
        if (downloadingVideos.isEmpty) isVideoDownloading = false;
        break;
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
      case DownloadStatus.paused:
        downloadingVideos.remove(t.titleId);
        downloadProgressMap.remove(t.titleId);
        if (downloadingVideos.isEmpty) isVideoDownloading = false;
        break;
    }
  }

  @action
  void _onDlCompleted(DownloadTask t) {
    if (!_isValidTitleId(t.titleId)) return;
    downloadingVideos.remove(t.titleId);
    downloadProgressMap.remove(t.titleId);
    downloadedVideoIds.add(t.titleId);
    if (downloadingVideos.isEmpty) isVideoDownloading = false;
  }

  @action
  void _onDlFailed(DownloadTask t) {
    if (!_isValidTitleId(t.titleId)) return;
    downloadingVideos.remove(t.titleId);
    downloadProgressMap.remove(t.titleId);
    if (downloadingVideos.isEmpty) isVideoDownloading = false;
  }

  /// Validate that a titleId is safe to use as a key in downloadedVideoIds.
  /// Rejects empty strings and the literal "null" (which would appear if
  /// a caller did `myNullable?.id.toString() ?? ""` and got "null" instead).
  /// These sentinel values were the root cause of the "all videos show
  /// downloaded" UI bug — a single bad write pollutes every sibling.
  bool _isValidTitleId(String? tid) {
    if (tid == null) return false;
    if (tid.isEmpty) return false;
    if (tid == 'null') return false;
    if (tid == 'undefined') return false;
    return true;
  }

  /// Load all downloaded video IDs from DB, verify files still exist on disk.
  /// Call once when a video-list screen mounts (replaces per-item FutureBuilder).
  @action
  Future<void> loadDownloadedIds(List<String> titleIds) async {
    final db = DbHelper();
    final verified = <String>{};
    for (final tid in titleIds) {
      if (!_isValidTitleId(tid)) continue; // skip junk IDs
      final row = await db.getVideoByTitleId(tid);
      if (row != null && row.videoPath != null && row.videoPath!.isNotEmpty) {
        if (await File(row.videoPath!).exists()) {
          verified.add(tid);
        } else {
          // file gone — clean up stale DB row
          await db.deleteVideoByTitleId(tid);
        }
      }
    }
    // Replace wholesale so sibling topics' downloads can't leak into this
    // screen's view. This screen is always scoped to one subcategory/topic.
    downloadedVideoIds = ObservableSet.of(verified);
  }

  @action
  void markDownloaded(String titleId) {
    if (!_isValidTitleId(titleId)) {
      // Refuse to add junk. Logging so the caller notices they passed a bad ID.
      return;
    }
    downloadedVideoIds.add(titleId);
  }

  @action
  void markNotDownloaded(String titleId) {
    if (!_isValidTitleId(titleId)) return;
    downloadedVideoIds.remove(titleId);
  }

  bool isVideoDownloadedCached(String titleId) {
    if (!_isValidTitleId(titleId)) return false;
    return downloadedVideoIds.contains(titleId);
  }

  int getNotificationId(String titleId) {
    if (!notificationIds.containsKey(titleId)) {
      notificationIds[titleId] = _nextNotificationId++;
    }
    return notificationIds[titleId]!;
  }

  void removeNotificationId(String titleId) {
    notificationIds.remove(titleId);
  }

  @action
  void setFilterValue(String value) {
    print('Setting filterValue: $value');
    filterValue = value;
  }

  @action
  void updateProgress(double progress) {
    downloadProgress = progress;
  }

  @action
  void startDownload(String titleId) {
    isVideoDownloading = true;
    downloadingVideos.add(titleId);
    downloadProgressMap[titleId] = 0;
  }

  @action
  void completeDownload(String titleId) {
    isVideoDownloading = false;
    downloadingVideos.remove(titleId);
    downloadProgressMap.remove(titleId);
  }

  @action
  void cancelDownload(String titleId) {
    downloadingVideos.remove(titleId);
    downloadProgressMap.remove(titleId);
  }

  bool isDownloading(String titleId) => downloadingVideos.contains(titleId);

  int getDownloadProgress(String titleId) => downloadProgressMap[titleId] ?? 0;

  @action
  void setDownloadProgress(String titleId, int progress) {
    downloadProgressMap[titleId] = progress;
  }

  /// Throttled progress setter — only updates observers every 500ms to prevent UI jank.
  /// Always fires at 0% and 100%.
  void setDownloadProgressThrottled(String titleId, int progress) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastProgressUpdateMs[titleId] ?? 0;
    if (progress == 0 || progress >= 100 || (now - last) >= 500) {
      _lastProgressUpdateMs[titleId] = now;
      setDownloadProgress(titleId, progress);
    }
  }

  @observable
  ObservableList<VideoCategoryModel?> videocategory = ObservableList<VideoCategoryModel>();

  @observable
  ObservableList<VideoSubCategoryModel?> videosubcategory = ObservableList<VideoSubCategoryModel>();

  @observable
  ObservableList<VideoTopicModel?> videotopic = ObservableList<VideoTopicModel>();

  @observable
  ObservableList<VideoTopicCategoryModel?> videotopiccategory = ObservableList<VideoTopicCategoryModel>();

  @observable
  ObservableList<VideoTopicDetailModel?> videotopicdetail = ObservableList<VideoTopicDetailModel>();

  @observable
  ObservableList<VideoChapterizationListModel?> videoChapterizationList = ObservableList<VideoChapterizationListModel>();

  @observable
  Observable<GetAllVideoTopicDetailModel?> allvideotopicdetail = Observable<GetAllVideoTopicDetailModel?>(null);

  @observable
  Observable<GetVideoQualityDataModel?> videoQualityDetail = Observable<GetVideoQualityDataModel?>(null);

  @observable
  Observable<CreateVideoHistoryModel?> createvideohistory = Observable<CreateVideoHistoryModel?>(null);

  @observable
  Observable<CreateVideoHistoryModel?> createBookmark = Observable<CreateVideoHistoryModel?>(null);

  @observable
  ObservableList<SearchedDataModel?> searchList = ObservableList<SearchedDataModel>();

  Future<void> onRegisterApiCall(BuildContext context) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }

    isLoading = true;
    try {
      final List<VideoCategoryModel> result = await _apiService.videoCategoryList();
      videocategory.clear();
      videocategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching videocategory: $e');
      videocategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onSubCategoryApiCall(String vid) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<VideoSubCategoryModel> result = await _apiService.videoSubCategoryList(vid);
      videosubcategory.clear();
      videosubcategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching videosubcategory: $e');
      videosubcategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onTopicCategoryApiCall(String subCatId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<VideoTopicCategoryModel> result = await _apiService.videoTopicCategoryList(subCatId);
      videotopiccategory.clear();
      videotopiccategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching videoctopiccategory: $e');
      videotopiccategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onTopicApiCall(String subCatId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<VideoTopicModel> result = await _apiService.videoTopicList(subCatId);
      videotopic.clear();
      videotopic.addAll(result);
    } catch (e) {
      debugPrint('Error fetching videoctopic: $e');
      videotopic.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onTopicDetailApiCall(String topicId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<VideoTopicDetailModel> result = await _apiService.videoTopicDetailList(topicId);
      videotopicdetail.clear();
      videotopicdetail.addAll(result);
    } catch (e) {
      debugPrint('Error fetching videoctopicdetail: $e');
      videotopicdetail.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onVideoChapterizationDetailApiCall(String videoId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoadingChapter = true;
    try {
      final List<VideoChapterizationListModel> result = await _apiService.videoChapterizationList(videoId);
      videoChapterizationList.clear();
      videoChapterizationList.addAll(result);
    } catch (e) {
      debugPrint('Error fetching videoChapterizationList: $e');
      videoChapterizationList.clear();
    } finally {
      isLoadingChapter = false;
    }
  }

  Future<void> onAllVideoTopicDetailApiCall(String topicId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    // isLoading = true;
    try {
      final GetAllVideoTopicDetailModel result = await _apiService.getAllVideoTopicDetailList(topicId);
      _setChapter(result);
    } catch (e) {
      debugPrint('Error fetching allvideotopicdetail: $e');
    } finally {
      // isLoading = false;
    }
  }

  Future<void> onVideoQualityDetailApiCall(String videoId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final GetVideoQualityDataModel result = await _apiService.getVideoQualityDetail(videoId);
      _setVideoData(result);
    } catch (e) {
      debugPrint('Error fetching videoQualityDetail: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCreateVideoHistoryApiCall(String contentId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    // isLoading = true;
    try {
      final CreateVideoHistoryModel result = await _apiService.createMarkAsCompleted(contentId);
      await Future.delayed(const Duration(milliseconds: 1));
      _setVideoHistory(result);
    } catch (e) {
      debugPrint('Error fetching create Video History: $e');
    } finally {
      // isLoading = false;
    }
  }

  Future<void> onCreateBookmarkContentApiCall(String contentId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    // isLoading = true;
    try {
      final result = await _apiService.createBookMarkContent(contentId);
      debugPrint('result of bookmark');
      // await Future.delayed(const Duration(milliseconds: 1));
      // _setBookMarkContent(result);
    } catch (e) {
      debugPrint('Error fetching create bookmark video content: $e');
    } finally {
      // isLoading = false;
    }
  }

  Future<void> onVideoProgressApiCall(String contentId, String pauseTime, int pageNo) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    // isLoading = true;
    try {
      final result = await _apiService.videoProgressTime(contentId,pauseTime,pageNo);
      debugPrint('result');
    } catch (e) {
      debugPrint('Error video progress: $e');
    } finally {
      isLoading = false;
    }
  }


  Future<void> onCategorySearchApiCall(String keyword) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<VideoCategoryModel> result = await _apiService.getSearchedData(keyword);
      videocategory.clear();
      videocategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching videoctopic: $e');
      videocategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onSubCategorySearchApiCall(String keyword, String catId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<VideoSubCategoryModel> result = await _apiService.getSearchedSubCategoryData(keyword, catId);
      videosubcategory.clear();
      videosubcategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching videoctopic: $e');
      videosubcategory.clear();
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
      final List<SearchedDataModel> result = await _apiService.getSearchedListData(keyword, type);
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
  void _setVideoHistory(CreateVideoHistoryModel value) {
    createvideohistory.value = value;
  }

  @action
  void _setBookMarkContent(CreateVideoHistoryModel value) {
    createBookmark.value = value;
  }

  @action
  void _setChapter(GetAllVideoTopicDetailModel value) {
    allvideotopicdetail.value = value;
  }
  @action
  void _setVideoData(GetVideoQualityDataModel value) {
    videoQualityDetail.value = value;
  }

}
