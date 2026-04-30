// CortexSnippetsScreen — student's saved-snippet library.
//
// Lists every assistant message they've starred (POST /message/:id/snippet).
// Each tile shows a preview + chat title context badge. Tap to navigate to
// the source chat. Long-press for note edit.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import 'cortex_chat_screen.dart';
import 'cortex_colors.dart';
import 'store/cortex_store.dart';

class CortexSnippetsScreen extends StatefulWidget {
  const CortexSnippetsScreen({super.key});

  static Route<dynamic> route(RouteSettings settings) =>
      CupertinoPageRoute(builder: (_) => const CortexSnippetsScreen());

  static Route<dynamic> routeNew() =>
      CupertinoPageRoute(builder: (_) => const CortexSnippetsScreen());

  @override
  State<CortexSnippetsScreen> createState() => _CortexSnippetsScreenState();
}

class _CortexSnippetsScreenState extends State<CortexSnippetsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<CortexStore>(context, listen: false).loadSnippets();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<CortexStore>(context, listen: false);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Saved Snippets'),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      body: Observer(builder: (_) {
        if (store.snippets.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 48, color: scheme.onSurface.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text('No saved snippets yet',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: scheme.onSurface.withOpacity(0.6))),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the bookmark icon on any Cortex reply to save it for later.',
                    style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.4)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: store.snippets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final s = store.snippets[i];
            return InkWell(
              onTap: () => Navigator.of(context).push(
                CortexChatScreen.route(RouteSettings(arguments: {'chat_id': s.chatId})),
              ),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.bookmark, size: 14, color: primaryColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          (s as dynamic).chatTitle ?? '(chat)',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryColor),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.bookmark_remove, size: 16),
                        tooltip: 'Unsave',
                        onPressed: () async {
                          await store.toggleSnippet(s.id, save: false);
                          await store.loadSnippets();
                        },
                      ),
                    ]),
                    const SizedBox(height: 4),
                    if ((s.snippetNote ?? '').isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(children: [
                          const Icon(Icons.sticky_note_2_outlined, size: 11, color: Colors.amber),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              s.snippetNote!,
                              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: ClipRect(
                        child: MarkdownBody(
                          data: s.content.length > 800 ? '${s.content.substring(0, 800)}…' : s.content,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                            p: TextStyle(fontSize: 11, height: 1.4, color: scheme.onSurface.withOpacity(0.85)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
