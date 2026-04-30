import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../helpers/app_tokens.dart';
import '../../models/get_user_details_model.dart';
import '../../models/registerationData.dart';
import '../dashboard/store/home_store.dart';
import '../signup/store/signup_store.dart';
import '../widgets/bottom_toast.dart';
import '../login/keyboard.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import
import '../widgets/custom_button.dart';

/// PreparingForBottomSheet — "which exam are you preparing for" picker
/// shown from the profile edit flow. Public surface preserved exactly:
///   • const constructor
///     `{super.key, this.userDetails, required VoidCallback onUpdate}`
///   • State still orchestrates: load preparing exams → pick group →
///     load standards → pick exam → send OTP → verify OTP → update
///     user profile → invoke [onUpdate] and pop the sheet
///   • Internal selection fields `selectedGroup`, `selectedExam`,
///     `isGroupSelected`, `isExamSelected`, `selectedGroupId`,
///     `selectedStandardId` retained for compatibility
class PreparingForBottomSheet extends StatefulWidget {
  final GetUserDetailsModel? userDetails;
  final VoidCallback onUpdate;

  const PreparingForBottomSheet({
    super.key,
    this.userDetails,
    required this.onUpdate,
  });

  @override
  State<PreparingForBottomSheet> createState() =>
      _PreparingForBottomSheetState();
}

class _PreparingForBottomSheetState extends State<PreparingForBottomSheet> {
  String? selectedGroup;
  String? selectedExam;
  bool isGroupSelected = false;
  bool isExamSelected = false;
  String? selectedGroupId;
  String? selectedStandardId;

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    await _loadPreparingExams();
    if (mounted) {
      await _initializeSelections();
    }
  }

  Future<void> _initializeSelections() async {
    final signupStore = Provider.of<SignupStore>(context, listen: false);

    debugPrint('Initializing selections...');
    debugPrint('preparing_id: ${widget.userDetails?.preparing_id}');
    debugPrint('standerd_id: ${widget.userDetails?.standerd_id}');
    debugPrint('preparingexams count: ${signupStore.preparingexams.length}');

    if (widget.userDetails?.preparing_id != null &&
        signupStore.preparingexams.isNotEmpty) {
      final selectedItem = signupStore.preparingexams.firstWhere(
        (item) => item?.id == widget.userDetails?.preparing_id,
        orElse: () => null,
      );

      debugPrint('Selected item: ${selectedItem?.preparingFor}');

      if (selectedItem != null) {
        if (mounted) {
          setState(() {
            selectedGroup = selectedItem.preparingFor;
            isGroupSelected = true;
            selectedGroupId = selectedItem.id;
          });
          debugPrint('Group selected: $selectedGroup');
        }

        await _loadStandards(selectedItem.id!);
        debugPrint('Standards loaded: ${signupStore.standardList.length}');

        if (widget.userDetails?.standerd_id != null && mounted) {
          final selectedStandard = signupStore.standardList.firstWhere(
            (item) => item?.mongoId == widget.userDetails?.standerd_id,
            orElse: () => null,
          );

          debugPrint('Selected standard: ${selectedStandard?.standerdFor}');

          if (selectedStandard != null) {
            setState(() {
              selectedExam = selectedStandard.standerdFor;
              isExamSelected = true;
              selectedStandardId = selectedStandard.mongoId;
            });
            debugPrint('Exam selected: $selectedExam');
          }
        }
      }
    }
  }

  Future<void> _loadPreparingExams() async {
    final store = Provider.of<SignupStore>(context, listen: false);
    await store.onGetPreparingExams();
  }

  Future<void> _loadStandards(String groupId) async {
    final store = Provider.of<SignupStore>(context, listen: false);
    await store.onGetStandardsByPreparingId(groupId);
  }

  Future<void> _sendOtpAndShowVerifyBottomSheet(
      SignupStore signupStore, HomeStore homeStore) async {
    final phone = widget.userDetails?.phone ?? '';
    final email = widget.userDetails?.email ?? '';
    debugPrint('sendotp call');
    await signupStore.onSendOtpToPhone(phone, email).then((value) {
      if (!mounted) return;
      if (signupStore.errorMessageOtp2.value?.message != null) {
        _showOtpVerificationBottomSheet(signupStore, homeStore, phone, email);
      } else if (signupStore.errorMessageOtp2.value?.error != null) {
        BottomToast.showBottomToastOverlay(
          // ignore: use_build_context_synchronously
          context: context,
          errorMessage: signupStore.errorMessageOtp2.value?.error ??
              'Failed to send OTP',
          // ignore: use_build_context_synchronously
          backgroundColor: AppTokens.danger(context),
        );
      }
    });
  }

  void _showOtpVerificationBottomSheet(
    SignupStore signupStore,
    HomeStore homeStore,
    String phone,
    String email,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => _OtpVerificationBottomSheet(
        phone: phone,
        email: email,
        onVerified: () async {
          Navigator.pop(context);
          await _updateUserProfile(homeStore, _createRegistrationData());
        },
      ),
    );
  }

  RegistrationData _createRegistrationData() {
    debugPrint('Creating RegistrationData with latest selections:');
    debugPrint('selectedGroupId (preparing_id): $selectedGroupId');
    debugPrint('selectedStandardId (standerd_id): $selectedStandardId');
    debugPrint('selectedGroup: $selectedGroup');
    debugPrint('selectedExam: $selectedExam');

    return RegistrationData(
      fullName: widget.userDetails?.fullname ?? '',
      dateOfBirth: widget.userDetails?.dateOfBirth ?? '',
      preparingValue: selectedGroup ?? '',
      stateValue: widget.userDetails?.state ?? '',
      preparingFor: selectedExam != null ? [selectedExam!] : [],
      currentStatus: widget.userDetails?.currentData ?? '',
      phoneNumber: widget.userDetails?.phone ?? '',
      email: widget.userDetails?.email ?? '',
      standardId: selectedStandardId,
      preparingId: selectedGroupId,
      userId: widget.userDetails?.id,
    );
  }

  Future<void> _updateUserProfile(
    HomeStore store, [
    RegistrationData? regData,
  ]) async {
    final data = regData ??
        RegistrationData(
          fullName: widget.userDetails?.fullname ?? '',
          dateOfBirth: widget.userDetails?.dateOfBirth ?? '',
          preparingValue: selectedGroup ?? '',
          stateValue: widget.userDetails?.state ?? '',
          preparingFor: selectedExam != null ? [selectedExam!] : [],
          currentStatus: widget.userDetails?.currentData ?? '',
          phoneNumber: widget.userDetails?.phone ?? '',
          email: widget.userDetails?.email ?? '',
        );

    final fullName = data.fullName;
    final dateOfBirth = data.dateOfBirth;
    final stateValue = data.stateValue;
    final currentStatus = data.currentStatus;
    final phone = data.phoneNumber;
    final email = data.email;
    final List<String> preparingExams = data.preparingFor;
    final String standerdForString =
        preparingExams.isNotEmpty ? preparingExams[0] : '';
    final userId = data.userId ?? widget.userDetails?.id ?? '';

    debugPrint('Updating user profile with:');
    debugPrint('preparing_id: $selectedGroupId');
    debugPrint('standerd_id: $selectedStandardId');
    debugPrint('preparing_for (group name): ${data.preparingValue}');
    debugPrint('standerd_for (exam name): $standerdForString');

    await store.onUpdateUserDetailsCall(
      userId,
      fullName,
      dateOfBirth,
      data.preparingValue,
      stateValue,
      [standerdForString],
      currentStatus,
      phone,
      email,
      context,
      standerdId: selectedStandardId,
      preparingId: selectedGroupId,
    );

    if (!mounted) return;
    if (store.updateUserDetails.value?.msg != null) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: 'Profile updated successfully',
        backgroundColor: AppTokens.success(context),
      );
      Navigator.pop(context);
      widget.onUpdate();
    } else if (store.updateUserDetails.value?.err != null) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: store.updateUserDetails.value?.err?.message ??
            'Failed to update profile',
        backgroundColor: AppTokens.danger(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final signupStore = Provider.of<SignupStore>(context, listen: false);
    final homeStore = Provider.of<HomeStore>(context, listen: false);

    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: _isDesktop ? const BoxConstraints(maxWidth: 640) : null,
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: _isDesktop
            ? BorderRadius.circular(AppTokens.r28)
            : const BorderRadius.vertical(
                top: Radius.circular(AppTokens.r28),
              ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s24,
                AppTokens.s16,
                AppTokens.s24,
                AppTokens.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isDesktop)
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppTokens.s16),
                        decoration: BoxDecoration(
                          color: AppTokens.border(context),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  _SectionHeader(
                    prefix: 'Select your ',
                    accent: 'Group',
                    subtitle: 'Select your preparation group',
                  ),
                  const SizedBox(height: AppTokens.s16),
                  Observer(
                    builder: (_) {
                      final groups = signupStore.preparingexams
                          .map((e) => e?.preparingFor ?? '')
                          .where((e) => e.isNotEmpty)
                          .toList();
                      if (groups.isEmpty) {
                        return _LoadingRow(
                          isLoading: signupStore.isLoading,
                          emptyLabel: 'No groups available',
                        );
                      }
                      return Column(
                        children: groups.asMap().entries.map((entry) {
                          final index = entry.key;
                          final group = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < groups.length - 1
                                  ? AppTokens.s12
                                  : 0,
                            ),
                            child: _RadioOptionCard(
                              label: group,
                              isSelected: selectedGroup == group,
                              onTap: () async {
                                setState(() {
                                  selectedGroup = group;
                                  isGroupSelected = true;
                                  selectedExam = null;
                                  isExamSelected = false;
                                });

                                final selectedItem =
                                    signupStore.preparingexams.firstWhere(
                                  (item) => item?.preparingFor == group,
                                  orElse: () => null,
                                );

                                if (selectedItem?.id != null) {
                                  selectedGroupId = selectedItem?.id;
                                  debugPrint(
                                      'Group selected - preparing_id updated to: $selectedGroupId');
                                  await _loadStandards(selectedItem!.id!);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  if (selectedGroup != null) ...[
                    const SizedBox(height: AppTokens.s32),
                    _SectionHeader(
                      prefix: 'Preparing for ',
                      accent: 'Which Exam',
                      subtitle: 'Select your target exam',
                    ),
                    const SizedBox(height: AppTokens.s16),
                    Observer(
                      builder: (_) {
                        final exams = signupStore.standardList
                            .map((e) => e?.standerdFor ?? '')
                            .where((e) => e.isNotEmpty)
                            .toList();
                        if (exams.isEmpty) {
                          return _LoadingRow(
                            isLoading: signupStore.isLoading,
                            emptyLabel:
                                'No exam options available for this group',
                          );
                        }
                        return Column(
                          children: exams.asMap().entries.map((entry) {
                            final index = entry.key;
                            final exam = entry.value;
                            final standardModel =
                                signupStore.standardList[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < exams.length - 1
                                    ? AppTokens.s12
                                    : 0,
                              ),
                              child: _RadioOptionCard(
                                label: exam,
                                isSelected: selectedExam == exam,
                                onTap: () {
                                  setState(() {
                                    selectedExam = exam;
                                    isExamSelected = true;
                                    selectedStandardId = standardModel?.mongoId;
                                  });
                                  debugPrint(
                                      'Exam selected - standerd_id updated to: $selectedStandardId');
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: AppTokens.s24),
                  Observer(
                    builder: (_) {
                      final enabled = isGroupSelected && isExamSelected;
                      return _GradientCta(
                        label: 'Verify',
                        icon: Icons.verified_user_rounded,
                        isLoading: homeStore.isLoading,
                        onTap: enabled && !homeStore.isLoading
                            ? () async {
                                debugPrint(
                                    'Verify button clicked with selections:');
                                debugPrint('preparing_id: $selectedGroupId');
                                debugPrint('standerd_id: $selectedStandardId');
                                await _sendOtpAndShowVerifyBottomSheet(
                                    signupStore, homeStore);
                              }
                            : null,
                      );
                    },
                  ),
                  const SizedBox(height: AppTokens.s8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// OTP verification bottom sheet — preserves the CustomKeyboard flow, the
// four-cell OTP input, and the onVerified → onUpdate callback chain.
// ---------------------------------------------------------------------------
class _OtpVerificationBottomSheet extends StatefulWidget {
  final String phone;
  final String email;
  final VoidCallback onVerified;

  const _OtpVerificationBottomSheet({
    required this.phone,
    required this.email,
    required this.onVerified,
  });

  @override
  State<_OtpVerificationBottomSheet> createState() =>
      _OtpVerificationBottomSheetState();
}

class _OtpVerificationBottomSheetState
    extends State<_OtpVerificationBottomSheet> {
  List<String> otpDigits = ['', '', '', ''];
  int currentIndex = 0;
  String otp = '';
  final SignupStore _signupStore = SignupStore();

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  Widget _buildCustomOTPInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(4, (index) {
        final filled = otpDigits[index].isNotEmpty;
        final focused = currentIndex == index;
        return GestureDetector(
          onTap: () {
            setState(() => currentIndex = index);
            _showCustomKeyboard();
          },
          child: Container(
            width: 58,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled
                  ? AppTokens.accentSoft(context)
                  : AppTokens.surface(context),
              border: Border.all(
                color: focused
                    ? AppTokens.accent(context)
                    : (filled
                        ? AppTokens.accent(context)
                        : AppTokens.border(context)),
                width: focused ? 2 : 1.2,
              ),
              borderRadius: BorderRadius.circular(AppTokens.r12),
            ),
            child: Text(
              otpDigits[index],
              style: AppTokens.numeric(context, size: 24),
            ),
          ),
        );
      }),
    );
  }

  void _showCustomKeyboard() {
    showModalBottomSheet(
      barrierColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CustomKeyboard(
          keyboardType: KeyboardType.number,
          onKeyPressed: (value) {
            if (value == '←') {
              if (otpDigits[currentIndex].isNotEmpty) {
                setState(() => otpDigits[currentIndex] = '');
              } else if (currentIndex > 0) {
                setState(() {
                  currentIndex--;
                  otpDigits[currentIndex] = '';
                });
              }
              otp = otpDigits.join();
            } else if (value == 'Done') {
              Navigator.pop(context);
            } else if (value.length == 1 && value != '←' && value != 'Done') {
              setState(() {
                otpDigits[currentIndex] = value;
                if (currentIndex < 3) currentIndex++;
              });
              otp = otpDigits.join();
            }
          },
        );
      },
    );
  }

  Future<void> _verifyOtp() async {
    await _signupStore.onVerifyOtpToPhone(widget.phone, otp);
    debugPrint('verifyotp call');
    if (!mounted) return;
    if (_signupStore.registerWithEmail2.value?.message != null) {
      widget.onVerified();
    } else if (_signupStore.registerWithEmail2.value?.error != null) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage:
            _signupStore.registerWithEmail2.value?.error ?? 'Invalid OTP',
        backgroundColor: AppTokens.danger(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          width: MediaQuery.of(context).size.width,
          constraints:
              _isDesktop ? const BoxConstraints(maxWidth: 560) : null,
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: _isDesktop
                ? BorderRadius.circular(AppTokens.r28)
                : const BorderRadius.vertical(
                    top: Radius.circular(AppTokens.r28),
                  ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s24,
              AppTokens.s16,
              AppTokens.s24,
              AppTokens.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isDesktop)
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppTokens.s16),
                      decoration: BoxDecoration(
                        color: AppTokens.border(context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                Text(
                  'Verify OTP',
                  style: AppTokens.titleLg(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  'Enter the 4 digit code sent to ${widget.phone}',
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.ink2(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s24),
                _buildCustomOTPInput(),
                const SizedBox(height: AppTokens.s24),
                Observer(
                  builder: (_) {
                    final isComplete =
                        otpDigits.every((digit) => digit.isNotEmpty);
                    return _GradientCta(
                      label: 'Verify',
                      icon: Icons.check_rounded,
                      isLoading: _signupStore.isLoading,
                      onTap: isComplete && !_signupStore.isLoading
                          ? () async => _verifyOtp()
                          : null,
                    );
                  },
                ),
                const SizedBox(height: AppTokens.s8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helper widgets
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.prefix,
    required this.accent,
    required this.subtitle,
  });

  final String prefix;
  final String accent;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: prefix,
                style: AppTokens.titleLg(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: accent,
                style: AppTokens.titleLg(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.accent(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        Text(
          subtitle,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.ink2(context),
          ),
        ),
      ],
    );
  }
}

class _RadioOptionCard extends StatelessWidget {
  const _RadioOptionCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
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
            color: isSelected
                ? AppTokens.accentSoft(context)
                : AppTokens.surface(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(
              color: isSelected
                  ? AppTokens.accent(context)
                  : AppTokens.border(context),
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppTokens.accent(context)
                        : AppTokens.border(context),
                    width: 2,
                  ),
                  color: AppTokens.surface(context),
                ),
                child: isSelected
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTokens.accent(context),
                        ),
                      )
                    : null,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow({required this.isLoading, required this.emptyLabel});

  final bool isLoading;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: Text(
          isLoading ? 'Loading…' : emptyLabel,
          style: AppTokens.body(context).copyWith(
            color: AppTokens.ink2(context),
          ),
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
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Container(
            height: 52,
            alignment: Alignment.center,
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
                  color: AppTokens.brand.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
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
      ),
    );
  }
}
