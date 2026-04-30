// RelatedMcqsCarousel — horizontal carousel of "more MCQs on this concept"
// cards. Pure DB query, no AI cost — appears below the result/solution
// row of a wrong question. Tapping a card navigates to the source exam
// and jumps to the matching question.

import 'package:flutter/material.dart';

import '../../../models/cortex_models.dart';
import '../cortex_colors.dart';
import '../cortex_service.dart';

class RelatedMcqsCarousel extends StatefulWidget {
  final String questionId;
  final String examType; // 'regular' | 'mock'
  final void Function(CortexRelatedMcq mcq)? onTap;

  const RelatedMcqsCarousel({
    super.key,
    required this.questionId,
    this.examType = 'regular',
    this.onTap,
  });

  @override
  State<RelatedMcqsCarousel> createState() => _RelatedMcqsCarouselState();
}

class _RelatedMcqsCarouselState extends State<RelatedMcqsCarousel> {
  final _service = CortexService();
  List<CortexRelatedMcq>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _service.relatedMcqs(widget.questionId, examType: widget.examType);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _items = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (_items == null || _items!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.replay, size: 14, color: primaryColor),
              const SizedBox(width: 5),
              Text(
                'Related practice',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor),
              ),
              const SizedBox(width: 4),
              Text(
                '· ${_items!.length}',
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _items!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final m = _items![i];
                return _RelatedCard(mcq: m, onTap: widget.onTap);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  final CortexRelatedMcq mcq;
  final void Function(CortexRelatedMcq mcq)? onTap;
  const _RelatedCard({required this.mcq, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(mcq),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.outline.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mcq.examName.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  mcq.examName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: primaryColor),
                ),
              ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                mcq.stemPreview.isEmpty ? '(No preview)' : mcq.stemPreview,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, height: 1.4, color: scheme.onSurface),
              ),
            ),
            if (mcq.subtopic.isNotEmpty)
              Text(
                mcq.subtopic,
                style: TextStyle(fontSize: 9, color: scheme.onSurface.withOpacity(0.55)),
              ),
          ],
        ),
      ),
    );
  }
}
