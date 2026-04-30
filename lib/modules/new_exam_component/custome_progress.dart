// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';

/// Horizontal multi-segment progress bar with overlap-avoiding labels.
///
/// Preserved public contracts:
///   • `DynamicProgressBar({super.key, required List&lt;ProgressItem&gt;
///     progressItems})` — same props and default.
///   • `ProgressItem({required label, required value, required color})`
///     — unchanged; caller-supplied colors still drive both the segment
///     and the label bubble.
///   • `TrianglePainter({required color})` — still publicly exported so
///     any external callers that reuse it continue to compile.
///
/// Algorithmic contract (preserved verbatim):
///   • Non-zero segments are laid out proportionally to their value.
///   • Labels are placed centred over their segment, then nudged right
///     to avoid overlap using:
///       - half-label-width = 40
///       - label-width = 80
///       - min spacing between labels = 85 (declared as local var)
///       - final `clamp(0.0, totalWidth - 65)` to stay on screen
///   • Triangle pointer sits under the label; when `item.value < 20`,
///     the pointer is re-centred over the segment centre via a
///     `Transform.translate` with `initialPositions[index]['center']! -
///     labelPosition - 31` — kept byte-for-byte.
///
/// Cosmetic changes only: empty-state track uses AppTokens.surface3,
/// label shadow reuses `AppTokens.shadow1`, and the track corner uses
/// `AppTokens.r8`.
class DynamicProgressBar extends StatelessWidget {
  const DynamicProgressBar({
    super.key,
    required this.progressItems,
  });

  final List<ProgressItem> progressItems;

  @override
  Widget build(BuildContext context) {
    final int total = progressItems.fold(0, (sum, item) => sum + item.value);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        double cumulativeWidth = 0;

        final List<Map<String, double>> initialPositions = progressItems
            .where((item) => item.value > 0)
            .map((item) {
          final double segmentWidth = (item.value / total) * totalWidth;
          final double centerPosition = cumulativeWidth + (segmentWidth / 2);
          cumulativeWidth += segmentWidth;
          return {
            'center': centerPosition,
            'width': segmentWidth,
          };
        }).toList();

        final List<double> adjustedPositions = [];
        // Minimum space between labels — preserved legacy value.
        // ignore: unused_local_variable
        const double minSpacing = 85.0;

        for (int i = 0; i < initialPositions.length; i++) {
          final double currentCenter = initialPositions[i]['center']!;
          double adjustedPosition = currentCenter - 40; // 40 = ½ label width
          if (i > 0) {
            final double previousAdjustedEnd =
                adjustedPositions[i - 1] + 80; // 80 = label width
            if (adjustedPosition < previousAdjustedEnd) {
              adjustedPosition = previousAdjustedEnd;
            }
          }
          adjustedPosition = adjustedPosition.clamp(0.0, totalWidth - 65);
          adjustedPositions.add(adjustedPosition);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 36,
              child: Stack(
                children: progressItems
                    .where((item) => item.value > 0)
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) {
                  final int index = entry.key;
                  final ProgressItem item = entry.value;
                  final double labelPosition = adjustedPositions[index];

                  return Positioned(
                    left: labelPosition,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 80),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: item.color,
                            borderRadius:
                                BorderRadius.circular(AppTokens.r8 / 2),
                            boxShadow: AppTokens.shadow1(context),
                          ),
                          child: Text(
                            '${item.label} ${item.value}',
                            style: AppTokens.caption(context).copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (item.value < 20) ...[
                          Transform.translate(
                            offset: Offset(
                              initialPositions[index]['center']! -
                                  labelPosition -
                                  31,
                              -1,
                            ),
                            child: CustomPaint(
                              size: const Size(10, 5),
                              painter: TrianglePainter(color: item.color),
                            ),
                          ),
                        ] else ...[
                          CustomPaint(
                            size: const Size(10, 5),
                            painter: TrianglePainter(color: item.color),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.r8),
              child: progressItems.every((item) => item.value == 0)
                  ? Container(
                      height: 6,
                      width: totalWidth,
                      color: AppTokens.surface3(context),
                    )
                  : Row(
                      children: progressItems
                          .where((item) => item.value > 0)
                          .map(
                            (item) => Flexible(
                              flex: item.value,
                              child: Container(
                                height: 6,
                                color: item.color,
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class ProgressItem {
  ProgressItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

/// Public painter used by the label's triangle pointer. Kept public
/// because external callers in the old codebase re-used it directly.
class TrianglePainter extends CustomPainter {
  TrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
