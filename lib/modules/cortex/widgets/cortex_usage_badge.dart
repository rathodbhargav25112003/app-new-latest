// CortexUsageBadge — small "X / N today" pill that indicates how much of
// the daily Cortex AI cap the student has used. Reactive — auto-refreshes
// when the store's `usage` observable changes (after every chat turn).

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../store/cortex_store.dart';

class CortexUsageBadge extends StatelessWidget {
  final bool compact;
  const CortexUsageBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<CortexStore>(context, listen: false);
    return Observer(builder: (_) {
      final u = store.usage.value;
      final low = u.remaining <= 5;
      final color = low ? Colors.red.shade400 : Theme.of(context).colorScheme.onSurface.withOpacity(0.55);
      final bg = low ? Colors.red.shade50.withOpacity(0.4) : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(low ? Icons.error_outline : Icons.bolt_outlined, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              compact ? '${u.used}/${u.cap}' : '${u.used} of ${u.cap} today',
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
    });
  }
}
