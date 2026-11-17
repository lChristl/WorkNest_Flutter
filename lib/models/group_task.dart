class GroupTask {
  final int id;
  final String name;
  final String subject;
  final String priority;
  final DateTime deadline;
  final String status; // pending, submitted, approved, rejected
  final int percent;
  final String? assignedTo;
  final String? submissionNote;
  final String? reviewNote;

  GroupTask({
    required this.id,
    required this.name,
    required this.subject,
    required this.priority,
    required this.deadline,
    required this.status,
    required this.percent,
    this.assignedTo,
    this.submissionNote,
    this.reviewNote,
  });

  factory GroupTask.fromMap(Map<String, dynamic> m) => GroupTask(
        id: m['id'] as int,
        name: m['name'] as String,
        subject: (m['subject'] as String?) ?? '',
        priority: m['priority'] as String,
        deadline: DateTime.parse(m['deadline'] as String),
        status: m['status'] as String,
        percent: (m['contribution_percent'] as num).toInt(),
        assignedTo: m['assigned_to'] as String?,
        submissionNote: m['submission_note'] as String?,
        reviewNote: m['review_note'] as String?,
      );
}