class Group {
  final int id;
  final String name;
  final String role; // 'lead' or 'member'

  Group({required this.id, required this.name, required this.role});

  bool get isLead => role == 'lead';
}