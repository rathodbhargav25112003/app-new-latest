// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$HomeStore on _HomeStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_HomeStore.isLoading', context: context);

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

  late final _$zoomlivemodelAtom =
      Atom(name: '_HomeStore.zoomlivemodel', context: context);

  @override
  Observable<ZoomLiveModel?> get zoomlivemodel {
    _$zoomlivemodelAtom.reportRead();
    return super.zoomlivemodel;
  }

  @override
  set zoomlivemodel(Observable<ZoomLiveModel?> value) {
    _$zoomlivemodelAtom.reportWrite(value, super.zoomlivemodel, () {
      super.zoomlivemodel = value;
    });
  }

  late final _$featuredContentAtom =
      Atom(name: '_HomeStore.featuredContent', context: context);

  @override
  Observable<FeaturedListModel?> get featuredContent {
    _$featuredContentAtom.reportRead();
    return super.featuredContent;
  }

  @override
  set featuredContent(Observable<FeaturedListModel?> value) {
    _$featuredContentAtom.reportWrite(value, super.featuredContent, () {
      super.featuredContent = value;
    });
  }

  late final _$blogsContentAtom =
      Atom(name: '_HomeStore.blogsContent', context: context);

  @override
  Observable<GetBlogsListModel?> get blogsContent {
    _$blogsContentAtom.reportRead();
    return super.blogsContent;
  }

  @override
  set blogsContent(Observable<GetBlogsListModel?> value) {
    _$blogsContentAtom.reportWrite(value, super.blogsContent, () {
      super.blogsContent = value;
    });
  }

  late final _$testimonialContentAtom =
      Atom(name: '_HomeStore.testimonialContent', context: context);

  @override
  Observable<GetTestimonialListModel?> get testimonialContent {
    _$testimonialContentAtom.reportRead();
    return super.testimonialContent;
  }

  @override
  set testimonialContent(Observable<GetTestimonialListModel?> value) {
    _$testimonialContentAtom.reportWrite(value, super.testimonialContent, () {
      super.testimonialContent = value;
    });
  }

  late final _$getDeclarationAtom =
      Atom(name: '_HomeStore.getDeclaration', context: context);

  @override
  GetDeclaration? get getDeclaration {
    _$getDeclarationAtom.reportRead();
    return super.getDeclaration;
  }

  @override
  set getDeclaration(GetDeclaration? value) {
    _$getDeclarationAtom.reportWrite(value, super.getDeclaration, () {
      super.getDeclaration = value;
    });
  }

  late final _$userDetailsAtom =
      Atom(name: '_HomeStore.userDetails', context: context);

  @override
  Observable<GetUserDetailsModel?> get userDetails {
    _$userDetailsAtom.reportRead();
    return super.userDetails;
  }

  @override
  set userDetails(Observable<GetUserDetailsModel?> value) {
    _$userDetailsAtom.reportWrite(value, super.userDetails, () {
      super.userDetails = value;
    });
  }

  late final _$progressDetailsAtom =
      Atom(name: '_HomeStore.progressDetails', context: context);

  @override
  Observable<ProgressDetailsModel?> get progressDetails {
    _$progressDetailsAtom.reportRead();
    return super.progressDetails;
  }

  @override
  set progressDetails(Observable<ProgressDetailsModel?> value) {
    _$progressDetailsAtom.reportWrite(value, super.progressDetails, () {
      super.progressDetails = value;
    });
  }

  late final _$mockTestDetailsAtom =
      Atom(name: '_HomeStore.mockTestDetails', context: context);

  @override
  Observable<GetMockTestDetailsModel?> get mockTestDetails {
    _$mockTestDetailsAtom.reportRead();
    return super.mockTestDetails;
  }

  @override
  set mockTestDetails(Observable<GetMockTestDetailsModel?> value) {
    _$mockTestDetailsAtom.reportWrite(value, super.mockTestDetails, () {
      super.mockTestDetails = value;
    });
  }

  late final _$updateUserDetailsAtom =
      Atom(name: '_HomeStore.updateUserDetails', context: context);

  @override
  Observable<UpdateUserProfileModel?> get updateUserDetails {
    _$updateUserDetailsAtom.reportRead();
    return super.updateUserDetails;
  }

  @override
  set updateUserDetails(Observable<UpdateUserProfileModel?> value) {
    _$updateUserDetailsAtom.reportWrite(value, super.updateUserDetails, () {
      super.updateUserDetails = value;
    });
  }

  late final _$createTestimonialAtom =
      Atom(name: '_HomeStore.createTestimonial', context: context);

  @override
  Observable<CreateTestimonialModel?> get createTestimonial {
    _$createTestimonialAtom.reportRead();
    return super.createTestimonial;
  }

  @override
  set createTestimonial(Observable<CreateTestimonialModel?> value) {
    _$createTestimonialAtom.reportWrite(value, super.createTestimonial, () {
      super.createTestimonial = value;
    });
  }

  late final _$offerBannersAtom =
      Atom(name: '_HomeStore.offerBanners', context: context);

  @override
  Observable<GetOffersModel?> get offerBanners {
    _$offerBannersAtom.reportRead();
    return super.offerBanners;
  }

  @override
  set offerBanners(Observable<GetOffersModel?> value) {
    _$offerBannersAtom.reportWrite(value, super.offerBanners, () {
      super.offerBanners = value;
    });
  }

  late final _$createVideoNoteHistoryAtom =
      Atom(name: '_HomeStore.createVideoNoteHistory', context: context);

  @override
  Observable<CreateVideoNoteHistoryModel?> get createVideoNoteHistory {
    _$createVideoNoteHistoryAtom.reportRead();
    return super.createVideoNoteHistory;
  }

  @override
  set createVideoNoteHistory(Observable<CreateVideoNoteHistoryModel?> value) {
    _$createVideoNoteHistoryAtom
        .reportWrite(value, super.createVideoNoteHistory, () {
      super.createVideoNoteHistory = value;
    });
  }

  late final _$deleteDataAtom =
      Atom(name: '_HomeStore.deleteData', context: context);

  @override
  Observable<DeleteAccountModel?> get deleteData {
    _$deleteDataAtom.reportRead();
    return super.deleteData;
  }

  @override
  set deleteData(Observable<DeleteAccountModel?> value) {
    _$deleteDataAtom.reportWrite(value, super.deleteData, () {
      super.deleteData = value;
    });
  }

  late final _$getNotificationListAtom =
      Atom(name: '_HomeStore.getNotificationList', context: context);

  @override
  ObservableList<NotificationListModel?> get getNotificationList {
    _$getNotificationListAtom.reportRead();
    return super.getNotificationList;
  }

  @override
  set getNotificationList(ObservableList<NotificationListModel?> value) {
    _$getNotificationListAtom.reportWrite(value, super.getNotificationList, () {
      super.getNotificationList = value;
    });
  }

  late final _$globalSearchListAtom =
      Atom(name: '_HomeStore.globalSearchList', context: context);

  @override
  ObservableList<GlobalSearchDataModel?> get globalSearchList {
    _$globalSearchListAtom.reportRead();
    return super.globalSearchList;
  }

  @override
  set globalSearchList(ObservableList<GlobalSearchDataModel?> value) {
    _$globalSearchListAtom.reportWrite(value, super.globalSearchList, () {
      super.globalSearchList = value;
    });
  }

  late final _$getBlogsListDataAtom =
      Atom(name: '_HomeStore.getBlogsListData', context: context);

  @override
  ObservableList<GetBlogsListModel?> get getBlogsListData {
    _$getBlogsListDataAtom.reportRead();
    return super.getBlogsListData;
  }

  @override
  set getBlogsListData(ObservableList<GetBlogsListModel?> value) {
    _$getBlogsListDataAtom.reportWrite(value, super.getBlogsListData, () {
      super.getBlogsListData = value;
    });
  }

  late final _$getContinueListDataAtom =
      Atom(name: '_HomeStore.getContinueListData', context: context);

  @override
  ObservableList<ContinueWatchingModel?> get getContinueListData {
    _$getContinueListDataAtom.reportRead();
    return super.getContinueListData;
  }

  @override
  set getContinueListData(ObservableList<ContinueWatchingModel?> value) {
    _$getContinueListDataAtom.reportWrite(value, super.getContinueListData, () {
      super.getContinueListData = value;
    });
  }

  late final _$getHomeListDataAtom =
      Atom(name: '_HomeStore.getHomeListData', context: context);

  @override
  ObservableList<HomePageWatchingModel?> get getHomeListData {
    _$getHomeListDataAtom.reportRead();
    return super.getHomeListData;
  }

  @override
  set getHomeListData(ObservableList<HomePageWatchingModel?> value) {
    _$getHomeListDataAtom.reportWrite(value, super.getHomeListData, () {
      super.getHomeListData = value;
    });
  }

  late final _$getBlogDetailsDataAtom =
      Atom(name: '_HomeStore.getBlogDetailsData', context: context);

  @override
  Observable<GetBlogDetailsModel?> get getBlogDetailsData {
    _$getBlogDetailsDataAtom.reportRead();
    return super.getBlogDetailsData;
  }

  @override
  set getBlogDetailsData(Observable<GetBlogDetailsModel?> value) {
    _$getBlogDetailsDataAtom.reportWrite(value, super.getBlogDetailsData, () {
      super.getBlogDetailsData = value;
    });
  }

  late final _$getTestimonialDataAtom =
      Atom(name: '_HomeStore.getTestimonialData', context: context);

  @override
  ObservableList<GetTestimonialListModel?> get getTestimonialData {
    _$getTestimonialDataAtom.reportRead();
    return super.getTestimonialData;
  }

  @override
  set getTestimonialData(ObservableList<GetTestimonialListModel?> value) {
    _$getTestimonialDataAtom.reportWrite(value, super.getTestimonialData, () {
      super.getTestimonialData = value;
    });
  }

  late final _$_HomeStoreActionController =
      ActionController(name: '_HomeStore', context: context);

  @override
  void _setFeaturedContent(FeaturedListModel value) {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore._setFeaturedContent');
    try {
      return super._setFeaturedContent(value);
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setUserDetails(GetUserDetailsModel value) {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore._setUserDetails');
    try {
      return super._setUserDetails(value);
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setProgressDetails(ProgressDetailsModel value) {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore._setProgressDetails');
    try {
      return super._setProgressDetails(value);
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setMockTestDetails(GetMockTestDetailsModel value) {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore._setMockTestDetails');
    try {
      return super._setMockTestDetails(value);
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setLiveDetails(ZoomLiveModel value) {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore._setLiveDetails');
    try {
      return super._setLiveDetails(value);
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setOfferDetails(GetOffersModel value) {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore._setOfferDetails');
    try {
      return super._setOfferDetails(value);
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setVideoNoteHistoryDetails(CreateVideoNoteHistoryModel value) {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore._setVideoNoteHistoryDetails');
    try {
      return super._setVideoNoteHistoryDetails(value);
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setBlogDetails(GetBlogDetailsModel value) {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore._setBlogDetails');
    try {
      return super._setBlogDetails(value);
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _deteleAccountDetails(DeleteAccountModel value) {
    final _$actionInfo = _$_HomeStoreActionController.startAction(
        name: '_HomeStore._deteleAccountDetails');
    try {
      return super._deteleAccountDetails(value);
    } finally {
      _$_HomeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
zoomlivemodel: ${zoomlivemodel},
featuredContent: ${featuredContent},
blogsContent: ${blogsContent},
testimonialContent: ${testimonialContent},
getDeclaration: ${getDeclaration},
userDetails: ${userDetails},
progressDetails: ${progressDetails},
mockTestDetails: ${mockTestDetails},
updateUserDetails: ${updateUserDetails},
createTestimonial: ${createTestimonial},
offerBanners: ${offerBanners},
createVideoNoteHistory: ${createVideoNoteHistory},
deleteData: ${deleteData},
getNotificationList: ${getNotificationList},
globalSearchList: ${globalSearchList},
getBlogsListData: ${getBlogsListData},
getContinueListData: ${getContinueListData},
getHomeListData: ${getHomeListData},
getBlogDetailsData: ${getBlogDetailsData},
getTestimonialData: ${getTestimonialData}
    ''';
  }
}
