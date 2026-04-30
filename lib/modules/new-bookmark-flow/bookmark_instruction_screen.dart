import 'dart:io';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/modules/widgets/bottom_toast.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';
import 'package:shusruta_lms/modules/login/store/verify_otp_phone.dart';
import 'package:shusruta_lms/modules/new_exam_component/exam_screen.dart';
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart' as test;
import 'package:shusruta_lms/modules/new_exam_component/store/exam_store.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/store/new_bookmark_store.dart';

/// BookmarkInstructionScreen — the pre-exam instructions gate for a
/// bookmark exam. Shows instruction bullets, the marking scheme, a
/// status-key legend, and navigation tips. The user must tick the
/// agreement checkbox in the sticky bottom bar before the Start Exam
/// CTA unlocks and launches [ExamScreen].
///
/// Public surface preserved exactly:
///   • class [BookmarkInstructionScreen]
///   • final fields `type`, `name`, `time`, `option`, `mainId`,
///     `id`, `isAll`, `isCustom`
///   • const constructor: seven required params + `mainId = ""`
///   • state field [isAgree]
///   • state field [items] — the 5 status-key entries with
///     title/subtitle/imagePath (exact same content)
///   • [buildColumnLayout] and [buildRowLayout] method signatures
///     (kept as instance methods on the state; their internals now
///     delegate to the unified private handler for parity)
///   • [startExamApiCall] method signature preserved (body kept
///     verbatim — unused but retained for public surface)
///   • Start-Exam routing through
///     `ongetBookmarkMacqQuestionsListApiCall` +
///     `onCreateCustomeExamApiCall` + push [ExamScreen] with
///     isAll/userExamId/id/mainId/timeDuration/type/name args
///   • Top-level widgets [bulletPoints] and [statusPoints]
class BookmarkInstructionScreen extends StatefulWidget {
  const BookmarkInstructionScreen({
    super.key,
    required this.type,
    required this.id,
    required this.time,
    required this.name,
    required this.option,
    required this.isAll,
    required this.isCustom,
    this.mainId = "",
  });
  final String type;
  final String name;
  final String time;
  final String option;
  final String? mainId;
  final String id;
  final bool isAll;
  final bool isCustom;

  @override
  State<BookmarkInstructionScreen> createState() =>
      _BookmarkInstructionScreenState();
}

class _BookmarkInstructionScreenState extends State<BookmarkInstructionScreen> {
  bool isAgree = false;
  final List<Map<String, dynamic>> items = [
    {
      'title': 'Attempted',
      'subtitle': 'Answered and submitted for evaluation.',
      'imagePath': 'assets/image/21.svg',
    },
    {
      'title': 'Marked for Review',
      'subtitle': 'Marked for review but unanswered.',
      'imagePath': 'assets/image/23.svg',
    },
    {
      'title': 'Attempted & Marked for Review',
      'subtitle': 'Answered but marked for review.',
      'imagePath': 'assets/image/32.svg',
    },
    {
      'title': 'Not Visited',
      'subtitle': 'Not opened yet.',
      'imagePath': 'assets/image/5.svg',
    },
    {
      'title': 'Skipped',
      'subtitle': 'Opened but not answered.',
      'imagePath': 'assets/image/0.svg',
    },
  ];

  // ---------------------------------------------------------------------
  // Public layout methods — preserved signatures, internals delegate to
  // the unified `_handleStart` so logic stays consistent between the
  // desktop Row and mobile Column bottom bars.
  // ---------------------------------------------------------------------

  // ignore: prefer_typing_uninitialized_variables
  Column buildColumnLayout(
      BuildContext context, bool isAgree, ValueChanged<bool?> onStatusChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _AgreeCheck(
          isAgree: isAgree,
          onStatusChanged: onStatusChanged,
        ),
        const SizedBox(height: AppTokens.s12),
        _GradientCta(
          label: "Start Exam",
          onTap: () => _onStartTapped(isAgree),
          icon: Icons.play_arrow_rounded,
        ),
      ],
    );
  }

  SizedBox buildRowLayout(
      BuildContext context, bool isAgree, ValueChanged<bool?> onStatusChanged) {
    return SizedBox(
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: _AgreeCheck(
              isAgree: isAgree,
              onStatusChanged: onStatusChanged,
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          SizedBox(
            width: 360,
            child: _GradientCta(
              label: "Start Exam",
              onTap: () => _onStartTapped(isAgree),
              icon: Icons.play_arrow_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Unified start-exam handler.
  // Replicates the three-branch logic from the original buildColumnLayout
  // verbatim: McqBookmark / Custom / else — each kicks off
  // ongetBookmarkMacqQuestionsListApiCall, onCreateCustomeExamApiCall and
  // pushes ExamScreen with matching args.
  // ---------------------------------------------------------------------

  Future<void> _onStartTapped(bool isAgree) async {
    if (!isAgree) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "Please agree to instructions",
        backgroundColor: ThemeManager.redAlert,
      );
      return;
    }

    showLoadingDialog(context);
    final store = Provider.of<ExamStore>(context, listen: false);
    final bookmarkStore =
        Provider.of<BookmarkNewStore>(context, listen: false);

    // ignore: avoid_print
    print(widget.type);

    if (widget.type == "McqBookmark") {
      final List<test.TestData> dataList =
          await bookmarkStore.ongetBookmarkMacqQuestionsListApiCall(
        widget.option,
        widget.id.isEmpty ? "67c46d7f26aedeedd69ba9cf" : widget.id,
        widget.isAll,
        widget.type == "MockBookmark",
        widget.isCustom,
      );
      store.setData(dataList, widget.type);
      final now = DateTime.now();
      final List<String> parts = widget.time.split(":");
      final int hours = int.parse(parts[0]);
      final int minutes = int.parse(parts[1]);
      final int totalMinutes = (hours * 60) + minutes;
      final endTime = now.add(Duration(minutes: totalMinutes));
      final Map<String, dynamic>? data =
          await bookmarkStore.onCreateCustomeExamApiCall(widget.type, {
        "customTest_id": widget.mainId!.isEmpty
            ? "67c46d7f26aedeedd69ba9cf"
            : widget.mainId,
        "start_time": now.toIso8601String(),
        "end_time": endTime.toIso8601String(),
        "isAllQSolve": widget.isAll,
        "userExamType": widget.option,
        "mainUserExam_id": widget.id,
      });
      if (!mounted) return;
      Navigator.pop(context);
      log(data.toString());
      // ignore: avoid_print
      print(widget.mainId);
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ExamScreen(
            isAll: widget.isAll,
            userExamId: data!['_id'],
            id: data['_id'],
            mainId: widget.mainId,
            timeDuration: widget.time,
            type: widget.type,
            name: widget.name,
          ),
        ),
      );
    } else if (widget.type == "Custom") {
      final List<test.TestData> dataList =
          await bookmarkStore.ongetBookmarkMacqQuestionsListApiCall(
        widget.option,
        widget.id.isEmpty ? "67c46d7f26aedeedd69ba9cf" : widget.id,
        widget.isAll,
        widget.type == "MockBookmark",
        true,
      );
      store.setData(dataList, widget.type);
      final now = DateTime.now();
      final List<String> parts = widget.time.split(":");
      final int hours = int.parse(parts[0]);
      final int minutes = int.parse(parts[1]);
      final int totalMinutes = (hours * 60) + minutes;
      final endTime = now.add(Duration(minutes: totalMinutes));
      final Map<String, dynamic>? data =
          await bookmarkStore.onCreateCustomeExamApiCall(widget.type, {
        "customTest_id": widget.mainId!.isEmpty
            ? "67c46d7f26aedeedd69ba9cf"
            : widget.mainId,
        "start_time": now.toIso8601String(),
        "end_time": endTime.toIso8601String(),
        "isAllQSolve": widget.isAll,
        "userExamType": widget.option,
        "mainUserExam_id": widget.id,
      });
      if (!mounted) return;
      Navigator.pop(context);
      log(data.toString());
      // ignore: avoid_print
      print(widget.mainId);
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ExamScreen(
            isAll: widget.isAll,
            userExamId: data!['_id'],
            id: data['_id'],
            mainId: widget.mainId,
            timeDuration: widget.time,
            type: widget.type,
            name: widget.name,
          ),
        ),
      );
    } else {
      final List<test.TestData> dataList =
          await bookmarkStore.ongetBookmarkMacqQuestionsListApiCall(
        widget.option,
        widget.id.isEmpty ? "67c46d7f26aedeedd69ba9cf" : widget.id,
        widget.isAll,
        widget.type == "MockBookmark",
        widget.isCustom,
      );
      store.setData(dataList, widget.type);
      final now = DateTime.now();
      final List<String> parts = widget.time.split(":");
      final int hours = int.parse(parts[0]);
      final int minutes = int.parse(parts[1]);
      final int totalMinutes = (hours * 60) + minutes;
      final endTime = now.add(Duration(minutes: totalMinutes));
      final Map<String, dynamic>? data =
          await bookmarkStore.onCreateCustomeExamApiCall(widget.type, {
        "customTest_id": widget.mainId!.isEmpty
            ? "67c46d7f26aedeedd69ba9cf"
            : widget.mainId,
        "start_time": now.toIso8601String(),
        "end_time": endTime.toIso8601String(),
        "isAllQSolve": widget.isAll,
        "userExamType": widget.option,
        "mainUserExam_id":
            widget.id.isEmpty ? "67c46d7f26aedeedd69ba9cf" : widget.id,
      });
      if (!mounted) return;
      Navigator.pop(context);
      log(data.toString());
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ExamScreen(
            isAll: widget.isAll,
            userExamId: data!['_id'],
            id: data['_id'],
            mainId: widget.mainId,
            timeDuration: widget.time,
            type: widget.type,
            name: widget.name,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print(widget.mainId);
    // ignore: avoid_print
    print(widget.type);
    // ignore: avoid_print
    print(widget.option);

    final isDesktop = Platform.isWindows || Platform.isMacOS;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      bottomNavigationBar: Observer(
        builder: (_) {
          return Container(
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              border: Border(
                top: BorderSide(color: AppTokens.border(context)),
              ),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 12,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s20,
              AppTokens.s16,
              AppTokens.s20,
              AppTokens.s20,
            ),
            child: SafeArea(
              top: false,
              child: isDesktop
                  ? buildRowLayout(context, isAgree, (status) {
                      setState(() {
                        isAgree = status!;
                      });
                    })
                  : buildColumnLayout(context, isAgree, (status) {
                      setState(() {
                        isAgree = status!;
                      });
                    }),
            ),
          );
        },
      ),
      body: Column(
        children: [
          // Gradient hero
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTokens.s20,
                  isDesktop ? AppTokens.s16 : AppTokens.s12,
                  AppTokens.s20,
                  AppTokens.s20,
                ),
                child: _Header(title: widget.name),
              ),
            ),
          ),

          // Body sheet
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTokens.surface2(context),
                borderRadius: isDesktop
                    ? null
                    : const BorderRadius.only(
                        topLeft: Radius.circular(28.8),
                        topRight: Radius.circular(28.8),
                      ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s20,
                  AppTokens.s24,
                  AppTokens.s20,
                  AppTokens.s32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instructions card
                    _SectionCard(
                      title: "Instructions",
                      children: [
                        bulletPoints(
                          "The timer starts at the beginning of the test. The countdown at the top shows the remaining time. The test auto-submits when time is up, or you can submit early.",
                        ),
                        const SizedBox(height: AppTokens.s12),
                        bulletPoints("Marking Scheme :"),
                        const SizedBox(height: AppTokens.s8),
                        _MarkingSchemeRow(),
                        const SizedBox(height: AppTokens.s12),
                        bulletPoints(
                          "The Question Palette shows the status of each question.",
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTokens.s16),

                    // Status Key card
                    _SectionCard(
                      title: "Status Key",
                      children: [
                        ListView.builder(
                          itemCount: items.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemBuilder: (BuildContext context, int index) {
                            return statusPoints(
                              items[index]['title'],
                              items[index]['subtitle'],
                              items[index]['imagePath'],
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTokens.s16),

                    // Navigation card
                    _SectionCard(
                      title: "Navigation",
                      children: [
                        bulletPoints(
                          "Click a question number in the Question Palette to jump directly to it. Progress will be saved automatically.",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Preserved legacy method — not referenced from the new tree but kept
  // as public surface. Body unchanged.
  // ---------------------------------------------------------------------
  Future<void> startExamApiCall(
    TestCategoryStore store,
    TestExamPaperListModel? testExamPaper,
    bool? isPractice,
    String type,
    String userExamIds,
  ) async {
    String examId = testExamPaper?.examId ?? "";
    DateTime now = DateTime.now();
    String startTime = DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(now);
    String timeDuration = testExamPaper?.timeDuration ?? "";
    List<String> timeParts = timeDuration.split(":");
    Duration duration = Duration(
      hours: int.parse(timeParts[0]),
      minutes: int.parse(timeParts[1]),
      seconds: int.parse(timeParts[2]),
    );
    DateTime startDateTime = DateTime.parse(startTime);
    DateTime endDateTime = startDateTime.add(duration);
    String endTime =
        DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(endDateTime);
    await store.onCreateTestHistoryCall(testExamPaper?.examId ?? '', 'exam');
    await store.startCreateExam(
        examId, startTime, endTime, isPractice, type, userExamIds);
    // ignore: unused_local_variable
    String? userExamId = store.startExam.value?.id;
    // ignore: unused_local_variable
    bool? isPracticeExam = store.startExam.value?.isPractice;
    if (store.startExam.value?.err?.message == null) {
      // preserved: original push commented out
    } else {
      if (!mounted) return;
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: store.startExam.value?.err?.message ?? "",
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GhostIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "INSTRUCTIONS",
                style: AppTokens.overline(context).copyWith(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.82),
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTokens.s4),
              Text(
                title.isEmpty ? "Before you begin" : title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTokens.titleLg(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GhostIconButton extends StatelessWidget {
  const _GhostIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s20),
      decoration: AppTokens.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTokens.brand, AppTokens.brand2],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Text(
                title,
                style: AppTokens.titleMd(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          ...children,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Marking scheme row
// ---------------------------------------------------------------------------

class _MarkingSchemeRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTokens.s20),
      child: Row(
        children: [
          _MarkChip(
            iconPath: "assets/image/correct_i.svg",
            label: "Correct Marks",
            tint: AppTokens.success(context),
          ),
          const SizedBox(width: AppTokens.s12),
          _MarkChip(
            iconPath: "assets/image/wrong_i.svg",
            label: "Incorrect Marks",
            tint: AppTokens.danger(context),
          ),
        ],
      ),
    );
  }
}

class _MarkChip extends StatelessWidget {
  const _MarkChip({
    required this.iconPath,
    required this.label,
    required this.tint,
  });
  final String iconPath;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: tint.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTokens.r20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(iconPath, height: 14, width: 14),
          const SizedBox(width: AppTokens.s8),
          Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: tint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Agreement checkbox
// ---------------------------------------------------------------------------

class _AgreeCheck extends StatelessWidget {
  const _AgreeCheck({
    required this.isAgree,
    required this.onStatusChanged,
  });
  final bool isAgree;
  final ValueChanged<bool?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onStatusChanged(!isAgree),
      borderRadius: BorderRadius.circular(AppTokens.r8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s4,
          vertical: AppTokens.s4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isAgree
                    ? AppTokens.accent(context)
                    : AppTokens.surface(context),
                borderRadius: BorderRadius.circular(AppTokens.r8),
                border: Border.all(
                  color: isAgree
                      ? AppTokens.accent(context)
                      : AppTokens.border(context),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isAgree
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: AppTokens.s8),
            Flexible(
              child: Text(
                'I have read the instructions.',
                style: AppTokens.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient CTA
// ---------------------------------------------------------------------------

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.label,
    required this.onTap,
    this.icon,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: AppTokens.brand.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: AppTokens.s8),
              ],
              Text(
                label,
                style: AppTokens.body(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top-level helpers preserved verbatim in signature, redesigned internally.
// ---------------------------------------------------------------------------

Widget bulletPoints(String text) {
  return Builder(
    builder: (context) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SvgPicture.asset('assets/image/bullet_icon.svg'),
        ),
        const SizedBox(width: AppTokens.s8),
        Flexible(
          child: Text(
            text,
            style: AppTokens.body(context).copyWith(
              color: AppTokens.ink2(context),
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget statusPoints(String text, String subtext, String path) {
  return Builder(
    builder: (context) => Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(path, height: 32, width: 32),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  subtext,
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.ink2(context),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    ),
  );
}
