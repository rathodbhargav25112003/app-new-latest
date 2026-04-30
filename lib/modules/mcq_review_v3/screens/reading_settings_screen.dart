// ReadingSettingsScreen — student-facing toggles for the reading-prefs
// (focus mode, auto-advance, speed-reading, confidence prompt, TTS auto-start).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../reading_prefs.dart';

class ReadingSettingsScreen extends StatefulWidget {
  const ReadingSettingsScreen({super.key});
  static Route<dynamic> route(RouteSettings settings) =>
      CupertinoPageRoute(builder: (_) => const ReadingSettingsScreen());
  @override
  State<ReadingSettingsScreen> createState() => _ReadingSettingsScreenState();
}

class _ReadingSettingsScreenState extends State<ReadingSettingsScreen> {
  @override
  void initState() {
    super.initState();
    ReadingPrefs.I.load().then((_) { if (mounted) setState(() {}); });
  }

  @override
  Widget build(BuildContext context) {
    final p = ReadingPrefs.I;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Reading & study preferences'),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel('🧘 Focus & flow'),
          SwitchListTile.adaptive(
            title: const Text('Focus mode'),
            subtitle: const Text('Hide top bar + nav · full-screen MCQ', style: TextStyle(fontSize: 11)),
            value: p.focusMode,
            onChanged: (v) => setState(() => p.focusMode = v),
          ),
          SwitchListTile.adaptive(
            title: const Text('Auto-advance after answer'),
            subtitle: Text(
              'After viewing answer for ${p.autoAdvanceSeconds}s, auto-jump to next Q',
              style: const TextStyle(fontSize: 11),
            ),
            value: p.autoAdvance,
            onChanged: (v) => setState(() => p.autoAdvance = v),
          ),
          if (p.autoAdvance)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Slider(
                value: p.autoAdvanceSeconds.toDouble(),
                min: 3, max: 30, divisions: 27,
                label: '${p.autoAdvanceSeconds}s',
                onChanged: (v) => setState(() => p.autoAdvanceSeconds = v.toInt()),
              ),
            ),
          const SizedBox(height: 8),

          _SectionLabel('⚡ Speed reading'),
          SwitchListTile.adaptive(
            title: const Text('Speed-reading mode'),
            subtitle: Text(
              'Larger font · auto-paced at ${p.wpm} WPM',
              style: const TextStyle(fontSize: 11),
            ),
            value: p.speedReading,
            onChanged: (v) => setState(() => p.speedReading = v),
          ),
          if (p.speedReading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Slider(
                value: p.wpm.toDouble(),
                min: 150, max: 700, divisions: 22,
                label: '${p.wpm} WPM',
                onChanged: (v) => setState(() => p.wpm = v.toInt()),
              ),
            ),

          const SizedBox(height: 8),
          _SectionLabel('🧠 Metacognition'),
          SwitchListTile.adaptive(
            title: const Text('Prompt for confidence before reveal'),
            subtitle: const Text('Captures pre-reveal confidence for calibration analytics', style: TextStyle(fontSize: 11)),
            value: p.promptConfidence,
            onChanged: (v) => setState(() => p.promptConfidence = v),
          ),

          const SizedBox(height: 8),
          _SectionLabel('🔊 Audio'),
          SwitchListTile.adaptive(
            title: const Text('Auto-start TTS on explanation open'),
            subtitle: const Text('Reads the explanation aloud when answer is revealed', style: TextStyle(fontSize: 11)),
            value: p.ttsAutoStart,
            onChanged: (v) => setState(() => p.ttsAutoStart = v),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85))),
    );
  }
}
