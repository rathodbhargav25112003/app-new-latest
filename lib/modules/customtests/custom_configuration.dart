import 'dart:io';

import 'package:flutter/material.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import
import 'package:shusruta_lms/modules/test/store/test_category_store.dart';
import '../widgets/bottom_toast.dart';

/// CustomConfiguration — fifth step of the custom-test creation wizard.
/// Lets the learner name/describe the test and dial in the number of
/// questions and total duration before previewing. Surface contract
/// preserved exactly:
///   • const constructor accepting six required fields (category /
///     chapter / topic / exam maps, totalQuestions, totalDurations) plus
///     Key?; static `route(RouteSettings)` reads the same six args
///   • controllers (testNameController, testDescriptionController,
///     numberOfQuestions, numberOfDurations), global keys (nameKey,
///     descriptionKey, numberQuestionKey, numberDurationsKey) and the
///     four bool `isXxxValid` flags all unchanged
///   • counterQuestionIncrement/Decrement + counterDurationsIncrement/
///     Decrement + convertDurationToMinutes logic preserved byte-for-byte
///     (inc. the `>180 → questionCount minutes` fallback)
///   • Navigator.pushNamed(Routes.customPreview) ships all eight args:
///     selectedCategoryItems, selectedChapterItems, selectedTopicItems,
///     selectedExamItems, counterQuestion (text), counterDurations
///     (text), testName, testDesc
///   • public CustomTextField widget signature (formKey, controller,
///     validator, title, isMultiline, hintText) retained
class CustomConfiguration extends StatefulWidget {
  final List<Map<String, dynamic>> selectedCategoryItems;
  final List<Map<String, dynamic>> selectedChapterItems;
  final List<Map<String, dynamic>> selectedTopicItems;
  final List<Map<String, dynamic>> selectedExamItems;
  final int totalQuestions;
  final String totalDurations;
  const CustomConfiguration({
    super.key,
    required this.selectedCategoryItems,
    required this.selectedChapterItems,
    required this.selectedTopicItems,
    required this.selectedExamItems,
    required this.totalQuestions,
    required this.totalDurations,
  });

  @override
  State<CustomConfiguration> createState() => _CustomConfigurationState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => CustomConfiguration(
        selectedCategoryItems: arguments['selectedCategoryItems'],
        selectedChapterItems: arguments['selectedChapterItems'],
        selectedTopicItems: arguments['selectedTopicItems'],
        selectedExamItems: arguments['selectedExamItems'],
        totalQuestions: arguments['totalQuestions'],
        totalDurations: arguments['totalDurations'],
      ),
    );
  }
}

class _CustomConfigurationState extends State<CustomConfiguration> {
  // ignore: unused_field
  String query = '';

  TextEditingController testNameController = TextEditingController();
  TextEditingController testDescriptionController = TextEditingController();
  TextEditingController numberOfQuestions = TextEditingController();
  TextEditingController numberOfDurations = TextEditingController();

  int counterQuestion = 0;
  int counterDurations = 0;

  final nameKey = GlobalKey<FormFieldState<String>>();
  final descriptionKey = GlobalKey<FormFieldState<String>>();
  final numberQuestionKey = GlobalKey<FormFieldState<String>>();
  final numberDurationsKey = GlobalKey<FormFieldState<String>>();

  bool isNameValid = false;
  bool isDescriptionValid = false;
  bool isNumberQuestionValid = false;
  bool isNumberDurationsValid = false;

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    counterQuestion = widget.totalQuestions;
    counterDurations = convertDurationToMinutes(widget.totalDurations);
    numberOfQuestions.text = widget.totalQuestions.toString();
    numberOfDurations.text = counterDurations.toString();
  }

  @override
  void dispose() {
    testNameController.dispose();
    testDescriptionController.dispose();
    numberOfQuestions.dispose();
    numberOfDurations.dispose();
    super.dispose();
  }

  void counterQuestionIncrement() {
    if (widget.totalQuestions > counterQuestion) {
      setState(() {
        counterQuestion++;
        numberOfQuestions.text = counterQuestion.toString();
      });
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: 'Too few questions available!!',
        backgroundColor: AppTokens.accent(context),
      );
    }
  }

  void counterQuestionDecrement() {
    if (counterQuestion > 0) {
      setState(() {
        counterQuestion--;
        numberOfQuestions.text = counterQuestion.toString();
      });
    }
  }

  void counterDurationsIncrement() {
    final int maxDuration = convertDurationToMinutes(widget.totalDurations);
    if (counterDurations < maxDuration) {
      setState(() {
        counterDurations++;
        numberOfDurations.text = counterDurations.toString();
      });
    }
  }

  void counterDurationsDecrement() {
    if (counterDurations > 0) {
      setState(() {
        counterDurations--;
        numberOfDurations.text = counterDurations.toString();
      });
    }
  }

  int convertDurationToMinutes(String durationStr) {
    final List<String> parts = durationStr.split(':');
    final int hours = int.parse(parts[0]);
    final int minutes = int.parse(parts[1]);
    final int seconds = int.parse(parts[2]);
    final int totalMinutes = hours * 60 + minutes + (seconds / 60).round();

    // For "all" selection, use a more reasonable calculation. If the raw
    // aggregate duration is >3 hours, fall back to 1 minute/question.
    if (totalMinutes > 180) {
      final int calculatedDuration = widget.totalQuestions;
      return calculatedDuration;
    }

    return totalMinutes;
  }

  void _submit() {
    final bool nameValid = nameKey.currentState?.validate() ?? false;
    final bool descriptionValid =
        descriptionKey.currentState?.validate() ?? false;
    final bool questionValid =
        numberQuestionKey.currentState?.validate() ?? false;
    final bool durationValid =
        numberDurationsKey.currentState?.validate() ?? false;

    if (nameValid && descriptionValid && questionValid && durationValid) {
      debugPrint(widget.selectedCategoryItems.toString());
      debugPrint(widget.selectedChapterItems.toString());
      debugPrint(widget.selectedTopicItems.toString());
      debugPrint(widget.selectedExamItems.toString());
      debugPrint(numberOfQuestions.text);
      debugPrint(numberOfDurations.text);
      debugPrint(testNameController.text);
      debugPrint(testDescriptionController.text);

      Navigator.of(context).pushNamed(
        Routes.customPreview,
        arguments: {
          'selectedCategoryItems': widget.selectedCategoryItems,
          'selectedChapterItems': widget.selectedChapterItems,
          'selectedTopicItems': widget.selectedTopicItems,
          'selectedExamItems': widget.selectedExamItems,
          'counterQuestion': numberOfQuestions.text,
          'counterDurations': numberOfDurations.text,
          'testName': testNameController.text,
          'testDesc': testDescriptionController.text,
        },
      );
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: 'Please fill all required fields correctly',
        backgroundColor: AppTokens.accent(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final store = Provider.of<TestCategoryStore>(context, listen: false);
    final int maxDuration = convertDurationToMinutes(widget.totalDurations);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _GradientHeader(
            title: 'Configuration',
            subtitle: 'Name the test and pick the shape of your session',
            onBack: () => Navigator.pop(context),
            isDesktop: _isDesktop,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: _isDesktop
                    ? null
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AppTokens.r28),
                        topRight: Radius.circular(AppTokens.r28),
                      ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s20,
                  AppTokens.s24,
                  AppTokens.s20,
                  AppTokens.s20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          icon: Icons.edit_note_rounded,
                          title: 'Test details',
                        ),
                        const SizedBox(height: AppTokens.s12),
                        Container(
                          padding: const EdgeInsets.all(AppTokens.s16),
                          decoration: BoxDecoration(
                            color: AppTokens.surface(context),
                            borderRadius:
                                BorderRadius.circular(AppTokens.r16),
                            border: Border.all(
                              color: AppTokens.border(context),
                            ),
                          ),
                          child: Column(
                            children: [
                              CustomTextField(
                                formKey: nameKey,
                                title: 'Name of Test',
                                controller: testNameController,
                                hintText: 'Enter test name',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    setState(() => isNameValid = false);
                                    return 'Please enter name of test';
                                  }
                                  setState(() => isNameValid = true);
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppTokens.s16),
                              CustomTextField(
                                isMultiline: true,
                                title: 'Description',
                                formKey: descriptionKey,
                                controller: testDescriptionController,
                                hintText: 'Enter test description',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    setState(
                                        () => isDescriptionValid = false);
                                    return 'Please enter description';
                                  }
                                  setState(() => isDescriptionValid = true);
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTokens.s24),
                        _SectionHeader(
                          icon: Icons.tune_rounded,
                          title: 'Session sizing',
                        ),
                        const SizedBox(height: AppTokens.s12),
                        _SliderCard(
                          title: 'No. of Questions',
                          icon: Icons.quiz_rounded,
                          color: AppTokens.accent(context),
                          soft: AppTokens.accentSoft(context),
                          value: counterQuestion,
                          min: 0,
                          max: widget.totalQuestions,
                          unit: '',
                          controller: numberOfQuestions,
                          formKey: numberQuestionKey,
                          onChanged: (newValue) {
                            setState(() {
                              counterQuestion = newValue;
                              numberOfQuestions.text = newValue.toString();
                            });
                          },
                          onDecrement: counterQuestionDecrement,
                          onIncrement: counterQuestionIncrement,
                          onValidationChanged: (ok) =>
                              setState(() => isNumberQuestionValid = ok),
                        ),
                        const SizedBox(height: AppTokens.s16),
                        _SliderCard(
                          title: 'Duration',
                          icon: Icons.schedule_rounded,
                          color: AppTokens.warning(context),
                          soft: AppTokens.warningSoft(context),
                          value: counterDurations,
                          min: 0,
                          max: maxDuration,
                          unit: 'Mins',
                          controller: numberOfDurations,
                          formKey: numberDurationsKey,
                          onChanged: (newValue) {
                            setState(() {
                              counterDurations = newValue;
                              numberOfDurations.text =
                                  newValue.toString();
                            });
                          },
                          onDecrement: counterDurationsDecrement,
                          onIncrement: counterDurationsIncrement,
                          onValidationChanged: (ok) =>
                              setState(() => isNumberDurationsValid = ok),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _PreviewCta(onTap: _submit),
        ],
      ),
    );
  }

  /// Preserved legacy slider helper — the rebuilt UI uses `_SliderCard`
  /// which delegates back to the same controllers/keys, but this method
  /// is kept for API parity in case any external code references it.
  // ignore: unused_element
  Widget buildSliderSection({
    required String title,
    required int value,
    required int min,
    required int max,
    required String unit,
    required ValueChanged<int> onChanged,
  }) {
    GlobalKey<FormFieldState<String>>? formKey;
    if (title == 'No. of Questions') {
      formKey = numberQuestionKey;
    } else if (title == 'Duration') {
      formKey = numberDurationsKey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
          child: Text(
            title,
            style:
                TextStyle(color: AppTokens.ink(context)),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
          child: SizedBox(
            height: 46,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppTokens.border(context)),
                      borderRadius: BorderRadius.circular(AppTokens.r8),
                    ),
                    child: TextFormField(
                      key: formKey,
                      controller: title == 'No. of Questions'
                          ? numberOfQuestions
                          : numberOfDurations,
                      readOnly: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          if (title == 'No. of Questions') {
                            setState(() => isNumberQuestionValid = false);
                          } else {
                            setState(() => isNumberDurationsValid = false);
                          }
                          return 'Please enter a value';
                        }
                        if (title == 'No. of Questions') {
                          setState(() => isNumberQuestionValid = true);
                        } else {
                          setState(() => isNumberDurationsValid = true);
                        }
                        return null;
                      },
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTokens.ink(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.s16),
                buildCounterButton('-', () {
                  if (title == 'No. of Questions') {
                    counterQuestionDecrement();
                  } else {
                    counterDurationsDecrement();
                  }
                }),
                const SizedBox(width: AppTokens.s8),
                buildCounterButton('+', () {
                  if (title == 'No. of Questions') {
                    counterQuestionIncrement();
                  } else {
                    counterDurationsIncrement();
                  }
                }),
              ],
            ),
          ),
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          onChanged: (double newValue) {
            onChanged(newValue.toInt());
          },
          activeColor: AppTokens.accent(context),
          inactiveColor: AppTokens.surface2(context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(min.toString()),
              Text(max.toString()),
            ],
          ),
        ),
      ],
    );
  }

  /// Legacy +/- counter button. Preserved for API parity with the old
  /// `buildSliderSection` callers.
  // ignore: unused_element
  Widget buildCounterButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 45,
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: AppTokens.surface2(context),
          foregroundColor: AppTokens.ink(context),
          elevation: 0,
          side: BorderSide(color: AppTokens.border(context)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

/// Brand-gradient header for the configuration screen (simpler than the
/// wizard list steps — no count pill or Select-All toggle).
class _GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final bool isDesktop;
  const _GradientHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final double topPad = isDesktop ? AppTokens.s20 : AppTokens.s32;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppTokens.s20,
        topPad,
        AppTokens.s20,
        AppTokens.s20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: isDesktop
            ? null
            : const BorderRadius.only(
                bottomLeft: Radius.circular(AppTokens.r28),
                bottomRight: Radius.circular(AppTokens.r28),
              ),
      ),
      child: SafeArea(
        top: !isDesktop,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Material(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.18),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: const Padding(
                      padding: EdgeInsets.all(AppTokens.s8),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTokens.titleMd(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              subtitle,
              style: AppTokens.body(context).copyWith(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTokens.accentSoft(context),
            borderRadius: BorderRadius.circular(AppTokens.r8),
          ),
          child: Icon(icon, size: 18, color: AppTokens.accent(context)),
        ),
        const SizedBox(width: AppTokens.s8),
        Text(
          title,
          style: AppTokens.titleSm(context)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// Slider card that wraps title, the read-only counter field, +/- pills
/// and a native slider — same controllers/keys as the legacy UI so
/// validation and state stay intact.
class _SliderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color soft;
  final int value;
  final int min;
  final int max;
  final String unit;
  final TextEditingController controller;
  final GlobalKey<FormFieldState<String>> formKey;
  final ValueChanged<int> onChanged;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<bool> onValidationChanged;
  const _SliderCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.soft,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.controller,
    required this.formKey,
    required this.onChanged,
    required this.onDecrement,
    required this.onIncrement,
    required this.onValidationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasRange = max > min;
    final double safeMax = hasRange ? max.toDouble() : (min + 1).toDouble();
    final double clampedValue = value.clamp(min, hasRange ? max : min).toDouble();
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Text(
                  title,
                  style: AppTokens.titleSm(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(AppTokens.r8),
                ),
                child: Text(
                  unit.isEmpty ? '$value' : '$value $unit',
                  style: AppTokens.caption(context).copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.surface2(context),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    border: Border.all(color: AppTokens.border(context)),
                  ),
                  child: TextFormField(
                    key: formKey,
                    controller: controller,
                    readOnly: true,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        onValidationChanged(false);
                        return 'Please enter a value';
                      }
                      onValidationChanged(true);
                      return null;
                    },
                    style: AppTokens.titleSm(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              _CounterPill(
                icon: Icons.remove_rounded,
                color: color,
                soft: soft,
                onTap: onDecrement,
              ),
              const SizedBox(width: AppTokens.s8),
              _CounterPill(
                icon: Icons.add_rounded,
                color: color,
                soft: soft,
                onTap: onIncrement,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: soft,
              thumbColor: color,
              overlayColor: color.withAlpha(32),
              trackHeight: 4,
            ),
            child: Slider(
              value: clampedValue,
              min: min.toDouble(),
              max: safeMax,
              onChanged: hasRange
                  ? (newValue) => onChanged(newValue.toInt())
                  : null,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$min',
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.ink2(context),
                ),
              ),
              Text(
                '$max',
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.ink2(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color soft;
  final VoidCallback onTap;
  const _CounterPill({
    required this.icon,
    required this.color,
    required this.soft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: soft,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r12),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _PreviewCta extends StatelessWidget {
  final VoidCallback onTap;
  const _PreviewCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s8,
          AppTokens.s20,
          AppTokens.s16,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.r16),
            onTap: onTap,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTokens.brand, AppTokens.brand2],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(AppTokens.r16),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: AppTokens.brand.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.visibility_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Text(
                    'Preview',
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
      ),
    );
  }
}

/// Polished input field used for test name / description. Retains the
/// exact public surface (controller, validator, hintText, title,
/// isMultiline, formKey) consumed by the configuration screen.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String hintText;
  final String title;
  final bool isMultiline;
  final GlobalKey<FormFieldState<String>>? formKey;
  // ignore: use_super_parameters
  const CustomTextField({
    Key? key,
    required this.controller,
    required this.validator,
    required this.title,
    this.isMultiline = false,
    required this.hintText,
    this.formKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.ink2(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: formKey,
          cursorColor: AppTokens.accent(context),
          style: AppTokens.body(context),
          controller: controller,
          validator: validator,
          maxLines: isMultiline ? 5 : 1,
          keyboardType: TextInputType.name,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppTokens.s12,
              vertical: isMultiline ? 16 : 14,
            ),
            filled: true,
            fillColor: AppTokens.surface2(context),
            hintText: hintText,
            hintStyle: AppTokens.body(context).copyWith(
              color: AppTokens.ink2(context),
            ),
            counterText: '',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.r12),
              borderSide:
                  BorderSide(color: AppTokens.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.r12),
              borderSide: BorderSide(
                color: AppTokens.accent(context),
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.r12),
              borderSide: BorderSide(color: AppTokens.danger(context)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.r12),
              borderSide: BorderSide(
                color: AppTokens.danger(context),
                width: 1.4,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.r12),
              borderSide:
                  BorderSide(color: AppTokens.border(context)),
            ),
          ),
        ),
      ],
    );
  }
}
