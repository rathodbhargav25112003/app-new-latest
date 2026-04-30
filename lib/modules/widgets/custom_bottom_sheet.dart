import 'package:flutter/material.dart';

import '../../helpers/app_tokens.dart';
import 'package:shusruta_lms/modules/videolectures/store/video_category_store.dart';

/// CustomBottomSheet — simple radio-list bottom sheet used by the video
/// module to filter responses. Public surface preserved exactly:
///   • const constructor `{super.key, required List radioItems,
///     VideoCategoryStore? store, required double heightSize,
///     required String selectedVal}` (radioItems is nullable List of String)
///   • state field [selectedValue] seeded from `widget.selectedVal`
///   • pop returns the selected string; if it differs from the seed,
///     `widget.store?.setFilterValue(selectedValue!)` is invoked
class CustomBottomSheet extends StatefulWidget {
  final List<String>? radioItems;
  final VideoCategoryStore? store;
  final double heightSize;
  final String selectedVal;
  const CustomBottomSheet({
    super.key,
    required this.radioItems,
    this.store,
    required this.heightSize,
    required this.selectedVal,
  });

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.selectedVal;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.radioItems ?? const <String>[];
    return Container(
      height: widget.heightSize,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SheetGrabber(),
            const SizedBox(height: AppTokens.s16),
            Text(
              'Response Filter',
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
                itemBuilder: (context, index) {
                  final label = items[index];
                  final selected = selectedValue == label;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.s8),
                    child: _FilterOptionTile(
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

class _FilterOptionTile extends StatelessWidget {
  const _FilterOptionTile({
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
