import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/registerationData.dart';
import '../login/store/login_store.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';
import 'store/signup_store.dart';

class PreparingForScreen extends StatefulWidget {
  final RegistrationData registrationData;

  const PreparingForScreen({
    super.key,
    required this.registrationData,
  });

  @override
  State<PreparingForScreen> createState() => _PreparingForScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>?;
    return CupertinoPageRoute(
      builder: (_) => PreparingForScreen(
        registrationData: args?['registrationData'] as RegistrationData,
      ),
    );
  }
}

class _PreparingForScreenState extends State<PreparingForScreen> {
  String? selectedGroup;
  String? selectedExam;
  bool isGroupSelected = false;
  bool isExamSelected = false;

  String? selectedGroupId;
  String? selectedStandardId;

  @override
  void initState() {
    super.initState();
    _loadPreparingExams();
  }

  Future<void> _loadPreparingExams() async {
    final store = Provider.of<SignupStore>(context, listen: false);
    await store.onGetPreparingExams();
  }

  Future<void> _loadStandards(String groupId) async {
    final store = Provider.of<SignupStore>(context, listen: false);
    await store.onGetStandardsByPreparingId(groupId);
  }

  Future<Map<String, String>> getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId = '';
    String deviceName = '';
    String platform = '';

    if (Platform.isAndroid) {
      // Android specific device information
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
      deviceName = androidInfo.model ?? 'Unknown';
      platform = 'Android';
    } else if (Platform.isIOS) {
      // iOS specific device information
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? 'Unknown';
      deviceName = iosInfo.name ?? 'Unknown';
      platform = 'iOS';
    } else if (Platform.isMacOS) {
      // macOS specific device information
      final macInfo = await deviceInfo.macOsInfo;
      deviceId = macInfo.systemGUID ?? 'Unknown';
      deviceName = macInfo.model ?? 'Unknown';
      platform = 'macOS';
    } else if (Platform.isWindows) {
      // Windows specific device information
      final windowsInfo = await deviceInfo.windowsInfo;
      deviceId = windowsInfo.deviceId ?? 'Unknown';
      deviceName = windowsInfo.computerName ?? 'Unknown';
      platform = 'Windows';
    }
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
    };
  }

  Future<void> _sendOtp(SignupStore store) async {
    await store
        .onSendOtpToPhone(
      widget.registrationData.phoneNumber,
      widget.registrationData.email,
    )
        .then((value) {
      if (store.errorMessageOtp2.value?.message != null) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: "OTP Sent Successfully! both Email and WhatsApp",
          backgroundColor: Theme.of(context).primaryColor,
        );
      } else if (store.errorMessageOtp2.value?.error != null) {
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: store.errorMessageOtp2.value?.error ?? "Something went wrong!",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SignupStore>(context, listen: false);
    final loginStore = Provider.of<LoginStore>(context, listen: false);

    // Get groups from API - using preparing_for field as groups
    final groups = store.preparingexams.map((e) => e?.preparingFor ?? '').where((e) => e.isNotEmpty).toList();

    // Get exams - using standerd_for field from standardList
    final exams = store.standardList.map((e) => e?.standerdFor ?? '').where((e) => e.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: ThemeManager.white,
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 600,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.08,
                  bottom: MediaQuery.of(context).size.height * 0.04,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Header
                    Observer(
                      builder: (_) {
                        return RichText(
                          text: TextSpan(
                            style: AppTokens.displayMd(context),
                            children: [
                              const TextSpan(text: "Select your "),
                              TextSpan(
                                text: "group",
                                style: TextStyle(color: AppTokens.accent(context)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppTokens.s8),
                    Text(
                      "Pick the qualification stream you're preparing for.",
                      style: AppTokens.bodyLg(context).copyWith(
                        color: AppTokens.muted(context),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s24),

                    // Group Selection
                    Observer(
                      builder: (_) {
                        final groups = store.preparingexams
                            .map((e) => e?.preparingFor ?? '')
                            .where((e) => e.isNotEmpty)
                            .toList();
                        return Column(
                          children: groups.asMap().entries.map((entry) {
                            int index = entry.key;
                            String group = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < groups.length - 1 ? AppTokens.s12 : 0,
                              ),
                              child: _buildRadioOption(
                                label: group,
                                isSelected: selectedGroup == group,
                                onTap: () async {
                                  setState(() {
                                    selectedGroup = group;
                                    isGroupSelected = true;
                                    // Clear exam selection when group changes
                                    selectedExam = null;
                                    isExamSelected = false;
                                  });

                                  // Find the selected group and get its ID
                                  final selectedItem = store.preparingexams.firstWhere(
                                    (item) => item?.preparingFor == group,
                                    orElse: () => null,
                                  );

                                  if (selectedItem?.id != null) {
                                    selectedGroupId = selectedItem?.id;
                                    // Fetch standards for this group using the _id
                                    await _loadStandards(selectedItem!.id!);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    // Only show exam selection section when a group is selected
                    if (selectedGroup != null) ...[
                      const SizedBox(height: AppTokens.s32),
                      RichText(
                        text: TextSpan(
                          style: AppTokens.displayMd(context),
                          children: [
                            const TextSpan(text: "Which "),
                            TextSpan(
                              text: "exam",
                              style: TextStyle(color: AppTokens.accent(context)),
                            ),
                            const TextSpan(text: "?"),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.s8),
                      Text(
                        "Choose the exam you're targeting in this group.",
                        style: AppTokens.bodyLg(context).copyWith(
                          color: AppTokens.muted(context),
                        ),
                      ),
                      const SizedBox(height: AppTokens.s24),

                      // Exam Selection - Only show when group is selected
                      Observer(
                        builder: (_) {
                          // Get exams from standardList
                          final exams = store.standardList
                              .map((e) => e?.standerdFor ?? '')
                              .where((e) => e.isNotEmpty)
                              .toList();

                          if (exams.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppTokens.s16),
                                child: Text(
                                  store.isLoading ? "Loading…" : "No exam options available for this group.",
                                  style: AppTokens.body(context),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: exams.asMap().entries.map((entry) {
                              int index = entry.key;
                              String exam = entry.value;
                              // Find the standard model for this exam
                              final standardModel = store.standardList[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index < exams.length - 1 ? AppTokens.s12 : 0,
                                ),
                                child: _buildRadioOption(
                                  label: exam,
                                  isSelected: selectedExam == exam,
                                  onTap: () {
                                    setState(() {
                                      selectedExam = exam;
                                      isExamSelected = true;
                                      // Store the standard ID
                                      selectedStandardId = standardModel?.mongoId;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: AppTokens.s32),

                    // Submit Button
                    Observer(
                      builder: (_) {
                        return CustomButton(
                          onPressed: isGroupSelected && isExamSelected
                              ? () async {
                                  // Check device registration first
                                  try {
                                    Map<String, String> deviceInfo = await getDeviceInfo();
                                    String deviceUniqueId = deviceInfo['device_id'] ?? '';

                                    // Validate device ID - must not be empty or 'Unknown'
                                    if (deviceUniqueId.isEmpty || deviceUniqueId == 'Unknown') {
                                      BottomToast.showBottomToastOverlay(
                                        context: context,
                                        errorMessage:
                                            "Unable to retrieve device information. Please try again.",
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                      );
                                      return;
                                    }

                                    Map<String, dynamic>? deviceCheckResult =
                                        await store.onCheckDeviceRegistration(deviceUniqueId);

                                    if (deviceCheckResult != null) {
                                      bool exists = deviceCheckResult['exists'] ?? false;
                                      bool success = deviceCheckResult['success'] ?? false;

                                      if (success && exists) {
                                        // Device is already registered, show error
                                        BottomToast.showBottomToastOverlay(
                                          context: context,
                                          errorMessage:
                                              "You cannot register from the same device multiple times",
                                          backgroundColor: Theme.of(context).colorScheme.error,
                                        );
                                        return;
                                      }
                                    }
                                  } catch (e) {
                                    // If device check fails, show error and return
                                    debugPrint("Device check error: $e");
                                    BottomToast.showBottomToastOverlay(
                                      context: context,
                                      errorMessage: "Failed to verify device. Please try again.",
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                    );
                                    return;
                                  }

                                  // Create updated registration data with selected values
                                  final updatedRegistrationData = RegistrationData(
                                    fullName: widget.registrationData.fullName,
                                    dateOfBirth: widget.registrationData.dateOfBirth,
                                    preparingValue: selectedGroup ?? '',
                                    stateValue: widget.registrationData.stateValue,
                                    preparingFor: selectedExam != null ? [selectedExam!] : [],
                                    currentStatus: widget.registrationData.currentStatus,
                                    phoneNumber: widget.registrationData.phoneNumber,
                                    email: widget.registrationData.email,
                                    standardId: selectedStandardId,
                                    preparingId: selectedGroupId,
                                  );

                                  // Send OTP before navigating to verify screen
                                  await _sendOtp(store);

                                  // Navigate to verify OTP screen
                                  Navigator.of(context).pushReplacementNamed(
                                    Routes.verifyOtp,
                                    arguments: {
                                      'email': widget.registrationData.phoneNumber,
                                      'registrationObj': updatedRegistrationData,
                                      'trial': true,
                                      'email2': widget.registrationData.email
                                    },
                                  );
                                }
                              : null,
                          buttonText: "Continue",
                          textColor: Colors.white,
                          height: 54,
                          bgColor: isGroupSelected && isExamSelected
                              ? AppTokens.accent(context)
                              : AppTokens.accent(context).withOpacity(0.4),
                          radius: AppTokens.r16,
                          transparent: true,
                          fontSize: 16,
                          child: store.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Apple-style selectable tile. Hairline border at rest, accent
  /// outline + soft tinted fill when selected. Uses AppTokens so it
  /// matches the rest of the auth flow's polish.
  Widget _buildRadioOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) => InkWell(
        onTap: onTap,
        borderRadius: AppTokens.radius12,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s16,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppTokens.accentSoft(context) : AppTokens.surface(context),
            borderRadius: AppTokens.radius12,
            border: Border.all(
              color: isSelected ? AppTokens.accent(context) : AppTokens.border(context),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTokens.accent(context) : AppTokens.borderStrong(context),
                    width: 2,
                  ),
                  color: AppTokens.surface(context),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTokens.accent(context),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Text(
                  label,
                  style: AppTokens.titleSm(context).copyWith(
                    color: isSelected ? AppTokens.accent(context) : AppTokens.ink(context),
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
