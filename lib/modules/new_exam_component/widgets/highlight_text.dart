// ════════════════════════════════════════════════════════════════════
// HighlightableText — drag-select on the question stem to mark spans
// ════════════════════════════════════════════════════════════════════
//
// Stores highlights as a list of (start, end) char offsets per
// question, persisted via [HighlightStore]. UI: SelectableText with a
// bottom-sheet on selection that offers "Highlight" / "Note" / clear.
//
// Persistence is local-only by design — highlights are study notes,
// not exam answers, so they don't need to round-trip through the
// backend. They survive app restart via SharedPreferences.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HighlightSpan {
  final int start;
  final int end;
  final String? note;
  HighlightSpan({required this.start, required this.end, this.note});
  Map<String, dynamic> toJson() => {
        'start': start, 'end': end,
        if (note != null && note!.isNotEmpty) 'note': note,
      };
  factory HighlightSpan.fromJson(Map<String, dynamic> j) => HighlightSpan(
        start: (j['start'] as num).toInt(),
        end: (j['end'] as num).toInt(),
        note: j['note'] as String?,
      );
}

class HighlightStore {
  static const _prefix = 'hl:';

  Future<List<HighlightSpan>> load(String key) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_prefix + key);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map>();
      return list
          .map((m) => HighlightSpan.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(String key, List<HighlightSpan> spans) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _prefix + key,
      jsonEncode(spans.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> clear(String key) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_prefix + key);
  }
}

class HighlightableText extends StatefulWidget {
  final String text;

  /// Stable key for persistence — typically `question_id`.
  final String storageKey;
  final TextStyle? style;
  final Color? highlightColor;

  const HighlightableText({
    super.key,
    required this.text,
    required this.storageKey,
    this.style,
    this.highlightColor,
  });

  @override
  State<HighlightableText> createState() => _HighlightableTextState();
}

class _HighlightableTextState extends State<HighlightableText> {
  final HighlightStore _store = HighlightStore();
  List<HighlightSpan> _spans = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _store.load(widget.storageKey);
    if (mounted) setState(() { _spans = s; _loaded = true; });
  }

  Future<void> _addSpan(int start, int end, {String? note}) async {
    if (start >= end || start < 0 || end > widget.text.length) return;
    setState(() => _spans = [..._spans, HighlightSpan(start: start, end: end, note: note)]);
    await _store.save(widget.storageKey, _spans);
  }

  Future<void> _clearAt(int offset) async {
    final remaining = _spans.where((s) => offset < s.start || offset >= s.end).toList();
    if (remaining.length == _spans.length) return;
    setState(() => _spans = remaining);
    await _store.save(widget.storageKey, _spans);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Text(widget.text, style: widget.style);
    }
    final cs = Theme.of(context).colorScheme;
    final hl = widget.highlightColor ?? cs.tertiary.withValues(alpha: 0.30);
    final spans = _buildTextSpans(hl, cs);
    return SelectableText.rich(
      TextSpan(children: spans, style: widget.style),
      contextMenuBuilder: (ctx, editableTextState) {
        final selection = editableTextState.textEditingValue.selection;
        final children = <ContextMenuButtonItem>[
          ...editableTextState.contextMenuButtonItems,
          if (!selection.isCollapsed)
            ContextMenuButtonItem(
              label: 'Highlight',
              onPressed: () {
                _addSpan(selection.start, selection.end);
                editableTextState.hideToolbar();
              },
            ),
          if (selection.isCollapsed)
            ContextMenuButtonItem(
              label: 'Clear highlight',
              onPressed: () {
                _clearAt(selection.start);
                editableTextState.hideToolbar();
              },
            ),
        ];
        return AdaptiveTextSelectionToolbar.buttonItems(
          buttonItems: children,
          anchors: editableTextState.contextMenuAnchors,
        );
      },
    );
  }

  List<InlineSpan> _buildTextSpans(Color hlColor, ColorScheme cs) {
    if (_spans.isEmpty) return [TextSpan(text: widget.text)];
    final sorted = [..._spans]..sort((a, b) => a.start.compareTo(b.start));
    final out = <InlineSpan>[];
    int cursor = 0;
    for (final s in sorted) {
      if (s.start > cursor) {
        out.add(TextSpan(text: widget.text.substring(cursor, s.start)));
      }
      out.add(TextSpan(
        text: widget.text.substring(s.start.clamp(0, widget.text.length), s.end.clamp(0, widget.text.length)),
        style: TextStyle(backgroundColor: hlColor),
      ));
      cursor = s.end;
    }
    if (cursor < widget.text.length) {
      out.add(TextSpan(text: widget.text.substring(cursor)));
    }
    return out;
  }
}
