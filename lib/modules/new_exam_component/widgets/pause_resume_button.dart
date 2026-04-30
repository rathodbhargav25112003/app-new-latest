// ════════════════════════════════════════════════════════════════════
// PauseResumeButton — drop-in for the exam screen app bar
// ════════════════════════════════════════════════════════════════════
//
// Wires to the new /api/exam-attempt/:id/pause + /resume endpoints.
// Confirmation dialog on pause prevents fat-finger pauses on a small
// app bar tap target. After a successful pause the host typically
// pops back to the exam list; we expose a `onPaused` callback so
// behaviour stays customisable.

import 'package:flutter/material.dart';
import '../../../api_service/exam_attempt_api.dart';

class PauseResumeButton extends StatefulWidget {
  final String userExamId;
  final String currentStatus; // 'in_progress' | 'paused' | ...
  final VoidCallback? onPaused;
  final VoidCallback? onResumed;
  final ExamAttemptApi? api;

  const PauseResumeButton({
    super.key,
    required this.userExamId,
    required this.currentStatus,
    this.onPaused,
    this.onResumed,
    this.api,
  });

  @override
  State<PauseResumeButton> createState() => _PauseResumeButtonState();
}

class _PauseResumeButtonState extends State<PauseResumeButton> {
  bool _busy = false;
  late final ExamAttemptApi _api = widget.api ?? ExamAttemptApi();

  Future<void> _confirmPause() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pause this attempt?'),
        content: const Text(
          'Your progress is saved. You can resume from where you left off any time within 7 days.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep going')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pause')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await _api.pause(widget.userExamId);
      if (mounted) widget.onPaused?.call();
    } on ActiveSessionElsewhere catch (e) {
      _showError(context,
        'This attempt is open on another device. Close it there first, or wait '
        '${_minutesUntilStale(e.staleSinceMs)} for the lock to expire.');
    } catch (e) {
      _showError(context, 'Could not pause: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _doResume() async {
    setState(() => _busy = true);
    try {
      await _api.resume(widget.userExamId);
      if (mounted) widget.onResumed?.call();
    } on ActiveSessionElsewhere catch (e) {
      _showError(context,
        'Active on another device. Wait '
        '${_minutesUntilStale(e.staleSinceMs)} or close it there.');
    } catch (e) {
      _showError(context, 'Could not resume: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(BuildContext ctx, String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _minutesUntilStale(int? staleSinceMs) {
    if (staleSinceMs == null) return 'a few minutes';
    final remaining = (5 * 60 * 1000) - staleSinceMs;
    if (remaining <= 0) return '0 min';
    return '${(remaining / 60000).ceil()} min';
  }

  @override
  Widget build(BuildContext context) {
    final isPaused = widget.currentStatus == 'paused';
    return IconButton(
      onPressed: _busy ? null : (isPaused ? _doResume : _confirmPause),
      icon: _busy
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(isPaused ? Icons.play_arrow : Icons.pause),
      tooltip: isPaused ? 'Resume' : 'Pause',
    );
  }
}
