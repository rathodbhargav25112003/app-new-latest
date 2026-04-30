import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/app_tokens.dart';

/// OtpField — shared OTP-entry widget used by all three verify screens
/// (verify_otp_phone, verify_otp_mail, verify_change_mobile_otp).
///
/// Replaces three nearly-identical inline implementations that each
/// hand-built a Row of [TextField]s with [FocusNode] plumbing. This
/// widget owns that plumbing — the caller just supplies an [onChanged]
/// (fires whenever the user types) and an [onCompleted] (fires when all
/// cells are filled).
///
/// Behaviour:
///  * Auto-advances on every digit entered.
///  * Auto-goes-back on backspace when current cell is empty.
///  * Tapping a cell moves focus there (consistent with iOS Auth UX).
///  * Supports paste into the first cell (e.g. iOS SMS autofill picks
///    up the code) — distributes digits across cells.
///  * Supports [autoFocus] so the keyboard opens on navigation-in.
///  * Tabular numerals — all cells stay the same width regardless of
///    which digits are entered.
///
/// Example:
///   OtpField(
///     length: 4,
///     onChanged: (v) => _otp = v,
///     onCompleted: (v) => _verify(v),
///   )
class OtpField extends StatefulWidget {
  const OtpField({
    super.key,
    this.length = 4,
    this.onChanged,
    this.onCompleted,
    this.autoFocus = true,
    this.cellWidth = 58,
    this.cellHeight = 64,
    this.errorText,
  });

  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autoFocus;
  final double cellWidth;
  final double cellHeight;

  /// When non-null, draws all cells with a danger border and renders
  /// the message below the row. Typical usage is to clear it on the
  /// next keystroke so the error only blinks once.
  final String? errorText;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  // Tracks the currently-focused cell index. Kept behind an ignore so the
  // field stays available for future visual-state work without failing the
  // linter today.
  // ignore: unused_field
  int _focused = 0;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (i) {
      final node = FocusNode();
      node.addListener(() {
        if (node.hasFocus) setState(() => _focused = i);
      });
      return node;
    });
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String _value() => _controllers.map((c) => c.text).join();

  void _handleChange(int index, String value) {
    // User pasted more than one digit into a single cell — distribute.
    if (value.length > 1) {
      for (var i = 0; i < value.length && index + i < widget.length; i++) {
        _controllers[index + i].text = value[i];
      }
      final last = (index + value.length - 1).clamp(0, widget.length - 1);
      if (last < widget.length - 1) {
        _focusNodes[last + 1].requestFocus();
      } else {
        _focusNodes[last].unfocus();
      }
      setState(() {});
      widget.onChanged?.call(_value());
      if (_value().length == widget.length) {
        widget.onCompleted?.call(_value());
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
    setState(() {});
    widget.onChanged?.call(_value());
    if (_value().length == widget.length) {
      widget.onCompleted?.call(_value());
    }
  }

  void _handleKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey != LogicalKeyboardKey.backspace) return;
    if (_controllers[index].text.isNotEmpty) return;
    if (index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
      widget.onChanged?.call(_value());
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (int i = 0; i < widget.length; i++) ...[
              SizedBox(
                width: widget.cellWidth,
                height: widget.cellHeight,
                child: KeyboardListener(
                  focusNode: FocusNode(skipTraversal: true),
                  onKeyEvent: (event) => _handleKey(i, event),
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: AppTokens.numeric(context, size: 24),
                    cursorColor: AppTokens.accent(context),
                    enableSuggestions: false,
                    autocorrect: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (v) => _handleChange(i, v),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: _controllers[i].text.isNotEmpty
                          ? AppTokens.accentSoft(context)
                          : AppTokens.surface(context),
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppTokens.radius12,
                        borderSide: BorderSide(
                          color: hasError
                              ? AppTokens.danger(context)
                              : (_controllers[i].text.isNotEmpty
                                  ? AppTokens.accent(context)
                                  : AppTokens.border(context)),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppTokens.radius12,
                        borderSide: BorderSide(
                          color: hasError
                              ? AppTokens.danger(context)
                              : AppTokens.accent(context),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (i != widget.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.errorText!,
              style: AppTokens.caption(context)
                  .copyWith(color: AppTokens.danger(context)),
            ),
          ),
      ],
    );
  }
}
