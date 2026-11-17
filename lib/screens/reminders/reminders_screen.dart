import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/reminder_service.dart';
import '../../services/task_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/task_tile.dart';
import '../../widgets/worknest_app_bar.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  Widget _section(String title, List<Task> tasks) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 8),
          child: Text(
            '$title (${tasks.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
        ),
        ...tasks.map((t) => TaskTile(task: t)),
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
                    final r = computeReminders(taskStore.tasks);

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