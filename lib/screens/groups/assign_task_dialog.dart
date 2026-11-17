import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/group.dart';
import '../../models/group_member.dart';
import '../../services/group_task_service.dart';
import '../../services/supabase_client.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_helpers.dart';

/// Returns true if a task was created.
class AssignTaskDialog extends StatefulWidget {
  final Group group;
  final List<GroupMember> members;
  const AssignTaskDialog({
    super.key,
    required this.group,
    required this.members,
  });

  @override
  State<AssignTaskDialog> createState() => _AssignTaskDialogState();
}

class _AssignTaskDialogState extends State<AssignTaskDialog> {
  final _name = TextEditingController();
  final _subject = TextEditingController();
  final _percent = TextEditingController(text: '0');
  String _priority = 'Medium';
  String? _assignedTo;
  DateTime? _deadline;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Default: assign to myself
    final myId = supabase.auth.currentUser?.id;
    if (widget.members.any((m) => m.userId == myId)) {
      _assignedTo = myId;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _subject.dispose();
    _percent.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    final percent = int.tryParse(_percent.text.trim());

    if (_name.text.trim().isEmpty ||
        _deadline == null ||
        _assignedTo == null) {
      setState(() => _error = 'Task name, assignee and deadline are required');
      return;
    }
    if (percent == null || percent < 0 || percent > 100) {
      setState(() => _error = 'Percentage must be a number from 0 to 100');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await groupTaskService.assignTask(
        groupId: widget.group.id,
        name: _name.text.trim(),
        subject: _subject.text.trim(),
        priority: _priority,
        deadline: _deadline!,
        assignedTo: _assignedTo!,
        percent: percent,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          s,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
      );

  InputDecoration _decoration({String? hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser?.id;

    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Assign Task',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
            ),
            _label('Task name:'),
            TextField(controller: _name, decoration: _decoration()),
            _label('Subject:'),
            TextField(controller: _subject, decoration: _decoration()),
            _label('Assign to:'),
            DropdownButtonFormField<String>(
              value: _assignedTo,
              isExpanded: true,
              decoration: _decoration(hint: 'Select a member'),
              borderRadius: BorderRadius.circular(14),
              items: widget.members
                  .map((m) => DropdownMenuItem(
                        value: m.userId,
                        child: Text(
                          m.userId == myId ? '${m.username} (me)' : m.username,
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _assignedTo = v),
            ),
            _label('Priority:'),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: _decoration(),
              borderRadius: BorderRadius.circular(14),
              items: const ['Low', 'Medium', 'High']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _priority = v ?? _priority),
            ),
            _label('Contribution percentage (0-100):'),
            TextField(
              controller: _percent,
              keyboardType: TextInputType.number,
              decoration: _decoration(hint: 'e.g. 25'),
            ),
            _label('Deadline:'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _deadline == null
                            ? 'Select date'
                            : formatDate(_deadline!),
                        style: TextStyle(
                          color: _deadline == null
                              ? Colors.grey[600]
                              : AppColors.dark,
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_today,
                        size: 18, color: AppColors.dark),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(_saving ? 'Saving...' : 'Assign'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}