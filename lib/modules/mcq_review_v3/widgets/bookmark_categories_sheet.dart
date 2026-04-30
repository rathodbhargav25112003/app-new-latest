// BookmarkCategoriesSheet — when a student bookmarks a Q, this sheet
// pops up so they can:
//   • Pick a category ("High-yield", "Need revision", "Tricky", "Custom")
//   • Add a per-bookmark note ("Why am I bookmarking this?")
//   • Set a color tag
//
// Storage is local-only (SharedPreferences key: 'mcq_bookmark_meta:<questionId>'
// → JSON {category, note, color, savedAt}). Wire to your existing
// bookmark POST endpoint as a follow-up if you want server-side sync.
//
// Drop-in: when the user taps the bookmark icon and the new state is
// "bookmarked", call BookmarkCategoriesSheet.show(...) right after.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkMeta {
  final String category;
  final String note;
  final String color;
  final DateTime savedAt;
  BookmarkMeta({this.category = 'general', this.note = '', this.color = 'yellow', DateTime? savedAt})
      : savedAt = savedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'category': category,
        'note': note,
        'color': color,
        'savedAt': savedAt.toIso8601String(),
      };

  factory BookmarkMeta.fromJson(Map<String, dynamic> j) => BookmarkMeta(
        category: (j['category'] ?? 'general').toString(),
        note: (j['note'] ?? '').toString(),
        color: (j['color'] ?? 'yellow').toString(),
        savedAt: DateTime.tryParse((j['savedAt'] ?? '').toString()) ?? DateTime.now(),
      );

  static String _key(String questionId) => 'mcq_bookmark_meta:$questionId';

  static Future<BookmarkMeta?> load(String questionId) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key(questionId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return BookmarkMeta.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String questionId, BookmarkMeta meta) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key(questionId), jsonEncode(meta.toJson()));
  }

  static Future<void> remove(String questionId) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key(questionId));
  }
}

class BookmarkCategoriesSheet extends StatefulWidget {
  final String questionId;
  final BookmarkMeta? initial;

  const BookmarkCategoriesSheet({super.key, required this.questionId, this.initial});

  /// Returns the saved meta, or null if cancelled.
  static Future<BookmarkMeta?> show(BuildContext context, {required String questionId}) async {
    final existing = await BookmarkMeta.load(questionId);
    if (!context.mounted) return null;
    return await showModalBottomSheet<BookmarkMeta>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: BookmarkCategoriesSheet(questionId: questionId, initial: existing),
      ),
    );
  }

  @override
  State<BookmarkCategoriesSheet> createState() => _BookmarkCategoriesSheetState();
}

class _BookmarkCategoriesSheetState extends State<BookmarkCategoriesSheet> {
  static const _categories = [
    {'id': 'high_yield', 'label': '⭐ High-yield', 'color': 'yellow'},
    {'id': 'revise', 'label': '🔁 Need revision', 'color': 'pink'},
    {'id': 'tricky', 'label': '🧠 Tricky', 'color': 'blue'},
    {'id': 'pearl', 'label': '💎 Clinical pearl', 'color': 'green'},
    {'id': 'general', 'label': '🔖 General', 'color': 'yellow'},
  ];

  late TextEditingController _noteCtrl;
  late String _category;
  late String _color;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.initial?.note ?? '');
    _category = widget.initial?.category ?? 'general';
    _color = widget.initial?.color ?? 'yellow';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final meta = BookmarkMeta(
      category: _category,
      note: _noteCtrl.text.trim(),
      color: _color,
      savedAt: DateTime.now(),
    );
    await BookmarkMeta.save(widget.questionId, meta);
    if (mounted) Navigator.pop(context, meta);
  }

  Future<void> _delete() async {
    await BookmarkMeta.remove(widget.questionId);
    if (mounted) Navigator.pop(context, null);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: scheme.onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.bookmark, color: scheme.primary),
            const SizedBox(width: 8),
            const Text('Bookmark', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: _categories.map((c) {
              final selected = c['id'] == _category;
              return InkWell(
                onTap: () => setState(() {
                  _category = c['id']!;
                  _color = c['color']!;
                }),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? scheme.primary : scheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.primary.withOpacity(selected ? 1 : 0.3)),
                  ),
                  child: Text(
                    c['label']!,
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : scheme.primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text('Note (optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            maxLength: 280,
            decoration: const InputDecoration(
              hintText: 'Why am I saving this?',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.initial != null)
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text('Remove', style: TextStyle(color: Colors.red)),
                ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.bookmark_added, size: 16),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
