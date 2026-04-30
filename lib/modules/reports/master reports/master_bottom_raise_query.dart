// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unnecessary_import, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
import 'package:shusruta_lms/modules/login/store/login_store.dart';
import 'package:shusruta_lms/modules/reports/store/report_by_category_store.dart';
import 'package:shusruta_lms/modules/videolectures/store/video_category_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_toast.dart';

/// Mock-exam "Raise Query" flow — three chained sheets/dialogs.
///
/// Preserved public contract:
///   • `MockBottomRaiseQuery({super.key, required questionId,
///     questionText, allOptions})`
///   • `MockBottomAskFaculty({super.key, required questionId,
///     required questionText, required allOptions})`
///   • `MockBottomReportIssue({super.key, required questionId,
///     required questionText, required allOptions})`
///   • Platform split `Platform.isWindows || Platform.isMacOS`
///     → `AlertDialog`, else → `showModalBottomSheet`.
///   • `MockBottomAskFaculty.initState` calls
///     `LoginStore.onGetSettingsData()` and
///     `HomeStore.onGetUserDetailsCall(context)`.
///   • Send → `_launchWhatsApp(phone, 'Question:...\n...\n\n...\n\nQuery by:...')`.
///   • Report → confirm dialog ("Are you sure you want to report?"),
///     then `addMockQuery(...)` → `store.onCreateQueryMock(context,
///     questionId, queryTxt, incorrectQues, incorrectAns,
///     explanationIssue, otherIssue)` + BottomToast
///     "Query Successfully Submitted" + pop.
///   • All user-facing labels preserved verbatim.

class MockBottomRaiseQuery extends StatefulWidget {
  final String questionId;
  final String? questionText;
  final String? allOptions;
  const MockBottomRaiseQuery({
    super.key,
    required this.questionId,
    this.questionText,
    this.allOptions,
  });

  @override
  State<MockBottomRaiseQuery> createState() => _MockBottomRaiseQueryState();
}

class _MockBottomRaiseQueryState extends State<MockBottomRaiseQuery> {
  TextEditingController queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  void _openAskFaculty() {
    Navigator.of(context).pop();
    if (_isDesktop) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.scaffold(context),
            insetPadding: const EdgeInsets.symmetric(horizontal: 100),
            actionsPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.r20),
            ),
            actions: [
              MockBottomAskFaculty(
                questionId: widget.questionId,
                questionText: widget.questionText ?? '',
                allOptions: widget.allOptions ?? '',
              ),
            ],
          );
        },
      );
    } else {
      showModalBottomSheet<String>(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTokens.r20)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return MockBottomAskFaculty(
            questionId: widget.questionId,
            questionText: widget.questionText ?? '',
            allOptions: widget.allOptions ?? '',
          );
        },
      );
    }
  }

  void _openReportIssue() {
    Navigator.of(context).pop();
    if (_isDesktop) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTokens.scaffold(context),
            insetPadding: const EdgeInsets.symmetric(horizontal: 100),
            actionsPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.r20),
            ),
            actions: [
              MockBottomReportIssue(
                questionId: widget.questionId,
                questionText: widget.questionText ?? '',
                allOptions: widget.allOptions ?? '',
              ),
            ],
          );
        },
      );
    } else {
      showModalBottomSheet<String>(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTokens.r20)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return MockBottomReportIssue(
            questionId: widget.questionId,
            questionText: widget.questionText ?? '',
            allOptions: widget.allOptions ?? '',
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          _isDesktop ? const BoxConstraints(maxWidth: 520) : null,
      decoration: BoxDecoration(
        color: AppTokens.scaffold(context),
        borderRadius:
            _isDesktop ? BorderRadius.circular(AppTokens.r20) : null,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s16,
        AppTokens.s20,
        AppTokens.s16,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (!_isDesktop)
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.border(context),
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
              ),
            if (!_isDesktop) const SizedBox(height: AppTokens.s16),
            Text(
              'Raise Query',
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              'Select any one of the options',
              style: AppTokens.body(context).copyWith(
                color: AppTokens.muted(context),
              ),
            ),
            const SizedBox(height: AppTokens.s24),
            _OptionTile(
              label: 'Ask Faculty ?',
              icon: Icons.forum_outlined,
              onTap: _openAskFaculty,
            ),
            const SizedBox(height: AppTokens.s12),
            _OptionTile(
              label: 'Report an Issue',
              icon: Icons.report_gmailerrorred_rounded,
              onTap: _openReportIssue,
            ),
            const SizedBox(height: AppTokens.s20),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OptionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r16),
      child: Container(
        height: 56,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          border: Border.all(color: AppTokens.border(context)),
          borderRadius: BorderRadius.circular(AppTokens.r16),
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
              child: Icon(
                icon,
                color: AppTokens.accent(context),
                size: 18,
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Text(
                label,
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTokens.ink(context),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTokens.muted(context),
            ),
          ],
        ),
      ),
    );
  }
}

class MockBottomAskFaculty extends StatefulWidget {
  final String questionId;
  final String questionText;
  final String allOptions;
  const MockBottomAskFaculty({
    super.key,
    required this.questionId,
    required this.questionText,
    required this.allOptions,
  });

  @override
  State<MockBottomAskFaculty> createState() => _MockBottomAskFacultyState();
}

class _MockBottomAskFacultyState extends State<MockBottomAskFaculty> {
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

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    final loginStore = Provider.of<LoginStore>(context, listen: false);
    final homeStore = Provider.of<HomeStore>(context, listen: false);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        constraints:
            _isDesktop ? const BoxConstraints(maxWidth: 520) : null,
        decoration: BoxDecoration(
          color: AppTokens.scaffold(context),
          borderRadius:
              _isDesktop ? BorderRadius.circular(AppTokens.r20) : null,
        ),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s16,
          AppTokens.s20,
          AppTokens.s16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (!_isDesktop)
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.border(context),
                    borderRadius: BorderRadius.circular(AppTokens.r8),
                  ),
                ),
              if (!_isDesktop) const SizedBox(height: AppTokens.s16),
              Text(
                'Ask Faculty',
                style: AppTokens.titleSm(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink(context),
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                'Send Your Doubt to Faculty',
                style: AppTokens.body(context).copyWith(
                  color: AppTokens.muted(context),
                ),
              ),
              const SizedBox(height: AppTokens.s20),
              Container(
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  border: Border.all(color: AppTokens.border(context)),
                ),
                child: TextFormField(
                  maxLines: 6,
                  cursorColor: AppTokens.accent(context),
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink(context),
                  ),
                  controller: queryController,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Write your query here...',
                    hintStyle: AppTokens.body(context).copyWith(
                      color: AppTokens.muted(context),
                    ),
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s12,
                      vertical: AppTokens.s12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s20),
              InkWell(
                onTap: () {
                  _launchWhatsApp(
                    loginStore.settingsData.value?.phone ?? "",
                    'Question:${widget.questionText}\n${widget.allOptions}\n\n${queryController.text}\n\nQuery by:${homeStore.userDetails.value?.fullname ?? ""}',
                  );
                },
                borderRadius: BorderRadius.circular(AppTokens.r28),
                child: Container(
                  alignment: Alignment.center,
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTokens.brand, AppTokens.brand2],
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.r28),
                  ),
                  child: Text(
                    'Send',
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  if (_isDesktop) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: AppTokens.scaffold(context),
                          insetPadding:
                              const EdgeInsets.symmetric(horizontal: 100),
                          actionsPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTokens.r20),
                          ),
                          actions: [
                            MockBottomReportIssue(
                              questionId: widget.questionId,
                              questionText: widget.questionText,
                              allOptions: widget.allOptions,
                            ),
                          ],
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
                      builder: (BuildContext context) {
                        return MockBottomReportIssue(
                          questionId: widget.questionId,
                          questionText: widget.questionText,
                          allOptions: widget.allOptions,
                        );
                      },
                    );
                  }
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTokens.s8),
                  child: Text(
                    'Report an Issue',
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTokens.accent(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s20),
            ],
          ),
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

class MockBottomReportIssue extends StatefulWidget {
  final String questionId;
  final String questionText;
  final String allOptions;
  const MockBottomReportIssue({
    super.key,
    required this.questionId,
    required this.questionText,
    required this.allOptions,
  });

  @override
  State<MockBottomReportIssue> createState() => _MockBottomReportIssueState();
}

class _MockBottomReportIssueState extends State<MockBottomReportIssue> {
  TextEditingController queryController = TextEditingController();
  bool value1 = false;
  bool value2 = false;
  bool value3 = false;
  bool value4 = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> addMockQuery(
      String questionId,
      String queryTxt,
      bool incorrectQues,
      bool incorrectAns,
      bool explanationIssue,
      bool otherIssue,
      BuildContext context) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onCreateQueryMock(context, questionId, queryTxt, incorrectQues,
        incorrectAns, explanationIssue, otherIssue);
    BottomToast.showBottomToastOverlay(
      context: context,
      errorMessage: "Query Successfully Submitted",
      backgroundColor: Theme.of(context).primaryColor,
    );
    Navigator.of(context).pop();
  }

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppTokens.surface(ctx),
        surfaceTintColor: Colors.transparent,
        contentPadding: const EdgeInsets.fromLTRB(
          AppTokens.s24,
          AppTokens.s24,
          AppTokens.s24,
          AppTokens.s12,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          0,
          AppTokens.s20,
          AppTokens.s20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
        ),
        content: Text(
          'Are you sure you want to report?',
          style: AppTokens.body(ctx).copyWith(
            fontWeight: FontWeight.w600,
            color: AppTokens.ink(ctx),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pop(ctx, false),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTokens.brand, AppTokens.brand2],
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                    ),
                    child: Text(
                      'No',
                      style: AppTokens.body(ctx).copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    addMockQuery(
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
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTokens.surface(ctx),
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                      border:
                          Border.all(color: AppTokens.accent(ctx)),
                    ),
                    child: Text(
                      'Yes',
                      style: AppTokens.body(ctx).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTokens.accent(ctx),
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

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            value: value,
            onChanged: onChanged,
            activeColor: AppTokens.accent(context),
            side: MaterialStateBorderSide.resolveWith(
              (states) => BorderSide(color: AppTokens.border(context)),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.r8),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Flexible(
          child: Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.ink(context),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        constraints:
            _isDesktop ? const BoxConstraints(maxWidth: 520) : null,
        decoration: BoxDecoration(
          color: AppTokens.scaffold(context),
          borderRadius:
              _isDesktop ? BorderRadius.circular(AppTokens.r20) : null,
        ),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s16,
          AppTokens.s20,
          AppTokens.s16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (!_isDesktop)
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.border(context),
                    borderRadius: BorderRadius.circular(AppTokens.r8),
                  ),
                ),
              if (!_isDesktop) const SizedBox(height: AppTokens.s16),
              Text(
                'Report an Issue',
                style: AppTokens.titleSm(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink(context),
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                'Ask question to faculty',
                style: AppTokens.body(context).copyWith(
                  color: AppTokens.muted(context),
                ),
              ),
              const SizedBox(height: AppTokens.s20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s12,
                  vertical: AppTokens.s12,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  border: Border.all(color: AppTokens.border(context)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCheckbox(
                            value: value1,
                            onChanged: (v) =>
                                setState(() => value1 = v ?? false),
                            label: 'Incorrect Question',
                          ),
                          const SizedBox(height: AppTokens.s12),
                          _buildCheckbox(
                            value: value3,
                            onChanged: (v) =>
                                setState(() => value3 = v ?? false),
                            label: 'Explanation Issue',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCheckbox(
                            value: value2,
                            onChanged: (v) =>
                                setState(() => value2 = v ?? false),
                            label: 'Incorrect Answer',
                          ),
                          const SizedBox(height: AppTokens.s12),
                          _buildCheckbox(
                            value: value4,
                            onChanged: (v) =>
                                setState(() => value4 = v ?? false),
                            label: 'Other',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.s16),
              Container(
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  border: Border.all(color: AppTokens.border(context)),
                ),
                child: TextFormField(
                  maxLines: 6,
                  cursorColor: AppTokens.accent(context),
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink(context),
                  ),
                  controller: queryController,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Write your query here...',
                    hintStyle: AppTokens.body(context).copyWith(
                      color: AppTokens.muted(context),
                    ),
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s12,
                      vertical: AppTokens.s12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s20),
              InkWell(
                onTap: _showConfirmDialog,
                borderRadius: BorderRadius.circular(AppTokens.r28),
                child: Container(
                  alignment: Alignment.center,
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTokens.brand, AppTokens.brand2],
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.r28),
                  ),
                  child: Text(
                    'Report',
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  if (_isDesktop) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: AppTokens.scaffold(context),
                          insetPadding:
                              const EdgeInsets.symmetric(horizontal: 100),
                          actionsPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTokens.r20),
                          ),
                          actions: [
                            MockBottomAskFaculty(
                              questionId: widget.questionId,
                              questionText: widget.questionText,
                              allOptions: widget.allOptions,
                            ),
                          ],
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
                      builder: (BuildContext context) {
                        return MockBottomAskFaculty(
                          questionId: widget.questionId,
                          questionText: widget.questionText,
                          allOptions: widget.allOptions,
                        );
                      },
                    );
                  }
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTokens.s8),
                  child: Text(
                    'Ask Faculty ?',
                    style: AppTokens.body(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTokens.accent(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s20),
            ],
          ),
        ),
      ),
    );
  }
}
