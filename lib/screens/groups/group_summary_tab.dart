import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../models/group_member.dart';
import '../../models/group_task.dart';
import '../../services/group_service.dart';
import '../../services/group_task_service.dart';
import '../../services/supabase_client.dart';
import '../../theme/app_colors.dart';

class _MemberStats {
  final GroupMember member;
  int approved = 0; // percent from approved tasks
  int submitted = 0; // percent waiting for review
  int assigned = 0; // percent of all tasks given
  int approvedCount = 0;
  int totalCount = 0;

  _MemberStats(this.member);
}

class GroupSummaryTab extends StatefulWidget {
  final Group group;
  const GroupSummaryTab({super.key, required this.group});

  @override
  State<GroupSummaryTab> createState() => _GroupSummaryTabState();
}

class _GroupSummaryTabState extends State<GroupSummaryTab> {
  List<_MemberStats> _stats = [];
  int _totalApproved = 0;
  int _totalAssigned = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final members = await groupService.fetchMembers(widget.group.id);
      final tasks = await groupTaskService.fetchGroupTasks(widget.group.id);

      final byUser = {for (final m in members) m.userId: _MemberStats(m)};
      var totalApproved = 0;
      var totalAssigned = 0;

      for (final GroupTask t in tasks) {
        totalAssigned += t.percent;
        if (t.status == 'approved') totalApproved += t.percent;

        final s = byUser[t.assignedTo];
        if (s == null) continue;
        s.assigned += t.percent;
        s.totalCount += 1;
        if (t.status == 'approved') {
          s.approved += t.percent;
          s.approvedCount += 1;
        } else if (t.status == 'submitted') {
          s.submitted += t.percent;
        }
      }

      final list = byUser.values.toList()
        ..sort((a, b) => b.approved.compareTo(a.approved));

      if (!mounted) return;
      setState(() {
        _stats = list;
        _totalApproved = totalApproved;
        _totalAssigned = totalAssigned;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      debugPrint('LOAD SUMMARY ERROR: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the summary.\n$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Contribution summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
              icon: const Icon(Icons.refresh, color: AppColors.dark),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }

    final myId = supabase.auth.currentUser?.id;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          _groupProgressCard(),
          const SizedBox(height: 12),
          ..._stats.map((s) => _memberCard(s, s.member.userId == myId)),
        ],
      ),
    );
  }

  Widget _groupProgressCard() {
    final value = _totalAssigned == 0
        ? 0.0
        : (_totalApproved / _totalAssigned).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.header,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Group progress',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: Colors.white,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_totalApproved% approved of $_totalAssigned% assigned',
            style: const TextStyle(fontSize: 12, color: AppColors.text),
          ),
        ],
      ),
    );
  }

  Widget _memberCard(_MemberStats s, bool isMe) {
    final value = (s.approved / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dark, width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: AppColors.dark, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMe ? '${s.member.username} (you)' : s.member.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                if (s.member.isLead)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.header,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.dark, width: 0.8),
                    ),
                    child: const Text('Lead',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 8),
                Text(
                  '${s.approved}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Assigned ${s.assigned}%  •  Awaiting review ${s.submitted}%',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Tasks approved: ${s.approvedCount} of ${s.totalCount}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
