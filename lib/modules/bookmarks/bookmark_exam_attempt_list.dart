import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/bookmarks/store/bookmark_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../models/bookmark_exam_list_model.dart';

/// BookMarkExamAttemptList — shows per-attempt bookmark breakdown for
/// a single exam and links into the question list for each attempt.
///
/// Public surface preserved exactly:
///   • class [BookMarkExamAttemptList]
///   • two required String fields: [id], [title]
///   • [BookMarkExamAttemptList]({Key? key, required this.id, required this.title})
///     constructor unchanged
///   • static [route] factory returns [CupertinoPageRoute] and reads
///     'id' / 'title' from the arguments map
///   • initState still calls
///     `store.onBookMarkExamTypeApiCall(widget.id)`
///   • [_getBookMarkQuestionsList] still calls
///     `store.onBookMarkQuestionListApiCall(examId)` and pushes
///     [Routes.bookMarkQuestionList] with args
///     `{ bookMarkQuestions, userExamId: examId }`
///   • Observer binding over [BookMarkStore.bookMarkByExamType] and
///     [BookMarkStore.isConnected]
class BookMarkExamAttemptList extends StatefulWidget {
  final String id;
  final String title;
  const BookMarkExamAttemptList({
    Key? key,
    required this.id,
    required this.title,
  }) : super(key: key);

  @override
  State<BookMarkExamAttemptList> createState() =>
      _BookMarkExamAttemptListState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => BookMarkExamAttemptList(
        id: arguments['id'],
        title: arguments['title'],
      ),
    );
  }
}

class _BookMarkExamAttemptListState extends State<BookMarkExamAttemptList> {
  // Preserved from the original public API even though the old screen
  // never wired it to a text field.
  // ignore: unused_field
  String query = '';

  @override
  void initState() {
    super.initState();
    final store = Provider.of<BookMarkStore>(context, listen: false);
    store.onBookMarkExamTypeApiCall(widget.id);
  }

  Future<void> _getBookMarkQuestionsList(String examId) async {
    final store = Provider.of<BookMarkStore>(context, listen: false);
    await store.onBookMarkQuestionListApiCall(examId).then((_) {
      Navigator.of(context).pushNamed(
        Routes.bookMarkQuestionList,
        arguments: {
          'bookMarkQuestions': store.bookMarkQuestionsList,
          'userExamId': examId,
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<BookMarkStore>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _Header(
            title: widget.title,
            onBack: () => Navigator.of(context).pop(),
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
              child: !store.isConnected
                  ? _Message(
                      icon: Icons.wifi_off_rounded,
                      title: 'No internet connection',
                      body: 'Reconnect and try again.',
                    )
                  : Observer(
                      builder: (_) {
                        if (store.bookMarkByExamType.isEmpty) {
                          return _Message(
                            icon: Icons.history_toggle_off_rounded,
                            title: 'No attempts yet',
                            body:
                                "We're sorry, there's no content available "
                                "right now. Check back later or explore other "
                                "sections for more educational resources.",
                          );
                        }
                        return ListView.separated(
                          itemCount: store.bookMarkByExamType.length,
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
                            final BookMarkExamListModel? item =
                                store.bookMarkByExamType[index];
                            return _AttemptCard(
                              title: widget.title,
                              attemptCount:
                                  item?.isAttemptcount?.toString() ?? '',
                              bookmarksCount: item?.bookmarksCount,
                              onTap: () => _getBookMarkQuestionsList(
                                item?.userExamId ?? '',
                              ),
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
  const _Header({required this.title, required this.onBack});

  final String title;
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
                      'ATTEMPTS',
                      style: AppTokens.overline(context).copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTokens.titleLg(context).copyWith(
                        color: Colors.white,
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

class _AttemptCard extends StatelessWidget {
  const _AttemptCard({
    required this.title,
    required this.attemptCount,
    required this.bookmarksCount,
    required this.onTap,
  });

  final String title;
  final String attemptCount;
  final int? bookmarksCount;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTokens.titleSm(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
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
                      attemptCount.isEmpty
                          ? 'Attempt'
                          : 'Attempt $attemptCount',
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.accent(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (bookmarksCount != null && bookmarksCount! > 0) ...[
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Icon(
                      Icons.bookmark_rounded,
                      size: 14,
                      color: AppTokens.muted(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$bookmarksCount bookmarked',
                      style: AppTokens.caption(context),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppTokens.s12),
              Container(height: 1, color: AppTokens.border(context)),
              const SizedBox(height: AppTokens.s12),
              Row(
                children: [
                  Text(
                    'View Questions',
                    style: AppTokens.titleSm(context).copyWith(
                      color: AppTokens.accent(context),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppTokens.accent(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

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
                icon,
                color: AppTokens.accent(context),
                size: 38,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              title,
              style: AppTokens.titleLg(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              body,
              style: AppTokens.body(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
