// ignore_for_file: use_build_context_synchronously, deprecated_member_use, unused_import

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/services.dart';
// ignore: unnecessary_import
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:progress_border/progress_border.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/models/get_all_my_custom_test_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/widget/loading_box.dart';
import 'package:shusruta_lms/modules/test/test_category.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/searched_data_model.dart';
import '../../models/test_subcategory_model.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/no_internet_connection.dart';
import 'custom_user_test_bottom_sheet.dart';
import 'store/custom_test_store.dart';

class CustomPreview extends StatefulWidget {
  final List<Map<String, dynamic>> selectedCategoryItems;
  final List<Map<String, dynamic>> selectedChapterItems;
  final List<Map<String, dynamic>> selectedTopicItems;
  final List<Map<String, dynamic>> selectedExamItems;
  final String counterQuestion;
  final String counterDurations;
  final String testName;
  final String testDesc;
  const CustomPreview({
    super.key,
    required this.selectedCategoryItems,
    required this.selectedChapterItems,
    required this.selectedTopicItems,
    required this.selectedExamItems,
    required this.counterQuestion,
    required this.counterDurations,
    required this.testName,
    required this.testDesc,
  });

  @override
  State<CustomPreview> createState() => _CustomPreviewState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => CustomPreview(
        selectedCategoryItems: arguments['selectedCategoryItems'],
        selectedChapterItems: arguments['selectedChapterItems'],
        selectedTopicItems: arguments['selectedTopicItems'],
        selectedExamItems: arguments['selectedExamItems'],
        counterQuestion: arguments['counterQuestion'],
        counterDurations: arguments['counterDurations'],
        testName: arguments['testName'],
        testDesc: arguments['testDesc'],
      ),
    );
  }
}

class _CustomPreviewState extends State<CustomPreview> {
  Map<int, bool> expandedCategory = {};
  Map<String, bool> expandedChapter = {};
  Map<String, bool> expandedTopic = {};
  Map<String, bool> expandedExam = {};

  late List<Map<String, dynamic>> selectedCategoryItems;
  late List<Map<String, dynamic>> selectedChapterItems;
  late List<Map<String, dynamic>> selectedTopicItems;
  late List<Map<String, dynamic>> selectedExamItems;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    selectedCategoryItems = List.from(widget.selectedCategoryItems);
    selectedChapterItems = List.from(widget.selectedChapterItems);
    selectedTopicItems = List.from(widget.selectedTopicItems);
    selectedExamItems = List.from(widget.selectedExamItems);

    for (int i = 0; i < selectedCategoryItems.length; i++) {
      expandedCategory[i] = false;
    }
    for (var chapter in selectedChapterItems) {
      expandedChapter[chapter['subcategory_id'].toString()] = false;
    }
    for (var topic in selectedTopicItems) {
      expandedTopic[topic['topic_id'].toString()] = false;
    }
    for (var exam in selectedExamItems) {
      expandedExam[exam['exam_id'].toString()] = false;
    }
    debugPrint('Selected Categories: $selectedCategoryItems');
    debugPrint('Selected Chapters: $selectedChapterItems');
    debugPrint('Selected Topics: $selectedTopicItems');
    debugPrint('Selected Exams: $selectedExamItems');
  }

  void toggleCategory(int index) {
    setState(() {
      final wasExpanded = expandedCategory[index] ?? false;
      expandedCategory[index] = !wasExpanded;

      if (!wasExpanded) {
        expandedCategory.forEach((key, value) {
          if (key != index) expandedCategory[key] = false;
        });

        final category = selectedCategoryItems[index];
        final categoryId = category['category_id'].toString();

        final chapters = selectedChapterItems
            .where((chapter) => chapter['category_id'].toString() == categoryId)
            .toList();

        for (var chapter in chapters) {
          final chapterId = chapter['subcategory_id'].toString();
          expandedChapter[chapterId] = true;

          final topics = selectedTopicItems
              .where((topic) => topic['subcategory_id'].toString() == chapterId)
              .toList();

          for (var topic in topics) {
            final topicId = topic['topic_id'].toString();
            expandedTopic[topicId] = true;

            final exams = selectedExamItems
                .where((exam) => exam['topic_id'].toString() == topicId)
                .toList();

            for (var exam in exams) {
              final examId = exam['exam_id'].toString();
              expandedExam[examId] = true;
            }
          }
        }
      } else {
        final category = selectedCategoryItems[index];
        final categoryId = category['category_id'].toString();

        final chapters = selectedChapterItems
            .where((chapter) => chapter['category_id'].toString() == categoryId)
            .toList();

        for (var chapter in chapters) {
          final chapterId = chapter['subcategory_id'].toString();
          expandedChapter[chapterId] = false;

          final topics = selectedTopicItems
              .where((topic) => topic['subcategory_id'].toString() == chapterId)
              .toList();

          for (var topic in topics) {
            final topicId = topic['topic_id'].toString();
            expandedTopic[topicId] = false;

            final exams = selectedExamItems
                .where((exam) => exam['topic_id'].toString() == topicId)
                .toList();

            for (var exam in exams) {
              final examId = exam['exam_id'].toString();
              expandedExam[examId] = false;
            }
          }
        }
      }
    });
  }

  void toggleChapter(String chapterId) {
    setState(() {
      expandedChapter[chapterId] = !(expandedChapter[chapterId] ?? false);
      if (expandedChapter[chapterId] == true) {
        expandedChapter.forEach((key, value) {
          if (key != chapterId) expandedChapter[key] = false;
        });
      }
    });
  }

  void toggleTopic(String topicId) {
    setState(() {
      expandedTopic[topicId] = !(expandedTopic[topicId] ?? false);
      if (expandedTopic[topicId] == true) {
        expandedTopic.forEach((key, value) {
          if (key != topicId) expandedTopic[key] = false;
        });
      }
    });
  }

  void removeCategory(int index) {
    setState(() {
      final category = selectedCategoryItems[index];
      final categoryId = category['category_id'].toString();

      selectedCategoryItems.removeAt(index);

      selectedChapterItems.removeWhere(
          (chapter) => chapter['category_id'].toString() == categoryId);

      final chapterIds = selectedChapterItems
          .where((chapter) => chapter['category_id'].toString() == categoryId)
          .map((chapter) => chapter['subcategory_id'].toString())
          .toList();

      selectedTopicItems.removeWhere(
          (topic) => chapterIds.contains(topic['subcategory_id'].toString()));

      final topicIds = selectedTopicItems
          .where((topic) =>
              chapterIds.contains(topic['subcategory_id'].toString()))
          .map((topic) => topic['topic_id'].toString())
          .toList();

      selectedExamItems.removeWhere(
          (exam) => topicIds.contains(exam['topic_id'].toString()));

      expandedCategory.clear();
      for (int i = 0; i < selectedCategoryItems.length; i++) {
        expandedCategory[i] = false;
      }
    });
  }

  void removeChapter(String chapterId) {
    setState(() {
      selectedChapterItems.removeWhere(
          (chapter) => chapter['subcategory_id'].toString() == chapterId);

      selectedTopicItems.removeWhere(
          (topic) => topic['subcategory_id'].toString() == chapterId);

      final topicIds = selectedTopicItems
          .where((topic) => topic['subcategory_id'].toString() == chapterId)
          .map((topic) => topic['topic_id'].toString())
          .toList();

      selectedExamItems.removeWhere(
          (exam) => topicIds.contains(exam['topic_id'].toString()));

      expandedChapter.clear();
      for (var chapter in selectedChapterItems) {
        expandedChapter[chapter['subcategory_id'].toString()] = false;
      }
    });
  }

  void removeTopic(String topicId) {
    setState(() {
      selectedTopicItems
          .removeWhere((topic) => topic['topic_id'].toString() == topicId);

      selectedExamItems
          .removeWhere((exam) => exam['topic_id'].toString() == topicId);

      expandedTopic.clear();
      for (var topic in selectedTopicItems) {
        expandedTopic[topic['topic_id'].toString()] = false;
      }
    });
  }

  void removeExam(String examId) {
    setState(() {
      selectedExamItems
          .removeWhere((exam) => exam['exam_id'].toString() == examId);

      expandedExam.clear();
      for (var exam in selectedExamItems) {
        expandedExam[exam['exam_id'].toString()] = false;
      }
    });
  }

  Future<void> _createCustomTest() async {
    final store = Provider.of<CustomTestCategoryStore>(context, listen: false);
    await store.onCreateCustomTestApiCall(
        widget.testName,
        widget.testDesc,
        int.parse(widget.counterQuestion),
        _formatMinutesToTimeString(int.parse(widget.counterDurations)),
        selectedCategoryItems,
        selectedChapterItems,
        selectedTopicItems,
        selectedExamItems);
  }

  String _formatMinutesToTimeString(int minutes) {
    int hours = (minutes ~/ 60) % 24;
    int remainingMinutes = minutes % 60;
    String formattedTime =
        '${hours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')}:00';

    return formattedTime;
  }

  Future<void> _onSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    showLoadingDialog(context);
    Object? err;
    try {
      await _createCustomTest();
    } catch (e) {
      err = e;
    }
    if (!mounted) return;
    // Dismiss loading dialog regardless of outcome.
    Navigator.of(context).pop();
    if (err != null) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }
    Navigator.of(context).push(CupertinoPageRoute(
        builder: (context) => const TestCategoryScreen(tabIndex: 1)));
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isWindows || Platform.isMacOS;
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        bottomNavigationBar: _SaveBar(
          busy: _isSaving,
          onTap: _onSave,
        ),
        body: Column(
          children: [
            _GradientHeader(
              title: 'Preview',
              subtitle: 'Review your custom test before saving',
              testName: widget.testName,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTokens.scaffold(context),
                  borderRadius: isDesktop
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r28),
                          topRight: Radius.circular(AppTokens.r28),
                        ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: AppTokens.s24),
                  child: Column(
                    children: [
                      const SizedBox(height: AppTokens.s24),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatTile(
                                icon: Icons.help_outline_rounded,
                                tone: AppTokens.accent(context),
                                soft: AppTokens.accentSoft(context),
                                value: widget.counterQuestion,
                                label: 'Questions',
                              ),
                            ),
                            const SizedBox(width: AppTokens.s12),
                            Expanded(
                              child: _StatTile(
                                icon: Icons.timer_outlined,
                                tone: AppTokens.warning(context),
                                soft: AppTokens.warningSoft(context),
                                value: '${widget.counterDurations} min',
                                label: 'Duration',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.testDesc.trim().isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s16),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.s20),
                          child: _DescriptionCard(
                            description: widget.testDesc,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTokens.s20),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Contents',
                              style:
                                  AppTokens.titleMd(context).copyWith(
                                color: AppTokens.ink(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.s12,
                                vertical: AppTokens.s4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTokens.accentSoft(context),
                                borderRadius:
                                    BorderRadius.circular(AppTokens.r8),
                              ),
                              child: Text(
                                '${selectedCategoryItems.length} '
                                '${selectedCategoryItems.length == 1 ? "Module" : "Modules"}',
                                style:
                                    AppTokens.caption(context).copyWith(
                                  color: AppTokens.accent(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.s12),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s20),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: selectedCategoryItems.length,
                          itemBuilder: (context, categoryIndex) {
                            final category =
                                selectedCategoryItems[categoryIndex];
                            final isExpanded =
                                expandedCategory[categoryIndex] ?? false;
                            final chapters = selectedChapterItems
                                .where((chapter) =>
                                    chapter['category_id'].toString() ==
                                    category['category_id'].toString())
                                .toList();

                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppTokens.s12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _SectionTile(
                                    level: _TileLevel.category,
                                    isExpanded: isExpanded,
                                    isMain: true,
                                    onTap: () => toggleCategory(categoryIndex),
                                    onTap2: () =>
                                        toggleCategory(categoryIndex),
                                    onRemove: () =>
                                        removeCategory(categoryIndex),
                                    title: category['category_name'] ?? '',
                                    subtitle:
                                        '${chapters.length} ${chapters.length == 1 ? "Chapter" : "Chapters"}',
                                  ),
                                  if (isExpanded) ...[
                                    const SizedBox(height: AppTokens.s8),
                                    ...chapters.map((chapter) {
                                      final chapterId =
                                          chapter['subcategory_id'].toString();
                                      final isChapterExpanded =
                                          expandedChapter[chapterId] ?? false;
                                      final topics = selectedTopicItems
                                          .where((topic) =>
                                              topic['subcategory_id']
                                                      .toString() ==
                                                  chapter['subcategory_id']
                                                      .toString())
                                          .toList();

                                      return _IndentedBranch(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _SectionTile(
                                              level: _TileLevel.chapter,
                                              isExpanded: isChapterExpanded,
                                              onTap: () =>
                                                  toggleChapter(chapterId),
                                              onTap2: () =>
                                                  toggleChapter(chapterId),
                                              onRemove: () =>
                                                  removeChapter(chapterId),
                                              title: chapter[
                                                      'subcategory_name'] ??
                                                  '',
                                              subtitle:
                                                  '${topics.length} ${topics.length == 1 ? "Topic" : "Topics"}',
                                            ),
                                            if (isChapterExpanded) ...[
                                              const SizedBox(
                                                  height: AppTokens.s8),
                                              ...topics.map((topic) {
                                                final topicId =
                                                    topic['topic_id']
                                                        .toString();
                                                final isTopicExpanded =
                                                    expandedTopic[topicId] ??
                                                        false;
                                                final exams = selectedExamItems
                                                    .where((exam) =>
                                                        exam['topic_id']
                                                                .toString() ==
                                                            topic['topic_id']
                                                                .toString())
                                                    .toList();

                                                return _IndentedBranch(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      _SectionTile(
                                                        level:
                                                            _TileLevel.topic,
                                                        isExpanded:
                                                            isTopicExpanded,
                                                        onTap: () =>
                                                            toggleTopic(
                                                                topicId),
                                                        onTap2: () =>
                                                            toggleTopic(
                                                                topicId),
                                                        onRemove: () =>
                                                            removeTopic(
                                                                topicId),
                                                        title: topic[
                                                                'topic_name'] ??
                                                            '',
                                                        subtitle:
                                                            '${exams.length} ${exams.length == 1 ? "Test" : "Tests"}',
                                                      ),
                                                      if (isTopicExpanded) ...[
                                                        const SizedBox(
                                                            height:
                                                                AppTokens.s8),
                                                        ...exams.map((exam) {
                                                          final examId = exam[
                                                                  'exam_id']
                                                              .toString();
                                                          debugPrint('$exam');
                                                          return _IndentedBranch(
                                                            child: _SectionTile(
                                                              level: _TileLevel
                                                                  .exam,
                                                              isExpanded: true,
                                                              onTap: () {},
                                                              onTap2: () {},
                                                              onRemove: () =>
                                                                  removeExam(
                                                                      examId),
                                                              title: exam[
                                                                      'exam_name'] ??
                                                                  '',
                                                              subtitle:
                                                                  '${exam['question_count'] ?? 0} Questions',
                                                            ),
                                                          );
                                                        }),
                                                      ]
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ],
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Private UI primitives
// ============================================================================

class _GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String testName;
  final VoidCallback onBack;
  const _GradientHeader({
    required this.title,
    required this.subtitle,
    required this.testName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTokens.s12,
        left: AppTokens.s16,
        right: AppTokens.s16,
        bottom: AppTokens.s24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: AppTokens.radius12,
                child: InkWell(
                  borderRadius: AppTokens.radius12,
                  onTap: onBack,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTokens.titleLg(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTokens.caption(context).copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (testName.trim().isNotEmpty) ...[
            const SizedBox(height: AppTokens.s16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s16,
                vertical: AppTokens.s12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: AppTokens.radius16,
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                  width: 1.1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: AppTokens.radius8,
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Name',
                          style: AppTokens.caption(context).copyWith(
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          testName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTokens.titleSm(context).copyWith(
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
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final Color soft;
  final String value;
  final String label;
  const _StatTile({
    required this.icon,
    required this.tone,
    required this.soft,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context), width: 1.1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: AppTokens.radius12,
            ),
            child: Icon(icon, color: tone, size: 22),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTokens.titleMd(context).copyWith(
                    color: AppTokens.ink(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.ink2(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final String description;
  const _DescriptionCard({required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context), width: 1.1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              borderRadius: AppTokens.radius8,
            ),
            child: Icon(
              Icons.notes_rounded,
              color: AppTokens.accent(context),
              size: 18,
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.ink2(context),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndentedBranch extends StatelessWidget {
  final Widget child;
  const _IndentedBranch({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTokens.s16,
        top: AppTokens.s4,
        bottom: AppTokens.s4,
      ),
      child: Container(
        padding: const EdgeInsets.only(left: AppTokens.s12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppTokens.accent(context).withOpacity(0.35),
              width: 2,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

enum _TileLevel { category, chapter, topic, exam }

class _SectionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final _TileLevel level;
  final bool isExpanded;
  final bool isMain;
  // ignore: unused_field
  final bool isTop;
  final VoidCallback? onTap;
  final VoidCallback? onTap2;
  final VoidCallback? onRemove;

  const _SectionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onTap2,
    this.level = _TileLevel.chapter,
    this.isExpanded = false,
    this.isMain = false,
    // ignore: unused_element_parameter
    this.isTop = false,
    this.onRemove,
  });

  IconData get _icon {
    switch (level) {
      case _TileLevel.category:
        return Icons.folder_open_rounded;
      case _TileLevel.chapter:
        return Icons.menu_book_outlined;
      case _TileLevel.topic:
        return Icons.bookmark_outline_rounded;
      case _TileLevel.exam:
        return Icons.quiz_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accent(context);
    final accentSoft = AppTokens.accentSoft(context);
    final bgColor = _bgFor(context);
    final borderColor =
        isExpanded ? accent.withOpacity(0.45) : AppTokens.border(context);

    return Material(
      color: bgColor,
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12,
            vertical: AppTokens.s12,
          ),
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius12,
            border: Border.all(
              color: borderColor,
              width: isExpanded ? 1.4 : 1.1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: AppTokens.radius8,
                ),
                child: Icon(_icon, color: accent, size: 18),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTokens.titleSm(context).copyWith(
                        color: AppTokens.ink(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTokens.caption(context).copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              if (level != _TileLevel.exam)
                _ActionChip(
                  icon: isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  onTap: onTap2,
                ),
              if (level != _TileLevel.exam) const SizedBox(width: AppTokens.s8),
              _ActionChip(
                icon: Icons.close_rounded,
                danger: true,
                onTap: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _bgFor(BuildContext context) {
    switch (level) {
      case _TileLevel.category:
        return AppTokens.surface(context);
      case _TileLevel.chapter:
        return AppTokens.surface2(context);
      case _TileLevel.topic:
      case _TileLevel.exam:
        return AppTokens.surface3(context);
    }
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool danger;
  const _ActionChip({
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final tone =
        danger ? AppTokens.danger(context) : AppTokens.ink2(context);
    final soft = danger
        ? AppTokens.dangerSoft(context)
        : AppTokens.surface(context);
    return Material(
      color: soft,
      borderRadius: AppTokens.radius8,
      child: InkWell(
        borderRadius: AppTokens.radius8,
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius8,
            border: Border.all(
              color: danger
                  ? AppTokens.danger(context).withOpacity(0.25)
                  : AppTokens.border(context),
              width: 1.0,
            ),
          ),
          child: Icon(icon, size: 16, color: tone),
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  final bool busy;
  final Future<void> Function() onTap;
  const _SaveBar({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppTokens.s16,
        right: AppTokens.s16,
        top: AppTokens.s12,
        bottom: MediaQuery.of(context).padding.bottom + AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        border: Border(
          top: BorderSide(color: AppTokens.border(context), width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTokens.radius16,
        child: InkWell(
          borderRadius: AppTokens.radius16,
          onTap: busy ? null : () => onTap(),
          child: Ink(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
              ),
              borderRadius: AppTokens.radius16,
              boxShadow: [
                BoxShadow(
                  color: AppTokens.brand.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.save_rounded,
                      color: Colors.white, size: 20),
                const SizedBox(width: AppTokens.s12),
                Text(
                  busy ? 'Saving...' : 'Save Custom Test',
                  style: AppTokens.titleSm(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
