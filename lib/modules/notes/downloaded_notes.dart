// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';

import 'package:shusruta_lms/app/routes.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/modules/widgets/custom_remove_file_bottomsheet.dart';

/// "Offline Notes" downloaded-file detail screen. This is the leaf of
/// the offline browse tree for a single already-downloaded PDF — tapping
/// the card opens the PDF via `Routes.notesReadView`, and the trash
/// button invokes `CustomRemoveFileBottomSheet` to confirm removal.
///
/// NOTE: Despite its name, this screen renders a *single* downloaded
/// entry (the one whose `titleId` was passed in via the route args)
/// rather than a list of every cached PDF. That behaviour matches the
/// original implementation and is preserved byte-for-byte.
///
/// Preserved public contract:
///   • `DownloadedNotes({super.key, this.filePath, this.title, this.titleId})`
///     with nullable `String?` fields.
///   • Static `route(RouteSettings)` factory reading `arguments['filePath']`,
///     `arguments['title']`, `arguments['titleId']` and returning a
///     `CupertinoPageRoute`.
///   • Navigator push `Routes.notesReadView` with the 4-key argument map
///     `{ 'contentUrl': widget.filePath, 'title': widget.title,
///        "isCompleted": true, 'isDownloaded': true }` preserved
///     byte-for-byte (including the mixed single/double-quoted keys
///     from the original).
///   • `CustomRemoveFileBottomSheet(context, widget.titleId)` call
///     preserved (the optional `file` argument is intentionally omitted
///     — matches the original).
///   • Public state method `getFilesInDocumentsDirectory()` returning
///     `Future<List<FileSystemEntity>>` preserved — other callers
///     reach this via GlobalKey in the legacy code paths.
class DownloadedNotes extends StatefulWidget {
  const DownloadedNotes({
    super.key,
    this.filePath,
    this.title,
    this.titleId,
  });

  final String? filePath;
  final String? title;
  final String? titleId;

  @override
  State<DownloadedNotes> createState() => _DownloadedNotesState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => DownloadedNotes(
        filePath: arguments['filePath'],
        title: arguments['title'],
        titleId: arguments['titleId'],
      ),
    );
  }
}

class _DownloadedNotesState extends State<DownloadedNotes> {
  // ignore: unused_field
  Future<List<FileSystemEntity>>? _fileList;

  Future<List<FileSystemEntity>> getFilesInDocumentsDirectory() async {
    final Directory appDocumentsDirectory =
        await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = appDocumentsDirectory.listSync();

    final List<FileSystemEntity> pdfFiles = files.where((file) {
      return file is File && file.path.toLowerCase().endsWith('.pdf');
    }).toList();

    return pdfFiles;
  }

  @override
  void initState() {
    super.initState();
    _fileList = getFilesInDocumentsDirectory();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isWindows || Platform.isMacOS;
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _HeroHeader(isDesktop: isDesktop),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                left: AppTokens.s20,
                right: AppTokens.s20,
                top: AppTokens.s24,
              ),
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: isDesktop
                    ? null
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.r28),
                        topRight: Radius.circular(AppTokens.r28),
                      ),
              ),
              child: FutureBuilder<List<FileSystemEntity>>(
                future: getFilesInDocumentsDirectory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: AppTokens.body(context).copyWith(
                          color: AppTokens.danger(context),
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _EmptyState();
                  } else {
                    final List<FileSystemEntity> fileList = snapshot.data!;
                    fileList.sort((a, b) =>
                        b.statSync().modified.compareTo(a.statSync().modified));

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTokens.s8),
                      child: _DownloadedTile(
                        title: widget.title ?? "",
                        onOpen: () {
                          Navigator.of(context).pushNamed(
                            Routes.notesReadView,
                            arguments: {
                              'contentUrl': widget.filePath,
                              'title': widget.title,
                              "isCompleted": true,
                              'isDownloaded': true,
                            },
                          );
                        },
                        onRemove: () async {
                          final FileSystemEntity? removedFile =
                              await showModalBottomSheet<FileSystemEntity>(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(AppTokens.r20),
                              ),
                            ),
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            context: context,
                            builder: (BuildContext context) {
                              return CustomRemoveFileBottomSheet(
                                context,
                                widget.titleId,
                              );
                            },
                          );
                          if (removedFile != null) {
                            setState(() {
                              fileList.remove(removedFile);
                            });
                          }
                        },
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      padding: isDesktop
          ? const EdgeInsets.symmetric(
              vertical: AppTokens.s24, horizontal: AppTokens.s24)
          : const EdgeInsets.only(
              top: AppTokens.s32 + AppTokens.s24,
              left: AppTokens.s20,
              right: AppTokens.s20,
              bottom: AppTokens.s20,
            ),
      child: Row(
        children: [
          IconButton(
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              "Offline Notes",
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: AppTokens.s32 + AppTokens.s32,
              width: AppTokens.s32 + AppTokens.s32,
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_off_rounded,
                color: AppTokens.muted(context),
                size: 32,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              "No offline content",
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
              style: AppTokens.body(context).copyWith(
                fontWeight: FontWeight.w400,
                color: AppTokens.muted(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadedTile extends StatelessWidget {
  const _DownloadedTile({
    required this.title,
    required this.onOpen,
    required this.onRemove,
  });

  final String title;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            border: Border.all(color: AppTokens.border(context)),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            boxShadow: AppTokens.shadow1(context),
          ),
          child: Row(
            children: [
              Container(
                height: AppTokens.s32 + AppTokens.s24,
                width: AppTokens.s32 + AppTokens.s24,
                padding: const EdgeInsets.all(AppTokens.s12),
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
                child: SvgPicture.asset(
                  "assets/image/book-open2.svg",
                  color: AppTokens.accent(context),
                ),
              ),
              const SizedBox(width: AppTokens.s16),
              Expanded(
                child: Text(
                  title,
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTokens.ink(context),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(AppTokens.r8),
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.s8),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 22,
                    color: AppTokens.danger(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
