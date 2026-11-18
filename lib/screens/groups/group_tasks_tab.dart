import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/task_store.dart';

import '../../models/group.dart';
import '../../models/group_member.dart';
import '../../models/group_task.dart';
import '../../services/group_service.dart';
import '../../services/group_task_service.dart';
import '../../services/supabase_client.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_helpers.dart';
import 'assign_task_dialog.dart';
import 'task_action_dialogs.dart';

class GroupTasksTab extends StatefulWidget {
  final Group group;
  const GroupTasksTab({super.key, required this.group});

  @override
  State<GroupTasksTab> createState() => _GroupTasksTabState();
}

class _GroupTasksTabState extends State<GroupTasksTab> {
  List<GroupTask> _tasks = [];
  List<GroupMember> _members = [];
  Map<String, String> _names = {};
  bool _loading = true;
  String? _error;

  Group get group => widget.group;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final members = await groupService.fetchMembers(group.id);
      final tasks = await groupTaskService.fetchGroupTasks(group.id);
      if (!mounted) return;
      setState(() {
        _members = members;
        _names = {for (final m in members) m.userId: m.username};
        _tasks = tasks;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      debugPrint('LOAD GROUP TASKS ERROR: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Could not load tasks.\n$e';
        _loading = false;
      });
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _assign() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => AssignTaskDialog(group: group, members: _members),
    );
    if (created == true) {
      _showMessage('Task assigned');
      await _load();
    }
  }

  Future<void> _delete(GroupTask t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete task'),
        content: Text('Delete "${t.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await groupTaskService.deleteTask(t.id);
      await _load();
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  Future<void> _submit(GroupTask t) async {
    final note = await showSubmitDialog(context, t);
    if (note == null) return;

    try {
      await groupTaskService.submitTask(t.id, note);
      _showMessage('Task submitted for review');
      await _load();
      taskStore.load();
    } on PostgrestException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  Future<void> _review(GroupTask t) async {
    final result =
        await showReviewDialog(context, t, _names[t.assignedTo] ?? 'Unknown');
    if (result == null) return;

    try {
      await groupTaskService.reviewTask(
        taskId: t.id,
        approve: result.approve,
        percent: result.percent,
        note: result.note,
      );
      _showMessage(result.approve ? 'Task approved' : 'Task rejected');
      await _load();
      taskStore.load();
    } on PostgrestException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'submitted':
        return const Color(0xFFE8CF85);
      case 'approved':
        return AppColors.header;
      case 'rejected':
        return const Color(0xFFDE9A8E);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _tasks.fold<int>(0, (sum, t) => sum + t.percent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
            ),
            if (group.isLead)
              ElevatedButton(
                onPressed: _loading ? null : _assign,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.header,
                  foregroundColor: AppColors.text,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  '+ Assign task',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        if (!_loading && _error == null && _tasks.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            total > 100
                ? 'Total assigned: $total% (over 100%)'
                : 'Total assigned: $total%',
            style: TextStyle(
              fontSize: 12,
              color: total > 100 ? Colors.redAccent : AppColors.dark,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    if (_tasks.isEmpty) {
      return Center(
        child: Text(
          group.isLead
              ? 'No tasks yet.\nTap "+ Assign task" to create one.'
              : 'No tasks have been assigned yet.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final myId = supabase.auth.currentUser?.id;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (_, i) {
          final t = _tasks[i];
          final assignee = _names[t.assignedTo] ?? 'Unknown';
          final canSubmit = t.assignedTo == myId &&
              (t.status == 'pending' || t.status == 'rejected');
          final canReview = group.isLead && t.status == 'submitted';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dark, width: 1.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.dark,
                              ),
                            ),
                            if (t.subject.isNotEmpty)
                              Text(t.subject,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.dark)),
                            const SizedBox(height: 4),
                            Text('Assigned to: $assignee',
                                style: const TextStyle(fontSize: 12)),
                            Text(
                              'Due ${formatDate(t.deadline)}  •  ${t.percent}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(t.status),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: AppColors.dark, width: 0.8),
                            ),
                            child: Text(
                              t.status,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (group.isLead) ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => _delete(t),
                              child: const Icon(Icons.delete,
                                  size: 20, color: AppColors.dark),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  if ((t.submissionNote ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Submission note: ${t.submissionNote}',
                        style: const TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                  if ((t.reviewNote ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Lead feedback: ${t.reviewNote}',
                        style: const TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                  if (canSubmit || canReview) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => canReview ? _review(t) : _submit(t),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dark,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(
                          canReview
                              ? 'Review'
                              : (t.status == 'rejected'
                                  ? 'Resubmit'
                                  : 'Submit'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
