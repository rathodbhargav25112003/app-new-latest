// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, use_super_parameters

import 'package:flutter/material.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';

/// Local document metadata used by the PDF file-explorer screen.
///
/// Kept as a separate class from `sharedhelper.Document` to avoid import
/// ambiguity. Constructor signature `LocalDocument(String name, String
/// path)` (positional) is preserved byte-for-byte for any external
/// callers.
class LocalDocument {
  LocalDocument(this.name, this.path);

  String path;
  String name;
}

/// Callback fired when a PDF document is selected in the file explorer.
/// Preserved verbatim.
typedef PdfDocumentTapCallback = void Function(LocalDocument document);

/// File Explorer widget for mobile — picks a PDF from a hardcoded
/// asset list and fires `onDocumentTap`.
///
/// Preserved public contract:
///   • Constructor `FileExplorer({Key? key, this.onDocumentTap})` with
///     `Key?` (not `super.key`) — matches the original.
///   • `onDocumentTap` remains a nullable `PdfDocumentTapCallback?`.
///   • The asset list and their display names are preserved byte-for-byte
///     (GIS Succinctly / HTTP Succinctly / JavaScript Succinctly /
///     Rotated Document / Single Page Document / Encrypted Document /
///     Corrupted Document).
///   • State class name `FileExplorerState` is kept PUBLIC (not
///     underscored) in case external callers grab the state via
///     GlobalKey.
class FileExplorer extends StatefulWidget {
  const FileExplorer({Key? key, this.onDocumentTap}) : super(key: key);

  /// Called when the document is selected.
  final PdfDocumentTapCallback? onDocumentTap;

  @override
  FileExplorerState createState() => FileExplorerState();
}

/// State for the File Explorer widget. Kept public to match the
/// original API surface.
class FileExplorerState extends State<FileExplorer> {
  late List<LocalDocument> _documents;

  @override
  void initState() {
    _documents = <LocalDocument>[
      LocalDocument('GIS Succinctly', 'assets/pdf/gis_succinctly.pdf'),
      LocalDocument('HTTP Succinctly', 'assets/pdf/http_succinctly.pdf'),
      LocalDocument(
          'JavaScript Succinctly', 'assets/pdf/javascript_succinctly.pdf'),
      LocalDocument('Rotated Document', 'assets/pdf/rotated_document.pdf'),
      LocalDocument(
          'Single Page Document', 'assets/pdf/single_page_document.pdf'),
      LocalDocument(
          'Encrypted Document', 'assets/pdf/encrypted_document.pdf'),
      LocalDocument(
          'Corrupted Document', 'assets/pdf/corrupted_document.pdf'),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: AppTokens.surface(context),
        surfaceTintColor: AppTokens.surface(context),
        title: Text(
          'Choose File',
          style: AppTokens.titleSm(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppTokens.ink(context),
          ),
        ),
      ),
      body: Container(
        color: AppTokens.scaffold(context),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s12,
          ),
          itemCount: _documents.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppTokens.s8),
          itemBuilder: (BuildContext context, int index) {
            final LocalDocument doc = _documents[index];
            return _DocumentTile(
              name: doc.name,
              onTap: () => widget.onDocumentTap!(doc),
            );
          },
        ),
      ),
    );
  }
}

/// Single-row card for a PDF document. Tappable — fires the
/// `onDocumentTap` callback captured from the parent.
class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surface(context),
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTokens.border(context)),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            boxShadow: AppTokens.shadow1(context),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s12,
          ),
          child: Row(
            children: [
              Container(
                height: AppTokens.s32 + AppTokens.s4,
                width: AppTokens.s32 + AppTokens.s4,
                decoration: BoxDecoration(
                  color: AppTokens.dangerSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: AppTokens.danger(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Text(
                  name,
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTokens.ink(context),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTokens.muted(context),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toolbar item widget — a size-constrained wrapper around an optional
/// `child`. Preserved public contract: `ToolbarItem({super.key,
/// this.height, this.width, required this.child})` with `child` typed
/// as nullable `Widget?`.
class ToolbarItem extends StatelessWidget {
  const ToolbarItem({
    super.key,
    this.height,
    this.width,
    required this.child,
  });

  /// Height of the toolbar item.
  final double? height;

  /// Width of the toolbar item.
  final double? width;

  /// Child widget of the toolbar item.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: child,
    );
  }
}

// Legacy notes kept as file comments so future PRs have the same signals:
//
// TODO: Implement search overlay using PSPDFKit's search methods (if
//       available)
// TODO: Implement annotation creation using PSPDFKit's addAnnotation
//       API
// TODO: Implement drawing as ink annotation using PSPDFKit's
//       addAnnotation API
//
// Removed all code that referenced sf.PdfTextSearchResult,
// sf.PdfViewerController, sf.PdfAnnotationMode, TextSearchOption, etc.
// Removed all code that referenced Syncfusion's undo/redo, annotation
// settings, etc.
//
// If you want to keep a custom search overlay, you must implement it
// using PSPDFKit's search methods (if available).
// If you want to keep annotation/drawing toolbars, implement their
// logic using PSPDFKit's annotation API.
