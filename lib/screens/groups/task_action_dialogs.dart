import 'package:flutter/material.dart';

import '../../models/group_task.dart';
import '../../theme/app_colors.dart';

InputDecoration _decoration(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );

ButtonStyle _darkButton() => ElevatedButton.styleFrom(
      backgroundColor: AppColors.dark,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );

// ───────────── Submit dialog (member) ─────────────

/// Returns the note (may be empty), or null if cancelled.
Future<String?> showSubmitDialog(BuildContext context, GroupTask task) {
  return showDialog<String>(
    context: context,
    builder: (_) => _SubmitDialog(task: task),
  );
}

class _SubmitDialog extends StatefulWidget {
  final GroupTask task;
  const _SubmitDialog({required this.task});

  @override
  State<_SubmitDialog> createState() => _SubmitDialogState();
}

class _SubmitDialogState extends State<_SubmitDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Submit task'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              minLines: 3,
              maxLines: 3,
              decoration: _decoration('Note about what you did (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: _darkButton(),
          onPressed: () => Navigator.of(context).pop(_note.text.trim()),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

// ───────────── Review dialog (lead) ─────────────

class ReviewResult {
  final bool approve;
  final int percent;
  final String note;
  ReviewResult(this.approve, this.percent, this.note);
}

/// Returns the lead's decision, or null if cancelled.
Future<ReviewResult?> showReviewDialog(
  BuildContext context,
  GroupTask task,
  String assigneeName,
) {
  return showDialog<ReviewResult>(
    context: context,
    builder: (_) => _ReviewDialog(task: task, assigneeName: assigneeName),
  );
}

class _ReviewDialog extends StatefulWidget {
  final GroupTask task;
  final String assigneeName;
  const _ReviewDialog({required this.task, required this.assigneeName});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late final TextEditingController _percent;
  final _note = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _percent = TextEditingController(text: widget.task.percent.toString());
  }

  @override
  void dispose() {
    _percent.dispose();
    _note.dispose();
    super.dispose();
  }

  void _decide(bool approve) {
    final percent = int.tryParse(_percent.text.trim());
    if (percent == null || percent < 0 || percent > 100) {
      setState(() => _error = 'Percentage must be a number from 0 to 100');
      return;
    }
    Navigator.of(context)
        .pop(ReviewResult(approve, percent, _note.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Review task'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Submitted by ${widget.assigneeName}',
                style: const TextStyle(fontSize: 12),
              ),
              if ((t.submissionNote ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Their note: ${t.submissionNote}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              const SizedBox(height: 14),
              const Text(
                'Contribution percentage (0-100):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _percent,
                keyboardType: TextInputType.number,
                decoration: _decoration('e.g. 25'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Feedback (optional):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 2,
                decoration: _decoration('Write feedback for the member'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              style: _darkButton(),
              onPressed: () => _decide(false),
              child: const Text('Reject'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.header,
                foregroundColor: AppColors.text,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => _decide(true),
              child: const Text('Approve'),
            ),
          ],
        ),
      ],
    );
  }
}