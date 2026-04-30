import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ReadingPreferencesService — persists the user's PDF reader UI
/// preferences across sessions. Lets the reader respect:
///   • Sepia/light/dark/auto background
///   • Brightness override (within the reader window)
///   • Reading-mode font scale
///   • "Stay awake while reading" lock
///
/// Backed by SharedPreferences. Exposes a simple [ChangeNotifier]
/// so screens that need to react (the reader chrome, the settings
/// sub-screen) can listen.
class ReadingPreferencesService extends ChangeNotifier {
  ReadingPreferencesService._();
  static final instance = ReadingPreferencesService._();

  static const _kBackground = 'reader_bg_v1';
  static const _kBrightness = 'reader_brightness_v1';
  static const _kFontScale = 'reader_font_scale_v1';
  static const _kKeepAwake = 'reader_keep_awake_v1';
  static const _kFitWidth = 'reader_fit_width_v1';

  ReaderBackground _background = ReaderBackground.system;
  double _brightnessOverride = -1.0; // -1 = follow system
  double _fontScale = 1.0;
  bool _keepAwake = true;
  bool _fitWidth = true;
  bool _loaded = false;

  ReaderBackground get background => _background;
  double get brightnessOverride => _brightnessOverride;
  double get fontScale => _fontScale;
  bool get keepAwake => _keepAwake;
  bool get fitWidth => _fitWidth;
  bool get loaded => _loaded;

  /// Returns the page-fill color for the current background mode.
  /// Plumb this into the PDF viewer's chrome (the canvas behind the
  /// rendered page).
  Color paperColor() {
    switch (_background) {
      case ReaderBackground.sepia:
        return const Color(0xFFFAF1E4);
      case ReaderBackground.dark:
        return const Color(0xFF111319);
      case ReaderBackground.light:
        return const Color(0xFFFFFFFF);
      case ReaderBackground.system:
      // ignore: unreachable_switch_default
      default:
        // Caller should detect platform brightness.
        return const Color(0xFFFFFFFF);
    }
  }

  /// Ink color matching the current paper.
  Color inkColor() {
    switch (_background) {
      case ReaderBackground.sepia:
        return const Color(0xFF40342B);
      case ReaderBackground.dark:
        return const Color(0xFFE8E8EE);
      case ReaderBackground.light:
        return const Color(0xFF0A0D14);
      case ReaderBackground.system:
      // ignore: unreachable_switch_default
      default:
        return const Color(0xFF0A0D14);
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _background = ReaderBackground.values[
        (prefs.getInt(_kBackground) ?? ReaderBackground.system.index)
            .clamp(0, ReaderBackground.values.length - 1)];
    _brightnessOverride = prefs.getDouble(_kBrightness) ?? -1.0;
    _fontScale = prefs.getDouble(_kFontScale) ?? 1.0;
    _keepAwake = prefs.getBool(_kKeepAwake) ?? true;
    _fitWidth = prefs.getBool(_kFitWidth) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setBackground(ReaderBackground b) async {
    if (_background == b) return;
    _background = b;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kBackground, b.index);
  }

  Future<void> setBrightnessOverride(double value) async {
    final clamped = value.clamp(-1.0, 1.0);
    _brightnessOverride = clamped;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kBrightness, clamped);
  }

  Future<void> setFontScale(double scale) async {
    final clamped = scale.clamp(0.7, 1.6);
    if (_fontScale == clamped) return;
    _fontScale = clamped;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFontScale, clamped);
  }

  Future<void> setKeepAwake(bool value) async {
    if (_keepAwake == value) return;
    _keepAwake = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKeepAwake, value);
  }

  Future<void> setFitWidth(bool value) async {
    if (_fitWidth == value) return;
    _fitWidth = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFitWidth, value);
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBackground);
    await prefs.remove(_kBrightness);
    await prefs.remove(_kFontScale);
    await prefs.remove(_kKeepAwake);
    await prefs.remove(_kFitWidth);
    _background = ReaderBackground.system;
    _brightnessOverride = -1.0;
    _fontScale = 1.0;
    _keepAwake = true;
    _fitWidth = true;
    notifyListeners();
  }
}

/// Background tone for the PDF reader.
enum ReaderBackground { system, light, sepia, dark }

extension ReaderBackgroundLabel on ReaderBackground {
  String get label {
    switch (this) {
      case ReaderBackground.system:
        return 'Auto';
      case ReaderBackground.light:
        return 'Light';
      case ReaderBackground.sepia:
        return 'Sepia';
      case ReaderBackground.dark:
        return 'Dark';
    }
  }
}
