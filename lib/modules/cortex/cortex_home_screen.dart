// CortexHomeScreen — replaces the legacy AskQuestionScreen as the
// "Ask Cortex.ai" tab landing page. Three sections:
//   1. Header: Cortex AI branding + usage badge + entry to memory/snippets
//   2. Quick prompts + mode tiles (server-driven via /quick-prompts)
//   3. Chat history list (pinned / archived filter; tap to resume)
//
// "New chat" composer at bottom — one-tap new chat with first message.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../models/cortex_models.dart';
import 'cortex_chat_screen.dart';
import 'cortex_colors.dart';
import 'cortex_memory_screen.dart';
import 'cortex_snippets_screen.dart';
import 'store/cortex_store.dart';
import 'widgets/cortex_usage_badge.dart';

class CortexHomeScreen extends StatefulWidget {
  const CortexHomeScreen({super.key});

  static Route<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(builder: (_) => const CortexHomeScreen());
  }

  @override
  State<CortexHomeScreen> createState() => _CortexHomeScreenState();
}

class _CortexHomeScreenState extends State<CortexHomeScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    final store = Provider.of<CortexStore>(context, listen: false);
    store.refreshUsage();
    store.loadChats(contextKind: null);
    store.loadQuickPrompts(contextKind: 'general');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startGeneralChat(String firstMessage) async {
    final store = Provider.of<CortexStore>(context, listen: false);
    final chat = await store.startChat(contextKind: 'general', firstMessage: firstMessage);
    if (chat != null && mounted) {
      Navigator.of(context).push(CortexChatScreen.routeForChat(chat));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = Provider.of<CortexStore>(context, listen: false);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cortex AI',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            )),
                        Text('Your NEET SS surgical tutor',
                            style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.55))),
                      ],
                    ),
                  ),
                  const CortexUsageBadge(),
                  IconButton(
                    icon: Icon(Icons.search, size: 20, color: scheme.onSurface.withOpacity(0.7)),
                    onPressed: () => setState(() => _showSearch = !_showSearch),
                    tooltip: 'Search chats',
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 20, color: scheme.onSurface.withOpacity(0.7)),
                    onSelected: (v) {
                      if (v == 'snippets') {
                        Navigator.of(context).push(CortexSnippetsScreen.routeNew());
                      } else if (v == 'memory') {
                        Navigator.of(context).push(CortexMemoryScreen.routeNew());
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'snippets',
                          child: Row(children: [
                            Icon(Icons.bookmark_border, size: 18),
                            SizedBox(width: 8),
                            Text('Saved snippets'),
                          ])),
                      PopupMenuItem(
                          value: 'memory',
                          child: Row(children: [
                            Icon(Icons.psychology_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Memory & settings'),
                          ])),
                    ],
                  ),
                ],
              ),
            ),

            // Search bar
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search across all your chats…',
                    hintStyle: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.5)),
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: scheme.outline.withOpacity(0.3)),
                    ),
                  ),
                  onSubmitted: (q) async {
                    if (q.trim().isEmpty) return;
                    final hits = await store.service.searchChats(q.trim());
                    if (!mounted) return;
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _SearchResultsSheet(query: q, hits: hits),
                    );
                  },
                ),
              ),

            // Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // Modes
                  _SectionHeader(label: '✨ Try a mode'),
                  const SizedBox(height: 10),
                  Observer(builder: (_) {
                    final qp = store.quickPrompts.value;
                    if (qp.modes.isEmpty) {
                      return _ModeGrid(modes: _defaultModes());
                    }
                    return _ModeGrid(modes: qp.modes);
                  }),
                  const SizedBox(height: 20),

                  // Personal — top weak topics ("Quiz me on X")
                  Observer(builder: (_) {
                    final qp = store.quickPrompts.value;
                    if (qp.personal.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(label: '🎯 For you'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: qp.personal
                              .map((p) => _PromptChip(label: p, onTap: () => _startGeneralChat(p)))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }),

                  // Suggested
                  Observer(builder: (_) {
                    final qp = store.quickPrompts.value;
                    final suggestions = qp.suggested.isEmpty ? _defaultSuggestions() : qp.suggested;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(label: '💡 Suggested prompts'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: suggestions
                              .map((p) => _PromptChip(label: p, onTap: () => _startGeneralChat(p)))
                              .toList(),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 24),

                  // Chat history
                  _SectionHeader(label: '💬 Recent chats'),
                  const SizedBox(height: 8),
                  Observer(builder: (_) {
                    if (store.chatsLoading.value && store.chats.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                            child: SizedBox(
                                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                      );
                    }
                    if (store.chats.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No chats yet — start one above ↑',
                            style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.4)),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: store.chats.map((c) => _ChatTile(chat: c)).toList(),
                    );
                  }),
                ],
              ),
            ),

            // New-chat composer
            _NewChatComposer(onSend: _startGeneralChat),
          ],
        ),
      ),
    );
  }

  List<CortexMode> _defaultModes() => [
        CortexMode(id: 'mnemonic', label: '🧠 Mnemonic', endpoint: ''),
        CortexMode(id: 'diagram', label: '📊 Diagram', endpoint: ''),
        CortexMode(id: 'roleplay', label: '🎭 Patient roleplay', endpoint: ''),
        CortexMode(id: 'osce', label: '🩺 OSCE viva', endpoint: ''),
        CortexMode(id: 'deep_dive', label: '🔍 Deep dive', endpoint: ''),
      ];

  List<String> _defaultSuggestions() => const [
        'Explain shock — types and management',
        'Make a mnemonic for branches of the celiac trunk',
        'Walk me through obstructive jaundice end-to-end',
        'High-yield NEET SS topics in upper GI',
      ];
}

// ── Helpers ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _ModeGrid extends StatelessWidget {
  final List<CortexMode> modes;
  const _ModeGrid({required this.modes});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: modes.map((m) => _ModeTile(mode: m)).toList(),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final CortexMode mode;
  const _ModeTile({required this.mode});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _onTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(0.4),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                mode.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: scheme.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    Navigator.of(context)
        .pushNamed(Routes.cortexModeStart, arguments: {'mode_id': mode.id, 'mode_label': mode.label});
  }
}

class _PromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PromptChip({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.06),
          border: Border.all(color: primaryColor.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final CortexChat chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ago = chat.lastActivityAt == null ? '' : _formatAgo(chat.lastActivityAt!);
    return InkWell(
      onTap: () => Navigator.of(context).push(CortexChatScreen.routeForChat(chat)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _ContextIcon(kind: chat.contextKind),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.title.isEmpty ? 'New chat' : chat.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onSurface),
                  ),
                  Text(
                    '${chat.totalMessages} message${chat.totalMessages == 1 ? '' : 's'} · $ago',
                    style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            if (chat.pinned) Icon(Icons.push_pin, size: 14, color: primaryColor.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  String _formatAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }
}

class _ContextIcon extends StatelessWidget {
  final String kind;
  const _ContextIcon({required this.kind});
  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.chat_bubble_outline;
    Color color = primaryColor;
    switch (kind) {
      case 'mcq':
        icon = Icons.help_outline;
        break;
      case 'mistake_debrief':
        icon = Icons.lightbulb_outline;
        color = Colors.orange;
        break;
      case 'roleplay':
        icon = Icons.theater_comedy_outlined;
        color = Colors.purple;
        break;
      case 'osce_viva':
        icon = Icons.local_hospital_outlined;
        color = Colors.teal;
        break;
      case 'topic_deep_dive':
        icon = Icons.menu_book_outlined;
        color = Colors.indigo;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _NewChatComposer extends StatefulWidget {
  final void Function(String) onSend;
  const _NewChatComposer({required this.onSend});
  @override
  State<_NewChatComposer> createState() => _NewChatComposerState();
}

class _NewChatComposerState extends State<_NewChatComposer> {
  final _ctrl = TextEditingController();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ask Cortex anything…',
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
                widget.onSend(v.trim());
                _ctrl.clear();
              },
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              final v = _ctrl.text.trim();
              if (v.isEmpty) return;
              widget.onSend(v);
              _ctrl.clear();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultsSheet extends StatelessWidget {
  final String query;
  final List<Map<String, dynamic>> hits;
  const _SearchResultsSheet({required this.query, required this.hits});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.search, color: primaryColor, size: 18),
            const SizedBox(width: 6),
            Text('Search: "$query"', style: const TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('${hits.length} hits', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
            child: hits.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No results.', textAlign: TextAlign.center),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: hits.length,
                    separatorBuilder: (_, __) => const Divider(height: 12),
                    itemBuilder: (_, i) {
                      final h = hits[i];
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          // TODO: open chat by chat_id
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h['chat_title']?.toString() ?? '(untitled)',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(h['preview']?.toString() ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
