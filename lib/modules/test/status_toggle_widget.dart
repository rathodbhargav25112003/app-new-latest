// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unintended_html_in_doc_comment

import 'package:flutter/material.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';

/// Horizontal pill segmented control — highlights the selected option and
/// calls back with its string label.
///
/// Preserved public contract:
///   • `StatusToggleWidget({super.key, required options, required
///     onOptionSelected})` where `options: List<String>` and
///     `onOptionSelected: Function(String)`.
///   • Initial selection is index 0.
///   • Tap fires `onOptionSelected(options[index])` and updates internal
///     selection state.
class StatusToggleWidget extends StatefulWidget {
  final List<String> options;
  final Function(String) onOptionSelected;

  const StatusToggleWidget({
    super.key,
    required this.options,
    required this.onOptionSelected,
  });

  @override
  State<StatusToggleWidget> createState() => _StatusToggleWidgetState();
}

class _StatusToggleWidgetState extends State<StatusToggleWidget> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.options.length, (index) {
          final isSelected = _selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                widget.onOptionSelected(widget.options[index]);
              },
              borderRadius: BorderRadius.circular(AppTokens.r20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s12,
                  vertical: AppTokens.s8,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppTokens.brand, AppTokens.brand2],
                        )
                      : null,
                  color: isSelected ? null : AppTokens.surface(context),
                  borderRadius: BorderRadius.circular(AppTokens.r20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppTokens.border(context),
                  ),
                ),
                child: Text(
                  widget.options[index],
                  style: AppTokens.caption(context).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTokens.muted(context),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
