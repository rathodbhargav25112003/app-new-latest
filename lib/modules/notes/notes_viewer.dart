import 'dart:io';
import 'dart:convert';
import 'dart:developer' show log;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/dbhelper.dart';
import 'package:nutrient_flutter/nutrient_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shusruta_lms/modules/notes/store/notes_category_store.dart';
import 'package:shusruta_lms/modules/new_exam_component/widget/loading_box.dart';

class NotesViewer extends StatefulWidget {
  final String pdfUrl;
  final String titleId;
  final int? initialPage;
  final bool isFromNormal;
  final void Function()? onAnnotationsChanged;
  final VoidCallback? onDocumentLoaded;
  final String? initialAnnotationJson;

  const NotesViewer({
    Key? key,
    required this.pdfUrl,
    required this.titleId,
    this.initialPage,
    this.isFromNormal = false,
    this.onAnnotationsChanged,
    this.onDocumentLoaded,
    this.initialAnnotationJson,
  }) : super(key: key);

  @override
  State<NotesViewer> createState() => NotesViewerState();
}

class NotesViewerState extends State<NotesViewer> {
  bool _loading = true;
  bool _error = false;
  String? _annotationJsonString; // Store raw Instant JSON string
  bool _saving = false;
  PdfDocument? _pdfController;
  bool _hasUnsavedChanges = false;
  String?
      _localPdfPath; // Will be set to local file path on iOS, or URL on Android
  bool _documentLoaded = false; // Set to true when PDF is loaded
  int? _currentPage;
  Uint8List? _pdfBytes;
  // Syncfusion controller for desktop platforms. This is only used on macOS/Windows.
  PdfViewerController? _sfPdfViewerController;
  // Annotation state — reserved for the future v3 overlay; currently
  // unused since Nutrient handles annotation editing natively.
  // ignore: unused_field
  final Map<int, List<dynamic>> _annotations = {};
  // ignore: unused_field
  final Color _annotationColor = Colors.red;

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  void resetUnsavedChanges() => setState(() => _hasUnsavedChanges = false);

  bool get canSave => !_loading && !_error && _localPdfPath != null;

  bool get isDocumentLoaded => _documentLoaded;

  // Function to sanitize Dart-style map string to valid JSON
  String? _sanitizeToJson(String? input) {
    if (input == null) return null;

    // Remove leading/trailing quotes if present
    if ((input.startsWith('"') && input.endsWith('"')) ||
        (input.startsWith("'") && input.endsWith("'"))) {
      input = input.substring(1, input.length - 1);
    }

    // If already valid JSON, return as is
    try {
      jsonDecode(input);
      return input;
    } catch (_) {}

    String sanitized = input;
    // Replace single quotes with double quotes
    sanitized = sanitized.replaceAll("'", '"');

    // Add double quotes around keys (works for flat and nested objects)
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'([,{"]\s*)([a-zA-Z0-9_]+)\s*:'),
      (match) => '${match[1]}"${match[2]}":',
    );

    // Add double quotes around string values (if not already quoted)
    sanitized = sanitized.replaceAllMapped(
      RegExp(r':\s*([^"{\[\d][^,}\]]*)'),
      (match) {
        String value = match[1]!.trim();
        // If value looks like a number, boolean, null, or already quoted, leave as is
        if (RegExp(r'^-?\d+(\.\d+)?').hasMatch(value) ||
            value == 'true' ||
            value == 'false' ||
            value == 'null' ||
            value.startsWith('"') ||
            value.startsWith('{') ||
            value.startsWith('[')) {
          return ': $value';
        }
        return ': "$value"';
      },
    );

    // Try to parse again, if fails, return null
    try {
      jsonDecode(sanitized);
      return sanitized;
    } catch (_) {
      return null;
    }
  }

  Future<String> _writeBytesToTempFile(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/temp_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  void initState() {
    super.initState();
    print('NotesViewerState initState');
    print('widget.initialPage: \\${widget.initialPage}');
    print('widget.pdfUrl: \\${widget.pdfUrl}');
    print('widget.titleId: \\${widget.titleId}');
    print('widget.isFromNormal: \\${widget.isFromNormal}');
    print('widget.onAnnotationsChanged: \\${widget.onAnnotationsChanged}');
    print('widget.onDocumentLoaded: \\${widget.onDocumentLoaded}');
    _currentPage = widget.initialPage;

    if (widget.initialAnnotationJson != null) {
      Uint8List? bytes;
      final sanitized = _sanitizeToJson(widget.initialAnnotationJson!);
      if (sanitized != null) {
        final map = jsonDecode(sanitized);
        log(map.toString());
        if (map != null &&
            map is Map &&
            map.containsKey('raw') &&
            map['raw'] != null) {
          bytes = base64Decode(map['raw']);
        } else {
          log("'raw' key missing or null in initialAnnotationJson map");
        }
      } else {
        log('Failed to sanitize initialAnnotationJson');
      }
      if (bytes != null) {
        _loading = true;
        _error = false;
        _documentLoaded = false;
        _writeBytesToTempFile(bytes).then((path) {
          setState(() {
            _localPdfPath = path;
            _loading = false;
            _documentLoaded = true;
          });
          print('_localPdfPath: \\$_localPdfPath');
        });
        return;
      }
    }
    _prepareDocument();
  }

  Future<String> _downloadPdfToLocal(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename =
        url.split('/').last.isNotEmpty ? url.split('/').last : 'document.pdf';
    final file = File('${dir.path}/$filename');
    if (await file.exists() && await file.length() > 100) {
      return file.path;
    }
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) throw Exception('Failed to download PDF');
    final bytes = <int>[];
    await for (var chunk in response) {
      bytes.addAll(chunk);
    }
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> _prepareDocument() async {
    setState(() {
      _loading = true;
      _error = false;
      _documentLoaded = false;
    });
    try {
      String path = widget.pdfUrl;
      if ((Platform.isIOS || Platform.isAndroid) && path.startsWith('http')) {
        path = await _downloadPdfToLocal(path);
      }
      final file = File(path);
      // print(
      //     'PDF file exists: \\${await file.exists()}, size: \\${await file.length()}');
      _localPdfPath = path;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _documentLoaded = true;
      });
      if (widget.onDocumentLoaded != null) widget.onDocumentLoaded!();
    } catch (e) {
      print(e);
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
        _documentLoaded = false;
      });
    }
  }

  Future<void> _saveAnnotations(String annotationJsonString) async {
    // Use SQLite via DbHelper
    await DbHelper().saveAnnotationJson(widget.titleId, annotationJsonString);

    // Also store annotation remotely via API
    final store = Provider.of<NotesCategoryStore>(context, listen: false);
    try {
      Map<String, dynamic> annotationMap;
      try {
        annotationMap = jsonDecode(annotationJsonString);
      } catch (e) {
        annotationMap = {'raw': annotationJsonString};
      }
      await store.onCreateNoteAnnotation({
        'content_id': widget.titleId,
        'annotation': annotationMap,
      });
    } catch (e) {
      debugPrint('Error sending annotation to API: '
          '[31m$e[0m');
    }
  }

  Future<void> saveLastPageToBackend() async {
    if (_currentPage != null && widget.titleId != null) {
      final store = Provider.of<NotesCategoryStore>(context, listen: false);
      await store.saveNoteProgress(widget.titleId, _currentPage);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _exportAndSaveAnnotations() async {
    showLoadingDialog(context);
    print(
        'Save/export: _loading=$_loading, _localPdfPath=$_localPdfPath, _documentLoaded=$_documentLoaded');
    if (_loading || _localPdfPath == null || !_documentLoaded) {
      print(
          'Cannot save: PDF not loaded, local path is null, or document not loaded');
      // Optionally show a user message
      return;
    }
    try {
      await _pdfController?.save();
      await _pdfController?.exportPdf().then((Uint8List data) async {
        /// Convert the data to a Base64 string.
        final base64Data = base64Encode(data);
        await _saveAnnotations(base64Data); // Save the raw strin
      });

      await saveLastPageToBackend(); // Save last page after annotation save
    } catch (e) {
      print('Error saving annotations: $e');
      // Optionally show a user message
    } finally {
      Navigator.pop(context);
    }
  }

  void _onPageChanged(int page) {
    if (!mounted) return;
    setState(() {
      _currentPage = page;
    });
  }

  // Expose these methods for parent access
  Future<void> exportAndSaveAnnotations() => _exportAndSaveAnnotations();

  void openSearch() {
    if (_localPdfPath == null) return;
    Nutrient.present(
      _localPdfPath!,
      configuration: {'showSearchAction': true},
    );
  }

  void openAnnotationToolbar() {
    _hasUnsavedChanges = true;
    if (_localPdfPath == null) return;
    Nutrient.present(
      _localPdfPath!,
      configuration: {
        'enableAnnotationEditing': true,
        'showAnnotationToolbar': true,
      },
    );
  }

  Future<bool> isAndroid10() async {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.version.sdkInt == 29;
    }
    return false;
  }

  @override
  Widget build(BuildContext context)  {
    print(widget.initialPage);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Ensure start page is a valid zero-based index. Nutrient asserts on iOS if a negative index is provided.
    final int computedStartPage = ((widget.initialPage ?? 1) - 1) < 0
        ? 0
        : ((widget.initialPage ?? 1) - 1);
    // On desktop platforms (macOS/Windows), use Syncfusion's SfPdfViewer which
    // is the previously used/expected viewer. Mobile continues to use Nutrient.
    if (Platform.isMacOS || Platform.isWindows) {
      final String source = _localPdfPath ?? widget.pdfUrl;
      final controller = _sfPdfViewerController ??= PdfViewerController();

      final Widget desktopViewer = source.startsWith('http')
          ? SfPdfViewer.network(
              source,
              key: ValueKey('sfpdf-${widget.initialPage ?? 0}'),
              controller: controller,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              onDocumentLoaded: (details) {
                _documentLoaded = true;
                if (widget.initialPage != null && widget.initialPage! > 0) {
                  // Syncfusion is 1-based
                  controller.jumpToPage(widget.initialPage!);
                }
                widget.onDocumentLoaded?.call();
              },
              onPageChanged: (details) => _onPageChanged(details.newPageNumber),
            )
          : SfPdfViewer.file(
              File(source),
              key: ValueKey('sfpdf-${widget.initialPage ?? 0}'),
              controller: controller,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              onDocumentLoaded: (details) {
                _documentLoaded = true;
                if (widget.initialPage != null && widget.initialPage! > 0) {
                  controller.jumpToPage(widget.initialPage!);
                }
                widget.onDocumentLoaded?.call();
              },
              onPageChanged: (details) => _onPageChanged(details.newPageNumber),
            );

      return desktopViewer;
    }
    
    // Default (mobile) – Nutrient (PSPDFKit successor).
    //
    // The previous build wrapped a PdfAnnotationOverlay around the
    // viewer for a future v3 highlight/notes overlay, but it was
    // pinned to `isEnabled: false` and `IgnorePointer(ignoring: true)`,
    // so it rendered nothing and intercepted nothing. Drop it — the
    // overlay can be re-introduced via NutrientView's native
    // annotation editing (already enabled below) without the dead
    // Flutter-level layer.
    return NutrientView(
      key: ValueKey('pdf-${widget.initialPage ?? 0}'),
      documentPath: _localPdfPath ?? '',
      onDocumentLoaded: (document) {
        _pdfController = document;
        setState(() {});
      },
      configuration: PdfConfiguration(
        scrollDirection: ScrollDirection.vertical,
        enableTextSelection: false,
        userInterfaceViewMode: UserInterfaceViewMode.always,
        enableAnnotationEditing: true,
        toolbarMenuItems: [],
        androidShowShareAction: false,
        androidDarkThemeResource: 'R.style.AppTheme',
        toolbarTitle: '',
        androidShowDocumentInfoView: false,
        showThumbnailBar: ThumbnailBarMode.none,
        androidShowBookmarksAction: false,
        androidShowPrintAction: false,
        iOSAllowToolbarTitleChange: false,
        // Explicitly control iOS toolbar items to exclude the Share action (activityButtonItem).
        iOSRightBarButtonItems: [
          'searchButtonItem',
          'annotationButtonItem',
          'thumbnailsButtonItem',
          'outlineButtonItem'
        ],
        documentLabelEnabled: false,
        disableAutosave: false,
        appearanceMode: ThemeManager.currentTheme == AppTheme.Dark
            ? AppearanceMode.night
            : AppearanceMode.defaultMode,
        // Clamp to prevent negative page index which crashes on iOS.
        startPage: computedStartPage,
      ),
      onPageChanged: (page) => _onPageChanged(page + 1),
      onViewCreated: (view) {},
    );
  }
}
