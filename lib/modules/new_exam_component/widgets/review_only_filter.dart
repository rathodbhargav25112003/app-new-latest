// ════════════════════════════════════════════════════════════════════
// ReviewOnlyFilter — palette filter for unanswered / marked-for-review
// ════════════════════════════════════════════════════════════════════
//
// Drop-in chip group. Pure UI; the host store applies the filter to
// its question palette via the returned `ReviewFilterMode`.

import 'package:flutter/material.dart';

enum ReviewFilterMode { all, unanswered, markedForReview, wrongSoFar }

class ReviewOnlyFilter extends StatelessWidget {
  final ReviewFilterMode current;
  final void Function(ReviewFilterMode) onChanged;

  /// Optional counts — if provided, render alongside each chip label.
  final Map<ReviewFilterMode, int>? counts;

  const ReviewOnlyFilter({
    super.key,
    required this.current,
    required this.onChanged,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ReviewFilterMode.values.map((m) {
        final n = counts?[m];
        return ChoiceChip(
          selected: current == m,
          label: Text(_label(m) + (n != null ? '  ($n)' : '')),
          onSelected: (sel) {
            if (sel) onChanged(m);
          },
        );
      }).toList(),
    );
  }

  String _label(ReviewFilterMode m) {
    switch (m) {
      case ReviewFilterMode.all:
        return 'All';
      case ReviewFilterMode.unanswered:
        return 'Unanswered';
      case ReviewFilterMode.markedForReview:
        return 'Marked';
      case ReviewFilterMode.wrongSoFar:
        return 'Wrong';
    }
  }

  /// Helper that callers can use to filter their own question lists
  /// based on the chosen mode + answer state.
  static bool include(
    ReviewFilterMode mode, {
    required bool attempted,
    required bool markedForReview,
    bool? isCorrect,
  }) {
    switch (mode) {
      case ReviewFilterMode.all:
        return true;
      case ReviewFilterMode.unanswered:
        return !attempted;
      case ReviewFilterMode.markedForReview:
        return markedForReview;
      case ReviewFilterMode.wrongSoFar:
        return attempted && isCorrect == false;
    }
  }
}
