import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../utils/date_helpers.dart';
import 'supabase_client.dart';

String _dateOnly(DateTime d) => d.toIso8601String().substring(0, 10);

/// My personal tasks + group tasks assigned to me, saved in Supabase.
class TaskStore extends ChangeNotifier {
  List<Task> _tasks = [];

  List<Task> get tasks {
    final copy = [..._tasks];
    copy.sort((a, b) => a.deadline.compareTo(b.deadline));
    return copy;
  }

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
      notifyListeners();
    } catch (e) {
      debugPrint('LOAD TASKS ERROR: $e');
    }
  }

  /// Forget everything (used on log out).
  void clear() {
    _tasks = [];
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