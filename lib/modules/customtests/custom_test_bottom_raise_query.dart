// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../helpers/app_tokens.dart';
// ignore: unused_import
import '../../../helpers/colors.dart';
// ignore: unused_import
import '../../../helpers/dimensions.dart';
// ignore: unused_import
import '../../../helpers/styles.dart';
// ignore: unused_import
import '../dashboard/store/home_store.dart';
import '../login/store/login_store.dart';
import '../reports/store/report_by_category_store.dart';
import '../widgets/bottom_toast.dart';
import '../dashboard/store/home_store.dart' show HomeStore;

// ============================================================================
// 1) Chooser — "Raise Query"
// ============================================================================

class CustomTestBottomRaiseQuery extends StatefulWidget {
  final String questionId;
  final String? questionText;
  final String? allOptions;
  const CustomTestBottomRaiseQuery({
    super.key,
    required this.questionId,
    this.questionText,
    this.allOptions,
  });

  @override
  State<CustomTestBottomRaiseQuery> createState() =>
      _CustomTestBottomRaiseQueryState();
}

class _CustomTestBottomRaiseQueryState
    extends State<CustomTestBottomRaiseQuery> {
  // Preserved from legacy implementation — unused in the polished chooser sheet
  // but kept so downstream references/store listeners stay stable.
  // ignore: unused_field
  final TextEditingController queryController = TextEditingController();
  // ignore: unused_field
  bool isCustomKeyboardOpen = false;

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  void _openAskFaculty() {
    Navigator.of(context).pop();
    showModalBottomSheet<String>(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.r28)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (BuildContext context) {
        return CustomTestBottomAskFaculty(
          questionId: widget.questionId,
          questionText: widget.questionText ?? '',
          allOptions: widget.allOptions ?? '',
        );
      },
    );
  }

  void _openReportIssue() {
    Navigator.of(context).pop();
    showModalBottomSheet<String>(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.r28)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (BuildContext context) {
        return CustomTestBottomReportIssue(
          questionId: widget.questionId,
          questionText: widget.questionText ?? '',
          allOptions: widget.allOptions ?? '',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Raise Query',
      subtitle: 'Choose how you\'d like to reach us',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChoiceTile(
            icon: Icons.chat_bubble_outline_rounded,
            iconTone: AppTokens.accent(context),
            iconSoft: AppTokens.accentSoft(context),
            title: 'Ask Faculty',
            helper: 'Send your doubt directly over WhatsApp',
            onTap: _openAskFaculty,
          ),
          const SizedBox(height: AppTokens.s12),
          _ChoiceTile(
            icon: Icons.outlined_flag_rounded,
            iconTone: AppTokens.warning(context),
            iconSoft: AppTokens.warningSoft(context),
            title: 'Report an Issue',
            helper: 'Flag an incorrect question, answer or explanation',
            onTap: _openReportIssue,
          ),
          const SizedBox(height: AppTokens.s24),
        ],
      ),
    );
  }
}

// ============================================================================
// 2) Ask Faculty bottom sheet
// ============================================================================

class CustomTestBottomAskFaculty extends StatefulWidget {
  final String questionId;
  final String questionText;
  final String allOptions;
  const CustomTestBottomAskFaculty({
    super.key,
    required this.questionId,
    required this.questionText,
    required this.allOptions,
  });

  @override
  State<CustomTestBottomAskFaculty> createState() =>
      _CustomTestBottomAskFacultyState();
}

class _CustomTestBottomAskFacultyState
    extends State<CustomTestBottomAskFaculty> {
  final TextEditingController queryController = TextEditingController();
  bool _isLaunching = false;

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
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  void _openReportIssue() {
    Navigator.of(context).pop();
    showModalBottomSheet<String>(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.r28)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (BuildContext context) {
        debugPrint("widget.questionId:${widget.questionId}");
        return CustomTestBottomReportIssue(
          questionId: widget.questionId,
          questionText: widget.questionText,
          allOptions: widget.allOptions,
        );
      },
    );
  }

  Future<void> _onSendTap() async {
    final loginStore = Provider.of<LoginStore>(context, listen: false);
    final homeStore = Provider.of<HomeStore>(context, listen: false);
    if (_isLaunching) return;
    setState(() => _isLaunching = true);
    final phone = loginStore.settingsData.value?.phone ?? "";
    final fullname = homeStore.userDetails.value?.fullname ?? "";
    final message =
        'Question:${widget.questionText}\n${widget.allOptions}\n\n${queryController.text}\n\nQuery by:$fullname';
    try {
      await _launchWhatsApp(phone, message);
    } catch (_) {
      if (mounted) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: "Could not open WhatsApp",
          backgroundColor: AppTokens.danger(context),
        );
      }
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = queryController.text.trim().isNotEmpty;
    return _SheetShell(
      title: 'Ask Faculty',
      subtitle: 'Send your doubt to the faculty team',
      onBack: () {
        Navigator.of(context).pop();
        showModalBottomSheet<String>(
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppTokens.r28)),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          context: context,
          builder: (BuildContext context) => CustomTestBottomRaiseQuery(
            questionId: widget.questionId,
            questionText: widget.questionText,
            allOptions: widget.allOptions,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QueryInput(
            controller: queryController,
            hint: 'Write your query here...',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppTokens.s20),
          _CtaButton(
            label: 'Send on WhatsApp',
            icon: Icons.send_rounded,
            enabled: canSend,
            busy: _isLaunching,
            onTap: _onSendTap,
          ),
          const SizedBox(height: AppTokens.s12),
          _SecondaryLink(
            label: 'Report an Issue instead',
            onTap: _openReportIssue,
          ),
          const SizedBox(height: AppTokens.s24),
        ],
      ),
    );
  }

  // Preserved byte-for-byte: URL shape, scheme/host, `91$phone` prefix,
  // canLaunch/launch — so backend/legacy routing continues to match.
  // ignore: unused_element
  _launchWhatsApp(String phone, String message) async {
    final Uri whatsAppLaunchUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: "91$phone",
      queryParameters: {
        'text': message,
      },
    );
    if (await canLaunch(whatsAppLaunchUri.toString())) {
      await launch(whatsAppLaunchUri.toString());
    } else {
      throw 'Could not launch WhatsApp';
    }
  }
}

// ============================================================================
// 3) Report an Issue bottom sheet
// ============================================================================

class CustomTestBottomReportIssue extends StatefulWidget {
  final String questionId;
  final String questionText;
  final String allOptions;
  const CustomTestBottomReportIssue({
    super.key,
    required this.questionId,
    required this.questionText,
    required this.allOptions,
  });

  @override
  State<CustomTestBottomReportIssue> createState() =>
      _CustomTestBottomReportIssueState();
}

class _CustomTestBottomReportIssueState
    extends State<CustomTestBottomReportIssue> {
  final TextEditingController queryController = TextEditingController();
  bool value1 = false;
  bool value2 = false;
  bool value3 = false;
  bool value4 = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  Future<void> addCustomTestQuery(
    String questionId,
    String queryTxt,
    bool incorrectQues,
    bool incorrectAns,
    bool explanationIssue,
    bool otherIssue,
    BuildContext context,
  ) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onCreateQueryCustomTest(
      context,
      questionId,
      queryTxt,
      incorrectQues,
      incorrectAns,
      explanationIssue,
      otherIssue,
    );
    if (!mounted) return;
    BottomToast.showBottomToastOverlay(
      context: context,
      errorMessage: "Query Successfully Submitted",
      backgroundColor: Theme.of(context).primaryColor,
    );
    Navigator.of(context).pop();
  }

  void _openAskFaculty() {
    Navigator.of(context).pop();
    showModalBottomSheet<String>(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.r28)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (BuildContext context) {
        return CustomTestBottomAskFaculty(
          questionId: widget.questionId,
          questionText: widget.questionText,
          allOptions: widget.allOptions,
        );
      },
    );
  }

  bool get _hasSelection => value1 || value2 || value3 || value4;

  Future<void> _onReportTap() async {
    if (_isSubmitting) return;
    final proceed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => _ReportConfirmDialog(),
    );
    if (proceed != true) return;
    if (!mounted) return;
    setState(() => _isSubmitting = true);
    debugPrint("widget.questionId:${widget.questionId}");
    try {
      await addCustomTestQuery(
        widget.questionId,
        queryController.text,
        value1,
        value2,
        value3,
        value4,
        context,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Report an Issue',
      subtitle: 'Tell us what\'s wrong with this question',
      onBack: () {
        Navigator.of(context).pop();
        showModalBottomSheet<String>(
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppTokens.r28)),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          context: context,
          builder: (BuildContext context) => CustomTestBottomRaiseQuery(
            questionId: widget.questionId,
            questionText: widget.questionText,
            allOptions: widget.allOptions,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What\'s the problem?',
            style: AppTokens.titleSm(context).copyWith(
              color: AppTokens.ink(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            children: [
              Expanded(
                child: _ReportChoicePill(
                  label: 'Incorrect\nQuestion',
                  icon: Icons.help_outline_rounded,
                  selected: value1,
                  onTap: () => setState(() => value1 = !value1),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: _ReportChoicePill(
                  label: 'Incorrect\nAnswer',
                  icon: Icons.cancel_outlined,
                  selected: value2,
                  onTap: () => setState(() => value2 = !value2),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            children: [
              Expanded(
                child: _ReportChoicePill(
                  label: 'Explanation\nIssue',
                  icon: Icons.menu_book_outlined,
                  selected: value3,
                  onTap: () => setState(() => value3 = !value3),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: _ReportChoicePill(
                  label: 'Other',
                  icon: Icons.more_horiz_rounded,
                  selected: value4,
                  onTap: () => setState(() => value4 = !value4),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s20),
          Text(
            'Additional details',
            style: AppTokens.titleSm(context).copyWith(
              color: AppTokens.ink(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          _QueryInput(
            controller: queryController,
            hint: 'Describe the issue briefly...',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppTokens.s20),
          _CtaButton(
            label: 'Submit Report',
            icon: Icons.flag_rounded,
            enabled: _hasSelection,
            busy: _isSubmitting,
            onTap: _onReportTap,
          ),
          const SizedBox(height: AppTokens.s12),
          _SecondaryLink(
            label: 'Ask Faculty instead',
            onTap: _openAskFaculty,
          ),
          const SizedBox(height: AppTokens.s24),
        ],
      ),
    );
  }
}

// ============================================================================
// Confirmation dialog for Report submission
// ============================================================================

class _ReportConfirmDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTokens.surface(context),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
      shape: const RoundedRectangleBorder(borderRadius: AppTokens.radius20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s24,
          AppTokens.s20,
          AppTokens.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTokens.warningSoft(context),
                borderRadius: AppTokens.radius16,
              ),
              child: Icon(
                Icons.outlined_flag_rounded,
                color: AppTokens.warning(context),
                size: 30,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'Submit report?',
              textAlign: TextAlign.center,
              style: AppTokens.titleMd(context).copyWith(
                color: AppTokens.ink(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              'This report will be sent to our content team for review.',
              textAlign: TextAlign.center,
              style: AppTokens.body(context)
                  .copyWith(color: AppTokens.ink2(context)),
            ),
            const SizedBox(height: AppTokens.s24),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(false),
                    filled: false,
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: _DialogButton(
                    label: 'Submit',
                    onTap: () => Navigator.of(context).pop(true),
                    filled: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Material(
        color: Colors.transparent,
        borderRadius: AppTokens.radius12,
        child: InkWell(
          borderRadius: AppTokens.radius12,
          onTap: onTap,
          child: Ink(
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
              ),
              borderRadius: AppTokens.radius12,
              boxShadow: [
                BoxShadow(
                  color: AppTokens.brand.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: AppTokens.titleSm(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Material(
      color: AppTokens.surface2(context),
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius12,
            border: Border.all(color: AppTokens.border(context), width: 1.2),
          ),
          child: Text(
            label,
            style: AppTokens.titleSm(context).copyWith(
              color: AppTokens.ink(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Shared primitives
// ============================================================================

class _SheetShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onBack;
  const _SheetShell({
    required this.title,
    required this.child,
    this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTokens.r28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s12,
                AppTokens.s20,
                AppTokens.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTokens.border(context),
                        borderRadius: BorderRadius.circular(AppTokens.r8),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.s16),
                  Row(
                    children: [
                      if (onBack != null)
                        Padding(
                          padding: const EdgeInsets.only(right: AppTokens.s12),
                          child: _BackChip(onTap: onBack!),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTokens.titleLg(context).copyWith(
                                color: AppTokens.ink(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: AppTokens.s4),
                              Text(
                                subtitle!,
                                style: AppTokens.body(context).copyWith(
                                  color: AppTokens.ink2(context),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s20),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackChip extends StatelessWidget {
  final VoidCallback onTap;
  const _BackChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surface2(context),
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius12,
            border: Border.all(color: AppTokens.border(context), width: 1.1),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppTokens.ink(context),
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final Color iconTone;
  final Color iconSoft;
  final String title;
  final String helper;
  final VoidCallback onTap;
  const _ChoiceTile({
    required this.icon,
    required this.iconTone,
    required this.iconSoft,
    required this.title,
    required this.helper,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surface2(context),
      borderRadius: AppTokens.radius16,
      child: InkWell(
        borderRadius: AppTokens.radius16,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius16,
            border: Border.all(color: AppTokens.border(context), width: 1.1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconSoft,
                  borderRadius: AppTokens.radius12,
                ),
                child: Icon(icon, color: iconTone, size: 24),
              ),
              const SizedBox(width: AppTokens.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTokens.titleMd(context).copyWith(
                        color: AppTokens.ink(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTokens.s4),
                    Text(
                      helper,
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.ink2(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTokens.ink2(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportChoicePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ReportChoicePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accent(context);
    final accentSoft = AppTokens.accentSoft(context);
    return Material(
      color: selected ? accentSoft : AppTokens.surface2(context),
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
              color: selected ? accent : AppTokens.border(context),
              width: selected ? 1.6 : 1.1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.7)
                      : AppTokens.surface(context),
                  borderRadius: AppTokens.radius8,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: selected ? accent : AppTokens.ink2(context),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  style: AppTokens.caption(context).copyWith(
                    color: selected ? accent : AppTokens.ink(context),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: selected ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                  border: Border.all(
                    color: selected ? accent : AppTokens.border(context),
                    width: 1.4,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueryInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  const _QueryInput({
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accent(context);
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      minLines: 4,
      maxLines: 8,
      cursorColor: accent,
      style: AppTokens.body(context).copyWith(color: AppTokens.ink(context)),
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      enableInteractiveSelection: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTokens.surface2(context),
        hintText: hint,
        hintStyle:
            AppTokens.body(context).copyWith(color: AppTokens.ink2(context)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16,
          vertical: AppTokens.s12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTokens.radius12,
          borderSide: BorderSide(
            color: AppTokens.border(context),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTokens.radius12,
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: AppTokens.radius12,
          borderSide: BorderSide(
            color: AppTokens.border(context),
            width: 1.1,
          ),
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool busy;
  final Future<void> Function() onTap;
  const _CtaButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy;
    return Opacity(
      opacity: active ? 1.0 : 0.55,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTokens.radius16,
        child: InkWell(
          borderRadius: AppTokens.radius16,
          onTap: active ? () => onTap() : null,
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
                  Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: AppTokens.s12),
                Text(
                  busy ? 'Please wait...' : label,
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

class _SecondaryLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTokens.radius8,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12,
            vertical: AppTokens.s8,
          ),
          child: Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.accent(context),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: AppTokens.accent(context),
            ),
          ),
        ),
      ),
    );
  }
}
