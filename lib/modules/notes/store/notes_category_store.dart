import 'package:mobx/mobx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../../app/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../../../helpers/constants.dart';
import '../../../api_service/api_service.dart';
import '../../../models/notes_topic_model.dart';
import '../../../models/searched_data_model.dart';
import '../../../models/notes_category_model.dart';
import '../../../models/notes_subcategory_model.dart';
import '../../../models/notes_topic_detail_model.dart';
import 'package:shusruta_lms/models/notes_topic_category_model.dart';
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';



part 'notes_category_store.g.dart';

class NotesCategoryStore =  _NotesCategoryStore with _$NotesCategoryStore;

abstract class _NotesCategoryStore extends InternetStore with Store {
  final ApiService _apiService = ApiService();

  @observable
  bool isLoading = false;

  @observable
  bool isLoadingAnnotation = false;

  @observable
  bool isLoadingPdf = false;

  @observable
  String filterValue = 'View all';

  ObservableMap<String, int> pdfPageCounts = ObservableMap<String, int>();

  @action
  void setFilterValue(String value) {
    filterValue = value;
  }

  @observable
  ObservableList<NotesCategoryModel?> notescategory = ObservableList<NotesCategoryModel>();

  @observable
  ObservableList<NotesSubCategoryModel?> notessubcategory = ObservableList<NotesSubCategoryModel>();

  @observable
  ObservableList<NotesTopicModel?> notestopic = ObservableList<NotesTopicModel>();

  @observable
  ObservableList<NotesTopicCategoryModel?> notestopiccategory = ObservableList<NotesTopicCategoryModel>();

  @observable
  Observable<NotesTopicDetailModel?> notestopicdetail = Observable<NotesTopicDetailModel?>(null);

  @observable
  ObservableList<SearchedDataModel?> searchList = ObservableList<SearchedDataModel>();

  @observable
  ObservableList<SearchedDataModel?> createAnnotationData = ObservableList<SearchedDataModel>();

  @observable
  bool isNoteDownloading = false;

  @observable
  ObservableSet<String> downloadingNotes = ObservableSet<String>();

  bool isDownloading(String titleId) => downloadingNotes.contains(titleId);

  @action
  void startDownload(String titleId) {
    isNoteDownloading = true;
    downloadingNotes.add(titleId);
  }

  @action
  void completeDownload(String titleId) {
    isNoteDownloading = false;
    downloadingNotes.remove(titleId);
  }

  @action
  void cancelDownload(String titleId) {
    downloadingNotes.remove(titleId);
  }

  Future<void> onRegisterApiCall(BuildContext context) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }

    isLoading = true;
    try {
      final List<NotesCategoryModel> result = await _apiService.notesCategoryList();
      notescategory.clear();
      notescategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      notescategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onSubCategoryApiCall(String notesid) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<NotesSubCategoryModel> result = await _apiService.notesSubCategoryList(notesid);
      notessubcategory.clear();
      notessubcategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      notessubcategory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onTopicCategoryApiCall(String subCatId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<NotesTopicCategoryModel> result = await _apiService.notesTopicCategoryList(subCatId);
      notestopiccategory.clear();
      notestopiccategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      notestopiccategory.clear();
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
      final List<NotesTopicModel> result = await _apiService.notesTopicList(subCatId);
      notestopic.clear();
      notestopic.addAll(result);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      notestopic.clear();
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
      final NotesTopicDetailModel result = await _apiService.notesTopicDetailList(topicId);
      await Future.delayed(const Duration(milliseconds: 1));
      notestopicdetail.value = result;
    } catch (e) {
      debugPrint('Error fetching notesTopic detail: $e');
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
      final List<NotesCategoryModel> result = await _apiService.getSearchedNotesData(keyword);
      notescategory.clear();
      notescategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching videoctopic: $e');
      notescategory.clear();
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
      final List<NotesSubCategoryModel> result = await _apiService.getSearchedSubCategoryNotesData(keyword, catId);
      notessubcategory.clear();
      notessubcategory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching videoctopic: $e');
      notessubcategory.clear();
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

  Future<void> onCreateNoteAnnotation(Map<String, dynamic> payload) async {
    isLoadingAnnotation = true;
    try {
      await _apiService.onCreateAnnotation(payload);
      debugPrint('result annotation success');
    } catch (e) {
      debugPrint('Error adding notes annotation: $e');
    } finally {
      isLoadingAnnotation = false;
    }
  }

  Future<void> fetchPdfPageCount(String pdf) async {
    if (pdf.isEmpty || pdfPageCounts.containsKey(pdf)) {
      return;
    }
    isLoadingPdf = true;
    try {
      // Build a downloadable URL. If 'pdf' isn't an absolute URL, fall back to API scheme used elsewhere: pdfBaseUrl + getPDF/<filename>
      String resolvedUrl = pdf;
      if (!pdf.startsWith('http')) {
        final String fileSegment = pdf.contains('/')
            ? pdf.substring(pdf.lastIndexOf('/'))
            : '/$pdf';
        resolvedUrl = pdfBaseUrl + 'getPDF' + fileSegment;
      }

      final http.Response resp = await http.get(Uri.parse(resolvedUrl));
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        final PdfDocument document = PdfDocument(inputBytes: resp.bodyBytes);
        final int pageCount = document.pages.count;
        document.dispose();
        _setPdfPageCount(pdf, pageCount);
      } else {
        _setPdfPageCount(pdf, 0);
      }
    } catch (e) {
      debugPrint('Error fetching PDF: $e');
    } finally {
      isLoadingPdf = false;
    }
  }

  @action
  void _setPdfPageCount(String pdf, int pageCount) {
    debugPrint('In fetchPdfPageCount - Key: $pdf');
    debugPrint('In ListView.builder - Key: $pdf');

    debugPrint('Setting page count for $pdf: $pageCount');
    pdfPageCounts[pdf] = pageCount;
  }

  Future<void> saveNoteProgress(String? titleId, int? pageNo) async {
    if (titleId == null || pageNo == null) return;
    await _apiService.noteProgressTime(titleId, pageNo);
  }

}
