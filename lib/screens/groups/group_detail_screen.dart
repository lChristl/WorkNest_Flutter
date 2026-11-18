import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../theme/app_colors.dart';
import '../../widgets/worknest_app_bar.dart';
import 'group_members_tab.dart';
import 'group_summary_tab.dart';
import 'group_tasks_tab.dart';

class GroupDetailScreen extends StatelessWidget {
    final Group group;
  final int initialTab;
  const GroupDetailScreen({
    super.key,
    required this.group,
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context) {
        return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: workNestAppBar(),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: const TextStyle(
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
              const SizedBox(height: 4),
              Text('Your role: ${group.isLead ? 'Lead' : 'Member'}'),
              const SizedBox(height: 8),
              const TabBar(
                labelColor: AppColors.dark,
                unselectedLabelColor: AppColors.dark,
                indicatorColor: AppColors.dark,
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Members'),
                  Tab(text: 'Tasks'),
                  Tab(text: 'Summary'),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TabBarView(
                    children: [
                      GroupMembersTab(group: group),
                      GroupTasksTab(group: group),
                      GroupSummaryTab(group: group),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
