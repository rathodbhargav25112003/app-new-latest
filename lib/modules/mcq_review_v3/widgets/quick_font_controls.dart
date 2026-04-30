// QuickFontControls — A+ / A / A- pill in the screen header. Replaces
// the existing "Open Font Size dialog" with a 1-tap pill that adjusts
// in 10% increments. Persists to SharedPreferences so the choice
// survives across screens + restarts.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuickFontControls extends StatefulWidget {
  /// Min/max scale percent (e.g., 70..150)
  final int minPct;
  final int maxPct;
  final int stepPct;
  final void Function(int pct) onChanged;
  const QuickFontControls({
    super.key,
    this.minPct = 70,
    this.maxPct = 160,
    this.stepPct = 10,
    required this.onChanged,
  });

  /// Read the persisted value (defaults to 100). Call once on screen init
  /// to seed your local font scale before binding to this widget.
  static Future<int> readPersisted() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt('mcq_font_scale_pct') ?? 100;
  }

  @override
  State<QuickFontControls> createState() => _QuickFontControlsState();
}

class _QuickFontControlsState extends State<QuickFontControls> {
  int _pct = 100;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    QuickFontControls.readPersisted().then((v) {
      if (!mounted) return;
      setState(() { _pct = v; _loaded = true; });
      widget.onChanged(_pct);
    });
  }

  Future<void> _set(int v) async {
    final clamped = v.clamp(widget.minPct, widget.maxPct);
    setState(() => _pct = clamped);
    final p = await SharedPreferences.getInstance();
    await p.setInt('mcq_font_scale_pct', clamped);
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox(width: 80, height: 28);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SizeBtn(
            icon: Icons.text_decrease,
            tooltip: 'Smaller text',
            onTap: () => _set(_pct - widget.stepPct),
          ),
          GestureDetector(
            onTap: () => _set(100), // tap label = reset to default
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '$_pct%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ),
          _SizeBtn(
            icon: Icons.text_increase,
            tooltip: 'Larger text',
            onTap: () => _set(_pct + widget.stepPct),
          ),
        ],
      ),
    );
  }
}

class _SizeBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _SizeBtn({required this.icon, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        ),
      ),
    );
  }
}
