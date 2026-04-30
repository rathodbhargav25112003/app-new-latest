import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../../helpers/app_tokens.dart';
import '../dashboard/store/home_store.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/styles.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/widgets.dart';
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';

/// ReviewBottomSheet — testimonial capture sheet with rating + free-text.
/// Public surface preserved exactly:
///   • const constructor `{super.key, required HomeStore store,
///     required String userName}`
///   • Submit dispatches `HomeStore.onCreatetestimonialCall(name,
///     description, rating, context)` then pops the sheet
class ReviewBottomSheet extends StatefulWidget {
  final HomeStore store;
  final String userName;

  const ReviewBottomSheet({
    super.key,
    required this.store,
    required this.userName,
  });

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  final TextEditingController descriptionController = TextEditingController();
  int ratingStar = 0;

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    debugPrint('uname${widget.userName}');
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createtestimonial(
    String name,
    String description,
    int rating,
  ) async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onCreatetestimonialCall(name, description, rating, context);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: _isDesktop ? const BoxConstraints(maxWidth: 560) : null,
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
        child: SingleChildScrollView(
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
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTokens.brand, AppTokens.brand2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                    ),
                    child: const Icon(
                      Icons.rate_review_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Write a review',
                          style: AppTokens.titleMd(context)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Share your experience with Sushruta LGS',
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.ink2(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s20),
              Text(
                'Your review',
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              Container(
                decoration: BoxDecoration(
                  color: AppTokens.surface2(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                  border: Border.all(color: AppTokens.border(context)),
                ),
                child: TextFormField(
                  controller: descriptionController,
                  maxLines: 5,
                  minLines: 4,
                  cursorColor: AppTokens.accent(context),
                  style: AppTokens.body(context),
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.all(AppTokens.s12),
                    hintText:
                        'Tell us what you loved, what could be better…',
                    hintStyle: AppTokens.body(context).copyWith(
                      color: AppTokens.ink2(context),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s20),
              Text(
                'Your rating',
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s12,
                  vertical: AppTokens.s12,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.warningSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RatingBar.builder(
                      direction: Axis.horizontal,
                      itemCount: 5,
                      unratedColor: AppTokens.border(context),
                      glow: false,
                      itemSize: 34,
                      itemPadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      itemBuilder: (context, _) => const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        setState(() => ratingStar = rating.toInt());
                        debugPrint('ratingStar:$ratingStar');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.s24),
              Row(
                children: [
                  if (_isDesktop) ...[
                    Expanded(
                      child: _OutlineCta(
                        label: 'Cancel',
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                  ],
                  Expanded(
                    child: _GradientCta(
                      label: 'Submit',
                      icon: Icons.send_rounded,
                      onTap: () => _createtestimonial(
                        widget.userName,
                        descriptionController.text,
                        ratingStar,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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

class _OutlineCta extends StatelessWidget {
  const _OutlineCta({required this.label, required this.onTap});

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
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(color: AppTokens.border(context)),
          ),
          child: Text(
            label,
            style: AppTokens.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink(context),
            ),
          ),
        ),
      ),
    );
  }
}
