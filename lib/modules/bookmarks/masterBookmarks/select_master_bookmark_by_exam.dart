import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/bookmarks/store/bookmark_store.dart';
import 'package:shusruta_lms/modules/new_exam_component/widget/loading_box.dart';

import '../../../app/routes.dart';
import '../../../helpers/app_tokens.dart';
import '../../../helpers/colors.dart';
import '../../../models/bookmark_by_examlist_model.dart';
import '../../widgets/bottom_toast.dart';

/// SelectMasterBookMarkExamList — surfaces the master exams that belong
/// to a bookmarked category/subcategory/topic and lets the user jump
/// straight into the bookmarked questions inside each exam.
///
/// Public surface preserved exactly:
///   • class [SelectMasterBookMarkExamList]
///   • three required String fields: [id], [title], [type]
///   • [SelectMasterBookMarkExamList]({Key? key, required this.id,
///     required this.title, required this.type}) constructor unchanged
///   • static [route] factory returns [CupertinoPageRoute] and reads
///     'categoryId' → id, 'categoryName' → title, 'type' → type
///   • initState still calls
///     `store.onMasterBookMarkExamListApiCall(widget.id)`
///   • [_getBookMarkQuestions] still wraps
///     `store.onMasterBookMarkQuestionListApiCall(examId)` with
///     [showLoadingDialog] + [Navigator.pop] and then navigates to
///     [Routes.masterBookMarkQuestionDetail] with
///     `{ bookMarkQuestions, examId, queIndex: 0 }` — or falls back to
///     [BottomToast.showBottomToastOverlay] when the list is empty
///   • Observer binding over [BookMarkStore.masterbookMarkByExam] and
///     [BookMarkStore.isConnected]
class SelectMasterBookMarkExamList extends StatefulWidget {
  final String id;
  final String title;
  final String type;
  const SelectMasterBookMarkExamList({
    Key? key,
    required this.id,
    required this.title,
    required this.type,
  }) : super(key: key);

  @override
  State<SelectMasterBookMarkExamList> createState() =>
      _SelectMasterBookMarkExamListState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => SelectMasterBookMarkExamList(
        id: arguments['categoryId'],
        title: arguments['categoryName'],
        type: arguments['type'],
      ),
    );
  }
}

class _SelectMasterBookMarkExamListState
    extends State<SelectMasterBookMarkExamList> {
  @override
  void initState() {
    super.initState();
    final store = Provider.of<BookMarkStore>(context, listen: false);
    store.onMasterBookMarkExamListApiCall(widget.id);
  }

  Future<void> _getBookMarkQuestions(
      BookMarkByExamListModel? bookMarkByExam) async {
    final store = Provider.of<BookMarkStore>(context, listen: false);
    showLoadingDialog(context);
    await store
        .onMasterBookMarkQuestionListApiCall(bookMarkByExam?.examId ?? "")
        .then((_) {
      Navigator.pop(context);
      if (store.masterBookMarkQuestionsList.isNotEmpty) {
        Navigator.of(context)
            .pushNamed(Routes.masterBookMarkQuestionDetail, arguments: {
          'bookMarkQuestions': store.masterBookMarkQuestionsList,
          'examId': bookMarkByExam?.examId,
          'queIndex': 0
        });
      } else {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: "No Bookmarks questions found!",
          backgroundColor: Theme.of(context).primaryColor,
        );
      }
    });
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
              child: !store.isConnected
                  ? _Message(
                      icon: Icons.wifi_off_rounded,
                      title: 'No internet connection',
                      body: 'Reconnect and try again.',
                    )
                  : Observer(
                      builder: (_) {
                        if (store.masterbookMarkByExam.isEmpty) {
                          return _Message(
                            icon: Icons.bookmark_border_rounded,
                            title: 'No master bookmarks here',
                            body:
                                "We're sorry, there's no content available "
                                "right now. Check back later or explore other "
                                "sections for more educational resources.",
                          );
                        }
                        return ListView.separated(
                          itemCount: store.masterbookMarkByExam.length,
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
                            final BookMarkByExamListModel? bookMarkByExam =
                                store.masterbookMarkByExam[index];
                            final String bookMarkCount =
                                bookMarkByExam?.bookmarkCount?.toString() ??
                                    '0';
                            return _ExamCard(
                              examName: bookMarkByExam?.examName ?? '',
                              bookMarkCount: bookMarkCount,
                              onTap: () =>
                                  _getBookMarkQuestions(bookMarkByExam),
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
  const _Header({
    required this.title,
    required this.type,
    required this.onBack,
  });

  final String title;
  final String type;
  final VoidCallback onBack;

  String get _overline {
    final t = type.toLowerCase();
    if (t == 'category') return 'MASTER · CATEGORY';
    if (t == 'subcategory') return 'MASTER · SUBCATEGORY';
    if (t == 'topic') return 'MASTER · TOPIC';
    return 'MASTER BOOKMARKS';
  }

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
                      _overline,
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
                  Icons.auto_stories_rounded,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 48,
                width: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: AppTokens.radius12,
                ),
                padding: const EdgeInsets.all(AppTokens.s8),
                child: SvgPicture.asset(
                  'assets/image/bookmarktopic.svg',
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
                      examName.isEmpty ? 'Untitled exam' : examName,
                      style: AppTokens.titleSm(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
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
