import 'package:flutter/material.dart';

import '../../api_service/api_service.dart';
import '../../helpers/app_tokens.dart';
import 'skeleton.dart';
// Legacy imports preserved for API parity; no longer referenced by the UI.
// ignore: unused_import
import '../../helpers/colors.dart';

/// ResumeBanner — horizontal "Pick up where you left off" card strip on the
/// home screen. Renders the top-N items returned by GET /api/user/resume-list
/// (unified mix of videos + notes + exams the user last touched).
///
/// Empty/loading states are silent — we don't want to occupy vertical space
/// on the home screen if the user has no history. Render nothing instead.
class ResumeBanner extends StatefulWidget {
  const ResumeBanner({super.key, this.onItemTap});

  /// Fires with the raw API item (see /resume-list docs). The home screen
  /// decides how to route based on `type` ('video' / 'note' / 'exam').
  final void Function(Map<String, dynamic> item)? onItemTap;

  @override
  State<ResumeBanner> createState() => _ResumeBannerState();
}

class _ResumeBannerState extends State<ResumeBanner> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = const <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService().getResumeList(limit: 6);
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const <Map<String, dynamic>>[];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppTokens.s8),
        child: SkeletonCardRow(count: 3, height: 120, width: 240),
      );
    }
    if (_items.isEmpty) {
      // Silent empty state — don't reserve space.
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.s12, bottom: AppTokens.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: AppTokens.accent(context),
                ),
                const SizedBox(width: AppTokens.s8),
                Text(
                  'Pick up where you left off',
                  style: AppTokens.titleSm(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTokens.s12),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final item = _items[i];
                return _ResumeCard(
                  item: item,
                  onTap: () => widget.onItemTap?.call(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = (item['title'] ?? 'Untitled').toString();
    final thumb = (item['thumbnail'] ?? '').toString();
    final type = (item['type'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.r16),
          child: Container(
            width: 240,
            decoration: BoxDecoration(
              color: AppTokens.surface(context),
              borderRadius: BorderRadius.circular(AppTokens.r16),
              border: Border.all(color: AppTokens.border(context)),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTokens.r16),
                    bottomLeft: Radius.circular(AppTokens.r16),
                  ),
                  child: SizedBox(
                    width: 84,
                    height: double.infinity,
                    child: thumb.isNotEmpty
                        ? Image.network(
                            thumb,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _thumbFallback(context, type),
                          )
                        : _thumbFallback(context, type),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s12,
                      vertical: AppTokens.s8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTokens.body(context).copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTokens.accentSoft(context),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _typeIcon(type),
                                size: 12,
                                color: AppTokens.accent(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _typeLabel(type),
                                style: AppTokens.caption(context).copyWith(
                                  color: AppTokens.accent(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbFallback(BuildContext context, String type) {
    return Container(
      color: AppTokens.surface2(context),
      alignment: Alignment.center,
      child: Icon(
        _typeIcon(type),
        size: 28,
        color: AppTokens.ink2(context),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_outline;
      case 'note':
        return Icons.menu_book_outlined;
      case 'exam':
        return Icons.quiz_outlined;
      default:
        return Icons.history;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'video':
        return 'Video';
      case 'note':
        return 'Notes';
      case 'exam':
        return 'Exam';
      default:
        return 'Continue';
    }
  }
}
