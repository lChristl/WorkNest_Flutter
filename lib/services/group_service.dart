import '../models/group.dart';
import '../models/group_member.dart';
import 'supabase_client.dart';

class GroupService {
  /// Groups the logged-in user belongs to, with their role in each.
  Future<List<Group>> fetchMyGroups() async {
    final userId = supabase.auth.currentUser!.id;

    final rows = await supabase
        .from('group_members')
        .select('role, project_groups(id, name)')
        .eq('user_id', userId)
        .order('joined_at', ascending: false);

    return rows.map<Group>((r) {
      final g = r['project_groups'] as Map<String, dynamic>;
      return Group(
        id: g['id'] as int,
        name: g['name'] as String,
        role: r['role'] as String,
      );
    }).toList();
  }

  /// Creates a group. The database makes the creator its lead.
  Future<void> createGroup(String name) async {
    await supabase.rpc('create_group', params: {'p_name': name});
  }

  /// Everyone in a group (lead first).
  Future<List<GroupMember>> fetchMembers(int groupId) async {
    final rows = await supabase
        .from('group_members')
        .select('user_id, role, profiles(username)')
        .eq('group_id', groupId)
        .order('joined_at');

    final members = rows.map<GroupMember>((r) {
      final p = r['profiles'] as Map<String, dynamic>?;
      return GroupMember(
        userId: r['user_id'] as String,
        username: (p?['username'] as String?) ?? 'Unknown',
        role: r['role'] as String,
      );
    }).toList();

    // Lead first
    members.sort((a, b) => a.isLead == b.isLead ? 0 : (a.isLead ? -1 : 1));
    return members;
  }

  /// Lead adds an existing WorkNest user by email.
  Future<void> addMemberByEmail(int groupId, String email) async {
    await supabase.rpc('add_member_by_email', params: {
      'p_group_id': groupId,
      'p_email': email,
    });
  }

  /// Lead removes a member from the group.
  Future<void> removeMember(int groupId, String userId) async {
    await supabase
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }
}

/// Shared instance used across the app.
final groupService = GroupService();