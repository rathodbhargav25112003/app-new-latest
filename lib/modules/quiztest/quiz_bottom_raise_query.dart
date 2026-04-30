// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_build_context_synchronously, non_constant_identifier_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
import 'package:shusruta_lms/modules/login/store/login_store.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_toast.dart';

/// "Raise Query" family of bottom sheets shown from the quiz flow —
/// entry sheet with two routes (Ask Faculty / Report an Issue) and
/// the two destination sheets.
///
/// Preserved public contract:
///   • `CustomQuizBottomRaiseQuery({super.key, required this.questionId,
///     this.questionText, this.allOptions})` — 1 required + 2 optional
///     fields preserved byte-for-byte.
///   • `CustomQuizBottomAskFaculty({super.key, required this.questionId,
///     required this.questionText, required this.allOptions})` — 3
///     required fields preserved.
///   • `CustomQuizBottomReportIssue({super.key, required this.questionId,
///     required this.questionText, required this.allOptions})` — 3
///     required fields preserved.
///   • `addQuizQuery(questionId, queryTxt, incorrectQues, incorrectAns,
///     explanationIssue, otherIssue, context)` 7-arg signature
///     preserved, calls `ReportsCategoryStore.onCreateQueryQuiz(...)`
///     then shows `"Query Successfully Submitted"` toast and pops.
///   • `_launchWhatsApp(phone, message)` builds
///     `https://wa.me/91$phone?text=…` and falls back to
///     `throw 'Could not launch WhatsApp'`.
///   • Cross-navigation between the three sheets preserved
///     (Ask-Faculty ⇄ Report-Issue footer links and the chooser
///     forwarding into each).
///   • Desktop vs mobile split preserved — Windows/macOS route through
///     `showDialog` + `AlertDialog(actions:[…])`, Android/iOS route
///     through `showModalBottomSheet`.
///   • Label strings preserved byte-for-byte: 'Raise Query',
///     'Select any one of the options', 'Ask Faculty ?', 'Ask Faculty',
///     'Send Your Doubt to Faculty', 'Report an Issue',
///     'Ask question to faculty', 'Incorrect Question',
///     'Incorrect Answer', 'Explanation Issue', 'Other',
///     'Write your query here...', 'Send', 'Report',
///     'Are you sure you want to report?', 'No', 'Yes',
///     'Query Successfully Submitted'.

bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

// ─────────────────────────────────────────────────────────────────────────────
// CustomQuizBottomRaiseQuery — chooser sheet
// ─────────────────────────────────────────────────────────────────────────────

class CustomQuizBottomRaiseQuery extends StatefulWidget {
  final String questionId;
  final String? questionText;
  final String? allOptions;
  const CustomQuizBottomRaiseQuery({
    super.key,
    required this.questionId,
    this.questionText,
    this.allOptions,
  });

  @override
  State<CustomQuizBottomRaiseQuery> createState() =>
      _CustomQuizBottomRaiseQueryState();
}

class _CustomQuizBottomRaiseQueryState
    extends State<CustomQuizBottomRaiseQuery> {
  TextEditingController queryController = TextEditingController();
  bool isCustomKeyboardOpen = false;

  @override
  void initState() {
    super.initState();
  }

  void _openAskFaculty() {
    Navigator.of(context).pop();
    final child = CustomQuizBottomAskFaculty(
      questionId: widget.questionId,
      questionText: widget.questionText ?? '',
      allOptions: widget.allOptions ?? '',
    );
    _presentSheet(context, child);
  }

  void _openReportIssue() {
    Navigator.of(context).pop();
    final child = CustomQuizBottomReportIssue(
      questionId: widget.questionId,
      questionText: widget.questionText ?? '',
      allOptions: widget.allOptions ?? '',
    );
    _presentSheet(context, child);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const _DragHandle(),
          const SizedBox(height: AppTokens.s16),
          Text(
            'Raise Query',
            style: AppTokens.titleSm(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink(context),
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          Text(
            'Select any one of the options',
            style: AppTokens.body(context).copyWith(
              color: AppTokens.muted(context),
            ),
          ),
          const SizedBox(height: AppTokens.s20),
          _OptionTile(label: 'Ask Faculty ?', onTap: _openAskFaculty),
          const SizedBox(height: AppTokens.s12),
          _OptionTile(label: 'Report an Issue', onTap: _openReportIssue),
          SizedBox(height: MediaQuery.of(context).size.height * 0.06),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomQuizBottomAskFaculty — WhatsApp-send sheet
// ─────────────────────────────────────────────────────────────────────────────

class CustomQuizBottomAskFaculty extends StatefulWidget {
  final String questionId;
  final String questionText;
  final String allOptions;
  const CustomQuizBottomAskFaculty({
    super.key,
    required this.questionId,
    required this.questionText,
    required this.allOptions,
  });

  @override
  State<CustomQuizBottomAskFaculty> createState() =>
      _CustomQuizBottomAskFacultyState();
}

class _CustomQuizBottomAskFacultyState
    extends State<CustomQuizBottomAskFaculty> {
  TextEditingController queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    settingsData();
    _getUserDetails();
  }

  Future<void> settingsData() async {
    final store = Provider.of<LoginStore>(context, listen: false);
    await store.onGetSettingsData();
  }

  Future<void> _getUserDetails() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onGetUserDetailsCall(context);
  }

  @override
  Widget build(BuildContext context) {
    final loginStore = Provider.of<LoginStore>(context, listen: false);
    final homeStore = Provider.of<HomeStore>(context, listen: false);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _SheetShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const _DragHandle(),
            const SizedBox(height: AppTokens.s16),
            Text(
              'Ask Faculty',
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            Text(
              'Send Your Doubt to Faculty',
              style: AppTokens.body(context).copyWith(
                color: AppTokens.muted(context),
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            _QueryTextField(controller: queryController),
            const SizedBox(height: AppTokens.s20),
            _PrimaryPillButton(
              label: 'Send',
              onTap: () {
                _launchWhatsApp(
                  loginStore.settingsData.value?.phone ?? "",
                  'Question:${widget.questionText}\n${widget.allOptions}\n\n${queryController.text}\n\nQuery by:${homeStore.userDetails.value?.fullname ?? ""}',
                );
              },
            ),
            const SizedBox(height: AppTokens.s16),
            _FooterLink(
              label: 'Report an Issue',
              onTap: () {
                Navigator.of(context).pop();
                final child = CustomQuizBottomReportIssue(
                  questionId: widget.questionId,
                  questionText: widget.questionText,
                  allOptions: widget.allOptions,
                );
                _presentSheet(context, child);
              },
            ),
            const SizedBox(height: AppTokens.s32),
          ],
        ),
      ),
    );
  }

  _launchWhatsApp(String phone, String message) async {
    final Uri whatsAppLaunchUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: "91$phone",
      queryParameters: {'text': message},
    );
    if (await canLaunch(whatsAppLaunchUri.toString())) {
      await launch(whatsAppLaunchUri.toString());
    } else {
      throw 'Could not launch WhatsApp';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomQuizBottomReportIssue — 4-checkbox report sheet
// ─────────────────────────────────────────────────────────────────────────────

class CustomQuizBottomReportIssue extends StatefulWidget {
  final String questionId;
  final String questionText;
  final String allOptions;
  const CustomQuizBottomReportIssue({
    super.key,
    required this.questionId,
    required this.questionText,
    required this.allOptions,
  });

  @override
  State<CustomQuizBottomReportIssue> createState() =>
      _CustomQuizBottomReportIssueState();
}

class _CustomQuizBottomReportIssueState
    extends State<CustomQuizBottomReportIssue> {
  TextEditingController queryController = TextEditingController();
  bool isCustomKeyboardOpen = false;
  bool value1 = false;
  bool value2 = false;
  bool value3 = false;
  bool value4 = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> addQuizQuery(
    String questionId,
    String queryTxt,
    bool incorrectQues,
    bool incorrectAns,
    bool explanationIssue,
    bool otherIssue,
    BuildContext context,
  ) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onCreateQueryQuiz(
      context,
      questionId,
      queryTxt,
      incorrectQues,
      incorrectAns,
      explanationIssue,
      otherIssue,
    );
    BottomToast.showBottomToastOverlay(
      context: context,
      errorMessage: "Query Successfully Submitted",
      backgroundColor: Theme.of(context).primaryColor,
    );
    Navigator.of(context).pop();
  }

  void _openConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTokens.surface(context),
        surfaceTintColor: AppTokens.surface(context),
        contentPadding: const EdgeInsets.only(
          top: AppTokens.s20,
          left: AppTokens.s24,
          right: AppTokens.s24,
          bottom: AppTokens.s12,
        ),
        alignment: Alignment.center,
        actionsPadding: const EdgeInsets.only(
          left: AppTokens.s20,
          right: AppTokens.s20,
          bottom: AppTokens.s24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
        ),
        content: Text(
          'Are you sure you want to report?',
          style: AppTokens.titleSm(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppTokens.ink(context),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pop(context, false),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  child: Container(
                    height: AppTokens.s32 + AppTokens.s16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTokens.brand, AppTokens.brand2],
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                      boxShadow: AppTokens.shadow1(context),
                    ),
                    child: Text(
                      'No',
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    debugPrint(
                        "widget.questionId:${widget.questionId}");
                    addQuizQuery(
                      widget.questionId,
                      queryController.text,
                      value1,
                      value2,
                      value3,
                      value4,
                      context,
                    );
                  },
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  child: Container(
                    height: AppTokens.s32 + AppTokens.s16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                      border:
                          Border.all(color: AppColors.primaryColor),
                      color: AppTokens.surface(context),
                    ),
                    child: Text(
                      'Yes',
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _SheetShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const _DragHandle(),
            const SizedBox(height: AppTokens.s16),
            Text(
              'Report an Issue',
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            Text(
              'Ask question to faculty',
              style: AppTokens.body(context).copyWith(
                color: AppTokens.muted(context),
              ),
            ),
            const SizedBox(height: AppTokens.s20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReportCheckRow(
                      label: 'Incorrect Question',
                      value: value1,
                      onChanged: (v) => setState(() => value1 = v ?? false),
                    ),
                    const SizedBox(height: AppTokens.s12),
                    _ReportCheckRow(
                      label: 'Explanation Issue',
                      value: value3,
                      onChanged: (v) => setState(() => value3 = v ?? false),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReportCheckRow(
                      label: 'Incorrect Answer',
                      value: value2,
                      onChanged: (v) => setState(() => value2 = v ?? false),
                    ),
                    const SizedBox(height: AppTokens.s12),
                    _ReportCheckRow(
                      label: 'Other',
                      value: value4,
                      onChanged: (v) => setState(() => value4 = v ?? false),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s16),
            _QueryTextField(controller: queryController),
            const SizedBox(height: AppTokens.s20),
            _PrimaryPillButton(
              label: 'Report',
              onTap: _openConfirmDialog,
            ),
            const SizedBox(height: AppTokens.s16),
            _FooterLink(
              label: 'Ask Faculty ?',
              onTap: () {
                Navigator.of(context).pop();
                final child = CustomQuizBottomAskFaculty(
                  questionId: widget.questionId,
                  questionText: widget.questionText,
                  allOptions: widget.allOptions,
                );
                _presentSheet(context, child);
              },
            ),
            const SizedBox(height: AppTokens.s32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared presentation helper — desktop dialog vs mobile modal sheet
// ─────────────────────────────────────────────────────────────────────────────

void _presentSheet(BuildContext context, Widget child) {
  if (_isDesktop) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTokens.surface(context),
          surfaceTintColor: AppTokens.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r16),
          ),
          actionsPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.symmetric(horizontal: 250),
          actions: [child],
        );
      },
    );
  } else {
    showModalBottomSheet<String>(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.r20),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (BuildContext context) => child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _isDesktop ? null : MediaQuery.of(context).size.width,
      constraints: _isDesktop
          ? const BoxConstraints(maxWidth: Dimensions.WEB_MAX_WIDTH * 0.4)
          : null,
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: _isDesktop
            ? BorderRadius.circular(AppTokens.r20)
            : const BorderRadius.vertical(
                top: Radius.circular(AppTokens.r20),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppTokens.s20,
          left: AppTokens.s24,
          right: AppTokens.s24,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return const SizedBox.shrink();
    }
    return Container(
      width: AppTokens.s32 + AppTokens.s16,
      height: 4,
      decoration: BoxDecoration(
        color: AppTokens.border(context),
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r28),
      child: Container(
        alignment: Alignment.center,
        height: AppTokens.s32 + AppTokens.s20,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: AppTokens.surface2(context),
          border: Border.all(color: AppTokens.border(context)),
          borderRadius: BorderRadius.circular(AppTokens.r28),
        ),
        child: Text(
          label,
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppTokens.ink(context),
          ),
        ),
      ),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r28),
      child: Container(
        alignment: Alignment.center,
        height: AppTokens.s32 + AppTokens.s20,
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTokens.brand, AppTokens.brand2],
          ),
          borderRadius: BorderRadius.circular(AppTokens.r28),
          boxShadow: AppTokens.shadow2(context),
        ),
        child: Text(
          label,
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12,
          vertical: AppTokens.s8,
        ),
        child: Text(
          label,
          style: AppTokens.body(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _QueryTextField extends StatelessWidget {
  const _QueryTextField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.2,
      child: TextFormField(
        enableInteractiveSelection: true,
        maxLines: 10,
        minLines: 3,
        cursorColor: AppTokens.ink(context),
        style: AppTokens.body(context).copyWith(
          color: AppTokens.ink(context),
        ),
        controller: controller,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTokens.surface2(context),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            borderSide: BorderSide(color: AppTokens.border(context)),
          ),
          hintText: 'Write your query here...',
          hintStyle: AppTokens.caption(context).copyWith(
            color: AppTokens.muted(context),
          ),
          counterText: '',
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            borderSide:
                BorderSide(color: AppColors.primaryColor, width: 1.2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            borderSide: BorderSide(color: AppTokens.border(context)),
          ),
        ),
      ),
    );
  }
}

class _ReportCheckRow extends StatelessWidget {
  const _ReportCheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryColor,
          side: MaterialStateBorderSide.resolveWith(
            (states) => BorderSide(color: AppTokens.border(context)),
          ),
        ),
        Text(
          label,
          style: AppTokens.caption(context).copyWith(
            fontWeight: FontWeight.w500,
            color: AppTokens.ink(context),
          ),
        ),
      ],
    );
  }
}
