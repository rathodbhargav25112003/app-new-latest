// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/model/plan_category_model.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/store/new_subscription_store.dart';

import '../../../helpers/app_tokens.dart';
import '../../../helpers/colors.dart';
import '../../../helpers/dimensions.dart';
import '../../../helpers/styles.dart';

/// ExamGoalDialog — first-run dialog asking the learner to pick a
/// NEET / INI‑CET etc. exam goal. Loads categories from
/// [NewSubscriptionStore.getPlanCategories] and returns a
/// `{ 'id': <planCategoryId>, 'name': <categoryName> }` map via
/// `Navigator.pop`.
///
/// Public surface preserved exactly:
///   • class [ExamGoalDialog] + const constructor `{super.key}`
///   • state loads `_store.planCategories` on init
///   • returns `{ 'id': selectedGoal, 'name': selectedCategory.category_name ?? "Unknown" }`
///     via `Navigator.pop(context, ...)` on proceed
class ExamGoalDialog extends StatefulWidget {
  const ExamGoalDialog({super.key});

  @override
  State<ExamGoalDialog> createState() => _ExamGoalDialogState();
}

class _ExamGoalDialogState extends State<ExamGoalDialog> {
  String? selectedGoal;
  late NewSubscriptionStore _store;

  @override
  void initState() {
    super.initState();
    _store = Provider.of<NewSubscriptionStore>(context, listen: false);
    _loadPlanCategories();
  }

  Future<void> _loadPlanCategories() async {
    await _store.getPlanCategories();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = kIsWeb || defaultTargetPlatform == TargetPlatform.macOS;

    return Dialog(
      backgroundColor: AppTokens.surface(context),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.r20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 500 : double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/image/exam_goal.svg',
                  height: isDesktop ? 140 : 120,
                ),
                const SizedBox(height: AppTokens.s24),
                Text(
                  "Select Your Exam Goal",
                  style: AppTokens.titleLg(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.ink(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  "Let us tailor the app experience to your preparation needs.",
                  textAlign: TextAlign.center,
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.muted(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s24),
                Observer(
                  builder: (_) {
                    if (_store.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppTokens.s20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTokens.brand,
                          ),
                        ),
                      );
                    }

                    if (_store.planCategories.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppTokens.s20),
                        child: Center(
                          child: Text(
                            "No exam categories available",
                            style: AppTokens.body(context).copyWith(
                              color: AppTokens.muted(context),
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: _store.planCategories.map((category) {
                        return Column(
                          children: [
                            _buildOption(
                              title: category.category_name ?? "Unknown",
                              subtitle: category.description ?? "",
                              value: category.sid ?? "",
                            ),
                            const SizedBox(height: AppTokens.s12),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: AppTokens.s12),
                SizedBox(
                  width: double.infinity,
                  child: _ProceedCta(
                    enabled: selectedGoal != null,
                    onTap: () {
                      final selectedCategory =
                          _store.planCategories.firstWhere(
                        (category) => category.sid == selectedGoal,
                        orElse: () => PlanCategoryModel(),
                      );

                      Navigator.pop(context, {
                        'id': selectedGoal,
                        'name':
                            selectedCategory.category_name ?? "Unknown",
                      });
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required String subtitle,
    required String value,
  }) {
    bool selected = selectedGoal == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r12),
        onTap: () => setState(() => selectedGoal = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? AppTokens.brand
                  : AppTokens.border(context),
              width: selected ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            color: selected
                ? AppTokens.accentSoft(context)
                : AppTokens.surface(context),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: selectedGoal,
                onChanged: (val) => setState(() => selectedGoal = val),
                activeColor: AppTokens.brand,
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTokens.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand-gradient "Proceed" CTA; grayed out when [enabled] is false.
class _ProceedCta extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _ProceedCta({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          onTap: enabled ? onTap : null,
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTokens.r12),
            ),
            child: Center(
              child: Text(
                "Proceed",
                style: AppTokens.titleSm(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
