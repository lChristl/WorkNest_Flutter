import 'package:flutter/material.dart';

import '../screens/reminders/reminders_screen.dart';
import '../services/reminder_service.dart';
import '../services/task_store.dart';
import '../theme/app_colors.dart';

class ReminderBell extends StatelessWidget {
  const ReminderBell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: taskStore,
      builder: (context, _) {
        final count = computeReminders(taskStore.tasks).count;
        return IconButton(
          tooltip: 'Reminders',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RemindersScreen()),
          ),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.text,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}