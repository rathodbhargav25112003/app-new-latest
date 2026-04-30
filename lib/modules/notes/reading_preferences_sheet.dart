import 'package:flutter/material.dart';

import '../../helpers/app_tokens.dart';
import '../../helpers/haptics.dart';
import '../../services/reading_preferences_service.dart';

/// ReadingPreferencesSheet — Apple-style modal that the PDF reader's
/// toolbar opens to let the user adjust the reading look-and-feel.
///
/// Controls:
///  • Background tone (Auto / Light / Sepia / Dark)
///  • Brightness slider (per-reader override)
///  • Keep awake toggle
///  • Fit width toggle
///  • Reset all
///
/// Persists via [ReadingPreferencesService] — listeners (the reader
/// chrome itself) react in real time.
class ReadingPreferencesSheet {
  ReadingPreferencesSheet._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => const _Sheet(),
    );
  }
}

class _Sheet extends StatefulWidget {
  const _Sheet();

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  final svc = ReadingPreferencesService.instance;

  @override
  void initState() {
    super.initState();
    svc.addListener(_onChange);
    if (!svc.loaded) {
      // ignore: discarded_futures
      svc.load();
    }
  }

  @override
  void dispose() {
    svc.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTokens.r28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTokens.s16, AppTokens.s12, AppTokens.s16, AppTokens.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.border(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s16),
              Text('Reading preferences',
                  style: AppTokens.titleLg(context)),
              const SizedBox(height: AppTokens.s4),
              Text(
                'Tweak the reader to match your eyes.',
                style: AppTokens.body(context),
              ),
              const SizedBox(height: AppTokens.s20),
              _label('Background'),
              const SizedBox(height: AppTokens.s8),
              _backgroundSegment(),
              const SizedBox(height: AppTokens.s20),
              _label('Brightness'),
              const SizedBox(height: AppTokens.s8),
              _brightnessRow(),
              const SizedBox(height: AppTokens.s20),
              _label('Behavior'),
              const SizedBox(height: AppTokens.s8),
              _toggleRow(
                icon: Icons.lock_clock_outlined,
                label: 'Keep screen awake',
                subtitle:
                    'Screen stays on while reading; turns off when you leave.',
                value: svc.keepAwake,
                onChanged: (v) {
                  Haptics.medium();
                  svc.setKeepAwake(v);
                },
              ),
              _toggleRow(
                icon: Icons.aspect_ratio_rounded,
                label: 'Fit to width',
                subtitle: 'Auto-zoom each page so text fills the screen.',
                value: svc.fitWidth,
                onChanged: (v) {
                  Haptics.medium();
                  svc.setFitWidth(v);
                },
              ),
              const SizedBox(height: AppTokens.s12),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Haptics.medium();
                    svc.resetAll();
                  },
                  icon: Icon(Icons.refresh_rounded,
                      size: 16, color: AppTokens.muted(context)),
                  label: Text(
                    'Reset to defaults',
                    style: AppTokens.titleSm(context).copyWith(
                      color: AppTokens.muted(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: AppTokens.overline(context),
      );

  Widget _backgroundSegment() {
    final modes = ReaderBackground.values;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: AppTokens.radius12,
      ),
      child: Row(
        children: modes.map((m) {
          final isActive = svc.background == m;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                Haptics.selection();
                svc.setBackground(m);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTokens.surface(context)
                      : Colors.transparent,
                  borderRadius: AppTokens.radius8,
                  boxShadow:
                      isActive ? AppTokens.shadow1(context) : null,
                ),
                child: Text(
                  m.label,
                  style: AppTokens.titleSm(context).copyWith(
                    color: isActive
                        ? AppTokens.ink(context)
                        : AppTokens.muted(context),
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _brightnessRow() {
    final v = svc.brightnessOverride;
    final usingSystem = v < 0;
    final displayed = usingSystem ? 0.5 : (v + 1) / 2; // -1..1 → 0..1
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12, vertical: AppTokens.s8),
      decoration: BoxDecoration(
        color: AppTokens.surface2(context),
        borderRadius: AppTokens.radius12,
      ),
      child: Row(
        children: [
          Icon(Icons.brightness_4_outlined,
              size: 18, color: AppTokens.muted(context)),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: AppTokens.accent(context),
                inactiveTrackColor: AppTokens.surface3(context),
                thumbColor: AppTokens.accent(context),
                overlayShape: SliderComponentShape.noOverlay,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: displayed.clamp(0.0, 1.0),
                onChanged: (raw) {
                  // Map 0..1 → -1..1.
                  final mapped = raw * 2 - 1;
                  svc.setBrightnessOverride(mapped);
                },
              ),
            ),
          ),
          IconButton(
            tooltip: 'Use system brightness',
            icon: Icon(
              usingSystem
                  ? Icons.lock_open_rounded
                  : Icons.lock_outline_rounded,
              size: 18,
              color: usingSystem
                  ? AppTokens.muted(context)
                  : AppTokens.accent(context),
            ),
            onPressed: () {
              Haptics.medium();
              svc.setBrightnessOverride(usingSystem ? 0.0 : -1.0);
            },
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              borderRadius: AppTokens.radius8,
            ),
            child:
                Icon(icon, color: AppTokens.accent(context), size: 18),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTokens.titleSm(context)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTokens.caption(context)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTokens.accent(context),
          ),
        ],
      ),
    );
  }
}
