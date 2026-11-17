import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_store.dart';
import '../theme/app_colors.dart';
import '../utils/date_helpers.dart';
import 'task_dialog.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final bool showActions; // edit + delete icons (personal tasks only)
  const TaskTile({super.key, required this.task, this.showActions = false});

  void _onTap(BuildContext context) {
    if (task.isGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This is a group task. Open the group\'s Tasks tab to submit it.',
          ),
        ),
      );
    } else {
      showTaskDialog(context, existing: task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final finished = task.isGroup ? task.status == 'approved' : task.done;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: task.isGroup ? null : () => taskStore.toggle(task),
            child: Icon(
              finished ? Icons.check_circle : Icons.circle_outlined,
              color: AppColors.dark,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => _onTap(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.dark, width: 1.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.dark,
                              decoration: finished
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            task.subject,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.dark),
                          ),
                          if (task.isGroup) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.groups,
                                    size: 14, color: AppColors.dark),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${task.groupName ?? 'Group'} • ${task.status}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.dark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                            color: priorityColor(task.priority),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            task.priority,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(task.deadline),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.dark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showActions && !task.isGroup) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => showTaskDialog(context, existing: task),
              child: const Icon(Icons.edit_note, color: AppColors.dark),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => taskStore.remove(task),
              child: const Icon(Icons.delete, color: AppColors.dark),
            ),
          ],
        ],
      ),
    );
  }
}