// Reading preferences — local-only (SharedPreferences). Powers Tier 4
// features: focus mode, auto-advance, speed-reading mode.
//
// All reads are O(1) once cached. Single instance held by ReadingPrefs.I.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingPrefs extends ChangeNotifier {
  static final ReadingPrefs I = ReadingPrefs._();
  ReadingPrefs._();

  bool _loaded = false;

  // Focus mode — hide top header, hide nav, full-screen MCQ
  bool _focusMode = false;
  bool get focusMode => _focusMode;
  set focusMode(bool v) {
    _focusMode = v;
    _save();
    notifyListeners();
  }

  // Auto-advance — after viewing answer for N seconds, jump to next Q
  bool _autoAdvance = false;
  bool get autoAdvance => _autoAdvance;
  set autoAdvance(bool v) {
    _autoAdvance = v;
    _save();
    notifyListeners();
  }
  int _autoAdvanceSeconds = 8;
  int get autoAdvanceSeconds => _autoAdvanceSeconds;
  set autoAdvanceSeconds(int v) {
    _autoAdvanceSeconds = v.clamp(3, 30);
    _save();
    notifyListeners();
  }

  // Speed-reading mode — larger font + tighter line height + 1 paragraph at a time
  bool _speedReading = false;
  bool get speedReading => _speedReading;
  set speedReading(bool v) {
    _speedReading = v;
    _save();
    notifyListeners();
  }
  // Words per minute target (drives auto-paragraph advance)
  int _wpm = 350;
  int get wpm => _wpm;
  set wpm(int v) {
    _wpm = v.clamp(150, 700);
    _save();
    notifyListeners();
  }

  // Confidence rating prompt — show before "View Answer" tap?
  bool _promptConfidence = true;
  bool get promptConfidence => _promptConfidence;
  set promptConfidence(bool v) {
    _promptConfidence = v;
    _save();
    notifyListeners();
  }

  // Read-aloud (TTS) auto-start when explanation opens?
  bool _ttsAutoStart = false;
  bool get ttsAutoStart => _ttsAutoStart;
  set ttsAutoStart(bool v) {
    _ttsAutoStart = v;
    _save();
    notifyListeners();
  }

  Future<void> load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    _focusMode = p.getBool('mcq_focus_mode') ?? false;
    _autoAdvance = p.getBool('mcq_auto_advance') ?? false;
    _autoAdvanceSeconds = p.getInt('mcq_auto_advance_secs') ?? 8;
    _speedReading = p.getBool('mcq_speed_reading') ?? false;
    _wpm = p.getInt('mcq_speed_wpm') ?? 350;
    _promptConfidence = p.getBool('mcq_prompt_confidence') ?? true;
    _ttsAutoStart = p.getBool('mcq_tts_auto_start') ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('mcq_focus_mode', _focusMode);
    await p.setBool('mcq_auto_advance', _autoAdvance);
    await p.setInt('mcq_auto_advance_secs', _autoAdvanceSeconds);
    await p.setBool('mcq_speed_reading', _speedReading);
    await p.setInt('mcq_speed_wpm', _wpm);
    await p.setBool('mcq_prompt_confidence', _promptConfidence);
    await p.setBool('mcq_tts_auto_start', _ttsAutoStart);
  }
}
