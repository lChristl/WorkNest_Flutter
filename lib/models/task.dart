class Task {
  final String id;
  String name;
  String subject;
  String priority; // Low, Medium, High
  DateTime deadline;
  bool done;

  // Group tasks only (null for personal tasks)
  final int? groupId;
  final String? groupName;
  final String status; // pending, submitted, approved, rejected

  Task({
    required this.id,
    required this.name,
    required this.subject,
    required this.priority,
    required this.deadline,
    this.done = false,
    this.groupId,
    this.groupName,
    this.status = 'pending',
  });

  bool get isGroup => groupId != null;

  factory Task.fromMap(Map<String, dynamic> m) {
    final group = m['project_groups'] as Map<String, dynamic>?;
    return Task(
      id: m['id'].toString(),
      name: m['name'] as String,
      subject: (m['subject'] as String?) ?? '',
      priority: m['priority'] as String,
      deadline: DateTime.parse(m['deadline'] as String),
      done: (m['done'] as bool?) ?? false,
      groupId: m['group_id'] as int?,
      groupName: group?['name'] as String?,
      status: (m['status'] as String?) ?? 'pending',
    );
  }
}