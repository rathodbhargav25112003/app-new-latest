import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../helpers/app_tokens.dart';
import '../../helpers/constants.dart';
import '../../models/featured_list_model.dart';

/// FeaturedNotesView — Apple-minimalistic featured-PDF viewer shell.
///
/// The viewer body is a placeholder Container (the real PDF render is
/// wired through [SfPdfViewer]/PSPDFKit elsewhere). This file's job is
/// to provide the navigation chrome:
///  • Clean AppBar with back button + topic title.
///  • Trailing download action (svg icon button on a tinted circle).
///  • Body that consumes [AppTokens.scaffold] and rounds the actual
///    PDF surface onto a soft surface card.
class FeaturedNotesView extends StatefulWidget {
  final Pdfs? featuredNotes;
  const FeaturedNotesView({Key? key, this.featuredNotes}) : super(key: key);

  @override
  State<FeaturedNotesView> createState() => _FeaturedNotesViewState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => FeaturedNotesView(
        featuredNotes: arguments['featuredNotes'],
      ),
    );
  }
}

class _FeaturedNotesViewState extends State<FeaturedNotesView> {
  bool permissionGranted = false;
  String pdfUrl = '';
  String modifiedString = '';
  String pdfName = '';

  @override
  void initState() {
    super.initState();
    pdfUrl = widget.featuredNotes?.contentUrl ?? "";
    pdfName = pdfUrl.contains('/') && pdfUrl.contains('.')
        ? pdfUrl.substring(pdfUrl.lastIndexOf('/') + 1, pdfUrl.lastIndexOf('.'))
        : 'note';
    modifiedString = pdfUrl.contains('/')
        ? "getPDF${pdfUrl.substring(pdfUrl.lastIndexOf('/'))}"
        : '';
    getPermission();
  }

  Future<void> getPermission() async {
    permissionGranted = await handleStoragePermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTokens.scaffold(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTokens.ink(context), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.featuredNotes?.topicName ?? "Notes",
          style: AppTokens.titleLg(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppTokens.s12),
            child: IconButton(
              tooltip: 'Download',
              icon: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  "assets/image/downloadIcon.svg",
                  color: AppTokens.accent(context),
                  width: 16,
                  height: 16,
                ),
              ),
              onPressed: () {
                final url = pdfBaseUrl + modifiedString;
                downloadPDF(url, pdfName);
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTokens.s16, AppTokens.s8, AppTokens.s16, AppTokens.s16),
          child: Container(
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              borderRadius: AppTokens.radius20,
              border: Border.all(
                color: AppTokens.border(context),
                width: 0.5,
              ),
            ),
            // The actual PDF is rendered via SfPdfViewer/PSPDFKit in
            // adjacent surfaces; this container is the chrome.
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  Future<void> downloadPDF(String url, String filename) async {
    if (!permissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTokens.ink(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTokens.radius12),
        content: const Text('Storage permission is required to save the PDF.'),
      ));
      openAppSettings();
      return;
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/$filename.pdf';
        await File(filePath).writeAsBytes(response.bodyBytes);
        debugPrint("filepath: $filePath");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppTokens.success(context),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTokens.radius12),
          content: const Text('PDF downloaded successfully'),
        ));
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTokens.danger(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTokens.radius12),
        content: const Text('Couldn’t download right now. Please try again.'),
      ));
    }
  }

  Future<bool> handleStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }
}
