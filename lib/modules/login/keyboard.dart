import 'package:flutter/material.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';

/// Custom on-screen keyboard for email (QWERTY) and number (T9) input.
///
/// Public surface preserved exactly:
///   • enum [KeyboardType] with values `number`, `email`
///   • class [CustomKeyboard] with
///     `onKeyPressed: Function(String)` and `keyboardType: KeyboardType`
///   • top-level [showCustomKeyboardSheet] with
///     `(BuildContext, KeyboardType, TextEditingController)` signature
///   • callback semantics for `←` (backspace), `Done` (close sheet)
///     and ordinary character keys are unchanged
enum KeyboardType { number, email }

class CustomKeyboard extends StatelessWidget {
  final Function(String) onKeyPressed;
  final KeyboardType keyboardType;

  const CustomKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s8,
        AppTokens.s12,
        AppTokens.s8,
        AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: AppTokens.border(context)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTokens.s8),
              decoration: BoxDecoration(
                color: AppTokens.border(context),
                borderRadius: BorderRadius.circular(AppTokens.r8),
              ),
            ),
            if (keyboardType == KeyboardType.number)
              _buildNumberKeyboard(context)
            else
              _buildEmailKeyboard(context),
            const SizedBox(height: AppTokens.s4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildKey(
                      context,
                      '←',
                      isSpecialKey: true,
                      special: _SpecialKind.backspace,
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: _buildKey(
                      context,
                      'Done',
                      isSpecialKey: true,
                      special: _SpecialKind.done,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s4),
          ],
        ),
      ),
    );
  }

  /// Layout for Numbers (T9-like layout)
  Widget _buildNumberKeyboard(BuildContext context) {
    List<List<String>> rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '']
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) {
                return const Spacer();
              }
              return Expanded(child: _buildKey(context, key));
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  /// Layout for Email (QWERTY-like layout)
  Widget _buildEmailKeyboard(BuildContext context) {
    List<List<String>> rows = [
      ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
      ['z', 'x', 'c', 'v', 'b', 'n', 'm', '@', '.', '_'],
      ['-', 'SPACE']
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key == 'SPACE') {
                return Expanded(
                  flex: 3,
                  child: _buildKey(
                    context,
                    ' ',
                    displayText: 'Space',
                    isSpaceKey: true,
                  ),
                );
              }
              return Expanded(child: _buildKey(context, key));
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(
    BuildContext context,
    String key, {
    bool isSpecialKey = false,
    String? displayText,
    bool isSpaceKey = false,
    _SpecialKind special = _SpecialKind.regular,
  }) {
    final bool isDone = special == _SpecialKind.done;
    final bool isBackspace = special == _SpecialKind.backspace;

    // Colors
    Color bg;
    Color fg;
    Gradient? gradient;
    Color borderColor;

    if (isDone) {
      gradient = const LinearGradient(
        colors: [AppTokens.brand, AppTokens.brand2],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      bg = AppTokens.brand;
      fg = Colors.white;
      borderColor = Colors.transparent;
    } else if (isBackspace) {
      bg = AppTokens.surface3(context);
      fg = AppTokens.ink(context);
      borderColor = AppTokens.border(context);
    } else if (isSpaceKey) {
      bg = AppTokens.surface(context);
      fg = AppTokens.ink2(context);
      borderColor = AppTokens.border(context);
    } else {
      bg = AppTokens.surface(context);
      fg = AppTokens.ink(context);
      borderColor = AppTokens.border(context);
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onKeyPressed(key),
          borderRadius: BorderRadius.circular(AppTokens.r8),
          child: Ink(
            decoration: BoxDecoration(
              color: gradient == null ? bg : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppTokens.r8),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: 34),
              padding: const EdgeInsets.symmetric(
                vertical: AppTokens.s8,
                horizontal: 2,
              ),
              child: Text(
                displayText ?? key,
                style: TextStyle(
                  fontSize: isSpecialKey
                      ? 16
                      : keyboardType == KeyboardType.number
                          ? 20
                          : 16,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _SpecialKind { regular, backspace, done }

void showCustomKeyboardSheet(BuildContext context, KeyboardType type,
    TextEditingController controller) {
  // Ensure no field has focus before showing custom keyboard
  FocusScope.of(context).unfocus();

  showModalBottomSheet(
    barrierColor: Colors.transparent,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) {
      return CustomKeyboard(
        keyboardType: type,
        onKeyPressed: (value) {
          if (value == '←') {
            if (controller.text.isNotEmpty) {
              controller.text =
                  controller.text.substring(0, controller.text.length - 1);
            }
          } else if (value == 'Done') {
            Navigator.pop(context); // Close keyboard
          } else {
            controller.text += value;
          }
        },
      );
    },
  );
}
