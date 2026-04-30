// ════════════════════════════════════════════════════════════════════
// OtpAutofillField — drop-in OTP input with SMS autofill
// ════════════════════════════════════════════════════════════════════
//
// Wraps a 6-digit OTP entry with:
//   • Apple-style boxed cells (rounded 12, hairline border, soft fill)
//   • iOS QuickType autofill via `AutofillHints.oneTimeCode`
//   • Android SMS Retriever autofill via `OtpAutofillService` stream
//   • Pasting a 6-digit code into any cell auto-distributes
//   • Auto-advances cursor on each keystroke; auto-fires onCompleted
//
// Designed to replace the existing `OTPTextField` widget used in:
//   • login_with_phone_screen.dart      (after we send OTP)
//   • signup_with_phone_screen.dart     (after we send OTP)
//   • verify_otp_mail.dart              (email-OTP flow)
//   • verifyotp/verify_otp.dart         (phone-OTP flow)
//   • verifyotp/verify_change_mobile_otp.dart (settings change-mobile)
//
// Usage:
//
//   OtpAutofillField(
//     length: 6,
//     onCompleted: (code) => _verifyOtp(code),
//     onChanged: (code)   => setState(() => _otp = code),
//     autoStartListener: true, // begin SMS retriever immediately
//   )
//
// The widget owns its own AnimationController for the focus-pulse on
// the active cell. Disposed automatically on widget unmount.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/app_tokens.dart';
import '../../services/otp_autofill_service.dart';

class OtpAutofillField extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  /// When true, immediately begins listening for an SMS-retrieved OTP
  /// in initState. Set false if the parent wants to delay (e.g. only
  /// listen after the OTP-send call has succeeded).
  final bool autoStartListener;

  /// Optional initial value (e.g. when restoring from a paused screen).
  final String? initialValue;

  /// Disable user input — useful while the verify call is in flight.
  final bool enabled;

  const OtpAutofillField({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.autoStartListener = true,
    this.initialValue,
    this.enabled = true,
  });

  @override
  State<OtpAutofillField> createState() => _OtpAutofillFieldState();
}

class _OtpAutofillFieldState extends State<OtpAutofillField> {
  late final List<TextEditingController> _ctrls;
  late final List<FocusNode> _focus;
  final OtpAutofillService _autofill = OtpAutofillService();
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(widget.length, (_) => TextEditingController());
    _focus = List.generate(widget.length, (_) => FocusNode());

    if (widget.initialValue != null) _distribute(widget.initialValue!);

    if (widget.autoStartListener) {
      _autofill.start();
      _sub = _autofill.codes.listen((code) {
        if (!mounted) return;
        _distribute(code);
        widget.onCompleted?.call(_currentCode());
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _autofill.stop();
    for (final c in _ctrls) c.dispose();
    for (final f in _focus) f.dispose();
    super.dispose();
  }

  String _currentCode() => _ctrls.map((c) => c.text).join();

  /// Distribute a multi-digit string across the cells. Used both for
  /// SMS-retrieved codes AND when the user pastes a code into one
  /// cell.
  void _distribute(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    for (var i = 0; i < widget.length; i++) {
      _ctrls[i].text = i < digits.length ? digits[i] : '';
    }
    final landed = digits.length.clamp(0, widget.length - 1);
    if (landed >= 0 && landed < _focus.length) {
      _focus[landed].requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
    widget.onChanged?.call(_currentCode());
    if (digits.length >= widget.length) {
      widget.onCompleted?.call(_currentCode());
    }
    if (mounted) setState(() {});
  }

  void _onCellChanged(int index, String value) {
    // Multi-char paste → distribute to subsequent cells.
    if (value.length > 1) {
      _distribute(value);
      return;
    }
    if (value.isNotEmpty && index < widget.length - 1) {
      _focus[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focus[index - 1].requestFocus();
    }
    widget.onChanged?.call(_currentCode());
    if (_currentCode().length == widget.length &&
        !_currentCode().contains(' ')) {
      widget.onCompleted?.call(_currentCode());
      FocusScope.of(context).unfocus();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.length, (i) {
          final filled = _ctrls[i].text.isNotEmpty;
          final isFirst = i == 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: SizedBox(
              width: 46,
              height: 56,
              child: TextField(
                controller: _ctrls[i],
                focusNode: _focus[i],
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                // Only the first cell carries the autofill hint — iOS
                // pastes the entire OTP starting from cell 0; we then
                // redistribute via _onCellChanged's paste path.
                autofillHints: isFirst
                    ? const [AutofillHints.oneTimeCode]
                    : null,
                style: AppTokens.titleMd(context).copyWith(
                  fontSize: 20,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: filled
                      ? AppTokens.surface(context)
                      : AppTokens.surface2(context),
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppTokens.radius12,
                    borderSide: BorderSide(
                      color: filled
                          ? AppTokens.accent(context)
                          : AppTokens.border(context),
                      width: filled ? 1.4 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppTokens.radius12,
                    borderSide: BorderSide(
                      color: AppTokens.accent(context),
                      width: 1.6,
                    ),
                  ),
                ),
                onChanged: (v) => _onCellChanged(i, v),
              ),
            ),
          );
        }),
      ),
    );
  }
}
