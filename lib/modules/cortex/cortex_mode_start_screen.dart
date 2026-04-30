// CortexModeStartScreen — universal launcher for the special chat modes.
//
// Single screen handles: roleplay (patient / examiner), OSCE viva, topic
// deep-dive, mnemonic generator, and diagram generator. The arguments
// passed in determine which mode is active (mode_id + mode_label). For
// modes that need extra inputs (scenario / topic / concept), this screen
// shows the right form. On submit it either:
//   - Creates a chat (roleplay / osce / deep-dive) and opens
//     CortexChatScreen
//   - Returns a one-shot result (mnemonic / diagram) inline as a card

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import 'cortex_chat_screen.dart';
import 'cortex_colors.dart';
import 'cortex_service.dart';
import 'store/cortex_store.dart';

class CortexModeStartScreen extends StatefulWidget {
  final String modeId;
  final String modeLabel;

  const CortexModeStartScreen({super.key, required this.modeId, required this.modeLabel});

  static Route<dynamic> route(RouteSettings settings) {
    final args = (settings.arguments ?? {}) as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => CortexModeStartScreen(
        modeId: args['mode_id']?.toString() ?? 'mnemonic',
        modeLabel: args['mode_label']?.toString() ?? 'Mode',
      ),
    );
  }

  @override
  State<CortexModeStartScreen> createState() => _CortexModeStartScreenState();
}

class _CortexModeStartScreenState extends State<CortexModeStartScreen> {
  final _input = TextEditingController();
  String _roleplayRole = 'patient';
  String _difficulty = 'standard';

  bool _busy = false;
  String? _resultText;
  String? _resultMermaid;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  bool get _isInline => widget.modeId == 'mnemonic' || widget.modeId == 'diagram';
  bool get _isRoleplay => widget.modeId == 'roleplay';

  String get _hint {
    switch (widget.modeId) {
      case 'mnemonic': return 'e.g., branches of the celiac trunk';
      case 'diagram': return 'e.g., approach to surgical jaundice';
      case 'roleplay': return 'e.g., 60-year-old man with epigastric pain for 3 weeks';
      case 'osce': return 'e.g., obstructive jaundice management';
      case 'deep_dive': return 'e.g., Acute pancreatitis';
      default: return '';
    }
  }

  String get _ctaLabel {
    switch (widget.modeId) {
      case 'mnemonic': return 'Generate mnemonic';
      case 'diagram': return 'Generate diagram';
      case 'roleplay': return 'Start roleplay';
      case 'osce': return 'Start OSCE viva';
      case 'deep_dive': return 'Begin deep dive';
      default: return 'Start';
    }
  }

  Future<void> _go() async {
    final v = _input.text.trim();
    if (v.isEmpty) return;
    final store = Provider.of<CortexStore>(context, listen: false);
    setState(() {
      _busy = true;
      _resultText = null;
      _resultMermaid = null;
    });
    try {
      switch (widget.modeId) {
        case 'mnemonic':
          final r = await store.service.mnemonic(v);
          setState(() => _resultText = (r['text'] ?? '').toString());
          break;
        case 'diagram':
          final r = await store.service.diagram(v);
          setState(() {
            _resultText = (r['text'] ?? '').toString();
            _resultMermaid = (r['mermaid_source'] ?? '').toString();
          });
          break;
        case 'roleplay':
          final r = await store.service.startRoleplay(role: _roleplayRole, scenario: v, difficulty: _difficulty);
          _openChat(r);
          break;
        case 'osce':
          final r = await store.service.startOsceViva(v);
          _openChat(r);
          break;
        case 'deep_dive':
          final r = await store.service.startTopicDeepDive(v);
          _openChat(r);
          break;
      }
      store.refreshUsage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openChat(Map<String, dynamic> data) {
    final chatId = data['chat_id']?.toString() ?? data['chat']?['_id']?.toString();
    if (chatId == null || !mounted) return;
    Navigator.of(context).pushReplacement(
      CortexChatScreen.route(RouteSettings(arguments: {'chat_id': chatId})),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(widget.modeLabel),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Text(_modeDescription(), style: TextStyle(fontSize: 12, height: 1.5, color: scheme.onSurface.withOpacity(0.85))),
            ),
            const SizedBox(height: 16),

            // Roleplay options
            if (_isRoleplay) ...[
              const Text('Cortex plays:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(children: [
                _SegmentBtn(label: 'Patient', icon: Icons.personal_injury_outlined, value: 'patient', current: _roleplayRole, onTap: (v) => setState(() => _roleplayRole = v)),
                const SizedBox(width: 8),
                _SegmentBtn(label: 'Examiner', icon: Icons.school_outlined, value: 'examiner', current: _roleplayRole, onTap: (v) => setState(() => _roleplayRole = v)),
              ]),
              const SizedBox(height: 12),
              const Text('Difficulty:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(children: [
                _SegmentBtn(label: 'Easy', value: 'easy', current: _difficulty, onTap: (v) => setState(() => _difficulty = v)),
                const SizedBox(width: 6),
                _SegmentBtn(label: 'Standard', value: 'standard', current: _difficulty, onTap: (v) => setState(() => _difficulty = v)),
                const SizedBox(width: 6),
                _SegmentBtn(label: 'Hard', value: 'hard', current: _difficulty, onTap: (v) => setState(() => _difficulty = v)),
              ]),
              const SizedBox(height: 12),
            ],

            // Input
            TextField(
              controller: _input,
              minLines: 2,
              maxLines: 4,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: _hint,
                hintStyle: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.4)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _go,
                icon: _busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome, size: 16),
                label: Text(_busy ? 'Working…' : _ctaLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Inline result for mnemonic / diagram
            if (_isInline && _resultText != null && _resultText!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(widget.modeId == 'mnemonic' ? Icons.psychology : Icons.account_tree, color: primaryColor, size: 18),
                      const SizedBox(width: 6),
                      Text(_ctaLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primaryColor)),
                    ]),
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data: _resultText!,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: TextStyle(fontSize: 12, height: 1.5, color: scheme.onSurface),
                        code: TextStyle(
                          fontFamily: 'monospace',
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black26
                              : Colors.grey.shade200,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (_resultMermaid != null && _resultMermaid!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline, size: 12, color: Colors.amber),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Mermaid diagram source available — render with mermaid.js if your build supports it.',
                              style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _modeDescription() {
    switch (widget.modeId) {
      case 'mnemonic':
        return '🧠 Generates a memorable mnemonic with expansion + clinical hook for any concept.';
      case 'diagram':
        return '📊 Generates a Mermaid.js flowchart / graph for management algorithms or anatomy.';
      case 'roleplay':
        return '🎭 Cortex plays a patient (you take history) or an examiner (you answer viva questions). Say "exit roleplay" to debrief.';
      case 'osce':
        return '🩺 Structured 8-12 question OSCE viva on any topic. Cortex grades you 10-point at the end.';
      case 'deep_dive':
        return '🔍 5-section guided walkthrough — Anatomy → Pathology → Clinical → Investigations → Management. Pause-and-resume between sections.';
      default:
        return '';
    }
  }
}

class _SegmentBtn extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final void Function(String) onTap;
  final IconData? icon;
  const _SegmentBtn({required this.label, required this.value, required this.current, required this.onTap, this.icon});
  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? primaryColor : primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: primaryColor.withOpacity(selected ? 1.0 : 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? Colors.white : primaryColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
