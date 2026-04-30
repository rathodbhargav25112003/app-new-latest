// CortexBubble — single message bubble in a Cortex chat.
//
// Renders user / assistant messages with markdown support, action row
// (snippet save, copy, rate, generate flashcards), and follow-up chips.
// Shows a typing indicator (... animation) when streaming and content
// is still empty.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../models/cortex_models.dart';
import '../cortex_colors.dart';

class CortexBubble extends StatelessWidget {
  final CortexMessage message;
  final bool isStreaming;
  final VoidCallback? onSnippetToggle;
  final VoidCallback? onFlashcards;
  final void Function(String prompt)? onFollowupTap;

  const CortexBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.onSnippetToggle,
    this.onFlashcards,
    this.onFollowupTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final isErrorBubble = (message.error ?? '').isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleBg = isUser
        ? primaryColor.withOpacity(0.10)
        : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100);
    final borderColor = isUser
        ? primaryColor.withOpacity(0.30)
        : (isDark ? Colors.white.withOpacity(0.10) : Colors.grey.shade300);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
            decoration: BoxDecoration(
              color: bubbleBg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isUser ? 14 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 14),
              ),
              border: Border.all(color: borderColor, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Text('🤖', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          'Cortex AI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                        if (message.model != null && message.model!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '· ${_shortModel(message.model!)}',
                            style: TextStyle(
                              fontSize: 9,
                              color: scheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                // Body — markdown for assistant, plain text for user.
                if (isUser)
                  Text(
                    message.content,
                    style: TextStyle(fontSize: 14, height: 1.45, color: scheme.onSurface),
                  )
                else if (isStreaming && message.content.isEmpty)
                  _TypingIndicator(color: scheme.onSurface.withOpacity(0.5))
                else
                  MarkdownBody(
                    data: message.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: TextStyle(fontSize: 14, height: 1.5, color: scheme.onSurface),
                      h1: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: scheme.onSurface),
                      h2: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.onSurface),
                      h3: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: scheme.onSurface),
                      strong: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
                      blockquote: TextStyle(
                        color: scheme.onSurface.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                      tableHead: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
                      tableBody: TextStyle(fontSize: 12, color: scheme.onSurface),
                      code: TextStyle(
                        fontFamily: 'monospace',
                        backgroundColor: isDark ? Colors.black26 : Colors.grey.shade200,
                        fontSize: 12,
                      ),
                    ),
                  ),

                // Image attachments
                if (message.images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...message.images.take(4).map((img) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            img,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      )),
                ],
              ],
            ),
          ),

          // Action row — only on completed assistant messages
          if (!isUser && !isStreaming && !isErrorBubble && message.id.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Row(
                children: [
                  _IconAction(
                    icon: message.savedSnippet ? Icons.bookmark : Icons.bookmark_border,
                    color: message.savedSnippet ? primaryColor : null,
                    tooltip: message.savedSnippet ? 'Saved' : 'Save snippet',
                    onTap: onSnippetToggle,
                  ),
                  _IconAction(
                    icon: Icons.copy_outlined,
                    tooltip: 'Copy',
                    onTap: () => Clipboard.setData(ClipboardData(text: message.content)),
                  ),
                  if (onFlashcards != null)
                    _IconAction(
                      icon: Icons.style_outlined,
                      tooltip: 'Generate flashcards',
                      onTap: onFlashcards,
                    ),
                ],
              ),
            ),

          // Follow-up chips (when present + not streaming)
          if (!isUser && !isStreaming && message.suggestedFollowups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: message.suggestedFollowups
                    .map((f) => InkWell(
                          onTap: () => onFollowupTap?.call(f),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: primaryColor.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(14),
                              color: primaryColor.withOpacity(0.05),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_forward, size: 12, color: primaryColor),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 240),
                                  child: Text(
                                    f,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _shortModel(String fullModel) {
    if (fullModel.contains('claude-opus')) return 'Claude Opus';
    if (fullModel.contains('claude-sonnet')) return 'Claude Sonnet';
    if (fullModel.contains('claude-haiku')) return 'Claude Haiku';
    if (fullModel.contains('gpt-4.1-mini')) return 'GPT-4.1 mini';
    if (fullModel.contains('gpt-4.1')) return 'GPT-4.1';
    return fullModel;
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;
  const _IconAction({required this.icon, required this.tooltip, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final Color color;
  const _TypingIndicator({required this.color});
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final phase = (_ctrl.value * 3).floor();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final active = i == phase;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(active ? 1.0 : 0.3),
              ),
            );
          }),
        );
      },
    );
  }
}
