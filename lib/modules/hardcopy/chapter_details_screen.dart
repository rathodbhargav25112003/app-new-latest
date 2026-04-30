// ignore_for_file: deprecated_member_use, avoid_print, unused_import

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';

/// Chapter PDF viewer — redesigned with AppTokens. Constructor and
/// static route preserved.
class ChapterDetailsScreen extends StatefulWidget {
  final String chapterName;
  final String chapterFile;
  final int chapterNumber;

  const ChapterDetailsScreen({
    super.key,
    required this.chapterName,
    required this.chapterFile,
    required this.chapterNumber,
  });

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>;
    return MaterialPageRoute(
      builder: (_) => ChapterDetailsScreen(
        chapterName: args['chapterName'],
        chapterFile: args['chapterFile'],
        chapterNumber: args['chapterNumber'],
      ),
    );
  }

  @override
  State<ChapterDetailsScreen> createState() => _ChapterDetailsScreenState();
}

class _ChapterDetailsScreenState extends State<ChapterDetailsScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  void _zoomIn() {
    final cur = _pdfViewerController.zoomLevel;
    _pdfViewerController.zoomLevel = (cur + 0.25).clamp(1.0, 3.0);
  }

  void _zoomOut() {
    final cur = _pdfViewerController.zoomLevel;
    _pdfViewerController.zoomLevel = (cur - 0.25).clamp(1.0, 3.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _ChapterHeader(
            chapterName: widget.chapterName,
            chapterNumber: widget.chapterNumber,
            onBack: () => Navigator.pop(context),
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTokens.surface(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTokens.r28),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: SfPdfViewer.network(
                widget.chapterFile,
                key: _pdfViewerKey,
                maxZoomLevel: 3,
                controller: _pdfViewerController,
                onZoomLevelChanged: (PdfZoomDetails details) {
                  print(details.newZoomLevel);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterHeader extends StatelessWidget {
  final String chapterName;
  final int chapterNumber;
  final VoidCallback onBack;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _ChapterHeader({
    required this.chapterName,
    required this.chapterNumber,
    required this.onBack,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTokens.brand.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s12,
            AppTokens.s8,
            AppTokens.s12,
            AppTokens.s16,
          ),
          child: Row(
            children: [
              _CircleBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Chapter ${chapterNumber.toString().padLeft(2, '0')}',
                      style: AppTokens.overline(context).copyWith(
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chapterName.isEmpty ? 'Chapter' : chapterName,
                      style: AppTokens.titleMd(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              _CircleBtn(icon: Icons.zoom_out_rounded, onTap: onZoomOut),
              const SizedBox(width: AppTokens.s8),
              _CircleBtn(icon: Icons.zoom_in_rounded, onTap: onZoomIn),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: SizedBox(
          height: 40,
          width: 40,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
