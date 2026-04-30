import 'dart:io';
import 'package:flutter/material.dart';

import '../../helpers/app_tokens.dart';
import 'package:shusruta_lms/modules/videolectures/store/video_category_store.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import, unnecessary_import
import 'package:flutter/cupertino.dart';
// ignore: unused_import
import '../../helpers/colors.dart';
// ignore: unused_import
import '../../helpers/dimensions.dart';
// ignore: unused_import
import '../../helpers/styles.dart';

/// CustomTopicBottomSheet — topic-filter bottom sheet for the video module.
/// Public surface preserved exactly:
///   • const constructor `{super.key, required List radioItems,
///     VideoCategoryStore? store, double? heightSize, required String
///     selectedVal}`
///   • seeds `selectedValue = widget.selectedVal`, pops returning the
///     selected string, and invokes
///     `widget.store?.setFilterValue(selectedValue!)` on change
class CustomTopicBottomSheet extends StatefulWidget {
  final List<String>? radioItems;
  final VideoCategoryStore? store;
  final double? heightSize;
  final String selectedVal;
  const CustomTopicBottomSheet({
    super.key,
    required this.radioItems,
    this.store,
    this.heightSize,
    required this.selectedVal,
  });

  @override
  State<CustomTopicBottomSheet> createState() => _CustomTopicBottomSheetState();
}

class _CustomTopicBottomSheetState extends State<CustomTopicBottomSheet> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.selectedVal;
  }

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    final items = widget.radioItems ?? const <String>[];
    return Container(
      height: _isDesktop ? null : widget.heightSize,
      width: MediaQuery.of(context).size.width,
      constraints: _isDesktop
          ? const BoxConstraints(maxWidth: 560)
          : null,
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: _isDesktop
            ? BorderRadius.circular(AppTokens.r20)
            : const BorderRadius.vertical(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!_isDesktop) _SheetGrabber(),
            const SizedBox(height: AppTokens.s12),
            Text(
              'Topics',
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
            const SizedBox(height: AppTokens.s16),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                padding: EdgeInsets.zero,
                itemBuilder: (BuildContext context, int index) {
                  final label = items[index];
                  final selected = selectedValue == label;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.s8),
                    child: _TopicTile(
                      label: label,
                      selected: selected,
                      onTap: () {
                        setState(() => selectedValue = label);
                        Navigator.of(context).pop(selectedValue);
                        if (widget.selectedVal != selectedValue) {
                          widget.store?.setFilterValue(selectedValue!);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
          ),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppTokens.brand, AppTokens.brand2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : AppTokens.surface2(context),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppTokens.border(context),
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppTokens.ink(context),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: AppTokens.s8),
                const Icon(Icons.check_rounded,
                    color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
