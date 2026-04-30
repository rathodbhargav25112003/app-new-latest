// CortexMemoryScreen — student's persistent Cortex memory + preferences.
//
// Three sections:
//   1. Stats card (total chats, debriefs, flashcards generated)
//   2. Weak topics — auto-tracked from mistake debriefs. Tap a chip to
//      open a deep-dive chat on that topic.
//   3. Preferences (tone toggle, show pearls, show reference, examiner view)
//   4. Free-form notes (synced via PATCH /api/cortex/memory)

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../models/cortex_models.dart';
import 'cortex_colors.dart';
import 'cortex_chat_screen.dart';
import 'store/cortex_store.dart';

class CortexMemoryScreen extends StatefulWidget {
  const CortexMemoryScreen({super.key});

  static Route<dynamic> route(RouteSettings settings) =>
      CupertinoPageRoute(builder: (_) => const CortexMemoryScreen());

  static Route<dynamic> routeNew() =>
      CupertinoPageRoute(builder: (_) => const CortexMemoryScreen());

  @override
  State<CortexMemoryScreen> createState() => _CortexMemoryScreenState();
}

class _CortexMemoryScreenState extends State<CortexMemoryScreen> {
  final _notesCtrl = TextEditingController();
  bool _notesDirty = false;

  @override
  void initState() {
    super.initState();
    final store = Provider.of<CortexStore>(context, listen: false);
    store.loadMemory().then((_) {
      _notesCtrl.text = store.memory.value.notes;
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<CortexStore>(context, listen: false);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Memory & Settings'),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        actions: [
          if (_notesDirty)
            TextButton(
              onPressed: () async {
                await store.updateMemory(notes: _notesCtrl.text);
                setState(() => _notesDirty = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved'), duration: Duration(seconds: 1)),
                  );
                }
              },
              child: Text('Save', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      body: Observer(builder: (_) {
        final m = store.memory.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats
            _StatsRow(memory: m),
            const SizedBox(height: 16),

            // Weak topics
            _SectionLabel('🎯 Topics you struggle with'),
            if (m.weakTopics.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No weak topics tracked yet. Cortex auto-records these when you use mistake debriefs.',
                  style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.5)),
                ),
              )
            else
              Wrap(
                spacing: 8, runSpacing: 8,
                children: m.weakTopics
                    .map((t) => InkWell(
                          onTap: () async {
                            final chat = await store.startChat(
                              contextKind: 'topic_deep_dive',
                              topicName: t.topic,
                              firstMessage:
                                  'Walk me through ${t.topic}${t.subtopic.isNotEmpty ? ' — ${t.subtopic}' : ''} end-to-end.',
                            );
                            if (chat != null && context.mounted) {
                              Navigator.of(context).push(CortexChatScreen.routeForChat(chat));
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              border: Border.all(color: Colors.orange.withOpacity(0.4)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                '${t.topic}${t.subtopic.isNotEmpty ? ' (${t.subtopic})' : ''}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.orange),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${t.mistakeCount}',
                                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ]),
                          ),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 24),

            // Preferences
            _SectionLabel('⚙️ Preferences'),
            const SizedBox(height: 8),
            _PreferenceTile(
              title: 'Reply tone',
              value: m.preferences.tone,
              options: const [
                _PrefOption('concise', 'Concise'),
                _PrefOption('detailed', 'Detailed'),
                _PrefOption('mnemonic-heavy', 'Mnemonic-heavy'),
              ],
              onChanged: (v) async {
                final updated = CortexPreferences(
                  tone: v,
                  showReferenceSection: m.preferences.showReferenceSection,
                  showPearls: m.preferences.showPearls,
                  showExaminerView: m.preferences.showExaminerView,
                );
                await store.updateMemory(preferences: updated);
              },
            ),
            _SwitchPref(
              label: 'Show 📖 Reference section',
              value: m.preferences.showReferenceSection,
              onChanged: (v) async {
                final updated = CortexPreferences(
                  tone: m.preferences.tone,
                  showReferenceSection: v,
                  showPearls: m.preferences.showPearls,
                  showExaminerView: m.preferences.showExaminerView,
                );
                await store.updateMemory(preferences: updated);
              },
            ),
            _SwitchPref(
              label: 'Show 💎 exam pearls',
              value: m.preferences.showPearls,
              onChanged: (v) async {
                final updated = CortexPreferences(
                  tone: m.preferences.tone,
                  showReferenceSection: m.preferences.showReferenceSection,
                  showPearls: v,
                  showExaminerView: m.preferences.showExaminerView,
                );
                await store.updateMemory(preferences: updated);
              },
            ),
            _SwitchPref(
              label: 'Show 🎯 examiner view',
              value: m.preferences.showExaminerView,
              onChanged: (v) async {
                final updated = CortexPreferences(
                  tone: m.preferences.tone,
                  showReferenceSection: m.preferences.showReferenceSection,
                  showPearls: m.preferences.showPearls,
                  showExaminerView: v,
                );
                await store.updateMemory(preferences: updated);
              },
            ),
            const SizedBox(height: 24),

            // Notes
            _SectionLabel('📝 Notes (Cortex sees these as context)'),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              maxLines: 6,
              maxLength: 2000,
              style: const TextStyle(fontSize: 12, height: 1.4),
              decoration: InputDecoration(
                hintText: 'e.g., "Currently rotating in HPB. Exam in 6 weeks. Focus on cholangitis pathophys."',
                hintStyle: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.4)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              onChanged: (_) => setState(() => _notesDirty = true),
            ),
            const SizedBox(height: 32),
          ],
        );
      }),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final CortexMemory memory;
  const _StatsRow({required this.memory});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatTile(label: 'Chats', value: '${memory.totalChats}')),
        const SizedBox(width: 8),
        Expanded(child: _StatTile(label: 'Debriefs', value: '${memory.totalDebriefs}')),
        const SizedBox(width: 8),
        Expanded(child: _StatTile(label: 'Flashcards', value: '${memory.totalFlashcardsGenerated}')),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryColor)),
          Text(label, style: TextStyle(fontSize: 10, color: scheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85))),
    );
  }
}

class _PrefOption {
  final String value;
  final String label;
  const _PrefOption(this.value, this.label);
}

class _PreferenceTile extends StatelessWidget {
  final String title;
  final String value;
  final List<_PrefOption> options;
  final void Function(String) onChanged;
  const _PreferenceTile({required this.title, required this.value, required this.options, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: options.map((o) {
              final selected = o.value == value;
              return InkWell(
                onTap: () => onChanged(o.value),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? primaryColor : primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withOpacity(selected ? 1.0 : 0.3)),
                  ),
                  child: Text(
                    o.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : primaryColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SwitchPref extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) onChanged;
  const _SwitchPref({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Switch(value: value, onChanged: onChanged, activeColor: primaryColor),
        ],
      ),
    );
  }
}
