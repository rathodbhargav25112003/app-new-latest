// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_category_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$NotesCategoryStore on _NotesCategoryStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_NotesCategoryStore.isLoading', context: context);

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

  late final _$isLoadingAnnotationAtom =
      Atom(name: '_NotesCategoryStore.isLoadingAnnotation', context: context);

  @override
  bool get isLoadingAnnotation {
    _$isLoadingAnnotationAtom.reportRead();
    return super.isLoadingAnnotation;
  }

  @override
  set isLoadingAnnotation(bool value) {
    _$isLoadingAnnotationAtom.reportWrite(value, super.isLoadingAnnotation, () {
      super.isLoadingAnnotation = value;
    });
  }

  late final _$isLoadingPdfAtom =
      Atom(name: '_NotesCategoryStore.isLoadingPdf', context: context);

  @override
  bool get isLoadingPdf {
    _$isLoadingPdfAtom.reportRead();
    return super.isLoadingPdf;
  }

  @override
  set isLoadingPdf(bool value) {
    _$isLoadingPdfAtom.reportWrite(value, super.isLoadingPdf, () {
      super.isLoadingPdf = value;
    });
  }

  late final _$filterValueAtom =
      Atom(name: '_NotesCategoryStore.filterValue', context: context);

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

  late final _$notescategoryAtom =
      Atom(name: '_NotesCategoryStore.notescategory', context: context);

  @override
  ObservableList<NotesCategoryModel?> get notescategory {
    _$notescategoryAtom.reportRead();
    return super.notescategory;
  }

  @override
  set notescategory(ObservableList<NotesCategoryModel?> value) {
    _$notescategoryAtom.reportWrite(value, super.notescategory, () {
      super.notescategory = value;
    });
  }

  late final _$notessubcategoryAtom =
      Atom(name: '_NotesCategoryStore.notessubcategory', context: context);

  @override
  ObservableList<NotesSubCategoryModel?> get notessubcategory {
    _$notessubcategoryAtom.reportRead();
    return super.notessubcategory;
  }

  @override
  set notessubcategory(ObservableList<NotesSubCategoryModel?> value) {
    _$notessubcategoryAtom.reportWrite(value, super.notessubcategory, () {
      super.notessubcategory = value;
    });
  }

  late final _$notestopicAtom =
      Atom(name: '_NotesCategoryStore.notestopic', context: context);

  @override
  ObservableList<NotesTopicModel?> get notestopic {
    _$notestopicAtom.reportRead();
    return super.notestopic;
  }

  @override
  set notestopic(ObservableList<NotesTopicModel?> value) {
    _$notestopicAtom.reportWrite(value, super.notestopic, () {
      super.notestopic = value;
    });
  }

  late final _$notestopiccategoryAtom =
      Atom(name: '_NotesCategoryStore.notestopiccategory', context: context);

  @override
  ObservableList<NotesTopicCategoryModel?> get notestopiccategory {
    _$notestopiccategoryAtom.reportRead();
    return super.notestopiccategory;
  }

  @override
  set notestopiccategory(ObservableList<NotesTopicCategoryModel?> value) {
    _$notestopiccategoryAtom.reportWrite(value, super.notestopiccategory, () {
      super.notestopiccategory = value;
    });
  }

  late final _$notestopicdetailAtom =
      Atom(name: '_NotesCategoryStore.notestopicdetail', context: context);

  @override
  Observable<NotesTopicDetailModel?> get notestopicdetail {
    _$notestopicdetailAtom.reportRead();
    return super.notestopicdetail;
  }

  @override
  set notestopicdetail(Observable<NotesTopicDetailModel?> value) {
    _$notestopicdetailAtom.reportWrite(value, super.notestopicdetail, () {
      super.notestopicdetail = value;
    });
  }

  late final _$searchListAtom =
      Atom(name: '_NotesCategoryStore.searchList', context: context);

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

  late final _$createAnnotationDataAtom =
      Atom(name: '_NotesCategoryStore.createAnnotationData', context: context);

  @override
  ObservableList<SearchedDataModel?> get createAnnotationData {
    _$createAnnotationDataAtom.reportRead();
    return super.createAnnotationData;
  }

  @override
  set createAnnotationData(ObservableList<SearchedDataModel?> value) {
    _$createAnnotationDataAtom.reportWrite(value, super.createAnnotationData,
        () {
      super.createAnnotationData = value;
    });
  }

  late final _$isNoteDownloadingAtom =
      Atom(name: '_NotesCategoryStore.isNoteDownloading', context: context);

  @override
  bool get isNoteDownloading {
    _$isNoteDownloadingAtom.reportRead();
    return super.isNoteDownloading;
  }

  @override
  set isNoteDownloading(bool value) {
    _$isNoteDownloadingAtom.reportWrite(value, super.isNoteDownloading, () {
      super.isNoteDownloading = value;
    });
  }

  late final _$downloadingNotesAtom =
      Atom(name: '_NotesCategoryStore.downloadingNotes', context: context);

  @override
  ObservableSet<String> get downloadingNotes {
    _$downloadingNotesAtom.reportRead();
    return super.downloadingNotes;
  }

  @override
  set downloadingNotes(ObservableSet<String> value) {
    _$downloadingNotesAtom.reportWrite(value, super.downloadingNotes, () {
      super.downloadingNotes = value;
    });
  }

  late final _$_NotesCategoryStoreActionController =
      ActionController(name: '_NotesCategoryStore', context: context);

  @override
  void setFilterValue(String value) {
    final _$actionInfo = _$_NotesCategoryStoreActionController.startAction(
        name: '_NotesCategoryStore.setFilterValue');
    try {
      return super.setFilterValue(value);
    } finally {
      _$_NotesCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void startDownload(String titleId) {
    final _$actionInfo = _$_NotesCategoryStoreActionController.startAction(
        name: '_NotesCategoryStore.startDownload');
    try {
      return super.startDownload(titleId);
    } finally {
      _$_NotesCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void completeDownload(String titleId) {
    final _$actionInfo = _$_NotesCategoryStoreActionController.startAction(
        name: '_NotesCategoryStore.completeDownload');
    try {
      return super.completeDownload(titleId);
    } finally {
      _$_NotesCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void cancelDownload(String titleId) {
    final _$actionInfo = _$_NotesCategoryStoreActionController.startAction(
        name: '_NotesCategoryStore.cancelDownload');
    try {
      return super.cancelDownload(titleId);
    } finally {
      _$_NotesCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setPdfPageCount(String pdf, int pageCount) {
    final _$actionInfo = _$_NotesCategoryStoreActionController.startAction(
        name: '_NotesCategoryStore._setPdfPageCount');
    try {
      return super._setPdfPageCount(pdf, pageCount);
    } finally {
      _$_NotesCategoryStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
isLoadingAnnotation: ${isLoadingAnnotation},
isLoadingPdf: ${isLoadingPdf},
filterValue: ${filterValue},
notescategory: ${notescategory},
notessubcategory: ${notessubcategory},
notestopic: ${notestopic},
notestopiccategory: ${notestopiccategory},
notestopicdetail: ${notestopicdetail},
searchList: ${searchList},
createAnnotationData: ${createAnnotationData},
isNoteDownloading: ${isNoteDownloading},
downloadingNotes: ${downloadingNotes}
    ''';
  }
}
