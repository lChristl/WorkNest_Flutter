import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_store.dart';
import '../theme/app_colors.dart';
import '../utils/date_helpers.dart';

/// Opens the "New Task" dialog (or "Edit Task" when [existing] is given).
Future<void> showTaskDialog(BuildContext context, {Task? existing}) {
  return showDialog(
    context: context,
    builder: (_) => TaskDialog(existing: existing),
  );
}

class TaskDialog extends StatefulWidget {
  final Task? existing;
  const TaskDialog({super.key, this.existing});

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late final TextEditingController _name;
  late final TextEditingController _subject;
  late String _priority;
  DateTime? _deadline;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _name = TextEditingController(text: t?.name ?? '');
    _subject = TextEditingController(text: t?.subject ?? '');
    _priority = t?.priority ?? 'Medium';
    _deadline = t?.deadline;
  }

  @override
  void dispose() {
    _name.dispose();
    _subject.dispose();
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

  void _submit() {
    if (_name.text.trim().isEmpty || _deadline == null) {
      setState(() => _error = 'Task name and deadline are required');
      return;
    }
    final t = widget.existing;
    if (t == null) {
      taskStore.add(Task(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        subject: _subject.text.trim(),
        priority: _priority,
        deadline: _deadline!,
      ));
    } else {
      taskStore.update(
        t,
        name: _name.text.trim(),
        subject: _subject.text.trim(),
        priority: _priority,
        deadline: _deadline,
      );
    }
    Navigator.of(context).pop();
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

  InputDecoration _decoration() => InputDecoration(
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

  Widget _dialogButton(String label, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Center(
              child: Text(
                _editing ? 'Edit Task' : 'New Task',
                style: const TextStyle(
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
                _dialogButton(_editing ? 'Save' : 'Add', _submit),
                const SizedBox(width: 10),
                _dialogButton('Cancel', () => Navigator.of(context).pop()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
