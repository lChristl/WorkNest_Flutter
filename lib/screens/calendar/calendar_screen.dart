import 'package:flutter/material.dart';

import '../../services/task_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_helpers.dart';
import 'day_tasks_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = DateTime(_month.year, _month.month, 1).weekday % 7; // Sun = 0
    final totalCells = ((offset + daysInMonth + 6) ~/ 7) * 7;
    final today = DateTime.now();

    return ListenableBuilder(
      listenable: taskStore,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: AppColors.dark,
                      child: Text(
                        '${kMonths[_month.month - 1]} ${_month.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                            .map((d) => Expanded(
                                  child: Center(
                                    child: Text(d,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.dark)),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalCells,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (_, i) {
                        final day = i - offset + 1;
                        if (day < 1 || day > daysInMonth) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.dark, width: 0.5),
                            ),
                          );
                        }
                        final date = DateTime(_month.year, _month.month, day);
                        final count = taskStore.forDate(date).length;
                        final isToday = sameDay(date, today);

                        return InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DayTasksScreen(date: date),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isToday ? AppColors.header : null,
                              border: Border.all(
                                  color: AppColors.dark, width: 0.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$day',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.dark),
                                ),
                                const Spacer(),
                                if (count > 0)
                                  Container(
                                    height: 6,
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.dark,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navButton('‹ Previous', () => _shift(-1)),
                  _navButton('Next ›', () => _shift(1)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _navButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
