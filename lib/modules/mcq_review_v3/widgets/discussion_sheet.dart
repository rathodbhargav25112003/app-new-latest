// DiscussionSheet — modal bottom sheet showing the community discussion
// for one MCQ. Top-level posts + 1-level replies, upvote toggle, post
// composer at bottom, "Top" / "New" sort.

import 'package:flutter/material.dart';

import '../../../models/mcq_review_models.dart';
import '../mcq_review_service.dart';

// Tiny relative-time formatter so we don't pull in `timeago` as a dependency.
// Returns strings like "just now", "5m", "3h", "2d", "4w" — short forms keep
// the post tile compact.
String _relativeTime(DateTime when) {
  final now = DateTime.now();
  final diff = now.difference(when);
  if (diff.isNegative) return 'just now';
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
  return '${(diff.inDays / 365).floor()}y';
}

class DiscussionSheet extends StatefulWidget {
  final String questionId;
  const DiscussionSheet({super.key, required this.questionId});

  static Future<void> show(BuildContext context, {required String questionId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DiscussionSheet(questionId: questionId),
        ),
      ),
    );
  }

  @override
  State<DiscussionSheet> createState() => _DiscussionSheetState();
}

class _DiscussionSheetState extends State<DiscussionSheet> {
  final _service = McqReviewService();
  final _composerCtrl = TextEditingController();
  String _sort = 'top';
  String? _replyToId;
  String? _replyToPreview;
  List<DiscussionPost> _posts = [];
  bool _loading = true;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _composerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _service.getThread(widget.questionId, sort: _sort);
    if (!mounted) return;
    setState(() {
      _posts = (res['posts'] as List).cast<DiscussionPost>();
      _loading = false;
    });
  }

  Future<void> _send() async {
    final content = _composerCtrl.text.trim();
    if (content.isEmpty) return;
    setState(() => _posting = true);
    final post = await _service.createPost(widget.questionId, content, parentPostId: _replyToId);
    if (post != null) {
      _composerCtrl.clear();
      _replyToId = null;
      _replyToPreview = null;
      await _load();
    }
    if (mounted) setState(() => _posting = false);
  }

  Future<void> _toggleUpvote(DiscussionPost p) async {
    final res = await _service.toggleUpvote(p.id);
    if (!mounted) return;
    setState(() {
      final i = _posts.indexWhere((x) => x.id == p.id);
      if (i != -1) {
        _posts[i] = _posts[i].copyWith(
          upvoteCount: res['upvote_count'] as int? ?? 0,
          didIUpvote: res['upvoted'] == true,
        );
      }
    });
  }

  Future<void> _report(DiscussionPost p) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report this post'),
        content: const Text('Reason: spam, harassment, off-topic, factually wrong?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, 'spam'), child: const Text('Spam')),
          TextButton(onPressed: () => Navigator.pop(context, 'wrong'), child: const Text('Factually wrong')),
        ],
      ),
    );
    if (reason != null) {
      await _service.reportPost(p.id, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks — moderators notified.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Header
          Row(children: [
            Icon(Icons.forum, color: scheme.primary),
            const SizedBox(width: 8),
            const Text('Discussion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const Spacer(),
            DropdownButton<String>(
              value: _sort,
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'top', child: Text('Top', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'new', child: Text('New', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (v) {
                setState(() => _sort = v ?? 'top');
                _load();
              },
            ),
          ]),
          // Posts
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _posts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.forum_outlined, size: 36, color: scheme.onSurface.withOpacity(0.3)),
                              const SizedBox(height: 8),
                              Text('No discussion yet', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface.withOpacity(0.6))),
                              const SizedBox(height: 4),
                              Text(
                                'Be the first to ask or share insight.',
                                style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.4)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _posts.length,
                        separatorBuilder: (_, __) => const Divider(height: 16),
                        itemBuilder: (_, i) => _PostTile(
                          post: _posts[i],
                          onUpvote: () => _toggleUpvote(_posts[i]),
                          onReply: () => setState(() {
                            _replyToId = _posts[i].id;
                            _replyToPreview = _posts[i].content.length > 60
                                ? '${_posts[i].content.substring(0, 60)}…'
                                : _posts[i].content;
                          }),
                          onReport: () => _report(_posts[i]),
                        ),
                      ),
          ),
          // Composer
          if (_replyToPreview != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(children: [
                const Icon(Icons.reply, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Replying: $_replyToPreview',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() {
                    _replyToId = null;
                    _replyToPreview = null;
                  }),
                ),
              ]),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _composerCtrl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: _replyToId != null ? 'Write a reply…' : 'Share insight or ask…',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _posting ? null : _send,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _posting ? scheme.outline : scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _posting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  final DiscussionPost post;
  final VoidCallback onUpvote;
  final VoidCallback onReply;
  final VoidCallback onReport;
  const _PostTile({required this.post, required this.onUpvote, required this.onReply, required this.onReport});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String _ago = '';
    try { _ago = post.createdAt != null ? _relativeTime(post.createdAt!) : ''; } catch (_) {}
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (post.isInstructor) Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Instructor', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.indigo)),
              ),
              if (post.isAcceptedAnswer) ...[
                if (post.isInstructor) const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('✓ Accepted', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.green)),
                ),
              ],
              const Spacer(),
              if (_ago.isNotEmpty)
                Text(_ago, style: TextStyle(fontSize: 9, color: scheme.onSurface.withOpacity(0.5))),
            ],
          ),
          const SizedBox(height: 4),
          Text(post.content, style: const TextStyle(fontSize: 13, height: 1.4)),
          if (post.isEdited) Text('(edited)', style: TextStyle(fontSize: 9, color: scheme.onSurface.withOpacity(0.4), fontStyle: FontStyle.italic)),
          const SizedBox(height: 4),
          Row(
            children: [
              InkWell(
                onTap: onUpvote,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(children: [
                    Icon(
                      post.didIUpvote ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 14,
                      color: post.didIUpvote ? scheme.primary : scheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 3),
                    Text('${post.upvoteCount}', style: TextStyle(fontSize: 11, color: post.didIUpvote ? scheme.primary : scheme.onSurface.withOpacity(0.6))),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onReply,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(children: [
                    Icon(Icons.reply, size: 14, color: scheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 3),
                    Text('Reply${post.replyCount > 0 ? ' · ${post.replyCount}' : ''}', style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.6))),
                  ]),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onReport,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.flag_outlined, size: 13, color: scheme.onSurface.withOpacity(0.4)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
