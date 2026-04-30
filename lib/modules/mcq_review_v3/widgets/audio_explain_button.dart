// AudioExplainButton — generates a Cortex-written audio script + speaks
// it via OS-native TTS (flutter_tts). Single button: tap → fetch script
// → start speaking; tap again → stop.
//
// Adds `flutter_tts` to pubspec required (install + pub get):
//   flutter_tts: ^4.2.0
//
// Until that's installed, this widget falls back to "show as text" mode —
// i.e., it pulls the script from the server and displays it in a sheet.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../mcq_review_service.dart';

class AudioExplainButton extends StatefulWidget {
  final String questionText;
  final List<dynamic> options;
  final String correctOption;
  final String? briefExplanation;

  const AudioExplainButton({
    super.key,
    required this.questionText,
    required this.options,
    required this.correctOption,
    this.briefExplanation,
  });

  @override
  State<AudioExplainButton> createState() => _AudioExplainButtonState();
}

class _AudioExplainButtonState extends State<AudioExplainButton> {
  bool _busy = false;

  Future<void> _go() async {
    setState(() => _busy = true);
    try {
      final res = await McqReviewService().audioExplain(
        questionText: widget.questionText,
        options: widget.options,
        correctOption: widget.correctOption,
        briefExplanation: widget.briefExplanation,
      );
      final script = (res['script'] ?? '').toString();
      if (!mounted) return;
      if (script.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio script generation failed')),
        );
      } else {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _AudioPlaybackSheet(script: script, estimatedSeconds: res['estimated_seconds'] ?? 0),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _busy ? null : _go,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.06),
          border: Border.all(color: Colors.teal.withOpacity(0.30)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _busy
                ? const SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                  )
                : const Icon(Icons.headphones_outlined, size: 14, color: Colors.teal),
            const SizedBox(width: 4),
            const Text('Listen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.teal)),
          ],
        ),
      ),
    );
  }
}

// Playback sheet — shows the script + a play/pause control. Uses
// flutter_tts when installed; falls back to text-only display.
class _AudioPlaybackSheet extends StatefulWidget {
  final String script;
  final int estimatedSeconds;
  const _AudioPlaybackSheet({required this.script, required this.estimatedSeconds});
  @override
  State<_AudioPlaybackSheet> createState() => _AudioPlaybackSheetState();
}

class _AudioPlaybackSheetState extends State<_AudioPlaybackSheet> {
  // ── flutter_tts integration ──
  // To enable real TTS, add `flutter_tts: ^4.2.0` to pubspec.yaml,
  // run `flutter pub get`, then uncomment the relevant lines below.
  //
  // import 'package:flutter_tts/flutter_tts.dart';
  // final FlutterTts _tts = FlutterTts();
  // bool _isPlaying = false;
  //
  // Future<void> _start() async {
  //   await _tts.setLanguage('en-IN');
  //   await _tts.setSpeechRate(0.5);
  //   await _tts.speak(widget.script);
  //   setState(() => _isPlaying = true);
  //   _tts.setCompletionHandler(() {
  //     if (mounted) setState(() => _isPlaying = false);
  //   });
  // }
  //
  // Future<void> _stop() async {
  //   await _tts.stop();
  //   if (mounted) setState(() => _isPlaying = false);
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.headphones, color: Colors.teal),
            const SizedBox(width: 8),
            const Text('Listen', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const Spacer(),
            Text('~${widget.estimatedSeconds}s',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(width: 8),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: widget.script,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 12, color: Colors.amber),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Add flutter_tts to pubspec for native voice playback. Until then this shows the script.',
                  style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
