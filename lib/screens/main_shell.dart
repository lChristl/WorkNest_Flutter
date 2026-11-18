import 'package:flutter/material.dart';

import '../services/reminder_service.dart';
import '../services/task_store.dart';
import '../theme/app_colors.dart';
import '../widgets/reminder_bell.dart';
import '../widgets/worknest_app_bar.dart';
import 'calendar/calendar_screen.dart';
import 'groups/groups_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'reminders/reminders_screen.dart';

/// Holds the header + bottom navigation (Home / Calendar / Groups / Profile).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _loadAndAnnounce();
  }

  Future<void> _loadAndAnnounce() async {
    await taskStore.load();
    if (!mounted) return;

    final count = taskStore.reminders.count;
    if (count == 0) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 1 ? 'You have 1 reminder' : 'You have $count reminders',
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RemindersScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: workNestAppBar(actions: const [ReminderBell()]),
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          CalendarScreen(),
          GroupsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.dark,
          indicatorColor: AppColors.header,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: Colors.white, fontSize: 12),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            return IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.dark
                  : Colors.white,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            setState(() => _index = i);
            taskStore.load();
          },
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined), label: 'Calendar'),
            NavigationDestination(
                icon: Icon(Icons.groups_outlined), label: 'Groups'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
