import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/models/bookmark_by_examlist_model.dart';
import 'package:shusruta_lms/modules/bookmarks/store/bookmark_store.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/store/new_bookmark_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';

/// BookMarkConfigrationScreen — the Step-5 pre-launch configuration page
/// that captures the module name, description, question count and
/// duration before firing [BookmarkNewStore.createModule].
///
/// Public surface preserved exactly:
///   • class [BookMarkConfigrationScreen]
///   • required `String` [type] field
///   • const constructor
///     [BookMarkConfigrationScreen]({super.key, required this.type})
///     unchanged
///   • [SingleTickerProviderStateMixin] on the state (legacy carry-over)
///   • state fields [tabIndex], [indexs], [numberOfQuestions], [duration],
///     [name], [description] preserved with original types
///   • helper methods [convertMinutesToHHMMSS],
///     [sumQuestionCountsByMode] unchanged
///   • [WillPopScope] still pushes [Routes.dashboard] and returns false
///   • Bottom CTA still calls
///     `store.createModule(data, widget.type).then(...)` with the exact
///     same `data` payload shape (testName, Description,
///     NumberOfQuestions, time_duration, category, subcategory, topic,
///     exam) and the same downstream `ongetAllMyCustomTestApiCall` +
///     multi-pop navigation (6 pops for McqBookmark, 4 pops otherwise)
///   • Public [CustomTextField] class kept in this file with the same
///     constructor
class BookMarkConfigrationScreen extends StatefulWidget {
  const BookMarkConfigrationScreen({super.key, required this.type});
  final String type;

  @override
  State<BookMarkConfigrationScreen> createState() =>
      _BookMarkConfigrationScreenState();
}

class _BookMarkConfigrationScreenState extends State<BookMarkConfigrationScreen>
    with SingleTickerProviderStateMixin {
  // Preserved from the legacy API even though the new layout does not
  // route a tab bar through here.
  // ignore: unused_field
  int tabIndex = 0;
  // ignore: unused_field
  List indexs = [];

  int numberOfQuestions = 1;
  int duration = 1;
  final TextEditingController name = TextEditingController();
  final TextEditingController description = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  String convertMinutesToHHMMSS(int minutes) {
    int hours = minutes ~/ 60; // Calculate whole hours
    int remainingMinutes = minutes % 60; // Remaining minutes after hours
    int seconds = 0; // If you have seconds, you can pass them too

    // Format with leading zeros to ensure 2 digits (e.g., 01:05:00)
    String formattedTime = '${hours.toString().padLeft(2, '0')}:'
        '${remainingMinutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';

    return formattedTime;
  }

  int sumQuestionCountsByMode(List<BookMarkByExamListModel> bookmarkList) {
    int count = 0;
    for (var item in bookmarkList) {
      count += item.bookmarkCount ?? 0;
    }
    return count;
  }

  int _selectedCount(BookmarkNewStore store) {
    return sumQuestionCountsByMode(store.selectedBookmarkTest.value);
  }

  void _popAfterCreate() {
    if (widget.type == 'McqBookmark') {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleCreate(BookmarkNewStore store) async {
    final Map<String, dynamic> data = {
      "testName": name.text,
      "Description": description.text,
      "NumberOfQuestions": numberOfQuestions,
      "time_duration": convertMinutesToHHMMSS(duration),
      "category": (store.selectedBookmarkCategory.value ?? const [])
          .map((e) => {
                "category_id": e.category_id,
                "category_name": e.category_name,
              })
          .toList(),
      "subcategory": store.selectedBookmarkSubCategory.value
          .map((e) => {
                "subcategory_id": e.subcategory_id,
                "subcategory_name": e.subcategory_name,
              })
          .toList(),
      "topic": store.selectedBookmarkTopic.value
          .map((e) => {
                "topic_id": e.topic_id,
                "topic_name": e.topic_name,
              })
          .toList(),
      "exam": store.selectedBookmarkTest.value
          .map((e) => {
                "exam_id": e.examId,
                "exam_name": e.examName,
              })
          .toList(),
    };

    await store.createModule(data, widget.type).then((_) {
      store.ongetAllMyCustomTestApiCall(widget.type);
      _popAfterCreate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<BookmarkNewStore>(context);
    final store2 = Provider.of<BookMarkStore>(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamed(Routes.dashboard);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        bottomNavigationBar: Observer(builder: (_) {
          final int maxCount = _selectedCount(store);
          final bool canSubmit = !store.isLoading &&
              name.text.trim().isNotEmpty &&
              numberOfQuestions > 0 &&
              duration > 0 &&
              maxCount > 0;
          return _PrimaryCta(
            label: 'Create Module',
            enabled: canSubmit,
            loading: store.isLoading,
            onTap: canSubmit ? () => _handleCreate(store) : null,
          );
        }),
        body: Column(
          children: [
            _Header(
              onBack: () => Navigator.of(context).pop(),
              selectedBuilder: () => Observer(builder: (_) {
                return Text(
                  _selectedCount(store).toString().padLeft(2, '0'),
                  style: AppTokens.titleMd(context).copyWith(
                    color: Colors.white,
                  ),
                );
              }),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  borderRadius: (Platform.isWindows || Platform.isMacOS)
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(28.8),
                          topRight: Radius.circular(28.8),
                        ),
                ),
                child: Observer(builder: (_) {
                  if (store2.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTokens.accent(context),
                      ),
                    );
                  }
                  final int totalSelected = _selectedCount(store);
                  final int safeMax = totalSelected > 0 ? totalSelected : 1;
                  // Clamp working values so a late-arriving selection
                  // never violates slider bounds.
                  if (numberOfQuestions > safeMax) numberOfQuestions = safeMax;
                  if (duration > safeMax) duration = safeMax;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.s20,
                      AppTokens.s24,
                      AppTokens.s20,
                      AppTokens.s24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SummaryPill(
                              total: totalSelected,
                              type: widget.type,
                            ),
                            const SizedBox(height: AppTokens.s24),
                            Text(
                              'Module details',
                              style: AppTokens.overline(context),
                            ),
                            const SizedBox(height: AppTokens.s8),
                            _LabelledField(
                              title: 'Name of test',
                              child: CustomTextField(
                                isMultiline: false,
                                title: 'Name of Test',
                                controller: name,
                                hintText: 'e.g. Thyroid — High-Yield Revision',
                                onChanged: (_) => setState(() {}),
                                validator: (_) {
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: AppTokens.s16),
                            _LabelledField(
                              title: 'Description',
                              child: CustomTextField(
                                isMultiline: true,
                                title: 'Description',
                                controller: description,
                                hintText:
                                    'Add a short note so you remember what this module focuses on.',
                                validator: (_) {
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: _s28Plus),
                            Text(
                              'Shape the test',
                              style: AppTokens.overline(context),
                            ),
                            const SizedBox(height: AppTokens.s8),
                            _StepperCard(
                              title: 'No. of Questions',
                              subtitle:
                                  'Pick how many bookmarks this module pulls into one session.',
                              value: numberOfQuestions,
                              min: 1,
                              max: safeMax,
                              unit: '',
                              onChanged: (v) {
                                setState(() {
                                  numberOfQuestions = v;
                                });
                              },
                            ),
                            const SizedBox(height: AppTokens.s16),
                            _StepperCard(
                              title: 'Duration',
                              subtitle:
                                  'Set how much time you want on the clock when you run this module.',
                              value: duration,
                              min: 1,
                              max: safeMax,
                              unit: 'min',
                              onChanged: (v) {
                                setState(() {
                                  duration = v;
                                });
                              },
                              footerRight: Text(
                                convertMinutesToHHMMSS(duration),
                                style: AppTokens.numeric(context, size: 13)
                                    .copyWith(
                                  color: AppTokens.accent(context),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTokens.s24),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.selectedBuilder,
  });

  final VoidCallback onBack;
  final Widget Function() selectedBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s12,
            AppTokens.s8,
            AppTokens.s20,
            AppTokens.s20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _BackChip(onTap: onBack),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: Text(
                      'STEP 5/5 · CONFIGURE',
                      style: AppTokens.overline(context).copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: AppTokens.radius12,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.22),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        selectedBuilder(),
                        const SizedBox(width: 6),
                        Text(
                          'picked',
                          style: AppTokens.caption(context).copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s20),
              Text(
                'Configure your module',
                style: AppTokens.displayMd(context).copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Name it, add a note, and dial in the question count and duration before you launch.',
                style: AppTokens.body(context).copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackChip extends StatelessWidget {
  const _BackChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.total, required this.type});

  final int total;
  final String type;

  String _typeLabel() {
    switch (type) {
      case 'McqBookmark':
        return 'MCQ BOOKMARK';
      case 'MockBookmark':
        return 'MOCK BOOKMARK';
      default:
        return type.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.accentSoft(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(
          color: AppTokens.accent(context).withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accent(context),
              borderRadius: AppTokens.radius12,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(),
                  style: AppTokens.overline(context).copyWith(
                    color: AppTokens.accent(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  total > 0
                      ? '$total bookmarks ready for this module'
                      : 'No bookmarks picked yet',
                  style: AppTokens.titleSm(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelledField extends StatelessWidget {
  const _LabelledField({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTokens.titleSm(context)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _StepperCard extends StatelessWidget {
  const _StepperCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
    this.footerRight,
  });

  final String title;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;
  final Widget? footerRight;

  @override
  Widget build(BuildContext context) {
    final bool canDecrement = value > min;
    final bool canIncrement = value < max;
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTokens.titleSm(context)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTokens.caption(context)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: AppTokens.radius12,
                  border: Border.all(
                    color: AppTokens.accent(context).withOpacity(0.24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value.toString(),
                      style: AppTokens.numeric(context, size: 18).copyWith(
                        color: AppTokens.accent(context),
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.accent(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.remove_rounded,
                enabled: canDecrement,
                onTap: canDecrement ? () => onChanged(value - 1) : null,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: AppTokens.accent(context),
                    inactiveTrackColor:
                        AppTokens.accent(context).withOpacity(0.16),
                    thumbColor: AppTokens.accent(context),
                    overlayColor: AppTokens.accent(context).withOpacity(0.18),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                  ),
                  child: Slider(
                    value: value.toDouble().clamp(
                          min.toDouble(),
                          max.toDouble(),
                        ),
                    min: min.toDouble(),
                    max: max.toDouble() == min.toDouble()
                        ? min.toDouble() + 1
                        : max.toDouble(),
                    onChanged: (v) => onChanged(v.toInt().clamp(min, max)),
                  ),
                ),
              ),
              _RoundIconButton(
                icon: Icons.add_rounded,
                enabled: canIncrement,
                onTap: canIncrement ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text(min.toString(), style: AppTokens.caption(context)),
                const Spacer(),
                if (footerRight != null)
                  footerRight!
                else
                  Text(max.toString(), style: AppTokens.caption(context)),
                if (footerRight != null) ...[
                  const SizedBox(width: AppTokens.s8),
                  Text(
                    '${max.toString()} max',
                    style: AppTokens.caption(context),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.surface2(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppTokens.border(context)),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppTokens.ink(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s12,
          AppTokens.s20,
          AppTokens.s16,
        ),
        decoration: BoxDecoration(
          color: AppTokens.surface(context),
          border: Border(
            top: BorderSide(color: AppTokens.border(context)),
          ),
        ),
        child: SizedBox(
          height: 54,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: loading ? null : onTap,
              borderRadius: AppTokens.radius16,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: enabled
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTokens.brand, AppTokens.brand2],
                        )
                      : null,
                  color: enabled ? null : AppTokens.surface3(context),
                  borderRadius: AppTokens.radius16,
                  boxShadow: enabled ? AppTokens.shadow2(context) : null,
                ),
                child: Center(
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: AppTokens.titleSm(context).copyWith(
                                color: enabled
                                    ? Colors.white
                                    : AppTokens.muted(context),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: AppTokens.s8),
                            Icon(
                              Icons.rocket_launch_rounded,
                              size: 18,
                              color: enabled
                                  ? Colors.white
                                  : AppTokens.muted(context),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomTextField — preserved PUBLIC class from the legacy screen. Rebuilt
// to consume [AppTokens.inputDecoration] but retaining its constructor
// so any external callers keep compiling.
// ---------------------------------------------------------------------------
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String hintText;
  final String title;
  final bool isMultiline;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.validator,
    required this.title,
    this.isMultiline = false,
    required this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      maxLines: isMultiline ? 5 : 1,
      keyboardType: isMultiline ? TextInputType.multiline : TextInputType.name,
      cursorColor: AppTokens.accent(context),
      style: AppTokens.body(context).copyWith(
        color: AppTokens.ink(context),
        fontSize: 15,
      ),
      decoration: AppTokens.inputDecoration(
        context,
        hint: hintText,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Local spacing — single non-canonical value used only by this screen,
// between the module-details block and the shape-the-test block. Kept
// private here to avoid mutating [AppTokens].
// ---------------------------------------------------------------------------
const double _s28Plus = 28;
