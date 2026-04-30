// CortexChatScreen — active multi-turn chat viewer.
//
// Shows the message history for a single CortexChat, supports:
//   • Streaming replies (via SSE) with typing indicator
//   • Snippet save / copy / flashcard generation per message
//   • Follow-up chip taps that auto-send the chip text
//   • Daily-cap awareness (shows banner + disables composer when over cap)
//   • PopupMenu: pin / archive / rename / export / summarize / delete
//
// Used by every chat surface — general, MCQ-anchored, mistake debrief,
// roleplay, OSCE viva, topic deep-dive — they're all just chats with
// different `context_kind`.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../models/cortex_models.dart';
import 'cortex_colors.dart';
import 'cortex_service.dart';
import 'store/cortex_store.dart';
import 'widgets/cortex_bubble.dart';
import 'widgets/cortex_usage_badge.dart';

class CortexChatScreen extends StatefulWidget {
  final String chatId;
  final CortexChat? initialChat;

  const CortexChatScreen({super.key, required this.chatId, this.initialChat});

  static Route<dynamic> route(RouteSettings settings) {
    final args = (settings.arguments ?? {}) as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => CortexChatScreen(
        chatId: args['chat_id'] as String,
        initialChat: args['initial_chat'] as CortexChat?,
      ),
    );
  }

  static Route<dynamic> routeForChat(CortexChat chat) {
    return CupertinoPageRoute(builder: (_) => CortexChatScreen(chatId: chat.id, initialChat: chat));
  }

  @override
  State<CortexChatScreen> createState() => _CortexChatScreenState();
}

class _CortexChatScreenState extends State<CortexChatScreen> {
  final _composerCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    final store = Provider.of<CortexStore>(context, listen: false);
    store.openChat(widget.chatId);
  }

  @override
  void dispose() {
    _composerCtrl.dispose();
    _scrollCtrl.dispose();
    final store = Provider.of<CortexStore>(context, listen: false);
    store.closeActiveChat();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String content, {List<String>? images}) async {
    if (content.trim().isEmpty) return;
    final store = Provider.of<CortexStore>(context, listen: false);
    try {
      await store.sendMessageStreaming(content.trim(), images: images);
      _scrollToBottom();
    } catch (e) {
      if (e is CortexApiException && e.isRateLimit) {
        _showRateLimit(e.message);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Send failed: $e')),
        );
      }
    }
  }

  void _showRateLimit(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Daily limit reached'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<CortexStore>(context, listen: false);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _Header(initialChat: widget.initialChat),

            // Messages list
            Expanded(
              child: Observer(builder: (_) {
                if (store.chatLoading.value && store.activeMessages.isEmpty) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (store.activeMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 36, color: primaryColor.withOpacity(0.6)),
                        const SizedBox(height: 8),
                        Text('Start chatting',
                            style: TextStyle(color: scheme.onSurface.withOpacity(0.5), fontSize: 14)),
                      ],
                    ),
                  );
                }
                // Auto-scroll on new messages
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: store.activeMessages.length,
                  itemBuilder: (_, i) {
                    final m = store.activeMessages[i];
                    final isStreamingThis = store.streamingMessageId.value == m.id;
                    return CortexBubble(
                      message: m,
                      isStreaming: isStreamingThis,
                      onSnippetToggle: m.id.startsWith('__tmp')
                          ? null
                          : () async {
                              final saved = await store.toggleSnippet(m.id, save: !m.savedSnippet);
                              if (mounted && saved) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Saved to snippets'), duration: Duration(seconds: 1)),
                                );
                              }
                            },
                      onFlashcards: m.id.startsWith('__tmp')
                          ? null
                          : () => _generateFlashcards(m),
                      onFollowupTap: (prompt) {
                        _composerCtrl.text = prompt;
                        _send(prompt);
                      },
                    );
                  },
                );
              }),
            ),

            // Composer
            _Composer(
              controller: _composerCtrl,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateFlashcards(CortexMessage m) async {
    final store = Provider.of<CortexStore>(context, listen: false);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating flashcards…'), duration: Duration(seconds: 2)),
      );
      final cards = await store.service.generateFlashcards(m.id, count: 5);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _FlashcardsSheet(cards: cards),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flashcard generation failed: $e')),
        );
      }
    }
  }
}

// ── Header ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final CortexChat? initialChat;
  const _Header({this.initialChat});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<CortexStore>(context, listen: false);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outline.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Observer(builder: (_) {
              final chat = store.activeChat.value ?? initialChat;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat?.title ?? 'Cortex AI',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: scheme.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _contextLabel(chat?.contextKind ?? 'general'),
                    style: TextStyle(fontSize: 10, color: scheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              );
            }),
          ),
          const CortexUsageBadge(compact: true),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: scheme.onSurface.withOpacity(0.6)),
            onSelected: (v) async {
              final chat = store.activeChat.value;
              if (chat == null) return;
              switch (v) {
                case 'pin':
                  await store.patchChat(chat.id, pinned: !chat.pinned);
                  break;
                case 'archive':
                  await store.patchChat(chat.id, archived: !chat.archived);
                  if (context.mounted) Navigator.pop(context);
                  break;
                case 'rename':
                  final newTitle = await _promptText(context, 'Rename chat', initial: chat.title);
                  if (newTitle != null && newTitle.isNotEmpty) {
                    await store.patchChat(chat.id, title: newTitle);
                  }
                  break;
                case 'summarize':
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Summarizing chat…')));
                  await store.service.summarizeChat(chat.id);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Summary saved')));
                  break;
                case 'export':
                  final md = await store.service.exportChat(chat.id);
                  await Clipboard.setData(ClipboardData(text: md));
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Markdown copied to clipboard')));
                  break;
                case 'delete':
                  final ok = await _confirm(context, 'Delete this chat?');
                  if (ok) {
                    await store.deleteChat(chat.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pin', child: Row(children: [Icon(Icons.push_pin_outlined, size: 16), SizedBox(width: 8), Text('Pin / unpin')])),
              PopupMenuItem(value: 'archive', child: Row(children: [Icon(Icons.archive_outlined, size: 16), SizedBox(width: 8), Text('Archive')])),
              PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Rename')])),
              PopupMenuItem(value: 'summarize', child: Row(children: [Icon(Icons.summarize_outlined, size: 16), SizedBox(width: 8), Text('Summarize')])),
              PopupMenuItem(value: 'export', child: Row(children: [Icon(Icons.download_outlined, size: 16), SizedBox(width: 8), Text('Export markdown')])),
              PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
    );
  }

  String _contextLabel(String kind) {
    switch (kind) {
      case 'mcq': return 'MCQ chat';
      case 'mistake_debrief': return '🤔 Mistake debrief';
      case 'roleplay': return '🎭 Patient roleplay';
      case 'osce_viva': return '🩺 OSCE viva';
      case 'topic_deep_dive': return '🔍 Deep dive';
      default: return 'General';
    }
  }
}

// ── Composer ───────────────────────────────────────────────────────────

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSend;

  const _Composer({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<CortexStore>(context, listen: false);
    final scheme = Theme.of(context).colorScheme;
    return Observer(builder: (_) {
      final isSending = store.sending.value;
      final usage = store.usage.value;
      final atCap = usage.remaining <= 0;
      return Container(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outline.withOpacity(0.1))),
        ),
        child: atCap
            ? Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "You've used all your Cortex AI messages today. Resets at midnight.",
                      style: TextStyle(fontSize: 11, color: Colors.red),
                    ),
                  ),
                ]),
              )
            : Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: !isSending,
                      minLines: 1,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: isSending ? 'Cortex is replying…' : 'Type your message…',
                        hintStyle: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.5)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: scheme.outline.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: scheme.outline.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                      ),
                      onSubmitted: (v) {
                        if (v.trim().isEmpty) return;
                        onSend(v.trim());
                        controller.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: isSending
                        ? null
                        : () {
                            final v = controller.text.trim();
                            if (v.isEmpty) return;
                            onSend(v);
                            controller.clear();
                          },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSending ? scheme.outline.withOpacity(0.3) : primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: isSending
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
      );
    });
  }
}

// ── Flashcards bottom sheet ─────────────────────────────────────────────

class _FlashcardsSheet extends StatelessWidget {
  final List<CortexFlashcard> cards;
  const _FlashcardsSheet({required this.cards});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.style, color: primaryColor),
            const SizedBox(width: 8),
            Text('Flashcards · ${cards.length}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: cards.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (_, i) {
                final c = cards[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Q${i + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: primaryColor)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _diffColor(c.difficulty).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(c.difficulty, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _diffColor(c.difficulty))),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(c.question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(c.answer, style: const TextStyle(fontSize: 12, height: 1.4)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved to your flashcard deck'), duration: Duration(seconds: 2)),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add all to my deck'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Color _diffColor(String d) {
    switch (d) { case 'easy': return Colors.green; case 'hard': return Colors.red; default: return Colors.orange; }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────

Future<String?> _promptText(BuildContext context, String title, {String initial = ''}) async {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctrl, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Save')),
      ],
    ),
  );
}

Future<bool> _confirm(BuildContext context, String message) async {
  return (await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm', style: TextStyle(color: Colors.red))),
          ],
        ),
      )) ??
      false;
}
