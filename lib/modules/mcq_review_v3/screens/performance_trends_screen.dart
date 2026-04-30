// PerformanceTrendsScreen — long-term analytics dashboard.
//   • Topic strength bar list
//   • Confidence calibration curve
//   • Per-topic accuracy trend over time

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../models/mcq_review_models.dart';
import '../mcq_review_service.dart';

class PerformanceTrendsScreen extends StatefulWidget {
  const PerformanceTrendsScreen({super.key});
  static Route<dynamic> route(RouteSettings settings) =>
      CupertinoPageRoute(builder: (_) => const PerformanceTrendsScreen());
  @override
  State<PerformanceTrendsScreen> createState() => _PerformanceTrendsScreenState();
}

class _PerformanceTrendsScreenState extends State<PerformanceTrendsScreen> {
  final _service = McqReviewService();
  List<TopicStrength> _topics = [];
  List<CalibrationBucket> _calibration = [];
  double? _brier;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final topics = await _service.topicStrength();
    final calib = await _service.calibration();
    if (!mounted) return;
    setState(() {
      _topics = topics;
      _calibration = (calib['buckets'] as List).cast<CalibrationBucket>();
      _brier = (calib['brier_score'] as num?)?.toDouble();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Performance Trends'),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _SectionHeader(label: '🎯 Topic strength'),
                  const SizedBox(height: 8),
                  if (_topics.isEmpty)
                    Text('No data yet — attempt a few exams to see trends.',
                        style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.5)))
                  else
                    ..._topics.map((t) => _TopicBar(topic: t)),
                  const SizedBox(height: 24),

                  const _SectionHeader(label: '🧠 Calibration'),
                  const SizedBox(height: 4),
                  if (_brier != null)
                    Text('Brier score: ${_brier!.toStringAsFixed(3)} (lower = better)',
                        style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.6))),
                  const SizedBox(height: 8),
                  if (_calibration.isEmpty)
                    Text('Rate your confidence on more questions to build the calibration curve.',
                        style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.5)))
                  else
                    _CalibrationChart(buckets: _calibration),
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85)));
  }
}

class _TopicBar extends StatelessWidget {
  final TopicStrength topic;
  const _TopicBar({required this.topic});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = topic.accuracyPct >= 75 ? Colors.green : topic.accuracyPct >= 50 ? Colors.orange : Colors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(topic.topic, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text('${topic.accuracyPct.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(width: 6),
            Text('(${topic.correct}/${topic.attempted})',
                style: TextStyle(fontSize: 10, color: scheme.onSurface.withOpacity(0.5))),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: topic.accuracyPct / 100,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalibrationChart extends StatelessWidget {
  final List<CalibrationBucket> buckets;
  const _CalibrationChart({required this.buckets});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(
        painter: _CalibrationPainter(buckets: buckets, scheme: Theme.of(context).colorScheme),
        size: Size.infinite,
      ),
    );
  }
}

class _CalibrationPainter extends CustomPainter {
  final List<CalibrationBucket> buckets;
  final ColorScheme scheme;
  _CalibrationPainter({required this.buckets, required this.scheme});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw axes + diagonal "perfect calibration" line
    final axisPaint = Paint()..color = scheme.onSurface.withOpacity(0.2)..strokeWidth = 1;
    canvas.drawLine(Offset(0, h), Offset(w, h), axisPaint); // x-axis
    canvas.drawLine(Offset(0, 0), Offset(0, h), axisPaint); // y-axis

    final diagPaint = Paint()..color = scheme.onSurface.withOpacity(0.15)..strokeWidth = 1;
    canvas.drawLine(Offset(0, h), Offset(w, 0), diagPaint);

    // Plot points
    if (buckets.isEmpty) return;
    final pointPaint = Paint()..color = scheme.primary;
    final linePaint = Paint()..color = scheme.primary..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path();
    Offset? prev;
    for (final b in buckets) {
      final x = (b.bucket / 100) * w;
      final y = h - (b.accuracyPct / 100) * h;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      if (prev == null) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      prev = Offset(x, y);
    }
    canvas.drawPath(path, linePaint);

    // Axis labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(text: 'Confidence →', style: TextStyle(fontSize: 9, color: scheme.onSurface.withOpacity(0.5)));
    tp.layout();
    tp.paint(canvas, Offset(w - tp.width, h - tp.height - 2));

    tp.text = TextSpan(text: 'Accuracy ↑', style: TextStyle(fontSize: 9, color: scheme.onSurface.withOpacity(0.5)));
    tp.layout();
    tp.paint(canvas, const Offset(2, 2));
  }

  @override
  bool shouldRepaint(_CalibrationPainter oldDelegate) => oldDelegate.buckets != buckets;
}
