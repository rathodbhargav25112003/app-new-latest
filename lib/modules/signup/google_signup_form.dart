import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';
import 'store/signup_store.dart';

/// GoogleSignUpForm — post-Google-OAuth details form.
///
/// UPGRADE NOTES (ruchir-new-app-upgrade-ui, screen 12):
/// - Same constructor: `{required this.username, required this.email}`.
/// - Same route factory — reads `username` / `email` from route arguments.
/// - Same SignupStore contract. `_register(...)` keeps the identical
///   positional signature and behaviour (the real API call was already
///   stubbed out upstream — kept as-is; success path still pushes
///   `Routes.login`).
/// - AppTokens for typography / colours / spacing / radii.
/// - PG Resident / Post-Graduate use the shared _RadioCard pattern from
///   screens 09 / 10 / 11. Sub-exam list uses _CheckChip.
class GoogleSignUpForm extends StatefulWidget {
  final String username;
  final String email;

  const GoogleSignUpForm({
    Key? key,
    required this.username,
    required this.email,
  }) : super(key: key);

  @override
  State<GoogleSignUpForm> createState() => _GoogleSignUpFormState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => GoogleSignUpForm(
        username: arguments['username'],
        email: arguments['email'],
      ),
    );
  }
}

class _GoogleSignUpFormState extends State<GoogleSignUpForm>
    with WidgetsBindingObserver {
  bool isKeyboardOpen = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  DateTime? selectedDate;
  String selectedValue = '';
  final List<String> selectedCheckboxValues = [];
  String? currentStatus;
  bool isSubmitted = false;

  final _nameKey = GlobalKey<FormFieldState<String>>();
  final _preparingKey = GlobalKey<FormFieldState<String>>();
  final _mobileKey = GlobalKey<FormFieldState<String>>();
  final _dobKey = GlobalKey<FormFieldState<String>>();

  String? _email;

  bool _isCurrentStatusPicked() =>
      currentStatus == 'PG Resident' || currentStatus == 'Post-Graduate';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    nameController.text = widget.username;
    _email = widget.email;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    nameController.dispose();
    dateController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (!mounted) return;
    setState(() {
      isKeyboardOpen = bottomInset > 0;
    });
  }

  // --------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
        dateController.text = DateFormat('dd - MMMM - yyyy').format(picked);
      });
    }
  }

  void _submit(SignupStore store) {
    setState(() => isSubmitted = true);
    final nameValidate = _nameKey.currentState?.validate() ?? false;
    final dateValidate = _dobKey.currentState?.validate() ?? false;
    final preparingValidate =
        _preparingKey.currentState?.validate() ?? false;
    final mobileValidate = _mobileKey.currentState?.validate() ?? false;

    if (nameValidate &&
        dateValidate &&
        preparingValidate &&
        mobileValidate &&
        _isCurrentStatusPicked()) {
      _register(
        store,
        nameController.text,
        dateController.text,
        selectedValue,
        selectedCheckboxValues,
        currentStatus ?? '',
        phoneController.text,
        _email ?? '',
        true,
      );
    }
  }

  Future<void> _register(
    SignupStore store,
    String fullName,
    String dateOfBirth,
    String preparingValue,
    List<String> preparingFor,
    String currentStatus,
    String phoneNumber,
    String email,
    bool isGoogle,
  ) async {
    // NOTE: the upstream API call was already commented out in the
    // legacy code — kept as-is to preserve behaviour. Enabling Google
    // signup requires restoring the call on [SignupStore] and routing
    // the response through `store.signup`.
    //
    // await store.onRegisterApiCall(fullName, dateOfBirth, preparingValue,
    //   preparingFor, currentStatus, phoneNumber, email, "", "", isGoogle);

    if (!mounted) return;
    if (store.signup.value?.created == null) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: 'User Registration Failed!',
        backgroundColor: AppTokens.danger(context),
      );
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: 'User Registered Successfully',
        backgroundColor: AppTokens.accent(context),
      );
      Navigator.of(context).pushNamed(Routes.login);
    }
  }

  // --------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SignupStore>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppTokens.s24,
                AppTokens.s16,
                AppTokens.s24,
                isKeyboardOpen
                    ? MediaQuery.of(context).viewInsets.bottom
                    : AppTokens.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackBubble(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(height: AppTokens.s20),
                  _Heading(email: _email ?? widget.email),
                  const SizedBox(height: AppTokens.s24),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(label: 'Full name'),
                          const SizedBox(height: AppTokens.s8),
                          TextFormField(
                            key: _nameKey,
                            controller: nameController,
                            cursorColor: AppTokens.accent(context),
                            style: AppTokens.body(context),
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.name,
                            decoration: AppTokens.inputDecoration(
                              context,
                              hint: 'Enter your full name',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter full name.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTokens.s16),
                          _FieldLabel(label: 'Date of birth'),
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
                              hint: 'dd - month - yyyy',
                              suffix: Icon(
                                Icons.event_rounded,
                                size: 18,
                                color: AppTokens.muted(context),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select date of birth.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTokens.s16),
                          _FieldLabel(label: 'Preparing for'),
                          const SizedBox(height: AppTokens.s8),
                          DropdownButtonFormField<String>(
                            key: _preparingKey,
                            dropdownColor: AppTokens.surface(context),
                            value: selectedValue.isNotEmpty
                                ? selectedValue
                                : null,
                            isExpanded: true,
                            iconSize: 22,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppTokens.muted(context),
                            ),
                            style: AppTokens.body(context),
                            decoration: AppTokens.inputDecoration(
                              context,
                              hint: 'Select stream',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Surgical',
                                child: Text('Surgical'),
                              ),
                              DropdownMenuItem(
                                value: 'Medical',
                                child: Text('Medical'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedValue = value ?? '';
                                selectedCheckboxValues.clear();
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please choose one.';
                              }
                              return null;
                            },
                          ),
                          if (selectedValue.isNotEmpty) ...[
                            const SizedBox(height: AppTokens.s16),
                            _FieldLabel(label: 'Target exam(s)'),
                            const SizedBox(height: AppTokens.s8),
                            _SubExamChips(
                              options: selectedValue == 'Surgical'
                                  ? const ['NEET SS', 'INI SS', 'MR CS']
                                  : const ['NEET SS', 'INI SS'],
                              selected: selectedCheckboxValues,
                              onToggle: (value) {
                                setState(() {
                                  if (selectedCheckboxValues.contains(value)) {
                                    selectedCheckboxValues.remove(value);
                                  } else {
                                    selectedCheckboxValues.add(value);
                                  }
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: AppTokens.s16),
                          _FieldLabel(label: 'Current status'),
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
                          if (isSubmitted && !_isCurrentStatusPicked())
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppTokens.s8,
                              ),
                              child: Text(
                                'Please pick your current status.',
                                style: AppTokens.caption(context).copyWith(
                                  color: AppTokens.danger(context),
                                ),
                              ),
                            ),
                          const SizedBox(height: AppTokens.s16),
                          _FieldLabel(label: 'Mobile number'),
                          const SizedBox(height: AppTokens.s8),
                          TextFormField(
                            key: _mobileKey,
                            controller: phoneController,
                            cursorColor: AppTokens.accent(context),
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            style: AppTokens.body(context).copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                            decoration: AppTokens.inputDecoration(
                              context,
                              hint: '10-digit mobile',
                              prefix: Padding(
                                padding: const EdgeInsets.only(
                                  left: AppTokens.s16,
                                  right: AppTokens.s8,
                                ),
                                child: Text(
                                  '+91',
                                  style: AppTokens.body(context).copyWith(
                                    color: AppTokens.ink(context),
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ).copyWith(
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 32,
                              ),
                              counterText: '',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter mobile number.';
                              }
                              if (value.length < 10) {
                                return 'Enter 10-digit mobile number.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTokens.s16),
                        ],
                      ),
                    ),
                  ),
                  Observer(
                    builder: (_) => CustomButton(
                      onPressed: store.isLoading ? null : () => _submit(store),
                      buttonText: store.isLoading ? '' : 'Submit',
                      height: 54,
                      bgColor: AppTokens.accent(context),
                      textColor: Colors.white,
                      radius: AppTokens.r12,
                      transparent: true,
                      fontSize: 16,
                      child: store.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// Local widgets
// ------------------------------------------------------------------

class _BackBubble extends StatelessWidget {
  const _BackBubble({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
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
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hello,', style: AppTokens.displayMd(context)),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            text: 'Finish your ',
            style: AppTokens.displayMd(context),
            children: [
              TextSpan(
                text: 'Sushruta LGS',
                style: AppTokens.displayMd(context).copyWith(
                  color: AppTokens.accent(context),
                ),
              ),
              const TextSpan(text: ' profile'),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s8),
        Text(
          'A few more details and you are in.',
          style: AppTokens.body(context).copyWith(
            color: AppTokens.ink2(context),
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12,
            vertical: AppTokens.s8,
          ),
          decoration: BoxDecoration(
            color: AppTokens.accentSoft(context),
            borderRadius: BorderRadius.circular(AppTokens.r8),
            border: Border.all(
              color: AppTokens.accent(context).withOpacity(0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppTokens.accent(context),
              ),
              const SizedBox(width: AppTokens.s8),
              Flexible(
                child: Text(
                  'Signed in as $email',
                  overflow: TextOverflow.ellipsis,
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.accent(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTokens.overline(context),
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
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16,
          vertical: AppTokens.s16,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppTokens.accentSoft(context)
              : AppTokens.surface2(context),
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(
            color: selected
                ? AppTokens.accent(context)
                : AppTokens.border(context),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            _RadioDot(selected: selected),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Text(
                label,
                style: AppTokens.titleSm(context).copyWith(
                  color: selected
                      ? AppTokens.accent(context)
                      : AppTokens.ink(context),
                ),
              ),
            ),
          ],
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
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppTokens.accent(context)
              : AppTokens.border(context),
          width: 1.6,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppTokens.accent(context),
                shape: BoxShape.circle,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _SubExamChips extends StatelessWidget {
  const _SubExamChips({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTokens.s8,
      runSpacing: AppTokens.s8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onToggle(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16,
              vertical: AppTokens.s8 + 2,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTokens.accentSoft(context)
                  : AppTokens.surface2(context),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? AppTokens.accent(context)
                    : AppTokens.border(context),
                width: isSelected ? 1.2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isSelected
                      ? AppTokens.accent(context)
                      : AppTokens.muted(context),
                ),
                const SizedBox(width: AppTokens.s8),
                Text(
                  option,
                  style: AppTokens.body(context).copyWith(
                    color: isSelected
                        ? AppTokens.accent(context)
                        : AppTokens.ink(context),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
