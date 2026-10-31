import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../utils/date_helpers.dart';

/// Simple in-memory store. Replace with a database / API later.
class TaskStore extends ChangeNotifier {
  final List<Task> _tasks = [];

  TaskStore() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _tasks.addAll([
      Task(
        id: '1',
        name: 'Making a website using html',
        subject: 'WebTech',
        priority: 'High',
        deadline: today,
      ),
      Task(
        id: '2',
        name: 'Program a Bank System using Java',
        subject: 'OOP',
        priority: 'Medium',
        deadline: today,
      ),
      Task(
        id: '3',
        name: 'Database ERD',
        subject: 'DBMS',
        priority: 'Low',
        deadline: today.add(const Duration(days: 3)),
      ),
    ]);
  }

  List<Task> get tasks {
    final copy = [..._tasks];
    copy.sort((a, b) => a.deadline.compareTo(b.deadline));
    return copy;
  }

  List<Task> forDate(DateTime d) =>
      tasks.where((t) => sameDay(t.deadline, d)).toList();

  void add(Task t) {
    _tasks.add(t);
    notifyListeners();
  }

  void update(
    Task t, {
    String? name,
    String? subject,
    String? priority,
    DateTime? deadline,
  }) {
    t.name = name ?? t.name;
    t.subject = subject ?? t.subject;
    t.priority = priority ?? t.priority;
    t.deadline = deadline ?? t.deadline;
    notifyListeners();
  }

  void toggle(Task t) {
    t.done = !t.done;
    notifyListeners();
  }

  void remove(Task t) {
    _tasks.remove(t);
    notifyListeners();
  }
}

/// Shared instance used across the app.
final taskStore = TaskStore();
