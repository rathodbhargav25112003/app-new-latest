// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';

/// Labeled checkbox used inside the exam screens (mark-for-review,
/// mark-for-guess). Redesigned with AppTokens while preserving:
///   • Constructor `CheckBoxWithLabel({super.key, required label,
///     style, required isChecked, required onStatusChanged,
///     required isShowMessage})`
///   • `onStatusChanged: ValueChanged<bool?>` retains its
///     `bool?` arg type so existing callers compile unchanged.
///   • `isShowMessage` short-circuit behaviour preserved — when
///     true, the widget fires a SnackBar with "Please Select Option"
///     and skips calling `onStatusChanged`.
///   • `style` override still takes precedence.
class CheckBoxWithLabel extends StatefulWidget {
  const CheckBoxWithLabel({
    super.key,
    required this.label,
    this.style,
    required this.isChecked,
    required this.onStatusChanged,
    required this.isShowMessage,
  });

  final String label;
  final bool isChecked;
  final TextStyle? style;
  final bool isShowMessage;
  final ValueChanged<bool?> onStatusChanged;

  @override
  _CheckBoxWithLabelState createState() => _CheckBoxWithLabelState();
}

class _CheckBoxWithLabelState extends State<CheckBoxWithLabel> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          value: widget.isChecked,
          activeColor: AppTokens.accent(context),
          checkColor: Colors.white,
          side: BorderSide(color: AppTokens.border(context), width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r8 / 2),
          ),
          onChanged: (value) {
            if (widget.isShowMessage) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                duration: Duration(seconds: 2),
                content: Text('Please Select Option'),
              ));
            } else {
              setState(() {
                widget.onStatusChanged(value);
              });
            }
          },
        ),
        const SizedBox(width: AppTokens.s4),
        Flexible(
          child: Text(
            widget.label,
            style: widget.style ??
                AppTokens.body(context).copyWith(
                  color: AppTokens.ink(context),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
