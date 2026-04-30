import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../models/get_user_details_model.dart';
import '../dashboard/store/home_store.dart';
import '../login/verify_otp_mail.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_change_mobile_bottomsheet.dart';

/// EditProfile — profile edit screen for a logged-in user.
///
/// UPGRADE NOTES (ruchir-new-app-upgrade-ui, screen 10):
/// - Same route factory and `GetUserDetailsModel` argument contract.
/// - Same store calls (HomeStore.onGetStanderdList,
///   onUpdateUserDetailsCall, onSignoutUser, onDeleteNotificationToken,
///   onDeleteUserAccountCall) and same CustomChangeMobileBottomSheet
///   invocation for phone / email change.
/// - AppTokens for typography / colors / spacing / radii.
/// - Name + DoB + mobile + email re-rendered with a unified
///   AppTokens.inputDecoration; phone + email stay read-only with a
///   trailing "Change" affordance that opens the bottom sheet.
/// - Read-only hierarchy (Group / Preparing-for / exam tags) now shown
///   as a soft-surface summary card instead of inline rows.
/// - PG Resident / Post-Graduate rebuilt as mutually-exclusive
///   _RadioCard tiles matching screen 09.
/// - Dead state (password / confirmPass / obsolete validity booleans)
///   and ~500 lines of commented-out blocks removed.
class EditProfile extends StatefulWidget {
  final GetUserDetailsModel userprofile;
  const EditProfile({Key? key, required this.userprofile}) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => EditProfile(
        userprofile: arguments['userprofile'],
      ),
    );
  }
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  DateTime? selectedDate;
  String selectedValue = '';
  String standerdFor = '';
  List<String> selectedCheckboxValues = [];
  String? currentStatus;
  String? selectedStandardId;
  bool isSubmitted = false;
  String loggedInPlatform = '';

  final _nameKey = GlobalKey<FormFieldState<String>>();
  final _mobileKey = GlobalKey<FormFieldState<String>>();
  final _emailKey = GlobalKey<FormFieldState<String>>();
  final _dobKey = GlobalKey<FormFieldState<String>>();

  final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  bool get _isCurrentStatusPicked => currentStatus == 'PG Resident' || currentStatus == 'Post-Graduate';

  @override
  void initState() {
    super.initState();
    nameController.text = widget.userprofile.fullname ?? '';
    dateController.text = widget.userprofile.dateOfBirth ?? '';
    phoneController.text = widget.userprofile.phone ?? '';
    emailController.text = widget.userprofile.email ?? '';
    currentStatus = widget.userprofile.currentData ?? '';

    Future.microtask(() async {
      final store = Provider.of<HomeStore>(context, listen: false);
      await store.onGetStanderdList();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  String _detectPlatform() {
    final deviceType = getDeviceType(context);
    final String type = deviceType == DeviceType.Tablet ? 'Tablet' : 'Mobile';
    if (Platform.isIOS) return 'ios$type';
    if (Platform.isAndroid) return 'android$type';
    if (Platform.isMacOS) return 'macOSDesktop';
    if (Platform.isWindows) return 'windowsDesktop';
    return 'unknownDesktop';
  }

  // ignore: unused_element
  void _signOut(HomeStore store, String loggedInPlatform) async {
    final prefs = await SharedPreferences.getInstance();
    final String? fcmToken = prefs.getString('fcmtoken');

    try {
      await store.onSignoutUser(loggedInPlatform);
    } catch (e) {
      debugPrint('API logout failed, proceeding with local logout: $e');
    }

    prefs.setString('token', '');
    prefs.setString('fcmtoken', '');
    prefs.setBool('isLoggedInWt', false);
    prefs.setBool('isloggedInEmail', false);
    prefs.setBool('isSignInGoogle', false);
    prefs.clear();
    if (!mounted) return;
    if (ThemeManager.currentTheme == AppTheme.Dark) {
      Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
    }
    Navigator.of(context).pushNamed(Routes.login);

    if (fcmToken != null && !Platform.isWindows && !Platform.isMacOS) {
      try {
        await store.onDeleteNotificationToken(fcmToken);
      } catch (e) {
        debugPrint('FCM token deletion failed: $e');
      }
    }
  }

  // ignore: unused_element
  Future<void> _deleteAccountUser() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onDeleteUserAccountCall(widget.userprofile.id ?? '');
  }

  Future<void> _updateProfile(
    String userId,
    String fullname,
    String dob,
    String preparingFor,
    List<String> preparingExams,
    String currentData,
    String phone,
    String email,
  ) async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onUpdateUserDetailsCall(
      userId,
      fullname,
      dob,
      preparingFor,
      '',
      preparingExams,
      currentData,
      phone,
      email,
      context,
      standerdId: selectedStandardId ?? '',
    );

    if (!mounted) return;
    if (store.updateUserDetails.value?.msg == 'Successfully update user...') {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: 'Profile updated successfully.',
        backgroundColor: AppTokens.accent(context),
      );
      Navigator.of(context).pushNamed(Routes.dashboard);
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: 'Profile not updated. Please try again.',
        backgroundColor: AppTokens.danger(context),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTokens.accent(ctx),
              onPrimary: Colors.white,
              onSurface: AppTokens.ink(ctx),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTokens.accent(ctx),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _openChangeSheet({required bool isMobile}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.r20)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (ctx) => CustomChangeMobileBottomSheet(ctx, isMobile),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => isSubmitted = true);

    final nameOk = _nameKey.currentState?.validate() ?? false;
    final dateOk = _dobKey.currentState?.validate() ?? false;
    final mobileOk = _mobileKey.currentState?.validate() ?? false;
    final emailOk = _emailKey.currentState?.validate() ?? false;
    final statusOk = _isCurrentStatusPicked;

    if (nameOk && dateOk && mobileOk && emailOk && statusOk) {
      _updateProfile(
        widget.userprofile.id ?? '',
        nameController.text,
        dateController.text,
        selectedValue,
        selectedCheckboxValues,
        currentStatus ?? '',
        phoneController.text,
        emailController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    selectedValue = widget.userprofile.preparingFor ?? '';
    standerdFor = widget.userprofile.standerdFor ?? '';
    selectedCheckboxValues = List<String>.from(widget.userprofile.exams as Iterable);
    loggedInPlatform = _detectPlatform();

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      // bottomNavigationBar: _SaveBar(onPressed: _submit),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: ThemeManager.white,
          boxShadow: [
            BoxShadow(
              color: ThemeManager.grey1.withOpacity(0.4),
              blurRadius: 10,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Dimensions.PADDING_SIZE_LARGE),
              CustomButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  // Navigator.of(context).pushNamed(Routes.login);
                  _updateProfile(
                      widget.userprofile.id ?? "",
                      nameController.text,
                      dateController.text,
                      selectedValue,
                      selectedCheckboxValues,
                      currentStatus ?? "",
                      phoneController.text,
                      emailController.text);
                },
                buttonText: "Save",
                textColor: Colors.white,
                height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.2,
                textAlign: TextAlign.center,
                radius: Dimensions.RADIUS_DEFAULT,
                transparent: true,
                bgColor: ThemeManager.blueFinal,
                fontSize: Dimensions.fontSizeDefault,
              ),
              const SizedBox(height: Dimensions.PADDING_SIZE_LARGE),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s24,
            AppTokens.s16,
            AppTokens.s24,
            AppTokens.s32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(onBack: () => Navigator.of(context).maybePop()),
              const SizedBox(height: AppTokens.s24),

              _SectionLabel('Personal details'),
              const SizedBox(height: AppTokens.s12),

              _FieldLabel('Full name'),
              const SizedBox(height: AppTokens.s8),
              TextFormField(
                key: _nameKey,
                controller: nameController,
                cursorColor: AppTokens.accent(context),
                style: AppTokens.body(context),
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                decoration: AppTokens.inputDecoration(
                  context,
                  hint: 'Your full name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.s16),

              _FieldLabel('Date of birth'),
              const SizedBox(height: AppTokens.s8),
              TextFormField(
                key: _dobKey,
                controller: dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                cursorColor: AppTokens.accent(context),
                style: AppTokens.body(context),
                decoration: AppTokens.inputDecoration(
                  context,
                  hint: 'dd/mm/yyyy',
                  suffix: Icon(
                    Icons.date_range_rounded,
                    size: 20,
                    color: AppTokens.muted(context),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your date of birth.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.s20),

              // Read-only summary card for Group / Preparing-for / exams
              _SummaryCard(
                group: selectedValue,
                preparingFor: standerdFor,
                exams: widget.userprofile.exams ?? const <String>[],
              ),
              const SizedBox(height: AppTokens.s20),

              _FieldLabel('What are you currently doing?'),
              const SizedBox(height: AppTokens.s8),
              Row(
                children: [
                  Expanded(
                    child: _RadioCard(
                      label: 'PG Resident',
                      selected: currentStatus == 'PG Resident',
                      onTap: () => setState(
                        () => currentStatus = 'PG Resident',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: _RadioCard(
                      label: 'Post-Graduate',
                      selected: currentStatus == 'Post-Graduate',
                      onTap: () => setState(
                        () => currentStatus = 'Post-Graduate',
                      ),
                    ),
                  ),
                ],
              ),
              if (isSubmitted && !_isCurrentStatusPicked)
                Padding(
                  padding: const EdgeInsets.only(top: AppTokens.s8),
                  child: Text(
                    'Please select one.',
                    style: AppTokens.caption(context).copyWith(color: AppTokens.danger(context)),
                  ),
                ),
              const SizedBox(height: AppTokens.s24),

              _SectionLabel('Contact and email details'),
              const SizedBox(height: AppTokens.s12),

              _FieldLabel('Mobile number'),
              const SizedBox(height: AppTokens.s8),
              TextFormField(
                key: _mobileKey,
                controller: phoneController,
                readOnly: true,
                cursorColor: AppTokens.accent(context),
                style: AppTokens.body(context).copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: AppTokens.inputDecoration(
                  context,
                  hint: 'Mobile number',
                  prefix: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.s12, vertical: AppTokens.s8),
                    child: Text(
                      '+91',
                      style: AppTokens.titleSm(context).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: AppTokens.ink(context),
                      ),
                    ),
                  ),
                  suffix: _ChangeAction(
                    onTap: () => _openChangeSheet(isMobile: true),
                  ),
                ).copyWith(
                  counterText: '',
                  prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 32),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your mobile number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.s16),

              _FieldLabel('Email'),
              const SizedBox(height: AppTokens.s8),
              TextFormField(
                key: _emailKey,
                controller: emailController,
                readOnly: true,
                cursorColor: AppTokens.accent(context),
                style: AppTokens.body(context),
                keyboardType: TextInputType.emailAddress,
                decoration: AppTokens.inputDecoration(
                  context,
                  hint: 'Email address',
                  suffix: _ChangeAction(
                    onTap: () => _openChangeSheet(isMobile: false),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email address.';
                  }
                  if (!_emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.s32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Local widgets
// ─────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTokens.surface2(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppTokens.border(context)),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: AppTokens.ink(context),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s12),
        Text(
          'Edit profile',
          style: AppTokens.titleLg(context).copyWith(color: AppTokens.ink(context)),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTokens.titleSm(context).copyWith(
        color: AppTokens.ink(context),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTokens.overline(context).copyWith(
        color: AppTokens.ink(context),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.group,
    required this.preparingFor,
    required this.exams,
  });

  final String group;
  final String preparingFor;
  final List<String> exams;

  @override
  Widget build(BuildContext context) {
    final hasGroup = group.isNotEmpty;
    final hasPrep = preparingFor.isNotEmpty;
    final hasExams = exams.isNotEmpty;
    if (!hasGroup && !hasPrep && !hasExams) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.accentSoft(context),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasGroup) _SummaryRow(label: 'Group', value: group),
          if (hasGroup && hasPrep) const SizedBox(height: AppTokens.s8),
          if (hasPrep) _SummaryRow(label: 'Preparing for', value: preparingFor),
          if (hasExams) ...[
            const SizedBox(height: AppTokens.s12),
            Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              children: exams
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTokens.surface(context),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppTokens.accent(context).withOpacity(0.6),
                        ),
                      ),
                      child: Text(
                        e,
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.accent(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.muted(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTokens.body(context).copyWith(
              color: AppTokens.ink(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChangeAction extends StatelessWidget {
  const _ChangeAction({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTokens.s12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: AppTokens.s16),
          child: Text(
            'Change',
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.accent(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioCard extends StatelessWidget {
  const _RadioCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? AppTokens.accentSoft(context) : AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(
          color: selected ? AppTokens.accent(context) : AppTokens.border(context),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s12, vertical: 14),
          child: Row(
            children: [
              _RadioDot(selected: selected),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  label,
                  style: AppTokens.titleSm(context).copyWith(
                    color: AppTokens.ink(context),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppTokens.accent(context) : AppTokens.border(context),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTokens.accent(context),
              ),
            )
          : null,
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        boxShadow: AppTokens.shadow2(context),
      ),
      padding: EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s16,
        AppTokens.s20,
        AppTokens.s16 + MediaQuery.of(context).padding.bottom * 0.6,
      ),
      child: CustomButton(
        onPressed: onPressed,
        buttonText: 'Save',
        height: 54,
        bgColor: AppTokens.accent(context),
        textColor: Colors.white,
        radius: AppTokens.r12,
        transparent: true,
        fontSize: 16,
      ),
    );
  }
}
