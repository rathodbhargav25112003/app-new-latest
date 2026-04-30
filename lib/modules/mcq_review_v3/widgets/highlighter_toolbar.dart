// HighlighterToolbar — 4-color toolbar shown when the highlighter is
// active. Tap a color → activates highlighting in that color. Tap the
// X to deactivate. Tap eraser to clear-on-tap mode.
//
// The actual text-painting still happens in the existing Quill editor
// (already supports background-color attribute). This widget just
// surfaces the controls.

import 'package:flutter/material.dart';

class HighlighterToolbar extends StatelessWidget {
  final String? activeColor;       // 'yellow' | 'blue' | 'pink' | 'green' | null
  final bool eraserMode;
  final void Function(String? color) onSelectColor;
  final VoidCallback onToggleEraser;
  final VoidCallback onClose;

  const HighlighterToolbar({
    super.key,
    required this.activeColor,
    required this.eraserMode,
    required this.onSelectColor,
    required this.onToggleEraser,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSlide(
      offset: Offset.zero,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: scheme.outline.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.format_color_fill, size: 14, color: scheme.onSurface.withOpacity(0.5)),
            const SizedBox(width: 6),
            for (final col in const ['yellow', 'blue', 'pink', 'green'])
              _SwatchButton(
                color: _colorOf(col),
                selected: activeColor == col && !eraserMode,
                onTap: () => onSelectColor(col),
              ),
            const SizedBox(width: 4),
            // Eraser
            _IconButton(
              icon: Icons.cleaning_services_outlined,
              selected: eraserMode,
              onTap: onToggleEraser,
              tooltip: 'Eraser',
            ),
            // Close
            _IconButton(
              icon: Icons.close,
              onTap: onClose,
              tooltip: 'Close',
            ),
          ],
        ),
      ),
    );
  }

  Color _colorOf(String c) {
    switch (c) {
      case 'yellow': return const Color(0xFFFFF59D);
      case 'blue':   return const Color(0xFFB3E5FC);
      case 'pink':   return const Color(0xFFF8BBD0);
      case 'green':  return const Color(0xFFC8E6C9);
      default:       return Colors.transparent;
    }
  }
}

class _SwatchButton extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _SwatchButton({required this.color, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? Colors.black87 : Colors.black.withOpacity(0.1),
              width: selected ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String tooltip;
  const _IconButton({required this.icon, this.selected = false, required this.onTap, required this.tooltip});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 28, height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? scheme.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 14, color: selected ? scheme.primary : scheme.onSurface.withOpacity(0.5)),
        ),
      ),
    );
  }
}
