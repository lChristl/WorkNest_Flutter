class Task {
  final String id;
  String name;
  String subject;
  String priority; // Low, Medium, High
  DateTime deadline;
  bool done;

  Task({
    required this.id,
    required this.name,
    required this.subject,
    required this.priority,
    required this.deadline,
    this.done = false,
  });
}
