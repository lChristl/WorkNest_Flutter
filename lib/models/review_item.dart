/// A submitted task waiting for the lead's review.
class ReviewItem {
  final int taskId;
  final String taskName;
  final int groupId;
  final String groupName;
  final String assigneeName;
  final String? note;

  ReviewItem({
    required this.taskId,
    required this.taskName,
    required this.groupId,
    required this.groupName,
    required this.assigneeName,
    this.note,
  });
}