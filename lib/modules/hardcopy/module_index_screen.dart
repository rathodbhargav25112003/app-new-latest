// ignore_for_file: deprecated_member_use, unused_import

import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';

/// Volume index — lists chapters of a hardcopy volume. Redesigned with
/// AppTokens; constructor, static route, and navigation target preserved.
class VolumeIndexScreen extends StatelessWidget {
  final String volumeName;
  final int volumeNumber;
  final List<Map<String, dynamic>> chapters;

  const VolumeIndexScreen({
    super.key,
    required this.volumeName,
    required this.volumeNumber,
    required this.chapters,
  });

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>;
    return MaterialPageRoute(
      builder: (_) => VolumeIndexScreen(
        volumeName: args['volumeName'],
        volumeNumber: args['volumeNumber'],
        chapters: List<Map<String, dynamic>>.from(args['chapters']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final contentWidth = isDesktop ? 800.0 : screenWidth;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _IndexHeader(
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.s16,
                    AppTokens.s16,
                    AppTokens.s16,
                    AppTokens.s24,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTokens.surface(context),
                      borderRadius: AppTokens.radius20,
                      border: Border.all(color: AppTokens.border(context)),
                      boxShadow: AppTokens.shadow1(context),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTokens.s16,
                            AppTokens.s16,
                            AppTokens.s16,
                            AppTokens.s8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Volume $volumeNumber',
                                style: AppTokens.overline(context),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                volumeName,
                                style: AppTokens.titleLg(context),
                              ),
                              const SizedBox(height: AppTokens.s4),
                              Text(
                                '${chapters.length} chapter${chapters.length == 1 ? '' : 's'}',
                                style: AppTokens.caption(context),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, thickness: 0.5),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppTokens.s12,
                            AppTokens.s12,
                            AppTokens.s12,
                            AppTokens.s16,
                          ),
                          itemCount: chapters.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppTokens.s8),
                          itemBuilder: (context, index) {
                            final chapter = chapters[index];
                            return _ChapterRow(
                              index: index + 1,
                              chapterName: chapter['name']?.toString() ?? '',
                              chapterNumber:
                                  "Chapter ${chapter['number'].toString().padLeft(2, '0')}",
                              pages: chapter['pages']?.toString() ?? '',
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  Routes.chapterDetails,
                                  arguments: {
                                    'chapterName': chapter['name'],
                                    'chapterFile': chapter['chapterFile'],
                                    'chapterNumber': index + 1,
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _IndexHeader({required this.onBack});

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
            AppTokens.s16,
            AppTokens.s16,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.18),
                borderRadius: AppTokens.radius12,
                child: InkWell(
                  borderRadius: AppTokens.radius12,
                  onTap: onBack,
                  child: const SizedBox(
                    height: 40,
                    width: 40,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hardcopy',
                      style: AppTokens.overline(context).copyWith(
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Index',
                      style: AppTokens.titleLg(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  final int index;
  final String chapterName;
  final String chapterNumber;
  final String pages;
  final VoidCallback onTap;

  const _ChapterRow({
    required this.index,
    required this.chapterName,
    required this.chapterNumber,
    required this.pages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s12),
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: AppTokens.radius12,
            border: Border.all(color: AppTokens.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTokens.brand, AppTokens.brand2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppTokens.radius8,
                ),
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: AppTokens.body(context).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapterName,
                      style: AppTokens.body(context).copyWith(
                        color: AppTokens.ink(context),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chapterNumber,
                      style: AppTokens.caption(context),
                    ),
                  ],
                ),
              ),
              if (pages.isNotEmpty) ...[
                const SizedBox(width: AppTokens.s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.surface2(context),
                    borderRadius: AppTokens.radius8,
                  ),
                  child: Text(
                    pages,
                    style: AppTokens.caption(context).copyWith(
                      color: AppTokens.ink2(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: AppTokens.s4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTokens.muted(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
