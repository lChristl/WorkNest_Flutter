import '../models/group_task.dart';
import 'supabase_client.dart';

class GroupTaskService {
  /// All tasks of one group.
  Future<List<GroupTask>> fetchGroupTasks(int groupId) async {
    final rows = await supabase
        .from('tasks')
        .select()
        .eq('group_id', groupId)
        .order('deadline');
    return rows.map<GroupTask>((r) => GroupTask.fromMap(r)).toList();
  }

  /// Lead assigns a task to a member (or to themselves).
  Future<void> assignTask({
    required int groupId,
    required String name,
    required String subject,
    required String priority,
    required DateTime deadline,
    required String assignedTo,
    required int percent,
  }) async {
    await supabase.from('tasks').insert({
      'group_id': groupId,
      'name': name,
      'subject': subject,
      'priority': priority,
      'deadline': deadline.toIso8601String().substring(0, 10),
      'assigned_to': assignedTo,
      'contribution_percent': percent,
    });
  }

  /// Lead deletes a group task.
  Future<void> deleteTask(int id) async {
    await supabase.from('tasks').delete().eq('id', id);
  }

  /// Member submits an accomplished task.
  Future<void> submitTask(int taskId, String? note) async {
    await supabase.rpc('submit_task', params: {
      'p_task_id': taskId,
      'p_note': (note == null || note.isEmpty) ? null : note,
    });
  }

  /// Lead approves or rejects a submitted task and sets the percentage.
  Future<void> reviewTask({
    required int taskId,
    required bool approve,
    required int percent,
    String? note,
  }) async {
    await supabase.rpc('review_task', params: {
      'p_task_id': taskId,
      'p_approve': approve,
      'p_percent': percent,
      'p_note': (note == null || note.isEmpty) ? null : note,
    });
  }
}

final groupTaskService = GroupTaskService();