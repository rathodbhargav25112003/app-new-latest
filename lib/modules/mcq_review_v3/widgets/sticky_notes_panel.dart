// StickyNotesPanel — multi-note panel for one Q. Replaces the legacy
// single-blob notes UI with a list of named notes ("Pearl 1: …",
// "To revise: …"). Each note is a {title, body, color} stored locally
// (or via the existing notes API if you wire it up).
//
// The widget is intentionally storage-agnostic — pass `notes`,
// `onSave(updated)`, `onDelete(id)` callbacks. Parent screen handles
// persistence.

import 'package:flutter/material.dart';

class StickyNote {
  final String id;
  String title;
  String body;
  String color; // 'yellow' | 'blue' | 'pink' | 'green'
  DateTime updatedAt;

  StickyNote({
    required this.id,
    required this.title,
    required this.body,
    this.color = 'yellow',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'color': color,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory StickyNote.fromJson(Map<String, dynamic> json) => StickyNote(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        body: (json['body'] ?? '').toString(),
        color: (json['color'] ?? 'yellow').toString(),
        updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ?? DateTime.now(),
      );
}

class StickyNotesPanel extends StatefulWidget {
  final List<StickyNote> notes;
  final Future<void> Function(StickyNote) onSave;
  final Future<void> Function(String id) onDelete;

  const StickyNotesPanel({
    super.key,
    required this.notes,
    required this.onSave,
    required this.onDelete,
  });

  static Future<void> show(BuildContext context, {
    required List<StickyNote> notes,
    required Future<void> Function(StickyNote) onSave,
    required Future<void> Function(String id) onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: StickyNotesPanel(notes: notes, onSave: onSave, onDelete: onDelete),
        ),
      ),
    );
  }

  @override
  State<StickyNotesPanel> createState() => _StickyNotesPanelState();
}

class _StickyNotesPanelState extends State<StickyNotesPanel> {
  late List<StickyNote> _notes;

  @override
  void initState() {
    super.initState();
    _notes = List.of(widget.notes);
  }

  void _addNote() {
    final n = StickyNote(
      id: 'n-${DateTime.now().millisecondsSinceEpoch}',
      title: 'New note',
      body: '',
      color: 'yellow',
    );
    setState(() => _notes.insert(0, n));
    _editNote(n);
  }

  Future<void> _editNote(StickyNote n) async {
    final result = await showDialog<StickyNote>(
      context: context,
      builder: (_) => _NoteEditorDialog(initial: n),
    );
    if (result != null) {
      setState(() {
        final idx = _notes.indexWhere((x) => x.id == result.id);
        if (idx == -1) _notes.insert(0, result);
        else _notes[idx] = result;
      });
      await widget.onSave(result);
    }
  }

  Future<void> _deleteNote(StickyNote n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: const Text('Delete this note?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _notes.removeWhere((x) => x.id == n.id));
      await widget.onDelete(n.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: scheme.onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.sticky_note_2_outlined, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(onPressed: _addNote, icon: const Icon(Icons.add)),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: _notes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.note_alt_outlined, size: 36, color: scheme.onSurface.withOpacity(0.3)),
                          const SizedBox(height: 6),
                          Text('No notes yet — tap + to add', style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.4))),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = _notes[i];
                      return _NoteCard(
                        note: n,
                        onTap: () => _editNote(n),
                        onDelete: () => _deleteNote(n),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final StickyNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _NoteCard({required this.note, required this.onTap, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _bg(note.color),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border(note.color), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(note.title.isEmpty ? '(untitled)' : note.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              ),
              InkWell(
                onTap: onDelete,
                child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 14)),
              ),
            ]),
            if (note.body.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(note.body, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }

  Color _bg(String c) {
    switch (c) {
      case 'blue':   return const Color(0xFFE3F2FD);
      case 'pink':   return const Color(0xFFFCE4EC);
      case 'green':  return const Color(0xFFE8F5E9);
      default:       return const Color(0xFFFFFDE7);
    }
  }

  Color _border(String c) {
    switch (c) {
      case 'blue':   return const Color(0xFF90CAF9);
      case 'pink':   return const Color(0xFFF48FB1);
      case 'green':  return const Color(0xFFA5D6A7);
      default:       return const Color(0xFFFFE082);
    }
  }
}

class _NoteEditorDialog extends StatefulWidget {
  final StickyNote initial;
  const _NoteEditorDialog({required this.initial});
  @override
  State<_NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<_NoteEditorDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  late String _color;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initial.title);
    _bodyCtrl = TextEditingController(text: widget.initial.body);
    _color = widget.initial.color;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Note'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(controller: _bodyCtrl, maxLines: 6, decoration: const InputDecoration(labelText: 'Body')),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final c in const ['yellow', 'blue', 'pink', 'green']) Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _color = c),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: _swatch(c),
                        shape: BoxShape.circle,
                        border: Border.all(color: _color == c ? Colors.black : Colors.grey.shade300, width: _color == c ? 2 : 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, StickyNote(
            id: widget.initial.id,
            title: _titleCtrl.text.trim(),
            body: _bodyCtrl.text,
            color: _color,
            updatedAt: DateTime.now(),
          )),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Color _swatch(String c) {
    switch (c) {
      case 'blue':   return const Color(0xFF90CAF9);
      case 'pink':   return const Color(0xFFF48FB1);
      case 'green':  return const Color(0xFFA5D6A7);
      default:       return const Color(0xFFFFE082);
    }
  }
}
