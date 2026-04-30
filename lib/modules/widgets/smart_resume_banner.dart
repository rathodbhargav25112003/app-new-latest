import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/haptics.dart';
import '../../services/smart_resume_service.dart';

/// SmartResumeBanner — single one-tap "pick up where you left off"
/// card for the home screen.
///
/// Drops into any home / dashboard layout. Fetches the latest
/// [ResumeEntry] across all four channels (mock, custom test, video,
/// note) and renders the most recent. Returns [SizedBox.shrink] when
/// the user has nothing in progress so it occupies zero space.
///
/// On tap, deep-links into the right module via the `extras` map the
/// recorder filled in.
class SmartResumeBanner extends StatefulWidget {
  const SmartResumeBanner({super.key});

  @override
  State<SmartResumeBanner> createState() => _SmartResumeBannerState();
}

class _SmartResumeBannerState extends State<SmartResumeBanner> {
  ResumeEntry? _entry;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) _load();
  }

  Future<void> _load() async {
    final entry = await SmartResumeService.instance.latest();
    if (!mounted) return;
    setState(() {
      _entry = entry;
      _loaded = true;
    });
  }

  void _resume() {
    final entry = _entry;
    if (entry == null) return;
    Haptics.selection();
    switch (entry.kind) {
      case ResumeKind.mockExam:
        Navigator.of(context).pushNamed(
          Routes.featuredTestExamPage,
          arguments: {
            'userexamId': entry.primaryId,
            'queNo': entry.extras['currentQuestion'],
            'fromPallete': true,
          },
        );
        break;
      case ResumeKind.customTest:
        Navigator.of(context).pushNamed(
          Routes.practiceCustomTestExamScreen,
          arguments: {
            'userexamId': entry.primaryId,
            'queNo': entry.extras['currentQuestion'],
          },
        );
        break;
      case ResumeKind.video:
        Navigator.of(context).pushNamed(
          Routes.videoPlayDetail,
          arguments: {
            'topicId': entry.primaryId,
            'positionSeconds': entry.extras['positionSeconds'],
          },
        );
        break;
      case ResumeKind.note:
        Navigator.of(context).pushNamed(
          Routes.notesReadView,
          arguments: {
            'titleId': entry.primaryId,
            'title': entry.title,
            'topic_name': entry.extras['topicName'] ?? '',
            'category_name': entry.extras['subjectName'] ?? '',
            'subcategory_name': '',
            'contentUrl': entry.extras['contentUrl'] ?? '',
            'isDownloaded': false,
            'isCompleted': false,
            'pageNo': entry.extras['currentPage'],
          },
        );
        break;
    }
  }

  Future<void> _dismiss() async {
    Haptics.medium();
    final kind = _entry?.kind;
    if (kind != null) {
      await SmartResumeService.instance.clear(kind);
    }
    if (!mounted) return;
    setState(() => _entry = null);
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    if (entry == null) return const SizedBox.shrink();

    // Tone — accent for tests/quizzes, success for completed items
    // (won't actually reach 1.0 here since 100% means "done"), info-
    // toned for video/note.
    final tint = _kindTint(entry.kind, context);
    final iconData = _kindIcon(entry.kind);
    final progressBarColor = entry.progress >= 0.85
        ? AppTokens.success(context)
        : tint;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16, vertical: AppTokens.s8),
      child: Material(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        child: InkWell(
          borderRadius: AppTokens.radius16,
          onTap: _resume,
          child: Container(
            padding: const EdgeInsets.all(AppTokens.s12),
            decoration: BoxDecoration(
              borderRadius: AppTokens.radius16,
              border: Border.all(
                color: tint.withOpacity(0.35),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tint.withOpacity(0.14),
                        borderRadius: AppTokens.radius12,
                      ),
                      child: Icon(iconData, color: tint, size: 22),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tint.withOpacity(0.14),
                                  borderRadius: AppTokens.radius8,
                                ),
                                child: Text(
                                  'Continue ${entry.kind.label.toLowerCase()}',
                                  style: AppTokens.caption(context).copyWith(
                                    color: tint,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTokens.titleSm(context),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTokens.caption(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTokens.s4),
                    IconButton(
                      tooltip: 'Dismiss',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close_rounded,
                          size: 18, color: AppTokens.muted(context)),
                      onPressed: _dismiss,
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: entry.progress.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppTokens.surface3(context),
                    color: progressBarColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _kindTint(ResumeKind kind, BuildContext ctx) {
    switch (kind) {
      case ResumeKind.mockExam:
        return AppTokens.accent(ctx);
      case ResumeKind.customTest:
        return const Color(0xFF8E44AD);
      case ResumeKind.video:
        return const Color(0xFFE89B20);
      case ResumeKind.note:
        return const Color(0xFF1E88E5);
    }
  }

  IconData _kindIcon(ResumeKind kind) {
    switch (kind) {
      case ResumeKind.mockExam:
        return Icons.assignment_outlined;
      case ResumeKind.customTest:
        return Icons.edit_note_rounded;
      case ResumeKind.video:
        return Icons.play_circle_outline_rounded;
      case ResumeKind.note:
        return Icons.menu_book_rounded;
    }
  }
}
