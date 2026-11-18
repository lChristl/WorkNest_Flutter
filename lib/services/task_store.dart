import 'package:flutter/foundation.dart';

import '../models/review_item.dart';
import '../models/task.dart';
import '../utils/date_helpers.dart';
import 'reminder_service.dart';
import 'supabase_client.dart';

String _dateOnly(DateTime d) => d.toIso8601String().substring(0, 10);

/// My personal tasks + group tasks assigned to me + tasks I must review.
class TaskStore extends ChangeNotifier {
  List<Task> _tasks = [];
  List<ReviewItem> _reviewQueue = [];

  List<Task> get tasks {
    final copy = [..._tasks];
    copy.sort((a, b) => a.deadline.compareTo(b.deadline));
    return copy;
  }

  List<ReviewItem> get reviewQueue => [..._reviewQueue];

  /// Everything that needs the user's attention.
  Reminders get reminders => computeReminders(tasks, reviewQueue);

  List<Task> forDate(DateTime d) =>
      tasks.where((t) => sameDay(t.deadline, d)).toList();

  Future<void> load() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final rows = await supabase
          .from('tasks')
          .select('*, project_groups(name)')
          .or('group_id.is.null,assigned_to.eq.$uid')
          .order('deadline');
      _tasks = rows.map<Task>((r) => Task.fromMap(r)).toList();
    } catch (e) {
      debugPrint('LOAD TASKS ERROR: $e');
    }

    await _loadReviewQueue(uid);
    notifyListeners();
  }

  /// Submitted tasks in groups where I am the lead.
  Future<void> _loadReviewQueue(String uid) async {
    try {
      final leadRows = await supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', uid)
          .eq('role', 'lead');
      final groupIds =
          leadRows.map<int>((r) => r['group_id'] as int).toList();

      if (groupIds.isEmpty) {
        _reviewQueue = [];
        return;
      }

      final rows = await supabase
          .from('tasks')
          .select(
              'id, name, group_id, assigned_to, submission_note, project_groups(name)')
          .inFilter('group_id', groupIds)
          .eq('status', 'submitted')
          .order('submitted_at');

      final assigneeIds = rows
          .map((r) => r['assigned_to'])
          .whereType<String>()
          .toSet()
          .toList();

      final names = <String, String>{};
      if (assigneeIds.isNotEmpty) {
        final profiles = await supabase
            .from('profiles')
            .select('id, username')
            .inFilter('id', assigneeIds);
        for (final p in profiles) {
          names[p['id'] as String] = p['username'] as String;
        }
      }

      _reviewQueue = rows.map<ReviewItem>((r) {
        final g = r['project_groups'] as Map<String, dynamic>?;
        return ReviewItem(
          taskId: r['id'] as int,
          taskName: r['name'] as String,
          groupId: r['group_id'] as int,
          groupName: (g?['name'] as String?) ?? 'Group',
          assigneeName: names[r['assigned_to']] ?? 'A member',
          note: r['submission_note'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('LOAD REVIEW QUEUE ERROR: $e');
    }
  }

  /// Forget everything (used on log out).
  void clear() {
    _tasks = [];
    _reviewQueue = [];
    notifyListeners();
  }

  Future<void> add(Task t) async {
    try {
      await supabase.from('tasks').insert({
        'name': t.name,
        'subject': t.subject,
        'priority': t.priority,
        'deadline': _dateOnly(t.deadline),
      });
    } catch (e) {
      debugPrint('ADD TASK ERROR: $e');
    }
    await load();
  }

  Future<void> update(
    Task t, {
    String? name,
    String? subject,
    String? priority,
    DateTime? deadline,
  }) async {
    if (t.isGroup) return; // group tasks are managed by the lead
    try {
      await supabase.from('tasks').update({
        if (name != null) 'name': name,
        if (subject != null) 'subject': subject,
        if (priority != null) 'priority': priority,
        if (deadline != null) 'deadline': _dateOnly(deadline),
      }).eq('id', t.id);
    } catch (e) {
      debugPrint('UPDATE TASK ERROR: $e');
    }
    await load();
  }

  Future<void> toggle(Task t) async {
    if (t.isGroup) return; // group tasks become done when the lead approves
    t.done = !t.done;
    notifyListeners();
    try {
      await supabase.from('tasks').update({'done': t.done}).eq('id', t.id);
    } catch (e) {
      debugPrint('TOGGLE TASK ERROR: $e');
      await load();
    }
  }

  Future<void> remove(Task t) async {
    if (t.isGroup) return;
    _tasks.remove(t);
    notifyListeners();
    try {
      await supabase.from('tasks').delete().eq('id', t.id);
    } catch (e) {
      debugPrint('DELETE TASK ERROR: $e');
      await load();
    }
  }
}

/// Shared instance used across the app.
final taskStore = TaskStore();