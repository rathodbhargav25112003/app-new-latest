// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_category_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$VideoCategoryStore on _VideoCategoryStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_VideoCategoryStore.isLoading', context: context);

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

  late final _$isLoadingChapterAtom =
      Atom(name: '_VideoCategoryStore.isLoadingChapter', context: context);

  @override
  bool get isLoadingChapter {
    _$isLoadingChapterAtom.reportRead();
    return super.isLoadingChapter;
  }

  @override
  set isLoadingChapter(bool value) {
    _$isLoadingChapterAtom.reportWrite(value, super.isLoadingChapter, () {
      super.isLoadingChapter = value;
    });
  }

  late final _$filterValueAtom =
      Atom(name: '_VideoCategoryStore.filterValue', context: context);

  @override
  String get filterValue {
    _$filterValueAtom.reportRead();
    return super.filterValue;
  }

  @override
  set filterValue(String value) {
    _$filterValueAtom.reportWrite(value, super.filterValue, () {
      super.filterValue = value;
    });
  }

  late final _$downloadProgressAtom =
      Atom(name: '_VideoCategoryStore.downloadProgress', context: context);

  @override
  num get downloadProgress {
    _$downloadProgressAtom.reportRead();
    return super.downloadProgress;
  }

  @override
  set downloadProgress(num value) {
    _$downloadProgressAtom.reportWrite(value, super.downloadProgress, () {
      super.downloadProgress = value;
    });
  }

  late final _$isVideoDownloadingAtom =
      Atom(name: '_VideoCategoryStore.isVideoDownloading', context: context);

  @override
  bool get isVideoDownloading {
    _$isVideoDownloadingAtom.reportRead();
    return super.isVideoDownloading;
  }

  @override
  set isVideoDownloading(bool value) {
    _$isVideoDownloadingAtom.reportWrite(value, super.isVideoDownloading, () {
      super.isVideoDownloading = value;
    });
  }

  late final _$downloadProgressMapAtom =
      Atom(name: '_VideoCategoryStore.downloadProgressMap', context: context);

  @override
  ObservableMap<String, int> get downloadProgressMap {
    _$downloadProgressMapAtom.reportRead();
    return super.downloadProgressMap;
  }

  @override
  set downloadProgressMap(ObservableMap<String, int> value) {
    _$downloadProgressMapAtom.reportWrite(value, super.downloadProgressMap, () {
      super.downloadProgressMap = value;
    });
  }

  late final _$downloadingVideosAtom =
      Atom(name: '_VideoCategoryStore.downloadingVideos', context: context);

  @override
  ObservableSet<String> get downloadingVideos {
    _$downloadingVideosAtom.reportRead();
    return super.downloadingVideos;
  }

  @override
  set downloadingVideos(ObservableSet<String> value) {
    _$downloadingVideosAtom.reportWrite(value, super.downloadingVideos, () {
      super.downloadingVideos = value;
    });
  }

  late final _$downloadedVideoIdsAtom =
      Atom(name: '_VideoCategoryStore.downloadedVideoIds', context: context);

  @override
  ObservableSet<String> get downloadedVideoIds {
    _$downloadedVideoIdsAtom.reportRead();
    return super.downloadedVideoIds;
  }

  @override
  set downloadedVideoIds(ObservableSet<String> value) {
    _$downloadedVideoIdsAtom.reportWrite(value, super.downloadedVideoIds, () {
      super.downloadedVideoIds = value;
    });
  }

  late final _$videocategoryAtom =
      Atom(name: '_VideoCategoryStore.videocategory', context: context);

  @override
  ObservableList<VideoCategoryModel?> get videocategory {
    _$videocategoryAtom.reportRead();
    return super.videocategory;
  }

  @override
  set videocategory(ObservableList<VideoCategoryModel?> value) {
    _$videocategoryAtom.reportWrite(value, super.videocategory, () {
      super.videocategory = value;
    });
  }

  late final _$videosubcategoryAtom =
      Atom(name: '_VideoCategoryStore.videosubcategory', context: context);

  @override
  ObservableList<VideoSubCategoryModel?> get videosubcategory {
    _$videosubcategoryAtom.reportRead();
    return super.videosubcategory;
  }

  @override
  set videosubcategory(ObservableList<VideoSubCategoryModel?> value) {
    _$videosubcategoryAtom.reportWrite(value, super.videosubcategory, () {
      super.videosubcategory = value;
    });
  }

  late final _$videotopicAtom =
      Atom(name: '_VideoCategoryStore.videotopic', context: context);

  @override
  ObservableList<VideoTopicModel?> get videotopic {
    _$videotopicAtom.reportRead();
    return super.videotopic;
  }

  @override
  set videotopic(ObservableList<VideoTopicModel?> value) {
    _$videotopicAtom.reportWrite(value, super.videotopic, () {
      super.videotopic = value;
    });
  }

  late final _$videotopiccategoryAtom =
      Atom(name: '_VideoCategoryStore.videotopiccategory', context: context);

  @override
  ObservableList<VideoTopicCategoryModel?> get videotopiccategory {
    _$videotopiccategoryAtom.reportRead();
    return super.videotopiccategory;
  }

  @override
  set videotopiccategory(ObservableList<VideoTopicCategoryModel?> value) {
    _$videotopiccategoryAtom.reportWrite(value, super.videotopiccategory, () {
      super.videotopiccategory = value;
    });
  }

  late final _$videotopicdetailAtom =
      Atom(name: '_VideoCategoryStore.videotopicdetail', context: context);

  @override
  ObservableList<VideoTopicDetailModel?> get videotopicdetail {
    _$videotopicdetailAtom.reportRead();
    return super.videotopicdetail;
  }

  @override
  set videotopicdetail(ObservableList<VideoTopicDetailModel?> value) {
    _$videotopicdetailAtom.reportWrite(value, super.videotopicdetail, () {
      super.videotopicdetail = value;
    });
  }

  late final _$videoChapterizationListAtom = Atom(
      name: '_VideoCategoryStore.videoChapterizationList', context: context);

  @override
  ObservableList<VideoChapterizationListModel?> get videoChapterizationList {
    _$videoChapterizationListAtom.reportRead();
    return super.videoChapterizationList;
  }

  @override
  set videoChapterizationList(
      ObservableList<VideoChapterizationListModel?> value) {
    _$videoChapterizationListAtom
        .reportWrite(value, super.videoChapterizationList, () {
      super.videoChapterizationList = value;
    });
  }

  late final _$allvideotopicdetailAtom =
      Atom(name: '_VideoCategoryStore.allvideotopicdetail', context: context);

  @override
  Observable<GetAllVideoTopicDetailModel?> get allvideotopicdetail {
    _$allvideotopicdetailAtom.reportRead();
    return super.allvideotopicdetail;
  }

  @override
  set allvideotopicdetail(Observable<GetAllVideoTopicDetailModel?> value) {
    _$allvideotopicdetailAtom.reportWrite(value, super.allvideotopicdetail, () {
      super.allvideotopicdetail = value;
    });
  }

  late final _$videoQualityDetailAtom =
      Atom(name: '_VideoCategoryStore.videoQualityDetail', context: context);

  @override
  Observable<GetVideoQualityDataModel?> get videoQualityDetail {
    _$videoQualityDetailAtom.reportRead();
    return super.videoQualityDetail;
  }

  @override
  set videoQualityDetail(Observable<GetVideoQualityDataModel?> value) {
    _$videoQualityDetailAtom.reportWrite(value, super.videoQualityDetail, () {
      super.videoQualityDetail = value;
    });
  }

  late final _$createvideohistoryAtom =
      Atom(name: '_VideoCategoryStore.createvideohistory', context: context);

  @override
  Observable<CreateVideoHistoryModel?> get createvideohistory {
    _$createvideohistoryAtom.reportRead();
    return super.createvideohistory;
  }

  @override
  set createvideohistory(Observable<CreateVideoHistoryModel?> value) {
    _$createvideohistoryAtom.reportWrite(value, super.createvideohistory, () {
      super.createvideohistory = value;
    });
  }

  late final _$createBookmarkAtom =
      Atom(name: '_VideoCategoryStore.createBookmark', context: context);

  @override
  Observable<CreateVideoHistoryModel?> get createBookmark {
    _$createBookmarkAtom.reportRead();
    return super.createBookmark;
  }

  @override
  set createBookmark(Observable<CreateVideoHistoryModel?> value) {
    _$createBookmarkAtom.reportWrite(value, super.createBookmark, () {
      super.createBookmark = value;
    });
  }

  late final _$searchListAtom =
      Atom(name: '_VideoCategoryStore.searchList', context: context);

  @override
  ObservableList<SearchedDataModel?> get searchList {
    _$searchListAtom.reportRead();
    return super.searchList;
  }

  @override
  set searchList(ObservableList<SearchedDataModel?> value) {
    _$searchListAtom.reportWrite(value, super.searchList, () {
      super.searchList = value;
    });
  }

  late final _$_VideoCategoryStoreActionController =
      ActionController(name: '_VideoCategoryStore', context: context);

  @override
  void setFilterValue(String value) {
    final _$actionInfo = _$_VideoCategoryStoreActionController.startAction(
        name: '_VideoCategoryStore.setFilterValue');
    try {
      return super.setFilterValue(value);
    } finally {
      _$_VideoCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateProgress(double progress) {
    final _$actionInfo = _$_VideoCategoryStoreActionController.startAction(
        name: '_VideoCategoryStore.updateProgress');
    try {
      return super.updateProgress(progress);
    } finally {
      _$_VideoCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void startDownload(String titleId) {
    final _$actionInfo = _$_VideoCategoryStoreActionController.startAction(
        name: '_VideoCategoryStore.startDownload');
    try {
      return super.startDownload(titleId);
    } finally {
      _$_VideoCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void completeDownload(String titleId) {
    final _$actionInfo = _$_VideoCategoryStoreActionController.startAction(
        name: '_VideoCategoryStore.completeDownload');
    try {
      return super.completeDownload(titleId);
    } finally {
      _$_VideoCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void cancelDownload(String titleId) {
    final _$actionInfo = _$_VideoCategoryStoreActionController.startAction(
        name: '_VideoCategoryStore.cancelDownload');
    try {
      return super.cancelDownload(titleId);
    } finally {
      _$_VideoCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  Future<void> loadDownloadedIds(List<String> titleIds) {
    return _$loadDownloadedIdsAsyncAction
        .run(() => super.loadDownloadedIds(titleIds));
  }

  late final _$loadDownloadedIdsAsyncAction = AsyncAction(
      '_VideoCategoryStore.loadDownloadedIds',
      context: context);

  @override
  void markDownloaded(String titleId) {
    final _$actionInfo = _$_VideoCategoryStoreActionController.startAction(
        name: '_VideoCategoryStore.markDownloaded');
    try {
      return super.markDownloaded(titleId);
    } finally {
      _$_VideoCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void markNotDownloaded(String titleId) {
    final _$actionInfo = _$_VideoCategoryStoreActionController.startAction(
        name: '_VideoCategoryStore.markNotDownloaded');
    try {
      return super.markNotDownloaded(titleId);
    } finally {
      _$_VideoCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDownloadProgress(String titleId, int progress) {
    final _$actionInfo = _$_VideoCategoryStoreActionController.startAction(
        name: '_VideoCategoryStore.setDownloadProgress');
    try {
      return super.setDownloadProgress(titleId, progress);
    } finally {
      _$_VideoCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setVideoHistory(CreateVideoHistoryModel value) {
    final _$actionInfo = _$_VideoCategoryStoreActionController.startAction(
        name: '_VideoCategoryStore._setVideoHistory');
    try {
      return super._setVideoHistory(value);
    } finally {
      _$_VideoCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setBookMarkContent(CreateVideoHistoryModel value) {
    final _$actionInfo = _$_VideoCategoryStoreActionController.startAction(
        name: '_VideoCategoryStore._setBookMarkContent');
    try {
      return super._setBookMarkContent(value);
    } finally {
      _$_VideoCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setChapter(GetAllVideoTopicDetailModel value) {
    final _$actionInfo = _$_VideoCategoryStoreActionController.startAction(
        name: '_VideoCategoryStore._setChapter');
    try {
      return super._setChapter(value);
    } finally {
      _$_VideoCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setVideoData(GetVideoQualityDataModel value) {
    final _$actionInfo = _$_VideoCategoryStoreActionController.startAction(
        name: '_VideoCategoryStore._setVideoData');
    try {
      return super._setVideoData(value);
    } finally {
      _$_VideoCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
isLoadingChapter: ${isLoadingChapter},
filterValue: ${filterValue},
downloadProgress: ${downloadProgress},
isVideoDownloading: ${isVideoDownloading},
downloadProgressMap: ${downloadProgressMap},
downloadingVideos: ${downloadingVideos},
downloadedVideoIds: ${downloadedVideoIds},
videocategory: ${videocategory},
videosubcategory: ${videosubcategory},
videotopic: ${videotopic},
videotopiccategory: ${videotopiccategory},
videotopicdetail: ${videotopicdetail},
videoChapterizationList: ${videoChapterizationList},
allvideotopicdetail: ${allvideotopicdetail},
videoQualityDetail: ${videoQualityDetail},
createvideohistory: ${createvideohistory},
createBookmark: ${createBookmark},
searchList: ${searchList}
    ''';
  }
}
