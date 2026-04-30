import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// AppCachedImage — opinionated wrapper around [CachedNetworkImage].
///
/// Replace any `Image.network(url)` call with:
/// ```dart
/// AppCachedImage(url: url, height: 80, width: 80)
/// ```
///
/// Benefits:
///  • Persistent disk cache survives app restart.
///  • No flicker on rebuild (in-memory cache).
///  • Skeleton-style soft placeholder while loading.
///  • Token-anchored fallback when the URL is empty / errors out.
class AppCachedImage extends StatelessWidget {
  const AppCachedImage({
    Key? key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
  }) : super(key: key);

  final String? url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _wrapRadius(_fallbackBox(context));
    }
    return _wrapRadius(
      CachedNetworkImage(
        imageUrl: url!,
        height: height,
        width: width,
        fit: fit,
        placeholder: (_, __) => _placeholder(context),
        errorWidget: (_, __, ___) => _fallbackBox(context),
        fadeInDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  Widget _wrapRadius(Widget child) {
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _placeholder(BuildContext ctx) => Container(
        height: height,
        width: width,
        color: AppTokens.surface2(ctx),
      );

  Widget _fallbackBox(BuildContext ctx) {
    if (fallback != null) return fallback!;
    return Container(
      height: height,
      width: width,
      color: AppTokens.surface2(ctx),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppTokens.muted(ctx),
        size: 24,
      ),
    );
  }
}
