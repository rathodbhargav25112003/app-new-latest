// MistakeDebriefSheet — modal bottom sheet shown after a wrong MCQ.
//
// Calls POST /api/cortex/mistake-debrief with streaming, renders the AI's
// 5-section diagnostic in real time, and offers a "Continue chat" button
// that opens the underlying CortexChat for follow-up drilldowns.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../cortex_chat_screen.dart';
import '../cortex_colors.dart';
import '../cortex_service.dart';
import '../store/cortex_store.dart';

class MistakeDebriefSheet extends StatefulWidget {
  final String questionId;
  final String selectedOption;
  final String? correctOption;
  final String? examId;
  final String? userExamId;
  final String examType; // 'regular' | 'mock'

  const MistakeDebriefSheet({
    super.key,
    required this.questionId,
    required this.selectedOption,
    this.correctOption,
    this.examId,
    this.userExamId,
    this.examType = 'regular',
  });

  /// Helper — show as a bottom sheet from anywhere.
  static Future<void> show(BuildContext context, {
    required String questionId,
    required String selectedOption,
    String? correctOption,
    String? examId,
    String? userExamId,
    String examType = 'regular',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: MistakeDebriefSheet(
            questionId: questionId,
            selectedOption: selectedOption,
            correctOption: correctOption,
            examId: examId,
            userExamId: userExamId,
            examType: examType,
          ),
        ),
      ),
    );
  }

  @override
  State<MistakeDebriefSheet> createState() => _MistakeDebriefSheetState();
}

class _MistakeDebriefSheetState extends State<MistakeDebriefSheet> {
  final _service = CortexService();
  String _content = '';
  String? _chatId;
  bool _streaming = true;
  bool _errorState = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    _service.streamMistakeDebrief(
      questionId: widget.questionId,
      selectedOption: widget.selectedOption,
      correctOption: widget.correctOption,
      examId: widget.examId,
      userExamId: widget.userExamId,
      examType: widget.examType,
    ).listen((ev) {
      if (!mounted) return;
      if (ev is CortexDelta) {
        setState(() => _content += ev.text);
      } else if (ev is CortexMeta) {
        setState(() => _chatId = ev.chatId);
      } else if (ev is CortexError) {
        setState(() {
          _errorState = true;
          _errorMsg = ev.message;
          _streaming = false;
        });
      }
    }, onDone: () {
      if (!mounted) return;
      setState(() => _streaming = false);
      // Refresh usage badge after debrief completes
      try {
        final store = Provider.of<CortexStore>(context, listen: false);
        store.refreshUsage();
      } catch (_) {}
    }, onError: (e) {
      if (!mounted) return;
      setState(() {
        _errorState = true;
        _errorMsg = e.toString();
        _streaming = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
            ),
            const SizedBox(width: 8),
            Text('Mistake Debrief',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: scheme.onSurface)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'You: ${widget.selectedOption} → Correct: ${widget.correctOption ?? "?"}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: _errorState
                  ? _ErrorView(message: _errorMsg ?? 'Failed', onRetry: () { setState(() { _errorState = false; _streaming = true; _content = ''; }); _start(); })
                  : _content.isEmpty && _streaming
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        )
                      : MarkdownBody(
                          data: _content,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                            p: TextStyle(fontSize: 13, height: 1.5, color: scheme.onSurface),
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 12),
          if (_chatId != null && !_streaming)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    CortexChatScreen.route(RouteSettings(arguments: {'chat_id': _chatId!})),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('Continue chat — drill down'),
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 36),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ],
      ),
    );
  }
}
