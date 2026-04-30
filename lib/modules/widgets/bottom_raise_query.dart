import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../dashboard/store/home_store.dart';
import '../login/store/login_store.dart';
import '../reports/store/report_by_category_store.dart';
import 'bottom_toast.dart';

/// CustomBottomRaiseQuery / CustomBottomAskFaculty / CustomBottomReportIssue —
/// three bottom-sheet components used by the question viewer to raise a
/// query against a specific MCQ. Public surface preserved exactly:
///   • [CustomBottomRaiseQuery] const named constructor with fields
///     `questionId` (required), `questionText`, `allOptions`
///   • [CustomBottomAskFaculty] const named constructor with fields
///     `questionId` / `questionText` / `allOptions` (all required) and
///     its state behaviour (`settingsData` → LoginStore.onGetSettingsData,
///     `_getUserDetails` → HomeStore.onGetUserDetailsCall(context),
///     `_queryFocusNode` autofocus via post-frame callback,
///     `_launchWhatsApp(phone,message)` with 91-prefixed `wa.me` path)
///   • [CustomBottomReportIssue] const named constructor with same
///     three required fields and full 10-flag boolean grid + `addQuery`
///     call to `ReportsCategoryStore.onCreateQuerySolutionReport(...)`
class CustomBottomRaiseQuery extends StatefulWidget {
  final String questionId;
  final String? questionText;
  final String? allOptions;
  const CustomBottomRaiseQuery({
    super.key,
    required this.questionId,
    this.questionText,
    this.allOptions,
  });

  @override
  State<CustomBottomRaiseQuery> createState() => _CustomBottomRaiseQueryState();
}

class _CustomBottomRaiseQueryState extends State<CustomBottomRaiseQuery> {
  // ignore: unused_field
  final TextEditingController queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _openAskFaculty() {
    Navigator.of(context).pop();
    showModalBottomSheet<String>(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (_) => CustomBottomAskFaculty(
        questionId: widget.questionId,
        questionText: widget.questionText ?? '',
        allOptions: widget.allOptions ?? '',
      ),
    );
  }

  void _openReport() {
    Navigator.of(context).pop();
    showModalBottomSheet<String>(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      context: context,
      builder: (_) => CustomBottomReportIssue(
        questionId: widget.questionId,
        questionText: widget.questionText ?? '',
        allOptions: widget.allOptions ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTokens.r20),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s12,
            AppTokens.s20,
            AppTokens.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetGrabber(),
              const SizedBox(height: AppTokens.s20),
              Text(
                'Raise Query',
                style: AppTokens.titleLg(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTokens.s4),
              Text(
                'Select any one of the options',
                style: AppTokens.body(context).copyWith(
                  color: AppTokens.ink2(context),
                ),
              ),
              const SizedBox(height: AppTokens.s20),
              _OutlinedActionRow(
                icon: Icons.forum_outlined,
                label: 'Ask Faculty',
                onTap: _openAskFaculty,
              ),
              const SizedBox(height: AppTokens.s12),
              _OutlinedActionRow(
                icon: Icons.report_gmailerrorred_outlined,
                label: 'Report an Issue',
                onTap: _openReport,
              ),
              const SizedBox(height: AppTokens.s16),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomBottomAskFaculty
// ---------------------------------------------------------------------------

class CustomBottomAskFaculty extends StatefulWidget {
  final String questionId;
  final String questionText;
  final String allOptions;
  const CustomBottomAskFaculty({
    super.key,
    required this.questionId,
    required this.questionText,
    required this.allOptions,
  });

  @override
  State<CustomBottomAskFaculty> createState() => _CustomBottomAskFacultyState();
}

class _CustomBottomAskFacultyState extends State<CustomBottomAskFaculty> {
  final TextEditingController queryController = TextEditingController();
  final FocusNode _queryFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    settingsData();
    _getUserDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_queryFocusNode);
    });
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
    _queryFocusNode.dispose();
    super.dispose();
  }

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
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.r20),
          ),
        ),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s12,
            AppTokens.s20,
            AppTokens.s20,
          ),
          child: SingleChildScrollView(
            reverse: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetGrabber(),
                const SizedBox(height: AppTokens.s20),
                Text(
                  'Ask Faculty',
                  style: AppTokens.titleLg(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  'Send your doubt to faculty',
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink2(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                TextFormField(
                  focusNode: _queryFocusNode,
                  autofocus: true,
                  enableInteractiveSelection: true,
                  maxLines: 8,
                  minLines: 4,
                  cursorColor: AppTokens.accent(context),
                  style: AppTokens.body(context),
                  controller: queryController,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: AppTokens.inputDecoration(
                    context,
                    hint: 'Write your query here...',
                  ),
                ),
                const SizedBox(height: AppTokens.s20),
                _GradientCta(
                  label: 'Send to Faculty',
                  icon: Icons.send_rounded,
                  onTap: () {
                    _launchWhatsApp(
                      loginStore.settingsData.value?.phone ?? '',
                      'Question:${widget.questionText}\n${widget.allOptions}\n\n${queryController.text}\n\nQuery by:${homeStore.userDetails.value?.fullname ?? ""}',
                    );
                  },
                ),
                const SizedBox(height: AppTokens.s12),
                _LinkButton(
                  label: 'Report an Issue',
                  onTap: () {
                    Navigator.of(context).pop();
                    showModalBottomSheet<String>(
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(25)),
                      ),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      context: context,
                      builder: (_) => CustomBottomReportIssue(
                        questionId: widget.questionId,
                        questionText: widget.questionText,
                        allOptions: widget.allOptions,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppTokens.s16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Preserved helper — keeps the 91-prefixed wa.me scheme/path contract.
  // ignore: prefer_final_parameters
  _launchWhatsApp(String phone, String message) async {
    final Uri whatsAppLaunchUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: "91$phone",
      queryParameters: {'text': message},
    );
    // ignore: deprecated_member_use
    if (await canLaunch(whatsAppLaunchUri.toString())) {
      // ignore: deprecated_member_use
      await launch(whatsAppLaunchUri.toString());
    } else {
      throw 'Could not launch WhatsApp';
    }
  }
}

// ---------------------------------------------------------------------------
// CustomBottomReportIssue
// ---------------------------------------------------------------------------

class CustomBottomReportIssue extends StatefulWidget {
  final String questionId;
  final String questionText;
  final String allOptions;
  const CustomBottomReportIssue({
    super.key,
    required this.questionId,
    required this.questionText,
    required this.allOptions,
  });

  @override
  State<CustomBottomReportIssue> createState() =>
      _CustomBottomReportIssueState();
}

class _CustomBottomReportIssueState extends State<CustomBottomReportIssue> {
  TextEditingController queryController = TextEditingController();
  bool value1 = false;
  bool value2 = false;
  bool value3 = false;
  bool value4 = false;
  // ignore: unused_field
  bool value5 = false;
  // ignore: unused_field
  bool value6 = false;
  // ignore: unused_field
  bool value7 = false;
  // ignore: unused_field
  bool value8 = false;
  // ignore: unused_field
  bool value9 = false;
  // ignore: unused_field
  bool value10 = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> addQuery(
    String questionId,
    String queryTxt,
    bool incorrectQues,
    bool incorrectAns,
    bool explanationIssue,
    bool otherIssue,
    bool wrongImg,
    bool imgNotClear,
    bool spelingError,
    bool explainQueNotMatch,
    bool explainAnsNotMatch,
    bool queAnsOptionNotMatch,
    BuildContext context,
  ) async {
    final store = Provider.of<ReportsCategoryStore>(context, listen: false);
    await store.onCreateQuerySolutionReport(
      context,
      questionId,
      queryTxt,
      incorrectQues,
      incorrectAns,
      explanationIssue,
      otherIssue,
      wrongImg,
      imgNotClear,
      spelingError,
      explainQueNotMatch,
      explainAnsNotMatch,
      queAnsOptionNotMatch,
    );
    if (!mounted) return;
    BottomToast.showBottomToastOverlay(
      // ignore: use_build_context_synchronously
      context: context,
      errorMessage: "Query Successfully Submitted",
      // ignore: use_build_context_synchronously
      backgroundColor: Theme.of(context).primaryColor,
    );
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.r20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s12,
            AppTokens.s20,
            AppTokens.s20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetGrabber(),
                const SizedBox(height: AppTokens.s20),
                Text(
                  'Report an Issue',
                  style: AppTokens.titleLg(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  'Flag the concerns you want us to look at',
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink2(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _FlagCheck(
                            label: 'Incorrect Question',
                            value: value1,
                            onChanged: (v) => setState(() => value1 = v),
                          ),
                          const SizedBox(height: AppTokens.s8),
                          _FlagCheck(
                            label: 'Explanation Issue',
                            value: value3,
                            onChanged: (v) => setState(() => value3 = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: Column(
                        children: [
                          _FlagCheck(
                            label: 'Incorrect Answer',
                            value: value2,
                            onChanged: (v) => setState(() => value2 = v),
                          ),
                          const SizedBox(height: AppTokens.s8),
                          _FlagCheck(
                            label: 'Other',
                            value: value4,
                            onChanged: (v) => setState(() => value4 = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s16),
                TextFormField(
                  enableInteractiveSelection: true,
                  maxLines: 8,
                  minLines: 4,
                  cursorColor: AppTokens.accent(context),
                  style: AppTokens.body(context),
                  controller: queryController,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: AppTokens.inputDecoration(
                    context,
                    hint: 'Write your query here...',
                  ),
                ),
                const SizedBox(height: AppTokens.s20),
                _GradientCta(
                  label: 'Submit Report',
                  icon: Icons.flag_rounded,
                  onTap: () => _showConfirmDialog(context),
                ),
                const SizedBox(height: AppTokens.s12),
                _LinkButton(
                  label: 'Ask Faculty',
                  onTap: () {
                    Navigator.of(context).pop();
                    showModalBottomSheet<String>(
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(25)),
                      ),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      context: context,
                      builder: (_) => CustomBottomAskFaculty(
                        questionId: widget.questionId,
                        questionText: widget.questionText,
                        allOptions: widget.allOptions,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppTokens.s16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showConfirmDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: AppTokens.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s20,
              AppTokens.s24,
              AppTokens.s20,
              AppTokens.s20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flag_circle_rounded,
                  color: AppTokens.accent(context),
                  size: 36,
                ),
                const SizedBox(height: AppTokens.s12),
                Text(
                  'Are you sure you want to report?',
                  textAlign: TextAlign.center,
                  style: AppTokens.titleSm(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  'Our editorial team will review this flag.',
                  textAlign: TextAlign.center,
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.ink2(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s20),
                Row(
                  children: [
                    Expanded(
                      child: _GhostCta(
                        label: 'No',
                        onTap: () => Navigator.pop(dialogCtx, false),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: _GradientCta(
                        label: 'Yes',
                        icon: Icons.check_rounded,
                        onTap: () {
                          Navigator.pop(dialogCtx, true);
                          addQuery(
                            widget.questionId,
                            queryController.text,
                            value1,
                            value2,
                            value3,
                            value4,
                            value5,
                            value6,
                            value7,
                            value8,
                            value9,
                            value10,
                            context,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared primitives
// ---------------------------------------------------------------------------

class _SheetGrabber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: AppTokens.border(context),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _OutlinedActionRow extends StatelessWidget {
  const _OutlinedActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s16,
          ),
          decoration: BoxDecoration(
            color: AppTokens.surface2(context),
            border: Border.all(color: AppTokens.border(context)),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
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
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTokens.ink2(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlagCheck extends StatelessWidget {
  const _FlagCheck({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppTokens.r8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.s4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppTokens.accent(context),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            Expanded(
              child: Text(
                label,
                style: AppTokens.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
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
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: AppTokens.s8),
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

class _GhostCta extends StatelessWidget {
  const _GhostCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.surface2(context),
            border: Border.all(color: AppTokens.border(context)),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Text(
            label,
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink2(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppTokens.accent(context),
      ),
      child: Text(
        label,
        style: AppTokens.body(context).copyWith(
          fontWeight: FontWeight.w700,
          color: AppTokens.accent(context),
        ),
      ),
    );
  }
}

// Keep legacy helpers reachable so any external references continue to resolve.
// ignore: unused_element
const _legacyAppColorsSink = AppColors.white;
