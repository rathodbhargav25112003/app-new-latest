// ════════════════════════════════════════════════════════════════════
// OtpAutofillService — single entry point for "auto-fill OTP from SMS"
// ════════════════════════════════════════════════════════════════════
//
// Big-tech apps (PhonePe, Swiggy, Zomato, etc.) auto-fill the OTP from
// the verification SMS without the user copy-pasting. We replicate that
// using two complementary mechanisms:
//
//   1. Android — SMS Retriever API via the `sms_autofill` plugin.
//      No READ_SMS permission required. The OTP message must contain
//      a unique 11-character app hash (Google's spec). We expose
//      `getAppSignature()` so the backend can prepend that hash to
//      every outgoing OTP message.
//
//   2. iOS — `AutofillHints.oneTimeCode` on a TextFormField surfaces
//      the OTP in QuickType automatically when the SMS arrives. No
//      plugin code required; just a constructor flag on the field.
//
// This file:
//   • exposes `start()` to begin listening (Android only — silent on
//     iOS since iOS handles it natively),
//   • exposes a Stream<String> of received OTPs,
//   • exposes `stop()` for cleanup.
//
// Usage from a screen's State:
//
//   final _autofill = OtpAutofillService();
//   StreamSubscription<String>? _sub;
//
//   @override
//   void initState() {
//     super.initState();
//     _autofill.start();
//     _sub = _autofill.codes.listen((code) {
//       _otpController.text = code;
//       _verifyOtp();      // your existing verify path
//     });
//   }
//
//   @override
//   void dispose() {
//     _sub?.cancel();
//     _autofill.stop();
//     super.dispose();
//   }
//
// And on the TextFormField:
//
//   TextFormField(
//     controller: _otpController,
//     keyboardType: TextInputType.number,
//     autofillHints: const [AutofillHints.oneTimeCode],
//   )

import 'dart:async';
import 'dart:io';
import 'package:sms_autofill/sms_autofill.dart';

class OtpAutofillService {
  final _controller = StreamController<String>.broadcast();
  bool _listening = false;
  StreamSubscription<String>? _codeSub;

  /// Stream of OTP codes received from SMS (Android). Emits the
  /// numeric portion only; whatever comes after the app hash is
  /// dropped so the consumer can paste straight into the field.
  Stream<String> get codes => _controller.stream;

  /// Begin listening for incoming SMS that match the app's signature.
  /// Idempotent — calling `start()` while already listening is a
  /// no-op. On iOS this is a no-op because Apple handles autofill
  /// natively via QuickType.
  ///
  /// The `sms_autofill` package fires matched SMS bodies through its
  /// `code` stream rather than returning them from `listenForCode()`,
  /// so we subscribe to the stream and call `listenForCode()` purely
  /// to register the underlying broadcast receiver.
  Future<void> start() async {
    if (!Platform.isAndroid) return;
    if (_listening) return;
    _listening = true;
    try {
      // Subscribe FIRST so we don't miss the very first SMS body.
      _codeSub = SmsAutoFill().code.listen((body) {
        final code = _extractOtp(body);
        if (code != null) _controller.add(code);
      });
      // Register the broadcast receiver. listenForCode() is fire-
      // and-forget; the body arrives via the subscription above.
      await SmsAutoFill().listenForCode();
    } catch (_) {
      // Plugin fails gracefully on emulators / older Android — just
      // keep silent; user can still paste manually.
      _listening = false;
    }
  }

  /// Stop listening + close the underlying SMS retriever. Call from
  /// dispose so the SMS Retriever Broadcast Receiver doesn't leak.
  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      await _codeSub?.cancel();
      _codeSub = null;
      await SmsAutoFill().unregisterListener();
    } catch (_) { /* ignore */ }
    _listening = false;
  }

  /// Returns the 11-char app hash the backend must prepend to every
  /// OTP SMS body for the SMS Retriever API to match. Format:
  /// `<#> Your OTP is 123456 \n\n <hash>`. Hand this to the backend
  /// (or surface in admin settings) so the SMS template includes it.
  Future<String?> getAppSignature() async {
    if (!Platform.isAndroid) return null;
    try {
      return await SmsAutoFill().getAppSignature;
    } catch (_) {
      return null;
    }
  }

  /// Extract the first numeric run of length 4–8 from the SMS body.
  /// Tolerant of various OTP message templates (PhonePe-style, Razorpay-
  /// style, plain). Returns null if no OTP-shaped substring found.
  String? _extractOtp(String? body) {
    if (body == null || body.isEmpty) return null;
    final match = RegExp(r'\b(\d{4,8})\b').firstMatch(body);
    return match?.group(1);
  }
}
