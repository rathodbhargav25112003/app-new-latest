// ════════════════════════════════════════════════════════════════════
// SectionNavigator — drives sectioned-normal AND sectioned-mock flows
// ════════════════════════════════════════════════════════════════════
//
// Reads from `ResumeState.sections` and renders one tile per section
// with status / per-section timer / answered-count badge. Tap routes
// the host screen into that section (caller hooks via onSectionTap).
//
// Theme-agnostic: uses Theme.of(context) colors, no hard-coded brand
// palette. Drop into the existing exam_screen scaffold and theme it
// to match.

import 'package:flutter/material.dart';
import '../../../api_service/exam_attempt_api.dart' show ResumeSection;

class SectionNavigator extends StatelessWidget {
  final List<ResumeSection> sections;
  final String? activeSectionId;
  final void Function(ResumeSection) onSectionTap;
  final void Function()? onSubmitAll;
  final bool allowSubmitAll;

  const SectionNavigator({
    super.key,
    required this.sections,
    required this.onSectionTap,
    this.activeSectionId,
    this.onSubmitAll,
    this.allowSubmitAll = false,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...sections.map((s) => _SectionTile(
              section: s,
              isActive: s.sectionId == activeSectionId,
              onTap: s.status == 'submitted' || s.status == 'locked'
                  ? null
                  : () => onSectionTap(s),
            )),
        if (allowSubmitAll && onSubmitAll != null) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _allSectionsSubmitted ? onSubmitAll : null,
            icon: const Icon(Icons.flag),
            label: Text(_allSectionsSubmitted
                ? 'Submit Final Attempt'
                : 'Finish all sections to submit'),
          ),
        ],
      ],
    );
  }

  bool get _allSectionsSubmitted =>
      sections.isNotEmpty && sections.every((s) => s.status == 'submitted');
}

class _SectionTile extends StatelessWidget {
  final ResumeSection section;
  final bool isActive;
  final VoidCallback? onTap;

  const _SectionTile({
    required this.section,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final disabled = onTap == null;

    Color statusColor;
    IconData statusIcon;
    switch (section.status) {
      case 'in_progress':
        statusColor = cs.primary;
        statusIcon = Icons.play_circle_fill;
        break;
      case 'submitted':
        statusColor = cs.tertiary;
        statusIcon = Icons.check_circle;
        break;
      case 'locked':
        statusColor = cs.outline;
        statusIcon = Icons.lock_outline;
        break;
      case 'available':
      default:
        statusColor = cs.onSurfaceVariant;
        statusIcon = Icons.radio_button_unchecked;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isActive ? cs.primary.withValues(alpha: 0.06) : cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isActive ? cs.primary : cs.outlineVariant,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        section.sectionId,
                        style: t.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: disabled ? cs.onSurfaceVariant : cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${section.questionsAnswered} answered'
                        '${_timeText() != null ? ' · ${_timeText()}' : ''}',
                        style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (section.status == 'in_progress')
                  Text(
                    'IN PROGRESS',
                    style: t.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      letterSpacing: 0.06 * 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _timeText() {
    final ms = section.timeRemainingMs;
    if (ms == null) return null;
    final m = (ms / 60000).floor();
    final s = ((ms % 60000) / 1000).floor();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} left';
  }
}
