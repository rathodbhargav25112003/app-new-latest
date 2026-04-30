import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../models/solution_reports_model.dart';

/// BookMarkQuestionList — compact list of bookmarked questions for
/// a single exam attempt. Tapping a row opens the full detail screen
/// at the corresponding index.
///
/// Public surface preserved exactly:
///   • class [BookMarkQuestionList]
///   • nullable fields [bookMarkQuestionsList]
///     (`List<SolutionReportsModel>?`) and [examId] (`String?`)
///   • [BookMarkQuestionList]({Key? key, this.bookMarkQuestionsList,
///     this.examId}) constructor unchanged
///   • static [route] factory returns [CupertinoPageRoute] and reads
///     'bookMarkQuestions' + 'examId' from the arguments map
///   • tap navigation still pushes [Routes.bookMarkQuestionDetail]
///     with arguments { 'bookMarkQuestions', 'queIndex', 'examId' }
///   • the questionText cleanup rules (strip `----...----`,
///     collapse blank lines, replace `--` with `•`) are preserved
class BookMarkQuestionList extends StatefulWidget {
  final List<SolutionReportsModel>? bookMarkQuestionsList;
  final String? examId;
  const BookMarkQuestionList({
    Key? key,
    this.bookMarkQuestionsList,
    this.examId,
  }) : super(key: key);

  @override
  State<BookMarkQuestionList> createState() => _BookMarkQuestionListState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => BookMarkQuestionList(
        bookMarkQuestionsList: arguments["bookMarkQuestions"],
        examId: arguments["examId"],
      ),
    );
  }
}

class _BookMarkQuestionListState extends State<BookMarkQuestionList> {
  @override
  Widget build(BuildContext context) {
    final List<SolutionReportsModel> items =
        widget.bookMarkQuestionsList ?? const [];
    final String countLabel = items.length.toString().padLeft(2, '0');
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _Header(
            count: countLabel,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28.8),
                  topRight: Radius.circular(28.8),
                ),
              ),
              child: items.isEmpty
                  ? _EmptyState()
                  : ListView.separated(
                      itemCount: items.length,
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.s20,
                        AppTokens.s24,
                        AppTokens.s20,
                        AppTokens.s24,
                      ),
                      physics: const BouncingScrollPhysics(),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTokens.s12),
                      itemBuilder: (context, index) {
                        final SolutionReportsModel item = items[index];
                        // Preserve the original questionText cleanup:
                        //   • strip `----...----` markers
                        //   • collapse multi-line blanks
                        //   • replace `--` with `•`
                        var inputString = item.questionText ?? '';
                        inputString = inputString.replaceAllMapped(
                          RegExp(r'^----(.*?)----$', multiLine: true),
                          (match) => '',
                        );
                        inputString = inputString
                            .replaceAll(RegExp(r'\n{2,}'), '\n')
                            .trim();
                        final String modifiedExplanation =
                            inputString.replaceAll('--', '•');

                        final String questionNumber = item.questionNumber
                                ?.toString()
                                .padLeft(2, '0') ??
                            '--';

                        return _QuestionCard(
                          questionNumber: questionNumber,
                          questionText: modifiedExplanation,
                          onTap: () {
                            debugPrint('examidbookmark${widget.examId}');
                            Navigator.of(context).pushNamed(
                              Routes.bookMarkQuestionDetail,
                              arguments: {
                                'bookMarkQuestions':
                                    widget.bookMarkQuestionsList,
                                'queIndex': index,
                                'examId': widget.examId,
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Private widgets
// ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onBack});

  final String count;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s12,
            AppTokens.s8,
            AppTokens.s20,
            AppTokens.s24,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: onBack,
                  child: Container(
                    height: 40,
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.22),
                      ),
                    ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bookmark Questions',
                      style: AppTokens.titleLg(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count Questions',
                      style: AppTokens.caption(context).copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                  ),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.questionNumber,
    required this.questionText,
    required this.onTap,
  });

  final String questionNumber;
  final String questionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppTokens.radius16,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: AppTokens.radius16,
            border: Border.all(color: AppTokens.border(context)),
            boxShadow: AppTokens.shadow1(context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: AppTokens.radius8,
                ),
                child: Text(
                  'Q $questionNumber',
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.accent(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Text(
                  questionText.isEmpty
                      ? 'Tap to view this bookmarked question'
                      : questionText,
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink(context),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTokens.muted(context),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 84,
              width: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                color: AppTokens.accent(context),
                size: 38,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'No bookmarks in this attempt',
              style: AppTokens.titleLg(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              "We're sorry, there's no content available right now. "
              "Check back later or explore other sections for more "
              "educational resources.",
              style: AppTokens.body(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
