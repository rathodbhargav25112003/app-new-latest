import 'dart:io';
import 'package:flutter/material.dart';

import '../../helpers/app_tokens.dart';
import 'package:shusruta_lms/modules/videolectures/store/video_category_store.dart';

/// CustomBottomSheetWindow — desktop / tablet variant of the filter sheet
/// (rounded dialog, scrollable list). Public surface preserved exactly:
///   • const constructor `{super.key, required List radioItems,
///     VideoCategoryStore? store, required String selectedVal}`
///     (radioItems is nullable List of String)
///   • `initState` debug-prints `widget.radioItems` and seeds
///     `selectedValue = widget.selectedVal`
///   • pop returns the selected string and invokes
///     `widget.store?.setFilterValue(selectedValue!)` on change
class CustomBottomSheetWindow extends StatefulWidget {
  final List<String>? radioItems;
  final VideoCategoryStore? store;
  final String selectedVal;
  const CustomBottomSheetWindow({
    super.key,
    required this.radioItems,
    this.store,
    required this.selectedVal,
  });

  @override
  State<CustomBottomSheetWindow> createState() =>
      _CustomBottomSheetWindowState();
}

class _CustomBottomSheetWindowState extends State<CustomBottomSheetWindow> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    debugPrint('${widget.radioItems}');
    selectedValue = widget.selectedVal;
  }

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    final items = widget.radioItems ?? const <String>[];
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: _isDesktop
              ? BorderRadius.circular(AppTokens.r20)
              : const BorderRadius.vertical(
                  top: Radius.circular(AppTokens.r20),
                ),
          color: AppTokens.surface(context),
        ),
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s20,
            AppTokens.s20,
            AppTokens.s20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter',
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
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  itemCount: items.length,
                  shrinkWrap: true,
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
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
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
