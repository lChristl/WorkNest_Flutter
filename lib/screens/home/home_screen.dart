import 'package:flutter/material.dart';

import '../../services/task_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/search_field.dart';
import '../../widgets/task_dialog.dart';
import '../../widgets/task_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () => showTaskDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.dark,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text(
                  '+ Add task',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SearchField(onChanged: (v) => setState(() => _query = v)),
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
              child: Column(
                children: [
                  const Text(
                    'Task List',
                    style: TextStyle(
                      fontSize: 18,
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
                        final items = taskStore.tasks.where((t) {
                          return q.isEmpty ||
                              t.name.toLowerCase().contains(q) ||
                              t.subject.toLowerCase().contains(q);
                        }).toList();

                        if (items.isEmpty) {
                          return const Center(child: Text('No tasks yet'));
                        }
                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final task = items[i];
                            return Dismissible(
                              key: ValueKey(task.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDE9A8E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.delete),
                              ),
                              onDismissed: (_) => taskStore.remove(task),
                              child: TaskTile(task: task),
                            );
                          },
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
    );
  }
}
