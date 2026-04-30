// ════════════════════════════════════════════════════════════════════
// PinEntryScreen — boot-time PIN gate
// ════════════════════════════════════════════════════════════════════
//
// Renders 4 hairline-bordered cells. The student types their 4-digit
// PIN; we verify against `PinLockService` (SHA-256 + salt). Lockout
// after 5 wrong attempts (5 min); after 10 wrong, the PIN is wiped
// and the student is forced to re-login via OTP.
//
// Use cases:
//   • Boot-time gate after splash, when biometric is unavailable
//     OR fails AND a PIN has been set.
//   • Sensitive-action confirm (Profile → Change phone number).
//
// Returns to caller via Navigator.pop with:
//   true   → unlock OK
//   false  → user backed out without unlocking
//
// Caller is responsible for routing to login on requiresLogin:
//   final ok = await Navigator.push<bool>(...);
//   if (ok != true) Navigator.pushReplacementNamed(context, Routes.login);

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../services/pin_lock_service.dart';

class PinEntryScreen extends StatefulWidget {
  /// Optional headline override — useful when reusing this screen
  /// from a sensitive-action gate ("Confirm to change phone").
  final String? title;
  final String? subtitle;
  const PinEntryScreen({super.key, this.title, this.subtitle});

  static Route<bool> route({String? title, String? subtitle}) {
    return MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => PinEntryScreen(title: title, subtitle: subtitle),
    );
  }

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _ctrls = List.generate(4, (_) => TextEditingController());
  final _focus = List.generate(4, (_) => FocusNode());
  final PinLockService _service = PinLockService();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final f in _focus) f.dispose();
    super.dispose();
  }

  String get _entry => _ctrls.map((c) => c.text).join();

  void _onChanged(int i, String v) {
    if (v.isNotEmpty && i < 3) {
      _focus[i + 1].requestFocus();
    } else if (v.isEmpty && i > 0) {
      _focus[i - 1].requestFocus();
    }
    if (_entry.length == 4) _verify();
    setState(() {});
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await _service.verify(_entry);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r['valid'] == true) {
      Navigator.of(context).pop(true);
      return;
    }
    if (r['requiresLogin'] == true) {
      // Hard reset — 10 wrong PINs cleared the stored hash.
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (_) => false);
      return;
    }
    final lockedSeconds = r['lockedSeconds'] as int? ?? 0;
    final remaining = r['remaining'] as int?;
    setState(() {
      if (lockedSeconds > 0) {
        _error = 'Too many wrong attempts. Try again in ${lockedSeconds}s.';
      } else if (remaining != null) {
        _error = 'Wrong PIN. ${remaining} attempts left.';
      } else {
        _error = 'Wrong PIN.';
      }
      // Clear cells so the student starts fresh.
      for (final c in _ctrls) c.clear();
      _focus[0].requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppTokens.scaffold(context),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: AppTokens.radius16,
                ),
                child: Icon(Icons.lock_outline_rounded,
                    size: 28, color: AppTokens.accent(context)),
              ),
              const SizedBox(height: 24),
              Text(
                widget.title ?? 'Enter your PIN',
                style: AppTokens.displayMd(context),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle ?? 'Confirm to continue.',
                style: AppTokens.bodyLg(context).copyWith(
                  color: AppTokens.muted(context),
                ),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(4, (i) {
                  final filled = _ctrls[i].text.isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 56,
                      height: 64,
                      child: TextField(
                        controller: _ctrls[i],
                        focusNode: _focus[i],
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        obscureText: true,
                        obscuringCharacter: '•',
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: AppTokens.titleMd(context).copyWith(
                          fontSize: 22,
                          height: 1,
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
                        onChanged: (v) => _onChanged(i, v),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 14, color: AppTokens.danger(context)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.danger(context),
                        ),
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          Routes.login,
                          (_) => false,
                        );
                      },
                child: Text(
                  "Sign in with OTP instead",
                  style: AppTokens.body(context).copyWith(
                    color: AppTokens.accent(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
