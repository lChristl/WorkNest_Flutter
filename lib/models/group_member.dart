class GroupMember {
  final String userId;
  final String username;
  final String role; // 'lead' or 'member'

  GroupMember({
    required this.userId,
    required this.username,
    required this.role,
  });

  bool get isLead => role == 'lead';
}