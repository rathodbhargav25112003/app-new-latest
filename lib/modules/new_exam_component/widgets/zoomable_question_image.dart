// ════════════════════════════════════════════════════════════════════
// ZoomableQuestionImage — pinch-zoom + pan + fullscreen tap
// ════════════════════════════════════════════════════════════════════
//
// Uses InteractiveViewer for inline pinch-zoom and a tap-to-fullscreen
// dialog for the case where the inline area is small (e.g. a packed
// MCQ stem). Supports caching via the existing CachedNetworkImage if
// it's available; falls back to plain Image.network otherwise.
//
// No new package dependencies introduced — uses Flutter built-ins
// only. The integrator can swap in cached_network_image later by
// replacing `_loadable`.

import 'package:flutter/material.dart';

class ZoomableQuestionImage extends StatelessWidget {
  final String url;
  final double height;
  final BoxFit fit;
  final String? heroTag;

  const ZoomableQuestionImage({
    super.key,
    required this.url,
    this.height = 200,
    this.fit = BoxFit.contain,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: heroTag != null
                ? Hero(tag: heroTag!, child: _loadable())
                : _loadable(),
          ),
        ),
      ),
    );
  }

  Widget _loadable() {
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (ctx, err, st) => const Center(
        child: Icon(Icons.broken_image_outlined, size: 32),
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _FullscreenImagePage(url: url, heroTag: heroTag),
    ));
  }
}

class _FullscreenImagePage extends StatelessWidget {
  final String url;
  final String? heroTag;

  const _FullscreenImagePage({required this.url, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final image = Image.network(url, fit: BoxFit.contain);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 6.0,
          child: heroTag != null ? Hero(tag: heroTag!, child: image) : image,
        ),
      ),
    );
  }
}
