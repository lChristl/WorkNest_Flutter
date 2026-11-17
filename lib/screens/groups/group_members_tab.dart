import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/group.dart';
import '../../models/group_member.dart';
import '../../services/group_service.dart';
import '../../services/supabase_client.dart';
import '../../theme/app_colors.dart';

class GroupMembersTab extends StatefulWidget {
  final Group group;
  const GroupMembersTab({super.key, required this.group});

  @override
  State<GroupMembersTab> createState() => _GroupMembersTabState();
}

class _GroupMembersTabState extends State<GroupMembersTab> {
  List<GroupMember> _members = [];
  bool _loading = true;
  String? _error;

  Group get group => widget.group;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await groupService.fetchMembers(group.id);
      if (!mounted) return;
      setState(() {
        _members = members;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      debugPrint('LOAD MEMBERS ERROR: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Could not load members.\n$e';
        _loading = false;
      });
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addMember() async {
    final controller = TextEditingController();

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add member'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Member email',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (email == null || email.isEmpty) return;

    try {
      await groupService.addMemberByEmail(group.id, email);
      _showMessage('Member added');
      await _loadMembers();
    } on PostgrestException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  Future<void> _removeMember(GroupMember m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Remove member'),
        content: Text('Remove ${m.username} from ${group.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await groupService.removeMember(group.id, m.userId);
      await _loadMembers();
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Members',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
            ),
            if (group.isLead)
              ElevatedButton(
                onPressed: _addMember,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.header,
                  foregroundColor: AppColors.text,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  '+ Add member',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildMembers(myId)),
      ],
    );
  }

  Widget _buildMembers(String? myId) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    return ListView.builder(
      itemCount: _members.length,
      itemBuilder: (_, i) {
        final m = _members[i];
        final isMe = m.userId == myId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.dark, width: 1.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: AppColors.dark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isMe ? '${m.username} (you)' : m.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: m.isLead ? AppColors.header : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.dark, width: 0.8),
                  ),
                  child: Text(
                    m.isLead ? 'Lead' : 'Member',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                if (group.isLead && !isMe) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _removeMember(m),
                    child: const Icon(Icons.person_remove,
                        color: AppColors.dark, size: 22),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}