import 'package:flutter/material.dart';
import '../../services/task_store.dart';

import '../../services/supabase_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pill_button.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = '';
  String _email = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    // Email comes from the login account
    _email = user.email ?? '';

    // Backup username from sign-up data, in case the profiles lookup fails
    _username = (user.userMetadata?['username'] as String?) ?? '';

    // Username from the profiles table
    try {
      final profile = await supabase
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .single();
      _username = profile['username'] as String;
    } catch (e) {
      debugPrint('PROFILE LOAD ERROR: $e');
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _logout() async {
    taskStore.clear();
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.card,
            child: Icon(Icons.person, size: 56, color: AppColors.dark),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            Text(
              _username.isEmpty ? 'No username' : _username,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            Text(_email),
          ],
          const SizedBox(height: 32),
          PillButton(label: 'Log out', onPressed: _logout),
        ],
      ),
    );
  }
}
