import '../models/review_item.dart';
import '../models/task.dart';

class Reminders {
  final List<ReviewItem> reviews; // submitted tasks the lead must review
  final List<Task> rejected; // group tasks the lead sent back
  final List<Task> overdue;
  final List<Task> today;
  final List<Task> tomorrow;

  Reminders({
    required this.reviews,
    required this.rejected,
    required this.overdue,
    required this.today,
    required this.tomorrow,
  });

  int get count =>
      reviews.length +
      rejected.length +
      overdue.length +
      today.length +
      tomorrow.length;
}

bool _finished(Task t) => t.isGroup ? t.status == 'approved' : t.done;

/// Works out which tasks need the user's attention.
Reminders computeReminders(List<Task> tasks, List<ReviewItem> reviews) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = DateTime(now.year, now.month, now.day + 1);

  final rejected = <Task>[];
  final overdue = <Task>[];
  final dueToday = <Task>[];
  final dueTomorrow = <Task>[];

  for (final t in tasks) {
    if (_finished(t)) continue;

    if (t.isGroup && t.status == 'rejected') {
      rejected.add(t);
      continue;
    }
    // Already handed in, now waiting on the lead
    if (t.isGroup && t.status == 'submitted') continue;

    final d = DateTime(t.deadline.year, t.deadline.month, t.deadline.day);
    if (d.isBefore(today)) {
      overdue.add(t);
    } else if (d == today) {
      dueToday.add(t);
    } else if (d == tomorrow) {
      dueTomorrow.add(t);
    }
  }

  return Reminders(
    reviews: reviews,
    rejected: rejected,
    overdue: overdue,
    today: dueToday,
    tomorrow: dueTomorrow,
  );
}