// ════════════════════════════════════════════════════════════════════
// DoubtChatSheet — multi-turn Claude chat scoped to one question
// ════════════════════════════════════════════════════════════════════
//
// Bottom sheet UI that wraps GET /api/doubt-chat/:question_id and
// POST /api/doubt-chat/:question_id/message. Shows the running
// transcript, sends new messages, and streams replies as they arrive.
//
// Usage:
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     builder: (_) => DoubtChatSheet(questionId: q.id, userExamId: a.id),
//   );

import 'package:flutter/material.dart';
import '../../../api_service/exam_analytics_api.dart';

class DoubtChatSheet extends StatefulWidget {
  final String questionId;
  final String? userExamId;
  final ExamAnalyticsApi? api;
  const DoubtChatSheet({
    super.key,
    required this.questionId,
    this.userExamId,
    this.api,
  });

  @override
  State<DoubtChatSheet> createState() => _DoubtChatSheetState();
}

class _DoubtChatSheetState extends State<DoubtChatSheet> {
  late final ExamAnalyticsApi _api = widget.api ?? ExamAnalyticsApi();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<DoubtChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final t = await _api.openDoubtChat(widget.questionId, userExamId: widget.userExamId);
      if (!mounted) return;
      setState(() {
        _messages = t.messages;
        _loading = false;
      });
      _scrollToEnd();
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = '$e'; });
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _messages = [..._messages, DoubtChatMessage(role: 'user', text: text)];
    });
    _input.clear();
    _scrollToEnd();
    try {
      final t = await _api.sendDoubtMessage(widget.questionId, text, userExamId: widget.userExamId);
      if (!mounted) return;
      setState(() {
        _messages = t.messages;
        _sending = false;
      });
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = '$e';
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final mediaInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: mediaInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.psychology_alt, color: cs.primary),
                  const SizedBox(width: 8),
                  Text('Ask a follow-up',
                      style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Ask anything about this question — what the correct answer means, why a distractor is wrong, the underlying concept.',
                              textAlign: TextAlign.center,
                              style: t.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (ctx, i) => _Bubble(message: _messages[i]),
                        ),
            ),
            if (_error != null)
              Container(
                color: cs.errorContainer,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Icon(Icons.error_outline, color: cs.onErrorContainer, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: t.textTheme.bodySmall?.copyWith(color: cs.onErrorContainer))),
                ]),
              ),

            // Composer
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: 'Type a question…',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send, size: 18),
                      label: const Text('Send'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final DoubtChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.primary.withValues(alpha: 0.15),
              child: Icon(Icons.auto_awesome, size: 14, color: cs.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message.text,
                style: t.textTheme.bodyMedium?.copyWith(
                  color: isUser ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
