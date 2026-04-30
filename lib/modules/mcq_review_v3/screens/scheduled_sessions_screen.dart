// ScheduledSessionsScreen — list + create recurring "Cortex tutor session"
// reminders. Each session: kind + topic + days-of-week + time. Cron
// worker on the server fires push notifications at scheduled times.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../models/mcq_review_models.dart';
import '../mcq_review_service.dart';

class ScheduledSessionsScreen extends StatefulWidget {
  const ScheduledSessionsScreen({super.key});
  static Route<dynamic> route(RouteSettings settings) =>
      CupertinoPageRoute(builder: (_) => const ScheduledSessionsScreen());
  @override
  State<ScheduledSessionsScreen> createState() => _ScheduledSessionsScreenState();
}

class _ScheduledSessionsScreenState extends State<ScheduledSessionsScreen> {
  final _service = McqReviewService();
  List<ScheduledSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.listScheduledSessions();
    if (!mounted) return;
    setState(() {
      _sessions = list;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final result = await showModalBottomSheet<ScheduledSession?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateSheet(),
    );
    if (result != null) await _load();
  }

  Future<void> _toggleStatus(ScheduledSession s) async {
    await _service.updateScheduledSession(s.id, {
      'status': s.status == 'active' ? 'paused' : 'active',
    });
    await _load();
  }

  Future<void> _delete(ScheduledSession s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: const Text('Cancel this scheduled session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await _service.deleteScheduledSession(s.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Scheduled Sessions'),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('New session'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _sessions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, size: 48, color: scheme.onSurface.withOpacity(0.3)),
                        const SizedBox(height: 10),
                        const Text('No sessions scheduled', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          'Schedule daily tutor sessions and Cortex will ping you at the right time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _SessionTile(
                    session: _sessions[i],
                    onToggle: () => _toggleStatus(_sessions[i]),
                    onDelete: () => _delete(_sessions[i]),
                  ),
                ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ScheduledSession session;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  const _SessionTile({required this.session, required this.onToggle, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = session.status == 'active';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? scheme.primary.withOpacity(0.3) : scheme.outline.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(_kindIcon(session.kind), color: active ? scheme.primary : scheme.onSurface.withOpacity(0.4), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_kindLabel(session.kind) + (session.topic.isNotEmpty ? ' · ${session.topic}' : ''),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  '${_daysText(session.daysOfWeek)} · ${session.timeOfDay} · ${session.estimatedMinutes} min',
                  style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          Switch(value: active, onChanged: (_) => onToggle()),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 18)),
        ],
      ),
    );
  }

  IconData _kindIcon(String k) {
    switch (k) {
      case 'topic_deep_dive': return Icons.menu_book_outlined;
      case 'osce_viva': return Icons.local_hospital_outlined;
      case 'review_queue': return Icons.repeat;
      case 'mock_exam': return Icons.assignment_turned_in_outlined;
      default: return Icons.schedule;
    }
  }

  String _kindLabel(String k) {
    switch (k) {
      case 'topic_deep_dive': return '🔍 Deep dive';
      case 'osce_viva': return '🩺 OSCE viva';
      case 'review_queue': return '🔁 Review queue';
      case 'mock_exam': return '📝 Mock exam';
      default: return k;
    }
  }

  String _daysText(List<int> dows) {
    if (dows.isEmpty) return 'One-time';
    if (dows.length == 7) return 'Every day';
    if (dows.length == 5 && dows.toSet().difference({0, 6}).length == 5) return 'Weekdays';
    if (dows.length == 2 && dows.toSet().intersection({0, 6}).length == 2) return 'Weekends';
    final names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return dows.map((d) => names[d]).join(' · ');
  }
}

class _CreateSheet extends StatefulWidget {
  const _CreateSheet();
  @override
  State<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends State<_CreateSheet> {
  String _kind = 'topic_deep_dive';
  String _topic = '';
  Set<int> _dows = {1, 2, 3, 4, 5}; // Mon-Fri
  String _time = '19:00';
  int _minutes = 15;
  bool _busy = false;

  Future<void> _save() async {
    if (_topic.isEmpty && (_kind == 'topic_deep_dive' || _kind == 'osce_viva')) return;
    setState(() => _busy = true);
    final s = await McqReviewService().createScheduledSession(
      kind: _kind,
      topic: _topic.isEmpty ? null : _topic,
      daysOfWeek: _dows.toList()..sort(),
      timeOfDay: _time,
      estimatedMinutes: _minutes,
    );
    if (mounted) Navigator.pop(context, s);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked != null) {
      setState(() => _time = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New session', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _kind,
            decoration: const InputDecoration(labelText: 'Kind'),
            items: const [
              DropdownMenuItem(value: 'topic_deep_dive', child: Text('🔍 Topic deep-dive')),
              DropdownMenuItem(value: 'osce_viva', child: Text('🩺 OSCE viva')),
              DropdownMenuItem(value: 'review_queue', child: Text('🔁 Review queue')),
              DropdownMenuItem(value: 'mock_exam', child: Text('📝 Mock exam')),
            ],
            onChanged: (v) => setState(() => _kind = v ?? 'topic_deep_dive'),
          ),
          if (_kind == 'topic_deep_dive' || _kind == 'osce_viva') ...[
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Topic (e.g., obstructive jaundice)'),
              onChanged: (v) => setState(() => _topic = v),
            ),
          ],
          const SizedBox(height: 12),
          const Text('Days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: List.generate(7, (i) {
              final names = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
              final selected = _dows.contains(i);
              return InkWell(
                onTap: () => setState(() => selected ? _dows.remove(i) : _dows.add(i)),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(names[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: selected ? Colors.white : Theme.of(context).colorScheme.primary)),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Time:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _pickTime, child: Text(_time)),
            const Spacer(),
            const Text('Length:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _minutes,
              items: const [
                DropdownMenuItem(value: 10, child: Text('10 min')),
                DropdownMenuItem(value: 15, child: Text('15 min')),
                DropdownMenuItem(value: 30, child: Text('30 min')),
                DropdownMenuItem(value: 60, child: Text('60 min')),
              ],
              onChanged: (v) => setState(() => _minutes = v ?? 15),
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _save,
              child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Schedule'),
            ),
          ),
        ],
      ),
    );
  }
}
