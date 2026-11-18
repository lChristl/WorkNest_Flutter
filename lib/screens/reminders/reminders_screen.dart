import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../models/review_item.dart';
import '../../models/task.dart';
import '../../services/task_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/task_tile.dart';
import '../../widgets/worknest_app_bar.dart';
import '../groups/group_detail_screen.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  Widget _heading(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Text(
        '$title ($count)',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.dark,
        ),
      ),
    );
  }

  Widget _section(String title, List<Task> tasks) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(title, tasks.length),
        ...tasks.map((t) => TaskTile(task: t)),
        const SizedBox(height: 6),
      ],
    );
  }

  void _openReview(BuildContext context, ReviewItem item) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => GroupDetailScreen(
              group: Group(
                id: item.groupId,
                name: item.groupName,
                role: 'lead',
              ),
              initialTab: 1, // open the Tasks tab
            ),
          ),
        )
        .then((_) => taskStore.load());
  }

  Widget _reviewSection(BuildContext context, List<ReviewItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Waiting for your review', items.length),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _openReview(context, item),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1E3B5),
                  border: Border.all(color: AppColors.dark, width: 1.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.rate_review, color: AppColors.dark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.taskName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                          ),
                          Text(
                            'Submitted by ${item.assigneeName} • ${item.groupName}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if ((item.note ?? '').isNotEmpty)
                            Text(
                              'Note: ${item.note}',
                              style: const TextStyle(
                                  fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.dark),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: workNestAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Reminders',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('‹ Back'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListenableBuilder(
                  listenable: taskStore,
                  builder: (context, _) {
                    final r = taskStore.reminders;

                    if (r.count == 0) {
                      return const Center(
                        child: Text(
                          'You are all caught up!\nNo reminders right now.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView(
                      children: [
                        _reviewSection(context, r.reviews),
                        _section('Needs resubmission', r.rejected),
                        _section('Overdue', r.overdue),
                        _section('Due today', r.today),
                        _section('Due tomorrow', r.tomorrow),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}