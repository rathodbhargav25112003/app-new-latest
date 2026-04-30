import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/bookmarks/store/bookmark_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/bookmark_by_examlist_model.dart';
import '../widgets/bottom_toast.dart';

/// SelectBookMarkExamList — shows the exams that carry bookmarks
/// inside a chosen category / subcategory / topic.
///
/// Public surface preserved exactly:
///   • class [SelectBookMarkExamList] and its three required String
///     fields: [id], [title], [type]
///   • static [route] factory returns a [CupertinoPageRoute] and
///     reads 'id', 'title' and 'type' from the arguments map
///   • initState call `store.onBookMarkExamByCategoryApiCall(id, type)`
///   • Observer binding over [BookMarkStore.bookMarkByExam],
///     [BookMarkStore.isLoading] and [BookMarkStore.isConnected]
///   • the private [_getBookMarkQuestions] helper keeps its push to
///     [Routes.bookMarkQuestionDetail] with the exact same args
///     contract ({ bookMarkQuestions, examId, queIndex: 0 }) plus the
///     "No Bookmarks questions found!" toast fallback
class SelectBookMarkExamList extends StatefulWidget {
  final String id;
  final String title;
  final String type;
  const SelectBookMarkExamList({
    Key? key,
    required this.id,
    required this.title,
    required this.type,
  }) : super(key: key);

  @override
  State<SelectBookMarkExamList> createState() => _SelectBookMarkExamListState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => SelectBookMarkExamList(
        id: arguments['id'],
        title: arguments['title'],
        type: arguments['type'],
      ),
    );
  }
}

class _SelectBookMarkExamListState extends State<SelectBookMarkExamList> {
  @override
  void initState() {
    super.initState();
    final store = Provider.of<BookMarkStore>(context, listen: false);
    store.onBookMarkExamByCategoryApiCall(widget.id, widget.type);
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<BookMarkStore>(context);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _Header(
            title: widget.title,
            type: widget.type,
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s20,
                  AppTokens.s24,
                  AppTokens.s20,
                  AppTokens.s16,
                ),
                child: Observer(
                  builder: (_) {
                    if (!store.isConnected) {
                      return _Message(
                        icon: Icons.wifi_off_rounded,
                        title: 'No internet connection',
                        body:
                            'Reconnect and pull this screen down to try again.',
                      );
                    }
                    if (store.isLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppTokens.accent(context),
                          strokeWidth: 2.5,
                        ),
                      );
                    }
                    if (store.bookMarkByExam.isEmpty) {
                      return _Message(
                        icon: Icons.bookmark_border_rounded,
                        title: 'Nothing saved here yet',
                        body:
                            "We're sorry, there's no content available right "
                            "now. Check back later or explore other sections "
                            "for more educational resources.",
                      );
                    }
                    return ListView.separated(
                      itemCount: store.bookMarkByExam.length,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTokens.s12),
                      itemBuilder: (context, index) {
                        final BookMarkByExamListModel? item =
                            store.bookMarkByExam[index];
                        final String bookMarkCount =
                            item?.bookmarkCount.toString() ?? '0';
                        return _ExamCard(
                          examName: item?.examName ?? '',
                          bookMarkCount: bookMarkCount,
                          onTap: () => _getBookMarkQuestions(item),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getBookMarkQuestions(
      BookMarkByExamListModel? bookMarkByExam) async {
    final store = Provider.of<BookMarkStore>(context, listen: false);
    await store
        .onBookMarkQuestionListApiCall(bookMarkByExam?.examId ?? '')
        .then((_) {
      if (store.bookMarkQuestionsList.isNotEmpty) {
        Navigator.of(context).pushNamed(
          Routes.bookMarkQuestionDetail,
          arguments: {
            'bookMarkQuestions': store.bookMarkQuestionsList,
            'examId': bookMarkByExam?.examId,
            'queIndex': 0,
          },
        );
      } else {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: "No Bookmarks questions found!",
          backgroundColor: Theme.of(context).primaryColor,
        );
      }
    });
  }
}

// ────────────────────────────────────────────────────────────────────
// Private widgets
// ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.type,
    required this.onBack,
  });

  final String title;
  final String type;
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
                      _prettyType(type),
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

  String _prettyType(String raw) {
    switch (raw.toLowerCase()) {
      case 'topic':
        return 'TOPIC';
      case 'subcategory':
        return 'SUBCATEGORY';
      case 'category':
        return 'CATEGORY';
      default:
        return raw.toUpperCase();
    }
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.examName,
    required this.bookMarkCount,
    required this.onTap,
  });

  final String examName;
  final String bookMarkCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
            children: [
              Container(
                height: 48,
                width: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: AppTokens.radius12,
                ),
                child: SvgPicture.asset(
                  'assets/image/bookmarktopic.svg',
                  width: 22,
                  height: 22,
                  color: isDark ? AppColors.white : AppTokens.accent(context),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      examName.isNotEmpty ? examName : 'Untitled exam',
                      style: AppTokens.titleSm(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTokens.s4),
                    Row(
                      children: [
                        Icon(
                          Icons.bookmark_rounded,
                          size: 14,
                          color: AppTokens.accent(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$bookMarkCount Questions',
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.accent(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
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
