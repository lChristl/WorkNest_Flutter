import 'package:flutter/material.dart';

import '../../services/task_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/search_field.dart';
import '../../widgets/task_tile.dart';
import '../../widgets/worknest_app_bar.dart';

class DayTasksScreen extends StatefulWidget {
  final DateTime date;
  const DayTasksScreen({super.key, required this.date});

  @override
  State<DayTasksScreen> createState() => _DayTasksScreenState();
}

class _DayTasksScreenState extends State<DayTasksScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final d = widget.date;
    return Scaffold(
      appBar: workNestAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tasks due on ${kMonths[d.month - 1]} ${d.day} ${d.year}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 12),
            SearchField(onChanged: (v) => setState(() => _query = v)),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All Tasks',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: taskStore,
                        builder: (context, _) {
                          final q = _query.trim().toLowerCase();
                          final items = taskStore.forDate(d).where((t) {
                            return q.isEmpty ||
                                t.name.toLowerCase().contains(q) ||
                                t.subject.toLowerCase().contains(q);
                          }).toList();

                          if (items.isEmpty) {
                            return const Center(
                                child: Text('No tasks due on this day'));
                          }
                          return ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (_, i) =>
                                TaskTile(task: items[i], showActions: true),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
